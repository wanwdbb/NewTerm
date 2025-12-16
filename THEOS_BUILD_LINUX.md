# 在 Linux 上使用 Theos 编译 NewTerm

## 当前状态

✅ **已安装**: Theos (`/home/pets/theos`)  
✅ **已安装**: iOS SDK (`iPhoneOS16.5.sdk`)  
✅ **已安装**: ldid（代码签名工具）  
✅ **已安装**: 基本工具（make, git, perl, python3）  
❌ **缺少**: xcodebuild（仅在 macOS 可用）  
❌ **缺少**: Swift 编译器（用于编译 Swift 代码）

## 问题分析

这个项目使用了 `xcodeproj.mk`，它依赖于：
- `xcodebuild`：Apple 的构建工具，**只能在 macOS 上运行**
- Xcode 项目文件（`.xcodeproj`）
- Swift 编译器（用于编译 Swift 代码）

**核心限制**：`xcodebuild` 是 macOS 专有工具，无法在 Linux 上运行。

## 解决方案

### 方案 1: 使用 GitHub Actions（推荐）⭐

项目已配置 GitHub Actions，可以在云端 macOS 环境自动构建：

```bash
# 1. 提交你的修改
git add .
git commit -m "修复 UI 卡顿问题"
git push

# 2. GitHub Actions 会自动：
#    - 在 macOS 环境中构建
#    - 生成 .deb 包
#    - 可以在 Actions 页面下载
```

查看构建状态：
- 打开 GitHub 仓库 → Actions 标签页
- 下载构建好的 `.deb` 包

### 方案 2: 在 macOS 上直接编译

如果你有 Mac 或可以访问 macOS 机器：

```bash
# 方式 1: 使用 Xcode GUI
open NewTerm.xcodeproj
# 然后在 Xcode 中点击 Build

# 方式 2: 使用命令行（推荐）
xcodebuild -project NewTerm.xcodeproj \
           -scheme "NewTerm (iOS)" \
           -configuration Release \
           -derivedDataPath ./build
```

### 方案 3: 配置 Linux Theos 环境（需要额外工具）

虽然在 Linux 上无法直接使用 `xcodebuild`，但可以尝试：

#### 3.1 安装 Swift 编译器

```bash
# 下载 Swift for Linux
cd ~
wget https://swift.org/builds/swift-5.9-release/ubuntu2204/swift-5.9-RELEASE/swift-5.9-RELEASE-ubuntu22.04.tar.gz
tar xzf swift-5.9-RELEASE-ubuntu22.04.tar.gz

# 添加到 PATH
export PATH=~/swift-5.9-RELEASE-ubuntu22.04/usr/bin:$PATH
echo 'export PATH=~/swift-5.9-RELEASE-ubuntu22.04/usr/bin:$PATH' >> ~/.bashrc

# 验证安装
swift --version
```

#### 3.2 安装依赖库

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    libicu-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libsqlite3-dev \
    libblocksruntime-dev \
    libdispatch-dev \
    clang \
    llvm
```

#### 3.3 创建 xcodebuild 包装脚本（实验性）

由于 `xcodebuild` 不可用，可以尝试创建一个包装脚本来模拟：

```bash
# 创建包装脚本
mkdir -p $THEOS/toolchain/linux/iphone/bin
cat > $THEOS/toolchain/linux/iphone/bin/xcodebuild << 'EOF'
#!/bin/bash
# xcodebuild 包装脚本（实验性）
# 注意：这只是一个占位符，可能无法完全工作

# 尝试使用 swift build 或其他方式
echo "Error: xcodebuild is not available on Linux"
echo "This project requires macOS to build"
exit 1
EOF

chmod +x $THEOS/toolchain/linux/iphone/bin/xcodebuild
```

**警告**：这只是占位符，实际编译仍需要 macOS。

### 方案 4: 使用 Docker 容器（不推荐）

理论上可以使用 macOS 容器，但：
- 法律问题（macOS EULA）
- 技术复杂
- 性能问题

## 推荐工作流程

对于 Linux 用户，推荐流程：

1. **开发阶段**（在 Linux）:
   ```bash
   # 编辑代码
   code TerminalController.swift
   
   # 提交修改
   git add .
   git commit -m "修复"
   ```

2. **构建阶段**（使用 GitHub Actions）:
   ```bash
   # 推送到 GitHub
   git push
   
   # GitHub Actions 自动构建
   # 在 Actions 页面下载 .deb 包
   ```

3. **安装阶段**（在越狱设备）:
   ```bash
   # 将 .deb 文件传输到设备
   scp NewTerm.deb root@device:/tmp/
   
   # 在设备上安装
   ssh root@device
   dpkg -i /tmp/NewTerm.deb
   ```

## 验证环境

运行以下命令检查你的环境：

```bash
#!/bin/bash
echo "=== Theos 环境检查 ==="
echo "Theos 路径: $THEOS"
echo "Theos 存在: $(test -d $THEOS && echo '✅' || echo '❌')"
echo ""
echo "iOS SDK:"
ls -d $THEOS/sdks/*.sdk 2>/dev/null | wc -l && echo "✅ SDK found" || echo "❌ No SDK"
echo ""
echo "工具检查:"
for tool in make git perl python3 ldid; do
    which $tool >/dev/null && echo "✅ $tool" || echo "❌ $tool"
done
echo ""
echo "Swift 编译器:"
which swift >/dev/null && swift --version || echo "❌ Swift not found"
echo ""
echo "xcodebuild (需要 macOS):"
which xcodebuild >/dev/null && echo "✅ xcodebuild" || echo "❌ xcodebuild (expected on Linux)"
```

## 总结

**在 Linux 上编译 iOS 应用的现实**：
- ✅ 可以编辑代码
- ✅ 可以使用 Git 版本控制
- ❌ 无法直接编译（需要 macOS）
- ✅ 可以使用 GitHub Actions 自动构建

**最佳实践**：
1. 在 Linux 上开发和编辑代码
2. 使用 GitHub Actions 进行自动构建
3. 下载构建产物并在设备上安装

## 快速命令参考

```bash
# 检查环境
export THEOS=/home/pets/theos
cd /home/pets/桌面/NewTerm-main
bash <(curl -s https://raw.githubusercontent.com/theos/theos/master/bin/setup.sh)

# 提交到 GitHub（触发自动构建）
git add .
git commit -m "你的提交信息"
git push

# 清理构建文件
make clean
```

