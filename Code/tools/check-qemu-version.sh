#!/bin/bash
# 检查QEMU版本和位置

echo "=========================================="
echo "QEMU版本信息"
echo "=========================================="

# 检查系统QEMU
QEMU_SYSTEM=$(which qemu-system-riscv64 2>/dev/null)
if [ -n "$QEMU_SYSTEM" ]; then
    echo "系统QEMU位置: $QEMU_SYSTEM"
    echo "版本信息:"
    $QEMU_SYSTEM --version | head -1
    echo ""
    
    # 检查是否有调试符号
    if file "$QEMU_SYSTEM" | grep -q "not stripped"; then
        echo "状态: 包含调试符号"
    else
        echo "状态: 已剥离调试符号（需要重新编译）"
    fi
else
    echo "未找到系统QEMU"
fi

echo ""

# 检查调试版QEMU
QEMU_DEBUG="$HOME/qemu/build-debug/riscv64-softmmu/qemu-system-riscv64"
if [ -f "$QEMU_DEBUG" ]; then
    echo "调试版QEMU位置: $QEMU_DEBUG"
    echo "版本信息:"
    $QEMU_DEBUG --version | head -1
    echo ""
    
    if file "$QEMU_DEBUG" | grep -q "not stripped"; then
        echo "状态: 包含调试符号 ✓"
    else
        echo "状态: 已剥离调试符号"
    fi
else
    echo "未找到调试版QEMU"
    echo "如需编译，运行: bash tools/build-qemu-debug.sh"
fi

echo ""
echo "=========================================="












