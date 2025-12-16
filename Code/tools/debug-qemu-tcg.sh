#!/bin/bash
# QEMU TCG调试脚本 - 附加到运行中的QEMU进程

QEMU_PID=$(pgrep -f qemu-system-riscv64 | head -1)

if [ -z "$QEMU_PID" ]; then
    echo "错误: 未找到QEMU进程"
    echo "请先在一个终端运行: make debug"
    exit 1
fi

echo "找到QEMU进程: PID=$QEMU_PID"

# 检查是否有调试版QEMU
QEMU_DEBUG="$HOME/qemu/build-debug/qemu-system-riscv64"
if [ -f "$QEMU_DEBUG" ]; then
    QEMU_BIN="$QEMU_DEBUG"
    echo "使用调试版QEMU: $QEMU_BIN"
else
    # 使用系统QEMU（可能没有调试符号）
    QEMU_BIN=$(which qemu-system-riscv64)
    echo "使用系统QEMU: $QEMU_BIN"
    echo "警告: 系统QEMU可能没有调试符号，建议编译调试版"
fi

# 使用系统的gdb（不是riscv64-unknown-elf-gdb）
# QEMU是x86_64进程，需要用x86_64的gdb调试
GDB_CMD="gdb"
if ! command -v gdb &> /dev/null; then
    echo "错误: 未找到gdb，请安装: sudo apt-get install gdb"
    exit 1
fi

# 启动GDB
$GDB_CMD \
  -ex "attach $QEMU_PID" \
  -ex "file $QEMU_BIN" \
  -ex "break riscv_cpu_do_interrupt" \
  -ex "echo \\n已附加到QEMU并设置断点\\n" \
  -ex "echo 输入 continue 开始调试\\n" \
  -ex "echo 提示: 可以在QEMU源码中设置更多断点\\n"

