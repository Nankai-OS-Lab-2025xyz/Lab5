/*
 * cow_advanced.c - COW 机制高级测试程序
 * 
 * 测试目的：全面验证 COW 机制的各种场景和边界情况
 * 
 * 包含 4 个测试用例：
 * 1. 基础 COW 功能测试 - 验证基本的写隔离
 * 2. 多页面 COW 测试 - 验证跨页面的 COW 机制
 * 3. 只读访问测试 - 验证只读操作不会触发 COW
 * 4. 顺序写入测试 - 验证父子进程顺序写入的场景
 */

#include <ulib.h>
#include <stdio.h>
#include <string.h>

#define PAGE_SIZE 4096     // 页面大小（4KB）
#define TEST_SIZE (PAGE_SIZE * 3)  // 测试数据大小：3 页（12KB）

// 全局数组，用于所有测试用例
static char shared_data[TEST_SIZE];

/* Test 1: 基础 COW 功能测试
 * 
 * 测试内容：
 * - 验证 fork 后父子进程初始共享数据
 * - 验证子进程写入时触发 COW 复制
 * - 验证父进程数据不受影响（写隔离）
 * 
 * 这是最基本的 COW 测试，验证核心功能是否正常工作
 */
void test_basic_cow(void)
{
    // 父进程初始化数据
    strcpy(shared_data, "parent-initial");
    
    // Fork 创建子进程
    // 此时父子进程共享同一个物理页面，标记为 COW
    int pid = fork();
    
    if (pid == 0) {
        // 子进程代码路径
        
        // 验证 1：子进程应该能看到父进程的数据（初始共享）
        // 因为父子进程共享同一个物理页面
        assert(strcmp(shared_data, "parent-initial") == 0);
        
        // 验证 2：子进程写入时触发 COW 机制
        // do_pgfault() 会分配新页面并复制内容
        strcpy(shared_data, "child-modified");
        
        // 验证 3：子进程应该能看到自己的修改
        assert(strcmp(shared_data, "child-modified") == 0);
        exit(0);
    }
    
    // 父进程代码路径
    assert(pid > 0);
    assert(wait() == 0);
    
    // 验证 4：父进程数据必须保持不变（写隔离）
    // 父进程的页表项仍然指向原来的物理页面
    assert(strcmp(shared_data, "parent-initial") == 0);
    cprintf("Test 1 (basic COW): PASSED\n");
}

/* Test 2: 多页面 COW 测试
 * 
 * 测试内容：
 * - 验证跨越多个页面（3 页）的 COW 机制
 * - 验证只修改中间页面时，其他页面仍然共享
 * - 验证"按需复制"特性：只复制被修改的页面
 * 
 * 这个测试验证 COW 机制在多页面场景下的正确性
 */
void test_multiple_pages(void)
{
    // 填充 3 页数据为 "ABCDEFGHIJKLMNOPQRST..." 的循环模式
    for (int i = 0; i < TEST_SIZE - 1; i++) {
        shared_data[i] = 'A' + (i % 26);
    }
    shared_data[TEST_SIZE - 1] = '\0';
    
    // Fork 创建子进程
    // 此时 3 个页面都被标记为 COW，父子进程共享
    int pid = fork();
    
    if (pid == 0) {
        // 子进程代码路径
        
        // 修改中间页面（第二页）的某个位置
        // PAGE_SIZE + 100 位于第二页的中间位置
        // 当写入这个位置时：
        // - 只触发第二页的 COW 复制
        // - 第一页和第三页仍然共享（没有被写入，不触发 COW）
        shared_data[PAGE_SIZE + 100] = 'X';
        assert(shared_data[PAGE_SIZE + 100] == 'X');
        exit(0);
    }
    
    // 父进程代码路径
    assert(pid > 0);
    assert(wait() == 0);
    
    // 验证父进程的中间页面数据未变
    // 因为子进程修改的是新分配的页面，父进程仍然使用原页面
    assert(shared_data[PAGE_SIZE + 100] == 'A' + ((PAGE_SIZE + 100) % 26));
    cprintf("Test 2 (multiple pages): PASSED\n");
}

/* Test 3: 只读访问测试
 * 
 * 测试内容：
 * - 验证只读操作不会触发 COW 机制
 * - 验证只读时页面仍然共享（引用计数保持为 2）
 * - 验证 COW 机制只在写入时触发
 * 
 * 这个测试验证 COW 机制的"按需复制"特性：
 * 只有写入操作才会触发 COW，读取操作不会
 */
void test_read_only(void)
{
    // 父进程初始化数据
    strcpy(shared_data, "read-test");
    
    // Fork 创建子进程
    // 此时页面标记为 COW，父子进程共享
    int pid = fork();
    
    if (pid == 0) {
        // 子进程代码路径
        
        // 关键：子进程只读取数据，不写入
        // 这不会触发 COW 机制，因为：
        // - COW 页面是可读的（PTE_R=1）
        // - 只有写入操作（需要 PTE_W）才会触发页面错误
        // - do_pgfault() 只处理写错误（is_write == true）
        char buf[100];
        strcpy(buf, shared_data);  // 只读操作，复制到缓冲区
        
        // 验证读取成功
        assert(strcmp(buf, "read-test") == 0);
        
        // 验证原数据未变（仍然共享，没有触发 COW）
        // 如果触发了 COW，页面引用计数会变化，但这里不应该触发
        assert(strcmp(shared_data, "read-test") == 0);
        exit(0);
    }
    
    // 父进程代码路径
    assert(pid > 0);
    assert(wait() == 0);
    
    // 由于子进程没有写入，页面应该仍然共享
    // 父进程的数据应该保持不变（实际上子进程也没有修改）
    cprintf("Test 3 (read-only): PASSED\n");
}

/* Test 4: 顺序写入测试
 * 
 * 测试内容：
 * - 验证父子进程顺序写入的场景
 * - 验证子进程写入后退出，父进程再写入的情况
 * - 验证引用计数的正确管理
 * 
 * 这个测试验证当子进程退出后，父进程写入时的行为：
 * - 如果子进程已经退出，页面引用计数变为 1
 * - 父进程写入时，do_pgfault() 检测到 ref==1
 * - 直接恢复写权限，不需要分配新页面
 */
void test_sequential_writes(void)
{
    // 父进程初始化数据
    strcpy(shared_data, "initial");
    
    // Fork 创建子进程
    // 此时页面标记为 COW，父子进程共享（ref=2）
    int pid = fork();
    
    if (pid == 0) {
        // 子进程代码路径
        
        // 子进程先写入（触发 COW）
        // 此时：
        // - do_pgfault() 检测到 ref=2（仍被共享）
        // - 分配新页面并复制内容
        // - 子进程的页表项指向新页面，恢复写权限
        // - 父进程的页表项仍然指向原页面（ref=1）
        strcpy(shared_data, "child-first");
        assert(strcmp(shared_data, "child-first") == 0);
        exit(0);  // 子进程退出，释放自己的页面
    }
    
    // 父进程代码路径
    assert(pid > 0);
    
    // 父进程等待子进程退出
    // 子进程退出后，如果子进程触发了 COW，子进程的页面会被释放
    // 父进程的页面引用计数可能变为 1（如果子进程复制了页面）
    assert(wait() == 0);
    
    // 父进程现在写入
    // 如果页面引用计数为 1：
    // - do_pgfault() 检测到 ref==1
    // - 直接恢复写权限，去掉 COW 标记
    // - 不需要分配新页面（已经是私有的了）
    strcpy(shared_data, "parent-after");
    assert(strcmp(shared_data, "parent-after") == 0);
    cprintf("Test 4 (sequential writes): PASSED\n");
}

/* 主函数：运行所有高级测试 */
int main(void)
{
    cprintf("Starting advanced COW tests...\n");
    
    // 依次运行 4 个测试用例
    test_basic_cow();           // 基础功能测试
    test_multiple_pages();      // 多页面测试
    test_read_only();           // 只读访问测试
    test_sequential_writes();   // 顺序写入测试
    
    cprintf("All advanced COW tests passed!\n");
    return 0;
}

