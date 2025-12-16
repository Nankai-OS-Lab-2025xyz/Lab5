# 快速开始：双重GDB调试系统调用

## 最简单的使用方法

### 1. 启动QEMU（终端1）

```bash
make debug
```

QEMU会启动并等待GDB连接。

### 2. 启动内核GDB（终端2）

**方法A：使用自动跟踪模式（推荐，自动显示所有系统调用）**

```bash
make gdb-trace
```

然后在GDB中：
```
(gdb) continue
```

**方法B：使用手动调试模式（可以单步执行）**

```bash
make gdb-kernel
```

然后在GDB中：
```
(gdb) continue
```

当程序在断点处停止时，可以使用：
```
(gdb) show_current_proc()
(gdb) show_trapframe(current->tf)
(gdb) syscall_name(current->tf->gpr.a0)
(gdb) step    # 单步执行
(gdb) next    # 下一行
(gdb) continue  # 继续执行
```

## 观察系统调用的关键点

### 系统调用流程中的关键位置：

1. **用户态触发**：`user/libs/syscall.c` 中的 `ecall` 指令
2. **陷阱入口**：`__alltraps` (kern/trap/trapentry.S)
3. **异常处理**：`exception_handler` (kern/trap/trap.c:205)
4. **系统调用处理**：`syscall` (kern/syscall/syscall.c:82)
5. **陷阱返回**：`__trapret` (kern/trap/trapentry.S)

### 在GDB中设置断点：

```
# 只在系统调用时停止
(gdb) break syscall

# 只在特定系统调用时停止
(gdb) break syscall if num == 18  # SYS_getpid
(gdb) break syscall if num == 2   # SYS_fork

# 观察陷阱入口
(gdb) break __alltraps

# 观察陷阱返回
(gdb) break __trapret
```

## 常用调试命令

```
# 查看当前进程
(gdb) show_current_proc()

# 查看陷阱帧
(gdb) show_trapframe(current->tf)

# 查看系统调用名称
(gdb) syscall_name(current->tf->gpr.a0)

# 查看寄存器
(gdb) info registers

# 查看调用栈
(gdb) backtrace

# 查看反汇编
(gdb) disassemble

# 单步执行汇编
(gdb) stepi

# 查看变量
(gdb) print num
(gdb) print/x arg[0]
```

## 示例：跟踪 waitkill 程序的系统调用

1. 启动QEMU：`make debug`
2. 启动GDB跟踪：`make gdb-trace`
3. 继续执行：`(gdb) continue`

你会看到所有系统调用的详细信息，包括：
- 进程ID和名称
- 系统调用号和名称
- 所有参数
- 上下文信息

## 更多信息

详细说明请查看：`tools/gdb-dual-debug.md`










