/*
 * dirtycow.c - Dirty COW 漏洞复现测试程序
 * 
 * 目的：复现 CVE-2016-5195 (Dirty COW) 漏洞
 * 
 * 漏洞原理：
 * 在 do_pgfault() 处理 COW 页面错误时，存在竞态条件窗口：
 * 1. 检查引用计数 (page_ref(page) > 1)
 * 2. 分配新页面 (alloc_page())
 * 3. 复制内容 (memcpy())
 * 4. 更新页表项 (page_insert())
 * 
 * 如果多个进程同时访问同一个 COW 页面，在这个时间窗口内：
 * - 多个进程可能都检测到 ref > 1
 * - 多个进程可能都分配新页面
 * - 可能导致数据不一致或内存泄漏
 * 
 * 测试方法：
 * 1. 父进程创建共享数据
 * 2. Fork 多个子进程
 * 3. 所有子进程同时写入同一个 COW 页面
 * 4. 观察是否出现竞态条件（数据不一致、panic等）
 * 
 * 修复方案：
 * 在 do_pgfault() 中使用 mm_lock 保护 COW 处理过程
 */

#include <ulib.h>
#include <stdio.h>
#include <string.h>

#define NUM_CHILDREN 4
#define TEST_ITERATIONS 100

// 共享数据页面，用于测试 COW 竞态条件
static char shared_data[4096] = "original-data";

// 子进程函数：不断写入共享数据，触发 COW
void child_worker(int id)
{
    char buffer[64];
    snprintf(buffer, sizeof(buffer), "child-%d-data", id);
    
    // 多次写入，增加触发竞态条件的概率
    for (int i = 0; i < TEST_ITERATIONS; i++)
    {
        // 写入操作会触发 COW 机制
        // 如果存在竞态条件，多个进程可能同时进入 do_pgfault()
        strcpy(shared_data, buffer);
        
        // 验证写入是否成功
        if (strncmp(shared_data, buffer, strlen(buffer)) != 0)
        {
            cprintf("[ERROR] Child %d: Data corruption detected at iteration %d!\n", id, i);
            
            // 安全输出：只显示可打印的ASCII字符，避免编码问题
            cprintf("[ERROR] Expected: ");
            // 打印 buffer 的前32个字符
            for (int j = 0; j < 32 && buffer[j] != '\0'; j++) {
                char c = buffer[j];
                if (c >= 32 && c < 127) {
                    cprintf("%c", c);
                } else {
                    cprintf("[0x%02x]", (unsigned char)c);
                }
            }
            cprintf(" (len=%d)\n", (int)strlen(buffer));
            
            cprintf("[ERROR] Got: ");
            // 打印 shared_data 的前32个字符
            for (int j = 0; j < 32 && j < sizeof(shared_data); j++) {
                char c = shared_data[j];
                if (c >= 32 && c < 127) {
                    cprintf("%c", c);
                } else if (c == '\0') {
                    cprintf("\\0");
                    break;
                } else {
                    cprintf("[0x%02x]", (unsigned char)c);
                }
            }
            cprintf("\n");
            exit(1);
        }
        
        // 短暂延迟，增加竞态条件窗口
        yield();
    }
    
    cprintf("[OK] Child %d completed %d iterations\n", id, TEST_ITERATIONS);
    exit(0);
}

int main(void)
{
    cprintf("========================================\n");
    cprintf("Dirty COW Vulnerability Test\n");
    cprintf("========================================\n");
    cprintf("\n");
    cprintf("This test attempts to reproduce the Dirty COW race condition.\n");
    cprintf("Multiple child processes will simultaneously write to a COW page.\n");
    cprintf("\n");
    
    // 初始化共享数据
    strcpy(shared_data, "original-data");
    cprintf("[INFO] Initial data: %s\n", shared_data);
    
    // Fork 多个子进程
    int pids[NUM_CHILDREN];
    for (int i = 0; i < NUM_CHILDREN; i++)
    {
        int pid = fork();
        if (pid == 0)
        {
            // 子进程：执行写入操作
            child_worker(i);
        }
        else if (pid > 0)
        {
            // 父进程：记录子进程 PID
            pids[i] = pid;
            cprintf("[INFO] Forked child %d (pid=%d)\n", i, pid);
        }
        else
        {
            cprintf("[ERROR] Fork failed for child %d\n", i);
            exit(1);
        }
    }
    
    // 父进程等待所有子进程完成
    cprintf("\n[INFO] Waiting for all children to complete...\n");
    for (int i = 0; i < NUM_CHILDREN; i++)
    {
        // 使用 wait() 等待任意子进程完成
        // 注意：wait() 返回 0 表示成功，-1 表示失败
        // 由于无法直接获取子进程 PID，我们只等待所有子进程完成
        int ret = wait();
        if (ret == 0)
        {
            // wait() 成功，子进程已退出
            // 由于无法直接获取 PID，我们只记录等待成功
        }
        else
        {
            cprintf("[WARN] wait() failed, ret=%d\n", ret);
        }
    }
    cprintf("[INFO] All children have been waited\n");
    
    // 验证父进程的数据是否被意外修改
    cprintf("\n[INFO] Verifying parent data integrity...\n");
    if (strcmp(shared_data, "original-data") == 0)
    {
        cprintf("[OK] Parent data unchanged: %s\n", shared_data);
    }
    else
    {
        cprintf("[ERROR] Parent data corrupted! Expected: original-data, Got: %s\n", shared_data);
        cprintf("[ERROR] This indicates a race condition in COW handling!\n");
        return 1;
    }
    
    cprintf("\n========================================\n");
    cprintf("Test completed.\n");
    cprintf("========================================\n");
    
    return 0;
}

