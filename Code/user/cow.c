/*
 * cow.c - 基础 COW 机制测试程序
 * 
 * 测试目的：验证 Copy-on-Write 机制的基本功能
 * 1. 验证 fork 后父子进程初始共享数据（子进程能看到父进程的数据）
 * 2. 验证子进程写入时触发 COW 复制（子进程能修改自己的数据）
 * 3. 验证写隔离（父进程的数据不受子进程修改影响）
 * 
 * 测试流程：
 * - 父进程在全局数组中写入数据
 * - Fork 创建子进程（此时父子进程共享同一个物理页面，标记为 COW）
 * - 子进程读取数据（应该看到父进程的数据，因为共享）
 * - 子进程写入数据（触发 COW 机制，分配新页面并复制）
 * - 父进程验证数据未变（写隔离成功）
 */

#include <ulib.h>
#include <stdio.h>
#include <string.h>

// 全局数组，大小为 4KB（一个页面）
// 这个数组会被父子进程共享，用于测试 COW 机制
static char shared_page[4096] = "parent-data";

int main(void)
{
    // 步骤 1：父进程在 fork 前写入数据
    // 此时 shared_page 对应的物理页面标记为可写（PTE_W=1）
    strcpy(shared_page, "parent-data");

    // 步骤 2：Fork 创建子进程
    // 在 copy_range() 中：
    // - 父子进程的页表项都指向同一个物理页面（共享）
    // - 页表项权限从 PTE_W 降级为 PTE_COW（只读，COW 标记）
    // - 页面引用计数从 1 变为 2
    int pid = fork();
    
    if (pid == 0)
    {
        // 子进程代码路径
        // 
        // 步骤 3：验证初始共享（COW 机制的关键验证点）
        // 子进程应该能看到父进程写入的数据，因为：
        // - 父子进程共享同一个物理页面
        // - 物理页面内容就是 "parent-data"
        // - 虽然页表项标记为只读（PTE_COW），但读操作是允许的
        assert(strcmp(shared_page, "parent-data") == 0);
        
        // 步骤 4：子进程尝试写入（触发 COW 机制）
        // 当执行 strcpy() 写入 shared_page 时：
        // - CPU 检测到页表项没有写权限（PTE_W=0）
        // - 触发 Store Page Fault 异常
        // - 进入 do_pgfault() 处理 COW 错误
        // - do_pgfault() 检测到 PTE_COW 标记和 ref>1
        // - 分配新的物理页面，复制内容，更新子进程页表项
        // - 子进程现在有自己的私有页面，可以正常写入
        strcpy(shared_page, "child-data");
        
        // 步骤 5：验证子进程的修改成功
        // 子进程应该能看到自己的修改，因为：
        // - COW 机制已经为子进程分配了新的私有页面
        // - 子进程的页表项现在指向新页面，并且有写权限
        assert(strcmp(shared_page, "child-data") == 0);
        exit(0);
    }

    // 父进程代码路径
    assert(pid > 0);
    
    // 步骤 6：父进程等待子进程完成
    // 在等待期间，子进程可能已经触发了 COW 机制
    assert(wait() == 0);
    
    // 步骤 7：验证写隔离（COW 机制的核心验证点）
    // 父进程的数据必须保持不变，因为：
    // - 父进程的页表项仍然指向原来的物理页面
    // - 子进程的修改只影响新分配的页面
    // - 两个进程的页表项指向不同的物理页面（写隔离）
    assert(strcmp(shared_page, "parent-data") == 0);

    cprintf("cow test passed.\n");
    return 0;
}


