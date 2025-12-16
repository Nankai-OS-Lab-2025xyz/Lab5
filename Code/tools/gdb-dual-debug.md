# 双重GDB调试系统调用流程指南

## 概述

本指南介绍如何使用双重GDB方案来观察系统调用的完整流程，从用户态触发到内核处理，再到返回用户态的整个过程。

## 系统调用流程概览

```
用户态程序
    ↓
syscall() (user/libs/syscall.c) - 准备参数，执行 ecall 指令
    ↓
__alltraps (kern/trap/trapentry.S) - 保存上下文，切换到内核栈
    ↓
trap() (kern/trap/trap.c) - 分发异常
    ↓
exception_handler() (kern/trap/trap.c) - 处理 CAUSE_USER_ECALL
    ↓
syscall() (kern/syscall/syscall.c) - 根据系统调用号调用具体处理函数
    ↓
具体系统调用处理函数 (如 sys_fork, sys_exit 等)
    ↓
__trapret (kern/trap/trapentry.S) - 恢复上下文，返回用户态
    ↓
用户态程序继续执行
```

## 准备工作

### 1. 编译项目

```bash
make clean
make
```

### 2. 准备测试程序

选择一个包含系统调用的用户程序，例如 `waitkill.c`：

```bash
# 查看用户程序
cat user/waitkill.c
```

## 双重GDB调试步骤

### 方法一：使用两个终端窗口

#### 终端1：启动QEMU并等待GDB连接

```bash
make debug
```

这会启动QEMU，但会在启动时暂停，等待GDB连接（端口1234）。

#### 终端2：启动内核GDB

```bash
riscv64-unknown-elf-gdb -x tools/gdb-kernel.init
```

或者：

```bash
make gdb-kernel
```

在内核GDB中，你可以：

1. **查看系统调用入口点**：
   ```
   (gdb) break __alltraps
   (gdb) break exception_handler
   (gdb) break syscall
   (gdb) break __trapret
   ```

2. **继续执行**：
   ```
   (gdb) continue
   ```

3. **当程序在断点处停止时，查看信息**：
   ```
   (gdb) show_current_proc()
   (gdb) show_trapframe(current->tf)
   (gdb) syscall_name(current->tf->gpr.a0)
   ```

#### 终端3：启动用户程序GDB（可选）

如果需要调试用户程序本身，可以启动另一个GDB实例：

```bash
riscv64-unknown-elf-gdb -x tools/gdb-user.init
```

然后在内核GDB中找到用户程序的加载地址，并在用户GDB中加载符号：

```
# 在内核GDB中
(gdb) print current->mm->pgdir
(gdb) print current->mm->vma

# 在用户GDB中
(gdb) load_user_symbols obj/user/waitkill.o 0x100000
(gdb) break main
```

### 方法二：使用GDB的multi-inferior功能（推荐）

在单个GDB实例中同时调试内核和用户程序：

```bash
riscv64-unknown-elf-gdb -x tools/gdb-kernel.init
```

在GDB中：

```
# 连接到内核（inferior 1）
(gdb) target remote :1234
(gdb) file bin/kernel

# 创建第二个inferior用于用户程序
(gdb) add-inferior
(gdb) inferior 2
(gdb) file obj/user/waitkill.o

# 切换回内核inferior
(gdb) inferior 1

# 设置断点
(gdb) break __alltraps
(gdb) break syscall
(gdb) continue
```

## 关键断点和观察点

### 1. 用户态系统调用触发点

在 `user/libs/syscall.c` 的 `syscall()` 函数中，`ecall` 指令执行前：

```c
asm volatile (
    "ld a0, %1\n"
    "ld a1, %2\n"
    ...
    "ecall\n"      // <-- 这里触发系统调用
    ...
);
```

### 2. 陷阱入口点

`kern/trap/trapentry.S` 中的 `__alltraps`：

- 保存所有寄存器
- 切换到内核栈
- 调用 `trap()` 函数

### 3. 异常处理分发

`kern/trap/trap.c` 中的 `exception_handler()`：

```c
case CAUSE_USER_ECALL:  // 0x8
    tf->epc += 4;
    syscall();  // <-- 调用系统调用处理函数
    break;
```

### 4. 系统调用处理

`kern/syscall/syscall.c` 中的 `syscall()`：

- 从 trapframe 读取系统调用号和参数
- 调用对应的系统调用处理函数
- 将返回值写入 trapframe

### 5. 陷阱返回

`kern/trap/trapentry.S` 中的 `__trapret`：

- 恢复所有寄存器
- 执行 `sret` 返回用户态

## 调试技巧

### 1. 跟踪系统调用参数

在 `syscall()` 函数处设置断点：

```
(gdb) break syscall
(gdb) commands
> printf "Syscall: %d\n", num
> printf "Args: a1=0x%lx, a2=0x%lx, a3=0x%lx\n", arg[0], arg[1], arg[2]
> continue
> end
```

### 2. 观察特权级切换

检查 `sstatus` 寄存器的 `SPP` 位：

```
(gdb) print/x current->tf->status
(gdb) print (current->tf->status & 0x100) != 0  # SPP bit
```

### 3. 查看调用栈

```
(gdb) backtrace
(gdb) frame 0  # 当前帧
(gdb) frame 1  # 上一帧
```

### 4. 单步执行汇编代码

```
(gdb) stepi    # 单步执行一条汇编指令
(gdb) nexti    # 执行到下一行（跳过函数调用）
(gdb) disassemble  # 查看当前反汇编
```

### 5. 观察寄存器变化

```
(gdb) info registers
(gdb) print/x $a0  # 查看a0寄存器（系统调用号）
(gdb) print/x $a1  # 查看a1寄存器（第一个参数）
```

## 实际调试示例：跟踪 waitkill 程序的系统调用

### 1. 启动QEMU

```bash
make debug
```

### 2. 启动内核GDB

```bash
riscv64-unknown-elf-gdb -x tools/gdb-kernel.init
```

### 3. 设置条件断点

```
(gdb) break syscall if num == 18  # SYS_getpid
(gdb) break syscall if num == 2   # SYS_fork
(gdb) break syscall if num == 12   # SYS_kill
(gdb) break syscall if num == 3    # SYS_wait
```

### 4. 运行并观察

```
(gdb) continue
```

当程序在断点处停止时：

```
(gdb) show_current_proc()
(gdb) show_trapframe(current->tf)
(gdb) syscall_name(current->tf->gpr.a0)
(gdb) print current->tf->gpr.a1  # 查看参数
```

### 5. 单步跟踪系统调用处理

```
(gdb) step    # 进入系统调用处理函数
(gdb) next    # 执行下一行
(gdb) print ret  # 查看返回值
```

## 常见问题

### Q: GDB无法连接到QEMU

**A:** 确保QEMU已启动并监听1234端口：
```bash
# 检查端口
netstat -an | grep 1234
```

### Q: 无法在用户程序中设置断点

**A:** 用户程序在用户态执行，需要：
1. 在内核GDB中找到用户程序的加载地址
2. 使用 `add-symbol-file` 加载用户程序符号
3. 设置断点时使用正确的地址

### Q: 如何查看用户程序的虚拟地址空间

**A:** 在内核GDB中：
```
(gdb) print current->mm->pgdir
(gdb) print current->mm->vma
```

### Q: 系统调用返回值在哪里

**A:** 返回值存储在 `trapframe->gpr.a0` 中，在 `syscall()` 函数中设置：
```c
tf->gpr.a0 = syscalls[num](arg);
```

## 参考资料

- RISC-V特权级架构规范
- uCore操作系统实验指导书
- GDB调试手册

## 总结

通过双重GDB调试，我们可以：

1. **观察特权级切换**：从用户态(U mode)切换到内核态(S mode)
2. **跟踪参数传递**：从用户态寄存器到内核处理函数
3. **理解上下文保存**：trapframe的保存和恢复机制
4. **验证系统调用实现**：确认系统调用的正确性

这种调试方法对于深入理解操作系统内核的工作原理非常有帮助。










