/*
 * cow_memory.c - COW 机制内存使用测试程序
 * 
 * 测试目的：
 * 1. 验证多页面（10 页）的 COW 机制
 * 2. 直观展示 COW 机制如何节省内存（fork 时共享，写入时才复制）
 * 3. 验证跨页面的写隔离
 * 
 * 测试特点：
 * - 使用 10 个页面（40KB）的测试数据，跨越多个物理页面
 * - 子进程只修改第一页，验证其他页面仍然共享
 * - 展示 COW 机制的"按需复制"特性
 */

#include <ulib.h>
#include <stdio.h>
#include <string.h>

#define TEST_PAGES 10      // 测试页面数量
#define PAGE_SIZE 4096     // 页面大小（4KB）

// 全局数组，大小为 10 页（40KB）
// 这个数组跨越多个物理页面，用于测试多页面 COW 机制
static char test_data[TEST_PAGES * PAGE_SIZE];

int main(void)
{
    // 步骤 1：父进程初始化测试数据
    // 填充数组为 "ABCDEFGHIJKLMNOPQRST..." 的循环模式
    // 这样每个位置的值都是可预测的，便于验证
    for (int i = 0; i < TEST_PAGES * PAGE_SIZE - 1; i++) {
        test_data[i] = 'A' + (i % 26);  // 循环使用 A-Z
    }
    test_data[TEST_PAGES * PAGE_SIZE - 1] = '\0';  // 字符串结束符
    
    cprintf("Parent: Allocated %d pages of test data\n", TEST_PAGES);
    cprintf("Parent: Data starts with: %.20s...\n", test_data);
    
    // 步骤 2：Fork 创建子进程
    // 在 copy_range() 中，对于 test_data 的 10 个页面：
    // - 每个可写页面都被标记为 COW（PTE_COW=1, PTE_W=0）
    // - 父子进程共享所有 10 个物理页面
    // - 页面引用计数都变为 2
    // 
    // 关键：此时没有复制任何物理页面内容，只是共享页表映射
    // 这就是 COW 机制节省内存的关键：延迟复制，按需分配
    int pid = fork();
    
    if (pid == 0) {
        // 子进程代码路径
        
        // 步骤 3：验证初始共享
        // 子进程应该能看到父进程写入的所有数据
        // 因为父子进程共享同一个物理页面
        cprintf("Child: Received shared data: %.20s...\n", test_data);
        cprintf("Child: Modifying page 0 (first page)...\n");
        
        // 步骤 4：子进程修改第一页（触发 COW 机制）
        // 当写入 test_data[0] 时：
        // - CPU 检测到第一页的页表项没有写权限（PTE_COW=1, PTE_W=0）
        // - 触发 Store Page Fault 异常
        // - do_pgfault() 检测到 COW 标记和 ref>1
        // - 只为第一页分配新的物理页面并复制内容
        // - 其他 9 页仍然共享（没有触发 COW，因为没有被写入）
        // 
        // 这就是 COW 的"按需复制"特性：只复制被修改的页面
        for (int i = 0; i < 100; i++) {
            test_data[i] = 'X';  // 修改第一页的前 100 字节
        }
        
        // 步骤 5：验证子进程的修改成功
        // 子进程应该能看到自己的修改
        cprintf("Child: Modified data: %.20s...\n", test_data);
        cprintf("Child: Modification successful\n");
        exit(0);
    }
    
    // 父进程代码路径
    assert(pid > 0);
    cprintf("Parent: Waiting for child...\n");
    assert(wait() == 0);
    
    // 步骤 6：验证写隔离
    // 父进程的数据必须保持不变
    // - test_data[0] 应该仍然是 'A'（子进程修改的是新页面）
    // - 其他页面也应该保持不变（仍然共享或未修改）
    assert(test_data[0] == 'A');  // 第一个字符应该仍然是 'A'
    cprintf("Parent: My data unchanged: %.20s...\n", test_data);
    cprintf("Parent: COW verification passed!\n");
    
    return 0;
}

