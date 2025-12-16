# 快速构建指南

## 当前环境状态

✅ **已安装**: Theos (`$THEOS=/home/pets/theos`)  
❌ **未安装**: Swift 编译器  
❓ **需要检查**: iOS SDK

## 尝试构建

在项目根目录运行：

```bash
cd /home/pets/桌面/NewTerm-main
export THEOS=/home/pets/theos
make
```

## 可能的错误和解决方案

### 1. 缺少 iOS SDK

**错误信息**: `SDKROOT not set` 或类似

**解决方案**: 
- iOS SDK 通常只能在 macOS 上获得
- 需要从 macOS 的 Xcode 复制 SDK 到 Linux
- 或者使用 GitHub Actions 在云端构建

### 2. 缺少 Swift 编译器

**错误信息**: `swift: command not found`

**解决方案**:
```bash
# 下载 Swift for Linux
wget https://swift.org/builds/swift-5.9-release/ubuntu2204/swift-5.9-RELEASE/swift-5.9-RELEASE-ubuntu22.04.tar.gz
tar xzf swift-5.9-RELEASE-ubuntu22.04.tar.gz
export PATH=$(pwd)/swift-5.9-RELEASE-ubuntu22.04/usr/bin:$PATH
```

### 3. 缺少其他依赖

根据错误信息安装相应工具。

## 推荐的构建方式

由于这是 iOS 应用，最可靠的方式是：

1. **使用 GitHub Actions**（已配置）:
   - 提交代码到 GitHub
   - 自动在 macOS 环境中构建

2. **在 macOS 机器上构建**:
   ```bash
   xcodebuild -project NewTerm.xcodeproj -scheme "NewTerm (iOS)"
   ```

3. **使用 Theos 在越狱设备上安装**:
   ```bash
   make do  # 需要配置设备连接
   ```

