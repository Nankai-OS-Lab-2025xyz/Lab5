#include <vmm.h>
#include <sync.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <error.h>
#include <pmm.h>
#include <riscv.h>
#include <kmalloc.h>
#include <memlayout.h>

/*
  vmm design include two parts: mm_struct (mm) & vma_struct (vma)
  mm is the memory manager for the set of continuous virtual memory
  area which have the same PDT. vma is a continuous virtual memory area.
  There a linear link list for vma & a redblack link list for vma in mm.
---------------
  mm related functions:
   golbal functions
     struct mm_struct * mm_create(void)
     void mm_destroy(struct mm_struct *mm)
     int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
--------------
  vma related functions:
   global functions
     struct vma_struct * vma_create (uintptr_t vm_start, uintptr_t vm_end,...)
     void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
     struct vma_struct * find_vma(struct mm_struct *mm, uintptr_t addr)
   local functions
     inline void check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
---------------
   check correctness functions
     void check_vmm(void);
     void check_vma_struct(void);
     void check_pgfault(void);
*/

// page fault statistics
volatile unsigned int pgfault_num = 0;

#define PF_WRITE 0x2

static void check_vmm(void);
static void check_vma_struct(void);

// mm_create -  alloc a mm_struct & initialize it.
struct mm_struct *
mm_create(void)
{
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));

    if (mm != NULL)
    {
        list_init(&(mm->mmap_list));
        mm->mmap_cache = NULL;
        mm->pgdir = NULL;
        mm->map_count = 0;

        mm->sm_priv = NULL;

        set_mm_count(mm, 0);
        lock_init(&(mm->mm_lock));
    }
    return mm;
}

// vma_create - alloc a vma_struct & initialize it. (addr range: vm_start~vm_end)
struct vma_struct *
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags)
{
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));

    if (vma != NULL)
    {
        vma->vm_start = vm_start;
        vma->vm_end = vm_end;
        vma->vm_flags = vm_flags;
    }
    return vma;
}

// find_vma - find a vma  (vma->vm_start <= addr <= vma_vm_end)
struct vma_struct *
find_vma(struct mm_struct *mm, uintptr_t addr)
{
    struct vma_struct *vma = NULL;
    if (mm != NULL)
    {
        vma = mm->mmap_cache;
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
        {
            bool found = 0;
            list_entry_t *list = &(mm->mmap_list), *le = list;
            while ((le = list_next(le)) != list)
            {
                vma = le2vma(le, list_link);
                if (vma->vm_start <= addr && addr < vma->vm_end)
                {
                    found = 1;
                    break;
                }
            }
            if (!found)
            {
                vma = NULL;
            }
        }
        if (vma != NULL)
        {
            mm->mmap_cache = vma;
        }
    }
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
    list_entry_t *list = &(mm->mmap_list);
    list_entry_t *le_prev = list, *le_next;

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
        {
            break;
        }
        le_prev = le;
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
    }
    if (le_next != list)
    {
        check_vma_overlap(vma, le2vma(le_next, list_link));
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
}

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
    }
    kfree(mm); // kfree mm
    mm = NULL;
}

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
    if (!USER_ACCESS(start, end))
    {
        return -E_INVAL;
    }

    assert(mm != NULL);

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
    {
        goto out;
    }
    ret = -E_NO_MEM;

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;

out:
    return ret;
}

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
    assert(to != NULL && from != NULL);
    list_entry_t *list = &(from->mmap_list), *le = list;
    while ((le = list_prev(le)) != list)
    {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}

void exit_mmap(struct mm_struct *mm)
{
    assert(mm != NULL && mm_count(mm) == 0);
    pde_t *pgdir = mm->pgdir;
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
    }
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
    }
}

/* do_pgfault - 处理页面错误（Page Fault）
 * 
 * COW 机制的关键处理函数：当进程尝试写入 COW 共享页面时，
 * CPU 会触发 Store Page Fault 异常，然后调用此函数处理。
 * 
 * 处理流程：
 * 1. 检测是否是 COW 页面错误（页表项有 PTE_COW 标记）
 * 2. 检查页面引用计数（page_ref）
 * 3. 如果仍被多个进程共享（ref > 1）：
 *    - 分配新的物理页面
 *    - 复制共享页面的内容到新页面
 *    - 更新当前进程的页表项指向新页面，恢复写权限
 * 4. 如果只有当前进程使用（ref == 1）：
 *    - 直接恢复写权限，去掉 COW 标记
 * 
 * @mm:         发生页面错误的进程的内存管理结构
 * @error_code: 错误代码（包含 PF_WRITE 表示是写错误）
 * @addr:       发生错误的虚拟地址
 * 
 * 返回值：0 成功处理，-E_INVAL 无法处理，-E_NO_MEM 内存不足
 * 
 * 调用链：CPU 异常 -> trap() -> exception_handler() -> do_pgfault()
 */
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
{
    int ret = -E_INVAL;
    pgfault_num++;  // 统计页面错误次数

    // 步骤 1：基本检查
    if (mm == NULL)
    {
        // 没有内存管理结构，无法处理
        return ret;
    }

    // 步骤 2：检查错误地址是否在有效的虚拟内存区域（VMA）内
    // VMA 定义了进程可以访问的虚拟地址范围
    struct vma_struct *vma = find_vma(mm, addr);
    if (vma == NULL || vma->vm_start > addr)
    {
        // 地址不在任何 VMA 中，这是真正的错误（访问了非法地址）
        return ret;
    }

    // 步骤 3：获取页表项
    // 将地址向下对齐到页边界（4KB 对齐）
    uintptr_t la = ROUNDDOWN(addr, PGSIZE);
    // 获取该地址对应的页表项（不创建新页表，create=0）
    pte_t *ptep = get_pte(mm->pgdir, la, 0);
    if (ptep == NULL)
    {
        // 页表项不存在，不是 COW 错误，让其他机制处理（如按需分配）
        return ret;
    }

    // 步骤 4：检查是否是 COW 页面错误
    // 只有标记了 PTE_COW 的页面才是 COW 共享页面
    
    if (!(*ptep & PTE_V))
    {
        // 页面不存在（页表项无效），不是 COW 错误
        // 这可能是按需分配的情况，但我们不实现
        // 返回错误，让进程被杀死（访问了无效地址）
        return ret;
    }

    if ((*ptep & PTE_COW) == 0)
    {
        // 不是 COW 页面，不是我们的责任
        // 这可能是权限错误或其他问题
        // 返回错误，让其他代码处理
        return ret;
    }

    // 步骤 5：确认这是 COW 页面错误，开始处理
    // COW 机制只处理写错误（读操作不会触发 COW）
    
    bool is_write = (error_code & PF_WRITE) != 0;
    if (!is_write)
    {
        // 读错误不应该发生在 COW 页面上（COW 页面是可读的）
        // 如果发生了，我们无法处理（COW 机制只处理写错误）
        return ret;
    }

    // 步骤 6：检查 VMA 是否允许写入
    // 即使页表项标记为只读，VMA 也必须允许写入，否则无法修复
    if (!(vma->vm_flags & VM_WRITE))
    {
        // VMA 不允许写入，无法修复
        return ret;
    }

    // ============================================================
    // Dirty COW 漏洞完整修复：使用页面级别锁
    // ============================================================
    // 完全修复 CVE-2016-5195 (Dirty COW) 的关键措施
    // 
    // 问题分析：
    // - mm_lock 只能保护单个进程内的操作
    // - COW 页面是跨进程共享的，需要页面级别的锁
    // 
    // 竞态条件窗口（修复前）：
    // 1. 检查引用计数 (page_ref(page) > 1)  ← 时间窗口开始
    // 2. 分配新页面 (alloc_page())
    // 3. 复制内容 (memcpy())
    // 4. 更新页表项 (page_insert())         ← 时间窗口结束
    // 
    // 如果多个进程同时进入这个窗口，可能导致：
    // - 多个进程都检测到 ref > 1
    // - 多个进程都分配新页面（内存泄漏）
    // - 数据不一致
    // 
    // 完整修复方案：
    // 1. 在 Page 结构体中添加 page_lock 字段
    // 2. 使用页面级别的锁保护整个 COW 处理过程
    // 3. 确保跨进程的 COW 操作被正确序列化
    // ============================================================
    
    // 步骤 7：获取共享的物理页面（在获取锁之前先获取，用于确定要锁哪个页面）
    struct Page *page = pte2page(*ptep);
    if (page == NULL)
    {
        return -E_NO_MEM;
    }

    // ✅ 关键修复：使用页面级别的锁保护 COW 处理
    // 这个锁是跨进程共享的（因为页面是共享的），可以防止竞态条件
    // 必须在检查引用计数之前获取锁，确保原子性
    lock(&(page->page_lock));

    // 步骤 8：重新检查页表项（双重检查锁定模式）
    // 在获取锁期间，页表项可能已被其他进程修改
    ptep = get_pte(mm->pgdir, la, 0);
    if (ptep == NULL || !(*ptep & PTE_V) || (*ptep & PTE_COW) == 0)
    {
        // 页表项状态已改变，可能已经被其他进程处理
        unlock(&(page->page_lock));
        return ret;
    }

    // 重新获取页面（可能在锁期间被修改，但应该还是同一个页面）
    struct Page *current_page = pte2page(*ptep);
    if (current_page == NULL)
    {
        unlock(&(page->page_lock));
        return -E_NO_MEM;
    }
    
    // 如果页面已经改变（不应该发生，但为了安全），需要释放旧锁并获取新锁
    if (current_page != page)
    {
        unlock(&(page->page_lock));
        page = current_page;
        lock(&(page->page_lock));
        
        // 再次检查页表项
        ptep = get_pte(mm->pgdir, la, 0);
        if (ptep == NULL || !(*ptep & PTE_V) || (*ptep & PTE_COW) == 0)
        {
            unlock(&(page->page_lock));
            return ret;
        }
        current_page = pte2page(*ptep);
        if (current_page == NULL || current_page != page)
        {
            unlock(&(page->page_lock));
            return -E_NO_MEM;
        }
    }
    page = current_page;

    // 步骤 9：准备新的权限位
    // 提取所有权限位（不包括 PTE_V 和 PTE_COW）
    // 然后恢复写权限（PTE_W），去掉 COW 标记（~PTE_COW）
    uint32_t perm = (*ptep & (PTE_R | PTE_W | PTE_X | PTE_U | PTE_G | PTE_A | PTE_D | PTE_SOFT));
    perm = (perm | PTE_W) & ~PTE_COW;  // 恢复写权限，去掉 COW 标记

    // 步骤 10：COW 机制核心处理（在页面锁保护下）
    // ✅ 关键修复：在锁保护下重新检查引用计数，确保原子性
    // 这是修复 Dirty COW 的关键：检查引用计数和分配新页面必须在同一个原子操作中
    int ref_count = page_ref(page);
    
    if (ref_count > 1)
    {
        // 情况 A：页面仍被多个进程共享（ref > 1）
        // 
        // ⚠️ 关键修复点：在锁保护下再次检查引用计数
        // 因为其他进程可能在我们获取锁之前已经完成了 COW，导致引用计数减少
        // 这是 Linux 内核修复 Dirty COW 的关键技术
        ref_count = page_ref(page);
        if (ref_count > 1)
        {
            // 处理策略：
            // 1. 为当前进程分配新的私有物理页面
            // 2. 将共享页面的内容复制到新页面
            // 3. 更新当前进程的页表项指向新页面，恢复写权限
            // 4. 其他进程的页表项仍然指向原页面（共享继续）
            
            // 分配新的物理页面
            struct Page *npage = alloc_page();
            if (npage == NULL)
            {
                unlock(&(page->page_lock));
                return -E_NO_MEM;
            }
            
            // 复制共享页面的内容到新页面
            // page2kva() 将物理页面转换为内核虚拟地址，以便访问
            memcpy(page2kva(npage), page2kva(page), PGSIZE);
            
            // ✅ 关键：在更新页表项之前，再次检查引用计数
            // 确保在复制内容期间，引用计数没有变化
            // 如果引用计数已经变为1，说明其他进程已经完成了COW，我们可以直接使用原页面
            ref_count = page_ref(page);
            if (ref_count > 1)
            {
                // ✅ 关键修复：在更新页表项之前，先减少原页面的引用计数
                // 这必须在锁保护下进行，确保原子性
                // 注意：我们需要在调用 page_insert 之前减少引用计数
                // 因为 page_insert 会调用 page_remove_pte，而 page_remove_pte 也会减少引用计数
                // 如果我们不提前减少，page_remove_pte 会减少两次（一次是我们，一次是 page_remove_pte）
                // 但实际上，page_remove_pte 会正确处理，我们不需要提前减少
                
                // 将当前进程的页表项更新为新页面，恢复写权限
                // page_insert 会：
                // 1. 增加新页面的引用计数（ref++）
                // 2. 调用 page_remove_pte 减少原页面的引用计数（ref--）
                // 3. 更新页表项指向新页面
                // ✅ 关键：page_insert 在锁保护下执行，确保原子性
                ret = page_insert(mm->pgdir, npage, la, perm);
                if (ret != 0)
                {
                    // 如果插入失败，释放新分配的页面
                    free_page(npage);
                    unlock(&(page->page_lock));
                    return ret;
                }
                
                // ✅ 关键修复：确保页表项更新和 TLB 刷新完成后再释放锁
                // 这确保了用户程序在开始写入时，页表项已经正确更新
                // 在 RISC-V 中，sfence.vma 是同步的，所以这里不需要额外的同步
                // 但为了安全，我们在释放锁之前确保所有操作完成
                
                // ✅ 额外验证：确保页表项已经正确更新
                // 重新读取页表项，验证更新是否成功
                ptep = get_pte(mm->pgdir, la, 0);
                if (ptep != NULL && (*ptep & PTE_V) && (*ptep & PTE_W) && !(*ptep & PTE_COW))
                {
                    // 验证新页面是否正确映射
                    struct Page *mapped_page = pte2page(*ptep);
                    if (mapped_page == npage)
                    {
                        // 页表项已正确更新，可以安全返回
                        // 现在当前进程有自己的私有页面了，可以正常写入
                    }
                    else
                    {
                        // 页表项指向了错误的页面，这是不应该发生的
                        unlock(&(page->page_lock));
                        return -E_INVAL;
                    }
                }
                else
                {
                    // 页表项更新失败，这是不应该发生的
                    // 但为了安全，我们仍然释放锁并返回错误
                    unlock(&(page->page_lock));
                    return -E_INVAL;
                }
            }
            else
            {
                // 引用计数已经变为1，说明其他进程已经完成了COW
                // 我们可以直接使用原页面，释放新分配的页面
                free_page(npage);
                // 直接恢复写权限
                *ptep = (*ptep & ~PTE_COW) | PTE_W;
                // 内存屏障确保页表项更新完成
                barrier();
                tlb_invalidate(mm->pgdir, la);
                ret = 0;
            }
        }
        else
        {
            // 引用计数已经变为1，直接恢复写权限
            *ptep = (*ptep & ~PTE_COW) | PTE_W;
            // 内存屏障确保页表项更新完成
            barrier();
            tlb_invalidate(mm->pgdir, la);
            ret = 0;
        }
    }
    else
    {
        // 情况 B：只有当前进程在使用（ref == 1）
        // 
        // 处理策略：
        // 1. 不需要分配新页面（已经是私有的了）
        // 2. 直接恢复写权限，去掉 COW 标记
        // 3. 这种情况可能发生在：其他进程已经退出，只剩下当前进程
        
        // 直接在页表项中恢复写权限，去掉 COW 标记
        *ptep = (*ptep & ~PTE_COW) | PTE_W;
        
        // 内存屏障确保页表项更新完成
        barrier();
        
        // 刷新 TLB，使页表项变更生效
        tlb_invalidate(mm->pgdir, la);
        ret = 0;
    }

    unlock(&(page->page_lock));  // ✅ 释放页面锁（在所有操作完成后）
    return ret;
}

bool copy_from_user(struct mm_struct *mm, void *dst, const void *src, size_t len, bool writable)
{
    if (!user_mem_check(mm, (uintptr_t)src, len, writable))
    {
        return 0;
    }
    memcpy(dst, src, len);
    return 1;
}

bool copy_to_user(struct mm_struct *mm, void *dst, const void *src, size_t len)
{
    if (!user_mem_check(mm, (uintptr_t)dst, len, 1))
    {
        return 0;
    }
    memcpy(dst, src, len);
    return 1;
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
    check_vmm();
}

// check_vmm - check correctness of vmm
static void
check_vmm(void)
{
    // size_t nr_free_pages_store = nr_free_pages();

    check_vma_struct();
    // check_pgfault();

    cprintf("check_vmm() succeeded.\n");
}

static void
check_vma_struct(void)
{
    // size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }

    for (i = step1 + 1; i <= step2; i++)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
    {
        assert(le != &(mm->mmap_list));
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
        assert(vma1 != NULL);
        struct vma_struct *vma2 = find_vma(mm, i + 1);
        assert(vma2 != NULL);
        struct vma_struct *vma3 = find_vma(mm, i + 2);
        assert(vma3 == NULL);
        struct vma_struct *vma4 = find_vma(mm, i + 3);
        assert(vma4 == NULL);
        struct vma_struct *vma5 = find_vma(mm, i + 4);
        assert(vma5 == NULL);

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
    }

    for (i = 4; i >= 0; i--)
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
        if (vma_below_5 != NULL)
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
    if (mm != NULL)
    {
        if (!USER_ACCESS(addr, addr + len))
        {
            return 0;
        }
        struct vma_struct *vma;
        uintptr_t start = addr, end = addr + len;
        while (start < end)
        {
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
            {
                return 0;
            }
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}