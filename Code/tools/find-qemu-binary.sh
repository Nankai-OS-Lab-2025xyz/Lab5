#!/bin/bash
# 查找编译后的QEMU可执行文件

echo "查找QEMU可执行文件..."
echo ""

# 在build-debug目录中搜索
cd ~/qemu/build-debug

# 查找所有qemu-system-riscv64文件
find . -name "qemu-system-riscv64" -type f 2>/dev/null

echo ""
echo "检查常见位置："

# 检查不同可能的位置
for path in \
    "riscv64-softmmu/qemu-system-riscv64" \
    "bin/qemu-system-riscv64" \
    "qemu-system-riscv64" \
    "build/riscv64-softmmu/qemu-system-riscv64"
do
    if [ -f "$path" ]; then
        echo "找到: $path"
        ls -lh "$path"
        file "$path" | grep -i "not stripped" && echo "  ✓ 包含调试符号" || echo "  ✗ 无调试符号"
    fi
done












