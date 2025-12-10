
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	000a6517          	auipc	a0,0xa6
ffffffffc020004e:	24650513          	addi	a0,a0,582 # ffffffffc02a6290 <buf>
ffffffffc0200052:	000aa617          	auipc	a2,0xaa
ffffffffc0200056:	6e260613          	addi	a2,a2,1762 # ffffffffc02aa734 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	658050ef          	jal	ra,ffffffffc02056ba <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00005597          	auipc	a1,0x5
ffffffffc0200072:	67a58593          	addi	a1,a1,1658 # ffffffffc02056e8 <etext+0x4>
ffffffffc0200076:	00005517          	auipc	a0,0x5
ffffffffc020007a:	69250513          	addi	a0,a0,1682 # ffffffffc0205708 <etext+0x24>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	69c020ef          	jal	ra,ffffffffc0202722 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	169030ef          	jal	ra,ffffffffc02039fa <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	577040ef          	jal	ra,ffffffffc0204e0c <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	703040ef          	jal	ra,ffffffffc0204fa4 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00005517          	auipc	a0,0x5
ffffffffc02000c0:	65450513          	addi	a0,a0,1620 # ffffffffc0205710 <etext+0x2c>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	000a6b97          	auipc	s7,0xa6
ffffffffc02000d6:	1beb8b93          	addi	s7,s7,446 # ffffffffc02a6290 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	12e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	11e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	10c000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	000a6517          	auipc	a0,0xa6
ffffffffc0200132:	16250513          	addi	a0,a0,354 # ffffffffc02a6290 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	42c000ef          	jal	ra,ffffffffc020058e <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	10e050ef          	jal	ra,ffffffffc0205296 <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc020a028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	0d8050ef          	jal	ra,ffffffffc0205296 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a6d1                	j	ffffffffc020058e <cons_putc>

ffffffffc02001cc <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001cc:	1101                	addi	sp,sp,-32
ffffffffc02001ce:	e822                	sd	s0,16(sp)
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e426                	sd	s1,8(sp)
ffffffffc02001d4:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d6:	00054503          	lbu	a0,0(a0)
ffffffffc02001da:	c51d                	beqz	a0,ffffffffc0200208 <cputs+0x3c>
ffffffffc02001dc:	0405                	addi	s0,s0,1
ffffffffc02001de:	4485                	li	s1,1
ffffffffc02001e0:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001e2:	3ac000ef          	jal	ra,ffffffffc020058e <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e6:	00044503          	lbu	a0,0(s0)
ffffffffc02001ea:	008487bb          	addw	a5,s1,s0
ffffffffc02001ee:	0405                	addi	s0,s0,1
ffffffffc02001f0:	f96d                	bnez	a0,ffffffffc02001e2 <cputs+0x16>
    (*cnt)++;
ffffffffc02001f2:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001f6:	4529                	li	a0,10
ffffffffc02001f8:	396000ef          	jal	ra,ffffffffc020058e <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fc:	60e2                	ld	ra,24(sp)
ffffffffc02001fe:	8522                	mv	a0,s0
ffffffffc0200200:	6442                	ld	s0,16(sp)
ffffffffc0200202:	64a2                	ld	s1,8(sp)
ffffffffc0200204:	6105                	addi	sp,sp,32
ffffffffc0200206:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc0200208:	4405                	li	s0,1
ffffffffc020020a:	b7f5                	j	ffffffffc02001f6 <cputs+0x2a>

ffffffffc020020c <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020020c:	1141                	addi	sp,sp,-16
ffffffffc020020e:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200210:	3b2000ef          	jal	ra,ffffffffc02005c2 <cons_getc>
ffffffffc0200214:	dd75                	beqz	a0,ffffffffc0200210 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200216:	60a2                	ld	ra,8(sp)
ffffffffc0200218:	0141                	addi	sp,sp,16
ffffffffc020021a:	8082                	ret

ffffffffc020021c <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc020021c:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020021e:	00005517          	auipc	a0,0x5
ffffffffc0200222:	4fa50513          	addi	a0,a0,1274 # ffffffffc0205718 <etext+0x34>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00005517          	auipc	a0,0x5
ffffffffc0200238:	50450513          	addi	a0,a0,1284 # ffffffffc0205738 <etext+0x54>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00005597          	auipc	a1,0x5
ffffffffc0200244:	4a458593          	addi	a1,a1,1188 # ffffffffc02056e4 <etext>
ffffffffc0200248:	00005517          	auipc	a0,0x5
ffffffffc020024c:	51050513          	addi	a0,a0,1296 # ffffffffc0205758 <etext+0x74>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000a6597          	auipc	a1,0xa6
ffffffffc0200258:	03c58593          	addi	a1,a1,60 # ffffffffc02a6290 <buf>
ffffffffc020025c:	00005517          	auipc	a0,0x5
ffffffffc0200260:	51c50513          	addi	a0,a0,1308 # ffffffffc0205778 <etext+0x94>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000aa597          	auipc	a1,0xaa
ffffffffc020026c:	4cc58593          	addi	a1,a1,1228 # ffffffffc02aa734 <end>
ffffffffc0200270:	00005517          	auipc	a0,0x5
ffffffffc0200274:	52850513          	addi	a0,a0,1320 # ffffffffc0205798 <etext+0xb4>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000ab597          	auipc	a1,0xab
ffffffffc0200280:	8b758593          	addi	a1,a1,-1865 # ffffffffc02aab33 <end+0x3ff>
ffffffffc0200284:	00000797          	auipc	a5,0x0
ffffffffc0200288:	dc678793          	addi	a5,a5,-570 # ffffffffc020004a <kern_init>
ffffffffc020028c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200290:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200294:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200296:	3ff5f593          	andi	a1,a1,1023
ffffffffc020029a:	95be                	add	a1,a1,a5
ffffffffc020029c:	85a9                	srai	a1,a1,0xa
ffffffffc020029e:	00005517          	auipc	a0,0x5
ffffffffc02002a2:	51a50513          	addi	a0,a0,1306 # ffffffffc02057b8 <etext+0xd4>
}
ffffffffc02002a6:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a8:	b5f5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002aa <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002aa:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002ac:	00005617          	auipc	a2,0x5
ffffffffc02002b0:	53c60613          	addi	a2,a2,1340 # ffffffffc02057e8 <etext+0x104>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00005517          	auipc	a0,0x5
ffffffffc02002bc:	54850513          	addi	a0,a0,1352 # ffffffffc0205800 <etext+0x11c>
{
ffffffffc02002c0:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002c2:	1cc000ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02002c6 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02002c6:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002c8:	00005617          	auipc	a2,0x5
ffffffffc02002cc:	55060613          	addi	a2,a2,1360 # ffffffffc0205818 <etext+0x134>
ffffffffc02002d0:	00005597          	auipc	a1,0x5
ffffffffc02002d4:	56858593          	addi	a1,a1,1384 # ffffffffc0205838 <etext+0x154>
ffffffffc02002d8:	00005517          	auipc	a0,0x5
ffffffffc02002dc:	56850513          	addi	a0,a0,1384 # ffffffffc0205840 <etext+0x15c>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00005617          	auipc	a2,0x5
ffffffffc02002ea:	56a60613          	addi	a2,a2,1386 # ffffffffc0205850 <etext+0x16c>
ffffffffc02002ee:	00005597          	auipc	a1,0x5
ffffffffc02002f2:	58a58593          	addi	a1,a1,1418 # ffffffffc0205878 <etext+0x194>
ffffffffc02002f6:	00005517          	auipc	a0,0x5
ffffffffc02002fa:	54a50513          	addi	a0,a0,1354 # ffffffffc0205840 <etext+0x15c>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00005617          	auipc	a2,0x5
ffffffffc0200306:	58660613          	addi	a2,a2,1414 # ffffffffc0205888 <etext+0x1a4>
ffffffffc020030a:	00005597          	auipc	a1,0x5
ffffffffc020030e:	59e58593          	addi	a1,a1,1438 # ffffffffc02058a8 <etext+0x1c4>
ffffffffc0200312:	00005517          	auipc	a0,0x5
ffffffffc0200316:	52e50513          	addi	a0,a0,1326 # ffffffffc0205840 <etext+0x15c>
ffffffffc020031a:	e7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc020031e:	60a2                	ld	ra,8(sp)
ffffffffc0200320:	4501                	li	a0,0
ffffffffc0200322:	0141                	addi	sp,sp,16
ffffffffc0200324:	8082                	ret

ffffffffc0200326 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200326:	1141                	addi	sp,sp,-16
ffffffffc0200328:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020032a:	ef3ff0ef          	jal	ra,ffffffffc020021c <print_kerninfo>
    return 0;
}
ffffffffc020032e:	60a2                	ld	ra,8(sp)
ffffffffc0200330:	4501                	li	a0,0
ffffffffc0200332:	0141                	addi	sp,sp,16
ffffffffc0200334:	8082                	ret

ffffffffc0200336 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200336:	1141                	addi	sp,sp,-16
ffffffffc0200338:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020033a:	f71ff0ef          	jal	ra,ffffffffc02002aa <print_stackframe>
    return 0;
}
ffffffffc020033e:	60a2                	ld	ra,8(sp)
ffffffffc0200340:	4501                	li	a0,0
ffffffffc0200342:	0141                	addi	sp,sp,16
ffffffffc0200344:	8082                	ret

ffffffffc0200346 <kmonitor>:
{
ffffffffc0200346:	7115                	addi	sp,sp,-224
ffffffffc0200348:	ed5e                	sd	s7,152(sp)
ffffffffc020034a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020034c:	00005517          	auipc	a0,0x5
ffffffffc0200350:	56c50513          	addi	a0,a0,1388 # ffffffffc02058b8 <etext+0x1d4>
{
ffffffffc0200354:	ed86                	sd	ra,216(sp)
ffffffffc0200356:	e9a2                	sd	s0,208(sp)
ffffffffc0200358:	e5a6                	sd	s1,200(sp)
ffffffffc020035a:	e1ca                	sd	s2,192(sp)
ffffffffc020035c:	fd4e                	sd	s3,184(sp)
ffffffffc020035e:	f952                	sd	s4,176(sp)
ffffffffc0200360:	f556                	sd	s5,168(sp)
ffffffffc0200362:	f15a                	sd	s6,160(sp)
ffffffffc0200364:	e962                	sd	s8,144(sp)
ffffffffc0200366:	e566                	sd	s9,136(sp)
ffffffffc0200368:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036a:	e2bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020036e:	00005517          	auipc	a0,0x5
ffffffffc0200372:	57250513          	addi	a0,a0,1394 # ffffffffc02058e0 <etext+0x1fc>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00005c17          	auipc	s8,0x5
ffffffffc0200388:	5ccc0c13          	addi	s8,s8,1484 # ffffffffc0205950 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00005917          	auipc	s2,0x5
ffffffffc0200390:	57c90913          	addi	s2,s2,1404 # ffffffffc0205908 <etext+0x224>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00005497          	auipc	s1,0x5
ffffffffc0200398:	57c48493          	addi	s1,s1,1404 # ffffffffc0205910 <etext+0x22c>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00005b17          	auipc	s6,0x5
ffffffffc02003a2:	57ab0b13          	addi	s6,s6,1402 # ffffffffc0205918 <etext+0x234>
        argv[argc++] = buf;
ffffffffc02003a6:	00005a17          	auipc	s4,0x5
ffffffffc02003aa:	492a0a13          	addi	s4,s4,1170 # ffffffffc0205838 <etext+0x154>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003ae:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL)
ffffffffc02003b0:	854a                	mv	a0,s2
ffffffffc02003b2:	cf5ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc02003b6:	842a                	mv	s0,a0
ffffffffc02003b8:	dd65                	beqz	a0,ffffffffc02003b0 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003ba:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003be:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003c0:	e1bd                	bnez	a1,ffffffffc0200426 <kmonitor+0xe0>
    if (argc == 0)
ffffffffc02003c2:	fe0c87e3          	beqz	s9,ffffffffc02003b0 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003c6:	6582                	ld	a1,0(sp)
ffffffffc02003c8:	00005d17          	auipc	s10,0x5
ffffffffc02003cc:	588d0d13          	addi	s10,s10,1416 # ffffffffc0205950 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	28a050ef          	jal	ra,ffffffffc0205660 <strcmp>
ffffffffc02003da:	c919                	beqz	a0,ffffffffc02003f0 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003dc:	2405                	addiw	s0,s0,1
ffffffffc02003de:	0b540063          	beq	s0,s5,ffffffffc020047e <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003e2:	000d3503          	ld	a0,0(s10)
ffffffffc02003e6:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003e8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003ea:	276050ef          	jal	ra,ffffffffc0205660 <strcmp>
ffffffffc02003ee:	f57d                	bnez	a0,ffffffffc02003dc <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003f0:	00141793          	slli	a5,s0,0x1
ffffffffc02003f4:	97a2                	add	a5,a5,s0
ffffffffc02003f6:	078e                	slli	a5,a5,0x3
ffffffffc02003f8:	97e2                	add	a5,a5,s8
ffffffffc02003fa:	6b9c                	ld	a5,16(a5)
ffffffffc02003fc:	865e                	mv	a2,s7
ffffffffc02003fe:	002c                	addi	a1,sp,8
ffffffffc0200400:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200404:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc0200406:	fa0555e3          	bgez	a0,ffffffffc02003b0 <kmonitor+0x6a>
}
ffffffffc020040a:	60ee                	ld	ra,216(sp)
ffffffffc020040c:	644e                	ld	s0,208(sp)
ffffffffc020040e:	64ae                	ld	s1,200(sp)
ffffffffc0200410:	690e                	ld	s2,192(sp)
ffffffffc0200412:	79ea                	ld	s3,184(sp)
ffffffffc0200414:	7a4a                	ld	s4,176(sp)
ffffffffc0200416:	7aaa                	ld	s5,168(sp)
ffffffffc0200418:	7b0a                	ld	s6,160(sp)
ffffffffc020041a:	6bea                	ld	s7,152(sp)
ffffffffc020041c:	6c4a                	ld	s8,144(sp)
ffffffffc020041e:	6caa                	ld	s9,136(sp)
ffffffffc0200420:	6d0a                	ld	s10,128(sp)
ffffffffc0200422:	612d                	addi	sp,sp,224
ffffffffc0200424:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200426:	8526                	mv	a0,s1
ffffffffc0200428:	27c050ef          	jal	ra,ffffffffc02056a4 <strchr>
ffffffffc020042c:	c901                	beqz	a0,ffffffffc020043c <kmonitor+0xf6>
ffffffffc020042e:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc0200432:	00040023          	sb	zero,0(s0)
ffffffffc0200436:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200438:	d5c9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc020043a:	b7f5                	j	ffffffffc0200426 <kmonitor+0xe0>
        if (*buf == '\0')
ffffffffc020043c:	00044783          	lbu	a5,0(s0)
ffffffffc0200440:	d3c9                	beqz	a5,ffffffffc02003c2 <kmonitor+0x7c>
        if (argc == MAXARGS - 1)
ffffffffc0200442:	033c8963          	beq	s9,s3,ffffffffc0200474 <kmonitor+0x12e>
        argv[argc++] = buf;
ffffffffc0200446:	003c9793          	slli	a5,s9,0x3
ffffffffc020044a:	0118                	addi	a4,sp,128
ffffffffc020044c:	97ba                	add	a5,a5,a4
ffffffffc020044e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200452:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc0200456:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200458:	e591                	bnez	a1,ffffffffc0200464 <kmonitor+0x11e>
ffffffffc020045a:	b7b5                	j	ffffffffc02003c6 <kmonitor+0x80>
ffffffffc020045c:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc0200460:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200462:	d1a5                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200464:	8526                	mv	a0,s1
ffffffffc0200466:	23e050ef          	jal	ra,ffffffffc02056a4 <strchr>
ffffffffc020046a:	d96d                	beqz	a0,ffffffffc020045c <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020046c:	00044583          	lbu	a1,0(s0)
ffffffffc0200470:	d9a9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200472:	bf55                	j	ffffffffc0200426 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200474:	45c1                	li	a1,16
ffffffffc0200476:	855a                	mv	a0,s6
ffffffffc0200478:	d1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc020047c:	b7e9                	j	ffffffffc0200446 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020047e:	6582                	ld	a1,0(sp)
ffffffffc0200480:	00005517          	auipc	a0,0x5
ffffffffc0200484:	4b850513          	addi	a0,a0,1208 # ffffffffc0205938 <etext+0x254>
ffffffffc0200488:	d0dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc020048c:	b715                	j	ffffffffc02003b0 <kmonitor+0x6a>

ffffffffc020048e <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc020048e:	000aa317          	auipc	t1,0xaa
ffffffffc0200492:	22a30313          	addi	t1,t1,554 # ffffffffc02aa6b8 <is_panic>
ffffffffc0200496:	00033e03          	ld	t3,0(t1)
{
ffffffffc020049a:	715d                	addi	sp,sp,-80
ffffffffc020049c:	ec06                	sd	ra,24(sp)
ffffffffc020049e:	e822                	sd	s0,16(sp)
ffffffffc02004a0:	f436                	sd	a3,40(sp)
ffffffffc02004a2:	f83a                	sd	a4,48(sp)
ffffffffc02004a4:	fc3e                	sd	a5,56(sp)
ffffffffc02004a6:	e0c2                	sd	a6,64(sp)
ffffffffc02004a8:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc02004aa:	020e1a63          	bnez	t3,ffffffffc02004de <__panic+0x50>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004ae:	4785                	li	a5,1
ffffffffc02004b0:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b4:	8432                	mv	s0,a2
ffffffffc02004b6:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b8:	862e                	mv	a2,a1
ffffffffc02004ba:	85aa                	mv	a1,a0
ffffffffc02004bc:	00005517          	auipc	a0,0x5
ffffffffc02004c0:	4dc50513          	addi	a0,a0,1244 # ffffffffc0205998 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c4:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004c6:	ccfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ca:	65a2                	ld	a1,8(sp)
ffffffffc02004cc:	8522                	mv	a0,s0
ffffffffc02004ce:	ca7ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004d2:	00006517          	auipc	a0,0x6
ffffffffc02004d6:	5be50513          	addi	a0,a0,1470 # ffffffffc0206a90 <default_pmm_manager+0x578>
ffffffffc02004da:	cbbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004de:	4501                	li	a0,0
ffffffffc02004e0:	4581                	li	a1,0
ffffffffc02004e2:	4601                	li	a2,0
ffffffffc02004e4:	48a1                	li	a7,8
ffffffffc02004e6:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ea:	4ca000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc02004ee:	4501                	li	a0,0
ffffffffc02004f0:	e57ff0ef          	jal	ra,ffffffffc0200346 <kmonitor>
    while (1)
ffffffffc02004f4:	bfed                	j	ffffffffc02004ee <__panic+0x60>

ffffffffc02004f6 <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc02004f6:	715d                	addi	sp,sp,-80
ffffffffc02004f8:	832e                	mv	t1,a1
ffffffffc02004fa:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004fc:	85aa                	mv	a1,a0
{
ffffffffc02004fe:	8432                	mv	s0,a2
ffffffffc0200500:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200502:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200504:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	00005517          	auipc	a0,0x5
ffffffffc020050a:	4b250513          	addi	a0,a0,1202 # ffffffffc02059b8 <commands+0x68>
{
ffffffffc020050e:	ec06                	sd	ra,24(sp)
ffffffffc0200510:	f436                	sd	a3,40(sp)
ffffffffc0200512:	f83a                	sd	a4,48(sp)
ffffffffc0200514:	e0c2                	sd	a6,64(sp)
ffffffffc0200516:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200518:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051a:	c7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020051e:	65a2                	ld	a1,8(sp)
ffffffffc0200520:	8522                	mv	a0,s0
ffffffffc0200522:	c53ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc0200526:	00006517          	auipc	a0,0x6
ffffffffc020052a:	56a50513          	addi	a0,a0,1386 # ffffffffc0206a90 <default_pmm_manager+0x578>
ffffffffc020052e:	c67ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);
}
ffffffffc0200532:	60e2                	ld	ra,24(sp)
ffffffffc0200534:	6442                	ld	s0,16(sp)
ffffffffc0200536:	6161                	addi	sp,sp,80
ffffffffc0200538:	8082                	ret

ffffffffc020053a <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc020053a:	67e1                	lui	a5,0x18
ffffffffc020053c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xd580>
ffffffffc0200540:	000aa717          	auipc	a4,0xaa
ffffffffc0200544:	18f73423          	sd	a5,392(a4) # ffffffffc02aa6c8 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200548:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020054c:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020054e:	953e                	add	a0,a0,a5
ffffffffc0200550:	4601                	li	a2,0
ffffffffc0200552:	4881                	li	a7,0
ffffffffc0200554:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200558:	02000793          	li	a5,32
ffffffffc020055c:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc0200560:	00005517          	auipc	a0,0x5
ffffffffc0200564:	47850513          	addi	a0,a0,1144 # ffffffffc02059d8 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000aa797          	auipc	a5,0xaa
ffffffffc020056c:	1407bc23          	sd	zero,344(a5) # ffffffffc02aa6c0 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000aa797          	auipc	a5,0xaa
ffffffffc020057a:	1527b783          	ld	a5,338(a5) # ffffffffc02aa6c8 <timebase>
ffffffffc020057e:	953e                	add	a0,a0,a5
ffffffffc0200580:	4581                	li	a1,0
ffffffffc0200582:	4601                	li	a2,0
ffffffffc0200584:	4881                	li	a7,0
ffffffffc0200586:	00000073          	ecall
ffffffffc020058a:	8082                	ret

ffffffffc020058c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020058c:	8082                	ret

ffffffffc020058e <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020058e:	100027f3          	csrr	a5,sstatus
ffffffffc0200592:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200594:	0ff57513          	zext.b	a0,a0
ffffffffc0200598:	e799                	bnez	a5,ffffffffc02005a6 <cons_putc+0x18>
ffffffffc020059a:	4581                	li	a1,0
ffffffffc020059c:	4601                	li	a2,0
ffffffffc020059e:	4885                	li	a7,1
ffffffffc02005a0:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc02005a4:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a6:	1101                	addi	sp,sp,-32
ffffffffc02005a8:	ec06                	sd	ra,24(sp)
ffffffffc02005aa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005ac:	408000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005b0:	6522                	ld	a0,8(sp)
ffffffffc02005b2:	4581                	li	a1,0
ffffffffc02005b4:	4601                	li	a2,0
ffffffffc02005b6:	4885                	li	a7,1
ffffffffc02005b8:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005bc:	60e2                	ld	ra,24(sp)
ffffffffc02005be:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc02005c0:	a6fd                	j	ffffffffc02009ae <intr_enable>

ffffffffc02005c2 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02005c2:	100027f3          	csrr	a5,sstatus
ffffffffc02005c6:	8b89                	andi	a5,a5,2
ffffffffc02005c8:	eb89                	bnez	a5,ffffffffc02005da <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005ca:	4501                	li	a0,0
ffffffffc02005cc:	4581                	li	a1,0
ffffffffc02005ce:	4601                	li	a2,0
ffffffffc02005d0:	4889                	li	a7,2
ffffffffc02005d2:	00000073          	ecall
ffffffffc02005d6:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d8:	8082                	ret
int cons_getc(void) {
ffffffffc02005da:	1101                	addi	sp,sp,-32
ffffffffc02005dc:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005de:	3d6000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005e2:	4501                	li	a0,0
ffffffffc02005e4:	4581                	li	a1,0
ffffffffc02005e6:	4601                	li	a2,0
ffffffffc02005e8:	4889                	li	a7,2
ffffffffc02005ea:	00000073          	ecall
ffffffffc02005ee:	2501                	sext.w	a0,a0
ffffffffc02005f0:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005f2:	3bc000ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc02005f6:	60e2                	ld	ra,24(sp)
ffffffffc02005f8:	6522                	ld	a0,8(sp)
ffffffffc02005fa:	6105                	addi	sp,sp,32
ffffffffc02005fc:	8082                	ret

ffffffffc02005fe <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005fe:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200600:	00005517          	auipc	a0,0x5
ffffffffc0200604:	3f850513          	addi	a0,a0,1016 # ffffffffc02059f8 <commands+0xa8>
void dtb_init(void) {
ffffffffc0200608:	fc86                	sd	ra,120(sp)
ffffffffc020060a:	f8a2                	sd	s0,112(sp)
ffffffffc020060c:	e8d2                	sd	s4,80(sp)
ffffffffc020060e:	f4a6                	sd	s1,104(sp)
ffffffffc0200610:	f0ca                	sd	s2,96(sp)
ffffffffc0200612:	ecce                	sd	s3,88(sp)
ffffffffc0200614:	e4d6                	sd	s5,72(sp)
ffffffffc0200616:	e0da                	sd	s6,64(sp)
ffffffffc0200618:	fc5e                	sd	s7,56(sp)
ffffffffc020061a:	f862                	sd	s8,48(sp)
ffffffffc020061c:	f466                	sd	s9,40(sp)
ffffffffc020061e:	f06a                	sd	s10,32(sp)
ffffffffc0200620:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200622:	b73ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200626:	0000b597          	auipc	a1,0xb
ffffffffc020062a:	9da5b583          	ld	a1,-1574(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc020062e:	00005517          	auipc	a0,0x5
ffffffffc0200632:	3da50513          	addi	a0,a0,986 # ffffffffc0205a08 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000b417          	auipc	s0,0xb
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020b008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00005517          	auipc	a0,0x5
ffffffffc0200648:	3d450513          	addi	a0,a0,980 # ffffffffc0205a18 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00005517          	auipc	a0,0x5
ffffffffc0200658:	3dc50513          	addi	a0,a0,988 # ffffffffc0205a30 <commands+0xe0>
    if (boot_dtb == 0) {
ffffffffc020065c:	120a0463          	beqz	s4,ffffffffc0200784 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200660:	57f5                	li	a5,-3
ffffffffc0200662:	07fa                	slli	a5,a5,0x1e
ffffffffc0200664:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200668:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020066e:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200670:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200674:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067c:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200686:	8ec9                	or	a3,a3,a0
ffffffffc0200688:	0087979b          	slliw	a5,a5,0x8
ffffffffc020068c:	1b7d                	addi	s6,s6,-1
ffffffffc020068e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200692:	8dd5                	or	a1,a1,a3
ffffffffc0200694:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200696:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe357b9>
ffffffffc02006a0:	10f59163          	bne	a1,a5,ffffffffc02007a2 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02006a4:	471c                	lw	a5,8(a4)
ffffffffc02006a6:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02006a8:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006aa:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006ae:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02006b2:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c2:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ce:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d2:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d4:	01146433          	or	s0,s0,a7
ffffffffc02006d8:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006dc:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e0:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e6:	8c49                	or	s0,s0,a0
ffffffffc02006e8:	0166f6b3          	and	a3,a3,s6
ffffffffc02006ec:	00ca6a33          	or	s4,s4,a2
ffffffffc02006f0:	0167f7b3          	and	a5,a5,s6
ffffffffc02006f4:	8c55                	or	s0,s0,a3
ffffffffc02006f6:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fa:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006fc:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fe:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200700:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200704:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200706:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200708:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020070c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020070e:	00005917          	auipc	s2,0x5
ffffffffc0200712:	37290913          	addi	s2,s2,882 # ffffffffc0205a80 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00005497          	auipc	s1,0x5
ffffffffc0200720:	35c48493          	addi	s1,s1,860 # ffffffffc0205a78 <commands+0x128>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200724:	000a2703          	lw	a4,0(s4)
ffffffffc0200728:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072c:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200730:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200734:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200738:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073c:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200740:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200742:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200746:	0087171b          	slliw	a4,a4,0x8
ffffffffc020074a:	8fd5                	or	a5,a5,a3
ffffffffc020074c:	00eb7733          	and	a4,s6,a4
ffffffffc0200750:	8fd9                	or	a5,a5,a4
ffffffffc0200752:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200754:	09778c63          	beq	a5,s7,ffffffffc02007ec <dtb_init+0x1ee>
ffffffffc0200758:	00fbea63          	bltu	s7,a5,ffffffffc020076c <dtb_init+0x16e>
ffffffffc020075c:	07a78663          	beq	a5,s10,ffffffffc02007c8 <dtb_init+0x1ca>
ffffffffc0200760:	4709                	li	a4,2
ffffffffc0200762:	00e79763          	bne	a5,a4,ffffffffc0200770 <dtb_init+0x172>
ffffffffc0200766:	4c81                	li	s9,0
ffffffffc0200768:	8a56                	mv	s4,s5
ffffffffc020076a:	bf6d                	j	ffffffffc0200724 <dtb_init+0x126>
ffffffffc020076c:	ffb78ee3          	beq	a5,s11,ffffffffc0200768 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200770:	00005517          	auipc	a0,0x5
ffffffffc0200774:	38850513          	addi	a0,a0,904 # ffffffffc0205af8 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00005517          	auipc	a0,0x5
ffffffffc0200780:	3b450513          	addi	a0,a0,948 # ffffffffc0205b30 <commands+0x1e0>
}
ffffffffc0200784:	7446                	ld	s0,112(sp)
ffffffffc0200786:	70e6                	ld	ra,120(sp)
ffffffffc0200788:	74a6                	ld	s1,104(sp)
ffffffffc020078a:	7906                	ld	s2,96(sp)
ffffffffc020078c:	69e6                	ld	s3,88(sp)
ffffffffc020078e:	6a46                	ld	s4,80(sp)
ffffffffc0200790:	6aa6                	ld	s5,72(sp)
ffffffffc0200792:	6b06                	ld	s6,64(sp)
ffffffffc0200794:	7be2                	ld	s7,56(sp)
ffffffffc0200796:	7c42                	ld	s8,48(sp)
ffffffffc0200798:	7ca2                	ld	s9,40(sp)
ffffffffc020079a:	7d02                	ld	s10,32(sp)
ffffffffc020079c:	6de2                	ld	s11,24(sp)
ffffffffc020079e:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02007a0:	bad5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc02007a2:	7446                	ld	s0,112(sp)
ffffffffc02007a4:	70e6                	ld	ra,120(sp)
ffffffffc02007a6:	74a6                	ld	s1,104(sp)
ffffffffc02007a8:	7906                	ld	s2,96(sp)
ffffffffc02007aa:	69e6                	ld	s3,88(sp)
ffffffffc02007ac:	6a46                	ld	s4,80(sp)
ffffffffc02007ae:	6aa6                	ld	s5,72(sp)
ffffffffc02007b0:	6b06                	ld	s6,64(sp)
ffffffffc02007b2:	7be2                	ld	s7,56(sp)
ffffffffc02007b4:	7c42                	ld	s8,48(sp)
ffffffffc02007b6:	7ca2                	ld	s9,40(sp)
ffffffffc02007b8:	7d02                	ld	s10,32(sp)
ffffffffc02007ba:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007bc:	00005517          	auipc	a0,0x5
ffffffffc02007c0:	29450513          	addi	a0,a0,660 # ffffffffc0205a50 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	64f040ef          	jal	ra,ffffffffc0205618 <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	6a7040ef          	jal	ra,ffffffffc020567e <strncmp>
ffffffffc02007dc:	e111                	bnez	a0,ffffffffc02007e0 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02007de:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007e0:	0a91                	addi	s5,s5,4
ffffffffc02007e2:	9ad2                	add	s5,s5,s4
ffffffffc02007e4:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007e8:	8a56                	mv	s4,s5
ffffffffc02007ea:	bf2d                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007ec:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007f0:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007f4:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02007f8:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fc:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200800:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200804:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200808:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200810:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200814:	00eaeab3          	or	s5,s5,a4
ffffffffc0200818:	00fb77b3          	and	a5,s6,a5
ffffffffc020081c:	00faeab3          	or	s5,s5,a5
ffffffffc0200820:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200822:	000c9c63          	bnez	s9,ffffffffc020083a <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200826:	1a82                	slli	s5,s5,0x20
ffffffffc0200828:	00368793          	addi	a5,a3,3
ffffffffc020082c:	020ada93          	srli	s5,s5,0x20
ffffffffc0200830:	9abe                	add	s5,s5,a5
ffffffffc0200832:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200836:	8a56                	mv	s4,s5
ffffffffc0200838:	b5f5                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020083a:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020083e:	85ca                	mv	a1,s2
ffffffffc0200840:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0187971b          	slliw	a4,a5,0x18
ffffffffc020084e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200852:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200856:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200858:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200860:	8d59                	or	a0,a0,a4
ffffffffc0200862:	00fb77b3          	and	a5,s6,a5
ffffffffc0200866:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200868:	1502                	slli	a0,a0,0x20
ffffffffc020086a:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020086c:	9522                	add	a0,a0,s0
ffffffffc020086e:	5f3040ef          	jal	ra,ffffffffc0205660 <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00005517          	auipc	a0,0x5
ffffffffc0200886:	20650513          	addi	a0,a0,518 # ffffffffc0205a88 <commands+0x138>
           fdt32_to_cpu(x >> 32);
ffffffffc020088a:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020088e:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200892:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200896:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020089a:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020089e:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008a2:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a6:	0187d693          	srli	a3,a5,0x18
ffffffffc02008aa:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02008ae:	0087579b          	srliw	a5,a4,0x8
ffffffffc02008b2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008b6:	0106561b          	srliw	a2,a2,0x10
ffffffffc02008ba:	010f6f33          	or	t5,t5,a6
ffffffffc02008be:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008c2:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c6:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008ca:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008ce:	0186f6b3          	and	a3,a3,s8
ffffffffc02008d2:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008d6:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008da:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008de:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008e2:	8361                	srli	a4,a4,0x18
ffffffffc02008e4:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e8:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008ec:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008f0:	00cb7633          	and	a2,s6,a2
ffffffffc02008f4:	0088181b          	slliw	a6,a6,0x8
ffffffffc02008f8:	0085959b          	slliw	a1,a1,0x8
ffffffffc02008fc:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200900:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200904:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200908:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020090c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200910:	011b78b3          	and	a7,s6,a7
ffffffffc0200914:	005eeeb3          	or	t4,t4,t0
ffffffffc0200918:	00c6e733          	or	a4,a3,a2
ffffffffc020091c:	006c6c33          	or	s8,s8,t1
ffffffffc0200920:	010b76b3          	and	a3,s6,a6
ffffffffc0200924:	00bb7b33          	and	s6,s6,a1
ffffffffc0200928:	01d7e7b3          	or	a5,a5,t4
ffffffffc020092c:	016c6b33          	or	s6,s8,s6
ffffffffc0200930:	01146433          	or	s0,s0,a7
ffffffffc0200934:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200936:	1702                	slli	a4,a4,0x20
ffffffffc0200938:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093a:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020093c:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093e:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200940:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200944:	0167eb33          	or	s6,a5,s6
ffffffffc0200948:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020094a:	84bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020094e:	85a2                	mv	a1,s0
ffffffffc0200950:	00005517          	auipc	a0,0x5
ffffffffc0200954:	15850513          	addi	a0,a0,344 # ffffffffc0205aa8 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	15e50513          	addi	a0,a0,350 # ffffffffc0205ac0 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	16c50513          	addi	a0,a0,364 # ffffffffc0205ae0 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	1b050513          	addi	a0,a0,432 # ffffffffc0205b30 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000aa797          	auipc	a5,0xaa
ffffffffc020098c:	d487b423          	sd	s0,-696(a5) # ffffffffc02aa6d0 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000aa797          	auipc	a5,0xaa
ffffffffc0200994:	d567b423          	sd	s6,-696(a5) # ffffffffc02aa6d8 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000aa517          	auipc	a0,0xaa
ffffffffc020099e:	d3653503          	ld	a0,-714(a0) # ffffffffc02aa6d0 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000aa517          	auipc	a0,0xaa
ffffffffc02009a8:	d3453503          	ld	a0,-716(a0) # ffffffffc02aa6d8 <memory_size>
ffffffffc02009ac:	8082                	ret

ffffffffc02009ae <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009ae:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009b2:	8082                	ret

ffffffffc02009b4 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009b4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02009b8:	8082                	ret

ffffffffc02009ba <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02009ba:	8082                	ret

ffffffffc02009bc <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02009bc:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009c0:	00000797          	auipc	a5,0x0
ffffffffc02009c4:	49078793          	addi	a5,a5,1168 # ffffffffc0200e50 <__alltraps>
ffffffffc02009c8:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009cc:	000407b7          	lui	a5,0x40
ffffffffc02009d0:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009d4:	8082                	ret

ffffffffc02009d6 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d6:	610c                	ld	a1,0(a0)
{
ffffffffc02009d8:	1141                	addi	sp,sp,-16
ffffffffc02009da:	e022                	sd	s0,0(sp)
ffffffffc02009dc:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009de:	00005517          	auipc	a0,0x5
ffffffffc02009e2:	16a50513          	addi	a0,a0,362 # ffffffffc0205b48 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	17250513          	addi	a0,a0,370 # ffffffffc0205b60 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	17c50513          	addi	a0,a0,380 # ffffffffc0205b78 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	18650513          	addi	a0,a0,390 # ffffffffc0205b90 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	19050513          	addi	a0,a0,400 # ffffffffc0205ba8 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	19a50513          	addi	a0,a0,410 # ffffffffc0205bc0 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	1a450513          	addi	a0,a0,420 # ffffffffc0205bd8 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	1ae50513          	addi	a0,a0,430 # ffffffffc0205bf0 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	1b850513          	addi	a0,a0,440 # ffffffffc0205c08 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	1c250513          	addi	a0,a0,450 # ffffffffc0205c20 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	1cc50513          	addi	a0,a0,460 # ffffffffc0205c38 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	1d650513          	addi	a0,a0,470 # ffffffffc0205c50 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	1e050513          	addi	a0,a0,480 # ffffffffc0205c68 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	1ea50513          	addi	a0,a0,490 # ffffffffc0205c80 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	1f450513          	addi	a0,a0,500 # ffffffffc0205c98 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	1fe50513          	addi	a0,a0,510 # ffffffffc0205cb0 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	20850513          	addi	a0,a0,520 # ffffffffc0205cc8 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	21250513          	addi	a0,a0,530 # ffffffffc0205ce0 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00005517          	auipc	a0,0x5
ffffffffc0200ae0:	21c50513          	addi	a0,a0,540 # ffffffffc0205cf8 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00005517          	auipc	a0,0x5
ffffffffc0200aee:	22650513          	addi	a0,a0,550 # ffffffffc0205d10 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00005517          	auipc	a0,0x5
ffffffffc0200afc:	23050513          	addi	a0,a0,560 # ffffffffc0205d28 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00005517          	auipc	a0,0x5
ffffffffc0200b0a:	23a50513          	addi	a0,a0,570 # ffffffffc0205d40 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	24450513          	addi	a0,a0,580 # ffffffffc0205d58 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00005517          	auipc	a0,0x5
ffffffffc0200b26:	24e50513          	addi	a0,a0,590 # ffffffffc0205d70 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00005517          	auipc	a0,0x5
ffffffffc0200b34:	25850513          	addi	a0,a0,600 # ffffffffc0205d88 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00005517          	auipc	a0,0x5
ffffffffc0200b42:	26250513          	addi	a0,a0,610 # ffffffffc0205da0 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00005517          	auipc	a0,0x5
ffffffffc0200b50:	26c50513          	addi	a0,a0,620 # ffffffffc0205db8 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00005517          	auipc	a0,0x5
ffffffffc0200b5e:	27650513          	addi	a0,a0,630 # ffffffffc0205dd0 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00005517          	auipc	a0,0x5
ffffffffc0200b6c:	28050513          	addi	a0,a0,640 # ffffffffc0205de8 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	28a50513          	addi	a0,a0,650 # ffffffffc0205e00 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00005517          	auipc	a0,0x5
ffffffffc0200b88:	29450513          	addi	a0,a0,660 # ffffffffc0205e18 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00005517          	auipc	a0,0x5
ffffffffc0200b9a:	29a50513          	addi	a0,a0,666 # ffffffffc0205e30 <commands+0x4e0>
}
ffffffffc0200b9e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ba0:	df4ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200ba4 <print_trapframe>:
{
ffffffffc0200ba4:	1141                	addi	sp,sp,-16
ffffffffc0200ba6:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba8:	85aa                	mv	a1,a0
{
ffffffffc0200baa:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bac:	00005517          	auipc	a0,0x5
ffffffffc0200bb0:	29c50513          	addi	a0,a0,668 # ffffffffc0205e48 <commands+0x4f8>
{
ffffffffc0200bb4:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb6:	ddeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bba:	8522                	mv	a0,s0
ffffffffc0200bbc:	e1bff0ef          	jal	ra,ffffffffc02009d6 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bc0:	10043583          	ld	a1,256(s0)
ffffffffc0200bc4:	00005517          	auipc	a0,0x5
ffffffffc0200bc8:	29c50513          	addi	a0,a0,668 # ffffffffc0205e60 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00005517          	auipc	a0,0x5
ffffffffc0200bd8:	2a450513          	addi	a0,a0,676 # ffffffffc0205e78 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00005517          	auipc	a0,0x5
ffffffffc0200be8:	2ac50513          	addi	a0,a0,684 # ffffffffc0205e90 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00005517          	auipc	a0,0x5
ffffffffc0200bfc:	2a850513          	addi	a0,a0,680 # ffffffffc0205ea0 <commands+0x550>
}
ffffffffc0200c00:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200c02:	d92ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200c06 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200c06:	11853783          	ld	a5,280(a0)
ffffffffc0200c0a:	472d                	li	a4,11
ffffffffc0200c0c:	0786                	slli	a5,a5,0x1
ffffffffc0200c0e:	8385                	srli	a5,a5,0x1
ffffffffc0200c10:	08f76a63          	bltu	a4,a5,ffffffffc0200ca4 <interrupt_handler+0x9e>
ffffffffc0200c14:	00005717          	auipc	a4,0x5
ffffffffc0200c18:	34470713          	addi	a4,a4,836 # ffffffffc0205f58 <commands+0x608>
ffffffffc0200c1c:	078a                	slli	a5,a5,0x2
ffffffffc0200c1e:	97ba                	add	a5,a5,a4
ffffffffc0200c20:	439c                	lw	a5,0(a5)
ffffffffc0200c22:	97ba                	add	a5,a5,a4
ffffffffc0200c24:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c26:	00005517          	auipc	a0,0x5
ffffffffc0200c2a:	2f250513          	addi	a0,a0,754 # ffffffffc0205f18 <commands+0x5c8>
ffffffffc0200c2e:	d66ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c32:	00005517          	auipc	a0,0x5
ffffffffc0200c36:	2c650513          	addi	a0,a0,710 # ffffffffc0205ef8 <commands+0x5a8>
ffffffffc0200c3a:	d5aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c3e:	00005517          	auipc	a0,0x5
ffffffffc0200c42:	27a50513          	addi	a0,a0,634 # ffffffffc0205eb8 <commands+0x568>
ffffffffc0200c46:	d4eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c4a:	00005517          	auipc	a0,0x5
ffffffffc0200c4e:	28e50513          	addi	a0,a0,654 # ffffffffc0205ed8 <commands+0x588>
ffffffffc0200c52:	d42ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200c56:	1141                	addi	sp,sp,-16
ffffffffc0200c58:	e406                	sd	ra,8(sp)
        *(1) 设置下一次时钟中断（clock_set_next_event）
        *(2) ticks 计数器自增
        *(3) 每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，如果有则标记该进程需要被重新调度（current->need_resched）
        */
        // (1) 设置下一次时钟中断，预约下一次中断
        clock_set_next_event();
ffffffffc0200c5a:	919ff0ef          	jal	ra,ffffffffc0200572 <clock_set_next_event>

        // (2) ticks 计数器自增
        ticks++;
ffffffffc0200c5e:	000aa797          	auipc	a5,0xaa
ffffffffc0200c62:	a6278793          	addi	a5,a5,-1438 # ffffffffc02aa6c0 <ticks>
ffffffffc0200c66:	6398                	ld	a4,0(a5)
ffffffffc0200c68:	0705                	addi	a4,a4,1
ffffffffc0200c6a:	e398                	sd	a4,0(a5)

        // (3) 每 TICK_NUM 次中断进行调度判断
        if (ticks % TICK_NUM == 0) {
ffffffffc0200c6c:	639c                	ld	a5,0(a5)
ffffffffc0200c6e:	06400713          	li	a4,100
ffffffffc0200c72:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200c76:	ef91                	bnez	a5,ffffffffc0200c92 <interrupt_handler+0x8c>
            // 检查当前是否有进程在运行（不是空闲进程）
            if (current != NULL && current != idleproc) {
ffffffffc0200c78:	000aa797          	auipc	a5,0xaa
ffffffffc0200c7c:	aa07b783          	ld	a5,-1376(a5) # ffffffffc02aa718 <current>
ffffffffc0200c80:	cb89                	beqz	a5,ffffffffc0200c92 <interrupt_handler+0x8c>
ffffffffc0200c82:	000aa717          	auipc	a4,0xaa
ffffffffc0200c86:	a9e73703          	ld	a4,-1378(a4) # ffffffffc02aa720 <idleproc>
ffffffffc0200c8a:	00e78463          	beq	a5,a4,ffffffffc0200c92 <interrupt_handler+0x8c>
                // 标记该进程需要被重新调度
                current->need_resched = 1;
ffffffffc0200c8e:	4705                	li	a4,1
ffffffffc0200c90:	ef98                	sd	a4,24(a5)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c92:	60a2                	ld	ra,8(sp)
ffffffffc0200c94:	0141                	addi	sp,sp,16
ffffffffc0200c96:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c98:	00005517          	auipc	a0,0x5
ffffffffc0200c9c:	2a050513          	addi	a0,a0,672 # ffffffffc0205f38 <commands+0x5e8>
ffffffffc0200ca0:	cf4ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200ca4:	b701                	j	ffffffffc0200ba4 <print_trapframe>

ffffffffc0200ca6 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200ca6:	11853783          	ld	a5,280(a0)
{
ffffffffc0200caa:	1141                	addi	sp,sp,-16
ffffffffc0200cac:	e022                	sd	s0,0(sp)
ffffffffc0200cae:	e406                	sd	ra,8(sp)
ffffffffc0200cb0:	473d                	li	a4,15
ffffffffc0200cb2:	842a                	mv	s0,a0
ffffffffc0200cb4:	0cf76463          	bltu	a4,a5,ffffffffc0200d7c <exception_handler+0xd6>
ffffffffc0200cb8:	00005717          	auipc	a4,0x5
ffffffffc0200cbc:	46070713          	addi	a4,a4,1120 # ffffffffc0206118 <commands+0x7c8>
ffffffffc0200cc0:	078a                	slli	a5,a5,0x2
ffffffffc0200cc2:	97ba                	add	a5,a5,a4
ffffffffc0200cc4:	439c                	lw	a5,0(a5)
ffffffffc0200cc6:	97ba                	add	a5,a5,a4
ffffffffc0200cc8:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200cca:	00005517          	auipc	a0,0x5
ffffffffc0200cce:	3a650513          	addi	a0,a0,934 # ffffffffc0206070 <commands+0x720>
ffffffffc0200cd2:	cc2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200cd6:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200cda:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200cdc:	0791                	addi	a5,a5,4
ffffffffc0200cde:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200ce2:	6402                	ld	s0,0(sp)
ffffffffc0200ce4:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200ce6:	4ae0406f          	j	ffffffffc0205194 <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200cea:	00005517          	auipc	a0,0x5
ffffffffc0200cee:	3a650513          	addi	a0,a0,934 # ffffffffc0206090 <commands+0x740>
}
ffffffffc0200cf2:	6402                	ld	s0,0(sp)
ffffffffc0200cf4:	60a2                	ld	ra,8(sp)
ffffffffc0200cf6:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200cf8:	c9cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200cfc:	00005517          	auipc	a0,0x5
ffffffffc0200d00:	3b450513          	addi	a0,a0,948 # ffffffffc02060b0 <commands+0x760>
ffffffffc0200d04:	b7fd                	j	ffffffffc0200cf2 <exception_handler+0x4c>
        cprintf("Instruction page fault\n");
ffffffffc0200d06:	00005517          	auipc	a0,0x5
ffffffffc0200d0a:	3ca50513          	addi	a0,a0,970 # ffffffffc02060d0 <commands+0x780>
ffffffffc0200d0e:	b7d5                	j	ffffffffc0200cf2 <exception_handler+0x4c>
        cprintf("Load page fault\n");
ffffffffc0200d10:	00005517          	auipc	a0,0x5
ffffffffc0200d14:	3d850513          	addi	a0,a0,984 # ffffffffc02060e8 <commands+0x798>
ffffffffc0200d18:	bfe9                	j	ffffffffc0200cf2 <exception_handler+0x4c>
        cprintf("Store/AMO page fault\n");
ffffffffc0200d1a:	00005517          	auipc	a0,0x5
ffffffffc0200d1e:	3e650513          	addi	a0,a0,998 # ffffffffc0206100 <commands+0x7b0>
ffffffffc0200d22:	bfc1                	j	ffffffffc0200cf2 <exception_handler+0x4c>
        cprintf("Instruction address misaligned\n");
ffffffffc0200d24:	00005517          	auipc	a0,0x5
ffffffffc0200d28:	26450513          	addi	a0,a0,612 # ffffffffc0205f88 <commands+0x638>
ffffffffc0200d2c:	b7d9                	j	ffffffffc0200cf2 <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200d2e:	00005517          	auipc	a0,0x5
ffffffffc0200d32:	27a50513          	addi	a0,a0,634 # ffffffffc0205fa8 <commands+0x658>
ffffffffc0200d36:	bf75                	j	ffffffffc0200cf2 <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200d38:	00005517          	auipc	a0,0x5
ffffffffc0200d3c:	29050513          	addi	a0,a0,656 # ffffffffc0205fc8 <commands+0x678>
ffffffffc0200d40:	bf4d                	j	ffffffffc0200cf2 <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200d42:	00005517          	auipc	a0,0x5
ffffffffc0200d46:	29e50513          	addi	a0,a0,670 # ffffffffc0205fe0 <commands+0x690>
ffffffffc0200d4a:	c4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200d4e:	6458                	ld	a4,136(s0)
ffffffffc0200d50:	47a9                	li	a5,10
ffffffffc0200d52:	04f70663          	beq	a4,a5,ffffffffc0200d9e <exception_handler+0xf8>
}
ffffffffc0200d56:	60a2                	ld	ra,8(sp)
ffffffffc0200d58:	6402                	ld	s0,0(sp)
ffffffffc0200d5a:	0141                	addi	sp,sp,16
ffffffffc0200d5c:	8082                	ret
        cprintf("Load address misaligned\n");
ffffffffc0200d5e:	00005517          	auipc	a0,0x5
ffffffffc0200d62:	29250513          	addi	a0,a0,658 # ffffffffc0205ff0 <commands+0x6a0>
ffffffffc0200d66:	b771                	j	ffffffffc0200cf2 <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200d68:	00005517          	auipc	a0,0x5
ffffffffc0200d6c:	2a850513          	addi	a0,a0,680 # ffffffffc0206010 <commands+0x6c0>
ffffffffc0200d70:	b749                	j	ffffffffc0200cf2 <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200d72:	00005517          	auipc	a0,0x5
ffffffffc0200d76:	2e650513          	addi	a0,a0,742 # ffffffffc0206058 <commands+0x708>
ffffffffc0200d7a:	bfa5                	j	ffffffffc0200cf2 <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200d7c:	8522                	mv	a0,s0
}
ffffffffc0200d7e:	6402                	ld	s0,0(sp)
ffffffffc0200d80:	60a2                	ld	ra,8(sp)
ffffffffc0200d82:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200d84:	b505                	j	ffffffffc0200ba4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d86:	00005617          	auipc	a2,0x5
ffffffffc0200d8a:	2a260613          	addi	a2,a2,674 # ffffffffc0206028 <commands+0x6d8>
ffffffffc0200d8e:	0c800593          	li	a1,200
ffffffffc0200d92:	00005517          	auipc	a0,0x5
ffffffffc0200d96:	2ae50513          	addi	a0,a0,686 # ffffffffc0206040 <commands+0x6f0>
ffffffffc0200d9a:	ef4ff0ef          	jal	ra,ffffffffc020048e <__panic>
            tf->epc += 4;
ffffffffc0200d9e:	10843783          	ld	a5,264(s0)
ffffffffc0200da2:	0791                	addi	a5,a5,4
ffffffffc0200da4:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0200da8:	3ec040ef          	jal	ra,ffffffffc0205194 <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200dac:	000aa797          	auipc	a5,0xaa
ffffffffc0200db0:	96c7b783          	ld	a5,-1684(a5) # ffffffffc02aa718 <current>
ffffffffc0200db4:	6b9c                	ld	a5,16(a5)
ffffffffc0200db6:	8522                	mv	a0,s0
}
ffffffffc0200db8:	6402                	ld	s0,0(sp)
ffffffffc0200dba:	60a2                	ld	ra,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200dbc:	6589                	lui	a1,0x2
ffffffffc0200dbe:	95be                	add	a1,a1,a5
}
ffffffffc0200dc0:	0141                	addi	sp,sp,16
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200dc2:	aab1                	j	ffffffffc0200f1e <kernel_execve_ret>

ffffffffc0200dc4 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200dc4:	1101                	addi	sp,sp,-32
ffffffffc0200dc6:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200dc8:	000aa417          	auipc	s0,0xaa
ffffffffc0200dcc:	95040413          	addi	s0,s0,-1712 # ffffffffc02aa718 <current>
ffffffffc0200dd0:	6018                	ld	a4,0(s0)
{
ffffffffc0200dd2:	ec06                	sd	ra,24(sp)
ffffffffc0200dd4:	e426                	sd	s1,8(sp)
ffffffffc0200dd6:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200dd8:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200ddc:	cf1d                	beqz	a4,ffffffffc0200e1a <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200dde:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200de2:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200de6:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200de8:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200dec:	0206c463          	bltz	a3,ffffffffc0200e14 <trap+0x50>
        exception_handler(tf);
ffffffffc0200df0:	eb7ff0ef          	jal	ra,ffffffffc0200ca6 <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200df4:	601c                	ld	a5,0(s0)
ffffffffc0200df6:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200dfa:	e499                	bnez	s1,ffffffffc0200e08 <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200dfc:	0b07a703          	lw	a4,176(a5)
ffffffffc0200e00:	8b05                	andi	a4,a4,1
ffffffffc0200e02:	e329                	bnez	a4,ffffffffc0200e44 <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200e04:	6f9c                	ld	a5,24(a5)
ffffffffc0200e06:	eb85                	bnez	a5,ffffffffc0200e36 <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200e08:	60e2                	ld	ra,24(sp)
ffffffffc0200e0a:	6442                	ld	s0,16(sp)
ffffffffc0200e0c:	64a2                	ld	s1,8(sp)
ffffffffc0200e0e:	6902                	ld	s2,0(sp)
ffffffffc0200e10:	6105                	addi	sp,sp,32
ffffffffc0200e12:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200e14:	df3ff0ef          	jal	ra,ffffffffc0200c06 <interrupt_handler>
ffffffffc0200e18:	bff1                	j	ffffffffc0200df4 <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e1a:	0006c863          	bltz	a3,ffffffffc0200e2a <trap+0x66>
}
ffffffffc0200e1e:	6442                	ld	s0,16(sp)
ffffffffc0200e20:	60e2                	ld	ra,24(sp)
ffffffffc0200e22:	64a2                	ld	s1,8(sp)
ffffffffc0200e24:	6902                	ld	s2,0(sp)
ffffffffc0200e26:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200e28:	bdbd                	j	ffffffffc0200ca6 <exception_handler>
}
ffffffffc0200e2a:	6442                	ld	s0,16(sp)
ffffffffc0200e2c:	60e2                	ld	ra,24(sp)
ffffffffc0200e2e:	64a2                	ld	s1,8(sp)
ffffffffc0200e30:	6902                	ld	s2,0(sp)
ffffffffc0200e32:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200e34:	bbc9                	j	ffffffffc0200c06 <interrupt_handler>
}
ffffffffc0200e36:	6442                	ld	s0,16(sp)
ffffffffc0200e38:	60e2                	ld	ra,24(sp)
ffffffffc0200e3a:	64a2                	ld	s1,8(sp)
ffffffffc0200e3c:	6902                	ld	s2,0(sp)
ffffffffc0200e3e:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200e40:	2680406f          	j	ffffffffc02050a8 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200e44:	555d                	li	a0,-9
ffffffffc0200e46:	5a8030ef          	jal	ra,ffffffffc02043ee <do_exit>
            if (current->need_resched)
ffffffffc0200e4a:	601c                	ld	a5,0(s0)
ffffffffc0200e4c:	bf65                	j	ffffffffc0200e04 <trap+0x40>
	...

ffffffffc0200e50 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200e50:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200e54:	00011463          	bnez	sp,ffffffffc0200e5c <__alltraps+0xc>
ffffffffc0200e58:	14002173          	csrr	sp,sscratch
ffffffffc0200e5c:	712d                	addi	sp,sp,-288
ffffffffc0200e5e:	e002                	sd	zero,0(sp)
ffffffffc0200e60:	e406                	sd	ra,8(sp)
ffffffffc0200e62:	ec0e                	sd	gp,24(sp)
ffffffffc0200e64:	f012                	sd	tp,32(sp)
ffffffffc0200e66:	f416                	sd	t0,40(sp)
ffffffffc0200e68:	f81a                	sd	t1,48(sp)
ffffffffc0200e6a:	fc1e                	sd	t2,56(sp)
ffffffffc0200e6c:	e0a2                	sd	s0,64(sp)
ffffffffc0200e6e:	e4a6                	sd	s1,72(sp)
ffffffffc0200e70:	e8aa                	sd	a0,80(sp)
ffffffffc0200e72:	ecae                	sd	a1,88(sp)
ffffffffc0200e74:	f0b2                	sd	a2,96(sp)
ffffffffc0200e76:	f4b6                	sd	a3,104(sp)
ffffffffc0200e78:	f8ba                	sd	a4,112(sp)
ffffffffc0200e7a:	fcbe                	sd	a5,120(sp)
ffffffffc0200e7c:	e142                	sd	a6,128(sp)
ffffffffc0200e7e:	e546                	sd	a7,136(sp)
ffffffffc0200e80:	e94a                	sd	s2,144(sp)
ffffffffc0200e82:	ed4e                	sd	s3,152(sp)
ffffffffc0200e84:	f152                	sd	s4,160(sp)
ffffffffc0200e86:	f556                	sd	s5,168(sp)
ffffffffc0200e88:	f95a                	sd	s6,176(sp)
ffffffffc0200e8a:	fd5e                	sd	s7,184(sp)
ffffffffc0200e8c:	e1e2                	sd	s8,192(sp)
ffffffffc0200e8e:	e5e6                	sd	s9,200(sp)
ffffffffc0200e90:	e9ea                	sd	s10,208(sp)
ffffffffc0200e92:	edee                	sd	s11,216(sp)
ffffffffc0200e94:	f1f2                	sd	t3,224(sp)
ffffffffc0200e96:	f5f6                	sd	t4,232(sp)
ffffffffc0200e98:	f9fa                	sd	t5,240(sp)
ffffffffc0200e9a:	fdfe                	sd	t6,248(sp)
ffffffffc0200e9c:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200ea0:	100024f3          	csrr	s1,sstatus
ffffffffc0200ea4:	14102973          	csrr	s2,sepc
ffffffffc0200ea8:	143029f3          	csrr	s3,stval
ffffffffc0200eac:	14202a73          	csrr	s4,scause
ffffffffc0200eb0:	e822                	sd	s0,16(sp)
ffffffffc0200eb2:	e226                	sd	s1,256(sp)
ffffffffc0200eb4:	e64a                	sd	s2,264(sp)
ffffffffc0200eb6:	ea4e                	sd	s3,272(sp)
ffffffffc0200eb8:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200eba:	850a                	mv	a0,sp
    jal trap
ffffffffc0200ebc:	f09ff0ef          	jal	ra,ffffffffc0200dc4 <trap>

ffffffffc0200ec0 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200ec0:	6492                	ld	s1,256(sp)
ffffffffc0200ec2:	6932                	ld	s2,264(sp)
ffffffffc0200ec4:	1004f413          	andi	s0,s1,256
ffffffffc0200ec8:	e401                	bnez	s0,ffffffffc0200ed0 <__trapret+0x10>
ffffffffc0200eca:	1200                	addi	s0,sp,288
ffffffffc0200ecc:	14041073          	csrw	sscratch,s0
ffffffffc0200ed0:	10049073          	csrw	sstatus,s1
ffffffffc0200ed4:	14191073          	csrw	sepc,s2
ffffffffc0200ed8:	60a2                	ld	ra,8(sp)
ffffffffc0200eda:	61e2                	ld	gp,24(sp)
ffffffffc0200edc:	7202                	ld	tp,32(sp)
ffffffffc0200ede:	72a2                	ld	t0,40(sp)
ffffffffc0200ee0:	7342                	ld	t1,48(sp)
ffffffffc0200ee2:	73e2                	ld	t2,56(sp)
ffffffffc0200ee4:	6406                	ld	s0,64(sp)
ffffffffc0200ee6:	64a6                	ld	s1,72(sp)
ffffffffc0200ee8:	6546                	ld	a0,80(sp)
ffffffffc0200eea:	65e6                	ld	a1,88(sp)
ffffffffc0200eec:	7606                	ld	a2,96(sp)
ffffffffc0200eee:	76a6                	ld	a3,104(sp)
ffffffffc0200ef0:	7746                	ld	a4,112(sp)
ffffffffc0200ef2:	77e6                	ld	a5,120(sp)
ffffffffc0200ef4:	680a                	ld	a6,128(sp)
ffffffffc0200ef6:	68aa                	ld	a7,136(sp)
ffffffffc0200ef8:	694a                	ld	s2,144(sp)
ffffffffc0200efa:	69ea                	ld	s3,152(sp)
ffffffffc0200efc:	7a0a                	ld	s4,160(sp)
ffffffffc0200efe:	7aaa                	ld	s5,168(sp)
ffffffffc0200f00:	7b4a                	ld	s6,176(sp)
ffffffffc0200f02:	7bea                	ld	s7,184(sp)
ffffffffc0200f04:	6c0e                	ld	s8,192(sp)
ffffffffc0200f06:	6cae                	ld	s9,200(sp)
ffffffffc0200f08:	6d4e                	ld	s10,208(sp)
ffffffffc0200f0a:	6dee                	ld	s11,216(sp)
ffffffffc0200f0c:	7e0e                	ld	t3,224(sp)
ffffffffc0200f0e:	7eae                	ld	t4,232(sp)
ffffffffc0200f10:	7f4e                	ld	t5,240(sp)
ffffffffc0200f12:	7fee                	ld	t6,248(sp)
ffffffffc0200f14:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200f16:	10200073          	sret

ffffffffc0200f1a <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200f1a:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200f1c:	b755                	j	ffffffffc0200ec0 <__trapret>

ffffffffc0200f1e <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200f1e:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cc8>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200f22:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200f26:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200f2a:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200f2e:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200f32:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200f36:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200f3a:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200f3e:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200f42:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200f44:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200f46:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200f48:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200f4a:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200f4c:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200f4e:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200f50:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200f52:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200f54:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200f56:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200f58:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200f5a:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200f5c:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200f5e:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200f60:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200f62:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200f64:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200f66:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200f68:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200f6a:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200f6c:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200f6e:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200f70:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200f72:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200f74:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200f76:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200f78:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200f7a:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200f7c:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200f7e:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200f80:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200f82:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200f84:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200f86:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200f88:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200f8a:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200f8c:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200f8e:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200f90:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200f92:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200f94:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200f96:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200f98:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200f9a:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200f9c:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200f9e:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200fa0:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200fa2:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200fa4:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200fa6:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200fa8:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200faa:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200fac:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200fae:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200fb0:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200fb2:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200fb4:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200fb6:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200fb8:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200fba:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200fbc:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200fbe:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200fc0:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200fc2:	812e                	mv	sp,a1
ffffffffc0200fc4:	bdf5                	j	ffffffffc0200ec0 <__trapret>

ffffffffc0200fc6 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200fc6:	000a5797          	auipc	a5,0xa5
ffffffffc0200fca:	6ca78793          	addi	a5,a5,1738 # ffffffffc02a6690 <free_area>
ffffffffc0200fce:	e79c                	sd	a5,8(a5)
ffffffffc0200fd0:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200fd2:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200fd6:	8082                	ret

ffffffffc0200fd8 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200fd8:	000a5517          	auipc	a0,0xa5
ffffffffc0200fdc:	6c856503          	lwu	a0,1736(a0) # ffffffffc02a66a0 <free_area+0x10>
ffffffffc0200fe0:	8082                	ret

ffffffffc0200fe2 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200fe2:	715d                	addi	sp,sp,-80
ffffffffc0200fe4:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200fe6:	000a5417          	auipc	s0,0xa5
ffffffffc0200fea:	6aa40413          	addi	s0,s0,1706 # ffffffffc02a6690 <free_area>
ffffffffc0200fee:	641c                	ld	a5,8(s0)
ffffffffc0200ff0:	e486                	sd	ra,72(sp)
ffffffffc0200ff2:	fc26                	sd	s1,56(sp)
ffffffffc0200ff4:	f84a                	sd	s2,48(sp)
ffffffffc0200ff6:	f44e                	sd	s3,40(sp)
ffffffffc0200ff8:	f052                	sd	s4,32(sp)
ffffffffc0200ffa:	ec56                	sd	s5,24(sp)
ffffffffc0200ffc:	e85a                	sd	s6,16(sp)
ffffffffc0200ffe:	e45e                	sd	s7,8(sp)
ffffffffc0201000:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201002:	2a878d63          	beq	a5,s0,ffffffffc02012bc <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0201006:	4481                	li	s1,0
ffffffffc0201008:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020100a:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020100e:	8b09                	andi	a4,a4,2
ffffffffc0201010:	2a070a63          	beqz	a4,ffffffffc02012c4 <default_check+0x2e2>
        count++, total += p->property;
ffffffffc0201014:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201018:	679c                	ld	a5,8(a5)
ffffffffc020101a:	2905                	addiw	s2,s2,1
ffffffffc020101c:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc020101e:	fe8796e3          	bne	a5,s0,ffffffffc020100a <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0201022:	89a6                	mv	s3,s1
ffffffffc0201024:	6df000ef          	jal	ra,ffffffffc0201f02 <nr_free_pages>
ffffffffc0201028:	6f351e63          	bne	a0,s3,ffffffffc0201724 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020102c:	4505                	li	a0,1
ffffffffc020102e:	657000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc0201032:	8aaa                	mv	s5,a0
ffffffffc0201034:	42050863          	beqz	a0,ffffffffc0201464 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201038:	4505                	li	a0,1
ffffffffc020103a:	64b000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc020103e:	89aa                	mv	s3,a0
ffffffffc0201040:	70050263          	beqz	a0,ffffffffc0201744 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201044:	4505                	li	a0,1
ffffffffc0201046:	63f000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc020104a:	8a2a                	mv	s4,a0
ffffffffc020104c:	48050c63          	beqz	a0,ffffffffc02014e4 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201050:	293a8a63          	beq	s5,s3,ffffffffc02012e4 <default_check+0x302>
ffffffffc0201054:	28aa8863          	beq	s5,a0,ffffffffc02012e4 <default_check+0x302>
ffffffffc0201058:	28a98663          	beq	s3,a0,ffffffffc02012e4 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020105c:	000aa783          	lw	a5,0(s5)
ffffffffc0201060:	2a079263          	bnez	a5,ffffffffc0201304 <default_check+0x322>
ffffffffc0201064:	0009a783          	lw	a5,0(s3)
ffffffffc0201068:	28079e63          	bnez	a5,ffffffffc0201304 <default_check+0x322>
ffffffffc020106c:	411c                	lw	a5,0(a0)
ffffffffc020106e:	28079b63          	bnez	a5,ffffffffc0201304 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0201072:	000a9797          	auipc	a5,0xa9
ffffffffc0201076:	68e7b783          	ld	a5,1678(a5) # ffffffffc02aa700 <pages>
ffffffffc020107a:	40fa8733          	sub	a4,s5,a5
ffffffffc020107e:	00006617          	auipc	a2,0x6
ffffffffc0201082:	7c263603          	ld	a2,1986(a2) # ffffffffc0207840 <nbase>
ffffffffc0201086:	8719                	srai	a4,a4,0x6
ffffffffc0201088:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020108a:	000a9697          	auipc	a3,0xa9
ffffffffc020108e:	66e6b683          	ld	a3,1646(a3) # ffffffffc02aa6f8 <npage>
ffffffffc0201092:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0201094:	0732                	slli	a4,a4,0xc
ffffffffc0201096:	28d77763          	bgeu	a4,a3,ffffffffc0201324 <default_check+0x342>
    return page - pages + nbase;
ffffffffc020109a:	40f98733          	sub	a4,s3,a5
ffffffffc020109e:	8719                	srai	a4,a4,0x6
ffffffffc02010a0:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010a2:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02010a4:	4cd77063          	bgeu	a4,a3,ffffffffc0201564 <default_check+0x582>
    return page - pages + nbase;
ffffffffc02010a8:	40f507b3          	sub	a5,a0,a5
ffffffffc02010ac:	8799                	srai	a5,a5,0x6
ffffffffc02010ae:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010b0:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02010b2:	30d7f963          	bgeu	a5,a3,ffffffffc02013c4 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc02010b6:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02010b8:	00043c03          	ld	s8,0(s0)
ffffffffc02010bc:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02010c0:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02010c4:	e400                	sd	s0,8(s0)
ffffffffc02010c6:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02010c8:	000a5797          	auipc	a5,0xa5
ffffffffc02010cc:	5c07ac23          	sw	zero,1496(a5) # ffffffffc02a66a0 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02010d0:	5b5000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc02010d4:	2c051863          	bnez	a0,ffffffffc02013a4 <default_check+0x3c2>
    free_page(p0);
ffffffffc02010d8:	4585                	li	a1,1
ffffffffc02010da:	8556                	mv	a0,s5
ffffffffc02010dc:	5e7000ef          	jal	ra,ffffffffc0201ec2 <free_pages>
    free_page(p1);
ffffffffc02010e0:	4585                	li	a1,1
ffffffffc02010e2:	854e                	mv	a0,s3
ffffffffc02010e4:	5df000ef          	jal	ra,ffffffffc0201ec2 <free_pages>
    free_page(p2);
ffffffffc02010e8:	4585                	li	a1,1
ffffffffc02010ea:	8552                	mv	a0,s4
ffffffffc02010ec:	5d7000ef          	jal	ra,ffffffffc0201ec2 <free_pages>
    assert(nr_free == 3);
ffffffffc02010f0:	4818                	lw	a4,16(s0)
ffffffffc02010f2:	478d                	li	a5,3
ffffffffc02010f4:	28f71863          	bne	a4,a5,ffffffffc0201384 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010f8:	4505                	li	a0,1
ffffffffc02010fa:	58b000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc02010fe:	89aa                	mv	s3,a0
ffffffffc0201100:	26050263          	beqz	a0,ffffffffc0201364 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201104:	4505                	li	a0,1
ffffffffc0201106:	57f000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc020110a:	8aaa                	mv	s5,a0
ffffffffc020110c:	3a050c63          	beqz	a0,ffffffffc02014c4 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201110:	4505                	li	a0,1
ffffffffc0201112:	573000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc0201116:	8a2a                	mv	s4,a0
ffffffffc0201118:	38050663          	beqz	a0,ffffffffc02014a4 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc020111c:	4505                	li	a0,1
ffffffffc020111e:	567000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc0201122:	36051163          	bnez	a0,ffffffffc0201484 <default_check+0x4a2>
    free_page(p0);
ffffffffc0201126:	4585                	li	a1,1
ffffffffc0201128:	854e                	mv	a0,s3
ffffffffc020112a:	599000ef          	jal	ra,ffffffffc0201ec2 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc020112e:	641c                	ld	a5,8(s0)
ffffffffc0201130:	20878a63          	beq	a5,s0,ffffffffc0201344 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0201134:	4505                	li	a0,1
ffffffffc0201136:	54f000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc020113a:	30a99563          	bne	s3,a0,ffffffffc0201444 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc020113e:	4505                	li	a0,1
ffffffffc0201140:	545000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc0201144:	2e051063          	bnez	a0,ffffffffc0201424 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0201148:	481c                	lw	a5,16(s0)
ffffffffc020114a:	2a079d63          	bnez	a5,ffffffffc0201404 <default_check+0x422>
    free_page(p);
ffffffffc020114e:	854e                	mv	a0,s3
ffffffffc0201150:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201152:	01843023          	sd	s8,0(s0)
ffffffffc0201156:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc020115a:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc020115e:	565000ef          	jal	ra,ffffffffc0201ec2 <free_pages>
    free_page(p1);
ffffffffc0201162:	4585                	li	a1,1
ffffffffc0201164:	8556                	mv	a0,s5
ffffffffc0201166:	55d000ef          	jal	ra,ffffffffc0201ec2 <free_pages>
    free_page(p2);
ffffffffc020116a:	4585                	li	a1,1
ffffffffc020116c:	8552                	mv	a0,s4
ffffffffc020116e:	555000ef          	jal	ra,ffffffffc0201ec2 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201172:	4515                	li	a0,5
ffffffffc0201174:	511000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc0201178:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020117a:	26050563          	beqz	a0,ffffffffc02013e4 <default_check+0x402>
ffffffffc020117e:	651c                	ld	a5,8(a0)
ffffffffc0201180:	8385                	srli	a5,a5,0x1
ffffffffc0201182:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0201184:	54079063          	bnez	a5,ffffffffc02016c4 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201188:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020118a:	00043b03          	ld	s6,0(s0)
ffffffffc020118e:	00843a83          	ld	s5,8(s0)
ffffffffc0201192:	e000                	sd	s0,0(s0)
ffffffffc0201194:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0201196:	4ef000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc020119a:	50051563          	bnez	a0,ffffffffc02016a4 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc020119e:	08098a13          	addi	s4,s3,128
ffffffffc02011a2:	8552                	mv	a0,s4
ffffffffc02011a4:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02011a6:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc02011aa:	000a5797          	auipc	a5,0xa5
ffffffffc02011ae:	4e07ab23          	sw	zero,1270(a5) # ffffffffc02a66a0 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02011b2:	511000ef          	jal	ra,ffffffffc0201ec2 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02011b6:	4511                	li	a0,4
ffffffffc02011b8:	4cd000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc02011bc:	4c051463          	bnez	a0,ffffffffc0201684 <default_check+0x6a2>
ffffffffc02011c0:	0889b783          	ld	a5,136(s3)
ffffffffc02011c4:	8385                	srli	a5,a5,0x1
ffffffffc02011c6:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02011c8:	48078e63          	beqz	a5,ffffffffc0201664 <default_check+0x682>
ffffffffc02011cc:	0909a703          	lw	a4,144(s3)
ffffffffc02011d0:	478d                	li	a5,3
ffffffffc02011d2:	48f71963          	bne	a4,a5,ffffffffc0201664 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02011d6:	450d                	li	a0,3
ffffffffc02011d8:	4ad000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc02011dc:	8c2a                	mv	s8,a0
ffffffffc02011de:	46050363          	beqz	a0,ffffffffc0201644 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc02011e2:	4505                	li	a0,1
ffffffffc02011e4:	4a1000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc02011e8:	42051e63          	bnez	a0,ffffffffc0201624 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc02011ec:	418a1c63          	bne	s4,s8,ffffffffc0201604 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02011f0:	4585                	li	a1,1
ffffffffc02011f2:	854e                	mv	a0,s3
ffffffffc02011f4:	4cf000ef          	jal	ra,ffffffffc0201ec2 <free_pages>
    free_pages(p1, 3);
ffffffffc02011f8:	458d                	li	a1,3
ffffffffc02011fa:	8552                	mv	a0,s4
ffffffffc02011fc:	4c7000ef          	jal	ra,ffffffffc0201ec2 <free_pages>
ffffffffc0201200:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201204:	04098c13          	addi	s8,s3,64
ffffffffc0201208:	8385                	srli	a5,a5,0x1
ffffffffc020120a:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020120c:	3c078c63          	beqz	a5,ffffffffc02015e4 <default_check+0x602>
ffffffffc0201210:	0109a703          	lw	a4,16(s3)
ffffffffc0201214:	4785                	li	a5,1
ffffffffc0201216:	3cf71763          	bne	a4,a5,ffffffffc02015e4 <default_check+0x602>
ffffffffc020121a:	008a3783          	ld	a5,8(s4)
ffffffffc020121e:	8385                	srli	a5,a5,0x1
ffffffffc0201220:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201222:	3a078163          	beqz	a5,ffffffffc02015c4 <default_check+0x5e2>
ffffffffc0201226:	010a2703          	lw	a4,16(s4)
ffffffffc020122a:	478d                	li	a5,3
ffffffffc020122c:	38f71c63          	bne	a4,a5,ffffffffc02015c4 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201230:	4505                	li	a0,1
ffffffffc0201232:	453000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc0201236:	36a99763          	bne	s3,a0,ffffffffc02015a4 <default_check+0x5c2>
    free_page(p0);
ffffffffc020123a:	4585                	li	a1,1
ffffffffc020123c:	487000ef          	jal	ra,ffffffffc0201ec2 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201240:	4509                	li	a0,2
ffffffffc0201242:	443000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc0201246:	32aa1f63          	bne	s4,a0,ffffffffc0201584 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc020124a:	4589                	li	a1,2
ffffffffc020124c:	477000ef          	jal	ra,ffffffffc0201ec2 <free_pages>
    free_page(p2);
ffffffffc0201250:	4585                	li	a1,1
ffffffffc0201252:	8562                	mv	a0,s8
ffffffffc0201254:	46f000ef          	jal	ra,ffffffffc0201ec2 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201258:	4515                	li	a0,5
ffffffffc020125a:	42b000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc020125e:	89aa                	mv	s3,a0
ffffffffc0201260:	48050263          	beqz	a0,ffffffffc02016e4 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0201264:	4505                	li	a0,1
ffffffffc0201266:	41f000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc020126a:	2c051d63          	bnez	a0,ffffffffc0201544 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc020126e:	481c                	lw	a5,16(s0)
ffffffffc0201270:	2a079a63          	bnez	a5,ffffffffc0201524 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201274:	4595                	li	a1,5
ffffffffc0201276:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201278:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc020127c:	01643023          	sd	s6,0(s0)
ffffffffc0201280:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201284:	43f000ef          	jal	ra,ffffffffc0201ec2 <free_pages>
    return listelm->next;
ffffffffc0201288:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc020128a:	00878963          	beq	a5,s0,ffffffffc020129c <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc020128e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201292:	679c                	ld	a5,8(a5)
ffffffffc0201294:	397d                	addiw	s2,s2,-1
ffffffffc0201296:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201298:	fe879be3          	bne	a5,s0,ffffffffc020128e <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc020129c:	26091463          	bnez	s2,ffffffffc0201504 <default_check+0x522>
    assert(total == 0);
ffffffffc02012a0:	46049263          	bnez	s1,ffffffffc0201704 <default_check+0x722>
}
ffffffffc02012a4:	60a6                	ld	ra,72(sp)
ffffffffc02012a6:	6406                	ld	s0,64(sp)
ffffffffc02012a8:	74e2                	ld	s1,56(sp)
ffffffffc02012aa:	7942                	ld	s2,48(sp)
ffffffffc02012ac:	79a2                	ld	s3,40(sp)
ffffffffc02012ae:	7a02                	ld	s4,32(sp)
ffffffffc02012b0:	6ae2                	ld	s5,24(sp)
ffffffffc02012b2:	6b42                	ld	s6,16(sp)
ffffffffc02012b4:	6ba2                	ld	s7,8(sp)
ffffffffc02012b6:	6c02                	ld	s8,0(sp)
ffffffffc02012b8:	6161                	addi	sp,sp,80
ffffffffc02012ba:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc02012bc:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02012be:	4481                	li	s1,0
ffffffffc02012c0:	4901                	li	s2,0
ffffffffc02012c2:	b38d                	j	ffffffffc0201024 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02012c4:	00005697          	auipc	a3,0x5
ffffffffc02012c8:	e9468693          	addi	a3,a3,-364 # ffffffffc0206158 <commands+0x808>
ffffffffc02012cc:	00005617          	auipc	a2,0x5
ffffffffc02012d0:	e9c60613          	addi	a2,a2,-356 # ffffffffc0206168 <commands+0x818>
ffffffffc02012d4:	11000593          	li	a1,272
ffffffffc02012d8:	00005517          	auipc	a0,0x5
ffffffffc02012dc:	ea850513          	addi	a0,a0,-344 # ffffffffc0206180 <commands+0x830>
ffffffffc02012e0:	9aeff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02012e4:	00005697          	auipc	a3,0x5
ffffffffc02012e8:	f3468693          	addi	a3,a3,-204 # ffffffffc0206218 <commands+0x8c8>
ffffffffc02012ec:	00005617          	auipc	a2,0x5
ffffffffc02012f0:	e7c60613          	addi	a2,a2,-388 # ffffffffc0206168 <commands+0x818>
ffffffffc02012f4:	0db00593          	li	a1,219
ffffffffc02012f8:	00005517          	auipc	a0,0x5
ffffffffc02012fc:	e8850513          	addi	a0,a0,-376 # ffffffffc0206180 <commands+0x830>
ffffffffc0201300:	98eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201304:	00005697          	auipc	a3,0x5
ffffffffc0201308:	f3c68693          	addi	a3,a3,-196 # ffffffffc0206240 <commands+0x8f0>
ffffffffc020130c:	00005617          	auipc	a2,0x5
ffffffffc0201310:	e5c60613          	addi	a2,a2,-420 # ffffffffc0206168 <commands+0x818>
ffffffffc0201314:	0dc00593          	li	a1,220
ffffffffc0201318:	00005517          	auipc	a0,0x5
ffffffffc020131c:	e6850513          	addi	a0,a0,-408 # ffffffffc0206180 <commands+0x830>
ffffffffc0201320:	96eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201324:	00005697          	auipc	a3,0x5
ffffffffc0201328:	f5c68693          	addi	a3,a3,-164 # ffffffffc0206280 <commands+0x930>
ffffffffc020132c:	00005617          	auipc	a2,0x5
ffffffffc0201330:	e3c60613          	addi	a2,a2,-452 # ffffffffc0206168 <commands+0x818>
ffffffffc0201334:	0de00593          	li	a1,222
ffffffffc0201338:	00005517          	auipc	a0,0x5
ffffffffc020133c:	e4850513          	addi	a0,a0,-440 # ffffffffc0206180 <commands+0x830>
ffffffffc0201340:	94eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201344:	00005697          	auipc	a3,0x5
ffffffffc0201348:	fc468693          	addi	a3,a3,-60 # ffffffffc0206308 <commands+0x9b8>
ffffffffc020134c:	00005617          	auipc	a2,0x5
ffffffffc0201350:	e1c60613          	addi	a2,a2,-484 # ffffffffc0206168 <commands+0x818>
ffffffffc0201354:	0f700593          	li	a1,247
ffffffffc0201358:	00005517          	auipc	a0,0x5
ffffffffc020135c:	e2850513          	addi	a0,a0,-472 # ffffffffc0206180 <commands+0x830>
ffffffffc0201360:	92eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201364:	00005697          	auipc	a3,0x5
ffffffffc0201368:	e5468693          	addi	a3,a3,-428 # ffffffffc02061b8 <commands+0x868>
ffffffffc020136c:	00005617          	auipc	a2,0x5
ffffffffc0201370:	dfc60613          	addi	a2,a2,-516 # ffffffffc0206168 <commands+0x818>
ffffffffc0201374:	0f000593          	li	a1,240
ffffffffc0201378:	00005517          	auipc	a0,0x5
ffffffffc020137c:	e0850513          	addi	a0,a0,-504 # ffffffffc0206180 <commands+0x830>
ffffffffc0201380:	90eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc0201384:	00005697          	auipc	a3,0x5
ffffffffc0201388:	f7468693          	addi	a3,a3,-140 # ffffffffc02062f8 <commands+0x9a8>
ffffffffc020138c:	00005617          	auipc	a2,0x5
ffffffffc0201390:	ddc60613          	addi	a2,a2,-548 # ffffffffc0206168 <commands+0x818>
ffffffffc0201394:	0ee00593          	li	a1,238
ffffffffc0201398:	00005517          	auipc	a0,0x5
ffffffffc020139c:	de850513          	addi	a0,a0,-536 # ffffffffc0206180 <commands+0x830>
ffffffffc02013a0:	8eeff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013a4:	00005697          	auipc	a3,0x5
ffffffffc02013a8:	f3c68693          	addi	a3,a3,-196 # ffffffffc02062e0 <commands+0x990>
ffffffffc02013ac:	00005617          	auipc	a2,0x5
ffffffffc02013b0:	dbc60613          	addi	a2,a2,-580 # ffffffffc0206168 <commands+0x818>
ffffffffc02013b4:	0e900593          	li	a1,233
ffffffffc02013b8:	00005517          	auipc	a0,0x5
ffffffffc02013bc:	dc850513          	addi	a0,a0,-568 # ffffffffc0206180 <commands+0x830>
ffffffffc02013c0:	8ceff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02013c4:	00005697          	auipc	a3,0x5
ffffffffc02013c8:	efc68693          	addi	a3,a3,-260 # ffffffffc02062c0 <commands+0x970>
ffffffffc02013cc:	00005617          	auipc	a2,0x5
ffffffffc02013d0:	d9c60613          	addi	a2,a2,-612 # ffffffffc0206168 <commands+0x818>
ffffffffc02013d4:	0e000593          	li	a1,224
ffffffffc02013d8:	00005517          	auipc	a0,0x5
ffffffffc02013dc:	da850513          	addi	a0,a0,-600 # ffffffffc0206180 <commands+0x830>
ffffffffc02013e0:	8aeff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc02013e4:	00005697          	auipc	a3,0x5
ffffffffc02013e8:	f6c68693          	addi	a3,a3,-148 # ffffffffc0206350 <commands+0xa00>
ffffffffc02013ec:	00005617          	auipc	a2,0x5
ffffffffc02013f0:	d7c60613          	addi	a2,a2,-644 # ffffffffc0206168 <commands+0x818>
ffffffffc02013f4:	11800593          	li	a1,280
ffffffffc02013f8:	00005517          	auipc	a0,0x5
ffffffffc02013fc:	d8850513          	addi	a0,a0,-632 # ffffffffc0206180 <commands+0x830>
ffffffffc0201400:	88eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc0201404:	00005697          	auipc	a3,0x5
ffffffffc0201408:	f3c68693          	addi	a3,a3,-196 # ffffffffc0206340 <commands+0x9f0>
ffffffffc020140c:	00005617          	auipc	a2,0x5
ffffffffc0201410:	d5c60613          	addi	a2,a2,-676 # ffffffffc0206168 <commands+0x818>
ffffffffc0201414:	0fd00593          	li	a1,253
ffffffffc0201418:	00005517          	auipc	a0,0x5
ffffffffc020141c:	d6850513          	addi	a0,a0,-664 # ffffffffc0206180 <commands+0x830>
ffffffffc0201420:	86eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201424:	00005697          	auipc	a3,0x5
ffffffffc0201428:	ebc68693          	addi	a3,a3,-324 # ffffffffc02062e0 <commands+0x990>
ffffffffc020142c:	00005617          	auipc	a2,0x5
ffffffffc0201430:	d3c60613          	addi	a2,a2,-708 # ffffffffc0206168 <commands+0x818>
ffffffffc0201434:	0fb00593          	li	a1,251
ffffffffc0201438:	00005517          	auipc	a0,0x5
ffffffffc020143c:	d4850513          	addi	a0,a0,-696 # ffffffffc0206180 <commands+0x830>
ffffffffc0201440:	84eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201444:	00005697          	auipc	a3,0x5
ffffffffc0201448:	edc68693          	addi	a3,a3,-292 # ffffffffc0206320 <commands+0x9d0>
ffffffffc020144c:	00005617          	auipc	a2,0x5
ffffffffc0201450:	d1c60613          	addi	a2,a2,-740 # ffffffffc0206168 <commands+0x818>
ffffffffc0201454:	0fa00593          	li	a1,250
ffffffffc0201458:	00005517          	auipc	a0,0x5
ffffffffc020145c:	d2850513          	addi	a0,a0,-728 # ffffffffc0206180 <commands+0x830>
ffffffffc0201460:	82eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201464:	00005697          	auipc	a3,0x5
ffffffffc0201468:	d5468693          	addi	a3,a3,-684 # ffffffffc02061b8 <commands+0x868>
ffffffffc020146c:	00005617          	auipc	a2,0x5
ffffffffc0201470:	cfc60613          	addi	a2,a2,-772 # ffffffffc0206168 <commands+0x818>
ffffffffc0201474:	0d700593          	li	a1,215
ffffffffc0201478:	00005517          	auipc	a0,0x5
ffffffffc020147c:	d0850513          	addi	a0,a0,-760 # ffffffffc0206180 <commands+0x830>
ffffffffc0201480:	80eff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201484:	00005697          	auipc	a3,0x5
ffffffffc0201488:	e5c68693          	addi	a3,a3,-420 # ffffffffc02062e0 <commands+0x990>
ffffffffc020148c:	00005617          	auipc	a2,0x5
ffffffffc0201490:	cdc60613          	addi	a2,a2,-804 # ffffffffc0206168 <commands+0x818>
ffffffffc0201494:	0f400593          	li	a1,244
ffffffffc0201498:	00005517          	auipc	a0,0x5
ffffffffc020149c:	ce850513          	addi	a0,a0,-792 # ffffffffc0206180 <commands+0x830>
ffffffffc02014a0:	feffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014a4:	00005697          	auipc	a3,0x5
ffffffffc02014a8:	d5468693          	addi	a3,a3,-684 # ffffffffc02061f8 <commands+0x8a8>
ffffffffc02014ac:	00005617          	auipc	a2,0x5
ffffffffc02014b0:	cbc60613          	addi	a2,a2,-836 # ffffffffc0206168 <commands+0x818>
ffffffffc02014b4:	0f200593          	li	a1,242
ffffffffc02014b8:	00005517          	auipc	a0,0x5
ffffffffc02014bc:	cc850513          	addi	a0,a0,-824 # ffffffffc0206180 <commands+0x830>
ffffffffc02014c0:	fcffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02014c4:	00005697          	auipc	a3,0x5
ffffffffc02014c8:	d1468693          	addi	a3,a3,-748 # ffffffffc02061d8 <commands+0x888>
ffffffffc02014cc:	00005617          	auipc	a2,0x5
ffffffffc02014d0:	c9c60613          	addi	a2,a2,-868 # ffffffffc0206168 <commands+0x818>
ffffffffc02014d4:	0f100593          	li	a1,241
ffffffffc02014d8:	00005517          	auipc	a0,0x5
ffffffffc02014dc:	ca850513          	addi	a0,a0,-856 # ffffffffc0206180 <commands+0x830>
ffffffffc02014e0:	faffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014e4:	00005697          	auipc	a3,0x5
ffffffffc02014e8:	d1468693          	addi	a3,a3,-748 # ffffffffc02061f8 <commands+0x8a8>
ffffffffc02014ec:	00005617          	auipc	a2,0x5
ffffffffc02014f0:	c7c60613          	addi	a2,a2,-900 # ffffffffc0206168 <commands+0x818>
ffffffffc02014f4:	0d900593          	li	a1,217
ffffffffc02014f8:	00005517          	auipc	a0,0x5
ffffffffc02014fc:	c8850513          	addi	a0,a0,-888 # ffffffffc0206180 <commands+0x830>
ffffffffc0201500:	f8ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc0201504:	00005697          	auipc	a3,0x5
ffffffffc0201508:	f9c68693          	addi	a3,a3,-100 # ffffffffc02064a0 <commands+0xb50>
ffffffffc020150c:	00005617          	auipc	a2,0x5
ffffffffc0201510:	c5c60613          	addi	a2,a2,-932 # ffffffffc0206168 <commands+0x818>
ffffffffc0201514:	14600593          	li	a1,326
ffffffffc0201518:	00005517          	auipc	a0,0x5
ffffffffc020151c:	c6850513          	addi	a0,a0,-920 # ffffffffc0206180 <commands+0x830>
ffffffffc0201520:	f6ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc0201524:	00005697          	auipc	a3,0x5
ffffffffc0201528:	e1c68693          	addi	a3,a3,-484 # ffffffffc0206340 <commands+0x9f0>
ffffffffc020152c:	00005617          	auipc	a2,0x5
ffffffffc0201530:	c3c60613          	addi	a2,a2,-964 # ffffffffc0206168 <commands+0x818>
ffffffffc0201534:	13a00593          	li	a1,314
ffffffffc0201538:	00005517          	auipc	a0,0x5
ffffffffc020153c:	c4850513          	addi	a0,a0,-952 # ffffffffc0206180 <commands+0x830>
ffffffffc0201540:	f4ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201544:	00005697          	auipc	a3,0x5
ffffffffc0201548:	d9c68693          	addi	a3,a3,-612 # ffffffffc02062e0 <commands+0x990>
ffffffffc020154c:	00005617          	auipc	a2,0x5
ffffffffc0201550:	c1c60613          	addi	a2,a2,-996 # ffffffffc0206168 <commands+0x818>
ffffffffc0201554:	13800593          	li	a1,312
ffffffffc0201558:	00005517          	auipc	a0,0x5
ffffffffc020155c:	c2850513          	addi	a0,a0,-984 # ffffffffc0206180 <commands+0x830>
ffffffffc0201560:	f2ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201564:	00005697          	auipc	a3,0x5
ffffffffc0201568:	d3c68693          	addi	a3,a3,-708 # ffffffffc02062a0 <commands+0x950>
ffffffffc020156c:	00005617          	auipc	a2,0x5
ffffffffc0201570:	bfc60613          	addi	a2,a2,-1028 # ffffffffc0206168 <commands+0x818>
ffffffffc0201574:	0df00593          	li	a1,223
ffffffffc0201578:	00005517          	auipc	a0,0x5
ffffffffc020157c:	c0850513          	addi	a0,a0,-1016 # ffffffffc0206180 <commands+0x830>
ffffffffc0201580:	f0ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201584:	00005697          	auipc	a3,0x5
ffffffffc0201588:	edc68693          	addi	a3,a3,-292 # ffffffffc0206460 <commands+0xb10>
ffffffffc020158c:	00005617          	auipc	a2,0x5
ffffffffc0201590:	bdc60613          	addi	a2,a2,-1060 # ffffffffc0206168 <commands+0x818>
ffffffffc0201594:	13200593          	li	a1,306
ffffffffc0201598:	00005517          	auipc	a0,0x5
ffffffffc020159c:	be850513          	addi	a0,a0,-1048 # ffffffffc0206180 <commands+0x830>
ffffffffc02015a0:	eeffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02015a4:	00005697          	auipc	a3,0x5
ffffffffc02015a8:	e9c68693          	addi	a3,a3,-356 # ffffffffc0206440 <commands+0xaf0>
ffffffffc02015ac:	00005617          	auipc	a2,0x5
ffffffffc02015b0:	bbc60613          	addi	a2,a2,-1092 # ffffffffc0206168 <commands+0x818>
ffffffffc02015b4:	13000593          	li	a1,304
ffffffffc02015b8:	00005517          	auipc	a0,0x5
ffffffffc02015bc:	bc850513          	addi	a0,a0,-1080 # ffffffffc0206180 <commands+0x830>
ffffffffc02015c0:	ecffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02015c4:	00005697          	auipc	a3,0x5
ffffffffc02015c8:	e5468693          	addi	a3,a3,-428 # ffffffffc0206418 <commands+0xac8>
ffffffffc02015cc:	00005617          	auipc	a2,0x5
ffffffffc02015d0:	b9c60613          	addi	a2,a2,-1124 # ffffffffc0206168 <commands+0x818>
ffffffffc02015d4:	12e00593          	li	a1,302
ffffffffc02015d8:	00005517          	auipc	a0,0x5
ffffffffc02015dc:	ba850513          	addi	a0,a0,-1112 # ffffffffc0206180 <commands+0x830>
ffffffffc02015e0:	eaffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02015e4:	00005697          	auipc	a3,0x5
ffffffffc02015e8:	e0c68693          	addi	a3,a3,-500 # ffffffffc02063f0 <commands+0xaa0>
ffffffffc02015ec:	00005617          	auipc	a2,0x5
ffffffffc02015f0:	b7c60613          	addi	a2,a2,-1156 # ffffffffc0206168 <commands+0x818>
ffffffffc02015f4:	12d00593          	li	a1,301
ffffffffc02015f8:	00005517          	auipc	a0,0x5
ffffffffc02015fc:	b8850513          	addi	a0,a0,-1144 # ffffffffc0206180 <commands+0x830>
ffffffffc0201600:	e8ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201604:	00005697          	auipc	a3,0x5
ffffffffc0201608:	ddc68693          	addi	a3,a3,-548 # ffffffffc02063e0 <commands+0xa90>
ffffffffc020160c:	00005617          	auipc	a2,0x5
ffffffffc0201610:	b5c60613          	addi	a2,a2,-1188 # ffffffffc0206168 <commands+0x818>
ffffffffc0201614:	12800593          	li	a1,296
ffffffffc0201618:	00005517          	auipc	a0,0x5
ffffffffc020161c:	b6850513          	addi	a0,a0,-1176 # ffffffffc0206180 <commands+0x830>
ffffffffc0201620:	e6ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201624:	00005697          	auipc	a3,0x5
ffffffffc0201628:	cbc68693          	addi	a3,a3,-836 # ffffffffc02062e0 <commands+0x990>
ffffffffc020162c:	00005617          	auipc	a2,0x5
ffffffffc0201630:	b3c60613          	addi	a2,a2,-1220 # ffffffffc0206168 <commands+0x818>
ffffffffc0201634:	12700593          	li	a1,295
ffffffffc0201638:	00005517          	auipc	a0,0x5
ffffffffc020163c:	b4850513          	addi	a0,a0,-1208 # ffffffffc0206180 <commands+0x830>
ffffffffc0201640:	e4ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201644:	00005697          	auipc	a3,0x5
ffffffffc0201648:	d7c68693          	addi	a3,a3,-644 # ffffffffc02063c0 <commands+0xa70>
ffffffffc020164c:	00005617          	auipc	a2,0x5
ffffffffc0201650:	b1c60613          	addi	a2,a2,-1252 # ffffffffc0206168 <commands+0x818>
ffffffffc0201654:	12600593          	li	a1,294
ffffffffc0201658:	00005517          	auipc	a0,0x5
ffffffffc020165c:	b2850513          	addi	a0,a0,-1240 # ffffffffc0206180 <commands+0x830>
ffffffffc0201660:	e2ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201664:	00005697          	auipc	a3,0x5
ffffffffc0201668:	d2c68693          	addi	a3,a3,-724 # ffffffffc0206390 <commands+0xa40>
ffffffffc020166c:	00005617          	auipc	a2,0x5
ffffffffc0201670:	afc60613          	addi	a2,a2,-1284 # ffffffffc0206168 <commands+0x818>
ffffffffc0201674:	12500593          	li	a1,293
ffffffffc0201678:	00005517          	auipc	a0,0x5
ffffffffc020167c:	b0850513          	addi	a0,a0,-1272 # ffffffffc0206180 <commands+0x830>
ffffffffc0201680:	e0ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201684:	00005697          	auipc	a3,0x5
ffffffffc0201688:	cf468693          	addi	a3,a3,-780 # ffffffffc0206378 <commands+0xa28>
ffffffffc020168c:	00005617          	auipc	a2,0x5
ffffffffc0201690:	adc60613          	addi	a2,a2,-1316 # ffffffffc0206168 <commands+0x818>
ffffffffc0201694:	12400593          	li	a1,292
ffffffffc0201698:	00005517          	auipc	a0,0x5
ffffffffc020169c:	ae850513          	addi	a0,a0,-1304 # ffffffffc0206180 <commands+0x830>
ffffffffc02016a0:	deffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02016a4:	00005697          	auipc	a3,0x5
ffffffffc02016a8:	c3c68693          	addi	a3,a3,-964 # ffffffffc02062e0 <commands+0x990>
ffffffffc02016ac:	00005617          	auipc	a2,0x5
ffffffffc02016b0:	abc60613          	addi	a2,a2,-1348 # ffffffffc0206168 <commands+0x818>
ffffffffc02016b4:	11e00593          	li	a1,286
ffffffffc02016b8:	00005517          	auipc	a0,0x5
ffffffffc02016bc:	ac850513          	addi	a0,a0,-1336 # ffffffffc0206180 <commands+0x830>
ffffffffc02016c0:	dcffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc02016c4:	00005697          	auipc	a3,0x5
ffffffffc02016c8:	c9c68693          	addi	a3,a3,-868 # ffffffffc0206360 <commands+0xa10>
ffffffffc02016cc:	00005617          	auipc	a2,0x5
ffffffffc02016d0:	a9c60613          	addi	a2,a2,-1380 # ffffffffc0206168 <commands+0x818>
ffffffffc02016d4:	11900593          	li	a1,281
ffffffffc02016d8:	00005517          	auipc	a0,0x5
ffffffffc02016dc:	aa850513          	addi	a0,a0,-1368 # ffffffffc0206180 <commands+0x830>
ffffffffc02016e0:	daffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02016e4:	00005697          	auipc	a3,0x5
ffffffffc02016e8:	d9c68693          	addi	a3,a3,-612 # ffffffffc0206480 <commands+0xb30>
ffffffffc02016ec:	00005617          	auipc	a2,0x5
ffffffffc02016f0:	a7c60613          	addi	a2,a2,-1412 # ffffffffc0206168 <commands+0x818>
ffffffffc02016f4:	13700593          	li	a1,311
ffffffffc02016f8:	00005517          	auipc	a0,0x5
ffffffffc02016fc:	a8850513          	addi	a0,a0,-1400 # ffffffffc0206180 <commands+0x830>
ffffffffc0201700:	d8ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc0201704:	00005697          	auipc	a3,0x5
ffffffffc0201708:	dac68693          	addi	a3,a3,-596 # ffffffffc02064b0 <commands+0xb60>
ffffffffc020170c:	00005617          	auipc	a2,0x5
ffffffffc0201710:	a5c60613          	addi	a2,a2,-1444 # ffffffffc0206168 <commands+0x818>
ffffffffc0201714:	14700593          	li	a1,327
ffffffffc0201718:	00005517          	auipc	a0,0x5
ffffffffc020171c:	a6850513          	addi	a0,a0,-1432 # ffffffffc0206180 <commands+0x830>
ffffffffc0201720:	d6ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc0201724:	00005697          	auipc	a3,0x5
ffffffffc0201728:	a7468693          	addi	a3,a3,-1420 # ffffffffc0206198 <commands+0x848>
ffffffffc020172c:	00005617          	auipc	a2,0x5
ffffffffc0201730:	a3c60613          	addi	a2,a2,-1476 # ffffffffc0206168 <commands+0x818>
ffffffffc0201734:	11300593          	li	a1,275
ffffffffc0201738:	00005517          	auipc	a0,0x5
ffffffffc020173c:	a4850513          	addi	a0,a0,-1464 # ffffffffc0206180 <commands+0x830>
ffffffffc0201740:	d4ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201744:	00005697          	auipc	a3,0x5
ffffffffc0201748:	a9468693          	addi	a3,a3,-1388 # ffffffffc02061d8 <commands+0x888>
ffffffffc020174c:	00005617          	auipc	a2,0x5
ffffffffc0201750:	a1c60613          	addi	a2,a2,-1508 # ffffffffc0206168 <commands+0x818>
ffffffffc0201754:	0d800593          	li	a1,216
ffffffffc0201758:	00005517          	auipc	a0,0x5
ffffffffc020175c:	a2850513          	addi	a0,a0,-1496 # ffffffffc0206180 <commands+0x830>
ffffffffc0201760:	d2ffe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201764 <default_free_pages>:
{
ffffffffc0201764:	1141                	addi	sp,sp,-16
ffffffffc0201766:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201768:	14058463          	beqz	a1,ffffffffc02018b0 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc020176c:	00659693          	slli	a3,a1,0x6
ffffffffc0201770:	96aa                	add	a3,a3,a0
ffffffffc0201772:	87aa                	mv	a5,a0
ffffffffc0201774:	02d50263          	beq	a0,a3,ffffffffc0201798 <default_free_pages+0x34>
ffffffffc0201778:	6798                	ld	a4,8(a5)
ffffffffc020177a:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020177c:	10071a63          	bnez	a4,ffffffffc0201890 <default_free_pages+0x12c>
ffffffffc0201780:	6798                	ld	a4,8(a5)
ffffffffc0201782:	8b09                	andi	a4,a4,2
ffffffffc0201784:	10071663          	bnez	a4,ffffffffc0201890 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201788:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc020178c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201790:	04078793          	addi	a5,a5,64
ffffffffc0201794:	fed792e3          	bne	a5,a3,ffffffffc0201778 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201798:	2581                	sext.w	a1,a1
ffffffffc020179a:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020179c:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017a0:	4789                	li	a5,2
ffffffffc02017a2:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02017a6:	000a5697          	auipc	a3,0xa5
ffffffffc02017aa:	eea68693          	addi	a3,a3,-278 # ffffffffc02a6690 <free_area>
ffffffffc02017ae:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02017b0:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02017b2:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02017b6:	9db9                	addw	a1,a1,a4
ffffffffc02017b8:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02017ba:	0ad78463          	beq	a5,a3,ffffffffc0201862 <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc02017be:	fe878713          	addi	a4,a5,-24
ffffffffc02017c2:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02017c6:	4581                	li	a1,0
            if (base < page)
ffffffffc02017c8:	00e56a63          	bltu	a0,a4,ffffffffc02017dc <default_free_pages+0x78>
    return listelm->next;
ffffffffc02017cc:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02017ce:	04d70c63          	beq	a4,a3,ffffffffc0201826 <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc02017d2:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02017d4:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02017d8:	fee57ae3          	bgeu	a0,a4,ffffffffc02017cc <default_free_pages+0x68>
ffffffffc02017dc:	c199                	beqz	a1,ffffffffc02017e2 <default_free_pages+0x7e>
ffffffffc02017de:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017e2:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02017e4:	e390                	sd	a2,0(a5)
ffffffffc02017e6:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02017e8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017ea:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc02017ec:	00d70d63          	beq	a4,a3,ffffffffc0201806 <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02017f0:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02017f4:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02017f8:	02059813          	slli	a6,a1,0x20
ffffffffc02017fc:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201800:	97b2                	add	a5,a5,a2
ffffffffc0201802:	02f50c63          	beq	a0,a5,ffffffffc020183a <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0201806:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0201808:	00d78c63          	beq	a5,a3,ffffffffc0201820 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc020180c:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc020180e:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc0201812:	02061593          	slli	a1,a2,0x20
ffffffffc0201816:	01a5d713          	srli	a4,a1,0x1a
ffffffffc020181a:	972a                	add	a4,a4,a0
ffffffffc020181c:	04e68a63          	beq	a3,a4,ffffffffc0201870 <default_free_pages+0x10c>
}
ffffffffc0201820:	60a2                	ld	ra,8(sp)
ffffffffc0201822:	0141                	addi	sp,sp,16
ffffffffc0201824:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201826:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201828:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020182a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020182c:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc020182e:	02d70763          	beq	a4,a3,ffffffffc020185c <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0201832:	8832                	mv	a6,a2
ffffffffc0201834:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201836:	87ba                	mv	a5,a4
ffffffffc0201838:	bf71                	j	ffffffffc02017d4 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc020183a:	491c                	lw	a5,16(a0)
ffffffffc020183c:	9dbd                	addw	a1,a1,a5
ffffffffc020183e:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201842:	57f5                	li	a5,-3
ffffffffc0201844:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201848:	01853803          	ld	a6,24(a0)
ffffffffc020184c:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc020184e:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201850:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201854:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201856:	0105b023          	sd	a6,0(a1)
ffffffffc020185a:	b77d                	j	ffffffffc0201808 <default_free_pages+0xa4>
ffffffffc020185c:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc020185e:	873e                	mv	a4,a5
ffffffffc0201860:	bf41                	j	ffffffffc02017f0 <default_free_pages+0x8c>
}
ffffffffc0201862:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201864:	e390                	sd	a2,0(a5)
ffffffffc0201866:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201868:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020186a:	ed1c                	sd	a5,24(a0)
ffffffffc020186c:	0141                	addi	sp,sp,16
ffffffffc020186e:	8082                	ret
            base->property += p->property;
ffffffffc0201870:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201874:	ff078693          	addi	a3,a5,-16
ffffffffc0201878:	9e39                	addw	a2,a2,a4
ffffffffc020187a:	c910                	sw	a2,16(a0)
ffffffffc020187c:	5775                	li	a4,-3
ffffffffc020187e:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201882:	6398                	ld	a4,0(a5)
ffffffffc0201884:	679c                	ld	a5,8(a5)
}
ffffffffc0201886:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201888:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020188a:	e398                	sd	a4,0(a5)
ffffffffc020188c:	0141                	addi	sp,sp,16
ffffffffc020188e:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201890:	00005697          	auipc	a3,0x5
ffffffffc0201894:	c3868693          	addi	a3,a3,-968 # ffffffffc02064c8 <commands+0xb78>
ffffffffc0201898:	00005617          	auipc	a2,0x5
ffffffffc020189c:	8d060613          	addi	a2,a2,-1840 # ffffffffc0206168 <commands+0x818>
ffffffffc02018a0:	09400593          	li	a1,148
ffffffffc02018a4:	00005517          	auipc	a0,0x5
ffffffffc02018a8:	8dc50513          	addi	a0,a0,-1828 # ffffffffc0206180 <commands+0x830>
ffffffffc02018ac:	be3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc02018b0:	00005697          	auipc	a3,0x5
ffffffffc02018b4:	c1068693          	addi	a3,a3,-1008 # ffffffffc02064c0 <commands+0xb70>
ffffffffc02018b8:	00005617          	auipc	a2,0x5
ffffffffc02018bc:	8b060613          	addi	a2,a2,-1872 # ffffffffc0206168 <commands+0x818>
ffffffffc02018c0:	09000593          	li	a1,144
ffffffffc02018c4:	00005517          	auipc	a0,0x5
ffffffffc02018c8:	8bc50513          	addi	a0,a0,-1860 # ffffffffc0206180 <commands+0x830>
ffffffffc02018cc:	bc3fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02018d0 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02018d0:	c941                	beqz	a0,ffffffffc0201960 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc02018d2:	000a5597          	auipc	a1,0xa5
ffffffffc02018d6:	dbe58593          	addi	a1,a1,-578 # ffffffffc02a6690 <free_area>
ffffffffc02018da:	0105a803          	lw	a6,16(a1)
ffffffffc02018de:	872a                	mv	a4,a0
ffffffffc02018e0:	02081793          	slli	a5,a6,0x20
ffffffffc02018e4:	9381                	srli	a5,a5,0x20
ffffffffc02018e6:	00a7ee63          	bltu	a5,a0,ffffffffc0201902 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02018ea:	87ae                	mv	a5,a1
ffffffffc02018ec:	a801                	j	ffffffffc02018fc <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc02018ee:	ff87a683          	lw	a3,-8(a5)
ffffffffc02018f2:	02069613          	slli	a2,a3,0x20
ffffffffc02018f6:	9201                	srli	a2,a2,0x20
ffffffffc02018f8:	00e67763          	bgeu	a2,a4,ffffffffc0201906 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02018fc:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02018fe:	feb798e3          	bne	a5,a1,ffffffffc02018ee <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201902:	4501                	li	a0,0
}
ffffffffc0201904:	8082                	ret
    return listelm->prev;
ffffffffc0201906:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020190a:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc020190e:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201912:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0201916:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc020191a:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc020191e:	02c77863          	bgeu	a4,a2,ffffffffc020194e <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0201922:	071a                	slli	a4,a4,0x6
ffffffffc0201924:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201926:	41c686bb          	subw	a3,a3,t3
ffffffffc020192a:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020192c:	00870613          	addi	a2,a4,8
ffffffffc0201930:	4689                	li	a3,2
ffffffffc0201932:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201936:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc020193a:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc020193e:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201942:	e290                	sd	a2,0(a3)
ffffffffc0201944:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201948:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc020194a:	01173c23          	sd	a7,24(a4)
ffffffffc020194e:	41c8083b          	subw	a6,a6,t3
ffffffffc0201952:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201956:	5775                	li	a4,-3
ffffffffc0201958:	17c1                	addi	a5,a5,-16
ffffffffc020195a:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020195e:	8082                	ret
{
ffffffffc0201960:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201962:	00005697          	auipc	a3,0x5
ffffffffc0201966:	b5e68693          	addi	a3,a3,-1186 # ffffffffc02064c0 <commands+0xb70>
ffffffffc020196a:	00004617          	auipc	a2,0x4
ffffffffc020196e:	7fe60613          	addi	a2,a2,2046 # ffffffffc0206168 <commands+0x818>
ffffffffc0201972:	06c00593          	li	a1,108
ffffffffc0201976:	00005517          	auipc	a0,0x5
ffffffffc020197a:	80a50513          	addi	a0,a0,-2038 # ffffffffc0206180 <commands+0x830>
{
ffffffffc020197e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201980:	b0ffe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201984 <default_init_memmap>:
{
ffffffffc0201984:	1141                	addi	sp,sp,-16
ffffffffc0201986:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201988:	c5f1                	beqz	a1,ffffffffc0201a54 <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc020198a:	00659693          	slli	a3,a1,0x6
ffffffffc020198e:	96aa                	add	a3,a3,a0
ffffffffc0201990:	87aa                	mv	a5,a0
ffffffffc0201992:	00d50f63          	beq	a0,a3,ffffffffc02019b0 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201996:	6798                	ld	a4,8(a5)
ffffffffc0201998:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc020199a:	cf49                	beqz	a4,ffffffffc0201a34 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc020199c:	0007a823          	sw	zero,16(a5)
ffffffffc02019a0:	0007b423          	sd	zero,8(a5)
ffffffffc02019a4:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02019a8:	04078793          	addi	a5,a5,64
ffffffffc02019ac:	fed795e3          	bne	a5,a3,ffffffffc0201996 <default_init_memmap+0x12>
    base->property = n;
ffffffffc02019b0:	2581                	sext.w	a1,a1
ffffffffc02019b2:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02019b4:	4789                	li	a5,2
ffffffffc02019b6:	00850713          	addi	a4,a0,8
ffffffffc02019ba:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02019be:	000a5697          	auipc	a3,0xa5
ffffffffc02019c2:	cd268693          	addi	a3,a3,-814 # ffffffffc02a6690 <free_area>
ffffffffc02019c6:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02019c8:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02019ca:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02019ce:	9db9                	addw	a1,a1,a4
ffffffffc02019d0:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02019d2:	04d78a63          	beq	a5,a3,ffffffffc0201a26 <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc02019d6:	fe878713          	addi	a4,a5,-24
ffffffffc02019da:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02019de:	4581                	li	a1,0
            if (base < page)
ffffffffc02019e0:	00e56a63          	bltu	a0,a4,ffffffffc02019f4 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02019e4:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02019e6:	02d70263          	beq	a4,a3,ffffffffc0201a0a <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc02019ea:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02019ec:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02019f0:	fee57ae3          	bgeu	a0,a4,ffffffffc02019e4 <default_init_memmap+0x60>
ffffffffc02019f4:	c199                	beqz	a1,ffffffffc02019fa <default_init_memmap+0x76>
ffffffffc02019f6:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02019fa:	6398                	ld	a4,0(a5)
}
ffffffffc02019fc:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02019fe:	e390                	sd	a2,0(a5)
ffffffffc0201a00:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201a02:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a04:	ed18                	sd	a4,24(a0)
ffffffffc0201a06:	0141                	addi	sp,sp,16
ffffffffc0201a08:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201a0a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a0c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201a0e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201a10:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201a12:	00d70663          	beq	a4,a3,ffffffffc0201a1e <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201a16:	8832                	mv	a6,a2
ffffffffc0201a18:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201a1a:	87ba                	mv	a5,a4
ffffffffc0201a1c:	bfc1                	j	ffffffffc02019ec <default_init_memmap+0x68>
}
ffffffffc0201a1e:	60a2                	ld	ra,8(sp)
ffffffffc0201a20:	e290                	sd	a2,0(a3)
ffffffffc0201a22:	0141                	addi	sp,sp,16
ffffffffc0201a24:	8082                	ret
ffffffffc0201a26:	60a2                	ld	ra,8(sp)
ffffffffc0201a28:	e390                	sd	a2,0(a5)
ffffffffc0201a2a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a2c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a2e:	ed1c                	sd	a5,24(a0)
ffffffffc0201a30:	0141                	addi	sp,sp,16
ffffffffc0201a32:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201a34:	00005697          	auipc	a3,0x5
ffffffffc0201a38:	abc68693          	addi	a3,a3,-1348 # ffffffffc02064f0 <commands+0xba0>
ffffffffc0201a3c:	00004617          	auipc	a2,0x4
ffffffffc0201a40:	72c60613          	addi	a2,a2,1836 # ffffffffc0206168 <commands+0x818>
ffffffffc0201a44:	04b00593          	li	a1,75
ffffffffc0201a48:	00004517          	auipc	a0,0x4
ffffffffc0201a4c:	73850513          	addi	a0,a0,1848 # ffffffffc0206180 <commands+0x830>
ffffffffc0201a50:	a3ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201a54:	00005697          	auipc	a3,0x5
ffffffffc0201a58:	a6c68693          	addi	a3,a3,-1428 # ffffffffc02064c0 <commands+0xb70>
ffffffffc0201a5c:	00004617          	auipc	a2,0x4
ffffffffc0201a60:	70c60613          	addi	a2,a2,1804 # ffffffffc0206168 <commands+0x818>
ffffffffc0201a64:	04700593          	li	a1,71
ffffffffc0201a68:	00004517          	auipc	a0,0x4
ffffffffc0201a6c:	71850513          	addi	a0,a0,1816 # ffffffffc0206180 <commands+0x830>
ffffffffc0201a70:	a1ffe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201a74 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201a74:	c94d                	beqz	a0,ffffffffc0201b26 <slob_free+0xb2>
{
ffffffffc0201a76:	1141                	addi	sp,sp,-16
ffffffffc0201a78:	e022                	sd	s0,0(sp)
ffffffffc0201a7a:	e406                	sd	ra,8(sp)
ffffffffc0201a7c:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201a7e:	e9c1                	bnez	a1,ffffffffc0201b0e <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a80:	100027f3          	csrr	a5,sstatus
ffffffffc0201a84:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a86:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a88:	ebd9                	bnez	a5,ffffffffc0201b1e <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a8a:	000a4617          	auipc	a2,0xa4
ffffffffc0201a8e:	7f660613          	addi	a2,a2,2038 # ffffffffc02a6280 <slobfree>
ffffffffc0201a92:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a94:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a96:	679c                	ld	a5,8(a5)
ffffffffc0201a98:	02877a63          	bgeu	a4,s0,ffffffffc0201acc <slob_free+0x58>
ffffffffc0201a9c:	00f46463          	bltu	s0,a5,ffffffffc0201aa4 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201aa0:	fef76ae3          	bltu	a4,a5,ffffffffc0201a94 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201aa4:	400c                	lw	a1,0(s0)
ffffffffc0201aa6:	00459693          	slli	a3,a1,0x4
ffffffffc0201aaa:	96a2                	add	a3,a3,s0
ffffffffc0201aac:	02d78a63          	beq	a5,a3,ffffffffc0201ae0 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201ab0:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201ab2:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201ab4:	00469793          	slli	a5,a3,0x4
ffffffffc0201ab8:	97ba                	add	a5,a5,a4
ffffffffc0201aba:	02f40e63          	beq	s0,a5,ffffffffc0201af6 <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201abe:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201ac0:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201ac2:	e129                	bnez	a0,ffffffffc0201b04 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201ac4:	60a2                	ld	ra,8(sp)
ffffffffc0201ac6:	6402                	ld	s0,0(sp)
ffffffffc0201ac8:	0141                	addi	sp,sp,16
ffffffffc0201aca:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201acc:	fcf764e3          	bltu	a4,a5,ffffffffc0201a94 <slob_free+0x20>
ffffffffc0201ad0:	fcf472e3          	bgeu	s0,a5,ffffffffc0201a94 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201ad4:	400c                	lw	a1,0(s0)
ffffffffc0201ad6:	00459693          	slli	a3,a1,0x4
ffffffffc0201ada:	96a2                	add	a3,a3,s0
ffffffffc0201adc:	fcd79ae3          	bne	a5,a3,ffffffffc0201ab0 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201ae0:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201ae2:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201ae4:	9db5                	addw	a1,a1,a3
ffffffffc0201ae6:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201ae8:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201aea:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201aec:	00469793          	slli	a5,a3,0x4
ffffffffc0201af0:	97ba                	add	a5,a5,a4
ffffffffc0201af2:	fcf416e3          	bne	s0,a5,ffffffffc0201abe <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201af6:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201af8:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201afa:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201afc:	9ebd                	addw	a3,a3,a5
ffffffffc0201afe:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201b00:	e70c                	sd	a1,8(a4)
ffffffffc0201b02:	d169                	beqz	a0,ffffffffc0201ac4 <slob_free+0x50>
}
ffffffffc0201b04:	6402                	ld	s0,0(sp)
ffffffffc0201b06:	60a2                	ld	ra,8(sp)
ffffffffc0201b08:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201b0a:	ea5fe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201b0e:	25bd                	addiw	a1,a1,15
ffffffffc0201b10:	8191                	srli	a1,a1,0x4
ffffffffc0201b12:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b14:	100027f3          	csrr	a5,sstatus
ffffffffc0201b18:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201b1a:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b1c:	d7bd                	beqz	a5,ffffffffc0201a8a <slob_free+0x16>
        intr_disable();
ffffffffc0201b1e:	e97fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201b22:	4505                	li	a0,1
ffffffffc0201b24:	b79d                	j	ffffffffc0201a8a <slob_free+0x16>
ffffffffc0201b26:	8082                	ret

ffffffffc0201b28 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b28:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b2a:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b2c:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b30:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b32:	352000ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
	if (!page)
ffffffffc0201b36:	c91d                	beqz	a0,ffffffffc0201b6c <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201b38:	000a9697          	auipc	a3,0xa9
ffffffffc0201b3c:	bc86b683          	ld	a3,-1080(a3) # ffffffffc02aa700 <pages>
ffffffffc0201b40:	8d15                	sub	a0,a0,a3
ffffffffc0201b42:	8519                	srai	a0,a0,0x6
ffffffffc0201b44:	00006697          	auipc	a3,0x6
ffffffffc0201b48:	cfc6b683          	ld	a3,-772(a3) # ffffffffc0207840 <nbase>
ffffffffc0201b4c:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201b4e:	00c51793          	slli	a5,a0,0xc
ffffffffc0201b52:	83b1                	srli	a5,a5,0xc
ffffffffc0201b54:	000a9717          	auipc	a4,0xa9
ffffffffc0201b58:	ba473703          	ld	a4,-1116(a4) # ffffffffc02aa6f8 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b5c:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201b5e:	00e7fa63          	bgeu	a5,a4,ffffffffc0201b72 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201b62:	000a9697          	auipc	a3,0xa9
ffffffffc0201b66:	bae6b683          	ld	a3,-1106(a3) # ffffffffc02aa710 <va_pa_offset>
ffffffffc0201b6a:	9536                	add	a0,a0,a3
}
ffffffffc0201b6c:	60a2                	ld	ra,8(sp)
ffffffffc0201b6e:	0141                	addi	sp,sp,16
ffffffffc0201b70:	8082                	ret
ffffffffc0201b72:	86aa                	mv	a3,a0
ffffffffc0201b74:	00005617          	auipc	a2,0x5
ffffffffc0201b78:	9dc60613          	addi	a2,a2,-1572 # ffffffffc0206550 <default_pmm_manager+0x38>
ffffffffc0201b7c:	07100593          	li	a1,113
ffffffffc0201b80:	00005517          	auipc	a0,0x5
ffffffffc0201b84:	9f850513          	addi	a0,a0,-1544 # ffffffffc0206578 <default_pmm_manager+0x60>
ffffffffc0201b88:	907fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201b8c <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201b8c:	1101                	addi	sp,sp,-32
ffffffffc0201b8e:	ec06                	sd	ra,24(sp)
ffffffffc0201b90:	e822                	sd	s0,16(sp)
ffffffffc0201b92:	e426                	sd	s1,8(sp)
ffffffffc0201b94:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201b96:	01050713          	addi	a4,a0,16
ffffffffc0201b9a:	6785                	lui	a5,0x1
ffffffffc0201b9c:	0cf77363          	bgeu	a4,a5,ffffffffc0201c62 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201ba0:	00f50493          	addi	s1,a0,15
ffffffffc0201ba4:	8091                	srli	s1,s1,0x4
ffffffffc0201ba6:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ba8:	10002673          	csrr	a2,sstatus
ffffffffc0201bac:	8a09                	andi	a2,a2,2
ffffffffc0201bae:	e25d                	bnez	a2,ffffffffc0201c54 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201bb0:	000a4917          	auipc	s2,0xa4
ffffffffc0201bb4:	6d090913          	addi	s2,s2,1744 # ffffffffc02a6280 <slobfree>
ffffffffc0201bb8:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bbc:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201bbe:	4398                	lw	a4,0(a5)
ffffffffc0201bc0:	08975e63          	bge	a4,s1,ffffffffc0201c5c <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201bc4:	00f68b63          	beq	a3,a5,ffffffffc0201bda <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bc8:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201bca:	4018                	lw	a4,0(s0)
ffffffffc0201bcc:	02975a63          	bge	a4,s1,ffffffffc0201c00 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201bd0:	00093683          	ld	a3,0(s2)
ffffffffc0201bd4:	87a2                	mv	a5,s0
ffffffffc0201bd6:	fef699e3          	bne	a3,a5,ffffffffc0201bc8 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201bda:	ee31                	bnez	a2,ffffffffc0201c36 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201bdc:	4501                	li	a0,0
ffffffffc0201bde:	f4bff0ef          	jal	ra,ffffffffc0201b28 <__slob_get_free_pages.constprop.0>
ffffffffc0201be2:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201be4:	cd05                	beqz	a0,ffffffffc0201c1c <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201be6:	6585                	lui	a1,0x1
ffffffffc0201be8:	e8dff0ef          	jal	ra,ffffffffc0201a74 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bec:	10002673          	csrr	a2,sstatus
ffffffffc0201bf0:	8a09                	andi	a2,a2,2
ffffffffc0201bf2:	ee05                	bnez	a2,ffffffffc0201c2a <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201bf4:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bf8:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201bfa:	4018                	lw	a4,0(s0)
ffffffffc0201bfc:	fc974ae3          	blt	a4,s1,ffffffffc0201bd0 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201c00:	04e48763          	beq	s1,a4,ffffffffc0201c4e <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201c04:	00449693          	slli	a3,s1,0x4
ffffffffc0201c08:	96a2                	add	a3,a3,s0
ffffffffc0201c0a:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201c0c:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201c0e:	9f05                	subw	a4,a4,s1
ffffffffc0201c10:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201c12:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201c14:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201c16:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201c1a:	e20d                	bnez	a2,ffffffffc0201c3c <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201c1c:	60e2                	ld	ra,24(sp)
ffffffffc0201c1e:	8522                	mv	a0,s0
ffffffffc0201c20:	6442                	ld	s0,16(sp)
ffffffffc0201c22:	64a2                	ld	s1,8(sp)
ffffffffc0201c24:	6902                	ld	s2,0(sp)
ffffffffc0201c26:	6105                	addi	sp,sp,32
ffffffffc0201c28:	8082                	ret
        intr_disable();
ffffffffc0201c2a:	d8bfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201c2e:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201c32:	4605                	li	a2,1
ffffffffc0201c34:	b7d1                	j	ffffffffc0201bf8 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201c36:	d79fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201c3a:	b74d                	j	ffffffffc0201bdc <slob_alloc.constprop.0+0x50>
ffffffffc0201c3c:	d73fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201c40:	60e2                	ld	ra,24(sp)
ffffffffc0201c42:	8522                	mv	a0,s0
ffffffffc0201c44:	6442                	ld	s0,16(sp)
ffffffffc0201c46:	64a2                	ld	s1,8(sp)
ffffffffc0201c48:	6902                	ld	s2,0(sp)
ffffffffc0201c4a:	6105                	addi	sp,sp,32
ffffffffc0201c4c:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201c4e:	6418                	ld	a4,8(s0)
ffffffffc0201c50:	e798                	sd	a4,8(a5)
ffffffffc0201c52:	b7d1                	j	ffffffffc0201c16 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201c54:	d61fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201c58:	4605                	li	a2,1
ffffffffc0201c5a:	bf99                	j	ffffffffc0201bb0 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201c5c:	843e                	mv	s0,a5
ffffffffc0201c5e:	87b6                	mv	a5,a3
ffffffffc0201c60:	b745                	j	ffffffffc0201c00 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c62:	00005697          	auipc	a3,0x5
ffffffffc0201c66:	92668693          	addi	a3,a3,-1754 # ffffffffc0206588 <default_pmm_manager+0x70>
ffffffffc0201c6a:	00004617          	auipc	a2,0x4
ffffffffc0201c6e:	4fe60613          	addi	a2,a2,1278 # ffffffffc0206168 <commands+0x818>
ffffffffc0201c72:	06300593          	li	a1,99
ffffffffc0201c76:	00005517          	auipc	a0,0x5
ffffffffc0201c7a:	93250513          	addi	a0,a0,-1742 # ffffffffc02065a8 <default_pmm_manager+0x90>
ffffffffc0201c7e:	811fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201c82 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201c82:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201c84:	00005517          	auipc	a0,0x5
ffffffffc0201c88:	93c50513          	addi	a0,a0,-1732 # ffffffffc02065c0 <default_pmm_manager+0xa8>
{
ffffffffc0201c8c:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201c8e:	d06fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201c92:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c94:	00005517          	auipc	a0,0x5
ffffffffc0201c98:	94450513          	addi	a0,a0,-1724 # ffffffffc02065d8 <default_pmm_manager+0xc0>
}
ffffffffc0201c9c:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c9e:	cf6fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201ca2 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201ca2:	4501                	li	a0,0
ffffffffc0201ca4:	8082                	ret

ffffffffc0201ca6 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201ca6:	1101                	addi	sp,sp,-32
ffffffffc0201ca8:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201caa:	6905                	lui	s2,0x1
{
ffffffffc0201cac:	e822                	sd	s0,16(sp)
ffffffffc0201cae:	ec06                	sd	ra,24(sp)
ffffffffc0201cb0:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cb2:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bb9>
{
ffffffffc0201cb6:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cb8:	04a7f963          	bgeu	a5,a0,ffffffffc0201d0a <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201cbc:	4561                	li	a0,24
ffffffffc0201cbe:	ecfff0ef          	jal	ra,ffffffffc0201b8c <slob_alloc.constprop.0>
ffffffffc0201cc2:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201cc4:	c929                	beqz	a0,ffffffffc0201d16 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201cc6:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201cca:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201ccc:	00f95763          	bge	s2,a5,ffffffffc0201cda <kmalloc+0x34>
ffffffffc0201cd0:	6705                	lui	a4,0x1
ffffffffc0201cd2:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201cd4:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201cd6:	fef74ee3          	blt	a4,a5,ffffffffc0201cd2 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201cda:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201cdc:	e4dff0ef          	jal	ra,ffffffffc0201b28 <__slob_get_free_pages.constprop.0>
ffffffffc0201ce0:	e488                	sd	a0,8(s1)
ffffffffc0201ce2:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201ce4:	c525                	beqz	a0,ffffffffc0201d4c <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ce6:	100027f3          	csrr	a5,sstatus
ffffffffc0201cea:	8b89                	andi	a5,a5,2
ffffffffc0201cec:	ef8d                	bnez	a5,ffffffffc0201d26 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201cee:	000a9797          	auipc	a5,0xa9
ffffffffc0201cf2:	9f278793          	addi	a5,a5,-1550 # ffffffffc02aa6e0 <bigblocks>
ffffffffc0201cf6:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201cf8:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201cfa:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201cfc:	60e2                	ld	ra,24(sp)
ffffffffc0201cfe:	8522                	mv	a0,s0
ffffffffc0201d00:	6442                	ld	s0,16(sp)
ffffffffc0201d02:	64a2                	ld	s1,8(sp)
ffffffffc0201d04:	6902                	ld	s2,0(sp)
ffffffffc0201d06:	6105                	addi	sp,sp,32
ffffffffc0201d08:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201d0a:	0541                	addi	a0,a0,16
ffffffffc0201d0c:	e81ff0ef          	jal	ra,ffffffffc0201b8c <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201d10:	01050413          	addi	s0,a0,16
ffffffffc0201d14:	f565                	bnez	a0,ffffffffc0201cfc <kmalloc+0x56>
ffffffffc0201d16:	4401                	li	s0,0
}
ffffffffc0201d18:	60e2                	ld	ra,24(sp)
ffffffffc0201d1a:	8522                	mv	a0,s0
ffffffffc0201d1c:	6442                	ld	s0,16(sp)
ffffffffc0201d1e:	64a2                	ld	s1,8(sp)
ffffffffc0201d20:	6902                	ld	s2,0(sp)
ffffffffc0201d22:	6105                	addi	sp,sp,32
ffffffffc0201d24:	8082                	ret
        intr_disable();
ffffffffc0201d26:	c8ffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201d2a:	000a9797          	auipc	a5,0xa9
ffffffffc0201d2e:	9b678793          	addi	a5,a5,-1610 # ffffffffc02aa6e0 <bigblocks>
ffffffffc0201d32:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201d34:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201d36:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201d38:	c77fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201d3c:	6480                	ld	s0,8(s1)
}
ffffffffc0201d3e:	60e2                	ld	ra,24(sp)
ffffffffc0201d40:	64a2                	ld	s1,8(sp)
ffffffffc0201d42:	8522                	mv	a0,s0
ffffffffc0201d44:	6442                	ld	s0,16(sp)
ffffffffc0201d46:	6902                	ld	s2,0(sp)
ffffffffc0201d48:	6105                	addi	sp,sp,32
ffffffffc0201d4a:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d4c:	45e1                	li	a1,24
ffffffffc0201d4e:	8526                	mv	a0,s1
ffffffffc0201d50:	d25ff0ef          	jal	ra,ffffffffc0201a74 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201d54:	b765                	j	ffffffffc0201cfc <kmalloc+0x56>

ffffffffc0201d56 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201d56:	c169                	beqz	a0,ffffffffc0201e18 <kfree+0xc2>
{
ffffffffc0201d58:	1101                	addi	sp,sp,-32
ffffffffc0201d5a:	e822                	sd	s0,16(sp)
ffffffffc0201d5c:	ec06                	sd	ra,24(sp)
ffffffffc0201d5e:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201d60:	03451793          	slli	a5,a0,0x34
ffffffffc0201d64:	842a                	mv	s0,a0
ffffffffc0201d66:	e3d9                	bnez	a5,ffffffffc0201dec <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d68:	100027f3          	csrr	a5,sstatus
ffffffffc0201d6c:	8b89                	andi	a5,a5,2
ffffffffc0201d6e:	e7d9                	bnez	a5,ffffffffc0201dfc <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d70:	000a9797          	auipc	a5,0xa9
ffffffffc0201d74:	9707b783          	ld	a5,-1680(a5) # ffffffffc02aa6e0 <bigblocks>
    return 0;
ffffffffc0201d78:	4601                	li	a2,0
ffffffffc0201d7a:	cbad                	beqz	a5,ffffffffc0201dec <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201d7c:	000a9697          	auipc	a3,0xa9
ffffffffc0201d80:	96468693          	addi	a3,a3,-1692 # ffffffffc02aa6e0 <bigblocks>
ffffffffc0201d84:	a021                	j	ffffffffc0201d8c <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d86:	01048693          	addi	a3,s1,16
ffffffffc0201d8a:	c3a5                	beqz	a5,ffffffffc0201dea <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201d8c:	6798                	ld	a4,8(a5)
ffffffffc0201d8e:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201d90:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201d92:	fe871ae3          	bne	a4,s0,ffffffffc0201d86 <kfree+0x30>
				*last = bb->next;
ffffffffc0201d96:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201d98:	ee2d                	bnez	a2,ffffffffc0201e12 <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201d9a:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201d9e:	4098                	lw	a4,0(s1)
ffffffffc0201da0:	08f46963          	bltu	s0,a5,ffffffffc0201e32 <kfree+0xdc>
ffffffffc0201da4:	000a9697          	auipc	a3,0xa9
ffffffffc0201da8:	96c6b683          	ld	a3,-1684(a3) # ffffffffc02aa710 <va_pa_offset>
ffffffffc0201dac:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201dae:	8031                	srli	s0,s0,0xc
ffffffffc0201db0:	000a9797          	auipc	a5,0xa9
ffffffffc0201db4:	9487b783          	ld	a5,-1720(a5) # ffffffffc02aa6f8 <npage>
ffffffffc0201db8:	06f47163          	bgeu	s0,a5,ffffffffc0201e1a <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201dbc:	00006517          	auipc	a0,0x6
ffffffffc0201dc0:	a8453503          	ld	a0,-1404(a0) # ffffffffc0207840 <nbase>
ffffffffc0201dc4:	8c09                	sub	s0,s0,a0
ffffffffc0201dc6:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201dc8:	000a9517          	auipc	a0,0xa9
ffffffffc0201dcc:	93853503          	ld	a0,-1736(a0) # ffffffffc02aa700 <pages>
ffffffffc0201dd0:	4585                	li	a1,1
ffffffffc0201dd2:	9522                	add	a0,a0,s0
ffffffffc0201dd4:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201dd8:	0ea000ef          	jal	ra,ffffffffc0201ec2 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201ddc:	6442                	ld	s0,16(sp)
ffffffffc0201dde:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201de0:	8526                	mv	a0,s1
}
ffffffffc0201de2:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201de4:	45e1                	li	a1,24
}
ffffffffc0201de6:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201de8:	b171                	j	ffffffffc0201a74 <slob_free>
ffffffffc0201dea:	e20d                	bnez	a2,ffffffffc0201e0c <kfree+0xb6>
ffffffffc0201dec:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201df0:	6442                	ld	s0,16(sp)
ffffffffc0201df2:	60e2                	ld	ra,24(sp)
ffffffffc0201df4:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201df6:	4581                	li	a1,0
}
ffffffffc0201df8:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201dfa:	b9ad                	j	ffffffffc0201a74 <slob_free>
        intr_disable();
ffffffffc0201dfc:	bb9fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e00:	000a9797          	auipc	a5,0xa9
ffffffffc0201e04:	8e07b783          	ld	a5,-1824(a5) # ffffffffc02aa6e0 <bigblocks>
        return 1;
ffffffffc0201e08:	4605                	li	a2,1
ffffffffc0201e0a:	fbad                	bnez	a5,ffffffffc0201d7c <kfree+0x26>
        intr_enable();
ffffffffc0201e0c:	ba3fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e10:	bff1                	j	ffffffffc0201dec <kfree+0x96>
ffffffffc0201e12:	b9dfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e16:	b751                	j	ffffffffc0201d9a <kfree+0x44>
ffffffffc0201e18:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201e1a:	00005617          	auipc	a2,0x5
ffffffffc0201e1e:	80660613          	addi	a2,a2,-2042 # ffffffffc0206620 <default_pmm_manager+0x108>
ffffffffc0201e22:	06900593          	li	a1,105
ffffffffc0201e26:	00004517          	auipc	a0,0x4
ffffffffc0201e2a:	75250513          	addi	a0,a0,1874 # ffffffffc0206578 <default_pmm_manager+0x60>
ffffffffc0201e2e:	e60fe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201e32:	86a2                	mv	a3,s0
ffffffffc0201e34:	00004617          	auipc	a2,0x4
ffffffffc0201e38:	7c460613          	addi	a2,a2,1988 # ffffffffc02065f8 <default_pmm_manager+0xe0>
ffffffffc0201e3c:	07700593          	li	a1,119
ffffffffc0201e40:	00004517          	auipc	a0,0x4
ffffffffc0201e44:	73850513          	addi	a0,a0,1848 # ffffffffc0206578 <default_pmm_manager+0x60>
ffffffffc0201e48:	e46fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e4c <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201e4c:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201e4e:	00004617          	auipc	a2,0x4
ffffffffc0201e52:	7d260613          	addi	a2,a2,2002 # ffffffffc0206620 <default_pmm_manager+0x108>
ffffffffc0201e56:	06900593          	li	a1,105
ffffffffc0201e5a:	00004517          	auipc	a0,0x4
ffffffffc0201e5e:	71e50513          	addi	a0,a0,1822 # ffffffffc0206578 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201e62:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201e64:	e2afe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e68 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201e68:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201e6a:	00004617          	auipc	a2,0x4
ffffffffc0201e6e:	7d660613          	addi	a2,a2,2006 # ffffffffc0206640 <default_pmm_manager+0x128>
ffffffffc0201e72:	07f00593          	li	a1,127
ffffffffc0201e76:	00004517          	auipc	a0,0x4
ffffffffc0201e7a:	70250513          	addi	a0,a0,1794 # ffffffffc0206578 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201e7e:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201e80:	e0efe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e84 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e84:	100027f3          	csrr	a5,sstatus
ffffffffc0201e88:	8b89                	andi	a5,a5,2
ffffffffc0201e8a:	e799                	bnez	a5,ffffffffc0201e98 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e8c:	000a9797          	auipc	a5,0xa9
ffffffffc0201e90:	87c7b783          	ld	a5,-1924(a5) # ffffffffc02aa708 <pmm_manager>
ffffffffc0201e94:	6f9c                	ld	a5,24(a5)
ffffffffc0201e96:	8782                	jr	a5
{
ffffffffc0201e98:	1141                	addi	sp,sp,-16
ffffffffc0201e9a:	e406                	sd	ra,8(sp)
ffffffffc0201e9c:	e022                	sd	s0,0(sp)
ffffffffc0201e9e:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201ea0:	b15fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ea4:	000a9797          	auipc	a5,0xa9
ffffffffc0201ea8:	8647b783          	ld	a5,-1948(a5) # ffffffffc02aa708 <pmm_manager>
ffffffffc0201eac:	6f9c                	ld	a5,24(a5)
ffffffffc0201eae:	8522                	mv	a0,s0
ffffffffc0201eb0:	9782                	jalr	a5
ffffffffc0201eb2:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201eb4:	afbfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201eb8:	60a2                	ld	ra,8(sp)
ffffffffc0201eba:	8522                	mv	a0,s0
ffffffffc0201ebc:	6402                	ld	s0,0(sp)
ffffffffc0201ebe:	0141                	addi	sp,sp,16
ffffffffc0201ec0:	8082                	ret

ffffffffc0201ec2 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ec2:	100027f3          	csrr	a5,sstatus
ffffffffc0201ec6:	8b89                	andi	a5,a5,2
ffffffffc0201ec8:	e799                	bnez	a5,ffffffffc0201ed6 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201eca:	000a9797          	auipc	a5,0xa9
ffffffffc0201ece:	83e7b783          	ld	a5,-1986(a5) # ffffffffc02aa708 <pmm_manager>
ffffffffc0201ed2:	739c                	ld	a5,32(a5)
ffffffffc0201ed4:	8782                	jr	a5
{
ffffffffc0201ed6:	1101                	addi	sp,sp,-32
ffffffffc0201ed8:	ec06                	sd	ra,24(sp)
ffffffffc0201eda:	e822                	sd	s0,16(sp)
ffffffffc0201edc:	e426                	sd	s1,8(sp)
ffffffffc0201ede:	842a                	mv	s0,a0
ffffffffc0201ee0:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201ee2:	ad3fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201ee6:	000a9797          	auipc	a5,0xa9
ffffffffc0201eea:	8227b783          	ld	a5,-2014(a5) # ffffffffc02aa708 <pmm_manager>
ffffffffc0201eee:	739c                	ld	a5,32(a5)
ffffffffc0201ef0:	85a6                	mv	a1,s1
ffffffffc0201ef2:	8522                	mv	a0,s0
ffffffffc0201ef4:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201ef6:	6442                	ld	s0,16(sp)
ffffffffc0201ef8:	60e2                	ld	ra,24(sp)
ffffffffc0201efa:	64a2                	ld	s1,8(sp)
ffffffffc0201efc:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201efe:	ab1fe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc0201f02 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f02:	100027f3          	csrr	a5,sstatus
ffffffffc0201f06:	8b89                	andi	a5,a5,2
ffffffffc0201f08:	e799                	bnez	a5,ffffffffc0201f16 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f0a:	000a8797          	auipc	a5,0xa8
ffffffffc0201f0e:	7fe7b783          	ld	a5,2046(a5) # ffffffffc02aa708 <pmm_manager>
ffffffffc0201f12:	779c                	ld	a5,40(a5)
ffffffffc0201f14:	8782                	jr	a5
{
ffffffffc0201f16:	1141                	addi	sp,sp,-16
ffffffffc0201f18:	e406                	sd	ra,8(sp)
ffffffffc0201f1a:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201f1c:	a99fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f20:	000a8797          	auipc	a5,0xa8
ffffffffc0201f24:	7e87b783          	ld	a5,2024(a5) # ffffffffc02aa708 <pmm_manager>
ffffffffc0201f28:	779c                	ld	a5,40(a5)
ffffffffc0201f2a:	9782                	jalr	a5
ffffffffc0201f2c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f2e:	a81fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f32:	60a2                	ld	ra,8(sp)
ffffffffc0201f34:	8522                	mv	a0,s0
ffffffffc0201f36:	6402                	ld	s0,0(sp)
ffffffffc0201f38:	0141                	addi	sp,sp,16
ffffffffc0201f3a:	8082                	ret

ffffffffc0201f3c <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f3c:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201f40:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201f44:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f46:	078e                	slli	a5,a5,0x3
{
ffffffffc0201f48:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f4a:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201f4e:	6094                	ld	a3,0(s1)
{
ffffffffc0201f50:	f04a                	sd	s2,32(sp)
ffffffffc0201f52:	ec4e                	sd	s3,24(sp)
ffffffffc0201f54:	e852                	sd	s4,16(sp)
ffffffffc0201f56:	fc06                	sd	ra,56(sp)
ffffffffc0201f58:	f822                	sd	s0,48(sp)
ffffffffc0201f5a:	e456                	sd	s5,8(sp)
ffffffffc0201f5c:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201f5e:	0016f793          	andi	a5,a3,1
{
ffffffffc0201f62:	892e                	mv	s2,a1
ffffffffc0201f64:	8a32                	mv	s4,a2
ffffffffc0201f66:	000a8997          	auipc	s3,0xa8
ffffffffc0201f6a:	79298993          	addi	s3,s3,1938 # ffffffffc02aa6f8 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201f6e:	efbd                	bnez	a5,ffffffffc0201fec <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f70:	14060c63          	beqz	a2,ffffffffc02020c8 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f74:	100027f3          	csrr	a5,sstatus
ffffffffc0201f78:	8b89                	andi	a5,a5,2
ffffffffc0201f7a:	14079963          	bnez	a5,ffffffffc02020cc <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f7e:	000a8797          	auipc	a5,0xa8
ffffffffc0201f82:	78a7b783          	ld	a5,1930(a5) # ffffffffc02aa708 <pmm_manager>
ffffffffc0201f86:	6f9c                	ld	a5,24(a5)
ffffffffc0201f88:	4505                	li	a0,1
ffffffffc0201f8a:	9782                	jalr	a5
ffffffffc0201f8c:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f8e:	12040d63          	beqz	s0,ffffffffc02020c8 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201f92:	000a8b17          	auipc	s6,0xa8
ffffffffc0201f96:	76eb0b13          	addi	s6,s6,1902 # ffffffffc02aa700 <pages>
ffffffffc0201f9a:	000b3503          	ld	a0,0(s6)
ffffffffc0201f9e:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201fa2:	000a8997          	auipc	s3,0xa8
ffffffffc0201fa6:	75698993          	addi	s3,s3,1878 # ffffffffc02aa6f8 <npage>
ffffffffc0201faa:	40a40533          	sub	a0,s0,a0
ffffffffc0201fae:	8519                	srai	a0,a0,0x6
ffffffffc0201fb0:	9556                	add	a0,a0,s5
ffffffffc0201fb2:	0009b703          	ld	a4,0(s3)
ffffffffc0201fb6:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201fba:	4685                	li	a3,1
ffffffffc0201fbc:	c014                	sw	a3,0(s0)
ffffffffc0201fbe:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201fc0:	0532                	slli	a0,a0,0xc
ffffffffc0201fc2:	16e7f763          	bgeu	a5,a4,ffffffffc0202130 <get_pte+0x1f4>
ffffffffc0201fc6:	000a8797          	auipc	a5,0xa8
ffffffffc0201fca:	74a7b783          	ld	a5,1866(a5) # ffffffffc02aa710 <va_pa_offset>
ffffffffc0201fce:	6605                	lui	a2,0x1
ffffffffc0201fd0:	4581                	li	a1,0
ffffffffc0201fd2:	953e                	add	a0,a0,a5
ffffffffc0201fd4:	6e6030ef          	jal	ra,ffffffffc02056ba <memset>
    return page - pages + nbase;
ffffffffc0201fd8:	000b3683          	ld	a3,0(s6)
ffffffffc0201fdc:	40d406b3          	sub	a3,s0,a3
ffffffffc0201fe0:	8699                	srai	a3,a3,0x6
ffffffffc0201fe2:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201fe4:	06aa                	slli	a3,a3,0xa
ffffffffc0201fe6:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201fea:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201fec:	77fd                	lui	a5,0xfffff
ffffffffc0201fee:	068a                	slli	a3,a3,0x2
ffffffffc0201ff0:	0009b703          	ld	a4,0(s3)
ffffffffc0201ff4:	8efd                	and	a3,a3,a5
ffffffffc0201ff6:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201ffa:	10e7ff63          	bgeu	a5,a4,ffffffffc0202118 <get_pte+0x1dc>
ffffffffc0201ffe:	000a8a97          	auipc	s5,0xa8
ffffffffc0202002:	712a8a93          	addi	s5,s5,1810 # ffffffffc02aa710 <va_pa_offset>
ffffffffc0202006:	000ab403          	ld	s0,0(s5)
ffffffffc020200a:	01595793          	srli	a5,s2,0x15
ffffffffc020200e:	1ff7f793          	andi	a5,a5,511
ffffffffc0202012:	96a2                	add	a3,a3,s0
ffffffffc0202014:	00379413          	slli	s0,a5,0x3
ffffffffc0202018:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc020201a:	6014                	ld	a3,0(s0)
ffffffffc020201c:	0016f793          	andi	a5,a3,1
ffffffffc0202020:	ebad                	bnez	a5,ffffffffc0202092 <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202022:	0a0a0363          	beqz	s4,ffffffffc02020c8 <get_pte+0x18c>
ffffffffc0202026:	100027f3          	csrr	a5,sstatus
ffffffffc020202a:	8b89                	andi	a5,a5,2
ffffffffc020202c:	efcd                	bnez	a5,ffffffffc02020e6 <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc020202e:	000a8797          	auipc	a5,0xa8
ffffffffc0202032:	6da7b783          	ld	a5,1754(a5) # ffffffffc02aa708 <pmm_manager>
ffffffffc0202036:	6f9c                	ld	a5,24(a5)
ffffffffc0202038:	4505                	li	a0,1
ffffffffc020203a:	9782                	jalr	a5
ffffffffc020203c:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc020203e:	c4c9                	beqz	s1,ffffffffc02020c8 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0202040:	000a8b17          	auipc	s6,0xa8
ffffffffc0202044:	6c0b0b13          	addi	s6,s6,1728 # ffffffffc02aa700 <pages>
ffffffffc0202048:	000b3503          	ld	a0,0(s6)
ffffffffc020204c:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202050:	0009b703          	ld	a4,0(s3)
ffffffffc0202054:	40a48533          	sub	a0,s1,a0
ffffffffc0202058:	8519                	srai	a0,a0,0x6
ffffffffc020205a:	9552                	add	a0,a0,s4
ffffffffc020205c:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0202060:	4685                	li	a3,1
ffffffffc0202062:	c094                	sw	a3,0(s1)
ffffffffc0202064:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202066:	0532                	slli	a0,a0,0xc
ffffffffc0202068:	0ee7f163          	bgeu	a5,a4,ffffffffc020214a <get_pte+0x20e>
ffffffffc020206c:	000ab783          	ld	a5,0(s5)
ffffffffc0202070:	6605                	lui	a2,0x1
ffffffffc0202072:	4581                	li	a1,0
ffffffffc0202074:	953e                	add	a0,a0,a5
ffffffffc0202076:	644030ef          	jal	ra,ffffffffc02056ba <memset>
    return page - pages + nbase;
ffffffffc020207a:	000b3683          	ld	a3,0(s6)
ffffffffc020207e:	40d486b3          	sub	a3,s1,a3
ffffffffc0202082:	8699                	srai	a3,a3,0x6
ffffffffc0202084:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202086:	06aa                	slli	a3,a3,0xa
ffffffffc0202088:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc020208c:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020208e:	0009b703          	ld	a4,0(s3)
ffffffffc0202092:	068a                	slli	a3,a3,0x2
ffffffffc0202094:	757d                	lui	a0,0xfffff
ffffffffc0202096:	8ee9                	and	a3,a3,a0
ffffffffc0202098:	00c6d793          	srli	a5,a3,0xc
ffffffffc020209c:	06e7f263          	bgeu	a5,a4,ffffffffc0202100 <get_pte+0x1c4>
ffffffffc02020a0:	000ab503          	ld	a0,0(s5)
ffffffffc02020a4:	00c95913          	srli	s2,s2,0xc
ffffffffc02020a8:	1ff97913          	andi	s2,s2,511
ffffffffc02020ac:	96aa                	add	a3,a3,a0
ffffffffc02020ae:	00391513          	slli	a0,s2,0x3
ffffffffc02020b2:	9536                	add	a0,a0,a3
}
ffffffffc02020b4:	70e2                	ld	ra,56(sp)
ffffffffc02020b6:	7442                	ld	s0,48(sp)
ffffffffc02020b8:	74a2                	ld	s1,40(sp)
ffffffffc02020ba:	7902                	ld	s2,32(sp)
ffffffffc02020bc:	69e2                	ld	s3,24(sp)
ffffffffc02020be:	6a42                	ld	s4,16(sp)
ffffffffc02020c0:	6aa2                	ld	s5,8(sp)
ffffffffc02020c2:	6b02                	ld	s6,0(sp)
ffffffffc02020c4:	6121                	addi	sp,sp,64
ffffffffc02020c6:	8082                	ret
            return NULL;
ffffffffc02020c8:	4501                	li	a0,0
ffffffffc02020ca:	b7ed                	j	ffffffffc02020b4 <get_pte+0x178>
        intr_disable();
ffffffffc02020cc:	8e9fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02020d0:	000a8797          	auipc	a5,0xa8
ffffffffc02020d4:	6387b783          	ld	a5,1592(a5) # ffffffffc02aa708 <pmm_manager>
ffffffffc02020d8:	6f9c                	ld	a5,24(a5)
ffffffffc02020da:	4505                	li	a0,1
ffffffffc02020dc:	9782                	jalr	a5
ffffffffc02020de:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02020e0:	8cffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02020e4:	b56d                	j	ffffffffc0201f8e <get_pte+0x52>
        intr_disable();
ffffffffc02020e6:	8cffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02020ea:	000a8797          	auipc	a5,0xa8
ffffffffc02020ee:	61e7b783          	ld	a5,1566(a5) # ffffffffc02aa708 <pmm_manager>
ffffffffc02020f2:	6f9c                	ld	a5,24(a5)
ffffffffc02020f4:	4505                	li	a0,1
ffffffffc02020f6:	9782                	jalr	a5
ffffffffc02020f8:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc02020fa:	8b5fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02020fe:	b781                	j	ffffffffc020203e <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202100:	00004617          	auipc	a2,0x4
ffffffffc0202104:	45060613          	addi	a2,a2,1104 # ffffffffc0206550 <default_pmm_manager+0x38>
ffffffffc0202108:	0fa00593          	li	a1,250
ffffffffc020210c:	00004517          	auipc	a0,0x4
ffffffffc0202110:	55c50513          	addi	a0,a0,1372 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0202114:	b7afe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202118:	00004617          	auipc	a2,0x4
ffffffffc020211c:	43860613          	addi	a2,a2,1080 # ffffffffc0206550 <default_pmm_manager+0x38>
ffffffffc0202120:	0ed00593          	li	a1,237
ffffffffc0202124:	00004517          	auipc	a0,0x4
ffffffffc0202128:	54450513          	addi	a0,a0,1348 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc020212c:	b62fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202130:	86aa                	mv	a3,a0
ffffffffc0202132:	00004617          	auipc	a2,0x4
ffffffffc0202136:	41e60613          	addi	a2,a2,1054 # ffffffffc0206550 <default_pmm_manager+0x38>
ffffffffc020213a:	0e900593          	li	a1,233
ffffffffc020213e:	00004517          	auipc	a0,0x4
ffffffffc0202142:	52a50513          	addi	a0,a0,1322 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0202146:	b48fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020214a:	86aa                	mv	a3,a0
ffffffffc020214c:	00004617          	auipc	a2,0x4
ffffffffc0202150:	40460613          	addi	a2,a2,1028 # ffffffffc0206550 <default_pmm_manager+0x38>
ffffffffc0202154:	0f700593          	li	a1,247
ffffffffc0202158:	00004517          	auipc	a0,0x4
ffffffffc020215c:	51050513          	addi	a0,a0,1296 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0202160:	b2efe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202164 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0202164:	1141                	addi	sp,sp,-16
ffffffffc0202166:	e022                	sd	s0,0(sp)
ffffffffc0202168:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020216a:	4601                	li	a2,0
{
ffffffffc020216c:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020216e:	dcfff0ef          	jal	ra,ffffffffc0201f3c <get_pte>
    if (ptep_store != NULL)
ffffffffc0202172:	c011                	beqz	s0,ffffffffc0202176 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0202174:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202176:	c511                	beqz	a0,ffffffffc0202182 <get_page+0x1e>
ffffffffc0202178:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc020217a:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020217c:	0017f713          	andi	a4,a5,1
ffffffffc0202180:	e709                	bnez	a4,ffffffffc020218a <get_page+0x26>
}
ffffffffc0202182:	60a2                	ld	ra,8(sp)
ffffffffc0202184:	6402                	ld	s0,0(sp)
ffffffffc0202186:	0141                	addi	sp,sp,16
ffffffffc0202188:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020218a:	078a                	slli	a5,a5,0x2
ffffffffc020218c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020218e:	000a8717          	auipc	a4,0xa8
ffffffffc0202192:	56a73703          	ld	a4,1386(a4) # ffffffffc02aa6f8 <npage>
ffffffffc0202196:	00e7ff63          	bgeu	a5,a4,ffffffffc02021b4 <get_page+0x50>
ffffffffc020219a:	60a2                	ld	ra,8(sp)
ffffffffc020219c:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc020219e:	fff80537          	lui	a0,0xfff80
ffffffffc02021a2:	97aa                	add	a5,a5,a0
ffffffffc02021a4:	079a                	slli	a5,a5,0x6
ffffffffc02021a6:	000a8517          	auipc	a0,0xa8
ffffffffc02021aa:	55a53503          	ld	a0,1370(a0) # ffffffffc02aa700 <pages>
ffffffffc02021ae:	953e                	add	a0,a0,a5
ffffffffc02021b0:	0141                	addi	sp,sp,16
ffffffffc02021b2:	8082                	ret
ffffffffc02021b4:	c99ff0ef          	jal	ra,ffffffffc0201e4c <pa2page.part.0>

ffffffffc02021b8 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc02021b8:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021ba:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02021be:	f486                	sd	ra,104(sp)
ffffffffc02021c0:	f0a2                	sd	s0,96(sp)
ffffffffc02021c2:	eca6                	sd	s1,88(sp)
ffffffffc02021c4:	e8ca                	sd	s2,80(sp)
ffffffffc02021c6:	e4ce                	sd	s3,72(sp)
ffffffffc02021c8:	e0d2                	sd	s4,64(sp)
ffffffffc02021ca:	fc56                	sd	s5,56(sp)
ffffffffc02021cc:	f85a                	sd	s6,48(sp)
ffffffffc02021ce:	f45e                	sd	s7,40(sp)
ffffffffc02021d0:	f062                	sd	s8,32(sp)
ffffffffc02021d2:	ec66                	sd	s9,24(sp)
ffffffffc02021d4:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021d6:	17d2                	slli	a5,a5,0x34
ffffffffc02021d8:	e3ed                	bnez	a5,ffffffffc02022ba <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc02021da:	002007b7          	lui	a5,0x200
ffffffffc02021de:	842e                	mv	s0,a1
ffffffffc02021e0:	0ef5ed63          	bltu	a1,a5,ffffffffc02022da <unmap_range+0x122>
ffffffffc02021e4:	8932                	mv	s2,a2
ffffffffc02021e6:	0ec5fa63          	bgeu	a1,a2,ffffffffc02022da <unmap_range+0x122>
ffffffffc02021ea:	4785                	li	a5,1
ffffffffc02021ec:	07fe                	slli	a5,a5,0x1f
ffffffffc02021ee:	0ec7e663          	bltu	a5,a2,ffffffffc02022da <unmap_range+0x122>
ffffffffc02021f2:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02021f4:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02021f6:	000a8c97          	auipc	s9,0xa8
ffffffffc02021fa:	502c8c93          	addi	s9,s9,1282 # ffffffffc02aa6f8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02021fe:	000a8c17          	auipc	s8,0xa8
ffffffffc0202202:	502c0c13          	addi	s8,s8,1282 # ffffffffc02aa700 <pages>
ffffffffc0202206:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc020220a:	000a8d17          	auipc	s10,0xa8
ffffffffc020220e:	4fed0d13          	addi	s10,s10,1278 # ffffffffc02aa708 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202212:	00200b37          	lui	s6,0x200
ffffffffc0202216:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc020221a:	4601                	li	a2,0
ffffffffc020221c:	85a2                	mv	a1,s0
ffffffffc020221e:	854e                	mv	a0,s3
ffffffffc0202220:	d1dff0ef          	jal	ra,ffffffffc0201f3c <get_pte>
ffffffffc0202224:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc0202226:	cd29                	beqz	a0,ffffffffc0202280 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc0202228:	611c                	ld	a5,0(a0)
ffffffffc020222a:	e395                	bnez	a5,ffffffffc020224e <unmap_range+0x96>
        start += PGSIZE;
ffffffffc020222c:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc020222e:	ff2466e3          	bltu	s0,s2,ffffffffc020221a <unmap_range+0x62>
}
ffffffffc0202232:	70a6                	ld	ra,104(sp)
ffffffffc0202234:	7406                	ld	s0,96(sp)
ffffffffc0202236:	64e6                	ld	s1,88(sp)
ffffffffc0202238:	6946                	ld	s2,80(sp)
ffffffffc020223a:	69a6                	ld	s3,72(sp)
ffffffffc020223c:	6a06                	ld	s4,64(sp)
ffffffffc020223e:	7ae2                	ld	s5,56(sp)
ffffffffc0202240:	7b42                	ld	s6,48(sp)
ffffffffc0202242:	7ba2                	ld	s7,40(sp)
ffffffffc0202244:	7c02                	ld	s8,32(sp)
ffffffffc0202246:	6ce2                	ld	s9,24(sp)
ffffffffc0202248:	6d42                	ld	s10,16(sp)
ffffffffc020224a:	6165                	addi	sp,sp,112
ffffffffc020224c:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc020224e:	0017f713          	andi	a4,a5,1
ffffffffc0202252:	df69                	beqz	a4,ffffffffc020222c <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc0202254:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202258:	078a                	slli	a5,a5,0x2
ffffffffc020225a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020225c:	08e7ff63          	bgeu	a5,a4,ffffffffc02022fa <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0202260:	000c3503          	ld	a0,0(s8)
ffffffffc0202264:	97de                	add	a5,a5,s7
ffffffffc0202266:	079a                	slli	a5,a5,0x6
ffffffffc0202268:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020226a:	411c                	lw	a5,0(a0)
ffffffffc020226c:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202270:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc0202272:	cf11                	beqz	a4,ffffffffc020228e <unmap_range+0xd6>
        *ptep = 0;
ffffffffc0202274:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202278:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc020227c:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc020227e:	bf45                	j	ffffffffc020222e <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202280:	945a                	add	s0,s0,s6
ffffffffc0202282:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc0202286:	d455                	beqz	s0,ffffffffc0202232 <unmap_range+0x7a>
ffffffffc0202288:	f92469e3          	bltu	s0,s2,ffffffffc020221a <unmap_range+0x62>
ffffffffc020228c:	b75d                	j	ffffffffc0202232 <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020228e:	100027f3          	csrr	a5,sstatus
ffffffffc0202292:	8b89                	andi	a5,a5,2
ffffffffc0202294:	e799                	bnez	a5,ffffffffc02022a2 <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc0202296:	000d3783          	ld	a5,0(s10)
ffffffffc020229a:	4585                	li	a1,1
ffffffffc020229c:	739c                	ld	a5,32(a5)
ffffffffc020229e:	9782                	jalr	a5
    if (flag)
ffffffffc02022a0:	bfd1                	j	ffffffffc0202274 <unmap_range+0xbc>
ffffffffc02022a2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02022a4:	f10fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02022a8:	000d3783          	ld	a5,0(s10)
ffffffffc02022ac:	6522                	ld	a0,8(sp)
ffffffffc02022ae:	4585                	li	a1,1
ffffffffc02022b0:	739c                	ld	a5,32(a5)
ffffffffc02022b2:	9782                	jalr	a5
        intr_enable();
ffffffffc02022b4:	efafe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02022b8:	bf75                	j	ffffffffc0202274 <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022ba:	00004697          	auipc	a3,0x4
ffffffffc02022be:	3be68693          	addi	a3,a3,958 # ffffffffc0206678 <default_pmm_manager+0x160>
ffffffffc02022c2:	00004617          	auipc	a2,0x4
ffffffffc02022c6:	ea660613          	addi	a2,a2,-346 # ffffffffc0206168 <commands+0x818>
ffffffffc02022ca:	12000593          	li	a1,288
ffffffffc02022ce:	00004517          	auipc	a0,0x4
ffffffffc02022d2:	39a50513          	addi	a0,a0,922 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc02022d6:	9b8fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02022da:	00004697          	auipc	a3,0x4
ffffffffc02022de:	3ce68693          	addi	a3,a3,974 # ffffffffc02066a8 <default_pmm_manager+0x190>
ffffffffc02022e2:	00004617          	auipc	a2,0x4
ffffffffc02022e6:	e8660613          	addi	a2,a2,-378 # ffffffffc0206168 <commands+0x818>
ffffffffc02022ea:	12100593          	li	a1,289
ffffffffc02022ee:	00004517          	auipc	a0,0x4
ffffffffc02022f2:	37a50513          	addi	a0,a0,890 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc02022f6:	998fe0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02022fa:	b53ff0ef          	jal	ra,ffffffffc0201e4c <pa2page.part.0>

ffffffffc02022fe <exit_range>:
{
ffffffffc02022fe:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202300:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202304:	fc86                	sd	ra,120(sp)
ffffffffc0202306:	f8a2                	sd	s0,112(sp)
ffffffffc0202308:	f4a6                	sd	s1,104(sp)
ffffffffc020230a:	f0ca                	sd	s2,96(sp)
ffffffffc020230c:	ecce                	sd	s3,88(sp)
ffffffffc020230e:	e8d2                	sd	s4,80(sp)
ffffffffc0202310:	e4d6                	sd	s5,72(sp)
ffffffffc0202312:	e0da                	sd	s6,64(sp)
ffffffffc0202314:	fc5e                	sd	s7,56(sp)
ffffffffc0202316:	f862                	sd	s8,48(sp)
ffffffffc0202318:	f466                	sd	s9,40(sp)
ffffffffc020231a:	f06a                	sd	s10,32(sp)
ffffffffc020231c:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020231e:	17d2                	slli	a5,a5,0x34
ffffffffc0202320:	20079a63          	bnez	a5,ffffffffc0202534 <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc0202324:	002007b7          	lui	a5,0x200
ffffffffc0202328:	24f5e463          	bltu	a1,a5,ffffffffc0202570 <exit_range+0x272>
ffffffffc020232c:	8ab2                	mv	s5,a2
ffffffffc020232e:	24c5f163          	bgeu	a1,a2,ffffffffc0202570 <exit_range+0x272>
ffffffffc0202332:	4785                	li	a5,1
ffffffffc0202334:	07fe                	slli	a5,a5,0x1f
ffffffffc0202336:	22c7ed63          	bltu	a5,a2,ffffffffc0202570 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc020233a:	c00009b7          	lui	s3,0xc0000
ffffffffc020233e:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202342:	ffe00937          	lui	s2,0xffe00
ffffffffc0202346:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc020234a:	5cfd                	li	s9,-1
ffffffffc020234c:	8c2a                	mv	s8,a0
ffffffffc020234e:	0125f933          	and	s2,a1,s2
ffffffffc0202352:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc0202354:	000a8d17          	auipc	s10,0xa8
ffffffffc0202358:	3a4d0d13          	addi	s10,s10,932 # ffffffffc02aa6f8 <npage>
    return KADDR(page2pa(page));
ffffffffc020235c:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202360:	000a8717          	auipc	a4,0xa8
ffffffffc0202364:	3a070713          	addi	a4,a4,928 # ffffffffc02aa700 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc0202368:	000a8d97          	auipc	s11,0xa8
ffffffffc020236c:	3a0d8d93          	addi	s11,s11,928 # ffffffffc02aa708 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202370:	c0000437          	lui	s0,0xc0000
ffffffffc0202374:	944e                	add	s0,s0,s3
ffffffffc0202376:	8079                	srli	s0,s0,0x1e
ffffffffc0202378:	1ff47413          	andi	s0,s0,511
ffffffffc020237c:	040e                	slli	s0,s0,0x3
ffffffffc020237e:	9462                	add	s0,s0,s8
ffffffffc0202380:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ee0>
        if (pde1 & PTE_V)
ffffffffc0202384:	001a7793          	andi	a5,s4,1
ffffffffc0202388:	eb99                	bnez	a5,ffffffffc020239e <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc020238a:	12098463          	beqz	s3,ffffffffc02024b2 <exit_range+0x1b4>
ffffffffc020238e:	400007b7          	lui	a5,0x40000
ffffffffc0202392:	97ce                	add	a5,a5,s3
ffffffffc0202394:	894e                	mv	s2,s3
ffffffffc0202396:	1159fe63          	bgeu	s3,s5,ffffffffc02024b2 <exit_range+0x1b4>
ffffffffc020239a:	89be                	mv	s3,a5
ffffffffc020239c:	bfd1                	j	ffffffffc0202370 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc020239e:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023a2:	0a0a                	slli	s4,s4,0x2
ffffffffc02023a4:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc02023a8:	1cfa7263          	bgeu	s4,a5,ffffffffc020256c <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02023ac:	fff80637          	lui	a2,0xfff80
ffffffffc02023b0:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc02023b2:	000806b7          	lui	a3,0x80
ffffffffc02023b6:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02023b8:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02023bc:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02023be:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02023c0:	18f5fa63          	bgeu	a1,a5,ffffffffc0202554 <exit_range+0x256>
ffffffffc02023c4:	000a8817          	auipc	a6,0xa8
ffffffffc02023c8:	34c80813          	addi	a6,a6,844 # ffffffffc02aa710 <va_pa_offset>
ffffffffc02023cc:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc02023d0:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc02023d2:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc02023d6:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc02023d8:	00080337          	lui	t1,0x80
ffffffffc02023dc:	6885                	lui	a7,0x1
ffffffffc02023de:	a819                	j	ffffffffc02023f4 <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc02023e0:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc02023e2:	002007b7          	lui	a5,0x200
ffffffffc02023e6:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023e8:	08090c63          	beqz	s2,ffffffffc0202480 <exit_range+0x182>
ffffffffc02023ec:	09397a63          	bgeu	s2,s3,ffffffffc0202480 <exit_range+0x182>
ffffffffc02023f0:	0f597063          	bgeu	s2,s5,ffffffffc02024d0 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02023f4:	01595493          	srli	s1,s2,0x15
ffffffffc02023f8:	1ff4f493          	andi	s1,s1,511
ffffffffc02023fc:	048e                	slli	s1,s1,0x3
ffffffffc02023fe:	94da                	add	s1,s1,s6
ffffffffc0202400:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc0202402:	0017f693          	andi	a3,a5,1
ffffffffc0202406:	dee9                	beqz	a3,ffffffffc02023e0 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc0202408:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc020240c:	078a                	slli	a5,a5,0x2
ffffffffc020240e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202410:	14b7fe63          	bgeu	a5,a1,ffffffffc020256c <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202414:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc0202416:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc020241a:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc020241e:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202422:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202424:	12bef863          	bgeu	t4,a1,ffffffffc0202554 <exit_range+0x256>
ffffffffc0202428:	00083783          	ld	a5,0(a6)
ffffffffc020242c:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc020242e:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc0202432:	629c                	ld	a5,0(a3)
ffffffffc0202434:	8b85                	andi	a5,a5,1
ffffffffc0202436:	f7d5                	bnez	a5,ffffffffc02023e2 <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202438:	06a1                	addi	a3,a3,8
ffffffffc020243a:	fed59ce3          	bne	a1,a3,ffffffffc0202432 <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc020243e:	631c                	ld	a5,0(a4)
ffffffffc0202440:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202442:	100027f3          	csrr	a5,sstatus
ffffffffc0202446:	8b89                	andi	a5,a5,2
ffffffffc0202448:	e7d9                	bnez	a5,ffffffffc02024d6 <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc020244a:	000db783          	ld	a5,0(s11)
ffffffffc020244e:	4585                	li	a1,1
ffffffffc0202450:	e032                	sd	a2,0(sp)
ffffffffc0202452:	739c                	ld	a5,32(a5)
ffffffffc0202454:	9782                	jalr	a5
    if (flag)
ffffffffc0202456:	6602                	ld	a2,0(sp)
ffffffffc0202458:	000a8817          	auipc	a6,0xa8
ffffffffc020245c:	2b880813          	addi	a6,a6,696 # ffffffffc02aa710 <va_pa_offset>
ffffffffc0202460:	fff80e37          	lui	t3,0xfff80
ffffffffc0202464:	00080337          	lui	t1,0x80
ffffffffc0202468:	6885                	lui	a7,0x1
ffffffffc020246a:	000a8717          	auipc	a4,0xa8
ffffffffc020246e:	29670713          	addi	a4,a4,662 # ffffffffc02aa700 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202472:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc0202476:	002007b7          	lui	a5,0x200
ffffffffc020247a:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc020247c:	f60918e3          	bnez	s2,ffffffffc02023ec <exit_range+0xee>
            if (free_pd0)
ffffffffc0202480:	f00b85e3          	beqz	s7,ffffffffc020238a <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc0202484:	000d3783          	ld	a5,0(s10)
ffffffffc0202488:	0efa7263          	bgeu	s4,a5,ffffffffc020256c <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc020248c:	6308                	ld	a0,0(a4)
ffffffffc020248e:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202490:	100027f3          	csrr	a5,sstatus
ffffffffc0202494:	8b89                	andi	a5,a5,2
ffffffffc0202496:	efad                	bnez	a5,ffffffffc0202510 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc0202498:	000db783          	ld	a5,0(s11)
ffffffffc020249c:	4585                	li	a1,1
ffffffffc020249e:	739c                	ld	a5,32(a5)
ffffffffc02024a0:	9782                	jalr	a5
ffffffffc02024a2:	000a8717          	auipc	a4,0xa8
ffffffffc02024a6:	25e70713          	addi	a4,a4,606 # ffffffffc02aa700 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02024aa:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc02024ae:	ee0990e3          	bnez	s3,ffffffffc020238e <exit_range+0x90>
}
ffffffffc02024b2:	70e6                	ld	ra,120(sp)
ffffffffc02024b4:	7446                	ld	s0,112(sp)
ffffffffc02024b6:	74a6                	ld	s1,104(sp)
ffffffffc02024b8:	7906                	ld	s2,96(sp)
ffffffffc02024ba:	69e6                	ld	s3,88(sp)
ffffffffc02024bc:	6a46                	ld	s4,80(sp)
ffffffffc02024be:	6aa6                	ld	s5,72(sp)
ffffffffc02024c0:	6b06                	ld	s6,64(sp)
ffffffffc02024c2:	7be2                	ld	s7,56(sp)
ffffffffc02024c4:	7c42                	ld	s8,48(sp)
ffffffffc02024c6:	7ca2                	ld	s9,40(sp)
ffffffffc02024c8:	7d02                	ld	s10,32(sp)
ffffffffc02024ca:	6de2                	ld	s11,24(sp)
ffffffffc02024cc:	6109                	addi	sp,sp,128
ffffffffc02024ce:	8082                	ret
            if (free_pd0)
ffffffffc02024d0:	ea0b8fe3          	beqz	s7,ffffffffc020238e <exit_range+0x90>
ffffffffc02024d4:	bf45                	j	ffffffffc0202484 <exit_range+0x186>
ffffffffc02024d6:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc02024d8:	e42a                	sd	a0,8(sp)
ffffffffc02024da:	cdafe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02024de:	000db783          	ld	a5,0(s11)
ffffffffc02024e2:	6522                	ld	a0,8(sp)
ffffffffc02024e4:	4585                	li	a1,1
ffffffffc02024e6:	739c                	ld	a5,32(a5)
ffffffffc02024e8:	9782                	jalr	a5
        intr_enable();
ffffffffc02024ea:	cc4fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02024ee:	6602                	ld	a2,0(sp)
ffffffffc02024f0:	000a8717          	auipc	a4,0xa8
ffffffffc02024f4:	21070713          	addi	a4,a4,528 # ffffffffc02aa700 <pages>
ffffffffc02024f8:	6885                	lui	a7,0x1
ffffffffc02024fa:	00080337          	lui	t1,0x80
ffffffffc02024fe:	fff80e37          	lui	t3,0xfff80
ffffffffc0202502:	000a8817          	auipc	a6,0xa8
ffffffffc0202506:	20e80813          	addi	a6,a6,526 # ffffffffc02aa710 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc020250a:	0004b023          	sd	zero,0(s1)
ffffffffc020250e:	b7a5                	j	ffffffffc0202476 <exit_range+0x178>
ffffffffc0202510:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0202512:	ca2fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202516:	000db783          	ld	a5,0(s11)
ffffffffc020251a:	6502                	ld	a0,0(sp)
ffffffffc020251c:	4585                	li	a1,1
ffffffffc020251e:	739c                	ld	a5,32(a5)
ffffffffc0202520:	9782                	jalr	a5
        intr_enable();
ffffffffc0202522:	c8cfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202526:	000a8717          	auipc	a4,0xa8
ffffffffc020252a:	1da70713          	addi	a4,a4,474 # ffffffffc02aa700 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc020252e:	00043023          	sd	zero,0(s0)
ffffffffc0202532:	bfb5                	j	ffffffffc02024ae <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202534:	00004697          	auipc	a3,0x4
ffffffffc0202538:	14468693          	addi	a3,a3,324 # ffffffffc0206678 <default_pmm_manager+0x160>
ffffffffc020253c:	00004617          	auipc	a2,0x4
ffffffffc0202540:	c2c60613          	addi	a2,a2,-980 # ffffffffc0206168 <commands+0x818>
ffffffffc0202544:	13500593          	li	a1,309
ffffffffc0202548:	00004517          	auipc	a0,0x4
ffffffffc020254c:	12050513          	addi	a0,a0,288 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0202550:	f3ffd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202554:	00004617          	auipc	a2,0x4
ffffffffc0202558:	ffc60613          	addi	a2,a2,-4 # ffffffffc0206550 <default_pmm_manager+0x38>
ffffffffc020255c:	07100593          	li	a1,113
ffffffffc0202560:	00004517          	auipc	a0,0x4
ffffffffc0202564:	01850513          	addi	a0,a0,24 # ffffffffc0206578 <default_pmm_manager+0x60>
ffffffffc0202568:	f27fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc020256c:	8e1ff0ef          	jal	ra,ffffffffc0201e4c <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202570:	00004697          	auipc	a3,0x4
ffffffffc0202574:	13868693          	addi	a3,a3,312 # ffffffffc02066a8 <default_pmm_manager+0x190>
ffffffffc0202578:	00004617          	auipc	a2,0x4
ffffffffc020257c:	bf060613          	addi	a2,a2,-1040 # ffffffffc0206168 <commands+0x818>
ffffffffc0202580:	13600593          	li	a1,310
ffffffffc0202584:	00004517          	auipc	a0,0x4
ffffffffc0202588:	0e450513          	addi	a0,a0,228 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc020258c:	f03fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202590 <page_remove>:
{
ffffffffc0202590:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202592:	4601                	li	a2,0
{
ffffffffc0202594:	ec26                	sd	s1,24(sp)
ffffffffc0202596:	f406                	sd	ra,40(sp)
ffffffffc0202598:	f022                	sd	s0,32(sp)
ffffffffc020259a:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020259c:	9a1ff0ef          	jal	ra,ffffffffc0201f3c <get_pte>
    if (ptep != NULL)
ffffffffc02025a0:	c511                	beqz	a0,ffffffffc02025ac <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc02025a2:	611c                	ld	a5,0(a0)
ffffffffc02025a4:	842a                	mv	s0,a0
ffffffffc02025a6:	0017f713          	andi	a4,a5,1
ffffffffc02025aa:	e711                	bnez	a4,ffffffffc02025b6 <page_remove+0x26>
}
ffffffffc02025ac:	70a2                	ld	ra,40(sp)
ffffffffc02025ae:	7402                	ld	s0,32(sp)
ffffffffc02025b0:	64e2                	ld	s1,24(sp)
ffffffffc02025b2:	6145                	addi	sp,sp,48
ffffffffc02025b4:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02025b6:	078a                	slli	a5,a5,0x2
ffffffffc02025b8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02025ba:	000a8717          	auipc	a4,0xa8
ffffffffc02025be:	13e73703          	ld	a4,318(a4) # ffffffffc02aa6f8 <npage>
ffffffffc02025c2:	06e7f363          	bgeu	a5,a4,ffffffffc0202628 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc02025c6:	fff80537          	lui	a0,0xfff80
ffffffffc02025ca:	97aa                	add	a5,a5,a0
ffffffffc02025cc:	079a                	slli	a5,a5,0x6
ffffffffc02025ce:	000a8517          	auipc	a0,0xa8
ffffffffc02025d2:	13253503          	ld	a0,306(a0) # ffffffffc02aa700 <pages>
ffffffffc02025d6:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02025d8:	411c                	lw	a5,0(a0)
ffffffffc02025da:	fff7871b          	addiw	a4,a5,-1
ffffffffc02025de:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc02025e0:	cb11                	beqz	a4,ffffffffc02025f4 <page_remove+0x64>
        *ptep = 0;
ffffffffc02025e2:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025e6:	12048073          	sfence.vma	s1
}
ffffffffc02025ea:	70a2                	ld	ra,40(sp)
ffffffffc02025ec:	7402                	ld	s0,32(sp)
ffffffffc02025ee:	64e2                	ld	s1,24(sp)
ffffffffc02025f0:	6145                	addi	sp,sp,48
ffffffffc02025f2:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02025f4:	100027f3          	csrr	a5,sstatus
ffffffffc02025f8:	8b89                	andi	a5,a5,2
ffffffffc02025fa:	eb89                	bnez	a5,ffffffffc020260c <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc02025fc:	000a8797          	auipc	a5,0xa8
ffffffffc0202600:	10c7b783          	ld	a5,268(a5) # ffffffffc02aa708 <pmm_manager>
ffffffffc0202604:	739c                	ld	a5,32(a5)
ffffffffc0202606:	4585                	li	a1,1
ffffffffc0202608:	9782                	jalr	a5
    if (flag)
ffffffffc020260a:	bfe1                	j	ffffffffc02025e2 <page_remove+0x52>
        intr_disable();
ffffffffc020260c:	e42a                	sd	a0,8(sp)
ffffffffc020260e:	ba6fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202612:	000a8797          	auipc	a5,0xa8
ffffffffc0202616:	0f67b783          	ld	a5,246(a5) # ffffffffc02aa708 <pmm_manager>
ffffffffc020261a:	739c                	ld	a5,32(a5)
ffffffffc020261c:	6522                	ld	a0,8(sp)
ffffffffc020261e:	4585                	li	a1,1
ffffffffc0202620:	9782                	jalr	a5
        intr_enable();
ffffffffc0202622:	b8cfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202626:	bf75                	j	ffffffffc02025e2 <page_remove+0x52>
ffffffffc0202628:	825ff0ef          	jal	ra,ffffffffc0201e4c <pa2page.part.0>

ffffffffc020262c <page_insert>:
{
ffffffffc020262c:	7139                	addi	sp,sp,-64
ffffffffc020262e:	e852                	sd	s4,16(sp)
ffffffffc0202630:	8a32                	mv	s4,a2
ffffffffc0202632:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202634:	4605                	li	a2,1
{
ffffffffc0202636:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202638:	85d2                	mv	a1,s4
{
ffffffffc020263a:	f426                	sd	s1,40(sp)
ffffffffc020263c:	fc06                	sd	ra,56(sp)
ffffffffc020263e:	f04a                	sd	s2,32(sp)
ffffffffc0202640:	ec4e                	sd	s3,24(sp)
ffffffffc0202642:	e456                	sd	s5,8(sp)
ffffffffc0202644:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202646:	8f7ff0ef          	jal	ra,ffffffffc0201f3c <get_pte>
    if (ptep == NULL)
ffffffffc020264a:	c961                	beqz	a0,ffffffffc020271a <page_insert+0xee>
    page->ref += 1;
ffffffffc020264c:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc020264e:	611c                	ld	a5,0(a0)
ffffffffc0202650:	89aa                	mv	s3,a0
ffffffffc0202652:	0016871b          	addiw	a4,a3,1
ffffffffc0202656:	c018                	sw	a4,0(s0)
ffffffffc0202658:	0017f713          	andi	a4,a5,1
ffffffffc020265c:	ef05                	bnez	a4,ffffffffc0202694 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc020265e:	000a8717          	auipc	a4,0xa8
ffffffffc0202662:	0a273703          	ld	a4,162(a4) # ffffffffc02aa700 <pages>
ffffffffc0202666:	8c19                	sub	s0,s0,a4
ffffffffc0202668:	000807b7          	lui	a5,0x80
ffffffffc020266c:	8419                	srai	s0,s0,0x6
ffffffffc020266e:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202670:	042a                	slli	s0,s0,0xa
ffffffffc0202672:	8cc1                	or	s1,s1,s0
ffffffffc0202674:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202678:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ee0>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020267c:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202680:	4501                	li	a0,0
}
ffffffffc0202682:	70e2                	ld	ra,56(sp)
ffffffffc0202684:	7442                	ld	s0,48(sp)
ffffffffc0202686:	74a2                	ld	s1,40(sp)
ffffffffc0202688:	7902                	ld	s2,32(sp)
ffffffffc020268a:	69e2                	ld	s3,24(sp)
ffffffffc020268c:	6a42                	ld	s4,16(sp)
ffffffffc020268e:	6aa2                	ld	s5,8(sp)
ffffffffc0202690:	6121                	addi	sp,sp,64
ffffffffc0202692:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202694:	078a                	slli	a5,a5,0x2
ffffffffc0202696:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202698:	000a8717          	auipc	a4,0xa8
ffffffffc020269c:	06073703          	ld	a4,96(a4) # ffffffffc02aa6f8 <npage>
ffffffffc02026a0:	06e7ff63          	bgeu	a5,a4,ffffffffc020271e <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02026a4:	000a8a97          	auipc	s5,0xa8
ffffffffc02026a8:	05ca8a93          	addi	s5,s5,92 # ffffffffc02aa700 <pages>
ffffffffc02026ac:	000ab703          	ld	a4,0(s5)
ffffffffc02026b0:	fff80937          	lui	s2,0xfff80
ffffffffc02026b4:	993e                	add	s2,s2,a5
ffffffffc02026b6:	091a                	slli	s2,s2,0x6
ffffffffc02026b8:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc02026ba:	01240c63          	beq	s0,s2,ffffffffc02026d2 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc02026be:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcd58cc>
ffffffffc02026c2:	fff7869b          	addiw	a3,a5,-1
ffffffffc02026c6:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc02026ca:	c691                	beqz	a3,ffffffffc02026d6 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026cc:	120a0073          	sfence.vma	s4
}
ffffffffc02026d0:	bf59                	j	ffffffffc0202666 <page_insert+0x3a>
ffffffffc02026d2:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc02026d4:	bf49                	j	ffffffffc0202666 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02026d6:	100027f3          	csrr	a5,sstatus
ffffffffc02026da:	8b89                	andi	a5,a5,2
ffffffffc02026dc:	ef91                	bnez	a5,ffffffffc02026f8 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc02026de:	000a8797          	auipc	a5,0xa8
ffffffffc02026e2:	02a7b783          	ld	a5,42(a5) # ffffffffc02aa708 <pmm_manager>
ffffffffc02026e6:	739c                	ld	a5,32(a5)
ffffffffc02026e8:	4585                	li	a1,1
ffffffffc02026ea:	854a                	mv	a0,s2
ffffffffc02026ec:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02026ee:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026f2:	120a0073          	sfence.vma	s4
ffffffffc02026f6:	bf85                	j	ffffffffc0202666 <page_insert+0x3a>
        intr_disable();
ffffffffc02026f8:	abcfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02026fc:	000a8797          	auipc	a5,0xa8
ffffffffc0202700:	00c7b783          	ld	a5,12(a5) # ffffffffc02aa708 <pmm_manager>
ffffffffc0202704:	739c                	ld	a5,32(a5)
ffffffffc0202706:	4585                	li	a1,1
ffffffffc0202708:	854a                	mv	a0,s2
ffffffffc020270a:	9782                	jalr	a5
        intr_enable();
ffffffffc020270c:	aa2fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202710:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202714:	120a0073          	sfence.vma	s4
ffffffffc0202718:	b7b9                	j	ffffffffc0202666 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc020271a:	5571                	li	a0,-4
ffffffffc020271c:	b79d                	j	ffffffffc0202682 <page_insert+0x56>
ffffffffc020271e:	f2eff0ef          	jal	ra,ffffffffc0201e4c <pa2page.part.0>

ffffffffc0202722 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202722:	00004797          	auipc	a5,0x4
ffffffffc0202726:	df678793          	addi	a5,a5,-522 # ffffffffc0206518 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020272a:	638c                	ld	a1,0(a5)
{
ffffffffc020272c:	7159                	addi	sp,sp,-112
ffffffffc020272e:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202730:	00004517          	auipc	a0,0x4
ffffffffc0202734:	f9050513          	addi	a0,a0,-112 # ffffffffc02066c0 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc0202738:	000a8b17          	auipc	s6,0xa8
ffffffffc020273c:	fd0b0b13          	addi	s6,s6,-48 # ffffffffc02aa708 <pmm_manager>
{
ffffffffc0202740:	f486                	sd	ra,104(sp)
ffffffffc0202742:	e8ca                	sd	s2,80(sp)
ffffffffc0202744:	e4ce                	sd	s3,72(sp)
ffffffffc0202746:	f0a2                	sd	s0,96(sp)
ffffffffc0202748:	eca6                	sd	s1,88(sp)
ffffffffc020274a:	e0d2                	sd	s4,64(sp)
ffffffffc020274c:	fc56                	sd	s5,56(sp)
ffffffffc020274e:	f45e                	sd	s7,40(sp)
ffffffffc0202750:	f062                	sd	s8,32(sp)
ffffffffc0202752:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202754:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202758:	a3dfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc020275c:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202760:	000a8997          	auipc	s3,0xa8
ffffffffc0202764:	fb098993          	addi	s3,s3,-80 # ffffffffc02aa710 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202768:	679c                	ld	a5,8(a5)
ffffffffc020276a:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020276c:	57f5                	li	a5,-3
ffffffffc020276e:	07fa                	slli	a5,a5,0x1e
ffffffffc0202770:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202774:	a26fe0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc0202778:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc020277a:	a2afe0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc020277e:	200505e3          	beqz	a0,ffffffffc0203188 <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202782:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0202784:	00004517          	auipc	a0,0x4
ffffffffc0202788:	f7450513          	addi	a0,a0,-140 # ffffffffc02066f8 <default_pmm_manager+0x1e0>
ffffffffc020278c:	a09fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202790:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202794:	fff40693          	addi	a3,s0,-1
ffffffffc0202798:	864a                	mv	a2,s2
ffffffffc020279a:	85a6                	mv	a1,s1
ffffffffc020279c:	00004517          	auipc	a0,0x4
ffffffffc02027a0:	f7450513          	addi	a0,a0,-140 # ffffffffc0206710 <default_pmm_manager+0x1f8>
ffffffffc02027a4:	9f1fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02027a8:	c8000737          	lui	a4,0xc8000
ffffffffc02027ac:	87a2                	mv	a5,s0
ffffffffc02027ae:	54876163          	bltu	a4,s0,ffffffffc0202cf0 <pmm_init+0x5ce>
ffffffffc02027b2:	757d                	lui	a0,0xfffff
ffffffffc02027b4:	000a9617          	auipc	a2,0xa9
ffffffffc02027b8:	f7f60613          	addi	a2,a2,-129 # ffffffffc02ab733 <end+0xfff>
ffffffffc02027bc:	8e69                	and	a2,a2,a0
ffffffffc02027be:	000a8497          	auipc	s1,0xa8
ffffffffc02027c2:	f3a48493          	addi	s1,s1,-198 # ffffffffc02aa6f8 <npage>
ffffffffc02027c6:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027ca:	000a8b97          	auipc	s7,0xa8
ffffffffc02027ce:	f36b8b93          	addi	s7,s7,-202 # ffffffffc02aa700 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02027d2:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027d4:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027d8:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027dc:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027de:	02f50863          	beq	a0,a5,ffffffffc020280e <pmm_init+0xec>
ffffffffc02027e2:	4781                	li	a5,0
ffffffffc02027e4:	4585                	li	a1,1
ffffffffc02027e6:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02027ea:	00679513          	slli	a0,a5,0x6
ffffffffc02027ee:	9532                	add	a0,a0,a2
ffffffffc02027f0:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd548d4>
ffffffffc02027f4:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027f8:	6088                	ld	a0,0(s1)
ffffffffc02027fa:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02027fc:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202800:	00d50733          	add	a4,a0,a3
ffffffffc0202804:	fee7e3e3          	bltu	a5,a4,ffffffffc02027ea <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202808:	071a                	slli	a4,a4,0x6
ffffffffc020280a:	00e606b3          	add	a3,a2,a4
ffffffffc020280e:	c02007b7          	lui	a5,0xc0200
ffffffffc0202812:	2ef6ece3          	bltu	a3,a5,ffffffffc020330a <pmm_init+0xbe8>
ffffffffc0202816:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020281a:	77fd                	lui	a5,0xfffff
ffffffffc020281c:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020281e:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202820:	5086eb63          	bltu	a3,s0,ffffffffc0202d36 <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202824:	00004517          	auipc	a0,0x4
ffffffffc0202828:	f1450513          	addi	a0,a0,-236 # ffffffffc0206738 <default_pmm_manager+0x220>
ffffffffc020282c:	969fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202830:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202834:	000a8917          	auipc	s2,0xa8
ffffffffc0202838:	ebc90913          	addi	s2,s2,-324 # ffffffffc02aa6f0 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc020283c:	7b9c                	ld	a5,48(a5)
ffffffffc020283e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202840:	00004517          	auipc	a0,0x4
ffffffffc0202844:	f1050513          	addi	a0,a0,-240 # ffffffffc0206750 <default_pmm_manager+0x238>
ffffffffc0202848:	94dfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020284c:	00007697          	auipc	a3,0x7
ffffffffc0202850:	7b468693          	addi	a3,a3,1972 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc0202854:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202858:	c02007b7          	lui	a5,0xc0200
ffffffffc020285c:	28f6ebe3          	bltu	a3,a5,ffffffffc02032f2 <pmm_init+0xbd0>
ffffffffc0202860:	0009b783          	ld	a5,0(s3)
ffffffffc0202864:	8e9d                	sub	a3,a3,a5
ffffffffc0202866:	000a8797          	auipc	a5,0xa8
ffffffffc020286a:	e8d7b123          	sd	a3,-382(a5) # ffffffffc02aa6e8 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020286e:	100027f3          	csrr	a5,sstatus
ffffffffc0202872:	8b89                	andi	a5,a5,2
ffffffffc0202874:	4a079763          	bnez	a5,ffffffffc0202d22 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202878:	000b3783          	ld	a5,0(s6)
ffffffffc020287c:	779c                	ld	a5,40(a5)
ffffffffc020287e:	9782                	jalr	a5
ffffffffc0202880:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202882:	6098                	ld	a4,0(s1)
ffffffffc0202884:	c80007b7          	lui	a5,0xc8000
ffffffffc0202888:	83b1                	srli	a5,a5,0xc
ffffffffc020288a:	66e7e363          	bltu	a5,a4,ffffffffc0202ef0 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc020288e:	00093503          	ld	a0,0(s2)
ffffffffc0202892:	62050f63          	beqz	a0,ffffffffc0202ed0 <pmm_init+0x7ae>
ffffffffc0202896:	03451793          	slli	a5,a0,0x34
ffffffffc020289a:	62079b63          	bnez	a5,ffffffffc0202ed0 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc020289e:	4601                	li	a2,0
ffffffffc02028a0:	4581                	li	a1,0
ffffffffc02028a2:	8c3ff0ef          	jal	ra,ffffffffc0202164 <get_page>
ffffffffc02028a6:	60051563          	bnez	a0,ffffffffc0202eb0 <pmm_init+0x78e>
ffffffffc02028aa:	100027f3          	csrr	a5,sstatus
ffffffffc02028ae:	8b89                	andi	a5,a5,2
ffffffffc02028b0:	44079e63          	bnez	a5,ffffffffc0202d0c <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc02028b4:	000b3783          	ld	a5,0(s6)
ffffffffc02028b8:	4505                	li	a0,1
ffffffffc02028ba:	6f9c                	ld	a5,24(a5)
ffffffffc02028bc:	9782                	jalr	a5
ffffffffc02028be:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02028c0:	00093503          	ld	a0,0(s2)
ffffffffc02028c4:	4681                	li	a3,0
ffffffffc02028c6:	4601                	li	a2,0
ffffffffc02028c8:	85d2                	mv	a1,s4
ffffffffc02028ca:	d63ff0ef          	jal	ra,ffffffffc020262c <page_insert>
ffffffffc02028ce:	26051ae3          	bnez	a0,ffffffffc0203342 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02028d2:	00093503          	ld	a0,0(s2)
ffffffffc02028d6:	4601                	li	a2,0
ffffffffc02028d8:	4581                	li	a1,0
ffffffffc02028da:	e62ff0ef          	jal	ra,ffffffffc0201f3c <get_pte>
ffffffffc02028de:	240502e3          	beqz	a0,ffffffffc0203322 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc02028e2:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc02028e4:	0017f713          	andi	a4,a5,1
ffffffffc02028e8:	5a070263          	beqz	a4,ffffffffc0202e8c <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02028ec:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02028ee:	078a                	slli	a5,a5,0x2
ffffffffc02028f0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02028f2:	58e7fb63          	bgeu	a5,a4,ffffffffc0202e88 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02028f6:	000bb683          	ld	a3,0(s7)
ffffffffc02028fa:	fff80637          	lui	a2,0xfff80
ffffffffc02028fe:	97b2                	add	a5,a5,a2
ffffffffc0202900:	079a                	slli	a5,a5,0x6
ffffffffc0202902:	97b6                	add	a5,a5,a3
ffffffffc0202904:	14fa17e3          	bne	s4,a5,ffffffffc0203252 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0202908:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>
ffffffffc020290c:	4785                	li	a5,1
ffffffffc020290e:	12f692e3          	bne	a3,a5,ffffffffc0203232 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202912:	00093503          	ld	a0,0(s2)
ffffffffc0202916:	77fd                	lui	a5,0xfffff
ffffffffc0202918:	6114                	ld	a3,0(a0)
ffffffffc020291a:	068a                	slli	a3,a3,0x2
ffffffffc020291c:	8efd                	and	a3,a3,a5
ffffffffc020291e:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202922:	0ee67ce3          	bgeu	a2,a4,ffffffffc020321a <pmm_init+0xaf8>
ffffffffc0202926:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020292a:	96e2                	add	a3,a3,s8
ffffffffc020292c:	0006ba83          	ld	s5,0(a3)
ffffffffc0202930:	0a8a                	slli	s5,s5,0x2
ffffffffc0202932:	00fafab3          	and	s5,s5,a5
ffffffffc0202936:	00cad793          	srli	a5,s5,0xc
ffffffffc020293a:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0203200 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020293e:	4601                	li	a2,0
ffffffffc0202940:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202942:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202944:	df8ff0ef          	jal	ra,ffffffffc0201f3c <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202948:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020294a:	55551363          	bne	a0,s5,ffffffffc0202e90 <pmm_init+0x76e>
ffffffffc020294e:	100027f3          	csrr	a5,sstatus
ffffffffc0202952:	8b89                	andi	a5,a5,2
ffffffffc0202954:	3a079163          	bnez	a5,ffffffffc0202cf6 <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202958:	000b3783          	ld	a5,0(s6)
ffffffffc020295c:	4505                	li	a0,1
ffffffffc020295e:	6f9c                	ld	a5,24(a5)
ffffffffc0202960:	9782                	jalr	a5
ffffffffc0202962:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202964:	00093503          	ld	a0,0(s2)
ffffffffc0202968:	46d1                	li	a3,20
ffffffffc020296a:	6605                	lui	a2,0x1
ffffffffc020296c:	85e2                	mv	a1,s8
ffffffffc020296e:	cbfff0ef          	jal	ra,ffffffffc020262c <page_insert>
ffffffffc0202972:	060517e3          	bnez	a0,ffffffffc02031e0 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202976:	00093503          	ld	a0,0(s2)
ffffffffc020297a:	4601                	li	a2,0
ffffffffc020297c:	6585                	lui	a1,0x1
ffffffffc020297e:	dbeff0ef          	jal	ra,ffffffffc0201f3c <get_pte>
ffffffffc0202982:	02050fe3          	beqz	a0,ffffffffc02031c0 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc0202986:	611c                	ld	a5,0(a0)
ffffffffc0202988:	0107f713          	andi	a4,a5,16
ffffffffc020298c:	7c070e63          	beqz	a4,ffffffffc0203168 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202990:	8b91                	andi	a5,a5,4
ffffffffc0202992:	7a078b63          	beqz	a5,ffffffffc0203148 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202996:	00093503          	ld	a0,0(s2)
ffffffffc020299a:	611c                	ld	a5,0(a0)
ffffffffc020299c:	8bc1                	andi	a5,a5,16
ffffffffc020299e:	78078563          	beqz	a5,ffffffffc0203128 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc02029a2:	000c2703          	lw	a4,0(s8)
ffffffffc02029a6:	4785                	li	a5,1
ffffffffc02029a8:	76f71063          	bne	a4,a5,ffffffffc0203108 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02029ac:	4681                	li	a3,0
ffffffffc02029ae:	6605                	lui	a2,0x1
ffffffffc02029b0:	85d2                	mv	a1,s4
ffffffffc02029b2:	c7bff0ef          	jal	ra,ffffffffc020262c <page_insert>
ffffffffc02029b6:	72051963          	bnez	a0,ffffffffc02030e8 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc02029ba:	000a2703          	lw	a4,0(s4)
ffffffffc02029be:	4789                	li	a5,2
ffffffffc02029c0:	70f71463          	bne	a4,a5,ffffffffc02030c8 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc02029c4:	000c2783          	lw	a5,0(s8)
ffffffffc02029c8:	6e079063          	bnez	a5,ffffffffc02030a8 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02029cc:	00093503          	ld	a0,0(s2)
ffffffffc02029d0:	4601                	li	a2,0
ffffffffc02029d2:	6585                	lui	a1,0x1
ffffffffc02029d4:	d68ff0ef          	jal	ra,ffffffffc0201f3c <get_pte>
ffffffffc02029d8:	6a050863          	beqz	a0,ffffffffc0203088 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc02029dc:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc02029de:	00177793          	andi	a5,a4,1
ffffffffc02029e2:	4a078563          	beqz	a5,ffffffffc0202e8c <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02029e6:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02029e8:	00271793          	slli	a5,a4,0x2
ffffffffc02029ec:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029ee:	48d7fd63          	bgeu	a5,a3,ffffffffc0202e88 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02029f2:	000bb683          	ld	a3,0(s7)
ffffffffc02029f6:	fff80ab7          	lui	s5,0xfff80
ffffffffc02029fa:	97d6                	add	a5,a5,s5
ffffffffc02029fc:	079a                	slli	a5,a5,0x6
ffffffffc02029fe:	97b6                	add	a5,a5,a3
ffffffffc0202a00:	66fa1463          	bne	s4,a5,ffffffffc0203068 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a04:	8b41                	andi	a4,a4,16
ffffffffc0202a06:	64071163          	bnez	a4,ffffffffc0203048 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202a0a:	00093503          	ld	a0,0(s2)
ffffffffc0202a0e:	4581                	li	a1,0
ffffffffc0202a10:	b81ff0ef          	jal	ra,ffffffffc0202590 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202a14:	000a2c83          	lw	s9,0(s4)
ffffffffc0202a18:	4785                	li	a5,1
ffffffffc0202a1a:	60fc9763          	bne	s9,a5,ffffffffc0203028 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202a1e:	000c2783          	lw	a5,0(s8)
ffffffffc0202a22:	5e079363          	bnez	a5,ffffffffc0203008 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202a26:	00093503          	ld	a0,0(s2)
ffffffffc0202a2a:	6585                	lui	a1,0x1
ffffffffc0202a2c:	b65ff0ef          	jal	ra,ffffffffc0202590 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202a30:	000a2783          	lw	a5,0(s4)
ffffffffc0202a34:	52079a63          	bnez	a5,ffffffffc0202f68 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202a38:	000c2783          	lw	a5,0(s8)
ffffffffc0202a3c:	50079663          	bnez	a5,ffffffffc0202f48 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202a40:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202a44:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a46:	000a3683          	ld	a3,0(s4)
ffffffffc0202a4a:	068a                	slli	a3,a3,0x2
ffffffffc0202a4c:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a4e:	42b6fd63          	bgeu	a3,a1,ffffffffc0202e88 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a52:	000bb503          	ld	a0,0(s7)
ffffffffc0202a56:	96d6                	add	a3,a3,s5
ffffffffc0202a58:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202a5a:	00d507b3          	add	a5,a0,a3
ffffffffc0202a5e:	439c                	lw	a5,0(a5)
ffffffffc0202a60:	4d979463          	bne	a5,s9,ffffffffc0202f28 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202a64:	8699                	srai	a3,a3,0x6
ffffffffc0202a66:	00080637          	lui	a2,0x80
ffffffffc0202a6a:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202a6c:	00c69713          	slli	a4,a3,0xc
ffffffffc0202a70:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a72:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202a74:	48b77e63          	bgeu	a4,a1,ffffffffc0202f10 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202a78:	0009b703          	ld	a4,0(s3)
ffffffffc0202a7c:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a7e:	629c                	ld	a5,0(a3)
ffffffffc0202a80:	078a                	slli	a5,a5,0x2
ffffffffc0202a82:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a84:	40b7f263          	bgeu	a5,a1,ffffffffc0202e88 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a88:	8f91                	sub	a5,a5,a2
ffffffffc0202a8a:	079a                	slli	a5,a5,0x6
ffffffffc0202a8c:	953e                	add	a0,a0,a5
ffffffffc0202a8e:	100027f3          	csrr	a5,sstatus
ffffffffc0202a92:	8b89                	andi	a5,a5,2
ffffffffc0202a94:	30079963          	bnez	a5,ffffffffc0202da6 <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202a98:	000b3783          	ld	a5,0(s6)
ffffffffc0202a9c:	4585                	li	a1,1
ffffffffc0202a9e:	739c                	ld	a5,32(a5)
ffffffffc0202aa0:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202aa2:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202aa6:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202aa8:	078a                	slli	a5,a5,0x2
ffffffffc0202aaa:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202aac:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202e88 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ab0:	000bb503          	ld	a0,0(s7)
ffffffffc0202ab4:	fff80737          	lui	a4,0xfff80
ffffffffc0202ab8:	97ba                	add	a5,a5,a4
ffffffffc0202aba:	079a                	slli	a5,a5,0x6
ffffffffc0202abc:	953e                	add	a0,a0,a5
ffffffffc0202abe:	100027f3          	csrr	a5,sstatus
ffffffffc0202ac2:	8b89                	andi	a5,a5,2
ffffffffc0202ac4:	2c079563          	bnez	a5,ffffffffc0202d8e <pmm_init+0x66c>
ffffffffc0202ac8:	000b3783          	ld	a5,0(s6)
ffffffffc0202acc:	4585                	li	a1,1
ffffffffc0202ace:	739c                	ld	a5,32(a5)
ffffffffc0202ad0:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202ad2:	00093783          	ld	a5,0(s2)
ffffffffc0202ad6:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd548cc>
    asm volatile("sfence.vma");
ffffffffc0202ada:	12000073          	sfence.vma
ffffffffc0202ade:	100027f3          	csrr	a5,sstatus
ffffffffc0202ae2:	8b89                	andi	a5,a5,2
ffffffffc0202ae4:	28079b63          	bnez	a5,ffffffffc0202d7a <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ae8:	000b3783          	ld	a5,0(s6)
ffffffffc0202aec:	779c                	ld	a5,40(a5)
ffffffffc0202aee:	9782                	jalr	a5
ffffffffc0202af0:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202af2:	4b441b63          	bne	s0,s4,ffffffffc0202fa8 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202af6:	00004517          	auipc	a0,0x4
ffffffffc0202afa:	f8250513          	addi	a0,a0,-126 # ffffffffc0206a78 <default_pmm_manager+0x560>
ffffffffc0202afe:	e96fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202b02:	100027f3          	csrr	a5,sstatus
ffffffffc0202b06:	8b89                	andi	a5,a5,2
ffffffffc0202b08:	24079f63          	bnez	a5,ffffffffc0202d66 <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b0c:	000b3783          	ld	a5,0(s6)
ffffffffc0202b10:	779c                	ld	a5,40(a5)
ffffffffc0202b12:	9782                	jalr	a5
ffffffffc0202b14:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b16:	6098                	ld	a4,0(s1)
ffffffffc0202b18:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b1c:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b1e:	00c71793          	slli	a5,a4,0xc
ffffffffc0202b22:	6a05                	lui	s4,0x1
ffffffffc0202b24:	02f47c63          	bgeu	s0,a5,ffffffffc0202b5c <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202b28:	00c45793          	srli	a5,s0,0xc
ffffffffc0202b2c:	00093503          	ld	a0,0(s2)
ffffffffc0202b30:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202e2e <pmm_init+0x70c>
ffffffffc0202b34:	0009b583          	ld	a1,0(s3)
ffffffffc0202b38:	4601                	li	a2,0
ffffffffc0202b3a:	95a2                	add	a1,a1,s0
ffffffffc0202b3c:	c00ff0ef          	jal	ra,ffffffffc0201f3c <get_pte>
ffffffffc0202b40:	32050463          	beqz	a0,ffffffffc0202e68 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b44:	611c                	ld	a5,0(a0)
ffffffffc0202b46:	078a                	slli	a5,a5,0x2
ffffffffc0202b48:	0157f7b3          	and	a5,a5,s5
ffffffffc0202b4c:	2e879e63          	bne	a5,s0,ffffffffc0202e48 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b50:	6098                	ld	a4,0(s1)
ffffffffc0202b52:	9452                	add	s0,s0,s4
ffffffffc0202b54:	00c71793          	slli	a5,a4,0xc
ffffffffc0202b58:	fcf468e3          	bltu	s0,a5,ffffffffc0202b28 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202b5c:	00093783          	ld	a5,0(s2)
ffffffffc0202b60:	639c                	ld	a5,0(a5)
ffffffffc0202b62:	42079363          	bnez	a5,ffffffffc0202f88 <pmm_init+0x866>
ffffffffc0202b66:	100027f3          	csrr	a5,sstatus
ffffffffc0202b6a:	8b89                	andi	a5,a5,2
ffffffffc0202b6c:	24079963          	bnez	a5,ffffffffc0202dbe <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202b70:	000b3783          	ld	a5,0(s6)
ffffffffc0202b74:	4505                	li	a0,1
ffffffffc0202b76:	6f9c                	ld	a5,24(a5)
ffffffffc0202b78:	9782                	jalr	a5
ffffffffc0202b7a:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202b7c:	00093503          	ld	a0,0(s2)
ffffffffc0202b80:	4699                	li	a3,6
ffffffffc0202b82:	10000613          	li	a2,256
ffffffffc0202b86:	85d2                	mv	a1,s4
ffffffffc0202b88:	aa5ff0ef          	jal	ra,ffffffffc020262c <page_insert>
ffffffffc0202b8c:	44051e63          	bnez	a0,ffffffffc0202fe8 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202b90:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>
ffffffffc0202b94:	4785                	li	a5,1
ffffffffc0202b96:	42f71963          	bne	a4,a5,ffffffffc0202fc8 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202b9a:	00093503          	ld	a0,0(s2)
ffffffffc0202b9e:	6405                	lui	s0,0x1
ffffffffc0202ba0:	4699                	li	a3,6
ffffffffc0202ba2:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8aa8>
ffffffffc0202ba6:	85d2                	mv	a1,s4
ffffffffc0202ba8:	a85ff0ef          	jal	ra,ffffffffc020262c <page_insert>
ffffffffc0202bac:	72051363          	bnez	a0,ffffffffc02032d2 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202bb0:	000a2703          	lw	a4,0(s4)
ffffffffc0202bb4:	4789                	li	a5,2
ffffffffc0202bb6:	6ef71e63          	bne	a4,a5,ffffffffc02032b2 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202bba:	00004597          	auipc	a1,0x4
ffffffffc0202bbe:	00658593          	addi	a1,a1,6 # ffffffffc0206bc0 <default_pmm_manager+0x6a8>
ffffffffc0202bc2:	10000513          	li	a0,256
ffffffffc0202bc6:	289020ef          	jal	ra,ffffffffc020564e <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202bca:	10040593          	addi	a1,s0,256
ffffffffc0202bce:	10000513          	li	a0,256
ffffffffc0202bd2:	28f020ef          	jal	ra,ffffffffc0205660 <strcmp>
ffffffffc0202bd6:	6a051e63          	bnez	a0,ffffffffc0203292 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202bda:	000bb683          	ld	a3,0(s7)
ffffffffc0202bde:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202be2:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202be4:	40da06b3          	sub	a3,s4,a3
ffffffffc0202be8:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202bea:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202bec:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202bee:	8031                	srli	s0,s0,0xc
ffffffffc0202bf0:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202bf4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202bf6:	30f77d63          	bgeu	a4,a5,ffffffffc0202f10 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202bfa:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202bfe:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c02:	96be                	add	a3,a3,a5
ffffffffc0202c04:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c08:	211020ef          	jal	ra,ffffffffc0205618 <strlen>
ffffffffc0202c0c:	66051363          	bnez	a0,ffffffffc0203272 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202c10:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202c14:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c16:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd548cc>
ffffffffc0202c1a:	068a                	slli	a3,a3,0x2
ffffffffc0202c1c:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c1e:	26f6f563          	bgeu	a3,a5,ffffffffc0202e88 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202c22:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c24:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c26:	2ef47563          	bgeu	s0,a5,ffffffffc0202f10 <pmm_init+0x7ee>
ffffffffc0202c2a:	0009b403          	ld	s0,0(s3)
ffffffffc0202c2e:	9436                	add	s0,s0,a3
ffffffffc0202c30:	100027f3          	csrr	a5,sstatus
ffffffffc0202c34:	8b89                	andi	a5,a5,2
ffffffffc0202c36:	1e079163          	bnez	a5,ffffffffc0202e18 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202c3a:	000b3783          	ld	a5,0(s6)
ffffffffc0202c3e:	4585                	li	a1,1
ffffffffc0202c40:	8552                	mv	a0,s4
ffffffffc0202c42:	739c                	ld	a5,32(a5)
ffffffffc0202c44:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c46:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202c48:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c4a:	078a                	slli	a5,a5,0x2
ffffffffc0202c4c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c4e:	22e7fd63          	bgeu	a5,a4,ffffffffc0202e88 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c52:	000bb503          	ld	a0,0(s7)
ffffffffc0202c56:	fff80737          	lui	a4,0xfff80
ffffffffc0202c5a:	97ba                	add	a5,a5,a4
ffffffffc0202c5c:	079a                	slli	a5,a5,0x6
ffffffffc0202c5e:	953e                	add	a0,a0,a5
ffffffffc0202c60:	100027f3          	csrr	a5,sstatus
ffffffffc0202c64:	8b89                	andi	a5,a5,2
ffffffffc0202c66:	18079d63          	bnez	a5,ffffffffc0202e00 <pmm_init+0x6de>
ffffffffc0202c6a:	000b3783          	ld	a5,0(s6)
ffffffffc0202c6e:	4585                	li	a1,1
ffffffffc0202c70:	739c                	ld	a5,32(a5)
ffffffffc0202c72:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c74:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202c78:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c7a:	078a                	slli	a5,a5,0x2
ffffffffc0202c7c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c7e:	20e7f563          	bgeu	a5,a4,ffffffffc0202e88 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c82:	000bb503          	ld	a0,0(s7)
ffffffffc0202c86:	fff80737          	lui	a4,0xfff80
ffffffffc0202c8a:	97ba                	add	a5,a5,a4
ffffffffc0202c8c:	079a                	slli	a5,a5,0x6
ffffffffc0202c8e:	953e                	add	a0,a0,a5
ffffffffc0202c90:	100027f3          	csrr	a5,sstatus
ffffffffc0202c94:	8b89                	andi	a5,a5,2
ffffffffc0202c96:	14079963          	bnez	a5,ffffffffc0202de8 <pmm_init+0x6c6>
ffffffffc0202c9a:	000b3783          	ld	a5,0(s6)
ffffffffc0202c9e:	4585                	li	a1,1
ffffffffc0202ca0:	739c                	ld	a5,32(a5)
ffffffffc0202ca2:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202ca4:	00093783          	ld	a5,0(s2)
ffffffffc0202ca8:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202cac:	12000073          	sfence.vma
ffffffffc0202cb0:	100027f3          	csrr	a5,sstatus
ffffffffc0202cb4:	8b89                	andi	a5,a5,2
ffffffffc0202cb6:	10079f63          	bnez	a5,ffffffffc0202dd4 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cba:	000b3783          	ld	a5,0(s6)
ffffffffc0202cbe:	779c                	ld	a5,40(a5)
ffffffffc0202cc0:	9782                	jalr	a5
ffffffffc0202cc2:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202cc4:	4c8c1e63          	bne	s8,s0,ffffffffc02031a0 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202cc8:	00004517          	auipc	a0,0x4
ffffffffc0202ccc:	f7050513          	addi	a0,a0,-144 # ffffffffc0206c38 <default_pmm_manager+0x720>
ffffffffc0202cd0:	cc4fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202cd4:	7406                	ld	s0,96(sp)
ffffffffc0202cd6:	70a6                	ld	ra,104(sp)
ffffffffc0202cd8:	64e6                	ld	s1,88(sp)
ffffffffc0202cda:	6946                	ld	s2,80(sp)
ffffffffc0202cdc:	69a6                	ld	s3,72(sp)
ffffffffc0202cde:	6a06                	ld	s4,64(sp)
ffffffffc0202ce0:	7ae2                	ld	s5,56(sp)
ffffffffc0202ce2:	7b42                	ld	s6,48(sp)
ffffffffc0202ce4:	7ba2                	ld	s7,40(sp)
ffffffffc0202ce6:	7c02                	ld	s8,32(sp)
ffffffffc0202ce8:	6ce2                	ld	s9,24(sp)
ffffffffc0202cea:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202cec:	f97fe06f          	j	ffffffffc0201c82 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202cf0:	c80007b7          	lui	a5,0xc8000
ffffffffc0202cf4:	bc7d                	j	ffffffffc02027b2 <pmm_init+0x90>
        intr_disable();
ffffffffc0202cf6:	cbffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202cfa:	000b3783          	ld	a5,0(s6)
ffffffffc0202cfe:	4505                	li	a0,1
ffffffffc0202d00:	6f9c                	ld	a5,24(a5)
ffffffffc0202d02:	9782                	jalr	a5
ffffffffc0202d04:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d06:	ca9fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d0a:	b9a9                	j	ffffffffc0202964 <pmm_init+0x242>
        intr_disable();
ffffffffc0202d0c:	ca9fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202d10:	000b3783          	ld	a5,0(s6)
ffffffffc0202d14:	4505                	li	a0,1
ffffffffc0202d16:	6f9c                	ld	a5,24(a5)
ffffffffc0202d18:	9782                	jalr	a5
ffffffffc0202d1a:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d1c:	c93fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d20:	b645                	j	ffffffffc02028c0 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202d22:	c93fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d26:	000b3783          	ld	a5,0(s6)
ffffffffc0202d2a:	779c                	ld	a5,40(a5)
ffffffffc0202d2c:	9782                	jalr	a5
ffffffffc0202d2e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d30:	c7ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d34:	b6b9                	j	ffffffffc0202882 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202d36:	6705                	lui	a4,0x1
ffffffffc0202d38:	177d                	addi	a4,a4,-1
ffffffffc0202d3a:	96ba                	add	a3,a3,a4
ffffffffc0202d3c:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202d3e:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202d42:	14a77363          	bgeu	a4,a0,ffffffffc0202e88 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202d46:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202d4a:	fff80537          	lui	a0,0xfff80
ffffffffc0202d4e:	972a                	add	a4,a4,a0
ffffffffc0202d50:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202d52:	8c1d                	sub	s0,s0,a5
ffffffffc0202d54:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202d58:	00c45593          	srli	a1,s0,0xc
ffffffffc0202d5c:	9532                	add	a0,a0,a2
ffffffffc0202d5e:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202d60:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202d64:	b4c1                	j	ffffffffc0202824 <pmm_init+0x102>
        intr_disable();
ffffffffc0202d66:	c4ffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d6a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d6e:	779c                	ld	a5,40(a5)
ffffffffc0202d70:	9782                	jalr	a5
ffffffffc0202d72:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d74:	c3bfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d78:	bb79                	j	ffffffffc0202b16 <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202d7a:	c3bfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202d7e:	000b3783          	ld	a5,0(s6)
ffffffffc0202d82:	779c                	ld	a5,40(a5)
ffffffffc0202d84:	9782                	jalr	a5
ffffffffc0202d86:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d88:	c27fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d8c:	b39d                	j	ffffffffc0202af2 <pmm_init+0x3d0>
ffffffffc0202d8e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d90:	c25fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202d94:	000b3783          	ld	a5,0(s6)
ffffffffc0202d98:	6522                	ld	a0,8(sp)
ffffffffc0202d9a:	4585                	li	a1,1
ffffffffc0202d9c:	739c                	ld	a5,32(a5)
ffffffffc0202d9e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202da0:	c0ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202da4:	b33d                	j	ffffffffc0202ad2 <pmm_init+0x3b0>
ffffffffc0202da6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202da8:	c0dfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202dac:	000b3783          	ld	a5,0(s6)
ffffffffc0202db0:	6522                	ld	a0,8(sp)
ffffffffc0202db2:	4585                	li	a1,1
ffffffffc0202db4:	739c                	ld	a5,32(a5)
ffffffffc0202db6:	9782                	jalr	a5
        intr_enable();
ffffffffc0202db8:	bf7fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dbc:	b1dd                	j	ffffffffc0202aa2 <pmm_init+0x380>
        intr_disable();
ffffffffc0202dbe:	bf7fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202dc2:	000b3783          	ld	a5,0(s6)
ffffffffc0202dc6:	4505                	li	a0,1
ffffffffc0202dc8:	6f9c                	ld	a5,24(a5)
ffffffffc0202dca:	9782                	jalr	a5
ffffffffc0202dcc:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202dce:	be1fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dd2:	b36d                	j	ffffffffc0202b7c <pmm_init+0x45a>
        intr_disable();
ffffffffc0202dd4:	be1fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202dd8:	000b3783          	ld	a5,0(s6)
ffffffffc0202ddc:	779c                	ld	a5,40(a5)
ffffffffc0202dde:	9782                	jalr	a5
ffffffffc0202de0:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202de2:	bcdfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202de6:	bdf9                	j	ffffffffc0202cc4 <pmm_init+0x5a2>
ffffffffc0202de8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202dea:	bcbfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202dee:	000b3783          	ld	a5,0(s6)
ffffffffc0202df2:	6522                	ld	a0,8(sp)
ffffffffc0202df4:	4585                	li	a1,1
ffffffffc0202df6:	739c                	ld	a5,32(a5)
ffffffffc0202df8:	9782                	jalr	a5
        intr_enable();
ffffffffc0202dfa:	bb5fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dfe:	b55d                	j	ffffffffc0202ca4 <pmm_init+0x582>
ffffffffc0202e00:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e02:	bb3fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e06:	000b3783          	ld	a5,0(s6)
ffffffffc0202e0a:	6522                	ld	a0,8(sp)
ffffffffc0202e0c:	4585                	li	a1,1
ffffffffc0202e0e:	739c                	ld	a5,32(a5)
ffffffffc0202e10:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e12:	b9dfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e16:	bdb9                	j	ffffffffc0202c74 <pmm_init+0x552>
        intr_disable();
ffffffffc0202e18:	b9dfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e1c:	000b3783          	ld	a5,0(s6)
ffffffffc0202e20:	4585                	li	a1,1
ffffffffc0202e22:	8552                	mv	a0,s4
ffffffffc0202e24:	739c                	ld	a5,32(a5)
ffffffffc0202e26:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e28:	b87fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e2c:	bd29                	j	ffffffffc0202c46 <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e2e:	86a2                	mv	a3,s0
ffffffffc0202e30:	00003617          	auipc	a2,0x3
ffffffffc0202e34:	72060613          	addi	a2,a2,1824 # ffffffffc0206550 <default_pmm_manager+0x38>
ffffffffc0202e38:	25400593          	li	a1,596
ffffffffc0202e3c:	00004517          	auipc	a0,0x4
ffffffffc0202e40:	82c50513          	addi	a0,a0,-2004 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0202e44:	e4afd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202e48:	00004697          	auipc	a3,0x4
ffffffffc0202e4c:	c9068693          	addi	a3,a3,-880 # ffffffffc0206ad8 <default_pmm_manager+0x5c0>
ffffffffc0202e50:	00003617          	auipc	a2,0x3
ffffffffc0202e54:	31860613          	addi	a2,a2,792 # ffffffffc0206168 <commands+0x818>
ffffffffc0202e58:	25500593          	li	a1,597
ffffffffc0202e5c:	00004517          	auipc	a0,0x4
ffffffffc0202e60:	80c50513          	addi	a0,a0,-2036 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0202e64:	e2afd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e68:	00004697          	auipc	a3,0x4
ffffffffc0202e6c:	c3068693          	addi	a3,a3,-976 # ffffffffc0206a98 <default_pmm_manager+0x580>
ffffffffc0202e70:	00003617          	auipc	a2,0x3
ffffffffc0202e74:	2f860613          	addi	a2,a2,760 # ffffffffc0206168 <commands+0x818>
ffffffffc0202e78:	25400593          	li	a1,596
ffffffffc0202e7c:	00003517          	auipc	a0,0x3
ffffffffc0202e80:	7ec50513          	addi	a0,a0,2028 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0202e84:	e0afd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202e88:	fc5fe0ef          	jal	ra,ffffffffc0201e4c <pa2page.part.0>
ffffffffc0202e8c:	fddfe0ef          	jal	ra,ffffffffc0201e68 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202e90:	00004697          	auipc	a3,0x4
ffffffffc0202e94:	a0068693          	addi	a3,a3,-1536 # ffffffffc0206890 <default_pmm_manager+0x378>
ffffffffc0202e98:	00003617          	auipc	a2,0x3
ffffffffc0202e9c:	2d060613          	addi	a2,a2,720 # ffffffffc0206168 <commands+0x818>
ffffffffc0202ea0:	22400593          	li	a1,548
ffffffffc0202ea4:	00003517          	auipc	a0,0x3
ffffffffc0202ea8:	7c450513          	addi	a0,a0,1988 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0202eac:	de2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202eb0:	00004697          	auipc	a3,0x4
ffffffffc0202eb4:	92068693          	addi	a3,a3,-1760 # ffffffffc02067d0 <default_pmm_manager+0x2b8>
ffffffffc0202eb8:	00003617          	auipc	a2,0x3
ffffffffc0202ebc:	2b060613          	addi	a2,a2,688 # ffffffffc0206168 <commands+0x818>
ffffffffc0202ec0:	21700593          	li	a1,535
ffffffffc0202ec4:	00003517          	auipc	a0,0x3
ffffffffc0202ec8:	7a450513          	addi	a0,a0,1956 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0202ecc:	dc2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202ed0:	00004697          	auipc	a3,0x4
ffffffffc0202ed4:	8c068693          	addi	a3,a3,-1856 # ffffffffc0206790 <default_pmm_manager+0x278>
ffffffffc0202ed8:	00003617          	auipc	a2,0x3
ffffffffc0202edc:	29060613          	addi	a2,a2,656 # ffffffffc0206168 <commands+0x818>
ffffffffc0202ee0:	21600593          	li	a1,534
ffffffffc0202ee4:	00003517          	auipc	a0,0x3
ffffffffc0202ee8:	78450513          	addi	a0,a0,1924 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0202eec:	da2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202ef0:	00004697          	auipc	a3,0x4
ffffffffc0202ef4:	88068693          	addi	a3,a3,-1920 # ffffffffc0206770 <default_pmm_manager+0x258>
ffffffffc0202ef8:	00003617          	auipc	a2,0x3
ffffffffc0202efc:	27060613          	addi	a2,a2,624 # ffffffffc0206168 <commands+0x818>
ffffffffc0202f00:	21500593          	li	a1,533
ffffffffc0202f04:	00003517          	auipc	a0,0x3
ffffffffc0202f08:	76450513          	addi	a0,a0,1892 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0202f0c:	d82fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202f10:	00003617          	auipc	a2,0x3
ffffffffc0202f14:	64060613          	addi	a2,a2,1600 # ffffffffc0206550 <default_pmm_manager+0x38>
ffffffffc0202f18:	07100593          	li	a1,113
ffffffffc0202f1c:	00003517          	auipc	a0,0x3
ffffffffc0202f20:	65c50513          	addi	a0,a0,1628 # ffffffffc0206578 <default_pmm_manager+0x60>
ffffffffc0202f24:	d6afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202f28:	00004697          	auipc	a3,0x4
ffffffffc0202f2c:	af868693          	addi	a3,a3,-1288 # ffffffffc0206a20 <default_pmm_manager+0x508>
ffffffffc0202f30:	00003617          	auipc	a2,0x3
ffffffffc0202f34:	23860613          	addi	a2,a2,568 # ffffffffc0206168 <commands+0x818>
ffffffffc0202f38:	23d00593          	li	a1,573
ffffffffc0202f3c:	00003517          	auipc	a0,0x3
ffffffffc0202f40:	72c50513          	addi	a0,a0,1836 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0202f44:	d4afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f48:	00004697          	auipc	a3,0x4
ffffffffc0202f4c:	a9068693          	addi	a3,a3,-1392 # ffffffffc02069d8 <default_pmm_manager+0x4c0>
ffffffffc0202f50:	00003617          	auipc	a2,0x3
ffffffffc0202f54:	21860613          	addi	a2,a2,536 # ffffffffc0206168 <commands+0x818>
ffffffffc0202f58:	23b00593          	li	a1,571
ffffffffc0202f5c:	00003517          	auipc	a0,0x3
ffffffffc0202f60:	70c50513          	addi	a0,a0,1804 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0202f64:	d2afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202f68:	00004697          	auipc	a3,0x4
ffffffffc0202f6c:	aa068693          	addi	a3,a3,-1376 # ffffffffc0206a08 <default_pmm_manager+0x4f0>
ffffffffc0202f70:	00003617          	auipc	a2,0x3
ffffffffc0202f74:	1f860613          	addi	a2,a2,504 # ffffffffc0206168 <commands+0x818>
ffffffffc0202f78:	23a00593          	li	a1,570
ffffffffc0202f7c:	00003517          	auipc	a0,0x3
ffffffffc0202f80:	6ec50513          	addi	a0,a0,1772 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0202f84:	d0afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202f88:	00004697          	auipc	a3,0x4
ffffffffc0202f8c:	b6868693          	addi	a3,a3,-1176 # ffffffffc0206af0 <default_pmm_manager+0x5d8>
ffffffffc0202f90:	00003617          	auipc	a2,0x3
ffffffffc0202f94:	1d860613          	addi	a2,a2,472 # ffffffffc0206168 <commands+0x818>
ffffffffc0202f98:	25800593          	li	a1,600
ffffffffc0202f9c:	00003517          	auipc	a0,0x3
ffffffffc0202fa0:	6cc50513          	addi	a0,a0,1740 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0202fa4:	ceafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202fa8:	00004697          	auipc	a3,0x4
ffffffffc0202fac:	aa868693          	addi	a3,a3,-1368 # ffffffffc0206a50 <default_pmm_manager+0x538>
ffffffffc0202fb0:	00003617          	auipc	a2,0x3
ffffffffc0202fb4:	1b860613          	addi	a2,a2,440 # ffffffffc0206168 <commands+0x818>
ffffffffc0202fb8:	24500593          	li	a1,581
ffffffffc0202fbc:	00003517          	auipc	a0,0x3
ffffffffc0202fc0:	6ac50513          	addi	a0,a0,1708 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0202fc4:	ccafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202fc8:	00004697          	auipc	a3,0x4
ffffffffc0202fcc:	b8068693          	addi	a3,a3,-1152 # ffffffffc0206b48 <default_pmm_manager+0x630>
ffffffffc0202fd0:	00003617          	auipc	a2,0x3
ffffffffc0202fd4:	19860613          	addi	a2,a2,408 # ffffffffc0206168 <commands+0x818>
ffffffffc0202fd8:	25d00593          	li	a1,605
ffffffffc0202fdc:	00003517          	auipc	a0,0x3
ffffffffc0202fe0:	68c50513          	addi	a0,a0,1676 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0202fe4:	caafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202fe8:	00004697          	auipc	a3,0x4
ffffffffc0202fec:	b2068693          	addi	a3,a3,-1248 # ffffffffc0206b08 <default_pmm_manager+0x5f0>
ffffffffc0202ff0:	00003617          	auipc	a2,0x3
ffffffffc0202ff4:	17860613          	addi	a2,a2,376 # ffffffffc0206168 <commands+0x818>
ffffffffc0202ff8:	25c00593          	li	a1,604
ffffffffc0202ffc:	00003517          	auipc	a0,0x3
ffffffffc0203000:	66c50513          	addi	a0,a0,1644 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0203004:	c8afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203008:	00004697          	auipc	a3,0x4
ffffffffc020300c:	9d068693          	addi	a3,a3,-1584 # ffffffffc02069d8 <default_pmm_manager+0x4c0>
ffffffffc0203010:	00003617          	auipc	a2,0x3
ffffffffc0203014:	15860613          	addi	a2,a2,344 # ffffffffc0206168 <commands+0x818>
ffffffffc0203018:	23700593          	li	a1,567
ffffffffc020301c:	00003517          	auipc	a0,0x3
ffffffffc0203020:	64c50513          	addi	a0,a0,1612 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0203024:	c6afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203028:	00004697          	auipc	a3,0x4
ffffffffc020302c:	85068693          	addi	a3,a3,-1968 # ffffffffc0206878 <default_pmm_manager+0x360>
ffffffffc0203030:	00003617          	auipc	a2,0x3
ffffffffc0203034:	13860613          	addi	a2,a2,312 # ffffffffc0206168 <commands+0x818>
ffffffffc0203038:	23600593          	li	a1,566
ffffffffc020303c:	00003517          	auipc	a0,0x3
ffffffffc0203040:	62c50513          	addi	a0,a0,1580 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0203044:	c4afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203048:	00004697          	auipc	a3,0x4
ffffffffc020304c:	9a868693          	addi	a3,a3,-1624 # ffffffffc02069f0 <default_pmm_manager+0x4d8>
ffffffffc0203050:	00003617          	auipc	a2,0x3
ffffffffc0203054:	11860613          	addi	a2,a2,280 # ffffffffc0206168 <commands+0x818>
ffffffffc0203058:	23300593          	li	a1,563
ffffffffc020305c:	00003517          	auipc	a0,0x3
ffffffffc0203060:	60c50513          	addi	a0,a0,1548 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0203064:	c2afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203068:	00003697          	auipc	a3,0x3
ffffffffc020306c:	7f868693          	addi	a3,a3,2040 # ffffffffc0206860 <default_pmm_manager+0x348>
ffffffffc0203070:	00003617          	auipc	a2,0x3
ffffffffc0203074:	0f860613          	addi	a2,a2,248 # ffffffffc0206168 <commands+0x818>
ffffffffc0203078:	23200593          	li	a1,562
ffffffffc020307c:	00003517          	auipc	a0,0x3
ffffffffc0203080:	5ec50513          	addi	a0,a0,1516 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0203084:	c0afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203088:	00004697          	auipc	a3,0x4
ffffffffc020308c:	87868693          	addi	a3,a3,-1928 # ffffffffc0206900 <default_pmm_manager+0x3e8>
ffffffffc0203090:	00003617          	auipc	a2,0x3
ffffffffc0203094:	0d860613          	addi	a2,a2,216 # ffffffffc0206168 <commands+0x818>
ffffffffc0203098:	23100593          	li	a1,561
ffffffffc020309c:	00003517          	auipc	a0,0x3
ffffffffc02030a0:	5cc50513          	addi	a0,a0,1484 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc02030a4:	beafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02030a8:	00004697          	auipc	a3,0x4
ffffffffc02030ac:	93068693          	addi	a3,a3,-1744 # ffffffffc02069d8 <default_pmm_manager+0x4c0>
ffffffffc02030b0:	00003617          	auipc	a2,0x3
ffffffffc02030b4:	0b860613          	addi	a2,a2,184 # ffffffffc0206168 <commands+0x818>
ffffffffc02030b8:	23000593          	li	a1,560
ffffffffc02030bc:	00003517          	auipc	a0,0x3
ffffffffc02030c0:	5ac50513          	addi	a0,a0,1452 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc02030c4:	bcafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02030c8:	00004697          	auipc	a3,0x4
ffffffffc02030cc:	8f868693          	addi	a3,a3,-1800 # ffffffffc02069c0 <default_pmm_manager+0x4a8>
ffffffffc02030d0:	00003617          	auipc	a2,0x3
ffffffffc02030d4:	09860613          	addi	a2,a2,152 # ffffffffc0206168 <commands+0x818>
ffffffffc02030d8:	22f00593          	li	a1,559
ffffffffc02030dc:	00003517          	auipc	a0,0x3
ffffffffc02030e0:	58c50513          	addi	a0,a0,1420 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc02030e4:	baafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02030e8:	00004697          	auipc	a3,0x4
ffffffffc02030ec:	8a868693          	addi	a3,a3,-1880 # ffffffffc0206990 <default_pmm_manager+0x478>
ffffffffc02030f0:	00003617          	auipc	a2,0x3
ffffffffc02030f4:	07860613          	addi	a2,a2,120 # ffffffffc0206168 <commands+0x818>
ffffffffc02030f8:	22e00593          	li	a1,558
ffffffffc02030fc:	00003517          	auipc	a0,0x3
ffffffffc0203100:	56c50513          	addi	a0,a0,1388 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0203104:	b8afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203108:	00004697          	auipc	a3,0x4
ffffffffc020310c:	87068693          	addi	a3,a3,-1936 # ffffffffc0206978 <default_pmm_manager+0x460>
ffffffffc0203110:	00003617          	auipc	a2,0x3
ffffffffc0203114:	05860613          	addi	a2,a2,88 # ffffffffc0206168 <commands+0x818>
ffffffffc0203118:	22c00593          	li	a1,556
ffffffffc020311c:	00003517          	auipc	a0,0x3
ffffffffc0203120:	54c50513          	addi	a0,a0,1356 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0203124:	b6afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203128:	00004697          	auipc	a3,0x4
ffffffffc020312c:	83068693          	addi	a3,a3,-2000 # ffffffffc0206958 <default_pmm_manager+0x440>
ffffffffc0203130:	00003617          	auipc	a2,0x3
ffffffffc0203134:	03860613          	addi	a2,a2,56 # ffffffffc0206168 <commands+0x818>
ffffffffc0203138:	22b00593          	li	a1,555
ffffffffc020313c:	00003517          	auipc	a0,0x3
ffffffffc0203140:	52c50513          	addi	a0,a0,1324 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0203144:	b4afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203148:	00004697          	auipc	a3,0x4
ffffffffc020314c:	80068693          	addi	a3,a3,-2048 # ffffffffc0206948 <default_pmm_manager+0x430>
ffffffffc0203150:	00003617          	auipc	a2,0x3
ffffffffc0203154:	01860613          	addi	a2,a2,24 # ffffffffc0206168 <commands+0x818>
ffffffffc0203158:	22a00593          	li	a1,554
ffffffffc020315c:	00003517          	auipc	a0,0x3
ffffffffc0203160:	50c50513          	addi	a0,a0,1292 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0203164:	b2afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203168:	00003697          	auipc	a3,0x3
ffffffffc020316c:	7d068693          	addi	a3,a3,2000 # ffffffffc0206938 <default_pmm_manager+0x420>
ffffffffc0203170:	00003617          	auipc	a2,0x3
ffffffffc0203174:	ff860613          	addi	a2,a2,-8 # ffffffffc0206168 <commands+0x818>
ffffffffc0203178:	22900593          	li	a1,553
ffffffffc020317c:	00003517          	auipc	a0,0x3
ffffffffc0203180:	4ec50513          	addi	a0,a0,1260 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0203184:	b0afd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc0203188:	00003617          	auipc	a2,0x3
ffffffffc020318c:	55060613          	addi	a2,a2,1360 # ffffffffc02066d8 <default_pmm_manager+0x1c0>
ffffffffc0203190:	06500593          	li	a1,101
ffffffffc0203194:	00003517          	auipc	a0,0x3
ffffffffc0203198:	4d450513          	addi	a0,a0,1236 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc020319c:	af2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02031a0:	00004697          	auipc	a3,0x4
ffffffffc02031a4:	8b068693          	addi	a3,a3,-1872 # ffffffffc0206a50 <default_pmm_manager+0x538>
ffffffffc02031a8:	00003617          	auipc	a2,0x3
ffffffffc02031ac:	fc060613          	addi	a2,a2,-64 # ffffffffc0206168 <commands+0x818>
ffffffffc02031b0:	26f00593          	li	a1,623
ffffffffc02031b4:	00003517          	auipc	a0,0x3
ffffffffc02031b8:	4b450513          	addi	a0,a0,1204 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc02031bc:	ad2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02031c0:	00003697          	auipc	a3,0x3
ffffffffc02031c4:	74068693          	addi	a3,a3,1856 # ffffffffc0206900 <default_pmm_manager+0x3e8>
ffffffffc02031c8:	00003617          	auipc	a2,0x3
ffffffffc02031cc:	fa060613          	addi	a2,a2,-96 # ffffffffc0206168 <commands+0x818>
ffffffffc02031d0:	22800593          	li	a1,552
ffffffffc02031d4:	00003517          	auipc	a0,0x3
ffffffffc02031d8:	49450513          	addi	a0,a0,1172 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc02031dc:	ab2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02031e0:	00003697          	auipc	a3,0x3
ffffffffc02031e4:	6e068693          	addi	a3,a3,1760 # ffffffffc02068c0 <default_pmm_manager+0x3a8>
ffffffffc02031e8:	00003617          	auipc	a2,0x3
ffffffffc02031ec:	f8060613          	addi	a2,a2,-128 # ffffffffc0206168 <commands+0x818>
ffffffffc02031f0:	22700593          	li	a1,551
ffffffffc02031f4:	00003517          	auipc	a0,0x3
ffffffffc02031f8:	47450513          	addi	a0,a0,1140 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc02031fc:	a92fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203200:	86d6                	mv	a3,s5
ffffffffc0203202:	00003617          	auipc	a2,0x3
ffffffffc0203206:	34e60613          	addi	a2,a2,846 # ffffffffc0206550 <default_pmm_manager+0x38>
ffffffffc020320a:	22300593          	li	a1,547
ffffffffc020320e:	00003517          	auipc	a0,0x3
ffffffffc0203212:	45a50513          	addi	a0,a0,1114 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0203216:	a78fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020321a:	00003617          	auipc	a2,0x3
ffffffffc020321e:	33660613          	addi	a2,a2,822 # ffffffffc0206550 <default_pmm_manager+0x38>
ffffffffc0203222:	22200593          	li	a1,546
ffffffffc0203226:	00003517          	auipc	a0,0x3
ffffffffc020322a:	44250513          	addi	a0,a0,1090 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc020322e:	a60fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203232:	00003697          	auipc	a3,0x3
ffffffffc0203236:	64668693          	addi	a3,a3,1606 # ffffffffc0206878 <default_pmm_manager+0x360>
ffffffffc020323a:	00003617          	auipc	a2,0x3
ffffffffc020323e:	f2e60613          	addi	a2,a2,-210 # ffffffffc0206168 <commands+0x818>
ffffffffc0203242:	22000593          	li	a1,544
ffffffffc0203246:	00003517          	auipc	a0,0x3
ffffffffc020324a:	42250513          	addi	a0,a0,1058 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc020324e:	a40fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203252:	00003697          	auipc	a3,0x3
ffffffffc0203256:	60e68693          	addi	a3,a3,1550 # ffffffffc0206860 <default_pmm_manager+0x348>
ffffffffc020325a:	00003617          	auipc	a2,0x3
ffffffffc020325e:	f0e60613          	addi	a2,a2,-242 # ffffffffc0206168 <commands+0x818>
ffffffffc0203262:	21f00593          	li	a1,543
ffffffffc0203266:	00003517          	auipc	a0,0x3
ffffffffc020326a:	40250513          	addi	a0,a0,1026 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc020326e:	a20fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203272:	00004697          	auipc	a3,0x4
ffffffffc0203276:	99e68693          	addi	a3,a3,-1634 # ffffffffc0206c10 <default_pmm_manager+0x6f8>
ffffffffc020327a:	00003617          	auipc	a2,0x3
ffffffffc020327e:	eee60613          	addi	a2,a2,-274 # ffffffffc0206168 <commands+0x818>
ffffffffc0203282:	26600593          	li	a1,614
ffffffffc0203286:	00003517          	auipc	a0,0x3
ffffffffc020328a:	3e250513          	addi	a0,a0,994 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc020328e:	a00fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0203292:	00004697          	auipc	a3,0x4
ffffffffc0203296:	94668693          	addi	a3,a3,-1722 # ffffffffc0206bd8 <default_pmm_manager+0x6c0>
ffffffffc020329a:	00003617          	auipc	a2,0x3
ffffffffc020329e:	ece60613          	addi	a2,a2,-306 # ffffffffc0206168 <commands+0x818>
ffffffffc02032a2:	26300593          	li	a1,611
ffffffffc02032a6:	00003517          	auipc	a0,0x3
ffffffffc02032aa:	3c250513          	addi	a0,a0,962 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc02032ae:	9e0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc02032b2:	00004697          	auipc	a3,0x4
ffffffffc02032b6:	8f668693          	addi	a3,a3,-1802 # ffffffffc0206ba8 <default_pmm_manager+0x690>
ffffffffc02032ba:	00003617          	auipc	a2,0x3
ffffffffc02032be:	eae60613          	addi	a2,a2,-338 # ffffffffc0206168 <commands+0x818>
ffffffffc02032c2:	25f00593          	li	a1,607
ffffffffc02032c6:	00003517          	auipc	a0,0x3
ffffffffc02032ca:	3a250513          	addi	a0,a0,930 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc02032ce:	9c0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02032d2:	00004697          	auipc	a3,0x4
ffffffffc02032d6:	88e68693          	addi	a3,a3,-1906 # ffffffffc0206b60 <default_pmm_manager+0x648>
ffffffffc02032da:	00003617          	auipc	a2,0x3
ffffffffc02032de:	e8e60613          	addi	a2,a2,-370 # ffffffffc0206168 <commands+0x818>
ffffffffc02032e2:	25e00593          	li	a1,606
ffffffffc02032e6:	00003517          	auipc	a0,0x3
ffffffffc02032ea:	38250513          	addi	a0,a0,898 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc02032ee:	9a0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02032f2:	00003617          	auipc	a2,0x3
ffffffffc02032f6:	30660613          	addi	a2,a2,774 # ffffffffc02065f8 <default_pmm_manager+0xe0>
ffffffffc02032fa:	0c900593          	li	a1,201
ffffffffc02032fe:	00003517          	auipc	a0,0x3
ffffffffc0203302:	36a50513          	addi	a0,a0,874 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0203306:	988fd0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020330a:	00003617          	auipc	a2,0x3
ffffffffc020330e:	2ee60613          	addi	a2,a2,750 # ffffffffc02065f8 <default_pmm_manager+0xe0>
ffffffffc0203312:	08100593          	li	a1,129
ffffffffc0203316:	00003517          	auipc	a0,0x3
ffffffffc020331a:	35250513          	addi	a0,a0,850 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc020331e:	970fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0203322:	00003697          	auipc	a3,0x3
ffffffffc0203326:	50e68693          	addi	a3,a3,1294 # ffffffffc0206830 <default_pmm_manager+0x318>
ffffffffc020332a:	00003617          	auipc	a2,0x3
ffffffffc020332e:	e3e60613          	addi	a2,a2,-450 # ffffffffc0206168 <commands+0x818>
ffffffffc0203332:	21e00593          	li	a1,542
ffffffffc0203336:	00003517          	auipc	a0,0x3
ffffffffc020333a:	33250513          	addi	a0,a0,818 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc020333e:	950fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0203342:	00003697          	auipc	a3,0x3
ffffffffc0203346:	4be68693          	addi	a3,a3,1214 # ffffffffc0206800 <default_pmm_manager+0x2e8>
ffffffffc020334a:	00003617          	auipc	a2,0x3
ffffffffc020334e:	e1e60613          	addi	a2,a2,-482 # ffffffffc0206168 <commands+0x818>
ffffffffc0203352:	21b00593          	li	a1,539
ffffffffc0203356:	00003517          	auipc	a0,0x3
ffffffffc020335a:	31250513          	addi	a0,a0,786 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc020335e:	930fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203362 <copy_range>:
{
ffffffffc0203362:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203364:	00d667b3          	or	a5,a2,a3
{
ffffffffc0203368:	f486                	sd	ra,104(sp)
ffffffffc020336a:	f0a2                	sd	s0,96(sp)
ffffffffc020336c:	eca6                	sd	s1,88(sp)
ffffffffc020336e:	e8ca                	sd	s2,80(sp)
ffffffffc0203370:	e4ce                	sd	s3,72(sp)
ffffffffc0203372:	e0d2                	sd	s4,64(sp)
ffffffffc0203374:	fc56                	sd	s5,56(sp)
ffffffffc0203376:	f85a                	sd	s6,48(sp)
ffffffffc0203378:	f45e                	sd	s7,40(sp)
ffffffffc020337a:	f062                	sd	s8,32(sp)
ffffffffc020337c:	ec66                	sd	s9,24(sp)
ffffffffc020337e:	e86a                	sd	s10,16(sp)
ffffffffc0203380:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203382:	17d2                	slli	a5,a5,0x34
ffffffffc0203384:	20079f63          	bnez	a5,ffffffffc02035a2 <copy_range+0x240>
    assert(USER_ACCESS(start, end));
ffffffffc0203388:	002007b7          	lui	a5,0x200
ffffffffc020338c:	8432                	mv	s0,a2
ffffffffc020338e:	1af66263          	bltu	a2,a5,ffffffffc0203532 <copy_range+0x1d0>
ffffffffc0203392:	8936                	mv	s2,a3
ffffffffc0203394:	18d67f63          	bgeu	a2,a3,ffffffffc0203532 <copy_range+0x1d0>
ffffffffc0203398:	4785                	li	a5,1
ffffffffc020339a:	07fe                	slli	a5,a5,0x1f
ffffffffc020339c:	18d7eb63          	bltu	a5,a3,ffffffffc0203532 <copy_range+0x1d0>
ffffffffc02033a0:	5b7d                	li	s6,-1
ffffffffc02033a2:	8aaa                	mv	s5,a0
ffffffffc02033a4:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc02033a6:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02033a8:	000a7c17          	auipc	s8,0xa7
ffffffffc02033ac:	350c0c13          	addi	s8,s8,848 # ffffffffc02aa6f8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02033b0:	000a7b97          	auipc	s7,0xa7
ffffffffc02033b4:	350b8b93          	addi	s7,s7,848 # ffffffffc02aa700 <pages>
    return KADDR(page2pa(page));
ffffffffc02033b8:	00cb5b13          	srli	s6,s6,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc02033bc:	000a7c97          	auipc	s9,0xa7
ffffffffc02033c0:	34cc8c93          	addi	s9,s9,844 # ffffffffc02aa708 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc02033c4:	4601                	li	a2,0
ffffffffc02033c6:	85a2                	mv	a1,s0
ffffffffc02033c8:	854e                	mv	a0,s3
ffffffffc02033ca:	b73fe0ef          	jal	ra,ffffffffc0201f3c <get_pte>
ffffffffc02033ce:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02033d0:	0e050c63          	beqz	a0,ffffffffc02034c8 <copy_range+0x166>
        if (*ptep & PTE_V)
ffffffffc02033d4:	611c                	ld	a5,0(a0)
ffffffffc02033d6:	8b85                	andi	a5,a5,1
ffffffffc02033d8:	e785                	bnez	a5,ffffffffc0203400 <copy_range+0x9e>
        start += PGSIZE;
ffffffffc02033da:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02033dc:	ff2464e3          	bltu	s0,s2,ffffffffc02033c4 <copy_range+0x62>
    return 0;
ffffffffc02033e0:	4501                	li	a0,0
}
ffffffffc02033e2:	70a6                	ld	ra,104(sp)
ffffffffc02033e4:	7406                	ld	s0,96(sp)
ffffffffc02033e6:	64e6                	ld	s1,88(sp)
ffffffffc02033e8:	6946                	ld	s2,80(sp)
ffffffffc02033ea:	69a6                	ld	s3,72(sp)
ffffffffc02033ec:	6a06                	ld	s4,64(sp)
ffffffffc02033ee:	7ae2                	ld	s5,56(sp)
ffffffffc02033f0:	7b42                	ld	s6,48(sp)
ffffffffc02033f2:	7ba2                	ld	s7,40(sp)
ffffffffc02033f4:	7c02                	ld	s8,32(sp)
ffffffffc02033f6:	6ce2                	ld	s9,24(sp)
ffffffffc02033f8:	6d42                	ld	s10,16(sp)
ffffffffc02033fa:	6da2                	ld	s11,8(sp)
ffffffffc02033fc:	6165                	addi	sp,sp,112
ffffffffc02033fe:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc0203400:	4605                	li	a2,1
ffffffffc0203402:	85a2                	mv	a1,s0
ffffffffc0203404:	8556                	mv	a0,s5
ffffffffc0203406:	b37fe0ef          	jal	ra,ffffffffc0201f3c <get_pte>
ffffffffc020340a:	c56d                	beqz	a0,ffffffffc02034f4 <copy_range+0x192>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc020340c:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V))
ffffffffc020340e:	0017f713          	andi	a4,a5,1
ffffffffc0203412:	01f7f493          	andi	s1,a5,31
ffffffffc0203416:	16070a63          	beqz	a4,ffffffffc020358a <copy_range+0x228>
    if (PPN(pa) >= npage)
ffffffffc020341a:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc020341e:	078a                	slli	a5,a5,0x2
ffffffffc0203420:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0203424:	14d77763          	bgeu	a4,a3,ffffffffc0203572 <copy_range+0x210>
    return &pages[PPN(pa) - nbase];
ffffffffc0203428:	000bb783          	ld	a5,0(s7)
ffffffffc020342c:	fff806b7          	lui	a3,0xfff80
ffffffffc0203430:	9736                	add	a4,a4,a3
ffffffffc0203432:	071a                	slli	a4,a4,0x6
ffffffffc0203434:	00e78db3          	add	s11,a5,a4
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203438:	10002773          	csrr	a4,sstatus
ffffffffc020343c:	8b09                	andi	a4,a4,2
ffffffffc020343e:	e345                	bnez	a4,ffffffffc02034de <copy_range+0x17c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203440:	000cb703          	ld	a4,0(s9)
ffffffffc0203444:	4505                	li	a0,1
ffffffffc0203446:	6f18                	ld	a4,24(a4)
ffffffffc0203448:	9702                	jalr	a4
ffffffffc020344a:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc020344c:	0c0d8363          	beqz	s11,ffffffffc0203512 <copy_range+0x1b0>
            assert(npage != NULL);
ffffffffc0203450:	100d0163          	beqz	s10,ffffffffc0203552 <copy_range+0x1f0>
    return page - pages + nbase;
ffffffffc0203454:	000bb703          	ld	a4,0(s7)
ffffffffc0203458:	000805b7          	lui	a1,0x80
    return KADDR(page2pa(page));
ffffffffc020345c:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0203460:	40ed86b3          	sub	a3,s11,a4
ffffffffc0203464:	8699                	srai	a3,a3,0x6
ffffffffc0203466:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0203468:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc020346c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020346e:	08c7f663          	bgeu	a5,a2,ffffffffc02034fa <copy_range+0x198>
    return page - pages + nbase;
ffffffffc0203472:	40ed07b3          	sub	a5,s10,a4
    return KADDR(page2pa(page));
ffffffffc0203476:	000a7717          	auipc	a4,0xa7
ffffffffc020347a:	29a70713          	addi	a4,a4,666 # ffffffffc02aa710 <va_pa_offset>
ffffffffc020347e:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc0203480:	8799                	srai	a5,a5,0x6
ffffffffc0203482:	97ae                	add	a5,a5,a1
    return KADDR(page2pa(page));
ffffffffc0203484:	0167f733          	and	a4,a5,s6
ffffffffc0203488:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc020348c:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc020348e:	06c77563          	bgeu	a4,a2,ffffffffc02034f8 <copy_range+0x196>
            memcpy(kva_dst, kva_src, PGSIZE);
ffffffffc0203492:	6605                	lui	a2,0x1
ffffffffc0203494:	953e                	add	a0,a0,a5
ffffffffc0203496:	236020ef          	jal	ra,ffffffffc02056cc <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc020349a:	86a6                	mv	a3,s1
ffffffffc020349c:	8622                	mv	a2,s0
ffffffffc020349e:	85ea                	mv	a1,s10
ffffffffc02034a0:	8556                	mv	a0,s5
ffffffffc02034a2:	98aff0ef          	jal	ra,ffffffffc020262c <page_insert>
            assert(ret == 0);
ffffffffc02034a6:	d915                	beqz	a0,ffffffffc02033da <copy_range+0x78>
ffffffffc02034a8:	00003697          	auipc	a3,0x3
ffffffffc02034ac:	7d068693          	addi	a3,a3,2000 # ffffffffc0206c78 <default_pmm_manager+0x760>
ffffffffc02034b0:	00003617          	auipc	a2,0x3
ffffffffc02034b4:	cb860613          	addi	a2,a2,-840 # ffffffffc0206168 <commands+0x818>
ffffffffc02034b8:	1b300593          	li	a1,435
ffffffffc02034bc:	00003517          	auipc	a0,0x3
ffffffffc02034c0:	1ac50513          	addi	a0,a0,428 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc02034c4:	fcbfc0ef          	jal	ra,ffffffffc020048e <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02034c8:	00200637          	lui	a2,0x200
ffffffffc02034cc:	9432                	add	s0,s0,a2
ffffffffc02034ce:	ffe00637          	lui	a2,0xffe00
ffffffffc02034d2:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);
ffffffffc02034d4:	f00406e3          	beqz	s0,ffffffffc02033e0 <copy_range+0x7e>
ffffffffc02034d8:	ef2466e3          	bltu	s0,s2,ffffffffc02033c4 <copy_range+0x62>
ffffffffc02034dc:	b711                	j	ffffffffc02033e0 <copy_range+0x7e>
        intr_disable();
ffffffffc02034de:	cd6fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02034e2:	000cb703          	ld	a4,0(s9)
ffffffffc02034e6:	4505                	li	a0,1
ffffffffc02034e8:	6f18                	ld	a4,24(a4)
ffffffffc02034ea:	9702                	jalr	a4
ffffffffc02034ec:	8d2a                	mv	s10,a0
        intr_enable();
ffffffffc02034ee:	cc0fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02034f2:	bfa9                	j	ffffffffc020344c <copy_range+0xea>
                return -E_NO_MEM;
ffffffffc02034f4:	5571                	li	a0,-4
ffffffffc02034f6:	b5f5                	j	ffffffffc02033e2 <copy_range+0x80>
ffffffffc02034f8:	86be                	mv	a3,a5
ffffffffc02034fa:	00003617          	auipc	a2,0x3
ffffffffc02034fe:	05660613          	addi	a2,a2,86 # ffffffffc0206550 <default_pmm_manager+0x38>
ffffffffc0203502:	07100593          	li	a1,113
ffffffffc0203506:	00003517          	auipc	a0,0x3
ffffffffc020350a:	07250513          	addi	a0,a0,114 # ffffffffc0206578 <default_pmm_manager+0x60>
ffffffffc020350e:	f81fc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(page != NULL);
ffffffffc0203512:	00003697          	auipc	a3,0x3
ffffffffc0203516:	74668693          	addi	a3,a3,1862 # ffffffffc0206c58 <default_pmm_manager+0x740>
ffffffffc020351a:	00003617          	auipc	a2,0x3
ffffffffc020351e:	c4e60613          	addi	a2,a2,-946 # ffffffffc0206168 <commands+0x818>
ffffffffc0203522:	19400593          	li	a1,404
ffffffffc0203526:	00003517          	auipc	a0,0x3
ffffffffc020352a:	14250513          	addi	a0,a0,322 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc020352e:	f61fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203532:	00003697          	auipc	a3,0x3
ffffffffc0203536:	17668693          	addi	a3,a3,374 # ffffffffc02066a8 <default_pmm_manager+0x190>
ffffffffc020353a:	00003617          	auipc	a2,0x3
ffffffffc020353e:	c2e60613          	addi	a2,a2,-978 # ffffffffc0206168 <commands+0x818>
ffffffffc0203542:	17c00593          	li	a1,380
ffffffffc0203546:	00003517          	auipc	a0,0x3
ffffffffc020354a:	12250513          	addi	a0,a0,290 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc020354e:	f41fc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(npage != NULL);
ffffffffc0203552:	00003697          	auipc	a3,0x3
ffffffffc0203556:	71668693          	addi	a3,a3,1814 # ffffffffc0206c68 <default_pmm_manager+0x750>
ffffffffc020355a:	00003617          	auipc	a2,0x3
ffffffffc020355e:	c0e60613          	addi	a2,a2,-1010 # ffffffffc0206168 <commands+0x818>
ffffffffc0203562:	19500593          	li	a1,405
ffffffffc0203566:	00003517          	auipc	a0,0x3
ffffffffc020356a:	10250513          	addi	a0,a0,258 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc020356e:	f21fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203572:	00003617          	auipc	a2,0x3
ffffffffc0203576:	0ae60613          	addi	a2,a2,174 # ffffffffc0206620 <default_pmm_manager+0x108>
ffffffffc020357a:	06900593          	li	a1,105
ffffffffc020357e:	00003517          	auipc	a0,0x3
ffffffffc0203582:	ffa50513          	addi	a0,a0,-6 # ffffffffc0206578 <default_pmm_manager+0x60>
ffffffffc0203586:	f09fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pte2page called with invalid pte");
ffffffffc020358a:	00003617          	auipc	a2,0x3
ffffffffc020358e:	0b660613          	addi	a2,a2,182 # ffffffffc0206640 <default_pmm_manager+0x128>
ffffffffc0203592:	07f00593          	li	a1,127
ffffffffc0203596:	00003517          	auipc	a0,0x3
ffffffffc020359a:	fe250513          	addi	a0,a0,-30 # ffffffffc0206578 <default_pmm_manager+0x60>
ffffffffc020359e:	ef1fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02035a2:	00003697          	auipc	a3,0x3
ffffffffc02035a6:	0d668693          	addi	a3,a3,214 # ffffffffc0206678 <default_pmm_manager+0x160>
ffffffffc02035aa:	00003617          	auipc	a2,0x3
ffffffffc02035ae:	bbe60613          	addi	a2,a2,-1090 # ffffffffc0206168 <commands+0x818>
ffffffffc02035b2:	17b00593          	li	a1,379
ffffffffc02035b6:	00003517          	auipc	a0,0x3
ffffffffc02035ba:	0b250513          	addi	a0,a0,178 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc02035be:	ed1fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02035c2 <pgdir_alloc_page>:
{
ffffffffc02035c2:	7179                	addi	sp,sp,-48
ffffffffc02035c4:	ec26                	sd	s1,24(sp)
ffffffffc02035c6:	e84a                	sd	s2,16(sp)
ffffffffc02035c8:	e052                	sd	s4,0(sp)
ffffffffc02035ca:	f406                	sd	ra,40(sp)
ffffffffc02035cc:	f022                	sd	s0,32(sp)
ffffffffc02035ce:	e44e                	sd	s3,8(sp)
ffffffffc02035d0:	8a2a                	mv	s4,a0
ffffffffc02035d2:	84ae                	mv	s1,a1
ffffffffc02035d4:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02035d6:	100027f3          	csrr	a5,sstatus
ffffffffc02035da:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc02035dc:	000a7997          	auipc	s3,0xa7
ffffffffc02035e0:	12c98993          	addi	s3,s3,300 # ffffffffc02aa708 <pmm_manager>
ffffffffc02035e4:	ef8d                	bnez	a5,ffffffffc020361e <pgdir_alloc_page+0x5c>
ffffffffc02035e6:	0009b783          	ld	a5,0(s3)
ffffffffc02035ea:	4505                	li	a0,1
ffffffffc02035ec:	6f9c                	ld	a5,24(a5)
ffffffffc02035ee:	9782                	jalr	a5
ffffffffc02035f0:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc02035f2:	cc09                	beqz	s0,ffffffffc020360c <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02035f4:	86ca                	mv	a3,s2
ffffffffc02035f6:	8626                	mv	a2,s1
ffffffffc02035f8:	85a2                	mv	a1,s0
ffffffffc02035fa:	8552                	mv	a0,s4
ffffffffc02035fc:	830ff0ef          	jal	ra,ffffffffc020262c <page_insert>
ffffffffc0203600:	e915                	bnez	a0,ffffffffc0203634 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc0203602:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc0203604:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc0203606:	4785                	li	a5,1
ffffffffc0203608:	04f71e63          	bne	a4,a5,ffffffffc0203664 <pgdir_alloc_page+0xa2>
}
ffffffffc020360c:	70a2                	ld	ra,40(sp)
ffffffffc020360e:	8522                	mv	a0,s0
ffffffffc0203610:	7402                	ld	s0,32(sp)
ffffffffc0203612:	64e2                	ld	s1,24(sp)
ffffffffc0203614:	6942                	ld	s2,16(sp)
ffffffffc0203616:	69a2                	ld	s3,8(sp)
ffffffffc0203618:	6a02                	ld	s4,0(sp)
ffffffffc020361a:	6145                	addi	sp,sp,48
ffffffffc020361c:	8082                	ret
        intr_disable();
ffffffffc020361e:	b96fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203622:	0009b783          	ld	a5,0(s3)
ffffffffc0203626:	4505                	li	a0,1
ffffffffc0203628:	6f9c                	ld	a5,24(a5)
ffffffffc020362a:	9782                	jalr	a5
ffffffffc020362c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020362e:	b80fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203632:	b7c1                	j	ffffffffc02035f2 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203634:	100027f3          	csrr	a5,sstatus
ffffffffc0203638:	8b89                	andi	a5,a5,2
ffffffffc020363a:	eb89                	bnez	a5,ffffffffc020364c <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc020363c:	0009b783          	ld	a5,0(s3)
ffffffffc0203640:	8522                	mv	a0,s0
ffffffffc0203642:	4585                	li	a1,1
ffffffffc0203644:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203646:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203648:	9782                	jalr	a5
    if (flag)
ffffffffc020364a:	b7c9                	j	ffffffffc020360c <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc020364c:	b68fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203650:	0009b783          	ld	a5,0(s3)
ffffffffc0203654:	8522                	mv	a0,s0
ffffffffc0203656:	4585                	li	a1,1
ffffffffc0203658:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020365a:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020365c:	9782                	jalr	a5
        intr_enable();
ffffffffc020365e:	b50fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203662:	b76d                	j	ffffffffc020360c <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc0203664:	00003697          	auipc	a3,0x3
ffffffffc0203668:	62468693          	addi	a3,a3,1572 # ffffffffc0206c88 <default_pmm_manager+0x770>
ffffffffc020366c:	00003617          	auipc	a2,0x3
ffffffffc0203670:	afc60613          	addi	a2,a2,-1284 # ffffffffc0206168 <commands+0x818>
ffffffffc0203674:	1fc00593          	li	a1,508
ffffffffc0203678:	00003517          	auipc	a0,0x3
ffffffffc020367c:	ff050513          	addi	a0,a0,-16 # ffffffffc0206668 <default_pmm_manager+0x150>
ffffffffc0203680:	e0ffc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203684 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203684:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203686:	00003697          	auipc	a3,0x3
ffffffffc020368a:	61a68693          	addi	a3,a3,1562 # ffffffffc0206ca0 <default_pmm_manager+0x788>
ffffffffc020368e:	00003617          	auipc	a2,0x3
ffffffffc0203692:	ada60613          	addi	a2,a2,-1318 # ffffffffc0206168 <commands+0x818>
ffffffffc0203696:	07400593          	li	a1,116
ffffffffc020369a:	00003517          	auipc	a0,0x3
ffffffffc020369e:	62650513          	addi	a0,a0,1574 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02036a2:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02036a4:	debfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02036a8 <mm_create>:
{
ffffffffc02036a8:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036aa:	04000513          	li	a0,64
{
ffffffffc02036ae:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036b0:	df6fe0ef          	jal	ra,ffffffffc0201ca6 <kmalloc>
    if (mm != NULL)
ffffffffc02036b4:	cd19                	beqz	a0,ffffffffc02036d2 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc02036b6:	e508                	sd	a0,8(a0)
ffffffffc02036b8:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02036ba:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02036be:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02036c2:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02036c6:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02036ca:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02036ce:	02053c23          	sd	zero,56(a0)
}
ffffffffc02036d2:	60a2                	ld	ra,8(sp)
ffffffffc02036d4:	0141                	addi	sp,sp,16
ffffffffc02036d6:	8082                	ret

ffffffffc02036d8 <find_vma>:
{
ffffffffc02036d8:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc02036da:	c505                	beqz	a0,ffffffffc0203702 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02036dc:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02036de:	c501                	beqz	a0,ffffffffc02036e6 <find_vma+0xe>
ffffffffc02036e0:	651c                	ld	a5,8(a0)
ffffffffc02036e2:	02f5f263          	bgeu	a1,a5,ffffffffc0203706 <find_vma+0x2e>
    return listelm->next;
ffffffffc02036e6:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc02036e8:	00f68d63          	beq	a3,a5,ffffffffc0203702 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02036ec:	fe87b703          	ld	a4,-24(a5) # 1fffe8 <_binary_obj___user_exit_out_size+0x1f4ec8>
ffffffffc02036f0:	00e5e663          	bltu	a1,a4,ffffffffc02036fc <find_vma+0x24>
ffffffffc02036f4:	ff07b703          	ld	a4,-16(a5)
ffffffffc02036f8:	00e5ec63          	bltu	a1,a4,ffffffffc0203710 <find_vma+0x38>
ffffffffc02036fc:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc02036fe:	fef697e3          	bne	a3,a5,ffffffffc02036ec <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0203702:	4501                	li	a0,0
}
ffffffffc0203704:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203706:	691c                	ld	a5,16(a0)
ffffffffc0203708:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02036e6 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc020370c:	ea88                	sd	a0,16(a3)
ffffffffc020370e:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0203710:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203714:	ea88                	sd	a0,16(a3)
ffffffffc0203716:	8082                	ret

ffffffffc0203718 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203718:	6590                	ld	a2,8(a1)
ffffffffc020371a:	0105b803          	ld	a6,16(a1) # 80010 <_binary_obj___user_exit_out_size+0x74ef0>
{
ffffffffc020371e:	1141                	addi	sp,sp,-16
ffffffffc0203720:	e406                	sd	ra,8(sp)
ffffffffc0203722:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203724:	01066763          	bltu	a2,a6,ffffffffc0203732 <insert_vma_struct+0x1a>
ffffffffc0203728:	a085                	j	ffffffffc0203788 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020372a:	fe87b703          	ld	a4,-24(a5)
ffffffffc020372e:	04e66863          	bltu	a2,a4,ffffffffc020377e <insert_vma_struct+0x66>
ffffffffc0203732:	86be                	mv	a3,a5
ffffffffc0203734:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0203736:	fef51ae3          	bne	a0,a5,ffffffffc020372a <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc020373a:	02a68463          	beq	a3,a0,ffffffffc0203762 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc020373e:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203742:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203746:	08e8f163          	bgeu	a7,a4,ffffffffc02037c8 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020374a:	04e66f63          	bltu	a2,a4,ffffffffc02037a8 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc020374e:	00f50a63          	beq	a0,a5,ffffffffc0203762 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203752:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203756:	05076963          	bltu	a4,a6,ffffffffc02037a8 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc020375a:	ff07b603          	ld	a2,-16(a5)
ffffffffc020375e:	02c77363          	bgeu	a4,a2,ffffffffc0203784 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203762:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203764:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203766:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc020376a:	e390                	sd	a2,0(a5)
ffffffffc020376c:	e690                	sd	a2,8(a3)
}
ffffffffc020376e:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203770:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203772:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203774:	0017079b          	addiw	a5,a4,1
ffffffffc0203778:	d11c                	sw	a5,32(a0)
}
ffffffffc020377a:	0141                	addi	sp,sp,16
ffffffffc020377c:	8082                	ret
    if (le_prev != list)
ffffffffc020377e:	fca690e3          	bne	a3,a0,ffffffffc020373e <insert_vma_struct+0x26>
ffffffffc0203782:	bfd1                	j	ffffffffc0203756 <insert_vma_struct+0x3e>
ffffffffc0203784:	f01ff0ef          	jal	ra,ffffffffc0203684 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203788:	00003697          	auipc	a3,0x3
ffffffffc020378c:	54868693          	addi	a3,a3,1352 # ffffffffc0206cd0 <default_pmm_manager+0x7b8>
ffffffffc0203790:	00003617          	auipc	a2,0x3
ffffffffc0203794:	9d860613          	addi	a2,a2,-1576 # ffffffffc0206168 <commands+0x818>
ffffffffc0203798:	07a00593          	li	a1,122
ffffffffc020379c:	00003517          	auipc	a0,0x3
ffffffffc02037a0:	52450513          	addi	a0,a0,1316 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc02037a4:	cebfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02037a8:	00003697          	auipc	a3,0x3
ffffffffc02037ac:	56868693          	addi	a3,a3,1384 # ffffffffc0206d10 <default_pmm_manager+0x7f8>
ffffffffc02037b0:	00003617          	auipc	a2,0x3
ffffffffc02037b4:	9b860613          	addi	a2,a2,-1608 # ffffffffc0206168 <commands+0x818>
ffffffffc02037b8:	07300593          	li	a1,115
ffffffffc02037bc:	00003517          	auipc	a0,0x3
ffffffffc02037c0:	50450513          	addi	a0,a0,1284 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc02037c4:	ccbfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02037c8:	00003697          	auipc	a3,0x3
ffffffffc02037cc:	52868693          	addi	a3,a3,1320 # ffffffffc0206cf0 <default_pmm_manager+0x7d8>
ffffffffc02037d0:	00003617          	auipc	a2,0x3
ffffffffc02037d4:	99860613          	addi	a2,a2,-1640 # ffffffffc0206168 <commands+0x818>
ffffffffc02037d8:	07200593          	li	a1,114
ffffffffc02037dc:	00003517          	auipc	a0,0x3
ffffffffc02037e0:	4e450513          	addi	a0,a0,1252 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc02037e4:	cabfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02037e8 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02037e8:	591c                	lw	a5,48(a0)
{
ffffffffc02037ea:	1141                	addi	sp,sp,-16
ffffffffc02037ec:	e406                	sd	ra,8(sp)
ffffffffc02037ee:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02037f0:	e78d                	bnez	a5,ffffffffc020381a <mm_destroy+0x32>
ffffffffc02037f2:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02037f4:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02037f6:	00a40c63          	beq	s0,a0,ffffffffc020380e <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02037fa:	6118                	ld	a4,0(a0)
ffffffffc02037fc:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02037fe:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203800:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203802:	e398                	sd	a4,0(a5)
ffffffffc0203804:	d52fe0ef          	jal	ra,ffffffffc0201d56 <kfree>
    return listelm->next;
ffffffffc0203808:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc020380a:	fea418e3          	bne	s0,a0,ffffffffc02037fa <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc020380e:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203810:	6402                	ld	s0,0(sp)
ffffffffc0203812:	60a2                	ld	ra,8(sp)
ffffffffc0203814:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0203816:	d40fe06f          	j	ffffffffc0201d56 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc020381a:	00003697          	auipc	a3,0x3
ffffffffc020381e:	51668693          	addi	a3,a3,1302 # ffffffffc0206d30 <default_pmm_manager+0x818>
ffffffffc0203822:	00003617          	auipc	a2,0x3
ffffffffc0203826:	94660613          	addi	a2,a2,-1722 # ffffffffc0206168 <commands+0x818>
ffffffffc020382a:	09e00593          	li	a1,158
ffffffffc020382e:	00003517          	auipc	a0,0x3
ffffffffc0203832:	49250513          	addi	a0,a0,1170 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc0203836:	c59fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020383a <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc020383a:	7139                	addi	sp,sp,-64
ffffffffc020383c:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020383e:	6405                	lui	s0,0x1
ffffffffc0203840:	147d                	addi	s0,s0,-1
ffffffffc0203842:	77fd                	lui	a5,0xfffff
ffffffffc0203844:	9622                	add	a2,a2,s0
ffffffffc0203846:	962e                	add	a2,a2,a1
{
ffffffffc0203848:	f426                	sd	s1,40(sp)
ffffffffc020384a:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020384c:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203850:	f04a                	sd	s2,32(sp)
ffffffffc0203852:	ec4e                	sd	s3,24(sp)
ffffffffc0203854:	e852                	sd	s4,16(sp)
ffffffffc0203856:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203858:	002005b7          	lui	a1,0x200
ffffffffc020385c:	00f67433          	and	s0,a2,a5
ffffffffc0203860:	06b4e363          	bltu	s1,a1,ffffffffc02038c6 <mm_map+0x8c>
ffffffffc0203864:	0684f163          	bgeu	s1,s0,ffffffffc02038c6 <mm_map+0x8c>
ffffffffc0203868:	4785                	li	a5,1
ffffffffc020386a:	07fe                	slli	a5,a5,0x1f
ffffffffc020386c:	0487ed63          	bltu	a5,s0,ffffffffc02038c6 <mm_map+0x8c>
ffffffffc0203870:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203872:	cd21                	beqz	a0,ffffffffc02038ca <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203874:	85a6                	mv	a1,s1
ffffffffc0203876:	8ab6                	mv	s5,a3
ffffffffc0203878:	8a3a                	mv	s4,a4
ffffffffc020387a:	e5fff0ef          	jal	ra,ffffffffc02036d8 <find_vma>
ffffffffc020387e:	c501                	beqz	a0,ffffffffc0203886 <mm_map+0x4c>
ffffffffc0203880:	651c                	ld	a5,8(a0)
ffffffffc0203882:	0487e263          	bltu	a5,s0,ffffffffc02038c6 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203886:	03000513          	li	a0,48
ffffffffc020388a:	c1cfe0ef          	jal	ra,ffffffffc0201ca6 <kmalloc>
ffffffffc020388e:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203890:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203892:	02090163          	beqz	s2,ffffffffc02038b4 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203896:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0203898:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc020389c:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc02038a0:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc02038a4:	85ca                	mv	a1,s2
ffffffffc02038a6:	e73ff0ef          	jal	ra,ffffffffc0203718 <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc02038aa:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc02038ac:	000a0463          	beqz	s4,ffffffffc02038b4 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc02038b0:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>

out:
    return ret;
}
ffffffffc02038b4:	70e2                	ld	ra,56(sp)
ffffffffc02038b6:	7442                	ld	s0,48(sp)
ffffffffc02038b8:	74a2                	ld	s1,40(sp)
ffffffffc02038ba:	7902                	ld	s2,32(sp)
ffffffffc02038bc:	69e2                	ld	s3,24(sp)
ffffffffc02038be:	6a42                	ld	s4,16(sp)
ffffffffc02038c0:	6aa2                	ld	s5,8(sp)
ffffffffc02038c2:	6121                	addi	sp,sp,64
ffffffffc02038c4:	8082                	ret
        return -E_INVAL;
ffffffffc02038c6:	5575                	li	a0,-3
ffffffffc02038c8:	b7f5                	j	ffffffffc02038b4 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02038ca:	00003697          	auipc	a3,0x3
ffffffffc02038ce:	47e68693          	addi	a3,a3,1150 # ffffffffc0206d48 <default_pmm_manager+0x830>
ffffffffc02038d2:	00003617          	auipc	a2,0x3
ffffffffc02038d6:	89660613          	addi	a2,a2,-1898 # ffffffffc0206168 <commands+0x818>
ffffffffc02038da:	0b300593          	li	a1,179
ffffffffc02038de:	00003517          	auipc	a0,0x3
ffffffffc02038e2:	3e250513          	addi	a0,a0,994 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc02038e6:	ba9fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02038ea <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02038ea:	7139                	addi	sp,sp,-64
ffffffffc02038ec:	fc06                	sd	ra,56(sp)
ffffffffc02038ee:	f822                	sd	s0,48(sp)
ffffffffc02038f0:	f426                	sd	s1,40(sp)
ffffffffc02038f2:	f04a                	sd	s2,32(sp)
ffffffffc02038f4:	ec4e                	sd	s3,24(sp)
ffffffffc02038f6:	e852                	sd	s4,16(sp)
ffffffffc02038f8:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02038fa:	c52d                	beqz	a0,ffffffffc0203964 <dup_mmap+0x7a>
ffffffffc02038fc:	892a                	mv	s2,a0
ffffffffc02038fe:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203900:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203902:	e595                	bnez	a1,ffffffffc020392e <dup_mmap+0x44>
ffffffffc0203904:	a085                	j	ffffffffc0203964 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203906:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0203908:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ee8>
        vma->vm_end = vm_end;
ffffffffc020390c:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203910:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0203914:	e05ff0ef          	jal	ra,ffffffffc0203718 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203918:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc020391c:	fe843603          	ld	a2,-24(s0)
ffffffffc0203920:	6c8c                	ld	a1,24(s1)
ffffffffc0203922:	01893503          	ld	a0,24(s2)
ffffffffc0203926:	4701                	li	a4,0
ffffffffc0203928:	a3bff0ef          	jal	ra,ffffffffc0203362 <copy_range>
ffffffffc020392c:	e105                	bnez	a0,ffffffffc020394c <dup_mmap+0x62>
    return listelm->prev;
ffffffffc020392e:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203930:	02848863          	beq	s1,s0,ffffffffc0203960 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203934:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203938:	fe843a83          	ld	s5,-24(s0)
ffffffffc020393c:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203940:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203944:	b62fe0ef          	jal	ra,ffffffffc0201ca6 <kmalloc>
ffffffffc0203948:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc020394a:	fd55                	bnez	a0,ffffffffc0203906 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc020394c:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc020394e:	70e2                	ld	ra,56(sp)
ffffffffc0203950:	7442                	ld	s0,48(sp)
ffffffffc0203952:	74a2                	ld	s1,40(sp)
ffffffffc0203954:	7902                	ld	s2,32(sp)
ffffffffc0203956:	69e2                	ld	s3,24(sp)
ffffffffc0203958:	6a42                	ld	s4,16(sp)
ffffffffc020395a:	6aa2                	ld	s5,8(sp)
ffffffffc020395c:	6121                	addi	sp,sp,64
ffffffffc020395e:	8082                	ret
    return 0;
ffffffffc0203960:	4501                	li	a0,0
ffffffffc0203962:	b7f5                	j	ffffffffc020394e <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203964:	00003697          	auipc	a3,0x3
ffffffffc0203968:	3f468693          	addi	a3,a3,1012 # ffffffffc0206d58 <default_pmm_manager+0x840>
ffffffffc020396c:	00002617          	auipc	a2,0x2
ffffffffc0203970:	7fc60613          	addi	a2,a2,2044 # ffffffffc0206168 <commands+0x818>
ffffffffc0203974:	0cf00593          	li	a1,207
ffffffffc0203978:	00003517          	auipc	a0,0x3
ffffffffc020397c:	34850513          	addi	a0,a0,840 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc0203980:	b0ffc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203984 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203984:	1101                	addi	sp,sp,-32
ffffffffc0203986:	ec06                	sd	ra,24(sp)
ffffffffc0203988:	e822                	sd	s0,16(sp)
ffffffffc020398a:	e426                	sd	s1,8(sp)
ffffffffc020398c:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc020398e:	c531                	beqz	a0,ffffffffc02039da <exit_mmap+0x56>
ffffffffc0203990:	591c                	lw	a5,48(a0)
ffffffffc0203992:	84aa                	mv	s1,a0
ffffffffc0203994:	e3b9                	bnez	a5,ffffffffc02039da <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203996:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203998:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc020399c:	02850663          	beq	a0,s0,ffffffffc02039c8 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02039a0:	ff043603          	ld	a2,-16(s0)
ffffffffc02039a4:	fe843583          	ld	a1,-24(s0)
ffffffffc02039a8:	854a                	mv	a0,s2
ffffffffc02039aa:	80ffe0ef          	jal	ra,ffffffffc02021b8 <unmap_range>
ffffffffc02039ae:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02039b0:	fe8498e3          	bne	s1,s0,ffffffffc02039a0 <exit_mmap+0x1c>
ffffffffc02039b4:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc02039b6:	00848c63          	beq	s1,s0,ffffffffc02039ce <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02039ba:	ff043603          	ld	a2,-16(s0)
ffffffffc02039be:	fe843583          	ld	a1,-24(s0)
ffffffffc02039c2:	854a                	mv	a0,s2
ffffffffc02039c4:	93bfe0ef          	jal	ra,ffffffffc02022fe <exit_range>
ffffffffc02039c8:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02039ca:	fe8498e3          	bne	s1,s0,ffffffffc02039ba <exit_mmap+0x36>
    }
}
ffffffffc02039ce:	60e2                	ld	ra,24(sp)
ffffffffc02039d0:	6442                	ld	s0,16(sp)
ffffffffc02039d2:	64a2                	ld	s1,8(sp)
ffffffffc02039d4:	6902                	ld	s2,0(sp)
ffffffffc02039d6:	6105                	addi	sp,sp,32
ffffffffc02039d8:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02039da:	00003697          	auipc	a3,0x3
ffffffffc02039de:	39e68693          	addi	a3,a3,926 # ffffffffc0206d78 <default_pmm_manager+0x860>
ffffffffc02039e2:	00002617          	auipc	a2,0x2
ffffffffc02039e6:	78660613          	addi	a2,a2,1926 # ffffffffc0206168 <commands+0x818>
ffffffffc02039ea:	0e800593          	li	a1,232
ffffffffc02039ee:	00003517          	auipc	a0,0x3
ffffffffc02039f2:	2d250513          	addi	a0,a0,722 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc02039f6:	a99fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02039fa <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc02039fa:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02039fc:	04000513          	li	a0,64
{
ffffffffc0203a00:	fc06                	sd	ra,56(sp)
ffffffffc0203a02:	f822                	sd	s0,48(sp)
ffffffffc0203a04:	f426                	sd	s1,40(sp)
ffffffffc0203a06:	f04a                	sd	s2,32(sp)
ffffffffc0203a08:	ec4e                	sd	s3,24(sp)
ffffffffc0203a0a:	e852                	sd	s4,16(sp)
ffffffffc0203a0c:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a0e:	a98fe0ef          	jal	ra,ffffffffc0201ca6 <kmalloc>
    if (mm != NULL)
ffffffffc0203a12:	2e050663          	beqz	a0,ffffffffc0203cfe <vmm_init+0x304>
ffffffffc0203a16:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203a18:	e508                	sd	a0,8(a0)
ffffffffc0203a1a:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203a1c:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203a20:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203a24:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203a28:	02053423          	sd	zero,40(a0)
ffffffffc0203a2c:	02052823          	sw	zero,48(a0)
ffffffffc0203a30:	02053c23          	sd	zero,56(a0)
ffffffffc0203a34:	03200413          	li	s0,50
ffffffffc0203a38:	a811                	j	ffffffffc0203a4c <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203a3a:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203a3c:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a3e:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203a42:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a44:	8526                	mv	a0,s1
ffffffffc0203a46:	cd3ff0ef          	jal	ra,ffffffffc0203718 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203a4a:	c80d                	beqz	s0,ffffffffc0203a7c <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a4c:	03000513          	li	a0,48
ffffffffc0203a50:	a56fe0ef          	jal	ra,ffffffffc0201ca6 <kmalloc>
ffffffffc0203a54:	85aa                	mv	a1,a0
ffffffffc0203a56:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203a5a:	f165                	bnez	a0,ffffffffc0203a3a <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203a5c:	00003697          	auipc	a3,0x3
ffffffffc0203a60:	4b468693          	addi	a3,a3,1204 # ffffffffc0206f10 <default_pmm_manager+0x9f8>
ffffffffc0203a64:	00002617          	auipc	a2,0x2
ffffffffc0203a68:	70460613          	addi	a2,a2,1796 # ffffffffc0206168 <commands+0x818>
ffffffffc0203a6c:	12c00593          	li	a1,300
ffffffffc0203a70:	00003517          	auipc	a0,0x3
ffffffffc0203a74:	25050513          	addi	a0,a0,592 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc0203a78:	a17fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203a7c:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a80:	1f900913          	li	s2,505
ffffffffc0203a84:	a819                	j	ffffffffc0203a9a <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203a86:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203a88:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a8a:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a8e:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a90:	8526                	mv	a0,s1
ffffffffc0203a92:	c87ff0ef          	jal	ra,ffffffffc0203718 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a96:	03240a63          	beq	s0,s2,ffffffffc0203aca <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a9a:	03000513          	li	a0,48
ffffffffc0203a9e:	a08fe0ef          	jal	ra,ffffffffc0201ca6 <kmalloc>
ffffffffc0203aa2:	85aa                	mv	a1,a0
ffffffffc0203aa4:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203aa8:	fd79                	bnez	a0,ffffffffc0203a86 <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203aaa:	00003697          	auipc	a3,0x3
ffffffffc0203aae:	46668693          	addi	a3,a3,1126 # ffffffffc0206f10 <default_pmm_manager+0x9f8>
ffffffffc0203ab2:	00002617          	auipc	a2,0x2
ffffffffc0203ab6:	6b660613          	addi	a2,a2,1718 # ffffffffc0206168 <commands+0x818>
ffffffffc0203aba:	13300593          	li	a1,307
ffffffffc0203abe:	00003517          	auipc	a0,0x3
ffffffffc0203ac2:	20250513          	addi	a0,a0,514 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc0203ac6:	9c9fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203aca:	649c                	ld	a5,8(s1)
ffffffffc0203acc:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203ace:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203ad2:	16f48663          	beq	s1,a5,ffffffffc0203c3e <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203ad6:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd548b4>
ffffffffc0203ada:	ffe70693          	addi	a3,a4,-2
ffffffffc0203ade:	10d61063          	bne	a2,a3,ffffffffc0203bde <vmm_init+0x1e4>
ffffffffc0203ae2:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203ae6:	0ed71c63          	bne	a4,a3,ffffffffc0203bde <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203aea:	0715                	addi	a4,a4,5
ffffffffc0203aec:	679c                	ld	a5,8(a5)
ffffffffc0203aee:	feb712e3          	bne	a4,a1,ffffffffc0203ad2 <vmm_init+0xd8>
ffffffffc0203af2:	4a1d                	li	s4,7
ffffffffc0203af4:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203af6:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203afa:	85a2                	mv	a1,s0
ffffffffc0203afc:	8526                	mv	a0,s1
ffffffffc0203afe:	bdbff0ef          	jal	ra,ffffffffc02036d8 <find_vma>
ffffffffc0203b02:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203b04:	16050d63          	beqz	a0,ffffffffc0203c7e <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203b08:	00140593          	addi	a1,s0,1
ffffffffc0203b0c:	8526                	mv	a0,s1
ffffffffc0203b0e:	bcbff0ef          	jal	ra,ffffffffc02036d8 <find_vma>
ffffffffc0203b12:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203b14:	14050563          	beqz	a0,ffffffffc0203c5e <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203b18:	85d2                	mv	a1,s4
ffffffffc0203b1a:	8526                	mv	a0,s1
ffffffffc0203b1c:	bbdff0ef          	jal	ra,ffffffffc02036d8 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203b20:	16051f63          	bnez	a0,ffffffffc0203c9e <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203b24:	00340593          	addi	a1,s0,3
ffffffffc0203b28:	8526                	mv	a0,s1
ffffffffc0203b2a:	bafff0ef          	jal	ra,ffffffffc02036d8 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203b2e:	1a051863          	bnez	a0,ffffffffc0203cde <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203b32:	00440593          	addi	a1,s0,4
ffffffffc0203b36:	8526                	mv	a0,s1
ffffffffc0203b38:	ba1ff0ef          	jal	ra,ffffffffc02036d8 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203b3c:	18051163          	bnez	a0,ffffffffc0203cbe <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203b40:	00893783          	ld	a5,8(s2)
ffffffffc0203b44:	0a879d63          	bne	a5,s0,ffffffffc0203bfe <vmm_init+0x204>
ffffffffc0203b48:	01093783          	ld	a5,16(s2)
ffffffffc0203b4c:	0b479963          	bne	a5,s4,ffffffffc0203bfe <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b50:	0089b783          	ld	a5,8(s3)
ffffffffc0203b54:	0c879563          	bne	a5,s0,ffffffffc0203c1e <vmm_init+0x224>
ffffffffc0203b58:	0109b783          	ld	a5,16(s3)
ffffffffc0203b5c:	0d479163          	bne	a5,s4,ffffffffc0203c1e <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203b60:	0415                	addi	s0,s0,5
ffffffffc0203b62:	0a15                	addi	s4,s4,5
ffffffffc0203b64:	f9541be3          	bne	s0,s5,ffffffffc0203afa <vmm_init+0x100>
ffffffffc0203b68:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203b6a:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203b6c:	85a2                	mv	a1,s0
ffffffffc0203b6e:	8526                	mv	a0,s1
ffffffffc0203b70:	b69ff0ef          	jal	ra,ffffffffc02036d8 <find_vma>
ffffffffc0203b74:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203b78:	c90d                	beqz	a0,ffffffffc0203baa <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203b7a:	6914                	ld	a3,16(a0)
ffffffffc0203b7c:	6510                	ld	a2,8(a0)
ffffffffc0203b7e:	00003517          	auipc	a0,0x3
ffffffffc0203b82:	31a50513          	addi	a0,a0,794 # ffffffffc0206e98 <default_pmm_manager+0x980>
ffffffffc0203b86:	e0efc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203b8a:	00003697          	auipc	a3,0x3
ffffffffc0203b8e:	33668693          	addi	a3,a3,822 # ffffffffc0206ec0 <default_pmm_manager+0x9a8>
ffffffffc0203b92:	00002617          	auipc	a2,0x2
ffffffffc0203b96:	5d660613          	addi	a2,a2,1494 # ffffffffc0206168 <commands+0x818>
ffffffffc0203b9a:	15900593          	li	a1,345
ffffffffc0203b9e:	00003517          	auipc	a0,0x3
ffffffffc0203ba2:	12250513          	addi	a0,a0,290 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc0203ba6:	8e9fc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203baa:	147d                	addi	s0,s0,-1
ffffffffc0203bac:	fd2410e3          	bne	s0,s2,ffffffffc0203b6c <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203bb0:	8526                	mv	a0,s1
ffffffffc0203bb2:	c37ff0ef          	jal	ra,ffffffffc02037e8 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203bb6:	00003517          	auipc	a0,0x3
ffffffffc0203bba:	32250513          	addi	a0,a0,802 # ffffffffc0206ed8 <default_pmm_manager+0x9c0>
ffffffffc0203bbe:	dd6fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203bc2:	7442                	ld	s0,48(sp)
ffffffffc0203bc4:	70e2                	ld	ra,56(sp)
ffffffffc0203bc6:	74a2                	ld	s1,40(sp)
ffffffffc0203bc8:	7902                	ld	s2,32(sp)
ffffffffc0203bca:	69e2                	ld	s3,24(sp)
ffffffffc0203bcc:	6a42                	ld	s4,16(sp)
ffffffffc0203bce:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203bd0:	00003517          	auipc	a0,0x3
ffffffffc0203bd4:	32850513          	addi	a0,a0,808 # ffffffffc0206ef8 <default_pmm_manager+0x9e0>
}
ffffffffc0203bd8:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203bda:	dbafc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203bde:	00003697          	auipc	a3,0x3
ffffffffc0203be2:	1d268693          	addi	a3,a3,466 # ffffffffc0206db0 <default_pmm_manager+0x898>
ffffffffc0203be6:	00002617          	auipc	a2,0x2
ffffffffc0203bea:	58260613          	addi	a2,a2,1410 # ffffffffc0206168 <commands+0x818>
ffffffffc0203bee:	13d00593          	li	a1,317
ffffffffc0203bf2:	00003517          	auipc	a0,0x3
ffffffffc0203bf6:	0ce50513          	addi	a0,a0,206 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc0203bfa:	895fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203bfe:	00003697          	auipc	a3,0x3
ffffffffc0203c02:	23a68693          	addi	a3,a3,570 # ffffffffc0206e38 <default_pmm_manager+0x920>
ffffffffc0203c06:	00002617          	auipc	a2,0x2
ffffffffc0203c0a:	56260613          	addi	a2,a2,1378 # ffffffffc0206168 <commands+0x818>
ffffffffc0203c0e:	14e00593          	li	a1,334
ffffffffc0203c12:	00003517          	auipc	a0,0x3
ffffffffc0203c16:	0ae50513          	addi	a0,a0,174 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc0203c1a:	875fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203c1e:	00003697          	auipc	a3,0x3
ffffffffc0203c22:	24a68693          	addi	a3,a3,586 # ffffffffc0206e68 <default_pmm_manager+0x950>
ffffffffc0203c26:	00002617          	auipc	a2,0x2
ffffffffc0203c2a:	54260613          	addi	a2,a2,1346 # ffffffffc0206168 <commands+0x818>
ffffffffc0203c2e:	14f00593          	li	a1,335
ffffffffc0203c32:	00003517          	auipc	a0,0x3
ffffffffc0203c36:	08e50513          	addi	a0,a0,142 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc0203c3a:	855fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203c3e:	00003697          	auipc	a3,0x3
ffffffffc0203c42:	15a68693          	addi	a3,a3,346 # ffffffffc0206d98 <default_pmm_manager+0x880>
ffffffffc0203c46:	00002617          	auipc	a2,0x2
ffffffffc0203c4a:	52260613          	addi	a2,a2,1314 # ffffffffc0206168 <commands+0x818>
ffffffffc0203c4e:	13b00593          	li	a1,315
ffffffffc0203c52:	00003517          	auipc	a0,0x3
ffffffffc0203c56:	06e50513          	addi	a0,a0,110 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc0203c5a:	835fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203c5e:	00003697          	auipc	a3,0x3
ffffffffc0203c62:	19a68693          	addi	a3,a3,410 # ffffffffc0206df8 <default_pmm_manager+0x8e0>
ffffffffc0203c66:	00002617          	auipc	a2,0x2
ffffffffc0203c6a:	50260613          	addi	a2,a2,1282 # ffffffffc0206168 <commands+0x818>
ffffffffc0203c6e:	14600593          	li	a1,326
ffffffffc0203c72:	00003517          	auipc	a0,0x3
ffffffffc0203c76:	04e50513          	addi	a0,a0,78 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc0203c7a:	815fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203c7e:	00003697          	auipc	a3,0x3
ffffffffc0203c82:	16a68693          	addi	a3,a3,362 # ffffffffc0206de8 <default_pmm_manager+0x8d0>
ffffffffc0203c86:	00002617          	auipc	a2,0x2
ffffffffc0203c8a:	4e260613          	addi	a2,a2,1250 # ffffffffc0206168 <commands+0x818>
ffffffffc0203c8e:	14400593          	li	a1,324
ffffffffc0203c92:	00003517          	auipc	a0,0x3
ffffffffc0203c96:	02e50513          	addi	a0,a0,46 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc0203c9a:	ff4fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203c9e:	00003697          	auipc	a3,0x3
ffffffffc0203ca2:	16a68693          	addi	a3,a3,362 # ffffffffc0206e08 <default_pmm_manager+0x8f0>
ffffffffc0203ca6:	00002617          	auipc	a2,0x2
ffffffffc0203caa:	4c260613          	addi	a2,a2,1218 # ffffffffc0206168 <commands+0x818>
ffffffffc0203cae:	14800593          	li	a1,328
ffffffffc0203cb2:	00003517          	auipc	a0,0x3
ffffffffc0203cb6:	00e50513          	addi	a0,a0,14 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc0203cba:	fd4fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203cbe:	00003697          	auipc	a3,0x3
ffffffffc0203cc2:	16a68693          	addi	a3,a3,362 # ffffffffc0206e28 <default_pmm_manager+0x910>
ffffffffc0203cc6:	00002617          	auipc	a2,0x2
ffffffffc0203cca:	4a260613          	addi	a2,a2,1186 # ffffffffc0206168 <commands+0x818>
ffffffffc0203cce:	14c00593          	li	a1,332
ffffffffc0203cd2:	00003517          	auipc	a0,0x3
ffffffffc0203cd6:	fee50513          	addi	a0,a0,-18 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc0203cda:	fb4fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203cde:	00003697          	auipc	a3,0x3
ffffffffc0203ce2:	13a68693          	addi	a3,a3,314 # ffffffffc0206e18 <default_pmm_manager+0x900>
ffffffffc0203ce6:	00002617          	auipc	a2,0x2
ffffffffc0203cea:	48260613          	addi	a2,a2,1154 # ffffffffc0206168 <commands+0x818>
ffffffffc0203cee:	14a00593          	li	a1,330
ffffffffc0203cf2:	00003517          	auipc	a0,0x3
ffffffffc0203cf6:	fce50513          	addi	a0,a0,-50 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc0203cfa:	f94fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203cfe:	00003697          	auipc	a3,0x3
ffffffffc0203d02:	04a68693          	addi	a3,a3,74 # ffffffffc0206d48 <default_pmm_manager+0x830>
ffffffffc0203d06:	00002617          	auipc	a2,0x2
ffffffffc0203d0a:	46260613          	addi	a2,a2,1122 # ffffffffc0206168 <commands+0x818>
ffffffffc0203d0e:	12400593          	li	a1,292
ffffffffc0203d12:	00003517          	auipc	a0,0x3
ffffffffc0203d16:	fae50513          	addi	a0,a0,-82 # ffffffffc0206cc0 <default_pmm_manager+0x7a8>
ffffffffc0203d1a:	f74fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203d1e <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203d1e:	7179                	addi	sp,sp,-48
ffffffffc0203d20:	f022                	sd	s0,32(sp)
ffffffffc0203d22:	f406                	sd	ra,40(sp)
ffffffffc0203d24:	ec26                	sd	s1,24(sp)
ffffffffc0203d26:	e84a                	sd	s2,16(sp)
ffffffffc0203d28:	e44e                	sd	s3,8(sp)
ffffffffc0203d2a:	e052                	sd	s4,0(sp)
ffffffffc0203d2c:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203d2e:	c135                	beqz	a0,ffffffffc0203d92 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203d30:	002007b7          	lui	a5,0x200
ffffffffc0203d34:	04f5e663          	bltu	a1,a5,ffffffffc0203d80 <user_mem_check+0x62>
ffffffffc0203d38:	00c584b3          	add	s1,a1,a2
ffffffffc0203d3c:	0495f263          	bgeu	a1,s1,ffffffffc0203d80 <user_mem_check+0x62>
ffffffffc0203d40:	4785                	li	a5,1
ffffffffc0203d42:	07fe                	slli	a5,a5,0x1f
ffffffffc0203d44:	0297ee63          	bltu	a5,s1,ffffffffc0203d80 <user_mem_check+0x62>
ffffffffc0203d48:	892a                	mv	s2,a0
ffffffffc0203d4a:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d4c:	6a05                	lui	s4,0x1
ffffffffc0203d4e:	a821                	j	ffffffffc0203d66 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d50:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d54:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203d56:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d58:	c685                	beqz	a3,ffffffffc0203d80 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203d5a:	c399                	beqz	a5,ffffffffc0203d60 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d5c:	02e46263          	bltu	s0,a4,ffffffffc0203d80 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203d60:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203d62:	04947663          	bgeu	s0,s1,ffffffffc0203dae <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203d66:	85a2                	mv	a1,s0
ffffffffc0203d68:	854a                	mv	a0,s2
ffffffffc0203d6a:	96fff0ef          	jal	ra,ffffffffc02036d8 <find_vma>
ffffffffc0203d6e:	c909                	beqz	a0,ffffffffc0203d80 <user_mem_check+0x62>
ffffffffc0203d70:	6518                	ld	a4,8(a0)
ffffffffc0203d72:	00e46763          	bltu	s0,a4,ffffffffc0203d80 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d76:	4d1c                	lw	a5,24(a0)
ffffffffc0203d78:	fc099ce3          	bnez	s3,ffffffffc0203d50 <user_mem_check+0x32>
ffffffffc0203d7c:	8b85                	andi	a5,a5,1
ffffffffc0203d7e:	f3ed                	bnez	a5,ffffffffc0203d60 <user_mem_check+0x42>
            return 0;
ffffffffc0203d80:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203d82:	70a2                	ld	ra,40(sp)
ffffffffc0203d84:	7402                	ld	s0,32(sp)
ffffffffc0203d86:	64e2                	ld	s1,24(sp)
ffffffffc0203d88:	6942                	ld	s2,16(sp)
ffffffffc0203d8a:	69a2                	ld	s3,8(sp)
ffffffffc0203d8c:	6a02                	ld	s4,0(sp)
ffffffffc0203d8e:	6145                	addi	sp,sp,48
ffffffffc0203d90:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203d92:	c02007b7          	lui	a5,0xc0200
ffffffffc0203d96:	4501                	li	a0,0
ffffffffc0203d98:	fef5e5e3          	bltu	a1,a5,ffffffffc0203d82 <user_mem_check+0x64>
ffffffffc0203d9c:	962e                	add	a2,a2,a1
ffffffffc0203d9e:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203d82 <user_mem_check+0x64>
ffffffffc0203da2:	c8000537          	lui	a0,0xc8000
ffffffffc0203da6:	0505                	addi	a0,a0,1
ffffffffc0203da8:	00a63533          	sltu	a0,a2,a0
ffffffffc0203dac:	bfd9                	j	ffffffffc0203d82 <user_mem_check+0x64>
        return 1;
ffffffffc0203dae:	4505                	li	a0,1
ffffffffc0203db0:	bfc9                	j	ffffffffc0203d82 <user_mem_check+0x64>

ffffffffc0203db2 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203db2:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203db4:	9402                	jalr	s0

	jal do_exit
ffffffffc0203db6:	638000ef          	jal	ra,ffffffffc02043ee <do_exit>

ffffffffc0203dba <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203dba:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203dbc:	10800513          	li	a0,264
{
ffffffffc0203dc0:	e022                	sd	s0,0(sp)
ffffffffc0203dc2:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203dc4:	ee3fd0ef          	jal	ra,ffffffffc0201ca6 <kmalloc>
ffffffffc0203dc8:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203dca:	cd21                	beqz	a0,ffffffffc0203e22 <alloc_proc+0x68>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;      // 设置进程状态为未初始化
ffffffffc0203dcc:	57fd                	li	a5,-1
ffffffffc0203dce:	1782                	slli	a5,a5,0x20
ffffffffc0203dd0:	e11c                	sd	a5,0(a0)
        proc->runs = 0;                 // 运行时间为0
        proc->kstack = 0;               // 内核栈地址初始化为0
        proc->need_resched = 0;         // 不需要调度
        proc->parent = NULL;            // 父进程为空
        proc->mm = NULL;                // 内存管理结构为空,内核线程共享内核内存
        memset(&(proc->context), 0, sizeof(struct context)); // 清空上下文
ffffffffc0203dd2:	07000613          	li	a2,112
ffffffffc0203dd6:	4581                	li	a1,0
        proc->runs = 0;                 // 运行时间为0
ffffffffc0203dd8:	00052423          	sw	zero,8(a0) # ffffffffc8000008 <end+0x7d558d4>
        proc->kstack = 0;               // 内核栈地址初始化为0
ffffffffc0203ddc:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;         // 不需要调度
ffffffffc0203de0:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;            // 父进程为空
ffffffffc0203de4:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                // 内存管理结构为空,内核线程共享内核内存
ffffffffc0203de8:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 清空上下文
ffffffffc0203dec:	03050513          	addi	a0,a0,48
ffffffffc0203df0:	0cb010ef          	jal	ra,ffffffffc02056ba <memset>
        proc->tf = NULL;                // 中断帧指针为空
        proc->pgdir = boot_pgdir_pa;    // 页目录设为内核页目录的物理地址
ffffffffc0203df4:	000a7797          	auipc	a5,0xa7
ffffffffc0203df8:	8f47b783          	ld	a5,-1804(a5) # ffffffffc02aa6e8 <boot_pgdir_pa>
        proc->tf = NULL;                // 中断帧指针为空
ffffffffc0203dfc:	0a043023          	sd	zero,160(s0)
        proc->pgdir = boot_pgdir_pa;    // 页目录设为内核页目录的物理地址
ffffffffc0203e00:	f45c                	sd	a5,168(s0)
        proc->flags = 0;                // 标志位初始化
ffffffffc0203e02:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1); // 清空进程名
ffffffffc0203e06:	4641                	li	a2,16
ffffffffc0203e08:	4581                	li	a1,0
ffffffffc0203e0a:	0b440513          	addi	a0,s0,180
ffffffffc0203e0e:	0ad010ef          	jal	ra,ffffffffc02056ba <memset>
        /*
        * below fields(add in LAB5) in proc_struct need to be initialized
        *       uint32_t wait_state;                        // waiting state
        *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
        */
        proc->wait_state = 0;           // 初始化等待状态
ffffffffc0203e12:	0e042623          	sw	zero,236(s0)
        proc->cptr = NULL;              // 初始化子进程指针
ffffffffc0203e16:	0e043823          	sd	zero,240(s0)
        proc->optr = NULL;              // 初始化兄弟进程指针
ffffffffc0203e1a:	10043023          	sd	zero,256(s0)
        proc->yptr = NULL;              // 初始化兄弟进程指针
ffffffffc0203e1e:	0e043c23          	sd	zero,248(s0)
    }
    return proc;
}
ffffffffc0203e22:	60a2                	ld	ra,8(sp)
ffffffffc0203e24:	8522                	mv	a0,s0
ffffffffc0203e26:	6402                	ld	s0,0(sp)
ffffffffc0203e28:	0141                	addi	sp,sp,16
ffffffffc0203e2a:	8082                	ret

ffffffffc0203e2c <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203e2c:	000a7797          	auipc	a5,0xa7
ffffffffc0203e30:	8ec7b783          	ld	a5,-1812(a5) # ffffffffc02aa718 <current>
ffffffffc0203e34:	73c8                	ld	a0,160(a5)
ffffffffc0203e36:	8e4fd06f          	j	ffffffffc0200f1a <forkrets>

ffffffffc0203e3a <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203e3a:	000a7797          	auipc	a5,0xa7
ffffffffc0203e3e:	8de7b783          	ld	a5,-1826(a5) # ffffffffc02aa718 <current>
ffffffffc0203e42:	43cc                	lw	a1,4(a5)
{
ffffffffc0203e44:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203e46:	00003617          	auipc	a2,0x3
ffffffffc0203e4a:	0da60613          	addi	a2,a2,218 # ffffffffc0206f20 <default_pmm_manager+0xa08>
ffffffffc0203e4e:	00003517          	auipc	a0,0x3
ffffffffc0203e52:	0e250513          	addi	a0,a0,226 # ffffffffc0206f30 <default_pmm_manager+0xa18>
{
ffffffffc0203e56:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203e58:	b3cfc0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0203e5c:	3fe07797          	auipc	a5,0x3fe07
ffffffffc0203e60:	b0478793          	addi	a5,a5,-1276 # a960 <_binary_obj___user_forktest_out_size>
ffffffffc0203e64:	e43e                	sd	a5,8(sp)
ffffffffc0203e66:	00003517          	auipc	a0,0x3
ffffffffc0203e6a:	0ba50513          	addi	a0,a0,186 # ffffffffc0206f20 <default_pmm_manager+0xa08>
ffffffffc0203e6e:	00046797          	auipc	a5,0x46
ffffffffc0203e72:	88278793          	addi	a5,a5,-1918 # ffffffffc02496f0 <_binary_obj___user_forktest_out_start>
ffffffffc0203e76:	f03e                	sd	a5,32(sp)
ffffffffc0203e78:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0203e7a:	e802                	sd	zero,16(sp)
ffffffffc0203e7c:	79c010ef          	jal	ra,ffffffffc0205618 <strlen>
ffffffffc0203e80:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0203e82:	4511                	li	a0,4
ffffffffc0203e84:	55a2                	lw	a1,40(sp)
ffffffffc0203e86:	4662                	lw	a2,24(sp)
ffffffffc0203e88:	5682                	lw	a3,32(sp)
ffffffffc0203e8a:	4722                	lw	a4,8(sp)
ffffffffc0203e8c:	48a9                	li	a7,10
ffffffffc0203e8e:	9002                	ebreak
ffffffffc0203e90:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0203e92:	65c2                	ld	a1,16(sp)
ffffffffc0203e94:	00003517          	auipc	a0,0x3
ffffffffc0203e98:	0c450513          	addi	a0,a0,196 # ffffffffc0206f58 <default_pmm_manager+0xa40>
ffffffffc0203e9c:	af8fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0203ea0:	00003617          	auipc	a2,0x3
ffffffffc0203ea4:	0c860613          	addi	a2,a2,200 # ffffffffc0206f68 <default_pmm_manager+0xa50>
ffffffffc0203ea8:	3d700593          	li	a1,983
ffffffffc0203eac:	00003517          	auipc	a0,0x3
ffffffffc0203eb0:	0dc50513          	addi	a0,a0,220 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc0203eb4:	ddafc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203eb8 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203eb8:	6d14                	ld	a3,24(a0)
{
ffffffffc0203eba:	1141                	addi	sp,sp,-16
ffffffffc0203ebc:	e406                	sd	ra,8(sp)
ffffffffc0203ebe:	c02007b7          	lui	a5,0xc0200
ffffffffc0203ec2:	02f6ee63          	bltu	a3,a5,ffffffffc0203efe <put_pgdir+0x46>
ffffffffc0203ec6:	000a7517          	auipc	a0,0xa7
ffffffffc0203eca:	84a53503          	ld	a0,-1974(a0) # ffffffffc02aa710 <va_pa_offset>
ffffffffc0203ece:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0203ed0:	82b1                	srli	a3,a3,0xc
ffffffffc0203ed2:	000a7797          	auipc	a5,0xa7
ffffffffc0203ed6:	8267b783          	ld	a5,-2010(a5) # ffffffffc02aa6f8 <npage>
ffffffffc0203eda:	02f6fe63          	bgeu	a3,a5,ffffffffc0203f16 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203ede:	00004517          	auipc	a0,0x4
ffffffffc0203ee2:	96253503          	ld	a0,-1694(a0) # ffffffffc0207840 <nbase>
}
ffffffffc0203ee6:	60a2                	ld	ra,8(sp)
ffffffffc0203ee8:	8e89                	sub	a3,a3,a0
ffffffffc0203eea:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203eec:	000a7517          	auipc	a0,0xa7
ffffffffc0203ef0:	81453503          	ld	a0,-2028(a0) # ffffffffc02aa700 <pages>
ffffffffc0203ef4:	4585                	li	a1,1
ffffffffc0203ef6:	9536                	add	a0,a0,a3
}
ffffffffc0203ef8:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203efa:	fc9fd06f          	j	ffffffffc0201ec2 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203efe:	00002617          	auipc	a2,0x2
ffffffffc0203f02:	6fa60613          	addi	a2,a2,1786 # ffffffffc02065f8 <default_pmm_manager+0xe0>
ffffffffc0203f06:	07700593          	li	a1,119
ffffffffc0203f0a:	00002517          	auipc	a0,0x2
ffffffffc0203f0e:	66e50513          	addi	a0,a0,1646 # ffffffffc0206578 <default_pmm_manager+0x60>
ffffffffc0203f12:	d7cfc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203f16:	00002617          	auipc	a2,0x2
ffffffffc0203f1a:	70a60613          	addi	a2,a2,1802 # ffffffffc0206620 <default_pmm_manager+0x108>
ffffffffc0203f1e:	06900593          	li	a1,105
ffffffffc0203f22:	00002517          	auipc	a0,0x2
ffffffffc0203f26:	65650513          	addi	a0,a0,1622 # ffffffffc0206578 <default_pmm_manager+0x60>
ffffffffc0203f2a:	d64fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203f2e <proc_run>:
{
ffffffffc0203f2e:	7179                	addi	sp,sp,-48
ffffffffc0203f30:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0203f32:	000a6917          	auipc	s2,0xa6
ffffffffc0203f36:	7e690913          	addi	s2,s2,2022 # ffffffffc02aa718 <current>
{
ffffffffc0203f3a:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0203f3c:	00093483          	ld	s1,0(s2)
{
ffffffffc0203f40:	f406                	sd	ra,40(sp)
ffffffffc0203f42:	e84e                	sd	s3,16(sp)
    if (proc != current)
ffffffffc0203f44:	02a48863          	beq	s1,a0,ffffffffc0203f74 <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f48:	100027f3          	csrr	a5,sstatus
ffffffffc0203f4c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203f4e:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f50:	ef9d                	bnez	a5,ffffffffc0203f8e <proc_run+0x60>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203f52:	755c                	ld	a5,168(a0)
ffffffffc0203f54:	577d                	li	a4,-1
ffffffffc0203f56:	177e                	slli	a4,a4,0x3f
ffffffffc0203f58:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc0203f5a:	00a93023          	sd	a0,0(s2)
ffffffffc0203f5e:	8fd9                	or	a5,a5,a4
ffffffffc0203f60:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(proc->context));
ffffffffc0203f64:	03050593          	addi	a1,a0,48
ffffffffc0203f68:	03048513          	addi	a0,s1,48
ffffffffc0203f6c:	052010ef          	jal	ra,ffffffffc0204fbe <switch_to>
    if (flag)
ffffffffc0203f70:	00099863          	bnez	s3,ffffffffc0203f80 <proc_run+0x52>
}
ffffffffc0203f74:	70a2                	ld	ra,40(sp)
ffffffffc0203f76:	7482                	ld	s1,32(sp)
ffffffffc0203f78:	6962                	ld	s2,24(sp)
ffffffffc0203f7a:	69c2                	ld	s3,16(sp)
ffffffffc0203f7c:	6145                	addi	sp,sp,48
ffffffffc0203f7e:	8082                	ret
ffffffffc0203f80:	70a2                	ld	ra,40(sp)
ffffffffc0203f82:	7482                	ld	s1,32(sp)
ffffffffc0203f84:	6962                	ld	s2,24(sp)
ffffffffc0203f86:	69c2                	ld	s3,16(sp)
ffffffffc0203f88:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0203f8a:	a25fc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc0203f8e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203f90:	a25fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0203f94:	6522                	ld	a0,8(sp)
ffffffffc0203f96:	4985                	li	s3,1
ffffffffc0203f98:	bf6d                	j	ffffffffc0203f52 <proc_run+0x24>

ffffffffc0203f9a <do_fork>:
{
ffffffffc0203f9a:	7119                	addi	sp,sp,-128
ffffffffc0203f9c:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203f9e:	000a6917          	auipc	s2,0xa6
ffffffffc0203fa2:	79290913          	addi	s2,s2,1938 # ffffffffc02aa730 <nr_process>
ffffffffc0203fa6:	00092703          	lw	a4,0(s2)
{
ffffffffc0203faa:	fc86                	sd	ra,120(sp)
ffffffffc0203fac:	f8a2                	sd	s0,112(sp)
ffffffffc0203fae:	f4a6                	sd	s1,104(sp)
ffffffffc0203fb0:	ecce                	sd	s3,88(sp)
ffffffffc0203fb2:	e8d2                	sd	s4,80(sp)
ffffffffc0203fb4:	e4d6                	sd	s5,72(sp)
ffffffffc0203fb6:	e0da                	sd	s6,64(sp)
ffffffffc0203fb8:	fc5e                	sd	s7,56(sp)
ffffffffc0203fba:	f862                	sd	s8,48(sp)
ffffffffc0203fbc:	f466                	sd	s9,40(sp)
ffffffffc0203fbe:	f06a                	sd	s10,32(sp)
ffffffffc0203fc0:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203fc2:	6785                	lui	a5,0x1
ffffffffc0203fc4:	32f75b63          	bge	a4,a5,ffffffffc02042fa <do_fork+0x360>
ffffffffc0203fc8:	8a2a                	mv	s4,a0
ffffffffc0203fca:	89ae                	mv	s3,a1
ffffffffc0203fcc:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc0203fce:	dedff0ef          	jal	ra,ffffffffc0203dba <alloc_proc>
ffffffffc0203fd2:	84aa                	mv	s1,a0
ffffffffc0203fd4:	30050463          	beqz	a0,ffffffffc02042dc <do_fork+0x342>
    proc->parent = current;
ffffffffc0203fd8:	000a6c17          	auipc	s8,0xa6
ffffffffc0203fdc:	740c0c13          	addi	s8,s8,1856 # ffffffffc02aa718 <current>
ffffffffc0203fe0:	000c3783          	ld	a5,0(s8)
    assert(current->wait_state == 0);
ffffffffc0203fe4:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8abc>
    proc->parent = current;
ffffffffc0203fe8:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc0203fea:	30071d63          	bnez	a4,ffffffffc0204304 <do_fork+0x36a>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203fee:	4509                	li	a0,2
ffffffffc0203ff0:	e95fd0ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
    if (page != NULL)
ffffffffc0203ff4:	2e050163          	beqz	a0,ffffffffc02042d6 <do_fork+0x33c>
    return page - pages + nbase;
ffffffffc0203ff8:	000a6a97          	auipc	s5,0xa6
ffffffffc0203ffc:	708a8a93          	addi	s5,s5,1800 # ffffffffc02aa700 <pages>
ffffffffc0204000:	000ab683          	ld	a3,0(s5)
ffffffffc0204004:	00004b17          	auipc	s6,0x4
ffffffffc0204008:	83cb0b13          	addi	s6,s6,-1988 # ffffffffc0207840 <nbase>
ffffffffc020400c:	000b3783          	ld	a5,0(s6)
ffffffffc0204010:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0204014:	000a6b97          	auipc	s7,0xa6
ffffffffc0204018:	6e4b8b93          	addi	s7,s7,1764 # ffffffffc02aa6f8 <npage>
    return page - pages + nbase;
ffffffffc020401c:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020401e:	5dfd                	li	s11,-1
ffffffffc0204020:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204024:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204026:	00cddd93          	srli	s11,s11,0xc
ffffffffc020402a:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc020402e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204030:	2ee67a63          	bgeu	a2,a4,ffffffffc0204324 <do_fork+0x38a>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0204034:	000c3603          	ld	a2,0(s8)
ffffffffc0204038:	000a6c17          	auipc	s8,0xa6
ffffffffc020403c:	6d8c0c13          	addi	s8,s8,1752 # ffffffffc02aa710 <va_pa_offset>
ffffffffc0204040:	000c3703          	ld	a4,0(s8)
ffffffffc0204044:	02863d03          	ld	s10,40(a2)
ffffffffc0204048:	e43e                	sd	a5,8(sp)
ffffffffc020404a:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc020404c:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc020404e:	020d0863          	beqz	s10,ffffffffc020407e <do_fork+0xe4>
    if (clone_flags & CLONE_VM)
ffffffffc0204052:	100a7a13          	andi	s4,s4,256
ffffffffc0204056:	1c0a0163          	beqz	s4,ffffffffc0204218 <do_fork+0x27e>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc020405a:	030d2703          	lw	a4,48(s10)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020405e:	018d3783          	ld	a5,24(s10)
ffffffffc0204062:	c02006b7          	lui	a3,0xc0200
ffffffffc0204066:	2705                	addiw	a4,a4,1
ffffffffc0204068:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc020406c:	03a4b423          	sd	s10,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204070:	2ed7e263          	bltu	a5,a3,ffffffffc0204354 <do_fork+0x3ba>
ffffffffc0204074:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204078:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020407a:	8f99                	sub	a5,a5,a4
ffffffffc020407c:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020407e:	6789                	lui	a5,0x2
ffffffffc0204080:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cc8>
ffffffffc0204084:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0204086:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204088:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc020408a:	87b6                	mv	a5,a3
ffffffffc020408c:	12040893          	addi	a7,s0,288
ffffffffc0204090:	00063803          	ld	a6,0(a2)
ffffffffc0204094:	6608                	ld	a0,8(a2)
ffffffffc0204096:	6a0c                	ld	a1,16(a2)
ffffffffc0204098:	6e18                	ld	a4,24(a2)
ffffffffc020409a:	0107b023          	sd	a6,0(a5)
ffffffffc020409e:	e788                	sd	a0,8(a5)
ffffffffc02040a0:	eb8c                	sd	a1,16(a5)
ffffffffc02040a2:	ef98                	sd	a4,24(a5)
ffffffffc02040a4:	02060613          	addi	a2,a2,32
ffffffffc02040a8:	02078793          	addi	a5,a5,32
ffffffffc02040ac:	ff1612e3          	bne	a2,a7,ffffffffc0204090 <do_fork+0xf6>
    proc->tf->gpr.a0 = 0;
ffffffffc02040b0:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02040b4:	12098f63          	beqz	s3,ffffffffc02041f2 <do_fork+0x258>
ffffffffc02040b8:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02040bc:	00000797          	auipc	a5,0x0
ffffffffc02040c0:	d7078793          	addi	a5,a5,-656 # ffffffffc0203e2c <forkret>
ffffffffc02040c4:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02040c6:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02040c8:	100027f3          	csrr	a5,sstatus
ffffffffc02040cc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02040ce:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02040d0:	14079063          	bnez	a5,ffffffffc0204210 <do_fork+0x276>
    if (++last_pid >= MAX_PID)
ffffffffc02040d4:	000a2817          	auipc	a6,0xa2
ffffffffc02040d8:	1b480813          	addi	a6,a6,436 # ffffffffc02a6288 <last_pid.1>
ffffffffc02040dc:	00082783          	lw	a5,0(a6)
ffffffffc02040e0:	6709                	lui	a4,0x2
ffffffffc02040e2:	0017851b          	addiw	a0,a5,1
ffffffffc02040e6:	00a82023          	sw	a0,0(a6)
ffffffffc02040ea:	08e55d63          	bge	a0,a4,ffffffffc0204184 <do_fork+0x1ea>
    if (last_pid >= next_safe)
ffffffffc02040ee:	000a2317          	auipc	t1,0xa2
ffffffffc02040f2:	19e30313          	addi	t1,t1,414 # ffffffffc02a628c <next_safe.0>
ffffffffc02040f6:	00032783          	lw	a5,0(t1)
ffffffffc02040fa:	000a6417          	auipc	s0,0xa6
ffffffffc02040fe:	5ae40413          	addi	s0,s0,1454 # ffffffffc02aa6a8 <proc_list>
ffffffffc0204102:	08f55963          	bge	a0,a5,ffffffffc0204194 <do_fork+0x1fa>
        proc->pid = get_pid(); // 获取唯一PID
ffffffffc0204106:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204108:	45a9                	li	a1,10
ffffffffc020410a:	2501                	sext.w	a0,a0
ffffffffc020410c:	108010ef          	jal	ra,ffffffffc0205214 <hash32>
ffffffffc0204110:	02051793          	slli	a5,a0,0x20
ffffffffc0204114:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204118:	000a2797          	auipc	a5,0xa2
ffffffffc020411c:	59078793          	addi	a5,a5,1424 # ffffffffc02a66a8 <hash_list>
ffffffffc0204120:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204122:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204124:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204126:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc020412a:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020412c:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc020412e:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204130:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204132:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc0204136:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc0204138:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc020413a:	e21c                	sd	a5,0(a2)
ffffffffc020413c:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc020413e:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc0204140:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc0204142:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204146:	10e4b023          	sd	a4,256(s1)
ffffffffc020414a:	c311                	beqz	a4,ffffffffc020414e <do_fork+0x1b4>
        proc->optr->yptr = proc;
ffffffffc020414c:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc020414e:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc0204152:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc0204154:	2785                	addiw	a5,a5,1
ffffffffc0204156:	00f92023          	sw	a5,0(s2)
    if (flag)
ffffffffc020415a:	18099363          	bnez	s3,ffffffffc02042e0 <do_fork+0x346>
    wakeup_proc(proc);
ffffffffc020415e:	8526                	mv	a0,s1
ffffffffc0204160:	6c9000ef          	jal	ra,ffffffffc0205028 <wakeup_proc>
    ret = proc->pid;
ffffffffc0204164:	40c8                	lw	a0,4(s1)
}
ffffffffc0204166:	70e6                	ld	ra,120(sp)
ffffffffc0204168:	7446                	ld	s0,112(sp)
ffffffffc020416a:	74a6                	ld	s1,104(sp)
ffffffffc020416c:	7906                	ld	s2,96(sp)
ffffffffc020416e:	69e6                	ld	s3,88(sp)
ffffffffc0204170:	6a46                	ld	s4,80(sp)
ffffffffc0204172:	6aa6                	ld	s5,72(sp)
ffffffffc0204174:	6b06                	ld	s6,64(sp)
ffffffffc0204176:	7be2                	ld	s7,56(sp)
ffffffffc0204178:	7c42                	ld	s8,48(sp)
ffffffffc020417a:	7ca2                	ld	s9,40(sp)
ffffffffc020417c:	7d02                	ld	s10,32(sp)
ffffffffc020417e:	6de2                	ld	s11,24(sp)
ffffffffc0204180:	6109                	addi	sp,sp,128
ffffffffc0204182:	8082                	ret
        last_pid = 1;
ffffffffc0204184:	4785                	li	a5,1
ffffffffc0204186:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc020418a:	4505                	li	a0,1
ffffffffc020418c:	000a2317          	auipc	t1,0xa2
ffffffffc0204190:	10030313          	addi	t1,t1,256 # ffffffffc02a628c <next_safe.0>
    return listelm->next;
ffffffffc0204194:	000a6417          	auipc	s0,0xa6
ffffffffc0204198:	51440413          	addi	s0,s0,1300 # ffffffffc02aa6a8 <proc_list>
ffffffffc020419c:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc02041a0:	6789                	lui	a5,0x2
ffffffffc02041a2:	00f32023          	sw	a5,0(t1)
ffffffffc02041a6:	86aa                	mv	a3,a0
ffffffffc02041a8:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc02041aa:	6e89                	lui	t4,0x2
ffffffffc02041ac:	148e0263          	beq	t3,s0,ffffffffc02042f0 <do_fork+0x356>
ffffffffc02041b0:	88ae                	mv	a7,a1
ffffffffc02041b2:	87f2                	mv	a5,t3
ffffffffc02041b4:	6609                	lui	a2,0x2
ffffffffc02041b6:	a811                	j	ffffffffc02041ca <do_fork+0x230>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02041b8:	00e6d663          	bge	a3,a4,ffffffffc02041c4 <do_fork+0x22a>
ffffffffc02041bc:	00c75463          	bge	a4,a2,ffffffffc02041c4 <do_fork+0x22a>
ffffffffc02041c0:	863a                	mv	a2,a4
ffffffffc02041c2:	4885                	li	a7,1
ffffffffc02041c4:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02041c6:	00878d63          	beq	a5,s0,ffffffffc02041e0 <do_fork+0x246>
            if (proc->pid == last_pid)
ffffffffc02041ca:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c6c>
ffffffffc02041ce:	fed715e3          	bne	a4,a3,ffffffffc02041b8 <do_fork+0x21e>
                if (++last_pid >= next_safe)
ffffffffc02041d2:	2685                	addiw	a3,a3,1
ffffffffc02041d4:	10c6d963          	bge	a3,a2,ffffffffc02042e6 <do_fork+0x34c>
ffffffffc02041d8:	679c                	ld	a5,8(a5)
ffffffffc02041da:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02041dc:	fe8797e3          	bne	a5,s0,ffffffffc02041ca <do_fork+0x230>
ffffffffc02041e0:	c581                	beqz	a1,ffffffffc02041e8 <do_fork+0x24e>
ffffffffc02041e2:	00d82023          	sw	a3,0(a6)
ffffffffc02041e6:	8536                	mv	a0,a3
ffffffffc02041e8:	f0088fe3          	beqz	a7,ffffffffc0204106 <do_fork+0x16c>
ffffffffc02041ec:	00c32023          	sw	a2,0(t1)
ffffffffc02041f0:	bf19                	j	ffffffffc0204106 <do_fork+0x16c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02041f2:	89b6                	mv	s3,a3
ffffffffc02041f4:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02041f8:	00000797          	auipc	a5,0x0
ffffffffc02041fc:	c3478793          	addi	a5,a5,-972 # ffffffffc0203e2c <forkret>
ffffffffc0204200:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204202:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204204:	100027f3          	csrr	a5,sstatus
ffffffffc0204208:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020420a:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020420c:	ec0784e3          	beqz	a5,ffffffffc02040d4 <do_fork+0x13a>
        intr_disable();
ffffffffc0204210:	fa4fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204214:	4985                	li	s3,1
ffffffffc0204216:	bd7d                	j	ffffffffc02040d4 <do_fork+0x13a>
    if ((mm = mm_create()) == NULL)
ffffffffc0204218:	c90ff0ef          	jal	ra,ffffffffc02036a8 <mm_create>
ffffffffc020421c:	8caa                	mv	s9,a0
ffffffffc020421e:	c541                	beqz	a0,ffffffffc02042a6 <do_fork+0x30c>
    if ((page = alloc_page()) == NULL)
ffffffffc0204220:	4505                	li	a0,1
ffffffffc0204222:	c63fd0ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc0204226:	cd2d                	beqz	a0,ffffffffc02042a0 <do_fork+0x306>
    return page - pages + nbase;
ffffffffc0204228:	000ab683          	ld	a3,0(s5)
ffffffffc020422c:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc020422e:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204232:	40d506b3          	sub	a3,a0,a3
ffffffffc0204236:	8699                	srai	a3,a3,0x6
ffffffffc0204238:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc020423a:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc020423e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204240:	0eedf263          	bgeu	s11,a4,ffffffffc0204324 <do_fork+0x38a>
ffffffffc0204244:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204248:	6605                	lui	a2,0x1
ffffffffc020424a:	000a6597          	auipc	a1,0xa6
ffffffffc020424e:	4a65b583          	ld	a1,1190(a1) # ffffffffc02aa6f0 <boot_pgdir_va>
ffffffffc0204252:	9a36                	add	s4,s4,a3
ffffffffc0204254:	8552                	mv	a0,s4
ffffffffc0204256:	476010ef          	jal	ra,ffffffffc02056cc <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc020425a:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc020425e:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204262:	4785                	li	a5,1
ffffffffc0204264:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc0204268:	8b85                	andi	a5,a5,1
ffffffffc020426a:	4a05                	li	s4,1
ffffffffc020426c:	c799                	beqz	a5,ffffffffc020427a <do_fork+0x2e0>
    {
        schedule();
ffffffffc020426e:	63b000ef          	jal	ra,ffffffffc02050a8 <schedule>
ffffffffc0204272:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock))
ffffffffc0204276:	8b85                	andi	a5,a5,1
ffffffffc0204278:	fbfd                	bnez	a5,ffffffffc020426e <do_fork+0x2d4>
        ret = dup_mmap(mm, oldmm);
ffffffffc020427a:	85ea                	mv	a1,s10
ffffffffc020427c:	8566                	mv	a0,s9
ffffffffc020427e:	e6cff0ef          	jal	ra,ffffffffc02038ea <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204282:	57f9                	li	a5,-2
ffffffffc0204284:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc0204288:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc020428a:	0e078e63          	beqz	a5,ffffffffc0204386 <do_fork+0x3ec>
good_mm:
ffffffffc020428e:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc0204290:	dc0505e3          	beqz	a0,ffffffffc020405a <do_fork+0xc0>
    exit_mmap(mm);
ffffffffc0204294:	8566                	mv	a0,s9
ffffffffc0204296:	eeeff0ef          	jal	ra,ffffffffc0203984 <exit_mmap>
    put_pgdir(mm);
ffffffffc020429a:	8566                	mv	a0,s9
ffffffffc020429c:	c1dff0ef          	jal	ra,ffffffffc0203eb8 <put_pgdir>
    mm_destroy(mm);
ffffffffc02042a0:	8566                	mv	a0,s9
ffffffffc02042a2:	d46ff0ef          	jal	ra,ffffffffc02037e8 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02042a6:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc02042a8:	c02007b7          	lui	a5,0xc0200
ffffffffc02042ac:	0cf6e163          	bltu	a3,a5,ffffffffc020436e <do_fork+0x3d4>
ffffffffc02042b0:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc02042b4:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc02042b8:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02042bc:	83b1                	srli	a5,a5,0xc
ffffffffc02042be:	06e7ff63          	bgeu	a5,a4,ffffffffc020433c <do_fork+0x3a2>
    return &pages[PPN(pa) - nbase];
ffffffffc02042c2:	000b3703          	ld	a4,0(s6)
ffffffffc02042c6:	000ab503          	ld	a0,0(s5)
ffffffffc02042ca:	4589                	li	a1,2
ffffffffc02042cc:	8f99                	sub	a5,a5,a4
ffffffffc02042ce:	079a                	slli	a5,a5,0x6
ffffffffc02042d0:	953e                	add	a0,a0,a5
ffffffffc02042d2:	bf1fd0ef          	jal	ra,ffffffffc0201ec2 <free_pages>
    kfree(proc);
ffffffffc02042d6:	8526                	mv	a0,s1
ffffffffc02042d8:	a7ffd0ef          	jal	ra,ffffffffc0201d56 <kfree>
    ret = -E_NO_MEM;
ffffffffc02042dc:	5571                	li	a0,-4
    return ret;
ffffffffc02042de:	b561                	j	ffffffffc0204166 <do_fork+0x1cc>
        intr_enable();
ffffffffc02042e0:	ecefc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02042e4:	bdad                	j	ffffffffc020415e <do_fork+0x1c4>
                    if (last_pid >= MAX_PID)
ffffffffc02042e6:	01d6c363          	blt	a3,t4,ffffffffc02042ec <do_fork+0x352>
                        last_pid = 1;
ffffffffc02042ea:	4685                	li	a3,1
                    goto repeat;
ffffffffc02042ec:	4585                	li	a1,1
ffffffffc02042ee:	bd7d                	j	ffffffffc02041ac <do_fork+0x212>
ffffffffc02042f0:	c599                	beqz	a1,ffffffffc02042fe <do_fork+0x364>
ffffffffc02042f2:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc02042f6:	8536                	mv	a0,a3
ffffffffc02042f8:	b539                	j	ffffffffc0204106 <do_fork+0x16c>
    int ret = -E_NO_FREE_PROC;
ffffffffc02042fa:	556d                	li	a0,-5
ffffffffc02042fc:	b5ad                	j	ffffffffc0204166 <do_fork+0x1cc>
    return last_pid;
ffffffffc02042fe:	00082503          	lw	a0,0(a6)
ffffffffc0204302:	b511                	j	ffffffffc0204106 <do_fork+0x16c>
    assert(current->wait_state == 0);
ffffffffc0204304:	00003697          	auipc	a3,0x3
ffffffffc0204308:	c9c68693          	addi	a3,a3,-868 # ffffffffc0206fa0 <default_pmm_manager+0xa88>
ffffffffc020430c:	00002617          	auipc	a2,0x2
ffffffffc0204310:	e5c60613          	addi	a2,a2,-420 # ffffffffc0206168 <commands+0x818>
ffffffffc0204314:	1e100593          	li	a1,481
ffffffffc0204318:	00003517          	auipc	a0,0x3
ffffffffc020431c:	c7050513          	addi	a0,a0,-912 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc0204320:	96efc0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0204324:	00002617          	auipc	a2,0x2
ffffffffc0204328:	22c60613          	addi	a2,a2,556 # ffffffffc0206550 <default_pmm_manager+0x38>
ffffffffc020432c:	07100593          	li	a1,113
ffffffffc0204330:	00002517          	auipc	a0,0x2
ffffffffc0204334:	24850513          	addi	a0,a0,584 # ffffffffc0206578 <default_pmm_manager+0x60>
ffffffffc0204338:	956fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020433c:	00002617          	auipc	a2,0x2
ffffffffc0204340:	2e460613          	addi	a2,a2,740 # ffffffffc0206620 <default_pmm_manager+0x108>
ffffffffc0204344:	06900593          	li	a1,105
ffffffffc0204348:	00002517          	auipc	a0,0x2
ffffffffc020434c:	23050513          	addi	a0,a0,560 # ffffffffc0206578 <default_pmm_manager+0x60>
ffffffffc0204350:	93efc0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204354:	86be                	mv	a3,a5
ffffffffc0204356:	00002617          	auipc	a2,0x2
ffffffffc020435a:	2a260613          	addi	a2,a2,674 # ffffffffc02065f8 <default_pmm_manager+0xe0>
ffffffffc020435e:	19600593          	li	a1,406
ffffffffc0204362:	00003517          	auipc	a0,0x3
ffffffffc0204366:	c2650513          	addi	a0,a0,-986 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc020436a:	924fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc020436e:	00002617          	auipc	a2,0x2
ffffffffc0204372:	28a60613          	addi	a2,a2,650 # ffffffffc02065f8 <default_pmm_manager+0xe0>
ffffffffc0204376:	07700593          	li	a1,119
ffffffffc020437a:	00002517          	auipc	a0,0x2
ffffffffc020437e:	1fe50513          	addi	a0,a0,510 # ffffffffc0206578 <default_pmm_manager+0x60>
ffffffffc0204382:	90cfc0ef          	jal	ra,ffffffffc020048e <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc0204386:	00003617          	auipc	a2,0x3
ffffffffc020438a:	c3a60613          	addi	a2,a2,-966 # ffffffffc0206fc0 <default_pmm_manager+0xaa8>
ffffffffc020438e:	03f00593          	li	a1,63
ffffffffc0204392:	00003517          	auipc	a0,0x3
ffffffffc0204396:	c3e50513          	addi	a0,a0,-962 # ffffffffc0206fd0 <default_pmm_manager+0xab8>
ffffffffc020439a:	8f4fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020439e <kernel_thread>:
{
ffffffffc020439e:	7129                	addi	sp,sp,-320
ffffffffc02043a0:	fa22                	sd	s0,304(sp)
ffffffffc02043a2:	f626                	sd	s1,296(sp)
ffffffffc02043a4:	f24a                	sd	s2,288(sp)
ffffffffc02043a6:	84ae                	mv	s1,a1
ffffffffc02043a8:	892a                	mv	s2,a0
ffffffffc02043aa:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02043ac:	4581                	li	a1,0
ffffffffc02043ae:	12000613          	li	a2,288
ffffffffc02043b2:	850a                	mv	a0,sp
{
ffffffffc02043b4:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02043b6:	304010ef          	jal	ra,ffffffffc02056ba <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02043ba:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02043bc:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02043be:	100027f3          	csrr	a5,sstatus
ffffffffc02043c2:	edd7f793          	andi	a5,a5,-291
ffffffffc02043c6:	1207e793          	ori	a5,a5,288
ffffffffc02043ca:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02043cc:	860a                	mv	a2,sp
ffffffffc02043ce:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02043d2:	00000797          	auipc	a5,0x0
ffffffffc02043d6:	9e078793          	addi	a5,a5,-1568 # ffffffffc0203db2 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02043da:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02043dc:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02043de:	bbdff0ef          	jal	ra,ffffffffc0203f9a <do_fork>
}
ffffffffc02043e2:	70f2                	ld	ra,312(sp)
ffffffffc02043e4:	7452                	ld	s0,304(sp)
ffffffffc02043e6:	74b2                	ld	s1,296(sp)
ffffffffc02043e8:	7912                	ld	s2,288(sp)
ffffffffc02043ea:	6131                	addi	sp,sp,320
ffffffffc02043ec:	8082                	ret

ffffffffc02043ee <do_exit>:
{
ffffffffc02043ee:	7179                	addi	sp,sp,-48
ffffffffc02043f0:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc02043f2:	000a6417          	auipc	s0,0xa6
ffffffffc02043f6:	32640413          	addi	s0,s0,806 # ffffffffc02aa718 <current>
ffffffffc02043fa:	601c                	ld	a5,0(s0)
{
ffffffffc02043fc:	f406                	sd	ra,40(sp)
ffffffffc02043fe:	ec26                	sd	s1,24(sp)
ffffffffc0204400:	e84a                	sd	s2,16(sp)
ffffffffc0204402:	e44e                	sd	s3,8(sp)
ffffffffc0204404:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc0204406:	000a6717          	auipc	a4,0xa6
ffffffffc020440a:	31a73703          	ld	a4,794(a4) # ffffffffc02aa720 <idleproc>
ffffffffc020440e:	0ce78c63          	beq	a5,a4,ffffffffc02044e6 <do_exit+0xf8>
    if (current == initproc)
ffffffffc0204412:	000a6497          	auipc	s1,0xa6
ffffffffc0204416:	31648493          	addi	s1,s1,790 # ffffffffc02aa728 <initproc>
ffffffffc020441a:	6098                	ld	a4,0(s1)
ffffffffc020441c:	0ee78b63          	beq	a5,a4,ffffffffc0204512 <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc0204420:	0287b983          	ld	s3,40(a5)
ffffffffc0204424:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc0204426:	02098663          	beqz	s3,ffffffffc0204452 <do_exit+0x64>
ffffffffc020442a:	000a6797          	auipc	a5,0xa6
ffffffffc020442e:	2be7b783          	ld	a5,702(a5) # ffffffffc02aa6e8 <boot_pgdir_pa>
ffffffffc0204432:	577d                	li	a4,-1
ffffffffc0204434:	177e                	slli	a4,a4,0x3f
ffffffffc0204436:	83b1                	srli	a5,a5,0xc
ffffffffc0204438:	8fd9                	or	a5,a5,a4
ffffffffc020443a:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc020443e:	0309a783          	lw	a5,48(s3)
ffffffffc0204442:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204446:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc020444a:	cb55                	beqz	a4,ffffffffc02044fe <do_exit+0x110>
        current->mm = NULL;
ffffffffc020444c:	601c                	ld	a5,0(s0)
ffffffffc020444e:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204452:	601c                	ld	a5,0(s0)
ffffffffc0204454:	470d                	li	a4,3
ffffffffc0204456:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc0204458:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020445c:	100027f3          	csrr	a5,sstatus
ffffffffc0204460:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204462:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204464:	e3f9                	bnez	a5,ffffffffc020452a <do_exit+0x13c>
        proc = current->parent;
ffffffffc0204466:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204468:	800007b7          	lui	a5,0x80000
ffffffffc020446c:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc020446e:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204470:	0ec52703          	lw	a4,236(a0)
ffffffffc0204474:	0af70f63          	beq	a4,a5,ffffffffc0204532 <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc0204478:	6018                	ld	a4,0(s0)
ffffffffc020447a:	7b7c                	ld	a5,240(a4)
ffffffffc020447c:	c3a1                	beqz	a5,ffffffffc02044bc <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc020447e:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204482:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204484:	0985                	addi	s3,s3,1
ffffffffc0204486:	a021                	j	ffffffffc020448e <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc0204488:	6018                	ld	a4,0(s0)
ffffffffc020448a:	7b7c                	ld	a5,240(a4)
ffffffffc020448c:	cb85                	beqz	a5,ffffffffc02044bc <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc020448e:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fe0>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204492:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204494:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204496:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0204498:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020449c:	10e7b023          	sd	a4,256(a5)
ffffffffc02044a0:	c311                	beqz	a4,ffffffffc02044a4 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc02044a2:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02044a4:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc02044a6:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc02044a8:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02044aa:	fd271fe3          	bne	a4,s2,ffffffffc0204488 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc02044ae:	0ec52783          	lw	a5,236(a0)
ffffffffc02044b2:	fd379be3          	bne	a5,s3,ffffffffc0204488 <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc02044b6:	373000ef          	jal	ra,ffffffffc0205028 <wakeup_proc>
ffffffffc02044ba:	b7f9                	j	ffffffffc0204488 <do_exit+0x9a>
    if (flag)
ffffffffc02044bc:	020a1263          	bnez	s4,ffffffffc02044e0 <do_exit+0xf2>
    schedule();
ffffffffc02044c0:	3e9000ef          	jal	ra,ffffffffc02050a8 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc02044c4:	601c                	ld	a5,0(s0)
ffffffffc02044c6:	00003617          	auipc	a2,0x3
ffffffffc02044ca:	b4260613          	addi	a2,a2,-1214 # ffffffffc0207008 <default_pmm_manager+0xaf0>
ffffffffc02044ce:	25800593          	li	a1,600
ffffffffc02044d2:	43d4                	lw	a3,4(a5)
ffffffffc02044d4:	00003517          	auipc	a0,0x3
ffffffffc02044d8:	ab450513          	addi	a0,a0,-1356 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc02044dc:	fb3fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc02044e0:	ccefc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02044e4:	bff1                	j	ffffffffc02044c0 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc02044e6:	00003617          	auipc	a2,0x3
ffffffffc02044ea:	b0260613          	addi	a2,a2,-1278 # ffffffffc0206fe8 <default_pmm_manager+0xad0>
ffffffffc02044ee:	22400593          	li	a1,548
ffffffffc02044f2:	00003517          	auipc	a0,0x3
ffffffffc02044f6:	a9650513          	addi	a0,a0,-1386 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc02044fa:	f95fb0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);
ffffffffc02044fe:	854e                	mv	a0,s3
ffffffffc0204500:	c84ff0ef          	jal	ra,ffffffffc0203984 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204504:	854e                	mv	a0,s3
ffffffffc0204506:	9b3ff0ef          	jal	ra,ffffffffc0203eb8 <put_pgdir>
            mm_destroy(mm);
ffffffffc020450a:	854e                	mv	a0,s3
ffffffffc020450c:	adcff0ef          	jal	ra,ffffffffc02037e8 <mm_destroy>
ffffffffc0204510:	bf35                	j	ffffffffc020444c <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc0204512:	00003617          	auipc	a2,0x3
ffffffffc0204516:	ae660613          	addi	a2,a2,-1306 # ffffffffc0206ff8 <default_pmm_manager+0xae0>
ffffffffc020451a:	22800593          	li	a1,552
ffffffffc020451e:	00003517          	auipc	a0,0x3
ffffffffc0204522:	a6a50513          	addi	a0,a0,-1430 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc0204526:	f69fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc020452a:	c8afc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc020452e:	4a05                	li	s4,1
ffffffffc0204530:	bf1d                	j	ffffffffc0204466 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc0204532:	2f7000ef          	jal	ra,ffffffffc0205028 <wakeup_proc>
ffffffffc0204536:	b789                	j	ffffffffc0204478 <do_exit+0x8a>

ffffffffc0204538 <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc0204538:	715d                	addi	sp,sp,-80
ffffffffc020453a:	f84a                	sd	s2,48(sp)
ffffffffc020453c:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc020453e:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc0204542:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc0204544:	fc26                	sd	s1,56(sp)
ffffffffc0204546:	f052                	sd	s4,32(sp)
ffffffffc0204548:	ec56                	sd	s5,24(sp)
ffffffffc020454a:	e85a                	sd	s6,16(sp)
ffffffffc020454c:	e45e                	sd	s7,8(sp)
ffffffffc020454e:	e486                	sd	ra,72(sp)
ffffffffc0204550:	e0a2                	sd	s0,64(sp)
ffffffffc0204552:	84aa                	mv	s1,a0
ffffffffc0204554:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc0204556:	000a6b97          	auipc	s7,0xa6
ffffffffc020455a:	1c2b8b93          	addi	s7,s7,450 # ffffffffc02aa718 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc020455e:	00050b1b          	sext.w	s6,a0
ffffffffc0204562:	fff50a9b          	addiw	s5,a0,-1
ffffffffc0204566:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc0204568:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc020456a:	ccbd                	beqz	s1,ffffffffc02045e8 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc020456c:	0359e863          	bltu	s3,s5,ffffffffc020459c <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204570:	45a9                	li	a1,10
ffffffffc0204572:	855a                	mv	a0,s6
ffffffffc0204574:	4a1000ef          	jal	ra,ffffffffc0205214 <hash32>
ffffffffc0204578:	02051793          	slli	a5,a0,0x20
ffffffffc020457c:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204580:	000a2797          	auipc	a5,0xa2
ffffffffc0204584:	12878793          	addi	a5,a5,296 # ffffffffc02a66a8 <hash_list>
ffffffffc0204588:	953e                	add	a0,a0,a5
ffffffffc020458a:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc020458c:	a029                	j	ffffffffc0204596 <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc020458e:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204592:	02978163          	beq	a5,s1,ffffffffc02045b4 <do_wait.part.0+0x7c>
ffffffffc0204596:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc0204598:	fe851be3          	bne	a0,s0,ffffffffc020458e <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc020459c:	5579                	li	a0,-2
}
ffffffffc020459e:	60a6                	ld	ra,72(sp)
ffffffffc02045a0:	6406                	ld	s0,64(sp)
ffffffffc02045a2:	74e2                	ld	s1,56(sp)
ffffffffc02045a4:	7942                	ld	s2,48(sp)
ffffffffc02045a6:	79a2                	ld	s3,40(sp)
ffffffffc02045a8:	7a02                	ld	s4,32(sp)
ffffffffc02045aa:	6ae2                	ld	s5,24(sp)
ffffffffc02045ac:	6b42                	ld	s6,16(sp)
ffffffffc02045ae:	6ba2                	ld	s7,8(sp)
ffffffffc02045b0:	6161                	addi	sp,sp,80
ffffffffc02045b2:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc02045b4:	000bb683          	ld	a3,0(s7)
ffffffffc02045b8:	f4843783          	ld	a5,-184(s0)
ffffffffc02045bc:	fed790e3          	bne	a5,a3,ffffffffc020459c <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02045c0:	f2842703          	lw	a4,-216(s0)
ffffffffc02045c4:	478d                	li	a5,3
ffffffffc02045c6:	0ef70b63          	beq	a4,a5,ffffffffc02046bc <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc02045ca:	4785                	li	a5,1
ffffffffc02045cc:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc02045ce:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc02045d2:	2d7000ef          	jal	ra,ffffffffc02050a8 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc02045d6:	000bb783          	ld	a5,0(s7)
ffffffffc02045da:	0b07a783          	lw	a5,176(a5)
ffffffffc02045de:	8b85                	andi	a5,a5,1
ffffffffc02045e0:	d7c9                	beqz	a5,ffffffffc020456a <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc02045e2:	555d                	li	a0,-9
ffffffffc02045e4:	e0bff0ef          	jal	ra,ffffffffc02043ee <do_exit>
        proc = current->cptr;
ffffffffc02045e8:	000bb683          	ld	a3,0(s7)
ffffffffc02045ec:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc02045ee:	d45d                	beqz	s0,ffffffffc020459c <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02045f0:	470d                	li	a4,3
ffffffffc02045f2:	a021                	j	ffffffffc02045fa <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc02045f4:	10043403          	ld	s0,256(s0)
ffffffffc02045f8:	d869                	beqz	s0,ffffffffc02045ca <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02045fa:	401c                	lw	a5,0(s0)
ffffffffc02045fc:	fee79ce3          	bne	a5,a4,ffffffffc02045f4 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc0204600:	000a6797          	auipc	a5,0xa6
ffffffffc0204604:	1207b783          	ld	a5,288(a5) # ffffffffc02aa720 <idleproc>
ffffffffc0204608:	0c878963          	beq	a5,s0,ffffffffc02046da <do_wait.part.0+0x1a2>
ffffffffc020460c:	000a6797          	auipc	a5,0xa6
ffffffffc0204610:	11c7b783          	ld	a5,284(a5) # ffffffffc02aa728 <initproc>
ffffffffc0204614:	0cf40363          	beq	s0,a5,ffffffffc02046da <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc0204618:	000a0663          	beqz	s4,ffffffffc0204624 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc020461c:	0e842783          	lw	a5,232(s0)
ffffffffc0204620:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204624:	100027f3          	csrr	a5,sstatus
ffffffffc0204628:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020462a:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020462c:	e7c1                	bnez	a5,ffffffffc02046b4 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc020462e:	6c70                	ld	a2,216(s0)
ffffffffc0204630:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc0204632:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc0204636:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0204638:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc020463a:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020463c:	6470                	ld	a2,200(s0)
ffffffffc020463e:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc0204640:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204642:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc0204644:	c319                	beqz	a4,ffffffffc020464a <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc0204646:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc0204648:	7c7c                	ld	a5,248(s0)
ffffffffc020464a:	c3b5                	beqz	a5,ffffffffc02046ae <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc020464c:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc0204650:	000a6717          	auipc	a4,0xa6
ffffffffc0204654:	0e070713          	addi	a4,a4,224 # ffffffffc02aa730 <nr_process>
ffffffffc0204658:	431c                	lw	a5,0(a4)
ffffffffc020465a:	37fd                	addiw	a5,a5,-1
ffffffffc020465c:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc020465e:	e5a9                	bnez	a1,ffffffffc02046a8 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204660:	6814                	ld	a3,16(s0)
ffffffffc0204662:	c02007b7          	lui	a5,0xc0200
ffffffffc0204666:	04f6ee63          	bltu	a3,a5,ffffffffc02046c2 <do_wait.part.0+0x18a>
ffffffffc020466a:	000a6797          	auipc	a5,0xa6
ffffffffc020466e:	0a67b783          	ld	a5,166(a5) # ffffffffc02aa710 <va_pa_offset>
ffffffffc0204672:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204674:	82b1                	srli	a3,a3,0xc
ffffffffc0204676:	000a6797          	auipc	a5,0xa6
ffffffffc020467a:	0827b783          	ld	a5,130(a5) # ffffffffc02aa6f8 <npage>
ffffffffc020467e:	06f6fa63          	bgeu	a3,a5,ffffffffc02046f2 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0204682:	00003517          	auipc	a0,0x3
ffffffffc0204686:	1be53503          	ld	a0,446(a0) # ffffffffc0207840 <nbase>
ffffffffc020468a:	8e89                	sub	a3,a3,a0
ffffffffc020468c:	069a                	slli	a3,a3,0x6
ffffffffc020468e:	000a6517          	auipc	a0,0xa6
ffffffffc0204692:	07253503          	ld	a0,114(a0) # ffffffffc02aa700 <pages>
ffffffffc0204696:	9536                	add	a0,a0,a3
ffffffffc0204698:	4589                	li	a1,2
ffffffffc020469a:	829fd0ef          	jal	ra,ffffffffc0201ec2 <free_pages>
    kfree(proc);
ffffffffc020469e:	8522                	mv	a0,s0
ffffffffc02046a0:	eb6fd0ef          	jal	ra,ffffffffc0201d56 <kfree>
    return 0;
ffffffffc02046a4:	4501                	li	a0,0
ffffffffc02046a6:	bde5                	j	ffffffffc020459e <do_wait.part.0+0x66>
        intr_enable();
ffffffffc02046a8:	b06fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02046ac:	bf55                	j	ffffffffc0204660 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc02046ae:	701c                	ld	a5,32(s0)
ffffffffc02046b0:	fbf8                	sd	a4,240(a5)
ffffffffc02046b2:	bf79                	j	ffffffffc0204650 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc02046b4:	b00fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02046b8:	4585                	li	a1,1
ffffffffc02046ba:	bf95                	j	ffffffffc020462e <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02046bc:	f2840413          	addi	s0,s0,-216
ffffffffc02046c0:	b781                	j	ffffffffc0204600 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc02046c2:	00002617          	auipc	a2,0x2
ffffffffc02046c6:	f3660613          	addi	a2,a2,-202 # ffffffffc02065f8 <default_pmm_manager+0xe0>
ffffffffc02046ca:	07700593          	li	a1,119
ffffffffc02046ce:	00002517          	auipc	a0,0x2
ffffffffc02046d2:	eaa50513          	addi	a0,a0,-342 # ffffffffc0206578 <default_pmm_manager+0x60>
ffffffffc02046d6:	db9fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc02046da:	00003617          	auipc	a2,0x3
ffffffffc02046de:	94e60613          	addi	a2,a2,-1714 # ffffffffc0207028 <default_pmm_manager+0xb10>
ffffffffc02046e2:	37f00593          	li	a1,895
ffffffffc02046e6:	00003517          	auipc	a0,0x3
ffffffffc02046ea:	8a250513          	addi	a0,a0,-1886 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc02046ee:	da1fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02046f2:	00002617          	auipc	a2,0x2
ffffffffc02046f6:	f2e60613          	addi	a2,a2,-210 # ffffffffc0206620 <default_pmm_manager+0x108>
ffffffffc02046fa:	06900593          	li	a1,105
ffffffffc02046fe:	00002517          	auipc	a0,0x2
ffffffffc0204702:	e7a50513          	addi	a0,a0,-390 # ffffffffc0206578 <default_pmm_manager+0x60>
ffffffffc0204706:	d89fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020470a <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc020470a:	1141                	addi	sp,sp,-16
ffffffffc020470c:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc020470e:	ff4fd0ef          	jal	ra,ffffffffc0201f02 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0204712:	d90fd0ef          	jal	ra,ffffffffc0201ca2 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0204716:	4601                	li	a2,0
ffffffffc0204718:	4581                	li	a1,0
ffffffffc020471a:	fffff517          	auipc	a0,0xfffff
ffffffffc020471e:	72050513          	addi	a0,a0,1824 # ffffffffc0203e3a <user_main>
ffffffffc0204722:	c7dff0ef          	jal	ra,ffffffffc020439e <kernel_thread>
    if (pid <= 0)
ffffffffc0204726:	00a04563          	bgtz	a0,ffffffffc0204730 <init_main+0x26>
ffffffffc020472a:	a071                	j	ffffffffc02047b6 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc020472c:	17d000ef          	jal	ra,ffffffffc02050a8 <schedule>
    if (code_store != NULL)
ffffffffc0204730:	4581                	li	a1,0
ffffffffc0204732:	4501                	li	a0,0
ffffffffc0204734:	e05ff0ef          	jal	ra,ffffffffc0204538 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204738:	d975                	beqz	a0,ffffffffc020472c <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc020473a:	00003517          	auipc	a0,0x3
ffffffffc020473e:	92e50513          	addi	a0,a0,-1746 # ffffffffc0207068 <default_pmm_manager+0xb50>
ffffffffc0204742:	a53fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204746:	000a6797          	auipc	a5,0xa6
ffffffffc020474a:	fe27b783          	ld	a5,-30(a5) # ffffffffc02aa728 <initproc>
ffffffffc020474e:	7bf8                	ld	a4,240(a5)
ffffffffc0204750:	e339                	bnez	a4,ffffffffc0204796 <init_main+0x8c>
ffffffffc0204752:	7ff8                	ld	a4,248(a5)
ffffffffc0204754:	e329                	bnez	a4,ffffffffc0204796 <init_main+0x8c>
ffffffffc0204756:	1007b703          	ld	a4,256(a5)
ffffffffc020475a:	ef15                	bnez	a4,ffffffffc0204796 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc020475c:	000a6697          	auipc	a3,0xa6
ffffffffc0204760:	fd46a683          	lw	a3,-44(a3) # ffffffffc02aa730 <nr_process>
ffffffffc0204764:	4709                	li	a4,2
ffffffffc0204766:	0ae69463          	bne	a3,a4,ffffffffc020480e <init_main+0x104>
    return listelm->next;
ffffffffc020476a:	000a6697          	auipc	a3,0xa6
ffffffffc020476e:	f3e68693          	addi	a3,a3,-194 # ffffffffc02aa6a8 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204772:	6698                	ld	a4,8(a3)
ffffffffc0204774:	0c878793          	addi	a5,a5,200
ffffffffc0204778:	06f71b63          	bne	a4,a5,ffffffffc02047ee <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020477c:	629c                	ld	a5,0(a3)
ffffffffc020477e:	04f71863          	bne	a4,a5,ffffffffc02047ce <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204782:	00003517          	auipc	a0,0x3
ffffffffc0204786:	9ce50513          	addi	a0,a0,-1586 # ffffffffc0207150 <default_pmm_manager+0xc38>
ffffffffc020478a:	a0bfb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc020478e:	60a2                	ld	ra,8(sp)
ffffffffc0204790:	4501                	li	a0,0
ffffffffc0204792:	0141                	addi	sp,sp,16
ffffffffc0204794:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204796:	00003697          	auipc	a3,0x3
ffffffffc020479a:	8fa68693          	addi	a3,a3,-1798 # ffffffffc0207090 <default_pmm_manager+0xb78>
ffffffffc020479e:	00002617          	auipc	a2,0x2
ffffffffc02047a2:	9ca60613          	addi	a2,a2,-1590 # ffffffffc0206168 <commands+0x818>
ffffffffc02047a6:	3ed00593          	li	a1,1005
ffffffffc02047aa:	00002517          	auipc	a0,0x2
ffffffffc02047ae:	7de50513          	addi	a0,a0,2014 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc02047b2:	cddfb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc02047b6:	00003617          	auipc	a2,0x3
ffffffffc02047ba:	89260613          	addi	a2,a2,-1902 # ffffffffc0207048 <default_pmm_manager+0xb30>
ffffffffc02047be:	3e400593          	li	a1,996
ffffffffc02047c2:	00002517          	auipc	a0,0x2
ffffffffc02047c6:	7c650513          	addi	a0,a0,1990 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc02047ca:	cc5fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02047ce:	00003697          	auipc	a3,0x3
ffffffffc02047d2:	95268693          	addi	a3,a3,-1710 # ffffffffc0207120 <default_pmm_manager+0xc08>
ffffffffc02047d6:	00002617          	auipc	a2,0x2
ffffffffc02047da:	99260613          	addi	a2,a2,-1646 # ffffffffc0206168 <commands+0x818>
ffffffffc02047de:	3f000593          	li	a1,1008
ffffffffc02047e2:	00002517          	auipc	a0,0x2
ffffffffc02047e6:	7a650513          	addi	a0,a0,1958 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc02047ea:	ca5fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02047ee:	00003697          	auipc	a3,0x3
ffffffffc02047f2:	90268693          	addi	a3,a3,-1790 # ffffffffc02070f0 <default_pmm_manager+0xbd8>
ffffffffc02047f6:	00002617          	auipc	a2,0x2
ffffffffc02047fa:	97260613          	addi	a2,a2,-1678 # ffffffffc0206168 <commands+0x818>
ffffffffc02047fe:	3ef00593          	li	a1,1007
ffffffffc0204802:	00002517          	auipc	a0,0x2
ffffffffc0204806:	78650513          	addi	a0,a0,1926 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc020480a:	c85fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc020480e:	00003697          	auipc	a3,0x3
ffffffffc0204812:	8d268693          	addi	a3,a3,-1838 # ffffffffc02070e0 <default_pmm_manager+0xbc8>
ffffffffc0204816:	00002617          	auipc	a2,0x2
ffffffffc020481a:	95260613          	addi	a2,a2,-1710 # ffffffffc0206168 <commands+0x818>
ffffffffc020481e:	3ee00593          	li	a1,1006
ffffffffc0204822:	00002517          	auipc	a0,0x2
ffffffffc0204826:	76650513          	addi	a0,a0,1894 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc020482a:	c65fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020482e <do_execve>:
{
ffffffffc020482e:	7171                	addi	sp,sp,-176
ffffffffc0204830:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204832:	000a6d97          	auipc	s11,0xa6
ffffffffc0204836:	ee6d8d93          	addi	s11,s11,-282 # ffffffffc02aa718 <current>
ffffffffc020483a:	000db783          	ld	a5,0(s11)
{
ffffffffc020483e:	e54e                	sd	s3,136(sp)
ffffffffc0204840:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204842:	0287b983          	ld	s3,40(a5)
{
ffffffffc0204846:	e94a                	sd	s2,144(sp)
ffffffffc0204848:	f4de                	sd	s7,104(sp)
ffffffffc020484a:	892a                	mv	s2,a0
ffffffffc020484c:	8bb2                	mv	s7,a2
ffffffffc020484e:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204850:	862e                	mv	a2,a1
ffffffffc0204852:	4681                	li	a3,0
ffffffffc0204854:	85aa                	mv	a1,a0
ffffffffc0204856:	854e                	mv	a0,s3
{
ffffffffc0204858:	f506                	sd	ra,168(sp)
ffffffffc020485a:	f122                	sd	s0,160(sp)
ffffffffc020485c:	e152                	sd	s4,128(sp)
ffffffffc020485e:	fcd6                	sd	s5,120(sp)
ffffffffc0204860:	f8da                	sd	s6,112(sp)
ffffffffc0204862:	f0e2                	sd	s8,96(sp)
ffffffffc0204864:	ece6                	sd	s9,88(sp)
ffffffffc0204866:	e8ea                	sd	s10,80(sp)
ffffffffc0204868:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc020486a:	cb4ff0ef          	jal	ra,ffffffffc0203d1e <user_mem_check>
ffffffffc020486e:	40050a63          	beqz	a0,ffffffffc0204c82 <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204872:	4641                	li	a2,16
ffffffffc0204874:	4581                	li	a1,0
ffffffffc0204876:	1808                	addi	a0,sp,48
ffffffffc0204878:	643000ef          	jal	ra,ffffffffc02056ba <memset>
    memcpy(local_name, name, len);
ffffffffc020487c:	47bd                	li	a5,15
ffffffffc020487e:	8626                	mv	a2,s1
ffffffffc0204880:	1e97e263          	bltu	a5,s1,ffffffffc0204a64 <do_execve+0x236>
ffffffffc0204884:	85ca                	mv	a1,s2
ffffffffc0204886:	1808                	addi	a0,sp,48
ffffffffc0204888:	645000ef          	jal	ra,ffffffffc02056cc <memcpy>
    if (mm != NULL)
ffffffffc020488c:	1e098363          	beqz	s3,ffffffffc0204a72 <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc0204890:	00002517          	auipc	a0,0x2
ffffffffc0204894:	4b850513          	addi	a0,a0,1208 # ffffffffc0206d48 <default_pmm_manager+0x830>
ffffffffc0204898:	935fb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc020489c:	000a6797          	auipc	a5,0xa6
ffffffffc02048a0:	e4c7b783          	ld	a5,-436(a5) # ffffffffc02aa6e8 <boot_pgdir_pa>
ffffffffc02048a4:	577d                	li	a4,-1
ffffffffc02048a6:	177e                	slli	a4,a4,0x3f
ffffffffc02048a8:	83b1                	srli	a5,a5,0xc
ffffffffc02048aa:	8fd9                	or	a5,a5,a4
ffffffffc02048ac:	18079073          	csrw	satp,a5
ffffffffc02048b0:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7b78>
ffffffffc02048b4:	fff7871b          	addiw	a4,a5,-1
ffffffffc02048b8:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc02048bc:	2c070463          	beqz	a4,ffffffffc0204b84 <do_execve+0x356>
        current->mm = NULL;
ffffffffc02048c0:	000db783          	ld	a5,0(s11)
ffffffffc02048c4:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc02048c8:	de1fe0ef          	jal	ra,ffffffffc02036a8 <mm_create>
ffffffffc02048cc:	84aa                	mv	s1,a0
ffffffffc02048ce:	1c050d63          	beqz	a0,ffffffffc0204aa8 <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc02048d2:	4505                	li	a0,1
ffffffffc02048d4:	db0fd0ef          	jal	ra,ffffffffc0201e84 <alloc_pages>
ffffffffc02048d8:	3a050963          	beqz	a0,ffffffffc0204c8a <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc02048dc:	000a6c97          	auipc	s9,0xa6
ffffffffc02048e0:	e24c8c93          	addi	s9,s9,-476 # ffffffffc02aa700 <pages>
ffffffffc02048e4:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc02048e8:	000a6c17          	auipc	s8,0xa6
ffffffffc02048ec:	e10c0c13          	addi	s8,s8,-496 # ffffffffc02aa6f8 <npage>
    return page - pages + nbase;
ffffffffc02048f0:	00003717          	auipc	a4,0x3
ffffffffc02048f4:	f5073703          	ld	a4,-176(a4) # ffffffffc0207840 <nbase>
ffffffffc02048f8:	40d506b3          	sub	a3,a0,a3
ffffffffc02048fc:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02048fe:	5afd                	li	s5,-1
ffffffffc0204900:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0204904:	96ba                	add	a3,a3,a4
ffffffffc0204906:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204908:	00cad713          	srli	a4,s5,0xc
ffffffffc020490c:	ec3a                	sd	a4,24(sp)
ffffffffc020490e:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204910:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204912:	38f77063          	bgeu	a4,a5,ffffffffc0204c92 <do_execve+0x464>
ffffffffc0204916:	000a6b17          	auipc	s6,0xa6
ffffffffc020491a:	dfab0b13          	addi	s6,s6,-518 # ffffffffc02aa710 <va_pa_offset>
ffffffffc020491e:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204922:	6605                	lui	a2,0x1
ffffffffc0204924:	000a6597          	auipc	a1,0xa6
ffffffffc0204928:	dcc5b583          	ld	a1,-564(a1) # ffffffffc02aa6f0 <boot_pgdir_va>
ffffffffc020492c:	9936                	add	s2,s2,a3
ffffffffc020492e:	854a                	mv	a0,s2
ffffffffc0204930:	59d000ef          	jal	ra,ffffffffc02056cc <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204934:	7782                	ld	a5,32(sp)
ffffffffc0204936:	4398                	lw	a4,0(a5)
ffffffffc0204938:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc020493c:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204940:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b945f>
ffffffffc0204944:	14f71863          	bne	a4,a5,ffffffffc0204a94 <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204948:	7682                	ld	a3,32(sp)
ffffffffc020494a:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc020494e:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204952:	00371793          	slli	a5,a4,0x3
ffffffffc0204956:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204958:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020495a:	078e                	slli	a5,a5,0x3
ffffffffc020495c:	97ce                	add	a5,a5,s3
ffffffffc020495e:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204960:	00f9fc63          	bgeu	s3,a5,ffffffffc0204978 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204964:	0009a783          	lw	a5,0(s3)
ffffffffc0204968:	4705                	li	a4,1
ffffffffc020496a:	14e78163          	beq	a5,a4,ffffffffc0204aac <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc020496e:	77a2                	ld	a5,40(sp)
ffffffffc0204970:	03898993          	addi	s3,s3,56
ffffffffc0204974:	fef9e8e3          	bltu	s3,a5,ffffffffc0204964 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204978:	4701                	li	a4,0
ffffffffc020497a:	46ad                	li	a3,11
ffffffffc020497c:	00100637          	lui	a2,0x100
ffffffffc0204980:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204984:	8526                	mv	a0,s1
ffffffffc0204986:	eb5fe0ef          	jal	ra,ffffffffc020383a <mm_map>
ffffffffc020498a:	8a2a                	mv	s4,a0
ffffffffc020498c:	1e051263          	bnez	a0,ffffffffc0204b70 <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204990:	6c88                	ld	a0,24(s1)
ffffffffc0204992:	467d                	li	a2,31
ffffffffc0204994:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204998:	c2bfe0ef          	jal	ra,ffffffffc02035c2 <pgdir_alloc_page>
ffffffffc020499c:	38050363          	beqz	a0,ffffffffc0204d22 <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc02049a0:	6c88                	ld	a0,24(s1)
ffffffffc02049a2:	467d                	li	a2,31
ffffffffc02049a4:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc02049a8:	c1bfe0ef          	jal	ra,ffffffffc02035c2 <pgdir_alloc_page>
ffffffffc02049ac:	34050b63          	beqz	a0,ffffffffc0204d02 <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc02049b0:	6c88                	ld	a0,24(s1)
ffffffffc02049b2:	467d                	li	a2,31
ffffffffc02049b4:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc02049b8:	c0bfe0ef          	jal	ra,ffffffffc02035c2 <pgdir_alloc_page>
ffffffffc02049bc:	32050363          	beqz	a0,ffffffffc0204ce2 <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc02049c0:	6c88                	ld	a0,24(s1)
ffffffffc02049c2:	467d                	li	a2,31
ffffffffc02049c4:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc02049c8:	bfbfe0ef          	jal	ra,ffffffffc02035c2 <pgdir_alloc_page>
ffffffffc02049cc:	2e050b63          	beqz	a0,ffffffffc0204cc2 <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc02049d0:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc02049d2:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc02049d6:	6c94                	ld	a3,24(s1)
ffffffffc02049d8:	2785                	addiw	a5,a5,1
ffffffffc02049da:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc02049dc:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc02049de:	c02007b7          	lui	a5,0xc0200
ffffffffc02049e2:	2cf6e463          	bltu	a3,a5,ffffffffc0204caa <do_execve+0x47c>
ffffffffc02049e6:	000b3783          	ld	a5,0(s6)
ffffffffc02049ea:	577d                	li	a4,-1
ffffffffc02049ec:	177e                	slli	a4,a4,0x3f
ffffffffc02049ee:	8e9d                	sub	a3,a3,a5
ffffffffc02049f0:	00c6d793          	srli	a5,a3,0xc
ffffffffc02049f4:	f654                	sd	a3,168(a2)
ffffffffc02049f6:	8fd9                	or	a5,a5,a4
ffffffffc02049f8:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc02049fc:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02049fe:	4581                	li	a1,0
ffffffffc0204a00:	12000613          	li	a2,288
ffffffffc0204a04:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204a06:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204a0a:	4b1000ef          	jal	ra,ffffffffc02056ba <memset>
    tf->epc = elf->e_entry;
ffffffffc0204a0e:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a10:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus | SSTATUS_SPIE) & ~SSTATUS_SPP;
ffffffffc0204a14:	edf4f493          	andi	s1,s1,-289
    tf->epc = elf->e_entry;
ffffffffc0204a18:	6f9c                	ld	a5,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a1a:	0b490913          	addi	s2,s2,180 # ffffffff800000b4 <_binary_obj___user_exit_out_size+0xffffffff7fff4f94>
    tf->status = (sstatus | SSTATUS_SPIE) & ~SSTATUS_SPP;
ffffffffc0204a1e:	0204e493          	ori	s1,s1,32
    tf->epc = elf->e_entry;
ffffffffc0204a22:	10f43423          	sd	a5,264(s0)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204a26:	4785                	li	a5,1
ffffffffc0204a28:	07fe                	slli	a5,a5,0x1f
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a2a:	4641                	li	a2,16
ffffffffc0204a2c:	4581                	li	a1,0
    tf->status = (sstatus | SSTATUS_SPIE) & ~SSTATUS_SPP;
ffffffffc0204a2e:	10943023          	sd	s1,256(s0)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204a32:	e81c                	sd	a5,16(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a34:	854a                	mv	a0,s2
ffffffffc0204a36:	485000ef          	jal	ra,ffffffffc02056ba <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204a3a:	463d                	li	a2,15
ffffffffc0204a3c:	180c                	addi	a1,sp,48
ffffffffc0204a3e:	854a                	mv	a0,s2
ffffffffc0204a40:	48d000ef          	jal	ra,ffffffffc02056cc <memcpy>
}
ffffffffc0204a44:	70aa                	ld	ra,168(sp)
ffffffffc0204a46:	740a                	ld	s0,160(sp)
ffffffffc0204a48:	64ea                	ld	s1,152(sp)
ffffffffc0204a4a:	694a                	ld	s2,144(sp)
ffffffffc0204a4c:	69aa                	ld	s3,136(sp)
ffffffffc0204a4e:	7ae6                	ld	s5,120(sp)
ffffffffc0204a50:	7b46                	ld	s6,112(sp)
ffffffffc0204a52:	7ba6                	ld	s7,104(sp)
ffffffffc0204a54:	7c06                	ld	s8,96(sp)
ffffffffc0204a56:	6ce6                	ld	s9,88(sp)
ffffffffc0204a58:	6d46                	ld	s10,80(sp)
ffffffffc0204a5a:	6da6                	ld	s11,72(sp)
ffffffffc0204a5c:	8552                	mv	a0,s4
ffffffffc0204a5e:	6a0a                	ld	s4,128(sp)
ffffffffc0204a60:	614d                	addi	sp,sp,176
ffffffffc0204a62:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204a64:	463d                	li	a2,15
ffffffffc0204a66:	85ca                	mv	a1,s2
ffffffffc0204a68:	1808                	addi	a0,sp,48
ffffffffc0204a6a:	463000ef          	jal	ra,ffffffffc02056cc <memcpy>
    if (mm != NULL)
ffffffffc0204a6e:	e20991e3          	bnez	s3,ffffffffc0204890 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204a72:	000db783          	ld	a5,0(s11)
ffffffffc0204a76:	779c                	ld	a5,40(a5)
ffffffffc0204a78:	e40788e3          	beqz	a5,ffffffffc02048c8 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204a7c:	00002617          	auipc	a2,0x2
ffffffffc0204a80:	6f460613          	addi	a2,a2,1780 # ffffffffc0207170 <default_pmm_manager+0xc58>
ffffffffc0204a84:	26400593          	li	a1,612
ffffffffc0204a88:	00002517          	auipc	a0,0x2
ffffffffc0204a8c:	50050513          	addi	a0,a0,1280 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc0204a90:	9fffb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc0204a94:	8526                	mv	a0,s1
ffffffffc0204a96:	c22ff0ef          	jal	ra,ffffffffc0203eb8 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204a9a:	8526                	mv	a0,s1
ffffffffc0204a9c:	d4dfe0ef          	jal	ra,ffffffffc02037e8 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204aa0:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc0204aa2:	8552                	mv	a0,s4
ffffffffc0204aa4:	94bff0ef          	jal	ra,ffffffffc02043ee <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204aa8:	5a71                	li	s4,-4
ffffffffc0204aaa:	bfe5                	j	ffffffffc0204aa2 <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204aac:	0289b603          	ld	a2,40(s3)
ffffffffc0204ab0:	0209b783          	ld	a5,32(s3)
ffffffffc0204ab4:	1cf66d63          	bltu	a2,a5,ffffffffc0204c8e <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204ab8:	0049a783          	lw	a5,4(s3)
ffffffffc0204abc:	0017f693          	andi	a3,a5,1
ffffffffc0204ac0:	c291                	beqz	a3,ffffffffc0204ac4 <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204ac2:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204ac4:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204ac8:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204aca:	e779                	bnez	a4,ffffffffc0204b98 <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204acc:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204ace:	c781                	beqz	a5,ffffffffc0204ad6 <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0204ad0:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204ad4:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204ad6:	0026f793          	andi	a5,a3,2
ffffffffc0204ada:	e3f1                	bnez	a5,ffffffffc0204b9e <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0204adc:	0046f793          	andi	a5,a3,4
ffffffffc0204ae0:	c399                	beqz	a5,ffffffffc0204ae6 <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204ae2:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204ae6:	0109b583          	ld	a1,16(s3)
ffffffffc0204aea:	4701                	li	a4,0
ffffffffc0204aec:	8526                	mv	a0,s1
ffffffffc0204aee:	d4dfe0ef          	jal	ra,ffffffffc020383a <mm_map>
ffffffffc0204af2:	8a2a                	mv	s4,a0
ffffffffc0204af4:	ed35                	bnez	a0,ffffffffc0204b70 <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204af6:	0109bb83          	ld	s7,16(s3)
ffffffffc0204afa:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204afc:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204b00:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204b04:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204b08:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204b0a:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204b0c:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc0204b0e:	054be963          	bltu	s7,s4,ffffffffc0204b60 <do_execve+0x332>
ffffffffc0204b12:	aa95                	j	ffffffffc0204c86 <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b14:	6785                	lui	a5,0x1
ffffffffc0204b16:	415b8533          	sub	a0,s7,s5
ffffffffc0204b1a:	9abe                	add	s5,s5,a5
ffffffffc0204b1c:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204b20:	015a7463          	bgeu	s4,s5,ffffffffc0204b28 <do_execve+0x2fa>
                size -= la - end;
ffffffffc0204b24:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0204b28:	000cb683          	ld	a3,0(s9)
ffffffffc0204b2c:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204b2e:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204b32:	40d406b3          	sub	a3,s0,a3
ffffffffc0204b36:	8699                	srai	a3,a3,0x6
ffffffffc0204b38:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204b3a:	67e2                	ld	a5,24(sp)
ffffffffc0204b3c:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b40:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b42:	14b87863          	bgeu	a6,a1,ffffffffc0204c92 <do_execve+0x464>
ffffffffc0204b46:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204b4a:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0204b4c:	9bb2                	add	s7,s7,a2
ffffffffc0204b4e:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204b50:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204b52:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204b54:	379000ef          	jal	ra,ffffffffc02056cc <memcpy>
            start += size, from += size;
ffffffffc0204b58:	6622                	ld	a2,8(sp)
ffffffffc0204b5a:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204b5c:	054bf363          	bgeu	s7,s4,ffffffffc0204ba2 <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204b60:	6c88                	ld	a0,24(s1)
ffffffffc0204b62:	866a                	mv	a2,s10
ffffffffc0204b64:	85d6                	mv	a1,s5
ffffffffc0204b66:	a5dfe0ef          	jal	ra,ffffffffc02035c2 <pgdir_alloc_page>
ffffffffc0204b6a:	842a                	mv	s0,a0
ffffffffc0204b6c:	f545                	bnez	a0,ffffffffc0204b14 <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204b6e:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc0204b70:	8526                	mv	a0,s1
ffffffffc0204b72:	e13fe0ef          	jal	ra,ffffffffc0203984 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204b76:	8526                	mv	a0,s1
ffffffffc0204b78:	b40ff0ef          	jal	ra,ffffffffc0203eb8 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204b7c:	8526                	mv	a0,s1
ffffffffc0204b7e:	c6bfe0ef          	jal	ra,ffffffffc02037e8 <mm_destroy>
    return ret;
ffffffffc0204b82:	b705                	j	ffffffffc0204aa2 <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204b84:	854e                	mv	a0,s3
ffffffffc0204b86:	dfffe0ef          	jal	ra,ffffffffc0203984 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204b8a:	854e                	mv	a0,s3
ffffffffc0204b8c:	b2cff0ef          	jal	ra,ffffffffc0203eb8 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204b90:	854e                	mv	a0,s3
ffffffffc0204b92:	c57fe0ef          	jal	ra,ffffffffc02037e8 <mm_destroy>
ffffffffc0204b96:	b32d                	j	ffffffffc02048c0 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204b98:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204b9c:	fb95                	bnez	a5,ffffffffc0204ad0 <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204b9e:	4d5d                	li	s10,23
ffffffffc0204ba0:	bf35                	j	ffffffffc0204adc <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204ba2:	0109b683          	ld	a3,16(s3)
ffffffffc0204ba6:	0289b903          	ld	s2,40(s3)
ffffffffc0204baa:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204bac:	075bfd63          	bgeu	s7,s5,ffffffffc0204c26 <do_execve+0x3f8>
            if (start == end)
ffffffffc0204bb0:	db790fe3          	beq	s2,s7,ffffffffc020496e <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204bb4:	6785                	lui	a5,0x1
ffffffffc0204bb6:	00fb8533          	add	a0,s7,a5
ffffffffc0204bba:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0204bbe:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0204bc2:	0b597d63          	bgeu	s2,s5,ffffffffc0204c7c <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204bc6:	000cb683          	ld	a3,0(s9)
ffffffffc0204bca:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204bcc:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204bd0:	40d406b3          	sub	a3,s0,a3
ffffffffc0204bd4:	8699                	srai	a3,a3,0x6
ffffffffc0204bd6:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204bd8:	67e2                	ld	a5,24(sp)
ffffffffc0204bda:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204bde:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204be0:	0ac5f963          	bgeu	a1,a2,ffffffffc0204c92 <do_execve+0x464>
ffffffffc0204be4:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204be8:	8652                	mv	a2,s4
ffffffffc0204bea:	4581                	li	a1,0
ffffffffc0204bec:	96c2                	add	a3,a3,a6
ffffffffc0204bee:	9536                	add	a0,a0,a3
ffffffffc0204bf0:	2cb000ef          	jal	ra,ffffffffc02056ba <memset>
            start += size;
ffffffffc0204bf4:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204bf8:	03597463          	bgeu	s2,s5,ffffffffc0204c20 <do_execve+0x3f2>
ffffffffc0204bfc:	d6e909e3          	beq	s2,a4,ffffffffc020496e <do_execve+0x140>
ffffffffc0204c00:	00002697          	auipc	a3,0x2
ffffffffc0204c04:	59868693          	addi	a3,a3,1432 # ffffffffc0207198 <default_pmm_manager+0xc80>
ffffffffc0204c08:	00001617          	auipc	a2,0x1
ffffffffc0204c0c:	56060613          	addi	a2,a2,1376 # ffffffffc0206168 <commands+0x818>
ffffffffc0204c10:	2cd00593          	li	a1,717
ffffffffc0204c14:	00002517          	auipc	a0,0x2
ffffffffc0204c18:	37450513          	addi	a0,a0,884 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc0204c1c:	873fb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204c20:	ff5710e3          	bne	a4,s5,ffffffffc0204c00 <do_execve+0x3d2>
ffffffffc0204c24:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204c26:	d52bf4e3          	bgeu	s7,s2,ffffffffc020496e <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204c2a:	6c88                	ld	a0,24(s1)
ffffffffc0204c2c:	866a                	mv	a2,s10
ffffffffc0204c2e:	85d6                	mv	a1,s5
ffffffffc0204c30:	993fe0ef          	jal	ra,ffffffffc02035c2 <pgdir_alloc_page>
ffffffffc0204c34:	842a                	mv	s0,a0
ffffffffc0204c36:	dd05                	beqz	a0,ffffffffc0204b6e <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c38:	6785                	lui	a5,0x1
ffffffffc0204c3a:	415b8533          	sub	a0,s7,s5
ffffffffc0204c3e:	9abe                	add	s5,s5,a5
ffffffffc0204c40:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204c44:	01597463          	bgeu	s2,s5,ffffffffc0204c4c <do_execve+0x41e>
                size -= la - end;
ffffffffc0204c48:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204c4c:	000cb683          	ld	a3,0(s9)
ffffffffc0204c50:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204c52:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204c56:	40d406b3          	sub	a3,s0,a3
ffffffffc0204c5a:	8699                	srai	a3,a3,0x6
ffffffffc0204c5c:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204c5e:	67e2                	ld	a5,24(sp)
ffffffffc0204c60:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c64:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204c66:	02b87663          	bgeu	a6,a1,ffffffffc0204c92 <do_execve+0x464>
ffffffffc0204c6a:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204c6e:	4581                	li	a1,0
            start += size;
ffffffffc0204c70:	9bb2                	add	s7,s7,a2
ffffffffc0204c72:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204c74:	9536                	add	a0,a0,a3
ffffffffc0204c76:	245000ef          	jal	ra,ffffffffc02056ba <memset>
ffffffffc0204c7a:	b775                	j	ffffffffc0204c26 <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204c7c:	417a8a33          	sub	s4,s5,s7
ffffffffc0204c80:	b799                	j	ffffffffc0204bc6 <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204c82:	5a75                	li	s4,-3
ffffffffc0204c84:	b3c1                	j	ffffffffc0204a44 <do_execve+0x216>
        while (start < end)
ffffffffc0204c86:	86de                	mv	a3,s7
ffffffffc0204c88:	bf39                	j	ffffffffc0204ba6 <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204c8a:	5a71                	li	s4,-4
ffffffffc0204c8c:	bdc5                	j	ffffffffc0204b7c <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204c8e:	5a61                	li	s4,-8
ffffffffc0204c90:	b5c5                	j	ffffffffc0204b70 <do_execve+0x342>
ffffffffc0204c92:	00002617          	auipc	a2,0x2
ffffffffc0204c96:	8be60613          	addi	a2,a2,-1858 # ffffffffc0206550 <default_pmm_manager+0x38>
ffffffffc0204c9a:	07100593          	li	a1,113
ffffffffc0204c9e:	00002517          	auipc	a0,0x2
ffffffffc0204ca2:	8da50513          	addi	a0,a0,-1830 # ffffffffc0206578 <default_pmm_manager+0x60>
ffffffffc0204ca6:	fe8fb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204caa:	00002617          	auipc	a2,0x2
ffffffffc0204cae:	94e60613          	addi	a2,a2,-1714 # ffffffffc02065f8 <default_pmm_manager+0xe0>
ffffffffc0204cb2:	2ec00593          	li	a1,748
ffffffffc0204cb6:	00002517          	auipc	a0,0x2
ffffffffc0204cba:	2d250513          	addi	a0,a0,722 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc0204cbe:	fd0fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204cc2:	00002697          	auipc	a3,0x2
ffffffffc0204cc6:	5ee68693          	addi	a3,a3,1518 # ffffffffc02072b0 <default_pmm_manager+0xd98>
ffffffffc0204cca:	00001617          	auipc	a2,0x1
ffffffffc0204cce:	49e60613          	addi	a2,a2,1182 # ffffffffc0206168 <commands+0x818>
ffffffffc0204cd2:	2e700593          	li	a1,743
ffffffffc0204cd6:	00002517          	auipc	a0,0x2
ffffffffc0204cda:	2b250513          	addi	a0,a0,690 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc0204cde:	fb0fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ce2:	00002697          	auipc	a3,0x2
ffffffffc0204ce6:	58668693          	addi	a3,a3,1414 # ffffffffc0207268 <default_pmm_manager+0xd50>
ffffffffc0204cea:	00001617          	auipc	a2,0x1
ffffffffc0204cee:	47e60613          	addi	a2,a2,1150 # ffffffffc0206168 <commands+0x818>
ffffffffc0204cf2:	2e600593          	li	a1,742
ffffffffc0204cf6:	00002517          	auipc	a0,0x2
ffffffffc0204cfa:	29250513          	addi	a0,a0,658 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc0204cfe:	f90fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d02:	00002697          	auipc	a3,0x2
ffffffffc0204d06:	51e68693          	addi	a3,a3,1310 # ffffffffc0207220 <default_pmm_manager+0xd08>
ffffffffc0204d0a:	00001617          	auipc	a2,0x1
ffffffffc0204d0e:	45e60613          	addi	a2,a2,1118 # ffffffffc0206168 <commands+0x818>
ffffffffc0204d12:	2e500593          	li	a1,741
ffffffffc0204d16:	00002517          	auipc	a0,0x2
ffffffffc0204d1a:	27250513          	addi	a0,a0,626 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc0204d1e:	f70fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204d22:	00002697          	auipc	a3,0x2
ffffffffc0204d26:	4b668693          	addi	a3,a3,1206 # ffffffffc02071d8 <default_pmm_manager+0xcc0>
ffffffffc0204d2a:	00001617          	auipc	a2,0x1
ffffffffc0204d2e:	43e60613          	addi	a2,a2,1086 # ffffffffc0206168 <commands+0x818>
ffffffffc0204d32:	2e400593          	li	a1,740
ffffffffc0204d36:	00002517          	auipc	a0,0x2
ffffffffc0204d3a:	25250513          	addi	a0,a0,594 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc0204d3e:	f50fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204d42 <do_yield>:
    current->need_resched = 1;
ffffffffc0204d42:	000a6797          	auipc	a5,0xa6
ffffffffc0204d46:	9d67b783          	ld	a5,-1578(a5) # ffffffffc02aa718 <current>
ffffffffc0204d4a:	4705                	li	a4,1
ffffffffc0204d4c:	ef98                	sd	a4,24(a5)
}
ffffffffc0204d4e:	4501                	li	a0,0
ffffffffc0204d50:	8082                	ret

ffffffffc0204d52 <do_wait>:
{
ffffffffc0204d52:	1101                	addi	sp,sp,-32
ffffffffc0204d54:	e822                	sd	s0,16(sp)
ffffffffc0204d56:	e426                	sd	s1,8(sp)
ffffffffc0204d58:	ec06                	sd	ra,24(sp)
ffffffffc0204d5a:	842e                	mv	s0,a1
ffffffffc0204d5c:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204d5e:	c999                	beqz	a1,ffffffffc0204d74 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204d60:	000a6797          	auipc	a5,0xa6
ffffffffc0204d64:	9b87b783          	ld	a5,-1608(a5) # ffffffffc02aa718 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204d68:	7788                	ld	a0,40(a5)
ffffffffc0204d6a:	4685                	li	a3,1
ffffffffc0204d6c:	4611                	li	a2,4
ffffffffc0204d6e:	fb1fe0ef          	jal	ra,ffffffffc0203d1e <user_mem_check>
ffffffffc0204d72:	c909                	beqz	a0,ffffffffc0204d84 <do_wait+0x32>
ffffffffc0204d74:	85a2                	mv	a1,s0
}
ffffffffc0204d76:	6442                	ld	s0,16(sp)
ffffffffc0204d78:	60e2                	ld	ra,24(sp)
ffffffffc0204d7a:	8526                	mv	a0,s1
ffffffffc0204d7c:	64a2                	ld	s1,8(sp)
ffffffffc0204d7e:	6105                	addi	sp,sp,32
ffffffffc0204d80:	fb8ff06f          	j	ffffffffc0204538 <do_wait.part.0>
ffffffffc0204d84:	60e2                	ld	ra,24(sp)
ffffffffc0204d86:	6442                	ld	s0,16(sp)
ffffffffc0204d88:	64a2                	ld	s1,8(sp)
ffffffffc0204d8a:	5575                	li	a0,-3
ffffffffc0204d8c:	6105                	addi	sp,sp,32
ffffffffc0204d8e:	8082                	ret

ffffffffc0204d90 <do_kill>:
{
ffffffffc0204d90:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204d92:	6789                	lui	a5,0x2
{
ffffffffc0204d94:	e406                	sd	ra,8(sp)
ffffffffc0204d96:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204d98:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204d9c:	17f9                	addi	a5,a5,-2
ffffffffc0204d9e:	02e7e963          	bltu	a5,a4,ffffffffc0204dd0 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204da2:	842a                	mv	s0,a0
ffffffffc0204da4:	45a9                	li	a1,10
ffffffffc0204da6:	2501                	sext.w	a0,a0
ffffffffc0204da8:	46c000ef          	jal	ra,ffffffffc0205214 <hash32>
ffffffffc0204dac:	02051793          	slli	a5,a0,0x20
ffffffffc0204db0:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204db4:	000a2797          	auipc	a5,0xa2
ffffffffc0204db8:	8f478793          	addi	a5,a5,-1804 # ffffffffc02a66a8 <hash_list>
ffffffffc0204dbc:	953e                	add	a0,a0,a5
ffffffffc0204dbe:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204dc0:	a029                	j	ffffffffc0204dca <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204dc2:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204dc6:	00870b63          	beq	a4,s0,ffffffffc0204ddc <do_kill+0x4c>
ffffffffc0204dca:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204dcc:	fef51be3          	bne	a0,a5,ffffffffc0204dc2 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204dd0:	5475                	li	s0,-3
}
ffffffffc0204dd2:	60a2                	ld	ra,8(sp)
ffffffffc0204dd4:	8522                	mv	a0,s0
ffffffffc0204dd6:	6402                	ld	s0,0(sp)
ffffffffc0204dd8:	0141                	addi	sp,sp,16
ffffffffc0204dda:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204ddc:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204de0:	00177693          	andi	a3,a4,1
ffffffffc0204de4:	e295                	bnez	a3,ffffffffc0204e08 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204de6:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204de8:	00176713          	ori	a4,a4,1
ffffffffc0204dec:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204df0:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204df2:	fe06d0e3          	bgez	a3,ffffffffc0204dd2 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204df6:	f2878513          	addi	a0,a5,-216
ffffffffc0204dfa:	22e000ef          	jal	ra,ffffffffc0205028 <wakeup_proc>
}
ffffffffc0204dfe:	60a2                	ld	ra,8(sp)
ffffffffc0204e00:	8522                	mv	a0,s0
ffffffffc0204e02:	6402                	ld	s0,0(sp)
ffffffffc0204e04:	0141                	addi	sp,sp,16
ffffffffc0204e06:	8082                	ret
        return -E_KILLED;
ffffffffc0204e08:	545d                	li	s0,-9
ffffffffc0204e0a:	b7e1                	j	ffffffffc0204dd2 <do_kill+0x42>

ffffffffc0204e0c <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204e0c:	1101                	addi	sp,sp,-32
ffffffffc0204e0e:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204e10:	000a6797          	auipc	a5,0xa6
ffffffffc0204e14:	89878793          	addi	a5,a5,-1896 # ffffffffc02aa6a8 <proc_list>
ffffffffc0204e18:	ec06                	sd	ra,24(sp)
ffffffffc0204e1a:	e822                	sd	s0,16(sp)
ffffffffc0204e1c:	e04a                	sd	s2,0(sp)
ffffffffc0204e1e:	000a2497          	auipc	s1,0xa2
ffffffffc0204e22:	88a48493          	addi	s1,s1,-1910 # ffffffffc02a66a8 <hash_list>
ffffffffc0204e26:	e79c                	sd	a5,8(a5)
ffffffffc0204e28:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204e2a:	000a6717          	auipc	a4,0xa6
ffffffffc0204e2e:	87e70713          	addi	a4,a4,-1922 # ffffffffc02aa6a8 <proc_list>
ffffffffc0204e32:	87a6                	mv	a5,s1
ffffffffc0204e34:	e79c                	sd	a5,8(a5)
ffffffffc0204e36:	e39c                	sd	a5,0(a5)
ffffffffc0204e38:	07c1                	addi	a5,a5,16
ffffffffc0204e3a:	fef71de3          	bne	a4,a5,ffffffffc0204e34 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204e3e:	f7dfe0ef          	jal	ra,ffffffffc0203dba <alloc_proc>
ffffffffc0204e42:	000a6917          	auipc	s2,0xa6
ffffffffc0204e46:	8de90913          	addi	s2,s2,-1826 # ffffffffc02aa720 <idleproc>
ffffffffc0204e4a:	00a93023          	sd	a0,0(s2)
ffffffffc0204e4e:	0e050f63          	beqz	a0,ffffffffc0204f4c <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204e52:	4789                	li	a5,2
ffffffffc0204e54:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204e56:	00003797          	auipc	a5,0x3
ffffffffc0204e5a:	1aa78793          	addi	a5,a5,426 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e5e:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204e62:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0204e64:	4785                	li	a5,1
ffffffffc0204e66:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e68:	4641                	li	a2,16
ffffffffc0204e6a:	4581                	li	a1,0
ffffffffc0204e6c:	8522                	mv	a0,s0
ffffffffc0204e6e:	04d000ef          	jal	ra,ffffffffc02056ba <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204e72:	463d                	li	a2,15
ffffffffc0204e74:	00002597          	auipc	a1,0x2
ffffffffc0204e78:	49c58593          	addi	a1,a1,1180 # ffffffffc0207310 <default_pmm_manager+0xdf8>
ffffffffc0204e7c:	8522                	mv	a0,s0
ffffffffc0204e7e:	04f000ef          	jal	ra,ffffffffc02056cc <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204e82:	000a6717          	auipc	a4,0xa6
ffffffffc0204e86:	8ae70713          	addi	a4,a4,-1874 # ffffffffc02aa730 <nr_process>
ffffffffc0204e8a:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0204e8c:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e90:	4601                	li	a2,0
    nr_process++;
ffffffffc0204e92:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e94:	4581                	li	a1,0
ffffffffc0204e96:	00000517          	auipc	a0,0x0
ffffffffc0204e9a:	87450513          	addi	a0,a0,-1932 # ffffffffc020470a <init_main>
    nr_process++;
ffffffffc0204e9e:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0204ea0:	000a6797          	auipc	a5,0xa6
ffffffffc0204ea4:	86d7bc23          	sd	a3,-1928(a5) # ffffffffc02aa718 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204ea8:	cf6ff0ef          	jal	ra,ffffffffc020439e <kernel_thread>
ffffffffc0204eac:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204eae:	08a05363          	blez	a0,ffffffffc0204f34 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204eb2:	6789                	lui	a5,0x2
ffffffffc0204eb4:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204eb8:	17f9                	addi	a5,a5,-2
ffffffffc0204eba:	2501                	sext.w	a0,a0
ffffffffc0204ebc:	02e7e363          	bltu	a5,a4,ffffffffc0204ee2 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204ec0:	45a9                	li	a1,10
ffffffffc0204ec2:	352000ef          	jal	ra,ffffffffc0205214 <hash32>
ffffffffc0204ec6:	02051793          	slli	a5,a0,0x20
ffffffffc0204eca:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204ece:	96a6                	add	a3,a3,s1
ffffffffc0204ed0:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204ed2:	a029                	j	ffffffffc0204edc <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0204ed4:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c7c>
ffffffffc0204ed8:	04870b63          	beq	a4,s0,ffffffffc0204f2e <proc_init+0x122>
    return listelm->next;
ffffffffc0204edc:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204ede:	fef69be3          	bne	a3,a5,ffffffffc0204ed4 <proc_init+0xc8>
    return NULL;
ffffffffc0204ee2:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ee4:	0b478493          	addi	s1,a5,180
ffffffffc0204ee8:	4641                	li	a2,16
ffffffffc0204eea:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204eec:	000a6417          	auipc	s0,0xa6
ffffffffc0204ef0:	83c40413          	addi	s0,s0,-1988 # ffffffffc02aa728 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ef4:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0204ef6:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ef8:	7c2000ef          	jal	ra,ffffffffc02056ba <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204efc:	463d                	li	a2,15
ffffffffc0204efe:	00002597          	auipc	a1,0x2
ffffffffc0204f02:	43a58593          	addi	a1,a1,1082 # ffffffffc0207338 <default_pmm_manager+0xe20>
ffffffffc0204f06:	8526                	mv	a0,s1
ffffffffc0204f08:	7c4000ef          	jal	ra,ffffffffc02056cc <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204f0c:	00093783          	ld	a5,0(s2)
ffffffffc0204f10:	cbb5                	beqz	a5,ffffffffc0204f84 <proc_init+0x178>
ffffffffc0204f12:	43dc                	lw	a5,4(a5)
ffffffffc0204f14:	eba5                	bnez	a5,ffffffffc0204f84 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204f16:	601c                	ld	a5,0(s0)
ffffffffc0204f18:	c7b1                	beqz	a5,ffffffffc0204f64 <proc_init+0x158>
ffffffffc0204f1a:	43d8                	lw	a4,4(a5)
ffffffffc0204f1c:	4785                	li	a5,1
ffffffffc0204f1e:	04f71363          	bne	a4,a5,ffffffffc0204f64 <proc_init+0x158>
}
ffffffffc0204f22:	60e2                	ld	ra,24(sp)
ffffffffc0204f24:	6442                	ld	s0,16(sp)
ffffffffc0204f26:	64a2                	ld	s1,8(sp)
ffffffffc0204f28:	6902                	ld	s2,0(sp)
ffffffffc0204f2a:	6105                	addi	sp,sp,32
ffffffffc0204f2c:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204f2e:	f2878793          	addi	a5,a5,-216
ffffffffc0204f32:	bf4d                	j	ffffffffc0204ee4 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0204f34:	00002617          	auipc	a2,0x2
ffffffffc0204f38:	3e460613          	addi	a2,a2,996 # ffffffffc0207318 <default_pmm_manager+0xe00>
ffffffffc0204f3c:	41300593          	li	a1,1043
ffffffffc0204f40:	00002517          	auipc	a0,0x2
ffffffffc0204f44:	04850513          	addi	a0,a0,72 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc0204f48:	d46fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0204f4c:	00002617          	auipc	a2,0x2
ffffffffc0204f50:	3ac60613          	addi	a2,a2,940 # ffffffffc02072f8 <default_pmm_manager+0xde0>
ffffffffc0204f54:	40400593          	li	a1,1028
ffffffffc0204f58:	00002517          	auipc	a0,0x2
ffffffffc0204f5c:	03050513          	addi	a0,a0,48 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc0204f60:	d2efb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204f64:	00002697          	auipc	a3,0x2
ffffffffc0204f68:	40468693          	addi	a3,a3,1028 # ffffffffc0207368 <default_pmm_manager+0xe50>
ffffffffc0204f6c:	00001617          	auipc	a2,0x1
ffffffffc0204f70:	1fc60613          	addi	a2,a2,508 # ffffffffc0206168 <commands+0x818>
ffffffffc0204f74:	41a00593          	li	a1,1050
ffffffffc0204f78:	00002517          	auipc	a0,0x2
ffffffffc0204f7c:	01050513          	addi	a0,a0,16 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc0204f80:	d0efb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204f84:	00002697          	auipc	a3,0x2
ffffffffc0204f88:	3bc68693          	addi	a3,a3,956 # ffffffffc0207340 <default_pmm_manager+0xe28>
ffffffffc0204f8c:	00001617          	auipc	a2,0x1
ffffffffc0204f90:	1dc60613          	addi	a2,a2,476 # ffffffffc0206168 <commands+0x818>
ffffffffc0204f94:	41900593          	li	a1,1049
ffffffffc0204f98:	00002517          	auipc	a0,0x2
ffffffffc0204f9c:	ff050513          	addi	a0,a0,-16 # ffffffffc0206f88 <default_pmm_manager+0xa70>
ffffffffc0204fa0:	ceefb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204fa4 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0204fa4:	1141                	addi	sp,sp,-16
ffffffffc0204fa6:	e022                	sd	s0,0(sp)
ffffffffc0204fa8:	e406                	sd	ra,8(sp)
ffffffffc0204faa:	000a5417          	auipc	s0,0xa5
ffffffffc0204fae:	76e40413          	addi	s0,s0,1902 # ffffffffc02aa718 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0204fb2:	6018                	ld	a4,0(s0)
ffffffffc0204fb4:	6f1c                	ld	a5,24(a4)
ffffffffc0204fb6:	dffd                	beqz	a5,ffffffffc0204fb4 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0204fb8:	0f0000ef          	jal	ra,ffffffffc02050a8 <schedule>
ffffffffc0204fbc:	bfdd                	j	ffffffffc0204fb2 <cpu_idle+0xe>

ffffffffc0204fbe <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204fbe:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204fc2:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204fc6:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204fc8:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204fca:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204fce:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204fd2:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204fd6:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204fda:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204fde:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204fe2:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204fe6:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204fea:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204fee:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204ff2:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204ff6:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0204ffa:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0204ffc:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0204ffe:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205002:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0205006:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020500a:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc020500e:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205012:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0205016:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020501a:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc020501e:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205022:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0205026:	8082                	ret

ffffffffc0205028 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205028:	4118                	lw	a4,0(a0)
{
ffffffffc020502a:	1101                	addi	sp,sp,-32
ffffffffc020502c:	ec06                	sd	ra,24(sp)
ffffffffc020502e:	e822                	sd	s0,16(sp)
ffffffffc0205030:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205032:	478d                	li	a5,3
ffffffffc0205034:	04f70b63          	beq	a4,a5,ffffffffc020508a <wakeup_proc+0x62>
ffffffffc0205038:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020503a:	100027f3          	csrr	a5,sstatus
ffffffffc020503e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205040:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205042:	ef9d                	bnez	a5,ffffffffc0205080 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205044:	4789                	li	a5,2
ffffffffc0205046:	02f70163          	beq	a4,a5,ffffffffc0205068 <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc020504a:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc020504c:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc0205050:	e491                	bnez	s1,ffffffffc020505c <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205052:	60e2                	ld	ra,24(sp)
ffffffffc0205054:	6442                	ld	s0,16(sp)
ffffffffc0205056:	64a2                	ld	s1,8(sp)
ffffffffc0205058:	6105                	addi	sp,sp,32
ffffffffc020505a:	8082                	ret
ffffffffc020505c:	6442                	ld	s0,16(sp)
ffffffffc020505e:	60e2                	ld	ra,24(sp)
ffffffffc0205060:	64a2                	ld	s1,8(sp)
ffffffffc0205062:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205064:	94bfb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0205068:	00002617          	auipc	a2,0x2
ffffffffc020506c:	36060613          	addi	a2,a2,864 # ffffffffc02073c8 <default_pmm_manager+0xeb0>
ffffffffc0205070:	45d1                	li	a1,20
ffffffffc0205072:	00002517          	auipc	a0,0x2
ffffffffc0205076:	33e50513          	addi	a0,a0,830 # ffffffffc02073b0 <default_pmm_manager+0xe98>
ffffffffc020507a:	c7cfb0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc020507e:	bfc9                	j	ffffffffc0205050 <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205080:	935fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205084:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc0205086:	4485                	li	s1,1
ffffffffc0205088:	bf75                	j	ffffffffc0205044 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020508a:	00002697          	auipc	a3,0x2
ffffffffc020508e:	30668693          	addi	a3,a3,774 # ffffffffc0207390 <default_pmm_manager+0xe78>
ffffffffc0205092:	00001617          	auipc	a2,0x1
ffffffffc0205096:	0d660613          	addi	a2,a2,214 # ffffffffc0206168 <commands+0x818>
ffffffffc020509a:	45a5                	li	a1,9
ffffffffc020509c:	00002517          	auipc	a0,0x2
ffffffffc02050a0:	31450513          	addi	a0,a0,788 # ffffffffc02073b0 <default_pmm_manager+0xe98>
ffffffffc02050a4:	beafb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02050a8 <schedule>:

void schedule(void)
{
ffffffffc02050a8:	1141                	addi	sp,sp,-16
ffffffffc02050aa:	e406                	sd	ra,8(sp)
ffffffffc02050ac:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02050ae:	100027f3          	csrr	a5,sstatus
ffffffffc02050b2:	8b89                	andi	a5,a5,2
ffffffffc02050b4:	4401                	li	s0,0
ffffffffc02050b6:	efbd                	bnez	a5,ffffffffc0205134 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02050b8:	000a5897          	auipc	a7,0xa5
ffffffffc02050bc:	6608b883          	ld	a7,1632(a7) # ffffffffc02aa718 <current>
ffffffffc02050c0:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02050c4:	000a5517          	auipc	a0,0xa5
ffffffffc02050c8:	65c53503          	ld	a0,1628(a0) # ffffffffc02aa720 <idleproc>
ffffffffc02050cc:	04a88e63          	beq	a7,a0,ffffffffc0205128 <schedule+0x80>
ffffffffc02050d0:	0c888693          	addi	a3,a7,200
ffffffffc02050d4:	000a5617          	auipc	a2,0xa5
ffffffffc02050d8:	5d460613          	addi	a2,a2,1492 # ffffffffc02aa6a8 <proc_list>
        le = last;
ffffffffc02050dc:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02050de:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc02050e0:	4809                	li	a6,2
ffffffffc02050e2:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc02050e4:	00c78863          	beq	a5,a2,ffffffffc02050f4 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc02050e8:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02050ec:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc02050f0:	03070163          	beq	a4,a6,ffffffffc0205112 <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc02050f4:	fef697e3          	bne	a3,a5,ffffffffc02050e2 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02050f8:	ed89                	bnez	a1,ffffffffc0205112 <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc02050fa:	451c                	lw	a5,8(a0)
ffffffffc02050fc:	2785                	addiw	a5,a5,1
ffffffffc02050fe:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc0205100:	00a88463          	beq	a7,a0,ffffffffc0205108 <schedule+0x60>
        {
            proc_run(next);
ffffffffc0205104:	e2bfe0ef          	jal	ra,ffffffffc0203f2e <proc_run>
    if (flag)
ffffffffc0205108:	e819                	bnez	s0,ffffffffc020511e <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020510a:	60a2                	ld	ra,8(sp)
ffffffffc020510c:	6402                	ld	s0,0(sp)
ffffffffc020510e:	0141                	addi	sp,sp,16
ffffffffc0205110:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc0205112:	4198                	lw	a4,0(a1)
ffffffffc0205114:	4789                	li	a5,2
ffffffffc0205116:	fef712e3          	bne	a4,a5,ffffffffc02050fa <schedule+0x52>
ffffffffc020511a:	852e                	mv	a0,a1
ffffffffc020511c:	bff9                	j	ffffffffc02050fa <schedule+0x52>
}
ffffffffc020511e:	6402                	ld	s0,0(sp)
ffffffffc0205120:	60a2                	ld	ra,8(sp)
ffffffffc0205122:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0205124:	88bfb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205128:	000a5617          	auipc	a2,0xa5
ffffffffc020512c:	58060613          	addi	a2,a2,1408 # ffffffffc02aa6a8 <proc_list>
ffffffffc0205130:	86b2                	mv	a3,a2
ffffffffc0205132:	b76d                	j	ffffffffc02050dc <schedule+0x34>
        intr_disable();
ffffffffc0205134:	881fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0205138:	4405                	li	s0,1
ffffffffc020513a:	bfbd                	j	ffffffffc02050b8 <schedule+0x10>

ffffffffc020513c <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc020513c:	000a5797          	auipc	a5,0xa5
ffffffffc0205140:	5dc7b783          	ld	a5,1500(a5) # ffffffffc02aa718 <current>
}
ffffffffc0205144:	43c8                	lw	a0,4(a5)
ffffffffc0205146:	8082                	ret

ffffffffc0205148 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0205148:	4501                	li	a0,0
ffffffffc020514a:	8082                	ret

ffffffffc020514c <sys_putc>:
    cputchar(c);
ffffffffc020514c:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc020514e:	1141                	addi	sp,sp,-16
ffffffffc0205150:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205152:	878fb0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc0205156:	60a2                	ld	ra,8(sp)
ffffffffc0205158:	4501                	li	a0,0
ffffffffc020515a:	0141                	addi	sp,sp,16
ffffffffc020515c:	8082                	ret

ffffffffc020515e <sys_kill>:
    return do_kill(pid);
ffffffffc020515e:	4108                	lw	a0,0(a0)
ffffffffc0205160:	c31ff06f          	j	ffffffffc0204d90 <do_kill>

ffffffffc0205164 <sys_yield>:
    return do_yield();
ffffffffc0205164:	bdfff06f          	j	ffffffffc0204d42 <do_yield>

ffffffffc0205168 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0205168:	6d14                	ld	a3,24(a0)
ffffffffc020516a:	6910                	ld	a2,16(a0)
ffffffffc020516c:	650c                	ld	a1,8(a0)
ffffffffc020516e:	6108                	ld	a0,0(a0)
ffffffffc0205170:	ebeff06f          	j	ffffffffc020482e <do_execve>

ffffffffc0205174 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205174:	650c                	ld	a1,8(a0)
ffffffffc0205176:	4108                	lw	a0,0(a0)
ffffffffc0205178:	bdbff06f          	j	ffffffffc0204d52 <do_wait>

ffffffffc020517c <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc020517c:	000a5797          	auipc	a5,0xa5
ffffffffc0205180:	59c7b783          	ld	a5,1436(a5) # ffffffffc02aa718 <current>
ffffffffc0205184:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0205186:	4501                	li	a0,0
ffffffffc0205188:	6a0c                	ld	a1,16(a2)
ffffffffc020518a:	e11fe06f          	j	ffffffffc0203f9a <do_fork>

ffffffffc020518e <sys_exit>:
    return do_exit(error_code);
ffffffffc020518e:	4108                	lw	a0,0(a0)
ffffffffc0205190:	a5eff06f          	j	ffffffffc02043ee <do_exit>

ffffffffc0205194 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc0205194:	715d                	addi	sp,sp,-80
ffffffffc0205196:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205198:	000a5497          	auipc	s1,0xa5
ffffffffc020519c:	58048493          	addi	s1,s1,1408 # ffffffffc02aa718 <current>
ffffffffc02051a0:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc02051a2:	e0a2                	sd	s0,64(sp)
ffffffffc02051a4:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc02051a6:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc02051a8:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02051aa:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc02051ac:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02051b0:	0327ee63          	bltu	a5,s2,ffffffffc02051ec <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc02051b4:	00391713          	slli	a4,s2,0x3
ffffffffc02051b8:	00002797          	auipc	a5,0x2
ffffffffc02051bc:	27878793          	addi	a5,a5,632 # ffffffffc0207430 <syscalls>
ffffffffc02051c0:	97ba                	add	a5,a5,a4
ffffffffc02051c2:	639c                	ld	a5,0(a5)
ffffffffc02051c4:	c785                	beqz	a5,ffffffffc02051ec <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc02051c6:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc02051c8:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc02051ca:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc02051cc:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc02051ce:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc02051d0:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc02051d2:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc02051d4:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc02051d6:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc02051d8:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02051da:	0028                	addi	a0,sp,8
ffffffffc02051dc:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02051de:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02051e0:	e828                	sd	a0,80(s0)
}
ffffffffc02051e2:	6406                	ld	s0,64(sp)
ffffffffc02051e4:	74e2                	ld	s1,56(sp)
ffffffffc02051e6:	7942                	ld	s2,48(sp)
ffffffffc02051e8:	6161                	addi	sp,sp,80
ffffffffc02051ea:	8082                	ret
    print_trapframe(tf);
ffffffffc02051ec:	8522                	mv	a0,s0
ffffffffc02051ee:	9b7fb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02051f2:	609c                	ld	a5,0(s1)
ffffffffc02051f4:	86ca                	mv	a3,s2
ffffffffc02051f6:	00002617          	auipc	a2,0x2
ffffffffc02051fa:	1f260613          	addi	a2,a2,498 # ffffffffc02073e8 <default_pmm_manager+0xed0>
ffffffffc02051fe:	43d8                	lw	a4,4(a5)
ffffffffc0205200:	06200593          	li	a1,98
ffffffffc0205204:	0b478793          	addi	a5,a5,180
ffffffffc0205208:	00002517          	auipc	a0,0x2
ffffffffc020520c:	21050513          	addi	a0,a0,528 # ffffffffc0207418 <default_pmm_manager+0xf00>
ffffffffc0205210:	a7efb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205214 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205214:	9e3707b7          	lui	a5,0x9e370
ffffffffc0205218:	2785                	addiw	a5,a5,1
ffffffffc020521a:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc020521e:	02000793          	li	a5,32
ffffffffc0205222:	9f8d                	subw	a5,a5,a1
}
ffffffffc0205224:	00f5553b          	srlw	a0,a0,a5
ffffffffc0205228:	8082                	ret

ffffffffc020522a <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020522a:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020522e:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0205230:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205234:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0205236:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020523a:	f022                	sd	s0,32(sp)
ffffffffc020523c:	ec26                	sd	s1,24(sp)
ffffffffc020523e:	e84a                	sd	s2,16(sp)
ffffffffc0205240:	f406                	sd	ra,40(sp)
ffffffffc0205242:	e44e                	sd	s3,8(sp)
ffffffffc0205244:	84aa                	mv	s1,a0
ffffffffc0205246:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0205248:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020524c:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020524e:	03067e63          	bgeu	a2,a6,ffffffffc020528a <printnum+0x60>
ffffffffc0205252:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0205254:	00805763          	blez	s0,ffffffffc0205262 <printnum+0x38>
ffffffffc0205258:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020525a:	85ca                	mv	a1,s2
ffffffffc020525c:	854e                	mv	a0,s3
ffffffffc020525e:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205260:	fc65                	bnez	s0,ffffffffc0205258 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205262:	1a02                	slli	s4,s4,0x20
ffffffffc0205264:	00002797          	auipc	a5,0x2
ffffffffc0205268:	2cc78793          	addi	a5,a5,716 # ffffffffc0207530 <syscalls+0x100>
ffffffffc020526c:	020a5a13          	srli	s4,s4,0x20
ffffffffc0205270:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0205272:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205274:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0205278:	70a2                	ld	ra,40(sp)
ffffffffc020527a:	69a2                	ld	s3,8(sp)
ffffffffc020527c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020527e:	85ca                	mv	a1,s2
ffffffffc0205280:	87a6                	mv	a5,s1
}
ffffffffc0205282:	6942                	ld	s2,16(sp)
ffffffffc0205284:	64e2                	ld	s1,24(sp)
ffffffffc0205286:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205288:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020528a:	03065633          	divu	a2,a2,a6
ffffffffc020528e:	8722                	mv	a4,s0
ffffffffc0205290:	f9bff0ef          	jal	ra,ffffffffc020522a <printnum>
ffffffffc0205294:	b7f9                	j	ffffffffc0205262 <printnum+0x38>

ffffffffc0205296 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0205296:	7119                	addi	sp,sp,-128
ffffffffc0205298:	f4a6                	sd	s1,104(sp)
ffffffffc020529a:	f0ca                	sd	s2,96(sp)
ffffffffc020529c:	ecce                	sd	s3,88(sp)
ffffffffc020529e:	e8d2                	sd	s4,80(sp)
ffffffffc02052a0:	e4d6                	sd	s5,72(sp)
ffffffffc02052a2:	e0da                	sd	s6,64(sp)
ffffffffc02052a4:	fc5e                	sd	s7,56(sp)
ffffffffc02052a6:	f06a                	sd	s10,32(sp)
ffffffffc02052a8:	fc86                	sd	ra,120(sp)
ffffffffc02052aa:	f8a2                	sd	s0,112(sp)
ffffffffc02052ac:	f862                	sd	s8,48(sp)
ffffffffc02052ae:	f466                	sd	s9,40(sp)
ffffffffc02052b0:	ec6e                	sd	s11,24(sp)
ffffffffc02052b2:	892a                	mv	s2,a0
ffffffffc02052b4:	84ae                	mv	s1,a1
ffffffffc02052b6:	8d32                	mv	s10,a2
ffffffffc02052b8:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02052ba:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02052be:	5b7d                	li	s6,-1
ffffffffc02052c0:	00002a97          	auipc	s5,0x2
ffffffffc02052c4:	29ca8a93          	addi	s5,s5,668 # ffffffffc020755c <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02052c8:	00002b97          	auipc	s7,0x2
ffffffffc02052cc:	4b0b8b93          	addi	s7,s7,1200 # ffffffffc0207778 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02052d0:	000d4503          	lbu	a0,0(s10)
ffffffffc02052d4:	001d0413          	addi	s0,s10,1
ffffffffc02052d8:	01350a63          	beq	a0,s3,ffffffffc02052ec <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02052dc:	c121                	beqz	a0,ffffffffc020531c <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02052de:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02052e0:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02052e2:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02052e4:	fff44503          	lbu	a0,-1(s0)
ffffffffc02052e8:	ff351ae3          	bne	a0,s3,ffffffffc02052dc <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02052ec:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02052f0:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02052f4:	4c81                	li	s9,0
ffffffffc02052f6:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02052f8:	5c7d                	li	s8,-1
ffffffffc02052fa:	5dfd                	li	s11,-1
ffffffffc02052fc:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0205300:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205302:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205306:	0ff5f593          	zext.b	a1,a1
ffffffffc020530a:	00140d13          	addi	s10,s0,1
ffffffffc020530e:	04b56263          	bltu	a0,a1,ffffffffc0205352 <vprintfmt+0xbc>
ffffffffc0205312:	058a                	slli	a1,a1,0x2
ffffffffc0205314:	95d6                	add	a1,a1,s5
ffffffffc0205316:	4194                	lw	a3,0(a1)
ffffffffc0205318:	96d6                	add	a3,a3,s5
ffffffffc020531a:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020531c:	70e6                	ld	ra,120(sp)
ffffffffc020531e:	7446                	ld	s0,112(sp)
ffffffffc0205320:	74a6                	ld	s1,104(sp)
ffffffffc0205322:	7906                	ld	s2,96(sp)
ffffffffc0205324:	69e6                	ld	s3,88(sp)
ffffffffc0205326:	6a46                	ld	s4,80(sp)
ffffffffc0205328:	6aa6                	ld	s5,72(sp)
ffffffffc020532a:	6b06                	ld	s6,64(sp)
ffffffffc020532c:	7be2                	ld	s7,56(sp)
ffffffffc020532e:	7c42                	ld	s8,48(sp)
ffffffffc0205330:	7ca2                	ld	s9,40(sp)
ffffffffc0205332:	7d02                	ld	s10,32(sp)
ffffffffc0205334:	6de2                	ld	s11,24(sp)
ffffffffc0205336:	6109                	addi	sp,sp,128
ffffffffc0205338:	8082                	ret
            padc = '0';
ffffffffc020533a:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc020533c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205340:	846a                	mv	s0,s10
ffffffffc0205342:	00140d13          	addi	s10,s0,1
ffffffffc0205346:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020534a:	0ff5f593          	zext.b	a1,a1
ffffffffc020534e:	fcb572e3          	bgeu	a0,a1,ffffffffc0205312 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0205352:	85a6                	mv	a1,s1
ffffffffc0205354:	02500513          	li	a0,37
ffffffffc0205358:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020535a:	fff44783          	lbu	a5,-1(s0)
ffffffffc020535e:	8d22                	mv	s10,s0
ffffffffc0205360:	f73788e3          	beq	a5,s3,ffffffffc02052d0 <vprintfmt+0x3a>
ffffffffc0205364:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0205368:	1d7d                	addi	s10,s10,-1
ffffffffc020536a:	ff379de3          	bne	a5,s3,ffffffffc0205364 <vprintfmt+0xce>
ffffffffc020536e:	b78d                	j	ffffffffc02052d0 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0205370:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0205374:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205378:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020537a:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020537e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205382:	02d86463          	bltu	a6,a3,ffffffffc02053aa <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0205386:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020538a:	002c169b          	slliw	a3,s8,0x2
ffffffffc020538e:	0186873b          	addw	a4,a3,s8
ffffffffc0205392:	0017171b          	slliw	a4,a4,0x1
ffffffffc0205396:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0205398:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020539c:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020539e:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02053a2:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02053a6:	fed870e3          	bgeu	a6,a3,ffffffffc0205386 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02053aa:	f40ddce3          	bgez	s11,ffffffffc0205302 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02053ae:	8de2                	mv	s11,s8
ffffffffc02053b0:	5c7d                	li	s8,-1
ffffffffc02053b2:	bf81                	j	ffffffffc0205302 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02053b4:	fffdc693          	not	a3,s11
ffffffffc02053b8:	96fd                	srai	a3,a3,0x3f
ffffffffc02053ba:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053be:	00144603          	lbu	a2,1(s0)
ffffffffc02053c2:	2d81                	sext.w	s11,s11
ffffffffc02053c4:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02053c6:	bf35                	j	ffffffffc0205302 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02053c8:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053cc:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02053d0:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053d2:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02053d4:	bfd9                	j	ffffffffc02053aa <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02053d6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02053d8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02053dc:	01174463          	blt	a4,a7,ffffffffc02053e4 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02053e0:	1a088e63          	beqz	a7,ffffffffc020559c <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02053e4:	000a3603          	ld	a2,0(s4)
ffffffffc02053e8:	46c1                	li	a3,16
ffffffffc02053ea:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02053ec:	2781                	sext.w	a5,a5
ffffffffc02053ee:	876e                	mv	a4,s11
ffffffffc02053f0:	85a6                	mv	a1,s1
ffffffffc02053f2:	854a                	mv	a0,s2
ffffffffc02053f4:	e37ff0ef          	jal	ra,ffffffffc020522a <printnum>
            break;
ffffffffc02053f8:	bde1                	j	ffffffffc02052d0 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02053fa:	000a2503          	lw	a0,0(s4)
ffffffffc02053fe:	85a6                	mv	a1,s1
ffffffffc0205400:	0a21                	addi	s4,s4,8
ffffffffc0205402:	9902                	jalr	s2
            break;
ffffffffc0205404:	b5f1                	j	ffffffffc02052d0 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205406:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205408:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020540c:	01174463          	blt	a4,a7,ffffffffc0205414 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0205410:	18088163          	beqz	a7,ffffffffc0205592 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0205414:	000a3603          	ld	a2,0(s4)
ffffffffc0205418:	46a9                	li	a3,10
ffffffffc020541a:	8a2e                	mv	s4,a1
ffffffffc020541c:	bfc1                	j	ffffffffc02053ec <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020541e:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0205422:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205424:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205426:	bdf1                	j	ffffffffc0205302 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0205428:	85a6                	mv	a1,s1
ffffffffc020542a:	02500513          	li	a0,37
ffffffffc020542e:	9902                	jalr	s2
            break;
ffffffffc0205430:	b545                	j	ffffffffc02052d0 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205432:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0205436:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205438:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020543a:	b5e1                	j	ffffffffc0205302 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc020543c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020543e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205442:	01174463          	blt	a4,a7,ffffffffc020544a <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0205446:	14088163          	beqz	a7,ffffffffc0205588 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc020544a:	000a3603          	ld	a2,0(s4)
ffffffffc020544e:	46a1                	li	a3,8
ffffffffc0205450:	8a2e                	mv	s4,a1
ffffffffc0205452:	bf69                	j	ffffffffc02053ec <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0205454:	03000513          	li	a0,48
ffffffffc0205458:	85a6                	mv	a1,s1
ffffffffc020545a:	e03e                	sd	a5,0(sp)
ffffffffc020545c:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020545e:	85a6                	mv	a1,s1
ffffffffc0205460:	07800513          	li	a0,120
ffffffffc0205464:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205466:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0205468:	6782                	ld	a5,0(sp)
ffffffffc020546a:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020546c:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0205470:	bfb5                	j	ffffffffc02053ec <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205472:	000a3403          	ld	s0,0(s4)
ffffffffc0205476:	008a0713          	addi	a4,s4,8
ffffffffc020547a:	e03a                	sd	a4,0(sp)
ffffffffc020547c:	14040263          	beqz	s0,ffffffffc02055c0 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205480:	0fb05763          	blez	s11,ffffffffc020556e <vprintfmt+0x2d8>
ffffffffc0205484:	02d00693          	li	a3,45
ffffffffc0205488:	0cd79163          	bne	a5,a3,ffffffffc020554a <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020548c:	00044783          	lbu	a5,0(s0)
ffffffffc0205490:	0007851b          	sext.w	a0,a5
ffffffffc0205494:	cf85                	beqz	a5,ffffffffc02054cc <vprintfmt+0x236>
ffffffffc0205496:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020549a:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020549e:	000c4563          	bltz	s8,ffffffffc02054a8 <vprintfmt+0x212>
ffffffffc02054a2:	3c7d                	addiw	s8,s8,-1
ffffffffc02054a4:	036c0263          	beq	s8,s6,ffffffffc02054c8 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02054a8:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02054aa:	0e0c8e63          	beqz	s9,ffffffffc02055a6 <vprintfmt+0x310>
ffffffffc02054ae:	3781                	addiw	a5,a5,-32
ffffffffc02054b0:	0ef47b63          	bgeu	s0,a5,ffffffffc02055a6 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02054b4:	03f00513          	li	a0,63
ffffffffc02054b8:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02054ba:	000a4783          	lbu	a5,0(s4)
ffffffffc02054be:	3dfd                	addiw	s11,s11,-1
ffffffffc02054c0:	0a05                	addi	s4,s4,1
ffffffffc02054c2:	0007851b          	sext.w	a0,a5
ffffffffc02054c6:	ffe1                	bnez	a5,ffffffffc020549e <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02054c8:	01b05963          	blez	s11,ffffffffc02054da <vprintfmt+0x244>
ffffffffc02054cc:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02054ce:	85a6                	mv	a1,s1
ffffffffc02054d0:	02000513          	li	a0,32
ffffffffc02054d4:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02054d6:	fe0d9be3          	bnez	s11,ffffffffc02054cc <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02054da:	6a02                	ld	s4,0(sp)
ffffffffc02054dc:	bbd5                	j	ffffffffc02052d0 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02054de:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02054e0:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02054e4:	01174463          	blt	a4,a7,ffffffffc02054ec <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02054e8:	08088d63          	beqz	a7,ffffffffc0205582 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02054ec:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02054f0:	0a044d63          	bltz	s0,ffffffffc02055aa <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02054f4:	8622                	mv	a2,s0
ffffffffc02054f6:	8a66                	mv	s4,s9
ffffffffc02054f8:	46a9                	li	a3,10
ffffffffc02054fa:	bdcd                	j	ffffffffc02053ec <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02054fc:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205500:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc0205502:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205504:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0205508:	8fb5                	xor	a5,a5,a3
ffffffffc020550a:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020550e:	02d74163          	blt	a4,a3,ffffffffc0205530 <vprintfmt+0x29a>
ffffffffc0205512:	00369793          	slli	a5,a3,0x3
ffffffffc0205516:	97de                	add	a5,a5,s7
ffffffffc0205518:	639c                	ld	a5,0(a5)
ffffffffc020551a:	cb99                	beqz	a5,ffffffffc0205530 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc020551c:	86be                	mv	a3,a5
ffffffffc020551e:	00000617          	auipc	a2,0x0
ffffffffc0205522:	1f260613          	addi	a2,a2,498 # ffffffffc0205710 <etext+0x2c>
ffffffffc0205526:	85a6                	mv	a1,s1
ffffffffc0205528:	854a                	mv	a0,s2
ffffffffc020552a:	0ce000ef          	jal	ra,ffffffffc02055f8 <printfmt>
ffffffffc020552e:	b34d                	j	ffffffffc02052d0 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205530:	00002617          	auipc	a2,0x2
ffffffffc0205534:	02060613          	addi	a2,a2,32 # ffffffffc0207550 <syscalls+0x120>
ffffffffc0205538:	85a6                	mv	a1,s1
ffffffffc020553a:	854a                	mv	a0,s2
ffffffffc020553c:	0bc000ef          	jal	ra,ffffffffc02055f8 <printfmt>
ffffffffc0205540:	bb41                	j	ffffffffc02052d0 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0205542:	00002417          	auipc	s0,0x2
ffffffffc0205546:	00640413          	addi	s0,s0,6 # ffffffffc0207548 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020554a:	85e2                	mv	a1,s8
ffffffffc020554c:	8522                	mv	a0,s0
ffffffffc020554e:	e43e                	sd	a5,8(sp)
ffffffffc0205550:	0e2000ef          	jal	ra,ffffffffc0205632 <strnlen>
ffffffffc0205554:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0205558:	01b05b63          	blez	s11,ffffffffc020556e <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc020555c:	67a2                	ld	a5,8(sp)
ffffffffc020555e:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205562:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0205564:	85a6                	mv	a1,s1
ffffffffc0205566:	8552                	mv	a0,s4
ffffffffc0205568:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020556a:	fe0d9ce3          	bnez	s11,ffffffffc0205562 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020556e:	00044783          	lbu	a5,0(s0)
ffffffffc0205572:	00140a13          	addi	s4,s0,1
ffffffffc0205576:	0007851b          	sext.w	a0,a5
ffffffffc020557a:	d3a5                	beqz	a5,ffffffffc02054da <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020557c:	05e00413          	li	s0,94
ffffffffc0205580:	bf39                	j	ffffffffc020549e <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205582:	000a2403          	lw	s0,0(s4)
ffffffffc0205586:	b7ad                	j	ffffffffc02054f0 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0205588:	000a6603          	lwu	a2,0(s4)
ffffffffc020558c:	46a1                	li	a3,8
ffffffffc020558e:	8a2e                	mv	s4,a1
ffffffffc0205590:	bdb1                	j	ffffffffc02053ec <vprintfmt+0x156>
ffffffffc0205592:	000a6603          	lwu	a2,0(s4)
ffffffffc0205596:	46a9                	li	a3,10
ffffffffc0205598:	8a2e                	mv	s4,a1
ffffffffc020559a:	bd89                	j	ffffffffc02053ec <vprintfmt+0x156>
ffffffffc020559c:	000a6603          	lwu	a2,0(s4)
ffffffffc02055a0:	46c1                	li	a3,16
ffffffffc02055a2:	8a2e                	mv	s4,a1
ffffffffc02055a4:	b5a1                	j	ffffffffc02053ec <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02055a6:	9902                	jalr	s2
ffffffffc02055a8:	bf09                	j	ffffffffc02054ba <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02055aa:	85a6                	mv	a1,s1
ffffffffc02055ac:	02d00513          	li	a0,45
ffffffffc02055b0:	e03e                	sd	a5,0(sp)
ffffffffc02055b2:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02055b4:	6782                	ld	a5,0(sp)
ffffffffc02055b6:	8a66                	mv	s4,s9
ffffffffc02055b8:	40800633          	neg	a2,s0
ffffffffc02055bc:	46a9                	li	a3,10
ffffffffc02055be:	b53d                	j	ffffffffc02053ec <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02055c0:	03b05163          	blez	s11,ffffffffc02055e2 <vprintfmt+0x34c>
ffffffffc02055c4:	02d00693          	li	a3,45
ffffffffc02055c8:	f6d79de3          	bne	a5,a3,ffffffffc0205542 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02055cc:	00002417          	auipc	s0,0x2
ffffffffc02055d0:	f7c40413          	addi	s0,s0,-132 # ffffffffc0207548 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055d4:	02800793          	li	a5,40
ffffffffc02055d8:	02800513          	li	a0,40
ffffffffc02055dc:	00140a13          	addi	s4,s0,1
ffffffffc02055e0:	bd6d                	j	ffffffffc020549a <vprintfmt+0x204>
ffffffffc02055e2:	00002a17          	auipc	s4,0x2
ffffffffc02055e6:	f67a0a13          	addi	s4,s4,-153 # ffffffffc0207549 <syscalls+0x119>
ffffffffc02055ea:	02800513          	li	a0,40
ffffffffc02055ee:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02055f2:	05e00413          	li	s0,94
ffffffffc02055f6:	b565                	j	ffffffffc020549e <vprintfmt+0x208>

ffffffffc02055f8 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02055f8:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02055fa:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02055fe:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205600:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205602:	ec06                	sd	ra,24(sp)
ffffffffc0205604:	f83a                	sd	a4,48(sp)
ffffffffc0205606:	fc3e                	sd	a5,56(sp)
ffffffffc0205608:	e0c2                	sd	a6,64(sp)
ffffffffc020560a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020560c:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020560e:	c89ff0ef          	jal	ra,ffffffffc0205296 <vprintfmt>
}
ffffffffc0205612:	60e2                	ld	ra,24(sp)
ffffffffc0205614:	6161                	addi	sp,sp,80
ffffffffc0205616:	8082                	ret

ffffffffc0205618 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0205618:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc020561c:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc020561e:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0205620:	cb81                	beqz	a5,ffffffffc0205630 <strlen+0x18>
        cnt ++;
ffffffffc0205622:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0205624:	00a707b3          	add	a5,a4,a0
ffffffffc0205628:	0007c783          	lbu	a5,0(a5)
ffffffffc020562c:	fbfd                	bnez	a5,ffffffffc0205622 <strlen+0xa>
ffffffffc020562e:	8082                	ret
    }
    return cnt;
}
ffffffffc0205630:	8082                	ret

ffffffffc0205632 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0205632:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205634:	e589                	bnez	a1,ffffffffc020563e <strnlen+0xc>
ffffffffc0205636:	a811                	j	ffffffffc020564a <strnlen+0x18>
        cnt ++;
ffffffffc0205638:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020563a:	00f58863          	beq	a1,a5,ffffffffc020564a <strnlen+0x18>
ffffffffc020563e:	00f50733          	add	a4,a0,a5
ffffffffc0205642:	00074703          	lbu	a4,0(a4)
ffffffffc0205646:	fb6d                	bnez	a4,ffffffffc0205638 <strnlen+0x6>
ffffffffc0205648:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020564a:	852e                	mv	a0,a1
ffffffffc020564c:	8082                	ret

ffffffffc020564e <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc020564e:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205650:	0005c703          	lbu	a4,0(a1)
ffffffffc0205654:	0785                	addi	a5,a5,1
ffffffffc0205656:	0585                	addi	a1,a1,1
ffffffffc0205658:	fee78fa3          	sb	a4,-1(a5)
ffffffffc020565c:	fb75                	bnez	a4,ffffffffc0205650 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc020565e:	8082                	ret

ffffffffc0205660 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205660:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205664:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205668:	cb89                	beqz	a5,ffffffffc020567a <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc020566a:	0505                	addi	a0,a0,1
ffffffffc020566c:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020566e:	fee789e3          	beq	a5,a4,ffffffffc0205660 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205672:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0205676:	9d19                	subw	a0,a0,a4
ffffffffc0205678:	8082                	ret
ffffffffc020567a:	4501                	li	a0,0
ffffffffc020567c:	bfed                	j	ffffffffc0205676 <strcmp+0x16>

ffffffffc020567e <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020567e:	c20d                	beqz	a2,ffffffffc02056a0 <strncmp+0x22>
ffffffffc0205680:	962e                	add	a2,a2,a1
ffffffffc0205682:	a031                	j	ffffffffc020568e <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0205684:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205686:	00e79a63          	bne	a5,a4,ffffffffc020569a <strncmp+0x1c>
ffffffffc020568a:	00b60b63          	beq	a2,a1,ffffffffc02056a0 <strncmp+0x22>
ffffffffc020568e:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205692:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205694:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0205698:	f7f5                	bnez	a5,ffffffffc0205684 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020569a:	40e7853b          	subw	a0,a5,a4
}
ffffffffc020569e:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02056a0:	4501                	li	a0,0
ffffffffc02056a2:	8082                	ret

ffffffffc02056a4 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02056a4:	00054783          	lbu	a5,0(a0)
ffffffffc02056a8:	c799                	beqz	a5,ffffffffc02056b6 <strchr+0x12>
        if (*s == c) {
ffffffffc02056aa:	00f58763          	beq	a1,a5,ffffffffc02056b8 <strchr+0x14>
    while (*s != '\0') {
ffffffffc02056ae:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc02056b2:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02056b4:	fbfd                	bnez	a5,ffffffffc02056aa <strchr+0x6>
    }
    return NULL;
ffffffffc02056b6:	4501                	li	a0,0
}
ffffffffc02056b8:	8082                	ret

ffffffffc02056ba <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02056ba:	ca01                	beqz	a2,ffffffffc02056ca <memset+0x10>
ffffffffc02056bc:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02056be:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02056c0:	0785                	addi	a5,a5,1
ffffffffc02056c2:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02056c6:	fec79de3          	bne	a5,a2,ffffffffc02056c0 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02056ca:	8082                	ret

ffffffffc02056cc <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02056cc:	ca19                	beqz	a2,ffffffffc02056e2 <memcpy+0x16>
ffffffffc02056ce:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc02056d0:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02056d2:	0005c703          	lbu	a4,0(a1)
ffffffffc02056d6:	0585                	addi	a1,a1,1
ffffffffc02056d8:	0785                	addi	a5,a5,1
ffffffffc02056da:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02056de:	fec59ae3          	bne	a1,a2,ffffffffc02056d2 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02056e2:	8082                	ret
