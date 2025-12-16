#!/bin/bash
# Theos 环境检查脚本

echo "=== NewTerm Theos 环境检查 ==="
echo ""

# 检查 Theos
echo "1. Theos 环境:"
if [ -z "$THEOS" ]; then
    echo "   ❌ THEOS 环境变量未设置"
    echo "   建议: export THEOS=/home/pets/theos"
    THEOS_FOUND=false
else
    echo "   ✅ THEOS=$THEOS"
    if [ -d "$THEOS" ]; then
        echo "   ✅ Theos 目录存在"
        THEOS_FOUND=true
    else
        echo "   ❌ Theos 目录不存在"
        THEOS_FOUND=false
    fi
fi
echo ""

# 检查 iOS SDK
echo "2. iOS SDK:"
if [ "$THEOS_FOUND" = true ]; then
    SDK_COUNT=$(ls -d $THEOS/sdks/*.sdk 2>/dev/null | wc -l)
    if [ "$SDK_COUNT" -gt 0 ]; then
        echo "   ✅ 找到 $SDK_COUNT 个 SDK:"
        ls -d $THEOS/sdks/*.sdk 2>/dev/null | sed 's/.*\//     - /'
    else
        echo "   ❌ 未找到 iOS SDK"
        echo "   需要从 macOS 复制 iOS SDK 到 $THEOS/sdks/"
    fi
else
    echo "   ⚠️  无法检查（Theos 未配置）"
fi
echo ""

# 检查基本工具
echo "3. 基本工具:"
TOOLS=("make" "git" "perl" "python3" "ldid")
ALL_TOOLS_OK=true
for tool in "${TOOLS[@]}"; do
    if which "$tool" >/dev/null 2>&1; then
        echo "   ✅ $tool: $(which $tool)"
    else
        echo "   ❌ $tool: 未找到"
        ALL_TOOLS_OK=false
    fi
done
echo ""

# 检查编译工具
echo "4. 编译工具:"
if [ "$THEOS_FOUND" = true ]; then
    # 检查 xcodebuild（需要在 macOS）
    if which xcodebuild >/dev/null 2>&1; then
        echo "   ✅ xcodebuild: $(which xcodebuild)"
        echo "      $(xcodebuild -version 2>/dev/null | head -1)"
    else
        echo "   ❌ xcodebuild: 未找到（这是正常的，因为你在 Linux 上）"
        echo "      ⚠️  xcodebuild 只能在 macOS 上运行"
        echo "      建议: 使用 GitHub Actions 进行自动构建"
    fi
    
    # 检查 Swift
    if [ -L "$THEOS/toolchain/linux/iphone/bin/swift" ]; then
        SWIFT_PATH=$(readlink -f "$THEOS/toolchain/linux/iphone/bin/swift" 2>/dev/null)
        if [ -f "$SWIFT_PATH" ]; then
            echo "   ✅ Swift toolchain link exists"
            if "$SWIFT_PATH" --version >/dev/null 2>&1; then
                echo "      $($SWIFT_PATH --version 2>/dev/null | head -1)"
            else
                echo "      ⚠️  Swift 编译器可能不可用"
            fi
        else
            echo "   ⚠️  Swift toolchain link 存在但目标文件不存在"
        fi
    else
        echo "   ⚠️  Swift toolchain 未配置"
    fi
else
    echo "   ⚠️  无法检查（Theos 未配置）"
fi
echo ""

# 总结
echo "=== 总结 ==="
if [ "$THEOS_FOUND" = true ] && [ "$ALL_TOOLS_OK" = true ]; then
    echo "✅ 基本环境配置完整"
    echo ""
    echo "⚠️  编译限制:"
    echo "   - 这个项目使用 xcodeproj.mk，需要 xcodebuild"
    echo "   - xcodebuild 只能在 macOS 上运行"
    echo "   - 在 Linux 上无法直接编译"
    echo ""
    echo "💡 建议:"
    echo "   1. 使用 GitHub Actions 自动构建（推荐）"
    echo "   2. 在 macOS 机器上编译"
    echo "   3. 在 Linux 上只进行代码编辑和 Git 操作"
else
    echo "❌ 环境配置不完整"
    echo ""
    echo "需要:"
    [ -z "$THEOS" ] && echo "   - 设置 THEOS 环境变量"
    [ "$ALL_TOOLS_OK" = false ] && echo "   - 安装缺失的工具"
fi
echo ""

