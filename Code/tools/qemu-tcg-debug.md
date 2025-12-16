# QEMU TCG 翻译调试指南

## 概述

本指南介绍如何在QEMU源码级别调试TCG（Tiny Code Generator）翻译过程，特别是`ecall`和`sret`指令的翻译。

## 环境要求

- WSL Ubuntu环境
- QEMU源码
- 编译工具链（gcc, make等）

## 步骤1：获取QEMU源码

```bash
# 在WSL中，选择一个合适的位置（如 ~/qemu）
cd ~
git clone https://gitlab.com/qemu-project/qemu.git
cd qemu

# 查看当前系统使用的QEMU版本
qemu-system-riscv64 --version

# 切换到对应版本（例如v6.2.0）
git tag | grep -E "^v[0-9]+\.[0-9]+\.[0-9]+$" | tail -10
git checkout v6.2.0  # 根据实际版本调整
```

## 步骤2：编译带调试信息的QEMU

```bash
cd ~/qemu
mkdir -p build-debug
cd build-debug

# 配置编译选项，启用调试信息
../configure \
    --target-list=riscv64-softmmu \
    --enable-debug \
    --disable-strip \
    --extra-cflags="-g -O0" \
    --extra-ldflags="-g"

# 编译（可能需要较长时间）
make -j$(nproc)
```

编译完成后，QEMU可执行文件位于：`~/qemu/build-debug/riscv64-softmmu/qemu-system-riscv64`

## 步骤3：设置调试环境

### 方法1：使用编译好的调试版QEMU

修改项目的Makefile，使用调试版QEMU：

```makefile
# 在Makefile开头添加
ifndef QEMU
QEMU := ~/qemu/build-debug/riscv64-softmmu/qemu-system-riscv64
endif
```

### 方法2：创建符号链接

```bash
# 备份原QEMU（如果需要）
sudo mv /usr/bin/qemu-system-riscv64 /usr/bin/qemu-system-riscv64.orig

# 创建符号链接（或直接替换）
sudo ln -sf ~/qemu/build-debug/riscv64-softmmu/qemu-system-riscv64 /usr/bin/qemu-system-riscv64
```

## 步骤4：关键TCG翻译函数位置

在QEMU源码中，TCG翻译相关的关键文件：

1. **RISC-V指令翻译**：`target/riscv/translate.c`
   - `ecall`指令：查找`gen_ecall`或`gen_helper_ecall`
   - `sret`指令：查找`gen_sret`或`gen_helper_sret`

2. **TCG后端**：`tcg/`目录
   - TCG IR生成和优化

3. **异常处理**：`target/riscv/cpu_helper.c`
   - `riscv_cpu_do_interrupt` - 处理中断和异常

## 步骤5：三重调试设置

### 终端1：启动QEMU（带GDB服务器）

```bash
cd /mnt/e/Lab5-Edison_lab5/Code/lab5
make debug
```

这会启动QEMU并等待GDB连接（端口1234）。

### 终端2：启动QEMU源码调试（新GDB实例）

```bash
cd /mnt/e/Lab5-Edison_lab5/Code/lab5
riscv64-unknown-elf-gdb -x tools/gdb-qemu-tcg.init
```

### 终端3：启动内核调试（另一个GDB实例）

```bash
cd /mnt/e/Lab5-Edison_lab5/Code/lab5
riscv64-unknown-elf-gdb -x tools/gdb-kernel.init
```

## 步骤6：在QEMU源码中设置断点

在QEMU的GDB中：

```gdb
# 加载QEMU符号
file ~/qemu/build-debug/riscv64-softmmu/qemu-system-riscv64

# 设置断点在TCG翻译函数
break translate.c:gen_ecall
break translate.c:gen_sret
break cpu_helper.c:riscv_cpu_do_interrupt

# 或者使用函数名
break gen_helper_ecall
break gen_helper_sret

# 继续执行
continue
```

## 注意事项

1. **QEMU GDB服务器**：QEMU本身不提供GDB服务器，需要通过`gdb`附加到QEMU进程
2. **进程附加**：需要找到QEMU的PID，然后附加：
   ```bash
   ps aux | grep qemu-system-riscv64
   gdb -p <PID>
   ```
3. **符号加载**：确保加载了QEMU的调试符号文件

## 调试技巧

1. **查看TCG IR**：在翻译函数中，可以查看生成的TCG操作码
2. **跟踪执行流**：使用`step`和`next`跟踪翻译过程
3. **查看寄存器**：在QEMU中，可以查看CPU状态结构

## 常见问题

**Q: 如何知道QEMU的PID？**
A: 使用`ps aux | grep qemu`或`pgrep qemu-system-riscv64`

**Q: GDB无法附加到QEMU进程？**
A: 可能需要`sudo`权限，或者检查`/proc/sys/kernel/yama/ptrace_scope`设置

**Q: 找不到TCG翻译函数？**
A: 不同版本的QEMU函数名可能不同，使用`grep -r "ecall" target/riscv/`查找












