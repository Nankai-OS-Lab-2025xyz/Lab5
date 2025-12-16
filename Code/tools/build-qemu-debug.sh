#!/bin/bash
# QEMU调试版本编译脚本
# 用于编译带完整调试信息的QEMU

set -e

# 配置变量
QEMU_VERSION="v6.2.0"  # 根据实际需要修改
QEMU_SRC_DIR="$HOME/qemu"
QEMU_BUILD_DIR="$HOME/qemu/build-debug"
NUM_JOBS=$(nproc)

echo "=========================================="
echo "QEMU调试版本编译脚本"
echo "=========================================="
echo ""

# 检查是否已存在源码
if [ ! -d "$QEMU_SRC_DIR" ]; then
    echo "QEMU源码目录不存在，开始克隆..."
    cd ~
    git clone https://gitlab.com/qemu-project/qemu.git
    cd qemu
    echo "切换到版本: $QEMU_VERSION"
    git checkout $QEMU_VERSION 2>/dev/null || {
        echo "警告: 无法切换到 $QEMU_VERSION，使用当前分支"
    }
else
    echo "QEMU源码目录已存在: $QEMU_SRC_DIR"
    cd $QEMU_SRC_DIR
    echo "更新源码..."
    git fetch
fi

# 创建构建目录
echo ""
echo "创建构建目录: $QEMU_BUILD_DIR"
mkdir -p $QEMU_BUILD_DIR
cd $QEMU_BUILD_DIR

# 检查依赖
echo ""
echo "检查编译依赖..."
if ! command -v pkg-config &> /dev/null; then
    echo "警告: pkg-config 未安装，可能影响编译"
fi

# 配置编译选项
echo ""
echo "配置编译选项（启用调试信息）..."
../configure \
    --target-list=riscv64-softmmu \
    --enable-debug \
    --disable-strip \
    --extra-cflags="-g -O0 -DDEBUG" \
    --extra-ldflags="-g" \
    --enable-trace-backends=log \
    || {
    echo "配置失败，尝试使用默认配置..."
    ../configure --target-list=riscv64-softmmu --enable-debug
}

# 编译
echo ""
echo "开始编译（使用 $NUM_JOBS 个并行任务）..."
echo "这可能需要较长时间，请耐心等待..."
make -j$NUM_JOBS

# 检查编译结果
if [ -f "riscv64-softmmu/qemu-system-riscv64" ]; then
    echo ""
    echo "=========================================="
    echo "编译成功！"
    echo "=========================================="
    echo "QEMU可执行文件位置:"
    echo "  $QEMU_BUILD_DIR/riscv64-softmmu/qemu-system-riscv64"
    echo ""
    echo "文件大小:"
    ls -lh riscv64-softmmu/qemu-system-riscv64
    echo ""
    echo "下一步："
    echo "1. 使用此QEMU替换系统QEMU，或"
    echo "2. 在Makefile中设置QEMU变量指向此路径"
    echo ""
    echo "例如，在Makefile中添加："
    echo "  QEMU := $QEMU_BUILD_DIR/riscv64-softmmu/qemu-system-riscv64"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "编译失败！"
    echo "=========================================="
    echo "请检查错误信息并修复问题"
    exit 1
fi












