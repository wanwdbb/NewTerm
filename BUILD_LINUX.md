# 在 Linux 上编译 NewTerm

## 重要说明

**这是一个 iOS 应用项目**，要在 Linux 上编译会有很大限制。主要原因：

1. **需要 iOS SDK**: iOS 应用需要 iOS SDK（UIKit、SwiftUI 等），这些只能在 macOS 上通过 Xcode 获得
2. **代码签名**: iOS 应用需要 Apple 的代码签名工具
3. **Swift 工具链**: 虽然 Swift 可以在 Linux 上运行，但 iOS SDK 不可用

## 理论上可行的方案

### 方案 1: 使用 Theos（推荐用于越狱设备）

Theos 是一个跨平台的 iOS 开发工具链，理论上可以在 Linux 上运行，但需要：

1. **安装 Theos**:
```bash
export THEOS=~/theos
git clone --recursive https://github.com/theos/theos.git $THEOS
```

2. **获取 iOS SDK**:
   - 这是最大的障碍，iOS SDK 通常只能从 macOS 的 Xcode 中提取
   - 需要从 Mac 复制 `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS*.sdk` 到 Linux

3. **安装依赖工具**:
```bash
# 安装基本工具
sudo apt-get update
sudo apt-get install -y build-essential git perl python3 python3-pip lib32stdc++-11-dev lib32z1-dev libclang-dev llvm-dev

# 安装 ldid（用于代码签名，iOS越狱开发需要）
sudo apt-get install -y ldid
# 或者从源码编译
```

4. **配置环境变量**:
```bash
export THEOS=~/theos
export PATH=$THEOS/bin:$PATH
```

5. **尝试编译**:
```bash
cd /home/pets/桌面/NewTerm-main
make
```

### 方案 2: 使用 Docker 模拟 macOS 环境（困难）

可以使用 Docker 容器模拟 macOS，但这涉及：
- macOS 镜像（法律和技术问题）
- Xcode 安装
- 非常复杂的设置

### 方案 3: 远程 macOS 构建

如果你有 macOS 机器或可以访问：
1. 在 macOS 上设置 SSH
2. 在 Linux 上通过 SSH 远程执行构建命令

## 实际建议

### 最实用的方案

1. **在 macOS 上编译**（如果有 Mac）:
   ```bash
   # 在 macOS 上
   xcodebuild -project NewTerm.xcodeproj -scheme "NewTerm (iOS)"
   ```

2. **使用 GitHub Actions**（项目已有）:
   项目已经配置了 GitHub Actions，可以在云端 macOS 环境中自动构建

3. **检查代码而不是编译**:
   在 Linux 上可以：
   - 检查 Swift 语法（如果安装了 Swift）
   - 运行静态分析
   - 查看代码结构

## 快速检查当前环境

运行以下命令检查你的系统是否满足最小要求：

```bash
# 检查基本工具
which make
which git
which perl

# 检查 Swift（如果已安装）
swift --version

# 检查 Theos（如果已安装）
echo $THEOS
ls -la $THEOS 2>/dev/null || echo "Theos not found"
```

## 如果只是想验证代码修改

如果你只是想验证刚才的代码修改是否正确，可以：

1. **语法检查**: 如果安装了 Swift，可以尝试语法检查
2. **查看构建配置**: 检查 Xcode 项目文件
3. **提交到 GitHub**: 使用 GitHub Actions 自动构建测试

## 具体到你的情况

基于当前系统（Linux），最可行的方案是：

1. **安装 Swift**（用于语法检查）:
   ```bash
   # 下载 Swift for Linux
   # https://www.swift.org/download/
   ```

2. **设置 GitHub Actions**（用于实际构建）:
   - 将修改推送到 GitHub
   - 让 GitHub Actions 在云端 macOS 环境中构建

3. **或者寻找 macOS 环境**:
   - 使用朋友的 Mac
   - 租用 Mac 云服务（如 MacStadium、MacInCloud）

## 总结

**在 Linux 上直接编译 iOS 应用是极其困难的**，因为缺少 iOS SDK。建议：
- 如果有 Mac：直接在 Mac 上编译
- 如果没有 Mac：使用 GitHub Actions 或寻找 Mac 云服务
- 如果只是验证代码：安装 Swift 进行语法检查，或使用在线工具

