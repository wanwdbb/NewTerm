# NewTerm UI 卡顿问题分析报告

## 问题概述

根据三个崩溃日志文件的分析，应用频繁出现 **"scene-update watchdog transgression"** 错误，导致UI卡顿，应用无法正常使用。

### 错误详情

所有三个日志文件都显示相同的错误：
```
scene-update watchdog transgression: application<ws.hbang.Terminal>:XXXX exhausted real (wall clock) time allowance of 10.00 seconds
```

这表明应用在场景更新时超过了iOS系统的10秒时间限制，导致看门狗终止应用。

## 根本原因分析

### 1. 主线程阻塞问题

**位置**: `TerminalController.swift` 的 `updateTimerFired()` 方法

**问题代码** (第217-274行):
```swift
@objc private func updateTimerFired() {
    terminalQueue.async {
        // ... 处理缓冲区 ...
        
        // 为所有需要更新的行生成 SwiftUI 视图
        for i in linesToUpdate {
            self.lines[i] = self.stringSupplier.attributedString(forScrollInvariantRow: i)
        }
        
        // 切换到主线程更新UI
        DispatchQueue.main.async {
            self.delegate?.refresh(lines: &self.lines)
        }
    }
}
```

**问题点**:
- 虽然在后台队列中执行，但生成了大量的 SwiftUI 视图对象
- 当终端有大量输出需要更新时（比如100+行），会创建100+个复杂的视图层次结构
- 这些视图对象在主线程更新时，SwiftUI 需要进行大量的布局计算和渲染，导致主线程阻塞

### 2. 视图创建性能问题

**位置**: `StringSupplier.swift` 的 `attributedString(forScrollInvariantRow:)` 方法

**问题代码** (第27-74行):
```swift
public func attributedString(forScrollInvariantRow row: Int) -> AnyView {
    // ...
    // 为每一行创建一个包含多个 Text 视图的 HStack
    return AnyView(HStack(alignment: .firstTextBaseline, spacing: 0) {
        views.reduce(AnyView(EmptyView()), { $0 + $1 })
    })
}
```

**问题点**:
- 每一行终端输出都会创建一个 `HStack` 包含多个 `Text` 视图
- 每个 `Text` 视图都有复杂的属性（颜色、字体、背景、样式等）
- 对于有大量行的终端，这会创建成百上千的视图对象
- SwiftUI 的视图层次结构在渲染时需要大量计算

### 3. 频繁更新问题

**位置**: `TerminalController.swift` 的 CADisplayLink 配置

**问题代码** (第166-171行):
```swift
private func startUpdateTimer(fps: TimeInterval) {
    updateTimer?.invalidate()
    updateTimer = CADisplayLink(target: self, selector: #selector(self.updateTimerFired))
    updateTimer?.preferredFramesPerSecond = Int(fps)
    updateTimer?.add(to: .main, forMode: .default)
}
```

**问题点**:
- 刷新率可能高达 60 FPS（每秒60次）
- 每次刷新都可能导致大量视图重新生成和更新
- 当终端有大量输出时，这种频繁更新会严重阻塞主线程

### 4. SwiftUI 视图更新开销

**位置**: `TerminalSessionViewController.swift` 的 `refresh` 方法

**问题代码** (第267-269行):
```swift
func refresh(lines: inout [AnyView]) {
    state.lines = lines
}
```

**问题点**:
- 直接替换整个 `lines` 数组会触发 SwiftUI 的完整重新渲染
- `TerminalView` 中的 `LazyVStack` 需要重新计算所有行的布局
- 对于大量行，这会非常耗时

## 解决方案

### 解决方案 1: 限制更新范围（推荐）

限制每次更新最多处理的行数，避免一次性更新过多行：

```swift
// 在 TerminalController.swift 中
private let maxLinesPerUpdate = 50 // 每次最多更新50行

@objc private func updateTimerFired() {
    terminalQueue.async {
        // ... 现有代码 ...
        
        // 限制更新的行数
        let linesToUpdateArray = Array(linesToUpdate).prefix(maxLinesPerUpdate)
        for i in linesToUpdateArray {
            self.lines[i] = self.stringSupplier.attributedString(forScrollInvariantRow: i)
        }
        
        // 如果还有未处理的更新，标记为需要下次更新
        if linesToUpdate.count > maxLinesPerUpdate {
            self.pendingLineUpdates = Set(linesToUpdate.suffix(from: maxLinesPerUpdate))
        }
        
        DispatchQueue.main.async {
            self.delegate?.refresh(lines: &self.lines)
        }
    }
}
```

### 解决方案 2: 批量更新

将更新分批处理，每次只处理一部分，避免长时间阻塞：

```swift
private var pendingLineUpdates: Set<Int> = []
private var isUpdating = false

@objc private func updateTimerFired() {
    terminalQueue.async {
        guard !self.isUpdating else { return }
        
        // ... 现有代码收集需要更新的行 ...
        
        // 分批处理，每次最多20行
        let batchSize = 20
        let linesToUpdateArray = Array(linesToUpdate).prefix(batchSize)
        
        for i in linesToUpdateArray {
            self.lines[i] = self.stringSupplier.attributedString(forScrollInvariantRow: i)
        }
        
        // 保存剩余需要更新的行
        let remaining = Set(linesToUpdate).subtracting(linesToUpdateArray)
        self.pendingLineUpdates.formUnion(remaining)
        
        DispatchQueue.main.async {
            self.delegate?.refresh(lines: &self.lines)
            
            // 如果还有未处理的更新，延迟处理
            if !self.pendingLineUpdates.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) { // ~60fps
                    self.processPendingUpdates()
                }
            }
        }
    }
}

private func processPendingUpdates() {
    guard !pendingLineUpdates.isEmpty else { return }
    
    terminalQueue.async {
        let batchSize = 20
        let linesToUpdateArray = Array(self.pendingLineUpdates).prefix(batchSize)
        
        for i in linesToUpdateArray {
            self.lines[i] = self.stringSupplier.attributedString(forScrollInvariantRow: i)
        }
        
        self.pendingLineUpdates.subtract(linesToUpdateArray)
        
        DispatchQueue.main.async {
            self.delegate?.refresh(lines: &self.lines)
            
            if !self.pendingLineUpdates.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) {
                    self.processPendingUpdates()
                }
            }
        }
    }
}
```

### 解决方案 3: 降低刷新率

当有大量更新时，动态降低刷新率：

```swift
private var consecutiveLargeUpdates = 0

@objc private func updateTimerFired() {
    terminalQueue.async {
        // ... 现有代码 ...
        
        if linesToUpdate.count > 100 {
            consecutiveLargeUpdates += 1
            if consecutiveLargeUpdates > 3 {
                // 降低刷新率
                self.startUpdateTimer(fps: min(self.refreshRate, 30))
            }
        } else {
            consecutiveLargeUpdates = 0
            // 恢复正常刷新率
            if self.updateTimer?.preferredFramesPerSecond != Int(self.refreshRate) {
                self.startUpdateTimer(fps: self.refreshRate)
            }
        }
    }
}
```

### 解决方案 4: 优化视图生成（长期方案）

考虑使用更轻量级的渲染方式，比如：
- 使用 Core Text 或 TextKit 直接渲染文本
- 缓存已生成的视图
- 使用 `drawingGroup()` 来优化性能（已经在 TerminalView 中使用，但可能需要调整）

## 推荐的修复策略

**立即修复**（快速缓解问题）:
1. 实施解决方案 1 和 2（限制更新范围和批量更新）
2. 添加更新范围的检查，避免单次更新过多行

**中期优化**:
1. 实施解决方案 3（动态刷新率）
2. 添加性能监控，检测更新耗时

**长期优化**:
1. 考虑重写视图渲染逻辑，使用更高效的渲染方式
2. 实现视图缓存机制
3. 优化 SwiftUI 视图层次结构

## 测试建议

1. **大量输出测试**: 运行产生大量输出的命令（如 `cat large_file.txt`）
2. **快速输入测试**: 快速输入命令，观察响应性
3. **后台切换测试**: 切换到后台再回来，检查是否能正常恢复
4. **内存监控**: 监控内存使用，确保不会因视图创建导致内存问题

## 总结

主要问题是当终端有大量输出时，一次性创建和更新过多的 SwiftUI 视图导致主线程阻塞。通过限制更新范围、批量处理和动态调整刷新率，可以显著改善UI响应性。

