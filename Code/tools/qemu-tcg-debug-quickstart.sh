#!/bin/bash
# QEMU TCG调试快速启动脚本
# 用于快速设置和启动QEMU源码级别的调试

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "QEMU TCG调试快速启动"
echo "=========================================="
echo ""

# 检查QEMU调试版本是否存在
QEMU_DEBUG="$HOME/qemu/build-debug/riscv64-softmmu/qemu-system-riscv64"
if [ ! -f "$QEMU_DEBUG" ]; then
    echo "错误: 未找到QEMU调试版本"
    echo "请先运行: bash tools/build-qemu-debug.sh"
    exit 1
fi

# 检查项目是否已编译
if [ ! -f "$PROJECT_DIR/bin/ucore.img" ]; then
    echo "编译项目..."
    cd $PROJECT_DIR
    make clean
    make
fi

# 查找QEMU进程
echo "查找QEMU进程..."
QEMU_PID=$(pgrep -f "qemu-system-riscv64" | head -1)

if [ -z "$QEMU_PID" ]; then
    echo "未找到运行中的QEMU进程"
    echo ""
    echo "请在一个终端中运行:"
    echo "  cd $PROJECT_DIR"
    echo "  make debug"
    echo ""
    echo "然后在另一个终端运行此脚本"
    exit 1
fi

echo "找到QEMU进程: PID=$QEMU_PID"
echo ""

# 创建临时GDB脚本
GDB_SCRIPT=$(mktemp)
cat > $GDB_SCRIPT <<EOF
# 附加到QEMU进程
attach $QEMU_PID

# 加载QEMU符号
file $QEMU_DEBUG

# 设置TCG翻译断点
break gen_helper_ecall
break gen_helper_sret
break riscv_cpu_do_interrupt

echo \n
echo ========================================\n
echo 已附加到QEMU进程并设置断点\n
echo 断点位置：\n
echo   - gen_helper_ecall\n
echo   - gen_helper_sret\n
echo   - riscv_cpu_do_interrupt\n
echo \n
echo 输入 'continue' 开始调试\n
echo ========================================\n
echo \n
EOF

echo "启动GDB调试QEMU..."
echo "使用脚本: $GDB_SCRIPT"
echo ""

# 启动GDB
cd $PROJECT_DIR
riscv64-unknown-elf-gdb -x $GDB_SCRIPT

# 清理临时文件
rm -f $GDB_SCRIPT












