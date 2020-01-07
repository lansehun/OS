
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
}*/
//>>>>>>> lab1

void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 79 11 f0       	mov    $0xf0117970,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 73 11 f0 	movl   $0xf0117300,(%esp)
f0100063:	e8 cf 38 00 00       	call   f0103937 <memset>
	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 bd 04 00 00       	call   f010052a <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 e0 3d 10 f0 	movl   $0xf0103de0,(%esp)
f010007c:	e8 49 2d 00 00       	call   f0102dca <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 5d 11 00 00       	call   f01011e3 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 a2 07 00 00       	call   f0100834 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 60 79 11 f0 00 	cmpl   $0x0,0xf0117960
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 60 79 11 f0    	mov    %esi,0xf0117960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 fb 3d 10 f0 	movl   $0xf0103dfb,(%esp)
f01000c8:	e8 fd 2c 00 00       	call   f0102dca <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 be 2c 00 00       	call   f0102d97 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 df 43 10 f0 	movl   $0xf01043df,(%esp)
f01000e0:	e8 e5 2c 00 00       	call   f0102dca <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 43 07 00 00       	call   f0100834 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 13 3e 10 f0 	movl   $0xf0103e13,(%esp)
f0100112:	e8 b3 2c 00 00       	call   f0102dca <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 71 2c 00 00       	call   f0102d97 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 df 43 10 f0 	movl   $0xf01043df,(%esp)
f010012d:	e8 98 2c 00 00       	call   f0102dca <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
f0100138:	66 90                	xchg   %ax,%ax
f010013a:	66 90                	xchg   %ax,%ax
f010013c:	66 90                	xchg   %ax,%ax
f010013e:	66 90                	xchg   %ax,%ax

f0100140 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100148:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100149:	a8 01                	test   $0x1,%al
f010014b:	74 08                	je     f0100155 <serial_proc_data+0x15>
f010014d:	b2 f8                	mov    $0xf8,%dl
f010014f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100150:	0f b6 c0             	movzbl %al,%eax
f0100153:	eb 05                	jmp    f010015a <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100155:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010015a:	5d                   	pop    %ebp
f010015b:	c3                   	ret    

f010015c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010015c:	55                   	push   %ebp
f010015d:	89 e5                	mov    %esp,%ebp
f010015f:	53                   	push   %ebx
f0100160:	83 ec 04             	sub    $0x4,%esp
f0100163:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100165:	eb 2a                	jmp    f0100191 <cons_intr+0x35>
		if (c == 0)
f0100167:	85 d2                	test   %edx,%edx
f0100169:	74 26                	je     f0100191 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010016b:	a1 24 75 11 f0       	mov    0xf0117524,%eax
f0100170:	8d 48 01             	lea    0x1(%eax),%ecx
f0100173:	89 0d 24 75 11 f0    	mov    %ecx,0xf0117524
f0100179:	88 90 20 73 11 f0    	mov    %dl,-0xfee8ce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010017f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100185:	75 0a                	jne    f0100191 <cons_intr+0x35>
			cons.wpos = 0;
f0100187:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f010018e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100191:	ff d3                	call   *%ebx
f0100193:	89 c2                	mov    %eax,%edx
f0100195:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100198:	75 cd                	jne    f0100167 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010019a:	83 c4 04             	add    $0x4,%esp
f010019d:	5b                   	pop    %ebx
f010019e:	5d                   	pop    %ebp
f010019f:	c3                   	ret    

f01001a0 <kbd_proc_data>:
f01001a0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001a5:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001a6:	a8 01                	test   $0x1,%al
f01001a8:	0f 84 ef 00 00 00    	je     f010029d <kbd_proc_data+0xfd>
f01001ae:	b2 60                	mov    $0x60,%dl
f01001b0:	ec                   	in     (%dx),%al
f01001b1:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001b3:	3c e0                	cmp    $0xe0,%al
f01001b5:	75 0d                	jne    f01001c4 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001b7:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f01001be:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001c3:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001c4:	55                   	push   %ebp
f01001c5:	89 e5                	mov    %esp,%ebp
f01001c7:	53                   	push   %ebx
f01001c8:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001cb:	84 c0                	test   %al,%al
f01001cd:	79 37                	jns    f0100206 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001cf:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001d5:	89 cb                	mov    %ecx,%ebx
f01001d7:	83 e3 40             	and    $0x40,%ebx
f01001da:	83 e0 7f             	and    $0x7f,%eax
f01001dd:	85 db                	test   %ebx,%ebx
f01001df:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e2:	0f b6 d2             	movzbl %dl,%edx
f01001e5:	0f b6 82 80 3f 10 f0 	movzbl -0xfefc080(%edx),%eax
f01001ec:	83 c8 40             	or     $0x40,%eax
f01001ef:	0f b6 c0             	movzbl %al,%eax
f01001f2:	f7 d0                	not    %eax
f01001f4:	21 c1                	and    %eax,%ecx
f01001f6:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
		return 0;
f01001fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100201:	e9 9d 00 00 00       	jmp    f01002a3 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100206:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f010020c:	f6 c1 40             	test   $0x40,%cl
f010020f:	74 0e                	je     f010021f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100211:	83 c8 80             	or     $0xffffff80,%eax
f0100214:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100216:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100219:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f010021f:	0f b6 d2             	movzbl %dl,%edx
f0100222:	0f b6 82 80 3f 10 f0 	movzbl -0xfefc080(%edx),%eax
f0100229:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
	shift ^= togglecode[data];
f010022f:	0f b6 8a 80 3e 10 f0 	movzbl -0xfefc180(%edx),%ecx
f0100236:	31 c8                	xor    %ecx,%eax
f0100238:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f010023d:	89 c1                	mov    %eax,%ecx
f010023f:	83 e1 03             	and    $0x3,%ecx
f0100242:	8b 0c 8d 60 3e 10 f0 	mov    -0xfefc1a0(,%ecx,4),%ecx
f0100249:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010024d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100250:	a8 08                	test   $0x8,%al
f0100252:	74 1b                	je     f010026f <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f0100254:	89 da                	mov    %ebx,%edx
f0100256:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100259:	83 f9 19             	cmp    $0x19,%ecx
f010025c:	77 05                	ja     f0100263 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f010025e:	83 eb 20             	sub    $0x20,%ebx
f0100261:	eb 0c                	jmp    f010026f <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f0100263:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100266:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100269:	83 fa 19             	cmp    $0x19,%edx
f010026c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010026f:	f7 d0                	not    %eax
f0100271:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100273:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100275:	f6 c2 06             	test   $0x6,%dl
f0100278:	75 29                	jne    f01002a3 <kbd_proc_data+0x103>
f010027a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100280:	75 21                	jne    f01002a3 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f0100282:	c7 04 24 2d 3e 10 f0 	movl   $0xf0103e2d,(%esp)
f0100289:	e8 3c 2b 00 00       	call   f0102dca <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010028e:	ba 92 00 00 00       	mov    $0x92,%edx
f0100293:	b8 03 00 00 00       	mov    $0x3,%eax
f0100298:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100299:	89 d8                	mov    %ebx,%eax
f010029b:	eb 06                	jmp    f01002a3 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010029d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002a2:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002a3:	83 c4 14             	add    $0x14,%esp
f01002a6:	5b                   	pop    %ebx
f01002a7:	5d                   	pop    %ebp
f01002a8:	c3                   	ret    

f01002a9 <cons_putc>:

// output a character to the console
//将一个字符输出到控制台
static void
cons_putc(int c)
{
f01002a9:	55                   	push   %ebp
f01002aa:	89 e5                	mov    %esp,%ebp
f01002ac:	57                   	push   %edi
f01002ad:	56                   	push   %esi
f01002ae:	53                   	push   %ebx
f01002af:	83 ec 1c             	sub    $0x1c,%esp
f01002b2:	89 c7                	mov    %eax,%edi
f01002b4:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002b9:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002be:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002c3:	eb 06                	jmp    f01002cb <cons_putc+0x22>
f01002c5:	89 ca                	mov    %ecx,%edx
f01002c7:	ec                   	in     (%dx),%al
f01002c8:	ec                   	in     (%dx),%al
f01002c9:	ec                   	in     (%dx),%al
f01002ca:	ec                   	in     (%dx),%al
f01002cb:	89 f2                	mov    %esi,%edx
f01002cd:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ce:	a8 20                	test   $0x20,%al
f01002d0:	75 05                	jne    f01002d7 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002d2:	83 eb 01             	sub    $0x1,%ebx
f01002d5:	75 ee                	jne    f01002c5 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01002d7:	89 f8                	mov    %edi,%eax
f01002d9:	0f b6 c0             	movzbl %al,%eax
f01002dc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002df:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002e4:	ee                   	out    %al,(%dx)
f01002e5:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ea:	be 79 03 00 00       	mov    $0x379,%esi
f01002ef:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002f4:	eb 06                	jmp    f01002fc <cons_putc+0x53>
f01002f6:	89 ca                	mov    %ecx,%edx
f01002f8:	ec                   	in     (%dx),%al
f01002f9:	ec                   	in     (%dx),%al
f01002fa:	ec                   	in     (%dx),%al
f01002fb:	ec                   	in     (%dx),%al
f01002fc:	89 f2                	mov    %esi,%edx
f01002fe:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002ff:	84 c0                	test   %al,%al
f0100301:	78 05                	js     f0100308 <cons_putc+0x5f>
f0100303:	83 eb 01             	sub    $0x1,%ebx
f0100306:	75 ee                	jne    f01002f6 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100308:	ba 78 03 00 00       	mov    $0x378,%edx
f010030d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100311:	ee                   	out    %al,(%dx)
f0100312:	b2 7a                	mov    $0x7a,%dl
f0100314:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100319:	ee                   	out    %al,(%dx)
f010031a:	b8 08 00 00 00       	mov    $0x8,%eax
f010031f:	ee                   	out    %al,(%dx)
static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	//如果没有给出属性，则在白色上使用黑色
	if (!(c & ~0xFF)) 
f0100320:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f0100326:	75 34                	jne    f010035c <cons_putc+0xb3>
	{
   		 char ch = c & 0x0FF;
   		 if (ch > 47 && ch < 58) 
f0100328:	89 fa                	mov    %edi,%edx
f010032a:	8d 47 d0             	lea    -0x30(%edi),%eax
f010032d:	3c 09                	cmp    $0x9,%al
f010032f:	77 08                	ja     f0100339 <cons_putc+0x90>
		 { 
     		    c |= 0x0800;
f0100331:	81 cf 00 08 00 00    	or     $0x800,%edi
f0100337:	eb 23                	jmp    f010035c <cons_putc+0xb3>
    		 } 
		 else if (ch > 64 && ch < 91) 
f0100339:	8d 47 bf             	lea    -0x41(%edi),%eax
f010033c:	3c 19                	cmp    $0x19,%al
f010033e:	77 08                	ja     f0100348 <cons_putc+0x9f>
		 {
     		    c |= 0x0700;
f0100340:	81 cf 00 07 00 00    	or     $0x700,%edi
f0100346:	eb 14                	jmp    f010035c <cons_putc+0xb3>
    		 } 
 		 else if (ch > 96 && ch < 123) 
f0100348:	83 ea 61             	sub    $0x61,%edx
		 {
                    c |= 0x0a00;
f010034b:	89 f8                	mov    %edi,%eax
f010034d:	80 cc 0a             	or     $0xa,%ah
f0100350:	81 cf 00 01 00 00    	or     $0x100,%edi
f0100356:	80 fa 19             	cmp    $0x19,%dl
f0100359:	0f 46 f8             	cmovbe %eax,%edi
		 else 
		 {
        	    c |= 0x0100;
    		 }
	}
	switch (c & 0xff) {
f010035c:	89 f8                	mov    %edi,%eax
f010035e:	0f b6 c0             	movzbl %al,%eax
f0100361:	83 f8 09             	cmp    $0x9,%eax
f0100364:	74 77                	je     f01003dd <cons_putc+0x134>
f0100366:	83 f8 09             	cmp    $0x9,%eax
f0100369:	7f 0a                	jg     f0100375 <cons_putc+0xcc>
f010036b:	83 f8 08             	cmp    $0x8,%eax
f010036e:	74 17                	je     f0100387 <cons_putc+0xde>
f0100370:	e9 9c 00 00 00       	jmp    f0100411 <cons_putc+0x168>
f0100375:	83 f8 0a             	cmp    $0xa,%eax
f0100378:	74 3d                	je     f01003b7 <cons_putc+0x10e>
f010037a:	83 f8 0d             	cmp    $0xd,%eax
f010037d:	8d 76 00             	lea    0x0(%esi),%esi
f0100380:	74 3d                	je     f01003bf <cons_putc+0x116>
f0100382:	e9 8a 00 00 00       	jmp    f0100411 <cons_putc+0x168>
	case '\b':
		if (crt_pos > 0) {
f0100387:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f010038e:	66 85 c0             	test   %ax,%ax
f0100391:	0f 84 e5 00 00 00    	je     f010047c <cons_putc+0x1d3>
			crt_pos--;
f0100397:	83 e8 01             	sub    $0x1,%eax
f010039a:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003a0:	0f b7 c0             	movzwl %ax,%eax
f01003a3:	66 81 e7 00 ff       	and    $0xff00,%di
f01003a8:	83 cf 20             	or     $0x20,%edi
f01003ab:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f01003b1:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003b5:	eb 78                	jmp    f010042f <cons_putc+0x186>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003b7:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f01003be:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003bf:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003c6:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003cc:	c1 e8 16             	shr    $0x16,%eax
f01003cf:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003d2:	c1 e0 04             	shl    $0x4,%eax
f01003d5:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
f01003db:	eb 52                	jmp    f010042f <cons_putc+0x186>
		break;
	case '\t':
		cons_putc(' ');
f01003dd:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e2:	e8 c2 fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003e7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ec:	e8 b8 fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003f1:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f6:	e8 ae fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003fb:	b8 20 00 00 00       	mov    $0x20,%eax
f0100400:	e8 a4 fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f0100405:	b8 20 00 00 00       	mov    $0x20,%eax
f010040a:	e8 9a fe ff ff       	call   f01002a9 <cons_putc>
f010040f:	eb 1e                	jmp    f010042f <cons_putc+0x186>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100411:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100418:	8d 50 01             	lea    0x1(%eax),%edx
f010041b:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f0100422:	0f b7 c0             	movzwl %ax,%eax
f0100425:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f010042b:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010042f:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f0100436:	cf 07 
f0100438:	76 42                	jbe    f010047c <cons_putc+0x1d3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010043a:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f010043f:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100446:	00 
f0100447:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010044d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100451:	89 04 24             	mov    %eax,(%esp)
f0100454:	e8 2b 35 00 00       	call   f0103984 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100459:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010045f:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100464:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010046a:	83 c0 01             	add    $0x1,%eax
f010046d:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100472:	75 f0                	jne    f0100464 <cons_putc+0x1bb>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100474:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f010047b:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010047c:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100482:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100487:	89 ca                	mov    %ecx,%edx
f0100489:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010048a:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
f0100491:	8d 71 01             	lea    0x1(%ecx),%esi
f0100494:	89 d8                	mov    %ebx,%eax
f0100496:	66 c1 e8 08          	shr    $0x8,%ax
f010049a:	89 f2                	mov    %esi,%edx
f010049c:	ee                   	out    %al,(%dx)
f010049d:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004a2:	89 ca                	mov    %ecx,%edx
f01004a4:	ee                   	out    %al,(%dx)
f01004a5:	89 d8                	mov    %ebx,%eax
f01004a7:	89 f2                	mov    %esi,%edx
f01004a9:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);//把一个字符输出给串口
	lpt_putc(c);//把一个字符输出给并口
	cga_putc(c);//把字符输出到cga（彩色适配器，即显示器）上
}
f01004aa:	83 c4 1c             	add    $0x1c,%esp
f01004ad:	5b                   	pop    %ebx
f01004ae:	5e                   	pop    %esi
f01004af:	5f                   	pop    %edi
f01004b0:	5d                   	pop    %ebp
f01004b1:	c3                   	ret    

f01004b2 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004b2:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f01004b9:	74 11                	je     f01004cc <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004bb:	55                   	push   %ebp
f01004bc:	89 e5                	mov    %esp,%ebp
f01004be:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004c1:	b8 40 01 10 f0       	mov    $0xf0100140,%eax
f01004c6:	e8 91 fc ff ff       	call   f010015c <cons_intr>
}
f01004cb:	c9                   	leave  
f01004cc:	f3 c3                	repz ret 

f01004ce <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004ce:	55                   	push   %ebp
f01004cf:	89 e5                	mov    %esp,%ebp
f01004d1:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004d4:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004d9:	e8 7e fc ff ff       	call   f010015c <cons_intr>
}
f01004de:	c9                   	leave  
f01004df:	c3                   	ret    

f01004e0 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004e0:	55                   	push   %ebp
f01004e1:	89 e5                	mov    %esp,%ebp
f01004e3:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004e6:	e8 c7 ff ff ff       	call   f01004b2 <serial_intr>
	kbd_intr();
f01004eb:	e8 de ff ff ff       	call   f01004ce <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004f0:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004f5:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004fb:	74 26                	je     f0100523 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004fd:	8d 50 01             	lea    0x1(%eax),%edx
f0100500:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f0100506:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f010050d:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010050f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100515:	75 11                	jne    f0100528 <cons_getc+0x48>
			cons.rpos = 0;
f0100517:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f010051e:	00 00 00 
f0100521:	eb 05                	jmp    f0100528 <cons_getc+0x48>
		return c;
	}
	return 0;
f0100523:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100528:	c9                   	leave  
f0100529:	c3                   	ret    

f010052a <cons_init>:
// initialize the console device
//初始化控制台设备

void
cons_init(void)
{
f010052a:	55                   	push   %ebp
f010052b:	89 e5                	mov    %esp,%ebp
f010052d:	57                   	push   %edi
f010052e:	56                   	push   %esi
f010052f:	53                   	push   %ebx
f0100530:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100533:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010053a:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100541:	5a a5 
	if (*cp != 0xA55A) {
f0100543:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010054a:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010054e:	74 11                	je     f0100561 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100550:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f0100557:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010055a:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f010055f:	eb 16                	jmp    f0100577 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100561:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100568:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f010056f:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100572:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100577:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f010057d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100582:	89 ca                	mov    %ecx,%edx
f0100584:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100585:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100588:	89 da                	mov    %ebx,%edx
f010058a:	ec                   	in     (%dx),%al
f010058b:	0f b6 f0             	movzbl %al,%esi
f010058e:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100591:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100596:	89 ca                	mov    %ecx,%edx
f0100598:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100599:	89 da                	mov    %ebx,%edx
f010059b:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010059c:	89 3d 2c 75 11 f0    	mov    %edi,0xf011752c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005a2:	0f b6 d8             	movzbl %al,%ebx
f01005a5:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005a7:	66 89 35 28 75 11 f0 	mov    %si,0xf0117528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ae:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005b3:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b8:	89 f2                	mov    %esi,%edx
f01005ba:	ee                   	out    %al,(%dx)
f01005bb:	b2 fb                	mov    $0xfb,%dl
f01005bd:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005c2:	ee                   	out    %al,(%dx)
f01005c3:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005c8:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005cd:	89 da                	mov    %ebx,%edx
f01005cf:	ee                   	out    %al,(%dx)
f01005d0:	b2 f9                	mov    $0xf9,%dl
f01005d2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d7:	ee                   	out    %al,(%dx)
f01005d8:	b2 fb                	mov    $0xfb,%dl
f01005da:	b8 03 00 00 00       	mov    $0x3,%eax
f01005df:	ee                   	out    %al,(%dx)
f01005e0:	b2 fc                	mov    $0xfc,%dl
f01005e2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e7:	ee                   	out    %al,(%dx)
f01005e8:	b2 f9                	mov    $0xf9,%dl
f01005ea:	b8 01 00 00 00       	mov    $0x1,%eax
f01005ef:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005f0:	b2 fd                	mov    $0xfd,%dl
f01005f2:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005f3:	3c ff                	cmp    $0xff,%al
f01005f5:	0f 95 c1             	setne  %cl
f01005f8:	88 0d 34 75 11 f0    	mov    %cl,0xf0117534
f01005fe:	89 f2                	mov    %esi,%edx
f0100600:	ec                   	in     (%dx),%al
f0100601:	89 da                	mov    %ebx,%edx
f0100603:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100604:	84 c9                	test   %cl,%cl
f0100606:	75 0c                	jne    f0100614 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f0100608:	c7 04 24 39 3e 10 f0 	movl   $0xf0103e39,(%esp)
f010060f:	e8 b6 27 00 00       	call   f0102dca <cprintf>
}
f0100614:	83 c4 1c             	add    $0x1c,%esp
f0100617:	5b                   	pop    %ebx
f0100618:	5e                   	pop    %esi
f0100619:	5f                   	pop    %edi
f010061a:	5d                   	pop    %ebp
f010061b:	c3                   	ret    

f010061c <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.
//`高级控制台I / O. 由readline和cprintf使用。
void
cputchar(int c)
{
f010061c:	55                   	push   %ebp
f010061d:	89 e5                	mov    %esp,%ebp
f010061f:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100622:	8b 45 08             	mov    0x8(%ebp),%eax
f0100625:	e8 7f fc ff ff       	call   f01002a9 <cons_putc>
}
f010062a:	c9                   	leave  
f010062b:	c3                   	ret    

f010062c <getchar>:

int
getchar(void)
{
f010062c:	55                   	push   %ebp
f010062d:	89 e5                	mov    %esp,%ebp
f010062f:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100632:	e8 a9 fe ff ff       	call   f01004e0 <cons_getc>
f0100637:	85 c0                	test   %eax,%eax
f0100639:	74 f7                	je     f0100632 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010063b:	c9                   	leave  
f010063c:	c3                   	ret    

f010063d <iscons>:

int
iscons(int fdnum)
{
f010063d:	55                   	push   %ebp
f010063e:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100640:	b8 01 00 00 00       	mov    $0x1,%eax
f0100645:	5d                   	pop    %ebp
f0100646:	c3                   	ret    
f0100647:	66 90                	xchg   %ax,%ax
f0100649:	66 90                	xchg   %ax,%ax
f010064b:	66 90                	xchg   %ax,%ax
f010064d:	66 90                	xchg   %ax,%ax
f010064f:	90                   	nop

f0100650 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100650:	55                   	push   %ebp
f0100651:	89 e5                	mov    %esp,%ebp
f0100653:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100656:	c7 44 24 08 80 40 10 	movl   $0xf0104080,0x8(%esp)
f010065d:	f0 
f010065e:	c7 44 24 04 9e 40 10 	movl   $0xf010409e,0x4(%esp)
f0100665:	f0 
f0100666:	c7 04 24 a3 40 10 f0 	movl   $0xf01040a3,(%esp)
f010066d:	e8 58 27 00 00       	call   f0102dca <cprintf>
f0100672:	c7 44 24 08 58 41 10 	movl   $0xf0104158,0x8(%esp)
f0100679:	f0 
f010067a:	c7 44 24 04 ac 40 10 	movl   $0xf01040ac,0x4(%esp)
f0100681:	f0 
f0100682:	c7 04 24 a3 40 10 f0 	movl   $0xf01040a3,(%esp)
f0100689:	e8 3c 27 00 00       	call   f0102dca <cprintf>
f010068e:	c7 44 24 08 58 41 10 	movl   $0xf0104158,0x8(%esp)
f0100695:	f0 
f0100696:	c7 44 24 04 b5 40 10 	movl   $0xf01040b5,0x4(%esp)
f010069d:	f0 
f010069e:	c7 04 24 a3 40 10 f0 	movl   $0xf01040a3,(%esp)
f01006a5:	e8 20 27 00 00       	call   f0102dca <cprintf>
	return 0;
}
f01006aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01006af:	c9                   	leave  
f01006b0:	c3                   	ret    

f01006b1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006b1:	55                   	push   %ebp
f01006b2:	89 e5                	mov    %esp,%ebp
f01006b4:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006b7:	c7 04 24 bf 40 10 f0 	movl   $0xf01040bf,(%esp)
f01006be:	e8 07 27 00 00       	call   f0102dca <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006c3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006ca:	00 
f01006cb:	c7 04 24 80 41 10 f0 	movl   $0xf0104180,(%esp)
f01006d2:	e8 f3 26 00 00       	call   f0102dca <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006d7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006de:	00 
f01006df:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006e6:	f0 
f01006e7:	c7 04 24 a8 41 10 f0 	movl   $0xf01041a8,(%esp)
f01006ee:	e8 d7 26 00 00       	call   f0102dca <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006f3:	c7 44 24 08 c7 3d 10 	movl   $0x103dc7,0x8(%esp)
f01006fa:	00 
f01006fb:	c7 44 24 04 c7 3d 10 	movl   $0xf0103dc7,0x4(%esp)
f0100702:	f0 
f0100703:	c7 04 24 cc 41 10 f0 	movl   $0xf01041cc,(%esp)
f010070a:	e8 bb 26 00 00       	call   f0102dca <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010070f:	c7 44 24 08 00 73 11 	movl   $0x117300,0x8(%esp)
f0100716:	00 
f0100717:	c7 44 24 04 00 73 11 	movl   $0xf0117300,0x4(%esp)
f010071e:	f0 
f010071f:	c7 04 24 f0 41 10 f0 	movl   $0xf01041f0,(%esp)
f0100726:	e8 9f 26 00 00       	call   f0102dca <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010072b:	c7 44 24 08 70 79 11 	movl   $0x117970,0x8(%esp)
f0100732:	00 
f0100733:	c7 44 24 04 70 79 11 	movl   $0xf0117970,0x4(%esp)
f010073a:	f0 
f010073b:	c7 04 24 14 42 10 f0 	movl   $0xf0104214,(%esp)
f0100742:	e8 83 26 00 00       	call   f0102dca <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100747:	b8 6f 7d 11 f0       	mov    $0xf0117d6f,%eax
f010074c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100751:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100756:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010075c:	85 c0                	test   %eax,%eax
f010075e:	0f 48 c2             	cmovs  %edx,%eax
f0100761:	c1 f8 0a             	sar    $0xa,%eax
f0100764:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100768:	c7 04 24 38 42 10 f0 	movl   $0xf0104238,(%esp)
f010076f:	e8 56 26 00 00       	call   f0102dca <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100774:	b8 00 00 00 00       	mov    $0x0,%eax
f0100779:	c9                   	leave  
f010077a:	c3                   	ret    

f010077b <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010077b:	55                   	push   %ebp
f010077c:	89 e5                	mov    %esp,%ebp
f010077e:	57                   	push   %edi
f010077f:	56                   	push   %esi
f0100780:	53                   	push   %ebx
f0100781:	83 ec 4c             	sub    $0x4c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100784:	89 ee                	mov    %ebp,%esi
	// Your code here.
      uint32_t ebp,eip;
        ebp = read_ebp();
        cprintf("Stack backtrace:\n");
f0100786:	c7 04 24 d8 40 10 f0 	movl   $0xf01040d8,(%esp)
f010078d:	e8 38 26 00 00       	call   f0102dca <cprintf>
        uint32_t esp = ebp;
	struct Eipdebuginfo eipinfo;
        while (ebp)
f0100792:	e9 88 00 00 00       	jmp    f010081f <mon_backtrace+0xa4>
        {
                eip = *(uint32_t*)(ebp + 4);
f0100797:	8b 7e 04             	mov    0x4(%esi),%edi
                cprintf("ebp %08x eip %08x args ",ebp,eip);
f010079a:	89 7c 24 08          	mov    %edi,0x8(%esp)
f010079e:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007a2:	c7 04 24 ea 40 10 f0 	movl   $0xf01040ea,(%esp)
f01007a9:	e8 1c 26 00 00       	call   f0102dca <cprintf>
                ebp = *(uint32_t*)(esp);
f01007ae:	8b 06                	mov    (%esi),%eax
f01007b0:	89 45 c4             	mov    %eax,-0x3c(%ebp)
                esp += 8;
f01007b3:	8d 5e 08             	lea    0x8(%esi),%ebx
f01007b6:	83 c6 1c             	add    $0x1c,%esi
		int i = 1;
                for(i = 1;i < 6;i++)
                {
                        cprintf("%08x ",*(uint32_t*)(esp));
f01007b9:	8b 03                	mov    (%ebx),%eax
f01007bb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007bf:	c7 04 24 02 41 10 f0 	movl   $0xf0104102,(%esp)
f01007c6:	e8 ff 25 00 00       	call   f0102dca <cprintf>
                        esp += 4;
f01007cb:	83 c3 04             	add    $0x4,%ebx
                eip = *(uint32_t*)(ebp + 4);
                cprintf("ebp %08x eip %08x args ",ebp,eip);
                ebp = *(uint32_t*)(esp);
                esp += 8;
		int i = 1;
                for(i = 1;i < 6;i++)
f01007ce:	39 f3                	cmp    %esi,%ebx
f01007d0:	75 e7                	jne    f01007b9 <mon_backtrace+0x3e>
                {
                        cprintf("%08x ",*(uint32_t*)(esp));
                        esp += 4;
                }
		debuginfo_eip(eip,&eipinfo);
f01007d2:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007d5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007d9:	89 3c 24             	mov    %edi,(%esp)
f01007dc:	e8 e0 26 00 00       	call   f0102ec1 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n",eipinfo.eip_file,eipinfo.eip_line,
f01007e1:	2b 7d e0             	sub    -0x20(%ebp),%edi
f01007e4:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01007e8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007eb:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007ef:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01007f2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007f6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007f9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007fd:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100800:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100804:	c7 04 24 08 41 10 f0 	movl   $0xf0104108,(%esp)
f010080b:	e8 ba 25 00 00       	call   f0102dca <cprintf>
			eipinfo.eip_fn_namelen,eipinfo.eip_fn_name,
			eip-eipinfo.eip_fn_addr);
                cprintf("\n");
f0100810:	c7 04 24 df 43 10 f0 	movl   $0xf01043df,(%esp)
f0100817:	e8 ae 25 00 00       	call   f0102dca <cprintf>
	struct Eipdebuginfo eipinfo;
        while (ebp)
        {
                eip = *(uint32_t*)(ebp + 4);
                cprintf("ebp %08x eip %08x args ",ebp,eip);
                ebp = *(uint32_t*)(esp);
f010081c:	8b 75 c4             	mov    -0x3c(%ebp),%esi
      uint32_t ebp,eip;
        ebp = read_ebp();
        cprintf("Stack backtrace:\n");
        uint32_t esp = ebp;
	struct Eipdebuginfo eipinfo;
        while (ebp)
f010081f:	85 f6                	test   %esi,%esi
f0100821:	0f 85 70 ff ff ff    	jne    f0100797 <mon_backtrace+0x1c>
			eip-eipinfo.eip_fn_addr);
                cprintf("\n");
                esp = ebp;
        }
 	return 0;
}
f0100827:	b8 00 00 00 00       	mov    $0x0,%eax
f010082c:	83 c4 4c             	add    $0x4c,%esp
f010082f:	5b                   	pop    %ebx
f0100830:	5e                   	pop    %esi
f0100831:	5f                   	pop    %edi
f0100832:	5d                   	pop    %ebp
f0100833:	c3                   	ret    

f0100834 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100834:	55                   	push   %ebp
f0100835:	89 e5                	mov    %esp,%ebp
f0100837:	57                   	push   %edi
f0100838:	56                   	push   %esi
f0100839:	53                   	push   %ebx
f010083a:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010083d:	c7 04 24 64 42 10 f0 	movl   $0xf0104264,(%esp)
f0100844:	e8 81 25 00 00       	call   f0102dca <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100849:	c7 04 24 88 42 10 f0 	movl   $0xf0104288,(%esp)
f0100850:	e8 75 25 00 00       	call   f0102dca <cprintf>


	while (1) {
		buf = readline("K> ");
f0100855:	c7 04 24 19 41 10 f0 	movl   $0xf0104119,(%esp)
f010085c:	e8 7f 2e 00 00       	call   f01036e0 <readline>
f0100861:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100863:	85 c0                	test   %eax,%eax
f0100865:	74 ee                	je     f0100855 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100867:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010086e:	be 00 00 00 00       	mov    $0x0,%esi
f0100873:	eb 0a                	jmp    f010087f <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100875:	c6 03 00             	movb   $0x0,(%ebx)
f0100878:	89 f7                	mov    %esi,%edi
f010087a:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010087d:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010087f:	0f b6 03             	movzbl (%ebx),%eax
f0100882:	84 c0                	test   %al,%al
f0100884:	74 63                	je     f01008e9 <monitor+0xb5>
f0100886:	0f be c0             	movsbl %al,%eax
f0100889:	89 44 24 04          	mov    %eax,0x4(%esp)
f010088d:	c7 04 24 1d 41 10 f0 	movl   $0xf010411d,(%esp)
f0100894:	e8 61 30 00 00       	call   f01038fa <strchr>
f0100899:	85 c0                	test   %eax,%eax
f010089b:	75 d8                	jne    f0100875 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f010089d:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008a0:	74 47                	je     f01008e9 <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008a2:	83 fe 0f             	cmp    $0xf,%esi
f01008a5:	75 16                	jne    f01008bd <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008a7:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008ae:	00 
f01008af:	c7 04 24 22 41 10 f0 	movl   $0xf0104122,(%esp)
f01008b6:	e8 0f 25 00 00       	call   f0102dca <cprintf>
f01008bb:	eb 98                	jmp    f0100855 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008bd:	8d 7e 01             	lea    0x1(%esi),%edi
f01008c0:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008c4:	eb 03                	jmp    f01008c9 <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008c6:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008c9:	0f b6 03             	movzbl (%ebx),%eax
f01008cc:	84 c0                	test   %al,%al
f01008ce:	74 ad                	je     f010087d <monitor+0x49>
f01008d0:	0f be c0             	movsbl %al,%eax
f01008d3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008d7:	c7 04 24 1d 41 10 f0 	movl   $0xf010411d,(%esp)
f01008de:	e8 17 30 00 00       	call   f01038fa <strchr>
f01008e3:	85 c0                	test   %eax,%eax
f01008e5:	74 df                	je     f01008c6 <monitor+0x92>
f01008e7:	eb 94                	jmp    f010087d <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f01008e9:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008f0:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008f1:	85 f6                	test   %esi,%esi
f01008f3:	0f 84 5c ff ff ff    	je     f0100855 <monitor+0x21>
f01008f9:	bb 00 00 00 00       	mov    $0x0,%ebx
f01008fe:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100901:	8b 04 85 c0 42 10 f0 	mov    -0xfefbd40(,%eax,4),%eax
f0100908:	89 44 24 04          	mov    %eax,0x4(%esp)
f010090c:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010090f:	89 04 24             	mov    %eax,(%esp)
f0100912:	e8 85 2f 00 00       	call   f010389c <strcmp>
f0100917:	85 c0                	test   %eax,%eax
f0100919:	75 24                	jne    f010093f <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f010091b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010091e:	8b 55 08             	mov    0x8(%ebp),%edx
f0100921:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100925:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100928:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010092c:	89 34 24             	mov    %esi,(%esp)
f010092f:	ff 14 85 c8 42 10 f0 	call   *-0xfefbd38(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100936:	85 c0                	test   %eax,%eax
f0100938:	78 25                	js     f010095f <monitor+0x12b>
f010093a:	e9 16 ff ff ff       	jmp    f0100855 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010093f:	83 c3 01             	add    $0x1,%ebx
f0100942:	83 fb 03             	cmp    $0x3,%ebx
f0100945:	75 b7                	jne    f01008fe <monitor+0xca>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100947:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010094a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010094e:	c7 04 24 3f 41 10 f0 	movl   $0xf010413f,(%esp)
f0100955:	e8 70 24 00 00       	call   f0102dca <cprintf>
f010095a:	e9 f6 fe ff ff       	jmp    f0100855 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010095f:	83 c4 5c             	add    $0x5c,%esp
f0100962:	5b                   	pop    %ebx
f0100963:	5e                   	pop    %esi
f0100964:	5f                   	pop    %edi
f0100965:	5d                   	pop    %ebp
f0100966:	c3                   	ret    

f0100967 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100967:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100969:	a1 38 75 11 f0       	mov    0xf0117538,%eax
f010096e:	85 c0                	test   %eax,%eax
f0100970:	75 50                	jne    f01009c2 <boot_alloc+0x5b>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100972:	b8 6f 89 11 f0       	mov    $0xf011896f,%eax
f0100977:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010097c:	a3 38 75 11 f0       	mov    %eax,0xf0117538
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
	if (n == 0)
f0100981:	85 d2                	test   %edx,%edx
f0100983:	74 41                	je     f01009c6 <boot_alloc+0x5f>
	{
	    return result;
	}
	else if (n >0)
	{
	    nextfree = ROUNDUP(result+n,PGSIZE);
f0100985:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f010098c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100992:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	    if ((uint32_t)nextfree > 0xF0400000)
f0100998:	81 fa 00 00 40 f0    	cmp    $0xf0400000,%edx
f010099e:	76 26                	jbe    f01009c6 <boot_alloc+0x5f>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009a0:	55                   	push   %ebp
f01009a1:	89 e5                	mov    %esp,%ebp
f01009a3:	83 ec 18             	sub    $0x18,%esp
	else if (n >0)
	{
	    nextfree = ROUNDUP(result+n,PGSIZE);
	    if ((uint32_t)nextfree > 0xF0400000)
	    {
		panic("Wrong,out of memory!\n");
f01009a6:	c7 44 24 08 e4 42 10 	movl   $0xf01042e4,0x8(%esp)
f01009ad:	f0 
f01009ae:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
f01009b5:	00 
f01009b6:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01009bd:	e8 d2 f6 ff ff       	call   f0100094 <_panic>
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
	if (n == 0)
f01009c2:	85 d2                	test   %edx,%edx
f01009c4:	75 bf                	jne    f0100985 <boot_alloc+0x1e>
		return NULL;
            }
	    return result;
	}
	return NULL;
}
f01009c6:	f3 c3                	repz ret 

f01009c8 <page2kva>:
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01009c8:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01009ce:	c1 f8 03             	sar    $0x3,%eax
f01009d1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009d4:	89 c2                	mov    %eax,%edx
f01009d6:	c1 ea 0c             	shr    $0xc,%edx
f01009d9:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01009df:	72 26                	jb     f0100a07 <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f01009e1:	55                   	push   %ebp
f01009e2:	89 e5                	mov    %esp,%ebp
f01009e4:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009e7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009eb:	c7 44 24 08 10 46 10 	movl   $0xf0104610,0x8(%esp)
f01009f2:	f0 
f01009f3:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01009fa:	00 
f01009fb:	c7 04 24 06 43 10 f0 	movl   $0xf0104306,(%esp)
f0100a02:	e8 8d f6 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100a07:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}
f0100a0c:	c3                   	ret    

f0100a0d <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a0d:	89 d1                	mov    %edx,%ecx
f0100a0f:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100a12:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a15:	a8 01                	test   $0x1,%al
f0100a17:	74 5d                	je     f0100a76 <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a19:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a1e:	89 c1                	mov    %eax,%ecx
f0100a20:	c1 e9 0c             	shr    $0xc,%ecx
f0100a23:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0100a29:	72 26                	jb     f0100a51 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a2b:	55                   	push   %ebp
f0100a2c:	89 e5                	mov    %esp,%ebp
f0100a2e:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a31:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a35:	c7 44 24 08 10 46 10 	movl   $0xf0104610,0x8(%esp)
f0100a3c:	f0 
f0100a3d:	c7 44 24 04 dd 02 00 	movl   $0x2dd,0x4(%esp)
f0100a44:	00 
f0100a45:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0100a4c:	e8 43 f6 ff ff       	call   f0100094 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100a51:	c1 ea 0c             	shr    $0xc,%edx
f0100a54:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a5a:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a61:	89 c2                	mov    %eax,%edx
f0100a63:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a66:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a6b:	85 d2                	test   %edx,%edx
f0100a6d:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a72:	0f 44 c2             	cmove  %edx,%eax
f0100a75:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a76:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a7b:	c3                   	ret    

f0100a7c <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a7c:	55                   	push   %ebp
f0100a7d:	89 e5                	mov    %esp,%ebp
f0100a7f:	57                   	push   %edi
f0100a80:	56                   	push   %esi
f0100a81:	53                   	push   %ebx
f0100a82:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a85:	84 c0                	test   %al,%al
f0100a87:	0f 85 07 03 00 00    	jne    f0100d94 <check_page_free_list+0x318>
f0100a8d:	e9 14 03 00 00       	jmp    f0100da6 <check_page_free_list+0x32a>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a92:	c7 44 24 08 34 46 10 	movl   $0xf0104634,0x8(%esp)
f0100a99:	f0 
f0100a9a:	c7 44 24 04 20 02 00 	movl   $0x220,0x4(%esp)
f0100aa1:	00 
f0100aa2:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0100aa9:	e8 e6 f5 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100aae:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100ab1:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ab4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ab7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100aba:	89 c2                	mov    %eax,%edx
f0100abc:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ac2:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100ac8:	0f 95 c2             	setne  %dl
f0100acb:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ace:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ad2:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ad4:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ad8:	8b 00                	mov    (%eax),%eax
f0100ada:	85 c0                	test   %eax,%eax
f0100adc:	75 dc                	jne    f0100aba <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100ade:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ae1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100ae7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100aea:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100aed:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100aef:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100af2:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100af7:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100afc:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100b02:	eb 63                	jmp    f0100b67 <check_page_free_list+0xeb>
f0100b04:	89 d8                	mov    %ebx,%eax
f0100b06:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100b0c:	c1 f8 03             	sar    $0x3,%eax
f0100b0f:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b12:	89 c2                	mov    %eax,%edx
f0100b14:	c1 ea 16             	shr    $0x16,%edx
f0100b17:	39 f2                	cmp    %esi,%edx
f0100b19:	73 4a                	jae    f0100b65 <check_page_free_list+0xe9>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b1b:	89 c2                	mov    %eax,%edx
f0100b1d:	c1 ea 0c             	shr    $0xc,%edx
f0100b20:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100b26:	72 20                	jb     f0100b48 <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b28:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b2c:	c7 44 24 08 10 46 10 	movl   $0xf0104610,0x8(%esp)
f0100b33:	f0 
f0100b34:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b3b:	00 
f0100b3c:	c7 04 24 06 43 10 f0 	movl   $0xf0104306,(%esp)
f0100b43:	e8 4c f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b48:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b4f:	00 
f0100b50:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b57:	00 
	return (void *)(pa + KERNBASE);
f0100b58:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b5d:	89 04 24             	mov    %eax,(%esp)
f0100b60:	e8 d2 2d 00 00       	call   f0103937 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b65:	8b 1b                	mov    (%ebx),%ebx
f0100b67:	85 db                	test   %ebx,%ebx
f0100b69:	75 99                	jne    f0100b04 <check_page_free_list+0x88>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b6b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b70:	e8 f2 fd ff ff       	call   f0100967 <boot_alloc>
f0100b75:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b78:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b7e:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
		assert(pp < pages + npages);
f0100b84:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100b89:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100b8c:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100b8f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b92:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b95:	bf 00 00 00 00       	mov    $0x0,%edi
f0100b9a:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b9d:	e9 97 01 00 00       	jmp    f0100d39 <check_page_free_list+0x2bd>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ba2:	39 ca                	cmp    %ecx,%edx
f0100ba4:	73 24                	jae    f0100bca <check_page_free_list+0x14e>
f0100ba6:	c7 44 24 0c 14 43 10 	movl   $0xf0104314,0xc(%esp)
f0100bad:	f0 
f0100bae:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0100bb5:	f0 
f0100bb6:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
f0100bbd:	00 
f0100bbe:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0100bc5:	e8 ca f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100bca:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bcd:	72 24                	jb     f0100bf3 <check_page_free_list+0x177>
f0100bcf:	c7 44 24 0c 35 43 10 	movl   $0xf0104335,0xc(%esp)
f0100bd6:	f0 
f0100bd7:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0100bde:	f0 
f0100bdf:	c7 44 24 04 3b 02 00 	movl   $0x23b,0x4(%esp)
f0100be6:	00 
f0100be7:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0100bee:	e8 a1 f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bf3:	89 d0                	mov    %edx,%eax
f0100bf5:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100bf8:	a8 07                	test   $0x7,%al
f0100bfa:	74 24                	je     f0100c20 <check_page_free_list+0x1a4>
f0100bfc:	c7 44 24 0c 58 46 10 	movl   $0xf0104658,0xc(%esp)
f0100c03:	f0 
f0100c04:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0100c0b:	f0 
f0100c0c:	c7 44 24 04 3c 02 00 	movl   $0x23c,0x4(%esp)
f0100c13:	00 
f0100c14:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0100c1b:	e8 74 f4 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c20:	c1 f8 03             	sar    $0x3,%eax
f0100c23:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c26:	85 c0                	test   %eax,%eax
f0100c28:	75 24                	jne    f0100c4e <check_page_free_list+0x1d2>
f0100c2a:	c7 44 24 0c 49 43 10 	movl   $0xf0104349,0xc(%esp)
f0100c31:	f0 
f0100c32:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0100c39:	f0 
f0100c3a:	c7 44 24 04 3f 02 00 	movl   $0x23f,0x4(%esp)
f0100c41:	00 
f0100c42:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0100c49:	e8 46 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c4e:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c53:	75 24                	jne    f0100c79 <check_page_free_list+0x1fd>
f0100c55:	c7 44 24 0c 5a 43 10 	movl   $0xf010435a,0xc(%esp)
f0100c5c:	f0 
f0100c5d:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0100c64:	f0 
f0100c65:	c7 44 24 04 40 02 00 	movl   $0x240,0x4(%esp)
f0100c6c:	00 
f0100c6d:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0100c74:	e8 1b f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c79:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c7e:	75 24                	jne    f0100ca4 <check_page_free_list+0x228>
f0100c80:	c7 44 24 0c 8c 46 10 	movl   $0xf010468c,0xc(%esp)
f0100c87:	f0 
f0100c88:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0100c8f:	f0 
f0100c90:	c7 44 24 04 41 02 00 	movl   $0x241,0x4(%esp)
f0100c97:	00 
f0100c98:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0100c9f:	e8 f0 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100ca4:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100ca9:	75 24                	jne    f0100ccf <check_page_free_list+0x253>
f0100cab:	c7 44 24 0c 73 43 10 	movl   $0xf0104373,0xc(%esp)
f0100cb2:	f0 
f0100cb3:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0100cba:	f0 
f0100cbb:	c7 44 24 04 42 02 00 	movl   $0x242,0x4(%esp)
f0100cc2:	00 
f0100cc3:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0100cca:	e8 c5 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100ccf:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cd4:	76 58                	jbe    f0100d2e <check_page_free_list+0x2b2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cd6:	89 c3                	mov    %eax,%ebx
f0100cd8:	c1 eb 0c             	shr    $0xc,%ebx
f0100cdb:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100cde:	77 20                	ja     f0100d00 <check_page_free_list+0x284>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ce0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ce4:	c7 44 24 08 10 46 10 	movl   $0xf0104610,0x8(%esp)
f0100ceb:	f0 
f0100cec:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100cf3:	00 
f0100cf4:	c7 04 24 06 43 10 f0 	movl   $0xf0104306,(%esp)
f0100cfb:	e8 94 f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100d00:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d05:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d08:	76 2a                	jbe    f0100d34 <check_page_free_list+0x2b8>
f0100d0a:	c7 44 24 0c b0 46 10 	movl   $0xf01046b0,0xc(%esp)
f0100d11:	f0 
f0100d12:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0100d19:	f0 
f0100d1a:	c7 44 24 04 43 02 00 	movl   $0x243,0x4(%esp)
f0100d21:	00 
f0100d22:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0100d29:	e8 66 f3 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d2e:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100d32:	eb 03                	jmp    f0100d37 <check_page_free_list+0x2bb>
		else
			++nfree_extmem;
f0100d34:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d37:	8b 12                	mov    (%edx),%edx
f0100d39:	85 d2                	test   %edx,%edx
f0100d3b:	0f 85 61 fe ff ff    	jne    f0100ba2 <check_page_free_list+0x126>
f0100d41:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d44:	85 db                	test   %ebx,%ebx
f0100d46:	7f 24                	jg     f0100d6c <check_page_free_list+0x2f0>
f0100d48:	c7 44 24 0c 8d 43 10 	movl   $0xf010438d,0xc(%esp)
f0100d4f:	f0 
f0100d50:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0100d57:	f0 
f0100d58:	c7 44 24 04 4b 02 00 	movl   $0x24b,0x4(%esp)
f0100d5f:	00 
f0100d60:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0100d67:	e8 28 f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d6c:	85 ff                	test   %edi,%edi
f0100d6e:	7f 4d                	jg     f0100dbd <check_page_free_list+0x341>
f0100d70:	c7 44 24 0c 9f 43 10 	movl   $0xf010439f,0xc(%esp)
f0100d77:	f0 
f0100d78:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0100d7f:	f0 
f0100d80:	c7 44 24 04 4c 02 00 	movl   $0x24c,0x4(%esp)
f0100d87:	00 
f0100d88:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0100d8f:	e8 00 f3 ff ff       	call   f0100094 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100d94:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100d99:	85 c0                	test   %eax,%eax
f0100d9b:	0f 85 0d fd ff ff    	jne    f0100aae <check_page_free_list+0x32>
f0100da1:	e9 ec fc ff ff       	jmp    f0100a92 <check_page_free_list+0x16>
f0100da6:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100dad:	0f 84 df fc ff ff    	je     f0100a92 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100db3:	be 00 04 00 00       	mov    $0x400,%esi
f0100db8:	e9 3f fd ff ff       	jmp    f0100afc <check_page_free_list+0x80>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100dbd:	83 c4 4c             	add    $0x4c,%esp
f0100dc0:	5b                   	pop    %ebx
f0100dc1:	5e                   	pop    %esi
f0100dc2:	5f                   	pop    %edi
f0100dc3:	5d                   	pop    %ebp
f0100dc4:	c3                   	ret    

f0100dc5 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100dc5:	55                   	push   %ebp
f0100dc6:	89 e5                	mov    %esp,%ebp
f0100dc8:	56                   	push   %esi
f0100dc9:	53                   	push   %ebx
f0100dca:	83 ec 10             	sub    $0x10,%esp
	// The example code here marks all physical pages as free.
	// However this is not truly the case.  What memory is free?
	//  1) Mark physical page 0 as in use.
	//     This way we preserve the real-mode IDT and BIOS structures
	//     in case we ever need them.  (Currently we don't, but...)
	pages[0].pp_ref = 1;
f0100dcd:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100dd2:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	//  2) The rest of base memory, [PGSIZE, npages_basemem * PGSIZE)
	//     is free.
	for(i = 1; i < npages_basemem; i++) {
f0100dd8:	8b 35 40 75 11 f0    	mov    0xf0117540,%esi
f0100dde:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100de4:	b8 01 00 00 00       	mov    $0x1,%eax
f0100de9:	eb 22                	jmp    f0100e0d <page_init+0x48>
f0100deb:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100df2:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
f0100df8:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = page_free_list;
f0100dff:	89 1c c1             	mov    %ebx,(%ecx,%eax,8)
	//     This way we preserve the real-mode IDT and BIOS structures
	//     in case we ever need them.  (Currently we don't, but...)
	pages[0].pp_ref = 1;
	//  2) The rest of base memory, [PGSIZE, npages_basemem * PGSIZE)
	//     is free.
	for(i = 1; i < npages_basemem; i++) {
f0100e02:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100e05:	03 15 6c 79 11 f0    	add    0xf011796c,%edx
f0100e0b:	89 d3                	mov    %edx,%ebx
	//     This way we preserve the real-mode IDT and BIOS structures
	//     in case we ever need them.  (Currently we don't, but...)
	pages[0].pp_ref = 1;
	//  2) The rest of base memory, [PGSIZE, npages_basemem * PGSIZE)
	//     is free.
	for(i = 1; i < npages_basemem; i++) {
f0100e0d:	39 f0                	cmp    %esi,%eax
f0100e0f:	72 da                	jb     f0100deb <page_init+0x26>
f0100e11:	89 1d 3c 75 11 f0    	mov    %ebx,0xf011753c
	//  3) Then comes the IO hole [IOPHYSMEM, EXTPHYSMEM), which must
	//     never be allocated.
	size_t IO_PHY = IOPHYSMEM/PGSIZE;
	size_t EXT_PHY = EXTPHYSMEM/PGSIZE;
	for(i = IO_PHY; i < EXT_PHY; i++) {
		pages[i].pp_ref = 1;
f0100e17:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100e1c:	bb a0 00 00 00       	mov    $0xa0,%ebx
f0100e21:	66 c7 44 d8 04 01 00 	movw   $0x1,0x4(%eax,%ebx,8)
	}
	//  3) Then comes the IO hole [IOPHYSMEM, EXTPHYSMEM), which must
	//     never be allocated.
	size_t IO_PHY = IOPHYSMEM/PGSIZE;
	size_t EXT_PHY = EXTPHYSMEM/PGSIZE;
	for(i = IO_PHY; i < EXT_PHY; i++) {
f0100e28:	83 c3 01             	add    $0x1,%ebx
f0100e2b:	81 fb 00 01 00 00    	cmp    $0x100,%ebx
f0100e31:	75 ee                	jne    f0100e21 <page_init+0x5c>
	//  4) Then extended memory [EXTPHYSMEM, ...).
	//     Some of it is in use, some is free. Where is the kernel
	//     in physical memory?  Which pages are already in use for
	//     page tables and other data structures?
	//
	size_t first_free_page_address = PADDR(boot_alloc(0))/PGSIZE;
f0100e33:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e38:	e8 2a fb ff ff       	call   f0100967 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100e3d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100e42:	77 20                	ja     f0100e64 <page_init+0x9f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100e44:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e48:	c7 44 24 08 f8 46 10 	movl   $0xf01046f8,0x8(%esp)
f0100e4f:	f0 
f0100e50:	c7 44 24 04 12 01 00 	movl   $0x112,0x4(%esp)
f0100e57:	00 
f0100e58:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0100e5f:	e8 30 f2 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100e64:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100e6a:	c1 ea 0c             	shr    $0xc,%edx
	for(i = EXT_PHY; i < first_free_page_address; i++) {
		pages[i].pp_ref = 1;
f0100e6d:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
	//     Some of it is in use, some is free. Where is the kernel
	//     in physical memory?  Which pages are already in use for
	//     page tables and other data structures?
	//
	size_t first_free_page_address = PADDR(boot_alloc(0))/PGSIZE;
	for(i = EXT_PHY; i < first_free_page_address; i++) {
f0100e72:	eb 0a                	jmp    f0100e7e <page_init+0xb9>
		pages[i].pp_ref = 1;
f0100e74:	66 c7 44 d8 04 01 00 	movw   $0x1,0x4(%eax,%ebx,8)
	//     Some of it is in use, some is free. Where is the kernel
	//     in physical memory?  Which pages are already in use for
	//     page tables and other data structures?
	//
	size_t first_free_page_address = PADDR(boot_alloc(0))/PGSIZE;
	for(i = EXT_PHY; i < first_free_page_address; i++) {
f0100e7b:	83 c3 01             	add    $0x1,%ebx
f0100e7e:	39 d3                	cmp    %edx,%ebx
f0100e80:	72 f2                	jb     f0100e74 <page_init+0xaf>
f0100e82:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100e88:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
f0100e8f:	eb 1e                	jmp    f0100eaf <page_init+0xea>
	}
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	for (i = first_free_page_address; i < npages; i++) {
		pages[i].pp_ref = 0;
f0100e91:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
f0100e97:	66 c7 44 01 04 00 00 	movw   $0x0,0x4(%ecx,%eax,1)
		pages[i].pp_link = page_free_list;
f0100e9e:	89 1c 01             	mov    %ebx,(%ecx,%eax,1)
		page_free_list = &pages[i];
f0100ea1:	89 c3                	mov    %eax,%ebx
f0100ea3:	03 1d 6c 79 11 f0    	add    0xf011796c,%ebx
		pages[i].pp_ref = 1;
	}
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	for (i = first_free_page_address; i < npages; i++) {
f0100ea9:	83 c2 01             	add    $0x1,%edx
f0100eac:	83 c0 08             	add    $0x8,%eax
f0100eaf:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100eb5:	72 da                	jb     f0100e91 <page_init+0xcc>
f0100eb7:	89 1d 3c 75 11 f0    	mov    %ebx,0xf011753c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100ebd:	83 c4 10             	add    $0x10,%esp
f0100ec0:	5b                   	pop    %ebx
f0100ec1:	5e                   	pop    %esi
f0100ec2:	5d                   	pop    %ebp
f0100ec3:	c3                   	ret    

f0100ec4 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100ec4:	55                   	push   %ebp
f0100ec5:	89 e5                	mov    %esp,%ebp
f0100ec7:	53                   	push   %ebx
f0100ec8:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	if (page_free_list == NULL) {
f0100ecb:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100ed1:	85 db                	test   %ebx,%ebx
f0100ed3:	74 6f                	je     f0100f44 <page_alloc+0x80>
		return NULL;
	}
	struct PageInfo *allocated_page = page_free_list;
	page_free_list = allocated_page->pp_link;
f0100ed5:	8b 03                	mov    (%ebx),%eax
f0100ed7:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	allocated_page->pp_link = NULL;
f0100edc:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO) {
		memset(page2kva(allocated_page), '\0', PGSIZE);
	}
	return allocated_page;
f0100ee2:	89 d8                	mov    %ebx,%eax
		return NULL;
	}
	struct PageInfo *allocated_page = page_free_list;
	page_free_list = allocated_page->pp_link;
	allocated_page->pp_link = NULL;
	if (alloc_flags & ALLOC_ZERO) {
f0100ee4:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ee8:	74 5f                	je     f0100f49 <page_alloc+0x85>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100eea:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100ef0:	c1 f8 03             	sar    $0x3,%eax
f0100ef3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ef6:	89 c2                	mov    %eax,%edx
f0100ef8:	c1 ea 0c             	shr    $0xc,%edx
f0100efb:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100f01:	72 20                	jb     f0100f23 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f03:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f07:	c7 44 24 08 10 46 10 	movl   $0xf0104610,0x8(%esp)
f0100f0e:	f0 
f0100f0f:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100f16:	00 
f0100f17:	c7 04 24 06 43 10 f0 	movl   $0xf0104306,(%esp)
f0100f1e:	e8 71 f1 ff ff       	call   f0100094 <_panic>
		memset(page2kva(allocated_page), '\0', PGSIZE);
f0100f23:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f2a:	00 
f0100f2b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f32:	00 
	return (void *)(pa + KERNBASE);
f0100f33:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f38:	89 04 24             	mov    %eax,(%esp)
f0100f3b:	e8 f7 29 00 00       	call   f0103937 <memset>
	}
	return allocated_page;
f0100f40:	89 d8                	mov    %ebx,%eax
f0100f42:	eb 05                	jmp    f0100f49 <page_alloc+0x85>
struct PageInfo *
page_alloc(int alloc_flags)
{
	// Fill this function in
	if (page_free_list == NULL) {
		return NULL;
f0100f44:	b8 00 00 00 00       	mov    $0x0,%eax
	allocated_page->pp_link = NULL;
	if (alloc_flags & ALLOC_ZERO) {
		memset(page2kva(allocated_page), '\0', PGSIZE);
	}
	return allocated_page;
}
f0100f49:	83 c4 14             	add    $0x14,%esp
f0100f4c:	5b                   	pop    %ebx
f0100f4d:	5d                   	pop    %ebp
f0100f4e:	c3                   	ret    

f0100f4f <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100f4f:	55                   	push   %ebp
f0100f50:	89 e5                	mov    %esp,%ebp
f0100f52:	83 ec 18             	sub    $0x18,%esp
f0100f55:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref != 0 || pp->pp_link != NULL) {
f0100f58:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f5d:	75 05                	jne    f0100f64 <page_free+0x15>
f0100f5f:	83 38 00             	cmpl   $0x0,(%eax)
f0100f62:	74 1c                	je     f0100f80 <page_free+0x31>
		panic("The page can not be free ");
f0100f64:	c7 44 24 08 b0 43 10 	movl   $0xf01043b0,0x8(%esp)
f0100f6b:	f0 
f0100f6c:	c7 44 24 04 47 01 00 	movl   $0x147,0x4(%esp)
f0100f73:	00 
f0100f74:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0100f7b:	e8 14 f1 ff ff       	call   f0100094 <_panic>
	}
	pp->pp_link = page_free_list;
f0100f80:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100f86:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f88:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
}
f0100f8d:	c9                   	leave  
f0100f8e:	c3                   	ret    

f0100f8f <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100f8f:	55                   	push   %ebp
f0100f90:	89 e5                	mov    %esp,%ebp
f0100f92:	83 ec 18             	sub    $0x18,%esp
f0100f95:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100f98:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0100f9c:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100f9f:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100fa3:	66 85 d2             	test   %dx,%dx
f0100fa6:	75 08                	jne    f0100fb0 <page_decref+0x21>
		page_free(pp);
f0100fa8:	89 04 24             	mov    %eax,(%esp)
f0100fab:	e8 9f ff ff ff       	call   f0100f4f <page_free>
}
f0100fb0:	c9                   	leave  
f0100fb1:	c3                   	ret    

f0100fb2 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100fb2:	55                   	push   %ebp
f0100fb3:	89 e5                	mov    %esp,%ebp
f0100fb5:	56                   	push   %esi
f0100fb6:	53                   	push   %ebx
f0100fb7:	83 ec 10             	sub    $0x10,%esp
f0100fba:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	uint32_t pg_dir_idx = PDX(va);
	uint32_t pg_tab_idx = PTX(va);
f0100fbd:	89 de                	mov    %ebx,%esi
f0100fbf:	c1 ee 0c             	shr    $0xc,%esi
f0100fc2:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
	uint32_t pg_dir_idx = PDX(va);
f0100fc8:	c1 eb 16             	shr    $0x16,%ebx
	uint32_t pg_tab_idx = PTX(va);
	pte_t * pg_addr_tab;
	if (pgdir[pg_dir_idx] & PTE_P) {
f0100fcb:	c1 e3 02             	shl    $0x2,%ebx
f0100fce:	03 5d 08             	add    0x8(%ebp),%ebx
f0100fd1:	f6 03 01             	testb  $0x1,(%ebx)
f0100fd4:	75 2c                	jne    f0101002 <pgdir_walk+0x50>
	}
	else {
		if (!create) {
f0100fd6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100fda:	74 63                	je     f010103f <pgdir_walk+0x8d>
				return NULL;
		}
		else {
		       struct PageInfo *page = page_alloc(ALLOC_ZERO);
f0100fdc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100fe3:	e8 dc fe ff ff       	call   f0100ec4 <page_alloc>
		       if(!page) {
f0100fe8:	85 c0                	test   %eax,%eax
f0100fea:	74 5a                	je     f0101046 <pgdir_walk+0x94>
					return NULL;
		       }
		       page->pp_ref += 1;
f0100fec:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ff1:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100ff7:	c1 f8 03             	sar    $0x3,%eax
f0100ffa:	c1 e0 0c             	shl    $0xc,%eax
		       pgdir[pg_dir_idx] = page2pa(page) | PTE_P | PTE_W | PTE_U;
f0100ffd:	83 c8 07             	or     $0x7,%eax
f0101000:	89 03                	mov    %eax,(%ebx)
                     }
	}
	pg_addr_tab = KADDR(PTE_ADDR(pgdir[pg_dir_idx]));
f0101002:	8b 03                	mov    (%ebx),%eax
f0101004:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101009:	89 c2                	mov    %eax,%edx
f010100b:	c1 ea 0c             	shr    $0xc,%edx
f010100e:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101014:	72 20                	jb     f0101036 <pgdir_walk+0x84>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101016:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010101a:	c7 44 24 08 10 46 10 	movl   $0xf0104610,0x8(%esp)
f0101021:	f0 
f0101022:	c7 44 24 04 83 01 00 	movl   $0x183,0x4(%esp)
f0101029:	00 
f010102a:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101031:	e8 5e f0 ff ff       	call   f0100094 <_panic>
	return &pg_addr_tab[pg_tab_idx];
f0101036:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f010103d:	eb 0c                	jmp    f010104b <pgdir_walk+0x99>
	pte_t * pg_addr_tab;
	if (pgdir[pg_dir_idx] & PTE_P) {
	}
	else {
		if (!create) {
				return NULL;
f010103f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101044:	eb 05                	jmp    f010104b <pgdir_walk+0x99>
		}
		else {
		       struct PageInfo *page = page_alloc(ALLOC_ZERO);
		       if(!page) {
					return NULL;
f0101046:	b8 00 00 00 00       	mov    $0x0,%eax
		       pgdir[pg_dir_idx] = page2pa(page) | PTE_P | PTE_W | PTE_U;
                     }
	}
	pg_addr_tab = KADDR(PTE_ADDR(pgdir[pg_dir_idx]));
	return &pg_addr_tab[pg_tab_idx];
}
f010104b:	83 c4 10             	add    $0x10,%esp
f010104e:	5b                   	pop    %ebx
f010104f:	5e                   	pop    %esi
f0101050:	5d                   	pop    %ebp
f0101051:	c3                   	ret    

f0101052 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101052:	55                   	push   %ebp
f0101053:	89 e5                	mov    %esp,%ebp
f0101055:	57                   	push   %edi
f0101056:	56                   	push   %esi
f0101057:	53                   	push   %ebx
f0101058:	83 ec 2c             	sub    $0x2c,%esp
f010105b:	89 c7                	mov    %eax,%edi
f010105d:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101060:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	int add_size;
	pte_t *pg_pte;
	for (add_size = 0; add_size < size ; add_size += PGSIZE) {
f0101063:	bb 00 00 00 00       	mov    $0x0,%ebx
		pg_pte = pgdir_walk(pgdir,(void*)va,1);
		if (!pg_pte) {
				panic("Wrong,out of memory! \n");
		}
		*pg_pte = pa | perm | PTE_P;
f0101068:	8b 45 0c             	mov    0xc(%ebp),%eax
f010106b:	83 c8 01             	or     $0x1,%eax
f010106e:	89 45 dc             	mov    %eax,-0x24(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int add_size;
	pte_t *pg_pte;
	for (add_size = 0; add_size < size ; add_size += PGSIZE) {
f0101071:	eb 44                	jmp    f01010b7 <boot_map_region+0x65>
		pg_pte = pgdir_walk(pgdir,(void*)va,1);
f0101073:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010107a:	00 
f010107b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010107e:	01 d8                	add    %ebx,%eax
f0101080:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101084:	89 3c 24             	mov    %edi,(%esp)
f0101087:	e8 26 ff ff ff       	call   f0100fb2 <pgdir_walk>
		if (!pg_pte) {
f010108c:	85 c0                	test   %eax,%eax
f010108e:	75 1c                	jne    f01010ac <boot_map_region+0x5a>
				panic("Wrong,out of memory! \n");
f0101090:	c7 44 24 08 ca 43 10 	movl   $0xf01043ca,0x8(%esp)
f0101097:	f0 
f0101098:	c7 44 24 04 9a 01 00 	movl   $0x19a,0x4(%esp)
f010109f:	00 
f01010a0:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01010a7:	e8 e8 ef ff ff       	call   f0100094 <_panic>
		}
		*pg_pte = pa | perm | PTE_P;
f01010ac:	0b 75 dc             	or     -0x24(%ebp),%esi
f01010af:	89 30                	mov    %esi,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int add_size;
	pte_t *pg_pte;
	for (add_size = 0; add_size < size ; add_size += PGSIZE) {
f01010b1:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01010b7:	89 de                	mov    %ebx,%esi
f01010b9:	03 75 08             	add    0x8(%ebp),%esi
f01010bc:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f01010bf:	77 b2                	ja     f0101073 <boot_map_region+0x21>
		}
		*pg_pte = pa | perm | PTE_P;
		pa += PGSIZE;
		va += PGSIZE;
	}
}
f01010c1:	83 c4 2c             	add    $0x2c,%esp
f01010c4:	5b                   	pop    %ebx
f01010c5:	5e                   	pop    %esi
f01010c6:	5f                   	pop    %edi
f01010c7:	5d                   	pop    %ebp
f01010c8:	c3                   	ret    

f01010c9 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01010c9:	55                   	push   %ebp
f01010ca:	89 e5                	mov    %esp,%ebp
f01010cc:	53                   	push   %ebx
f01010cd:	83 ec 14             	sub    $0x14,%esp
f01010d0:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pg_pte = pgdir_walk(pgdir, va, 0);
f01010d3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01010da:	00 
f01010db:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010de:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010e2:	8b 45 08             	mov    0x8(%ebp),%eax
f01010e5:	89 04 24             	mov    %eax,(%esp)
f01010e8:	e8 c5 fe ff ff       	call   f0100fb2 <pgdir_walk>
	if (!pg_pte) {
f01010ed:	85 c0                	test   %eax,%eax
f01010ef:	74 3a                	je     f010112b <page_lookup+0x62>
		return NULL;
	}
	else {
		if (pte_store) {
f01010f1:	85 db                	test   %ebx,%ebx
f01010f3:	74 02                	je     f01010f7 <page_lookup+0x2e>
	       		*pte_store = pg_pte;
f01010f5:	89 03                	mov    %eax,(%ebx)
		}
		return pa2page(PTE_ADDR(*pg_pte));
f01010f7:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010f9:	c1 e8 0c             	shr    $0xc,%eax
f01010fc:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0101102:	72 1c                	jb     f0101120 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f0101104:	c7 44 24 08 1c 47 10 	movl   $0xf010471c,0x8(%esp)
f010110b:	f0 
f010110c:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0101113:	00 
f0101114:	c7 04 24 06 43 10 f0 	movl   $0xf0104306,(%esp)
f010111b:	e8 74 ef ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0101120:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0101126:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0101129:	eb 05                	jmp    f0101130 <page_lookup+0x67>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pg_pte = pgdir_walk(pgdir, va, 0);
	if (!pg_pte) {
		return NULL;
f010112b:	b8 00 00 00 00       	mov    $0x0,%eax
		if (pte_store) {
	       		*pte_store = pg_pte;
		}
		return pa2page(PTE_ADDR(*pg_pte));
	}  
}
f0101130:	83 c4 14             	add    $0x14,%esp
f0101133:	5b                   	pop    %ebx
f0101134:	5d                   	pop    %ebp
f0101135:	c3                   	ret    

f0101136 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101136:	55                   	push   %ebp
f0101137:	89 e5                	mov    %esp,%ebp
f0101139:	53                   	push   %ebx
f010113a:	83 ec 24             	sub    $0x24,%esp
f010113d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pg_pte;
	struct PageInfo *pginfo = page_lookup(pgdir, va, &pg_pte);
f0101140:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101143:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101147:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010114b:	8b 45 08             	mov    0x8(%ebp),%eax
f010114e:	89 04 24             	mov    %eax,(%esp)
f0101151:	e8 73 ff ff ff       	call   f01010c9 <page_lookup>
	if (!pginfo) {
f0101156:	85 c0                	test   %eax,%eax
f0101158:	74 14                	je     f010116e <page_remove+0x38>
		return;
	} 
	page_decref(pginfo);
f010115a:	89 04 24             	mov    %eax,(%esp)
f010115d:	e8 2d fe ff ff       	call   f0100f8f <page_decref>
	*pg_pte = 0;
f0101162:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101165:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010116b:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir, va);
}
f010116e:	83 c4 24             	add    $0x24,%esp
f0101171:	5b                   	pop    %ebx
f0101172:	5d                   	pop    %ebp
f0101173:	c3                   	ret    

f0101174 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101174:	55                   	push   %ebp
f0101175:	89 e5                	mov    %esp,%ebp
f0101177:	57                   	push   %edi
f0101178:	56                   	push   %esi
f0101179:	53                   	push   %ebx
f010117a:	83 ec 1c             	sub    $0x1c,%esp
f010117d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101180:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pg_pte = pgdir_walk(pgdir, va, 1);
f0101183:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010118a:	00 
f010118b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010118f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101192:	89 04 24             	mov    %eax,(%esp)
f0101195:	e8 18 fe ff ff       	call   f0100fb2 <pgdir_walk>
f010119a:	89 c3                	mov    %eax,%ebx
	if (!pg_pte) {
f010119c:	85 c0                	test   %eax,%eax
f010119e:	74 36                	je     f01011d6 <page_insert+0x62>
		return -E_NO_MEM;
	}
	pp->pp_ref++;
f01011a0:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	if (*pg_pte & PTE_P) {
f01011a5:	f6 00 01             	testb  $0x1,(%eax)
f01011a8:	74 0f                	je     f01011b9 <page_insert+0x45>
		page_remove(pgdir, va);
f01011aa:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01011b1:	89 04 24             	mov    %eax,(%esp)
f01011b4:	e8 7d ff ff ff       	call   f0101136 <page_remove>
	}
	*pg_pte = page2pa(pp) | perm | PTE_P;
f01011b9:	8b 45 14             	mov    0x14(%ebp),%eax
f01011bc:	83 c8 01             	or     $0x1,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01011bf:	2b 35 6c 79 11 f0    	sub    0xf011796c,%esi
f01011c5:	c1 fe 03             	sar    $0x3,%esi
f01011c8:	c1 e6 0c             	shl    $0xc,%esi
f01011cb:	09 c6                	or     %eax,%esi
f01011cd:	89 33                	mov    %esi,(%ebx)
	return 0;
f01011cf:	b8 00 00 00 00       	mov    $0x0,%eax
f01011d4:	eb 05                	jmp    f01011db <page_insert+0x67>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t *pg_pte = pgdir_walk(pgdir, va, 1);
	if (!pg_pte) {
		return -E_NO_MEM;
f01011d6:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	if (*pg_pte & PTE_P) {
		page_remove(pgdir, va);
	}
	*pg_pte = page2pa(pp) | perm | PTE_P;
	return 0;
}
f01011db:	83 c4 1c             	add    $0x1c,%esp
f01011de:	5b                   	pop    %ebx
f01011df:	5e                   	pop    %esi
f01011e0:	5f                   	pop    %edi
f01011e1:	5d                   	pop    %ebp
f01011e2:	c3                   	ret    

f01011e3 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01011e3:	55                   	push   %ebp
f01011e4:	89 e5                	mov    %esp,%ebp
f01011e6:	57                   	push   %edi
f01011e7:	56                   	push   %esi
f01011e8:	53                   	push   %ebx
f01011e9:	83 ec 4c             	sub    $0x4c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01011ec:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f01011f3:	e8 62 1b 00 00       	call   f0102d5a <mc146818_read>
f01011f8:	89 c3                	mov    %eax,%ebx
f01011fa:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101201:	e8 54 1b 00 00       	call   f0102d5a <mc146818_read>
f0101206:	c1 e0 08             	shl    $0x8,%eax
f0101209:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010120b:	89 d8                	mov    %ebx,%eax
f010120d:	c1 e0 0a             	shl    $0xa,%eax
f0101210:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101216:	85 c0                	test   %eax,%eax
f0101218:	0f 48 c2             	cmovs  %edx,%eax
f010121b:	c1 f8 0c             	sar    $0xc,%eax
f010121e:	a3 40 75 11 f0       	mov    %eax,0xf0117540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101223:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010122a:	e8 2b 1b 00 00       	call   f0102d5a <mc146818_read>
f010122f:	89 c3                	mov    %eax,%ebx
f0101231:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101238:	e8 1d 1b 00 00       	call   f0102d5a <mc146818_read>
f010123d:	c1 e0 08             	shl    $0x8,%eax
f0101240:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101242:	89 d8                	mov    %ebx,%eax
f0101244:	c1 e0 0a             	shl    $0xa,%eax
f0101247:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010124d:	85 c0                	test   %eax,%eax
f010124f:	0f 48 c2             	cmovs  %edx,%eax
f0101252:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101255:	85 c0                	test   %eax,%eax
f0101257:	74 0e                	je     f0101267 <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101259:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010125f:	89 15 64 79 11 f0    	mov    %edx,0xf0117964
f0101265:	eb 0c                	jmp    f0101273 <mem_init+0x90>
	else
		npages = npages_basemem;
f0101267:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
f010126d:	89 15 64 79 11 f0    	mov    %edx,0xf0117964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101273:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101276:	c1 e8 0a             	shr    $0xa,%eax
f0101279:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f010127d:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f0101282:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101285:	c1 e8 0a             	shr    $0xa,%eax
f0101288:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f010128c:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0101291:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101294:	c1 e8 0a             	shr    $0xa,%eax
f0101297:	89 44 24 04          	mov    %eax,0x4(%esp)
f010129b:	c7 04 24 3c 47 10 f0 	movl   $0xf010473c,(%esp)
f01012a2:	e8 23 1b 00 00       	call   f0102dca <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01012a7:	b8 00 10 00 00       	mov    $0x1000,%eax
f01012ac:	e8 b6 f6 ff ff       	call   f0100967 <boot_alloc>
f01012b1:	a3 68 79 11 f0       	mov    %eax,0xf0117968
	memset(kern_pgdir, 0, PGSIZE);
f01012b6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01012bd:	00 
f01012be:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012c5:	00 
f01012c6:	89 04 24             	mov    %eax,(%esp)
f01012c9:	e8 69 26 00 00       	call   f0103937 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01012ce:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01012d3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01012d8:	77 20                	ja     f01012fa <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01012da:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012de:	c7 44 24 08 f8 46 10 	movl   $0xf01046f8,0x8(%esp)
f01012e5:	f0 
f01012e6:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
f01012ed:	00 
f01012ee:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01012f5:	e8 9a ed ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01012fa:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101300:	83 ca 05             	or     $0x5,%edx
f0101303:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
        pages = (struct PageInfo *) boot_alloc(sizeof(struct PageInfo)* npages);
f0101309:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f010130e:	c1 e0 03             	shl    $0x3,%eax
f0101311:	e8 51 f6 ff ff       	call   f0100967 <boot_alloc>
f0101316:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
	memset(pages,0,sizeof(struct PageInfo)* npages);
f010131b:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f0101321:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101328:	89 54 24 08          	mov    %edx,0x8(%esp)
f010132c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101333:	00 
f0101334:	89 04 24             	mov    %eax,(%esp)
f0101337:	e8 fb 25 00 00       	call   f0103937 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010133c:	e8 84 fa ff ff       	call   f0100dc5 <page_init>

	check_page_free_list(1);
f0101341:	b8 01 00 00 00       	mov    $0x1,%eax
f0101346:	e8 31 f7 ff ff       	call   f0100a7c <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010134b:	83 3d 6c 79 11 f0 00 	cmpl   $0x0,0xf011796c
f0101352:	75 1c                	jne    f0101370 <mem_init+0x18d>
		panic("'pages' is a null pointer!");
f0101354:	c7 44 24 08 e1 43 10 	movl   $0xf01043e1,0x8(%esp)
f010135b:	f0 
f010135c:	c7 44 24 04 5d 02 00 	movl   $0x25d,0x4(%esp)
f0101363:	00 
f0101364:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f010136b:	e8 24 ed ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101370:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101375:	bb 00 00 00 00       	mov    $0x0,%ebx
f010137a:	eb 05                	jmp    f0101381 <mem_init+0x19e>
		++nfree;
f010137c:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010137f:	8b 00                	mov    (%eax),%eax
f0101381:	85 c0                	test   %eax,%eax
f0101383:	75 f7                	jne    f010137c <mem_init+0x199>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101385:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010138c:	e8 33 fb ff ff       	call   f0100ec4 <page_alloc>
f0101391:	89 c7                	mov    %eax,%edi
f0101393:	85 c0                	test   %eax,%eax
f0101395:	75 24                	jne    f01013bb <mem_init+0x1d8>
f0101397:	c7 44 24 0c fc 43 10 	movl   $0xf01043fc,0xc(%esp)
f010139e:	f0 
f010139f:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01013a6:	f0 
f01013a7:	c7 44 24 04 65 02 00 	movl   $0x265,0x4(%esp)
f01013ae:	00 
f01013af:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01013b6:	e8 d9 ec ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01013bb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013c2:	e8 fd fa ff ff       	call   f0100ec4 <page_alloc>
f01013c7:	89 c6                	mov    %eax,%esi
f01013c9:	85 c0                	test   %eax,%eax
f01013cb:	75 24                	jne    f01013f1 <mem_init+0x20e>
f01013cd:	c7 44 24 0c 12 44 10 	movl   $0xf0104412,0xc(%esp)
f01013d4:	f0 
f01013d5:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01013dc:	f0 
f01013dd:	c7 44 24 04 66 02 00 	movl   $0x266,0x4(%esp)
f01013e4:	00 
f01013e5:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01013ec:	e8 a3 ec ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01013f1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013f8:	e8 c7 fa ff ff       	call   f0100ec4 <page_alloc>
f01013fd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101400:	85 c0                	test   %eax,%eax
f0101402:	75 24                	jne    f0101428 <mem_init+0x245>
f0101404:	c7 44 24 0c 28 44 10 	movl   $0xf0104428,0xc(%esp)
f010140b:	f0 
f010140c:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101413:	f0 
f0101414:	c7 44 24 04 67 02 00 	movl   $0x267,0x4(%esp)
f010141b:	00 
f010141c:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101423:	e8 6c ec ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101428:	39 f7                	cmp    %esi,%edi
f010142a:	75 24                	jne    f0101450 <mem_init+0x26d>
f010142c:	c7 44 24 0c 3e 44 10 	movl   $0xf010443e,0xc(%esp)
f0101433:	f0 
f0101434:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f010143b:	f0 
f010143c:	c7 44 24 04 6a 02 00 	movl   $0x26a,0x4(%esp)
f0101443:	00 
f0101444:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f010144b:	e8 44 ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101450:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101453:	39 c6                	cmp    %eax,%esi
f0101455:	74 04                	je     f010145b <mem_init+0x278>
f0101457:	39 c7                	cmp    %eax,%edi
f0101459:	75 24                	jne    f010147f <mem_init+0x29c>
f010145b:	c7 44 24 0c 78 47 10 	movl   $0xf0104778,0xc(%esp)
f0101462:	f0 
f0101463:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f010146a:	f0 
f010146b:	c7 44 24 04 6b 02 00 	movl   $0x26b,0x4(%esp)
f0101472:	00 
f0101473:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f010147a:	e8 15 ec ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010147f:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101485:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f010148a:	c1 e0 0c             	shl    $0xc,%eax
f010148d:	89 f9                	mov    %edi,%ecx
f010148f:	29 d1                	sub    %edx,%ecx
f0101491:	c1 f9 03             	sar    $0x3,%ecx
f0101494:	c1 e1 0c             	shl    $0xc,%ecx
f0101497:	39 c1                	cmp    %eax,%ecx
f0101499:	72 24                	jb     f01014bf <mem_init+0x2dc>
f010149b:	c7 44 24 0c 50 44 10 	movl   $0xf0104450,0xc(%esp)
f01014a2:	f0 
f01014a3:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01014aa:	f0 
f01014ab:	c7 44 24 04 6c 02 00 	movl   $0x26c,0x4(%esp)
f01014b2:	00 
f01014b3:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01014ba:	e8 d5 eb ff ff       	call   f0100094 <_panic>
f01014bf:	89 f1                	mov    %esi,%ecx
f01014c1:	29 d1                	sub    %edx,%ecx
f01014c3:	c1 f9 03             	sar    $0x3,%ecx
f01014c6:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01014c9:	39 c8                	cmp    %ecx,%eax
f01014cb:	77 24                	ja     f01014f1 <mem_init+0x30e>
f01014cd:	c7 44 24 0c 6d 44 10 	movl   $0xf010446d,0xc(%esp)
f01014d4:	f0 
f01014d5:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01014dc:	f0 
f01014dd:	c7 44 24 04 6d 02 00 	movl   $0x26d,0x4(%esp)
f01014e4:	00 
f01014e5:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01014ec:	e8 a3 eb ff ff       	call   f0100094 <_panic>
f01014f1:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01014f4:	29 d1                	sub    %edx,%ecx
f01014f6:	89 ca                	mov    %ecx,%edx
f01014f8:	c1 fa 03             	sar    $0x3,%edx
f01014fb:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01014fe:	39 d0                	cmp    %edx,%eax
f0101500:	77 24                	ja     f0101526 <mem_init+0x343>
f0101502:	c7 44 24 0c 8a 44 10 	movl   $0xf010448a,0xc(%esp)
f0101509:	f0 
f010150a:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101511:	f0 
f0101512:	c7 44 24 04 6e 02 00 	movl   $0x26e,0x4(%esp)
f0101519:	00 
f010151a:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101521:	e8 6e eb ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101526:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010152b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010152e:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101535:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101538:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010153f:	e8 80 f9 ff ff       	call   f0100ec4 <page_alloc>
f0101544:	85 c0                	test   %eax,%eax
f0101546:	74 24                	je     f010156c <mem_init+0x389>
f0101548:	c7 44 24 0c a7 44 10 	movl   $0xf01044a7,0xc(%esp)
f010154f:	f0 
f0101550:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101557:	f0 
f0101558:	c7 44 24 04 75 02 00 	movl   $0x275,0x4(%esp)
f010155f:	00 
f0101560:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101567:	e8 28 eb ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010156c:	89 3c 24             	mov    %edi,(%esp)
f010156f:	e8 db f9 ff ff       	call   f0100f4f <page_free>
	page_free(pp1);
f0101574:	89 34 24             	mov    %esi,(%esp)
f0101577:	e8 d3 f9 ff ff       	call   f0100f4f <page_free>
	page_free(pp2);
f010157c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010157f:	89 04 24             	mov    %eax,(%esp)
f0101582:	e8 c8 f9 ff ff       	call   f0100f4f <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101587:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010158e:	e8 31 f9 ff ff       	call   f0100ec4 <page_alloc>
f0101593:	89 c6                	mov    %eax,%esi
f0101595:	85 c0                	test   %eax,%eax
f0101597:	75 24                	jne    f01015bd <mem_init+0x3da>
f0101599:	c7 44 24 0c fc 43 10 	movl   $0xf01043fc,0xc(%esp)
f01015a0:	f0 
f01015a1:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01015a8:	f0 
f01015a9:	c7 44 24 04 7c 02 00 	movl   $0x27c,0x4(%esp)
f01015b0:	00 
f01015b1:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01015b8:	e8 d7 ea ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01015bd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015c4:	e8 fb f8 ff ff       	call   f0100ec4 <page_alloc>
f01015c9:	89 c7                	mov    %eax,%edi
f01015cb:	85 c0                	test   %eax,%eax
f01015cd:	75 24                	jne    f01015f3 <mem_init+0x410>
f01015cf:	c7 44 24 0c 12 44 10 	movl   $0xf0104412,0xc(%esp)
f01015d6:	f0 
f01015d7:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01015de:	f0 
f01015df:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
f01015e6:	00 
f01015e7:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01015ee:	e8 a1 ea ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01015f3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015fa:	e8 c5 f8 ff ff       	call   f0100ec4 <page_alloc>
f01015ff:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101602:	85 c0                	test   %eax,%eax
f0101604:	75 24                	jne    f010162a <mem_init+0x447>
f0101606:	c7 44 24 0c 28 44 10 	movl   $0xf0104428,0xc(%esp)
f010160d:	f0 
f010160e:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101615:	f0 
f0101616:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
f010161d:	00 
f010161e:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101625:	e8 6a ea ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010162a:	39 fe                	cmp    %edi,%esi
f010162c:	75 24                	jne    f0101652 <mem_init+0x46f>
f010162e:	c7 44 24 0c 3e 44 10 	movl   $0xf010443e,0xc(%esp)
f0101635:	f0 
f0101636:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f010163d:	f0 
f010163e:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f0101645:	00 
f0101646:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f010164d:	e8 42 ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101652:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101655:	39 c7                	cmp    %eax,%edi
f0101657:	74 04                	je     f010165d <mem_init+0x47a>
f0101659:	39 c6                	cmp    %eax,%esi
f010165b:	75 24                	jne    f0101681 <mem_init+0x49e>
f010165d:	c7 44 24 0c 78 47 10 	movl   $0xf0104778,0xc(%esp)
f0101664:	f0 
f0101665:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f010166c:	f0 
f010166d:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
f0101674:	00 
f0101675:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f010167c:	e8 13 ea ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101681:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101688:	e8 37 f8 ff ff       	call   f0100ec4 <page_alloc>
f010168d:	85 c0                	test   %eax,%eax
f010168f:	74 24                	je     f01016b5 <mem_init+0x4d2>
f0101691:	c7 44 24 0c a7 44 10 	movl   $0xf01044a7,0xc(%esp)
f0101698:	f0 
f0101699:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01016a0:	f0 
f01016a1:	c7 44 24 04 82 02 00 	movl   $0x282,0x4(%esp)
f01016a8:	00 
f01016a9:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01016b0:	e8 df e9 ff ff       	call   f0100094 <_panic>
f01016b5:	89 f0                	mov    %esi,%eax
f01016b7:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01016bd:	c1 f8 03             	sar    $0x3,%eax
f01016c0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016c3:	89 c2                	mov    %eax,%edx
f01016c5:	c1 ea 0c             	shr    $0xc,%edx
f01016c8:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01016ce:	72 20                	jb     f01016f0 <mem_init+0x50d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016d0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016d4:	c7 44 24 08 10 46 10 	movl   $0xf0104610,0x8(%esp)
f01016db:	f0 
f01016dc:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01016e3:	00 
f01016e4:	c7 04 24 06 43 10 f0 	movl   $0xf0104306,(%esp)
f01016eb:	e8 a4 e9 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01016f0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01016f7:	00 
f01016f8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01016ff:	00 
	return (void *)(pa + KERNBASE);
f0101700:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101705:	89 04 24             	mov    %eax,(%esp)
f0101708:	e8 2a 22 00 00       	call   f0103937 <memset>
	page_free(pp0);
f010170d:	89 34 24             	mov    %esi,(%esp)
f0101710:	e8 3a f8 ff ff       	call   f0100f4f <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101715:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010171c:	e8 a3 f7 ff ff       	call   f0100ec4 <page_alloc>
f0101721:	85 c0                	test   %eax,%eax
f0101723:	75 24                	jne    f0101749 <mem_init+0x566>
f0101725:	c7 44 24 0c b6 44 10 	movl   $0xf01044b6,0xc(%esp)
f010172c:	f0 
f010172d:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101734:	f0 
f0101735:	c7 44 24 04 87 02 00 	movl   $0x287,0x4(%esp)
f010173c:	00 
f010173d:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101744:	e8 4b e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101749:	39 c6                	cmp    %eax,%esi
f010174b:	74 24                	je     f0101771 <mem_init+0x58e>
f010174d:	c7 44 24 0c d4 44 10 	movl   $0xf01044d4,0xc(%esp)
f0101754:	f0 
f0101755:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f010175c:	f0 
f010175d:	c7 44 24 04 88 02 00 	movl   $0x288,0x4(%esp)
f0101764:	00 
f0101765:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f010176c:	e8 23 e9 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101771:	89 f0                	mov    %esi,%eax
f0101773:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101779:	c1 f8 03             	sar    $0x3,%eax
f010177c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010177f:	89 c2                	mov    %eax,%edx
f0101781:	c1 ea 0c             	shr    $0xc,%edx
f0101784:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f010178a:	72 20                	jb     f01017ac <mem_init+0x5c9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010178c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101790:	c7 44 24 08 10 46 10 	movl   $0xf0104610,0x8(%esp)
f0101797:	f0 
f0101798:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010179f:	00 
f01017a0:	c7 04 24 06 43 10 f0 	movl   $0xf0104306,(%esp)
f01017a7:	e8 e8 e8 ff ff       	call   f0100094 <_panic>
f01017ac:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01017b2:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017b8:	80 38 00             	cmpb   $0x0,(%eax)
f01017bb:	74 24                	je     f01017e1 <mem_init+0x5fe>
f01017bd:	c7 44 24 0c e4 44 10 	movl   $0xf01044e4,0xc(%esp)
f01017c4:	f0 
f01017c5:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01017cc:	f0 
f01017cd:	c7 44 24 04 8b 02 00 	movl   $0x28b,0x4(%esp)
f01017d4:	00 
f01017d5:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01017dc:	e8 b3 e8 ff ff       	call   f0100094 <_panic>
f01017e1:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01017e4:	39 d0                	cmp    %edx,%eax
f01017e6:	75 d0                	jne    f01017b8 <mem_init+0x5d5>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01017e8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01017eb:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f01017f0:	89 34 24             	mov    %esi,(%esp)
f01017f3:	e8 57 f7 ff ff       	call   f0100f4f <page_free>
	page_free(pp1);
f01017f8:	89 3c 24             	mov    %edi,(%esp)
f01017fb:	e8 4f f7 ff ff       	call   f0100f4f <page_free>
	page_free(pp2);
f0101800:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101803:	89 04 24             	mov    %eax,(%esp)
f0101806:	e8 44 f7 ff ff       	call   f0100f4f <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010180b:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101810:	eb 05                	jmp    f0101817 <mem_init+0x634>
		--nfree;
f0101812:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101815:	8b 00                	mov    (%eax),%eax
f0101817:	85 c0                	test   %eax,%eax
f0101819:	75 f7                	jne    f0101812 <mem_init+0x62f>
		--nfree;
	assert(nfree == 0);
f010181b:	85 db                	test   %ebx,%ebx
f010181d:	74 24                	je     f0101843 <mem_init+0x660>
f010181f:	c7 44 24 0c ee 44 10 	movl   $0xf01044ee,0xc(%esp)
f0101826:	f0 
f0101827:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f010182e:	f0 
f010182f:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f0101836:	00 
f0101837:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f010183e:	e8 51 e8 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101843:	c7 04 24 98 47 10 f0 	movl   $0xf0104798,(%esp)
f010184a:	e8 7b 15 00 00       	call   f0102dca <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010184f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101856:	e8 69 f6 ff ff       	call   f0100ec4 <page_alloc>
f010185b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010185e:	85 c0                	test   %eax,%eax
f0101860:	75 24                	jne    f0101886 <mem_init+0x6a3>
f0101862:	c7 44 24 0c fc 43 10 	movl   $0xf01043fc,0xc(%esp)
f0101869:	f0 
f010186a:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101871:	f0 
f0101872:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f0101879:	00 
f010187a:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101881:	e8 0e e8 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101886:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010188d:	e8 32 f6 ff ff       	call   f0100ec4 <page_alloc>
f0101892:	89 c3                	mov    %eax,%ebx
f0101894:	85 c0                	test   %eax,%eax
f0101896:	75 24                	jne    f01018bc <mem_init+0x6d9>
f0101898:	c7 44 24 0c 12 44 10 	movl   $0xf0104412,0xc(%esp)
f010189f:	f0 
f01018a0:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01018a7:	f0 
f01018a8:	c7 44 24 04 f2 02 00 	movl   $0x2f2,0x4(%esp)
f01018af:	00 
f01018b0:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01018b7:	e8 d8 e7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01018bc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018c3:	e8 fc f5 ff ff       	call   f0100ec4 <page_alloc>
f01018c8:	89 c6                	mov    %eax,%esi
f01018ca:	85 c0                	test   %eax,%eax
f01018cc:	75 24                	jne    f01018f2 <mem_init+0x70f>
f01018ce:	c7 44 24 0c 28 44 10 	movl   $0xf0104428,0xc(%esp)
f01018d5:	f0 
f01018d6:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01018dd:	f0 
f01018de:	c7 44 24 04 f3 02 00 	movl   $0x2f3,0x4(%esp)
f01018e5:	00 
f01018e6:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01018ed:	e8 a2 e7 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018f2:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01018f5:	75 24                	jne    f010191b <mem_init+0x738>
f01018f7:	c7 44 24 0c 3e 44 10 	movl   $0xf010443e,0xc(%esp)
f01018fe:	f0 
f01018ff:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101906:	f0 
f0101907:	c7 44 24 04 f6 02 00 	movl   $0x2f6,0x4(%esp)
f010190e:	00 
f010190f:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101916:	e8 79 e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010191b:	39 c3                	cmp    %eax,%ebx
f010191d:	74 05                	je     f0101924 <mem_init+0x741>
f010191f:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101922:	75 24                	jne    f0101948 <mem_init+0x765>
f0101924:	c7 44 24 0c 78 47 10 	movl   $0xf0104778,0xc(%esp)
f010192b:	f0 
f010192c:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101933:	f0 
f0101934:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
f010193b:	00 
f010193c:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101943:	e8 4c e7 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101948:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010194d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101950:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101957:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010195a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101961:	e8 5e f5 ff ff       	call   f0100ec4 <page_alloc>
f0101966:	85 c0                	test   %eax,%eax
f0101968:	74 24                	je     f010198e <mem_init+0x7ab>
f010196a:	c7 44 24 0c a7 44 10 	movl   $0xf01044a7,0xc(%esp)
f0101971:	f0 
f0101972:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101979:	f0 
f010197a:	c7 44 24 04 fe 02 00 	movl   $0x2fe,0x4(%esp)
f0101981:	00 
f0101982:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101989:	e8 06 e7 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010198e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101991:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101995:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010199c:	00 
f010199d:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01019a2:	89 04 24             	mov    %eax,(%esp)
f01019a5:	e8 1f f7 ff ff       	call   f01010c9 <page_lookup>
f01019aa:	85 c0                	test   %eax,%eax
f01019ac:	74 24                	je     f01019d2 <mem_init+0x7ef>
f01019ae:	c7 44 24 0c b8 47 10 	movl   $0xf01047b8,0xc(%esp)
f01019b5:	f0 
f01019b6:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01019bd:	f0 
f01019be:	c7 44 24 04 01 03 00 	movl   $0x301,0x4(%esp)
f01019c5:	00 
f01019c6:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01019cd:	e8 c2 e6 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019d2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01019d9:	00 
f01019da:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01019e1:	00 
f01019e2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01019e6:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01019eb:	89 04 24             	mov    %eax,(%esp)
f01019ee:	e8 81 f7 ff ff       	call   f0101174 <page_insert>
f01019f3:	85 c0                	test   %eax,%eax
f01019f5:	78 24                	js     f0101a1b <mem_init+0x838>
f01019f7:	c7 44 24 0c f0 47 10 	movl   $0xf01047f0,0xc(%esp)
f01019fe:	f0 
f01019ff:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101a06:	f0 
f0101a07:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f0101a0e:	00 
f0101a0f:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101a16:	e8 79 e6 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a1b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a1e:	89 04 24             	mov    %eax,(%esp)
f0101a21:	e8 29 f5 ff ff       	call   f0100f4f <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a26:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a2d:	00 
f0101a2e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a35:	00 
f0101a36:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101a3a:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101a3f:	89 04 24             	mov    %eax,(%esp)
f0101a42:	e8 2d f7 ff ff       	call   f0101174 <page_insert>
f0101a47:	85 c0                	test   %eax,%eax
f0101a49:	74 24                	je     f0101a6f <mem_init+0x88c>
f0101a4b:	c7 44 24 0c 20 48 10 	movl   $0xf0104820,0xc(%esp)
f0101a52:	f0 
f0101a53:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101a5a:	f0 
f0101a5b:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
f0101a62:	00 
f0101a63:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101a6a:	e8 25 e6 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a6f:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a75:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101a7a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101a7d:	8b 17                	mov    (%edi),%edx
f0101a7f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a85:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101a88:	29 c1                	sub    %eax,%ecx
f0101a8a:	89 c8                	mov    %ecx,%eax
f0101a8c:	c1 f8 03             	sar    $0x3,%eax
f0101a8f:	c1 e0 0c             	shl    $0xc,%eax
f0101a92:	39 c2                	cmp    %eax,%edx
f0101a94:	74 24                	je     f0101aba <mem_init+0x8d7>
f0101a96:	c7 44 24 0c 50 48 10 	movl   $0xf0104850,0xc(%esp)
f0101a9d:	f0 
f0101a9e:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101aa5:	f0 
f0101aa6:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f0101aad:	00 
f0101aae:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101ab5:	e8 da e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101aba:	ba 00 00 00 00       	mov    $0x0,%edx
f0101abf:	89 f8                	mov    %edi,%eax
f0101ac1:	e8 47 ef ff ff       	call   f0100a0d <check_va2pa>
f0101ac6:	89 da                	mov    %ebx,%edx
f0101ac8:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101acb:	c1 fa 03             	sar    $0x3,%edx
f0101ace:	c1 e2 0c             	shl    $0xc,%edx
f0101ad1:	39 d0                	cmp    %edx,%eax
f0101ad3:	74 24                	je     f0101af9 <mem_init+0x916>
f0101ad5:	c7 44 24 0c 78 48 10 	movl   $0xf0104878,0xc(%esp)
f0101adc:	f0 
f0101add:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101ae4:	f0 
f0101ae5:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0101aec:	00 
f0101aed:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101af4:	e8 9b e5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101af9:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101afe:	74 24                	je     f0101b24 <mem_init+0x941>
f0101b00:	c7 44 24 0c f9 44 10 	movl   $0xf01044f9,0xc(%esp)
f0101b07:	f0 
f0101b08:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101b0f:	f0 
f0101b10:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0101b17:	00 
f0101b18:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101b1f:	e8 70 e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101b24:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b27:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b2c:	74 24                	je     f0101b52 <mem_init+0x96f>
f0101b2e:	c7 44 24 0c 0a 45 10 	movl   $0xf010450a,0xc(%esp)
f0101b35:	f0 
f0101b36:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101b3d:	f0 
f0101b3e:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f0101b45:	00 
f0101b46:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101b4d:	e8 42 e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b52:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b59:	00 
f0101b5a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b61:	00 
f0101b62:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101b66:	89 3c 24             	mov    %edi,(%esp)
f0101b69:	e8 06 f6 ff ff       	call   f0101174 <page_insert>
f0101b6e:	85 c0                	test   %eax,%eax
f0101b70:	74 24                	je     f0101b96 <mem_init+0x9b3>
f0101b72:	c7 44 24 0c a8 48 10 	movl   $0xf01048a8,0xc(%esp)
f0101b79:	f0 
f0101b7a:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101b81:	f0 
f0101b82:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f0101b89:	00 
f0101b8a:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101b91:	e8 fe e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b96:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b9b:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101ba0:	e8 68 ee ff ff       	call   f0100a0d <check_va2pa>
f0101ba5:	89 f2                	mov    %esi,%edx
f0101ba7:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101bad:	c1 fa 03             	sar    $0x3,%edx
f0101bb0:	c1 e2 0c             	shl    $0xc,%edx
f0101bb3:	39 d0                	cmp    %edx,%eax
f0101bb5:	74 24                	je     f0101bdb <mem_init+0x9f8>
f0101bb7:	c7 44 24 0c e4 48 10 	movl   $0xf01048e4,0xc(%esp)
f0101bbe:	f0 
f0101bbf:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101bc6:	f0 
f0101bc7:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f0101bce:	00 
f0101bcf:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101bd6:	e8 b9 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101bdb:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101be0:	74 24                	je     f0101c06 <mem_init+0xa23>
f0101be2:	c7 44 24 0c 1b 45 10 	movl   $0xf010451b,0xc(%esp)
f0101be9:	f0 
f0101bea:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101bf1:	f0 
f0101bf2:	c7 44 24 04 11 03 00 	movl   $0x311,0x4(%esp)
f0101bf9:	00 
f0101bfa:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101c01:	e8 8e e4 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101c06:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c0d:	e8 b2 f2 ff ff       	call   f0100ec4 <page_alloc>
f0101c12:	85 c0                	test   %eax,%eax
f0101c14:	74 24                	je     f0101c3a <mem_init+0xa57>
f0101c16:	c7 44 24 0c a7 44 10 	movl   $0xf01044a7,0xc(%esp)
f0101c1d:	f0 
f0101c1e:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101c25:	f0 
f0101c26:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0101c2d:	00 
f0101c2e:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101c35:	e8 5a e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c3a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c41:	00 
f0101c42:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c49:	00 
f0101c4a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c4e:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101c53:	89 04 24             	mov    %eax,(%esp)
f0101c56:	e8 19 f5 ff ff       	call   f0101174 <page_insert>
f0101c5b:	85 c0                	test   %eax,%eax
f0101c5d:	74 24                	je     f0101c83 <mem_init+0xaa0>
f0101c5f:	c7 44 24 0c a8 48 10 	movl   $0xf01048a8,0xc(%esp)
f0101c66:	f0 
f0101c67:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101c6e:	f0 
f0101c6f:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101c76:	00 
f0101c77:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101c7e:	e8 11 e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c83:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c88:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101c8d:	e8 7b ed ff ff       	call   f0100a0d <check_va2pa>
f0101c92:	89 f2                	mov    %esi,%edx
f0101c94:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101c9a:	c1 fa 03             	sar    $0x3,%edx
f0101c9d:	c1 e2 0c             	shl    $0xc,%edx
f0101ca0:	39 d0                	cmp    %edx,%eax
f0101ca2:	74 24                	je     f0101cc8 <mem_init+0xae5>
f0101ca4:	c7 44 24 0c e4 48 10 	movl   $0xf01048e4,0xc(%esp)
f0101cab:	f0 
f0101cac:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101cb3:	f0 
f0101cb4:	c7 44 24 04 18 03 00 	movl   $0x318,0x4(%esp)
f0101cbb:	00 
f0101cbc:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101cc3:	e8 cc e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101cc8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ccd:	74 24                	je     f0101cf3 <mem_init+0xb10>
f0101ccf:	c7 44 24 0c 1b 45 10 	movl   $0xf010451b,0xc(%esp)
f0101cd6:	f0 
f0101cd7:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101cde:	f0 
f0101cdf:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f0101ce6:	00 
f0101ce7:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101cee:	e8 a1 e3 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101cf3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cfa:	e8 c5 f1 ff ff       	call   f0100ec4 <page_alloc>
f0101cff:	85 c0                	test   %eax,%eax
f0101d01:	74 24                	je     f0101d27 <mem_init+0xb44>
f0101d03:	c7 44 24 0c a7 44 10 	movl   $0xf01044a7,0xc(%esp)
f0101d0a:	f0 
f0101d0b:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101d12:	f0 
f0101d13:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f0101d1a:	00 
f0101d1b:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101d22:	e8 6d e3 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d27:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f0101d2d:	8b 02                	mov    (%edx),%eax
f0101d2f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d34:	89 c1                	mov    %eax,%ecx
f0101d36:	c1 e9 0c             	shr    $0xc,%ecx
f0101d39:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0101d3f:	72 20                	jb     f0101d61 <mem_init+0xb7e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d41:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d45:	c7 44 24 08 10 46 10 	movl   $0xf0104610,0x8(%esp)
f0101d4c:	f0 
f0101d4d:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0101d54:	00 
f0101d55:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101d5c:	e8 33 e3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101d61:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d66:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d69:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d70:	00 
f0101d71:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101d78:	00 
f0101d79:	89 14 24             	mov    %edx,(%esp)
f0101d7c:	e8 31 f2 ff ff       	call   f0100fb2 <pgdir_walk>
f0101d81:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101d84:	8d 51 04             	lea    0x4(%ecx),%edx
f0101d87:	39 d0                	cmp    %edx,%eax
f0101d89:	74 24                	je     f0101daf <mem_init+0xbcc>
f0101d8b:	c7 44 24 0c 14 49 10 	movl   $0xf0104914,0xc(%esp)
f0101d92:	f0 
f0101d93:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101d9a:	f0 
f0101d9b:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0101da2:	00 
f0101da3:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101daa:	e8 e5 e2 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101daf:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101db6:	00 
f0101db7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101dbe:	00 
f0101dbf:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101dc3:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101dc8:	89 04 24             	mov    %eax,(%esp)
f0101dcb:	e8 a4 f3 ff ff       	call   f0101174 <page_insert>
f0101dd0:	85 c0                	test   %eax,%eax
f0101dd2:	74 24                	je     f0101df8 <mem_init+0xc15>
f0101dd4:	c7 44 24 0c 54 49 10 	movl   $0xf0104954,0xc(%esp)
f0101ddb:	f0 
f0101ddc:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101de3:	f0 
f0101de4:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0101deb:	00 
f0101dec:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101df3:	e8 9c e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101df8:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101dfe:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e03:	89 f8                	mov    %edi,%eax
f0101e05:	e8 03 ec ff ff       	call   f0100a0d <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e0a:	89 f2                	mov    %esi,%edx
f0101e0c:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101e12:	c1 fa 03             	sar    $0x3,%edx
f0101e15:	c1 e2 0c             	shl    $0xc,%edx
f0101e18:	39 d0                	cmp    %edx,%eax
f0101e1a:	74 24                	je     f0101e40 <mem_init+0xc5d>
f0101e1c:	c7 44 24 0c e4 48 10 	movl   $0xf01048e4,0xc(%esp)
f0101e23:	f0 
f0101e24:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101e2b:	f0 
f0101e2c:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0101e33:	00 
f0101e34:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101e3b:	e8 54 e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101e40:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e45:	74 24                	je     f0101e6b <mem_init+0xc88>
f0101e47:	c7 44 24 0c 1b 45 10 	movl   $0xf010451b,0xc(%esp)
f0101e4e:	f0 
f0101e4f:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101e56:	f0 
f0101e57:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f0101e5e:	00 
f0101e5f:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101e66:	e8 29 e2 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e6b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e72:	00 
f0101e73:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e7a:	00 
f0101e7b:	89 3c 24             	mov    %edi,(%esp)
f0101e7e:	e8 2f f1 ff ff       	call   f0100fb2 <pgdir_walk>
f0101e83:	f6 00 04             	testb  $0x4,(%eax)
f0101e86:	75 24                	jne    f0101eac <mem_init+0xcc9>
f0101e88:	c7 44 24 0c 94 49 10 	movl   $0xf0104994,0xc(%esp)
f0101e8f:	f0 
f0101e90:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101e97:	f0 
f0101e98:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f0101e9f:	00 
f0101ea0:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101ea7:	e8 e8 e1 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101eac:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101eb1:	f6 00 04             	testb  $0x4,(%eax)
f0101eb4:	75 24                	jne    f0101eda <mem_init+0xcf7>
f0101eb6:	c7 44 24 0c 2c 45 10 	movl   $0xf010452c,0xc(%esp)
f0101ebd:	f0 
f0101ebe:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101ec5:	f0 
f0101ec6:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f0101ecd:	00 
f0101ece:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101ed5:	e8 ba e1 ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101eda:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ee1:	00 
f0101ee2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ee9:	00 
f0101eea:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101eee:	89 04 24             	mov    %eax,(%esp)
f0101ef1:	e8 7e f2 ff ff       	call   f0101174 <page_insert>
f0101ef6:	85 c0                	test   %eax,%eax
f0101ef8:	74 24                	je     f0101f1e <mem_init+0xd3b>
f0101efa:	c7 44 24 0c a8 48 10 	movl   $0xf01048a8,0xc(%esp)
f0101f01:	f0 
f0101f02:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101f09:	f0 
f0101f0a:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0101f11:	00 
f0101f12:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101f19:	e8 76 e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101f1e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f25:	00 
f0101f26:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f2d:	00 
f0101f2e:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101f33:	89 04 24             	mov    %eax,(%esp)
f0101f36:	e8 77 f0 ff ff       	call   f0100fb2 <pgdir_walk>
f0101f3b:	f6 00 02             	testb  $0x2,(%eax)
f0101f3e:	75 24                	jne    f0101f64 <mem_init+0xd81>
f0101f40:	c7 44 24 0c c8 49 10 	movl   $0xf01049c8,0xc(%esp)
f0101f47:	f0 
f0101f48:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101f4f:	f0 
f0101f50:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f0101f57:	00 
f0101f58:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101f5f:	e8 30 e1 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f64:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f6b:	00 
f0101f6c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f73:	00 
f0101f74:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101f79:	89 04 24             	mov    %eax,(%esp)
f0101f7c:	e8 31 f0 ff ff       	call   f0100fb2 <pgdir_walk>
f0101f81:	f6 00 04             	testb  $0x4,(%eax)
f0101f84:	74 24                	je     f0101faa <mem_init+0xdc7>
f0101f86:	c7 44 24 0c fc 49 10 	movl   $0xf01049fc,0xc(%esp)
f0101f8d:	f0 
f0101f8e:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101f95:	f0 
f0101f96:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0101f9d:	00 
f0101f9e:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101fa5:	e8 ea e0 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101faa:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101fb1:	00 
f0101fb2:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101fb9:	00 
f0101fba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fbd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101fc1:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101fc6:	89 04 24             	mov    %eax,(%esp)
f0101fc9:	e8 a6 f1 ff ff       	call   f0101174 <page_insert>
f0101fce:	85 c0                	test   %eax,%eax
f0101fd0:	78 24                	js     f0101ff6 <mem_init+0xe13>
f0101fd2:	c7 44 24 0c 34 4a 10 	movl   $0xf0104a34,0xc(%esp)
f0101fd9:	f0 
f0101fda:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0101fe1:	f0 
f0101fe2:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0101fe9:	00 
f0101fea:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0101ff1:	e8 9e e0 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101ff6:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ffd:	00 
f0101ffe:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102005:	00 
f0102006:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010200a:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010200f:	89 04 24             	mov    %eax,(%esp)
f0102012:	e8 5d f1 ff ff       	call   f0101174 <page_insert>
f0102017:	85 c0                	test   %eax,%eax
f0102019:	74 24                	je     f010203f <mem_init+0xe5c>
f010201b:	c7 44 24 0c 6c 4a 10 	movl   $0xf0104a6c,0xc(%esp)
f0102022:	f0 
f0102023:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f010202a:	f0 
f010202b:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0102032:	00 
f0102033:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f010203a:	e8 55 e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010203f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102046:	00 
f0102047:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010204e:	00 
f010204f:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102054:	89 04 24             	mov    %eax,(%esp)
f0102057:	e8 56 ef ff ff       	call   f0100fb2 <pgdir_walk>
f010205c:	f6 00 04             	testb  $0x4,(%eax)
f010205f:	74 24                	je     f0102085 <mem_init+0xea2>
f0102061:	c7 44 24 0c fc 49 10 	movl   $0xf01049fc,0xc(%esp)
f0102068:	f0 
f0102069:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102070:	f0 
f0102071:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f0102078:	00 
f0102079:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102080:	e8 0f e0 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102085:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f010208b:	ba 00 00 00 00       	mov    $0x0,%edx
f0102090:	89 f8                	mov    %edi,%eax
f0102092:	e8 76 e9 ff ff       	call   f0100a0d <check_va2pa>
f0102097:	89 c1                	mov    %eax,%ecx
f0102099:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010209c:	89 d8                	mov    %ebx,%eax
f010209e:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01020a4:	c1 f8 03             	sar    $0x3,%eax
f01020a7:	c1 e0 0c             	shl    $0xc,%eax
f01020aa:	39 c1                	cmp    %eax,%ecx
f01020ac:	74 24                	je     f01020d2 <mem_init+0xeef>
f01020ae:	c7 44 24 0c a8 4a 10 	movl   $0xf0104aa8,0xc(%esp)
f01020b5:	f0 
f01020b6:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01020bd:	f0 
f01020be:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f01020c5:	00 
f01020c6:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01020cd:	e8 c2 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020d2:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020d7:	89 f8                	mov    %edi,%eax
f01020d9:	e8 2f e9 ff ff       	call   f0100a0d <check_va2pa>
f01020de:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01020e1:	74 24                	je     f0102107 <mem_init+0xf24>
f01020e3:	c7 44 24 0c d4 4a 10 	movl   $0xf0104ad4,0xc(%esp)
f01020ea:	f0 
f01020eb:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01020f2:	f0 
f01020f3:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f01020fa:	00 
f01020fb:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102102:	e8 8d df ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102107:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f010210c:	74 24                	je     f0102132 <mem_init+0xf4f>
f010210e:	c7 44 24 0c 42 45 10 	movl   $0xf0104542,0xc(%esp)
f0102115:	f0 
f0102116:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f010211d:	f0 
f010211e:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f0102125:	00 
f0102126:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f010212d:	e8 62 df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102132:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102137:	74 24                	je     f010215d <mem_init+0xf7a>
f0102139:	c7 44 24 0c 53 45 10 	movl   $0xf0104553,0xc(%esp)
f0102140:	f0 
f0102141:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102148:	f0 
f0102149:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f0102150:	00 
f0102151:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102158:	e8 37 df ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010215d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102164:	e8 5b ed ff ff       	call   f0100ec4 <page_alloc>
f0102169:	85 c0                	test   %eax,%eax
f010216b:	74 04                	je     f0102171 <mem_init+0xf8e>
f010216d:	39 c6                	cmp    %eax,%esi
f010216f:	74 24                	je     f0102195 <mem_init+0xfb2>
f0102171:	c7 44 24 0c 04 4b 10 	movl   $0xf0104b04,0xc(%esp)
f0102178:	f0 
f0102179:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102180:	f0 
f0102181:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f0102188:	00 
f0102189:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102190:	e8 ff de ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102195:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010219c:	00 
f010219d:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01021a2:	89 04 24             	mov    %eax,(%esp)
f01021a5:	e8 8c ef ff ff       	call   f0101136 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01021aa:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f01021b0:	ba 00 00 00 00       	mov    $0x0,%edx
f01021b5:	89 f8                	mov    %edi,%eax
f01021b7:	e8 51 e8 ff ff       	call   f0100a0d <check_va2pa>
f01021bc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021bf:	74 24                	je     f01021e5 <mem_init+0x1002>
f01021c1:	c7 44 24 0c 28 4b 10 	movl   $0xf0104b28,0xc(%esp)
f01021c8:	f0 
f01021c9:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01021d0:	f0 
f01021d1:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f01021d8:	00 
f01021d9:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01021e0:	e8 af de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01021e5:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021ea:	89 f8                	mov    %edi,%eax
f01021ec:	e8 1c e8 ff ff       	call   f0100a0d <check_va2pa>
f01021f1:	89 da                	mov    %ebx,%edx
f01021f3:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01021f9:	c1 fa 03             	sar    $0x3,%edx
f01021fc:	c1 e2 0c             	shl    $0xc,%edx
f01021ff:	39 d0                	cmp    %edx,%eax
f0102201:	74 24                	je     f0102227 <mem_init+0x1044>
f0102203:	c7 44 24 0c d4 4a 10 	movl   $0xf0104ad4,0xc(%esp)
f010220a:	f0 
f010220b:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102212:	f0 
f0102213:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f010221a:	00 
f010221b:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102222:	e8 6d de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0102227:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010222c:	74 24                	je     f0102252 <mem_init+0x106f>
f010222e:	c7 44 24 0c f9 44 10 	movl   $0xf01044f9,0xc(%esp)
f0102235:	f0 
f0102236:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f010223d:	f0 
f010223e:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f0102245:	00 
f0102246:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f010224d:	e8 42 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102252:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102257:	74 24                	je     f010227d <mem_init+0x109a>
f0102259:	c7 44 24 0c 53 45 10 	movl   $0xf0104553,0xc(%esp)
f0102260:	f0 
f0102261:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102268:	f0 
f0102269:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f0102270:	00 
f0102271:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102278:	e8 17 de ff ff       	call   f0100094 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f010227d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0102284:	00 
f0102285:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010228c:	00 
f010228d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102291:	89 3c 24             	mov    %edi,(%esp)
f0102294:	e8 db ee ff ff       	call   f0101174 <page_insert>
f0102299:	85 c0                	test   %eax,%eax
f010229b:	74 24                	je     f01022c1 <mem_init+0x10de>
f010229d:	c7 44 24 0c 4c 4b 10 	movl   $0xf0104b4c,0xc(%esp)
f01022a4:	f0 
f01022a5:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01022ac:	f0 
f01022ad:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f01022b4:	00 
f01022b5:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01022bc:	e8 d3 dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref);
f01022c1:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01022c6:	75 24                	jne    f01022ec <mem_init+0x1109>
f01022c8:	c7 44 24 0c 64 45 10 	movl   $0xf0104564,0xc(%esp)
f01022cf:	f0 
f01022d0:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01022d7:	f0 
f01022d8:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f01022df:	00 
f01022e0:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01022e7:	e8 a8 dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_link == NULL);
f01022ec:	83 3b 00             	cmpl   $0x0,(%ebx)
f01022ef:	74 24                	je     f0102315 <mem_init+0x1132>
f01022f1:	c7 44 24 0c 70 45 10 	movl   $0xf0104570,0xc(%esp)
f01022f8:	f0 
f01022f9:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102300:	f0 
f0102301:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0102308:	00 
f0102309:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102310:	e8 7f dd ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102315:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010231c:	00 
f010231d:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102322:	89 04 24             	mov    %eax,(%esp)
f0102325:	e8 0c ee ff ff       	call   f0101136 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010232a:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0102330:	ba 00 00 00 00       	mov    $0x0,%edx
f0102335:	89 f8                	mov    %edi,%eax
f0102337:	e8 d1 e6 ff ff       	call   f0100a0d <check_va2pa>
f010233c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010233f:	74 24                	je     f0102365 <mem_init+0x1182>
f0102341:	c7 44 24 0c 28 4b 10 	movl   $0xf0104b28,0xc(%esp)
f0102348:	f0 
f0102349:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102350:	f0 
f0102351:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f0102358:	00 
f0102359:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102360:	e8 2f dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102365:	ba 00 10 00 00       	mov    $0x1000,%edx
f010236a:	89 f8                	mov    %edi,%eax
f010236c:	e8 9c e6 ff ff       	call   f0100a0d <check_va2pa>
f0102371:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102374:	74 24                	je     f010239a <mem_init+0x11b7>
f0102376:	c7 44 24 0c 84 4b 10 	movl   $0xf0104b84,0xc(%esp)
f010237d:	f0 
f010237e:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102385:	f0 
f0102386:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f010238d:	00 
f010238e:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102395:	e8 fa dc ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f010239a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010239f:	74 24                	je     f01023c5 <mem_init+0x11e2>
f01023a1:	c7 44 24 0c 85 45 10 	movl   $0xf0104585,0xc(%esp)
f01023a8:	f0 
f01023a9:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01023b0:	f0 
f01023b1:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f01023b8:	00 
f01023b9:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01023c0:	e8 cf dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01023c5:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01023ca:	74 24                	je     f01023f0 <mem_init+0x120d>
f01023cc:	c7 44 24 0c 53 45 10 	movl   $0xf0104553,0xc(%esp)
f01023d3:	f0 
f01023d4:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01023db:	f0 
f01023dc:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f01023e3:	00 
f01023e4:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01023eb:	e8 a4 dc ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01023f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01023f7:	e8 c8 ea ff ff       	call   f0100ec4 <page_alloc>
f01023fc:	85 c0                	test   %eax,%eax
f01023fe:	74 04                	je     f0102404 <mem_init+0x1221>
f0102400:	39 c3                	cmp    %eax,%ebx
f0102402:	74 24                	je     f0102428 <mem_init+0x1245>
f0102404:	c7 44 24 0c ac 4b 10 	movl   $0xf0104bac,0xc(%esp)
f010240b:	f0 
f010240c:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102413:	f0 
f0102414:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f010241b:	00 
f010241c:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102423:	e8 6c dc ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102428:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010242f:	e8 90 ea ff ff       	call   f0100ec4 <page_alloc>
f0102434:	85 c0                	test   %eax,%eax
f0102436:	74 24                	je     f010245c <mem_init+0x1279>
f0102438:	c7 44 24 0c a7 44 10 	movl   $0xf01044a7,0xc(%esp)
f010243f:	f0 
f0102440:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102447:	f0 
f0102448:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f010244f:	00 
f0102450:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102457:	e8 38 dc ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010245c:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102461:	8b 08                	mov    (%eax),%ecx
f0102463:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102469:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010246c:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102472:	c1 fa 03             	sar    $0x3,%edx
f0102475:	c1 e2 0c             	shl    $0xc,%edx
f0102478:	39 d1                	cmp    %edx,%ecx
f010247a:	74 24                	je     f01024a0 <mem_init+0x12bd>
f010247c:	c7 44 24 0c 50 48 10 	movl   $0xf0104850,0xc(%esp)
f0102483:	f0 
f0102484:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f010248b:	f0 
f010248c:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0102493:	00 
f0102494:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f010249b:	e8 f4 db ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f01024a0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01024a6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01024a9:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01024ae:	74 24                	je     f01024d4 <mem_init+0x12f1>
f01024b0:	c7 44 24 0c 0a 45 10 	movl   $0xf010450a,0xc(%esp)
f01024b7:	f0 
f01024b8:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01024bf:	f0 
f01024c0:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f01024c7:	00 
f01024c8:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01024cf:	e8 c0 db ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f01024d4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01024d7:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01024dd:	89 04 24             	mov    %eax,(%esp)
f01024e0:	e8 6a ea ff ff       	call   f0100f4f <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01024e5:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01024ec:	00 
f01024ed:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01024f4:	00 
f01024f5:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01024fa:	89 04 24             	mov    %eax,(%esp)
f01024fd:	e8 b0 ea ff ff       	call   f0100fb2 <pgdir_walk>
f0102502:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102505:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102508:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f010250e:	8b 7a 04             	mov    0x4(%edx),%edi
f0102511:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102517:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f010251d:	89 f8                	mov    %edi,%eax
f010251f:	c1 e8 0c             	shr    $0xc,%eax
f0102522:	39 c8                	cmp    %ecx,%eax
f0102524:	72 20                	jb     f0102546 <mem_init+0x1363>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102526:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010252a:	c7 44 24 08 10 46 10 	movl   $0xf0104610,0x8(%esp)
f0102531:	f0 
f0102532:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f0102539:	00 
f010253a:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102541:	e8 4e db ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102546:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f010254c:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f010254f:	74 24                	je     f0102575 <mem_init+0x1392>
f0102551:	c7 44 24 0c 96 45 10 	movl   $0xf0104596,0xc(%esp)
f0102558:	f0 
f0102559:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102560:	f0 
f0102561:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f0102568:	00 
f0102569:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102570:	e8 1f db ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102575:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f010257c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010257f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102585:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010258b:	c1 f8 03             	sar    $0x3,%eax
f010258e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102591:	89 c2                	mov    %eax,%edx
f0102593:	c1 ea 0c             	shr    $0xc,%edx
f0102596:	39 d1                	cmp    %edx,%ecx
f0102598:	77 20                	ja     f01025ba <mem_init+0x13d7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010259a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010259e:	c7 44 24 08 10 46 10 	movl   $0xf0104610,0x8(%esp)
f01025a5:	f0 
f01025a6:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01025ad:	00 
f01025ae:	c7 04 24 06 43 10 f0 	movl   $0xf0104306,(%esp)
f01025b5:	e8 da da ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01025ba:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01025c1:	00 
f01025c2:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01025c9:	00 
	return (void *)(pa + KERNBASE);
f01025ca:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025cf:	89 04 24             	mov    %eax,(%esp)
f01025d2:	e8 60 13 00 00       	call   f0103937 <memset>
	page_free(pp0);
f01025d7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01025da:	89 3c 24             	mov    %edi,(%esp)
f01025dd:	e8 6d e9 ff ff       	call   f0100f4f <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01025e2:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01025e9:	00 
f01025ea:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01025f1:	00 
f01025f2:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01025f7:	89 04 24             	mov    %eax,(%esp)
f01025fa:	e8 b3 e9 ff ff       	call   f0100fb2 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025ff:	89 fa                	mov    %edi,%edx
f0102601:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102607:	c1 fa 03             	sar    $0x3,%edx
f010260a:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010260d:	89 d0                	mov    %edx,%eax
f010260f:	c1 e8 0c             	shr    $0xc,%eax
f0102612:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0102618:	72 20                	jb     f010263a <mem_init+0x1457>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010261a:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010261e:	c7 44 24 08 10 46 10 	movl   $0xf0104610,0x8(%esp)
f0102625:	f0 
f0102626:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010262d:	00 
f010262e:	c7 04 24 06 43 10 f0 	movl   $0xf0104306,(%esp)
f0102635:	e8 5a da ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f010263a:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102640:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102643:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102649:	f6 00 01             	testb  $0x1,(%eax)
f010264c:	74 24                	je     f0102672 <mem_init+0x148f>
f010264e:	c7 44 24 0c ae 45 10 	movl   $0xf01045ae,0xc(%esp)
f0102655:	f0 
f0102656:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f010265d:	f0 
f010265e:	c7 44 24 04 6e 03 00 	movl   $0x36e,0x4(%esp)
f0102665:	00 
f0102666:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f010266d:	e8 22 da ff ff       	call   f0100094 <_panic>
f0102672:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102675:	39 d0                	cmp    %edx,%eax
f0102677:	75 d0                	jne    f0102649 <mem_init+0x1466>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102679:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010267e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102684:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102687:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010268d:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102690:	89 3d 3c 75 11 f0    	mov    %edi,0xf011753c

	// free the pages we took
	page_free(pp0);
f0102696:	89 04 24             	mov    %eax,(%esp)
f0102699:	e8 b1 e8 ff ff       	call   f0100f4f <page_free>
	page_free(pp1);
f010269e:	89 1c 24             	mov    %ebx,(%esp)
f01026a1:	e8 a9 e8 ff ff       	call   f0100f4f <page_free>
	page_free(pp2);
f01026a6:	89 34 24             	mov    %esi,(%esp)
f01026a9:	e8 a1 e8 ff ff       	call   f0100f4f <page_free>

	cprintf("check_page() succeeded!\n");
f01026ae:	c7 04 24 c5 45 10 f0 	movl   $0xf01045c5,(%esp)
f01026b5:	e8 10 07 00 00       	call   f0102dca <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U|PTE_P);
f01026ba:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026bf:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026c4:	77 20                	ja     f01026e6 <mem_init+0x1503>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026c6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01026ca:	c7 44 24 08 f8 46 10 	movl   $0xf01046f8,0x8(%esp)
f01026d1:	f0 
f01026d2:	c7 44 24 04 ba 00 00 	movl   $0xba,0x4(%esp)
f01026d9:	00 
f01026da:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01026e1:	e8 ae d9 ff ff       	call   f0100094 <_panic>
f01026e6:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01026ed:	00 
	return (physaddr_t)kva - KERNBASE;
f01026ee:	05 00 00 00 10       	add    $0x10000000,%eax
f01026f3:	89 04 24             	mov    %eax,(%esp)
f01026f6:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01026fb:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102700:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102705:	e8 48 e9 ff ff       	call   f0101052 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010270a:	bb 00 d0 10 f0       	mov    $0xf010d000,%ebx
f010270f:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102715:	77 20                	ja     f0102737 <mem_init+0x1554>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102717:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010271b:	c7 44 24 08 f8 46 10 	movl   $0xf01046f8,0x8(%esp)
f0102722:	f0 
f0102723:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
f010272a:	00 
f010272b:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102732:	e8 5d d9 ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W|PTE_P);
f0102737:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f010273e:	00 
f010273f:	c7 04 24 00 d0 10 00 	movl   $0x10d000,(%esp)
f0102746:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010274b:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102750:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102755:	e8 f8 e8 ff ff       	call   f0101052 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff-KERNBASE, 0,PTE_W|PTE_P);
f010275a:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102761:	00 
f0102762:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102769:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010276e:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102773:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102778:	e8 d5 e8 ff ff       	call   f0101052 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010277d:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102783:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0102788:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010278b:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102792:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102797:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010279a:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f010279f:	89 45 cc             	mov    %eax,-0x34(%ebp)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027a2:	89 45 c8             	mov    %eax,-0x38(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f01027a5:	05 00 00 00 10       	add    $0x10000000,%eax
f01027aa:	89 45 c4             	mov    %eax,-0x3c(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01027ad:	be 00 00 00 00       	mov    $0x0,%esi
f01027b2:	eb 6d                	jmp    f0102821 <mem_init+0x163e>
f01027b4:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01027ba:	89 f8                	mov    %edi,%eax
f01027bc:	e8 4c e2 ff ff       	call   f0100a0d <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027c1:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f01027c8:	77 23                	ja     f01027ed <mem_init+0x160a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027ca:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01027cd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01027d1:	c7 44 24 08 f8 46 10 	movl   $0xf01046f8,0x8(%esp)
f01027d8:	f0 
f01027d9:	c7 44 24 04 b0 02 00 	movl   $0x2b0,0x4(%esp)
f01027e0:	00 
f01027e1:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01027e8:	e8 a7 d8 ff ff       	call   f0100094 <_panic>
f01027ed:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f01027f0:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01027f3:	39 c2                	cmp    %eax,%edx
f01027f5:	74 24                	je     f010281b <mem_init+0x1638>
f01027f7:	c7 44 24 0c d0 4b 10 	movl   $0xf0104bd0,0xc(%esp)
f01027fe:	f0 
f01027ff:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102806:	f0 
f0102807:	c7 44 24 04 b0 02 00 	movl   $0x2b0,0x4(%esp)
f010280e:	00 
f010280f:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102816:	e8 79 d8 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010281b:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102821:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f0102824:	77 8e                	ja     f01027b4 <mem_init+0x15d1>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102826:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102829:	c1 e0 0c             	shl    $0xc,%eax
f010282c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010282f:	be 00 00 00 00       	mov    $0x0,%esi
f0102834:	eb 3b                	jmp    f0102871 <mem_init+0x168e>
f0102836:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010283c:	89 f8                	mov    %edi,%eax
f010283e:	e8 ca e1 ff ff       	call   f0100a0d <check_va2pa>
f0102843:	39 c6                	cmp    %eax,%esi
f0102845:	74 24                	je     f010286b <mem_init+0x1688>
f0102847:	c7 44 24 0c 04 4c 10 	movl   $0xf0104c04,0xc(%esp)
f010284e:	f0 
f010284f:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102856:	f0 
f0102857:	c7 44 24 04 b5 02 00 	movl   $0x2b5,0x4(%esp)
f010285e:	00 
f010285f:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102866:	e8 29 d8 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010286b:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102871:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0102874:	72 c0                	jb     f0102836 <mem_init+0x1653>
f0102876:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f010287b:	81 c3 00 80 00 20    	add    $0x20008000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102881:	89 f2                	mov    %esi,%edx
f0102883:	89 f8                	mov    %edi,%eax
f0102885:	e8 83 e1 ff ff       	call   f0100a0d <check_va2pa>
f010288a:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f010288d:	39 d0                	cmp    %edx,%eax
f010288f:	74 24                	je     f01028b5 <mem_init+0x16d2>
f0102891:	c7 44 24 0c 2c 4c 10 	movl   $0xf0104c2c,0xc(%esp)
f0102898:	f0 
f0102899:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01028a0:	f0 
f01028a1:	c7 44 24 04 b9 02 00 	movl   $0x2b9,0x4(%esp)
f01028a8:	00 
f01028a9:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01028b0:	e8 df d7 ff ff       	call   f0100094 <_panic>
f01028b5:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01028bb:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01028c1:	75 be                	jne    f0102881 <mem_init+0x169e>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01028c3:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01028c8:	89 f8                	mov    %edi,%eax
f01028ca:	e8 3e e1 ff ff       	call   f0100a0d <check_va2pa>
f01028cf:	83 f8 ff             	cmp    $0xffffffff,%eax
f01028d2:	75 0a                	jne    f01028de <mem_init+0x16fb>
f01028d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01028d9:	e9 f0 00 00 00       	jmp    f01029ce <mem_init+0x17eb>
f01028de:	c7 44 24 0c 74 4c 10 	movl   $0xf0104c74,0xc(%esp)
f01028e5:	f0 
f01028e6:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01028ed:	f0 
f01028ee:	c7 44 24 04 ba 02 00 	movl   $0x2ba,0x4(%esp)
f01028f5:	00 
f01028f6:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01028fd:	e8 92 d7 ff ff       	call   f0100094 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102902:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102907:	72 3c                	jb     f0102945 <mem_init+0x1762>
f0102909:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010290e:	76 07                	jbe    f0102917 <mem_init+0x1734>
f0102910:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102915:	75 2e                	jne    f0102945 <mem_init+0x1762>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102917:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f010291b:	0f 85 aa 00 00 00    	jne    f01029cb <mem_init+0x17e8>
f0102921:	c7 44 24 0c de 45 10 	movl   $0xf01045de,0xc(%esp)
f0102928:	f0 
f0102929:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102930:	f0 
f0102931:	c7 44 24 04 c2 02 00 	movl   $0x2c2,0x4(%esp)
f0102938:	00 
f0102939:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102940:	e8 4f d7 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102945:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010294a:	76 55                	jbe    f01029a1 <mem_init+0x17be>
				assert(pgdir[i] & PTE_P);
f010294c:	8b 14 87             	mov    (%edi,%eax,4),%edx
f010294f:	f6 c2 01             	test   $0x1,%dl
f0102952:	75 24                	jne    f0102978 <mem_init+0x1795>
f0102954:	c7 44 24 0c de 45 10 	movl   $0xf01045de,0xc(%esp)
f010295b:	f0 
f010295c:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102963:	f0 
f0102964:	c7 44 24 04 c6 02 00 	movl   $0x2c6,0x4(%esp)
f010296b:	00 
f010296c:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102973:	e8 1c d7 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0102978:	f6 c2 02             	test   $0x2,%dl
f010297b:	75 4e                	jne    f01029cb <mem_init+0x17e8>
f010297d:	c7 44 24 0c ef 45 10 	movl   $0xf01045ef,0xc(%esp)
f0102984:	f0 
f0102985:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f010298c:	f0 
f010298d:	c7 44 24 04 c7 02 00 	movl   $0x2c7,0x4(%esp)
f0102994:	00 
f0102995:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f010299c:	e8 f3 d6 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f01029a1:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01029a5:	74 24                	je     f01029cb <mem_init+0x17e8>
f01029a7:	c7 44 24 0c 00 46 10 	movl   $0xf0104600,0xc(%esp)
f01029ae:	f0 
f01029af:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f01029b6:	f0 
f01029b7:	c7 44 24 04 c9 02 00 	movl   $0x2c9,0x4(%esp)
f01029be:	00 
f01029bf:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f01029c6:	e8 c9 d6 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01029cb:	83 c0 01             	add    $0x1,%eax
f01029ce:	3d 00 04 00 00       	cmp    $0x400,%eax
f01029d3:	0f 85 29 ff ff ff    	jne    f0102902 <mem_init+0x171f>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01029d9:	c7 04 24 a4 4c 10 f0 	movl   $0xf0104ca4,(%esp)
f01029e0:	e8 e5 03 00 00       	call   f0102dca <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01029e5:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029ea:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029ef:	77 20                	ja     f0102a11 <mem_init+0x182e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029f1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029f5:	c7 44 24 08 f8 46 10 	movl   $0xf01046f8,0x8(%esp)
f01029fc:	f0 
f01029fd:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
f0102a04:	00 
f0102a05:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102a0c:	e8 83 d6 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102a11:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102a16:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102a19:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a1e:	e8 59 e0 ff ff       	call   f0100a7c <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102a23:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102a26:	83 e0 f3             	and    $0xfffffff3,%eax
f0102a29:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102a2e:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102a31:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a38:	e8 87 e4 ff ff       	call   f0100ec4 <page_alloc>
f0102a3d:	89 c3                	mov    %eax,%ebx
f0102a3f:	85 c0                	test   %eax,%eax
f0102a41:	75 24                	jne    f0102a67 <mem_init+0x1884>
f0102a43:	c7 44 24 0c fc 43 10 	movl   $0xf01043fc,0xc(%esp)
f0102a4a:	f0 
f0102a4b:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102a52:	f0 
f0102a53:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f0102a5a:	00 
f0102a5b:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102a62:	e8 2d d6 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102a67:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a6e:	e8 51 e4 ff ff       	call   f0100ec4 <page_alloc>
f0102a73:	89 c7                	mov    %eax,%edi
f0102a75:	85 c0                	test   %eax,%eax
f0102a77:	75 24                	jne    f0102a9d <mem_init+0x18ba>
f0102a79:	c7 44 24 0c 12 44 10 	movl   $0xf0104412,0xc(%esp)
f0102a80:	f0 
f0102a81:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102a88:	f0 
f0102a89:	c7 44 24 04 8a 03 00 	movl   $0x38a,0x4(%esp)
f0102a90:	00 
f0102a91:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102a98:	e8 f7 d5 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102a9d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102aa4:	e8 1b e4 ff ff       	call   f0100ec4 <page_alloc>
f0102aa9:	89 c6                	mov    %eax,%esi
f0102aab:	85 c0                	test   %eax,%eax
f0102aad:	75 24                	jne    f0102ad3 <mem_init+0x18f0>
f0102aaf:	c7 44 24 0c 28 44 10 	movl   $0xf0104428,0xc(%esp)
f0102ab6:	f0 
f0102ab7:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102abe:	f0 
f0102abf:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f0102ac6:	00 
f0102ac7:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102ace:	e8 c1 d5 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102ad3:	89 1c 24             	mov    %ebx,(%esp)
f0102ad6:	e8 74 e4 ff ff       	call   f0100f4f <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102adb:	89 f8                	mov    %edi,%eax
f0102add:	e8 e6 de ff ff       	call   f01009c8 <page2kva>
f0102ae2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ae9:	00 
f0102aea:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102af1:	00 
f0102af2:	89 04 24             	mov    %eax,(%esp)
f0102af5:	e8 3d 0e 00 00       	call   f0103937 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102afa:	89 f0                	mov    %esi,%eax
f0102afc:	e8 c7 de ff ff       	call   f01009c8 <page2kva>
f0102b01:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b08:	00 
f0102b09:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102b10:	00 
f0102b11:	89 04 24             	mov    %eax,(%esp)
f0102b14:	e8 1e 0e 00 00       	call   f0103937 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b19:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102b20:	00 
f0102b21:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b28:	00 
f0102b29:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102b2d:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102b32:	89 04 24             	mov    %eax,(%esp)
f0102b35:	e8 3a e6 ff ff       	call   f0101174 <page_insert>
	assert(pp1->pp_ref == 1);
f0102b3a:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102b3f:	74 24                	je     f0102b65 <mem_init+0x1982>
f0102b41:	c7 44 24 0c f9 44 10 	movl   $0xf01044f9,0xc(%esp)
f0102b48:	f0 
f0102b49:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102b50:	f0 
f0102b51:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f0102b58:	00 
f0102b59:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102b60:	e8 2f d5 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102b65:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102b6c:	01 01 01 
f0102b6f:	74 24                	je     f0102b95 <mem_init+0x19b2>
f0102b71:	c7 44 24 0c c4 4c 10 	movl   $0xf0104cc4,0xc(%esp)
f0102b78:	f0 
f0102b79:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102b80:	f0 
f0102b81:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f0102b88:	00 
f0102b89:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102b90:	e8 ff d4 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102b95:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102b9c:	00 
f0102b9d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ba4:	00 
f0102ba5:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102ba9:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102bae:	89 04 24             	mov    %eax,(%esp)
f0102bb1:	e8 be e5 ff ff       	call   f0101174 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102bb6:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102bbd:	02 02 02 
f0102bc0:	74 24                	je     f0102be6 <mem_init+0x1a03>
f0102bc2:	c7 44 24 0c e8 4c 10 	movl   $0xf0104ce8,0xc(%esp)
f0102bc9:	f0 
f0102bca:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102bd1:	f0 
f0102bd2:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0102bd9:	00 
f0102bda:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102be1:	e8 ae d4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102be6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102beb:	74 24                	je     f0102c11 <mem_init+0x1a2e>
f0102bed:	c7 44 24 0c 1b 45 10 	movl   $0xf010451b,0xc(%esp)
f0102bf4:	f0 
f0102bf5:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102bfc:	f0 
f0102bfd:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f0102c04:	00 
f0102c05:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102c0c:	e8 83 d4 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102c11:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102c16:	74 24                	je     f0102c3c <mem_init+0x1a59>
f0102c18:	c7 44 24 0c 85 45 10 	movl   $0xf0104585,0xc(%esp)
f0102c1f:	f0 
f0102c20:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102c27:	f0 
f0102c28:	c7 44 24 04 95 03 00 	movl   $0x395,0x4(%esp)
f0102c2f:	00 
f0102c30:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102c37:	e8 58 d4 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102c3c:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102c43:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c46:	89 f0                	mov    %esi,%eax
f0102c48:	e8 7b dd ff ff       	call   f01009c8 <page2kva>
f0102c4d:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102c53:	74 24                	je     f0102c79 <mem_init+0x1a96>
f0102c55:	c7 44 24 0c 0c 4d 10 	movl   $0xf0104d0c,0xc(%esp)
f0102c5c:	f0 
f0102c5d:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102c64:	f0 
f0102c65:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0102c6c:	00 
f0102c6d:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102c74:	e8 1b d4 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c79:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102c80:	00 
f0102c81:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102c86:	89 04 24             	mov    %eax,(%esp)
f0102c89:	e8 a8 e4 ff ff       	call   f0101136 <page_remove>
	assert(pp2->pp_ref == 0);
f0102c8e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102c93:	74 24                	je     f0102cb9 <mem_init+0x1ad6>
f0102c95:	c7 44 24 0c 53 45 10 	movl   $0xf0104553,0xc(%esp)
f0102c9c:	f0 
f0102c9d:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102ca4:	f0 
f0102ca5:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f0102cac:	00 
f0102cad:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102cb4:	e8 db d3 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102cb9:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102cbe:	8b 08                	mov    (%eax),%ecx
f0102cc0:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102cc6:	89 da                	mov    %ebx,%edx
f0102cc8:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102cce:	c1 fa 03             	sar    $0x3,%edx
f0102cd1:	c1 e2 0c             	shl    $0xc,%edx
f0102cd4:	39 d1                	cmp    %edx,%ecx
f0102cd6:	74 24                	je     f0102cfc <mem_init+0x1b19>
f0102cd8:	c7 44 24 0c 50 48 10 	movl   $0xf0104850,0xc(%esp)
f0102cdf:	f0 
f0102ce0:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102ce7:	f0 
f0102ce8:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f0102cef:	00 
f0102cf0:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102cf7:	e8 98 d3 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102cfc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102d02:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102d07:	74 24                	je     f0102d2d <mem_init+0x1b4a>
f0102d09:	c7 44 24 0c 0a 45 10 	movl   $0xf010450a,0xc(%esp)
f0102d10:	f0 
f0102d11:	c7 44 24 08 20 43 10 	movl   $0xf0104320,0x8(%esp)
f0102d18:	f0 
f0102d19:	c7 44 24 04 9e 03 00 	movl   $0x39e,0x4(%esp)
f0102d20:	00 
f0102d21:	c7 04 24 fa 42 10 f0 	movl   $0xf01042fa,(%esp)
f0102d28:	e8 67 d3 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102d2d:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102d33:	89 1c 24             	mov    %ebx,(%esp)
f0102d36:	e8 14 e2 ff ff       	call   f0100f4f <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102d3b:	c7 04 24 38 4d 10 f0 	movl   $0xf0104d38,(%esp)
f0102d42:	e8 83 00 00 00       	call   f0102dca <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102d47:	83 c4 4c             	add    $0x4c,%esp
f0102d4a:	5b                   	pop    %ebx
f0102d4b:	5e                   	pop    %esi
f0102d4c:	5f                   	pop    %edi
f0102d4d:	5d                   	pop    %ebp
f0102d4e:	c3                   	ret    

f0102d4f <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102d4f:	55                   	push   %ebp
f0102d50:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102d52:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d55:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102d58:	5d                   	pop    %ebp
f0102d59:	c3                   	ret    

f0102d5a <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102d5a:	55                   	push   %ebp
f0102d5b:	89 e5                	mov    %esp,%ebp
f0102d5d:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102d61:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d66:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102d67:	b2 71                	mov    $0x71,%dl
f0102d69:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102d6a:	0f b6 c0             	movzbl %al,%eax
}
f0102d6d:	5d                   	pop    %ebp
f0102d6e:	c3                   	ret    

f0102d6f <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102d6f:	55                   	push   %ebp
f0102d70:	89 e5                	mov    %esp,%ebp
f0102d72:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102d76:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d7b:	ee                   	out    %al,(%dx)
f0102d7c:	b2 71                	mov    $0x71,%dl
f0102d7e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d81:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102d82:	5d                   	pop    %ebp
f0102d83:	c3                   	ret    

f0102d84 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102d84:	55                   	push   %ebp
f0102d85:	89 e5                	mov    %esp,%ebp
f0102d87:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102d8a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d8d:	89 04 24             	mov    %eax,(%esp)
f0102d90:	e8 87 d8 ff ff       	call   f010061c <cputchar>
//调用了console.c中的cputchar程序
	*cnt++;
}
f0102d95:	c9                   	leave  
f0102d96:	c3                   	ret    

f0102d97 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102d97:	55                   	push   %ebp
f0102d98:	89 e5                	mov    %esp,%ebp
f0102d9a:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102d9d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102da4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102da7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102dab:	8b 45 08             	mov    0x8(%ebp),%eax
f0102dae:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102db2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102db5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102db9:	c7 04 24 84 2d 10 f0 	movl   $0xf0102d84,(%esp)
f0102dc0:	e8 b9 04 00 00       	call   f010327e <vprintfmt>
//调用了printfmt.c中的vprintfmt（）
	return cnt;
}
f0102dc5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102dc8:	c9                   	leave  
f0102dc9:	c3                   	ret    

f0102dca <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102dca:	55                   	push   %ebp
f0102dcb:	89 e5                	mov    %esp,%ebp
f0102dcd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102dd0:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102dd3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102dd7:	8b 45 08             	mov    0x8(%ebp),%eax
f0102dda:	89 04 24             	mov    %eax,(%esp)
f0102ddd:	e8 b5 ff ff ff       	call   f0102d97 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102de2:	c9                   	leave  
f0102de3:	c3                   	ret    

f0102de4 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102de4:	55                   	push   %ebp
f0102de5:	89 e5                	mov    %esp,%ebp
f0102de7:	57                   	push   %edi
f0102de8:	56                   	push   %esi
f0102de9:	53                   	push   %ebx
f0102dea:	83 ec 10             	sub    $0x10,%esp
f0102ded:	89 c6                	mov    %eax,%esi
f0102def:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102df2:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102df5:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102df8:	8b 1a                	mov    (%edx),%ebx
f0102dfa:	8b 01                	mov    (%ecx),%eax
f0102dfc:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102dff:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0102e06:	eb 77                	jmp    f0102e7f <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0102e08:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102e0b:	01 d8                	add    %ebx,%eax
f0102e0d:	b9 02 00 00 00       	mov    $0x2,%ecx
f0102e12:	99                   	cltd   
f0102e13:	f7 f9                	idiv   %ecx
f0102e15:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102e17:	eb 01                	jmp    f0102e1a <stab_binsearch+0x36>
			m--;
f0102e19:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102e1a:	39 d9                	cmp    %ebx,%ecx
f0102e1c:	7c 1d                	jl     f0102e3b <stab_binsearch+0x57>
f0102e1e:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102e21:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102e26:	39 fa                	cmp    %edi,%edx
f0102e28:	75 ef                	jne    f0102e19 <stab_binsearch+0x35>
f0102e2a:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102e2d:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102e30:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0102e34:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102e37:	73 18                	jae    f0102e51 <stab_binsearch+0x6d>
f0102e39:	eb 05                	jmp    f0102e40 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102e3b:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0102e3e:	eb 3f                	jmp    f0102e7f <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102e40:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102e43:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0102e45:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102e48:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102e4f:	eb 2e                	jmp    f0102e7f <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102e51:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102e54:	73 15                	jae    f0102e6b <stab_binsearch+0x87>
			*region_right = m - 1;
f0102e56:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102e59:	48                   	dec    %eax
f0102e5a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102e5d:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102e60:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102e62:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102e69:	eb 14                	jmp    f0102e7f <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102e6b:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102e6e:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0102e71:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0102e73:	ff 45 0c             	incl   0xc(%ebp)
f0102e76:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102e78:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102e7f:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102e82:	7e 84                	jle    f0102e08 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102e84:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102e88:	75 0d                	jne    f0102e97 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0102e8a:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102e8d:	8b 00                	mov    (%eax),%eax
f0102e8f:	48                   	dec    %eax
f0102e90:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e93:	89 07                	mov    %eax,(%edi)
f0102e95:	eb 22                	jmp    f0102eb9 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e97:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102e9a:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102e9c:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102e9f:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102ea1:	eb 01                	jmp    f0102ea4 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102ea3:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102ea4:	39 c1                	cmp    %eax,%ecx
f0102ea6:	7d 0c                	jge    f0102eb4 <stab_binsearch+0xd0>
f0102ea8:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0102eab:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102eb0:	39 fa                	cmp    %edi,%edx
f0102eb2:	75 ef                	jne    f0102ea3 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102eb4:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0102eb7:	89 07                	mov    %eax,(%edi)
	}
}
f0102eb9:	83 c4 10             	add    $0x10,%esp
f0102ebc:	5b                   	pop    %ebx
f0102ebd:	5e                   	pop    %esi
f0102ebe:	5f                   	pop    %edi
f0102ebf:	5d                   	pop    %ebp
f0102ec0:	c3                   	ret    

f0102ec1 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102ec1:	55                   	push   %ebp
f0102ec2:	89 e5                	mov    %esp,%ebp
f0102ec4:	57                   	push   %edi
f0102ec5:	56                   	push   %esi
f0102ec6:	53                   	push   %ebx
f0102ec7:	83 ec 3c             	sub    $0x3c,%esp
f0102eca:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ecd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102ed0:	c7 03 64 4d 10 f0    	movl   $0xf0104d64,(%ebx)
	info->eip_line = 0;
f0102ed6:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102edd:	c7 43 08 64 4d 10 f0 	movl   $0xf0104d64,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102ee4:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102eeb:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102eee:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102ef5:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102efb:	76 12                	jbe    f0102f0f <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102efd:	b8 64 ca 10 f0       	mov    $0xf010ca64,%eax
f0102f02:	3d 99 ac 10 f0       	cmp    $0xf010ac99,%eax
f0102f07:	0f 86 d2 01 00 00    	jbe    f01030df <debuginfo_eip+0x21e>
f0102f0d:	eb 1c                	jmp    f0102f2b <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102f0f:	c7 44 24 08 6e 4d 10 	movl   $0xf0104d6e,0x8(%esp)
f0102f16:	f0 
f0102f17:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102f1e:	00 
f0102f1f:	c7 04 24 7b 4d 10 f0 	movl   $0xf0104d7b,(%esp)
f0102f26:	e8 69 d1 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102f2b:	80 3d 63 ca 10 f0 00 	cmpb   $0x0,0xf010ca63
f0102f32:	0f 85 ae 01 00 00    	jne    f01030e6 <debuginfo_eip+0x225>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102f38:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102f3f:	b8 98 ac 10 f0       	mov    $0xf010ac98,%eax
f0102f44:	2d b0 4f 10 f0       	sub    $0xf0104fb0,%eax
f0102f49:	c1 f8 02             	sar    $0x2,%eax
f0102f4c:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102f52:	83 e8 01             	sub    $0x1,%eax
f0102f55:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102f58:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f5c:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102f63:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102f66:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102f69:	b8 b0 4f 10 f0       	mov    $0xf0104fb0,%eax
f0102f6e:	e8 71 fe ff ff       	call   f0102de4 <stab_binsearch>
	if (lfile == 0)
f0102f73:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102f76:	85 c0                	test   %eax,%eax
f0102f78:	0f 84 6f 01 00 00    	je     f01030ed <debuginfo_eip+0x22c>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102f7e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102f81:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102f84:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102f87:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f8b:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102f92:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102f95:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102f98:	b8 b0 4f 10 f0       	mov    $0xf0104fb0,%eax
f0102f9d:	e8 42 fe ff ff       	call   f0102de4 <stab_binsearch>

	if (lfun <= rfun) {
f0102fa2:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102fa5:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102fa8:	39 d0                	cmp    %edx,%eax
f0102faa:	7f 3d                	jg     f0102fe9 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102fac:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0102faf:	8d b9 b0 4f 10 f0    	lea    -0xfefb050(%ecx),%edi
f0102fb5:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102fb8:	8b 89 b0 4f 10 f0    	mov    -0xfefb050(%ecx),%ecx
f0102fbe:	bf 64 ca 10 f0       	mov    $0xf010ca64,%edi
f0102fc3:	81 ef 99 ac 10 f0    	sub    $0xf010ac99,%edi
f0102fc9:	39 f9                	cmp    %edi,%ecx
f0102fcb:	73 09                	jae    f0102fd6 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102fcd:	81 c1 99 ac 10 f0    	add    $0xf010ac99,%ecx
f0102fd3:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102fd6:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102fd9:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102fdc:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102fdf:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102fe1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102fe4:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102fe7:	eb 0f                	jmp    f0102ff8 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102fe9:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102fec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102fef:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102ff2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102ff5:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102ff8:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102fff:	00 
f0103000:	8b 43 08             	mov    0x8(%ebx),%eax
f0103003:	89 04 24             	mov    %eax,(%esp)
f0103006:	e8 10 09 00 00       	call   f010391b <strfind>
f010300b:	2b 43 08             	sub    0x8(%ebx),%eax
f010300e:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103011:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103015:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f010301c:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010301f:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103022:	b8 b0 4f 10 f0       	mov    $0xf0104fb0,%eax
f0103027:	e8 b8 fd ff ff       	call   f0102de4 <stab_binsearch>
	if(lline <= rline) {
f010302c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010302f:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103032:	7f 0f                	jg     f0103043 <debuginfo_eip+0x182>
  		info->eip_line = stabs[lline].n_desc;
f0103034:	6b c0 0c             	imul   $0xc,%eax,%eax
f0103037:	0f b7 80 b6 4f 10 f0 	movzwl -0xfefb04a(%eax),%eax
f010303e:	89 43 04             	mov    %eax,0x4(%ebx)
f0103041:	eb 07                	jmp    f010304a <debuginfo_eip+0x189>
	}
	else info->eip_line = -1;
f0103043:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010304a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010304d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0103050:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103053:	6b d0 0c             	imul   $0xc,%eax,%edx
f0103056:	81 c2 b0 4f 10 f0    	add    $0xf0104fb0,%edx
f010305c:	eb 06                	jmp    f0103064 <debuginfo_eip+0x1a3>
f010305e:	83 e8 01             	sub    $0x1,%eax
f0103061:	83 ea 0c             	sub    $0xc,%edx
f0103064:	89 c6                	mov    %eax,%esi
f0103066:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0103069:	7f 33                	jg     f010309e <debuginfo_eip+0x1dd>
	       && stabs[lline].n_type != N_SOL
f010306b:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010306f:	80 f9 84             	cmp    $0x84,%cl
f0103072:	74 0b                	je     f010307f <debuginfo_eip+0x1be>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103074:	80 f9 64             	cmp    $0x64,%cl
f0103077:	75 e5                	jne    f010305e <debuginfo_eip+0x19d>
f0103079:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f010307d:	74 df                	je     f010305e <debuginfo_eip+0x19d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010307f:	6b f6 0c             	imul   $0xc,%esi,%esi
f0103082:	8b 86 b0 4f 10 f0    	mov    -0xfefb050(%esi),%eax
f0103088:	ba 64 ca 10 f0       	mov    $0xf010ca64,%edx
f010308d:	81 ea 99 ac 10 f0    	sub    $0xf010ac99,%edx
f0103093:	39 d0                	cmp    %edx,%eax
f0103095:	73 07                	jae    f010309e <debuginfo_eip+0x1dd>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103097:	05 99 ac 10 f0       	add    $0xf010ac99,%eax
f010309c:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010309e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01030a1:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01030a4:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01030a9:	39 ca                	cmp    %ecx,%edx
f01030ab:	7d 4c                	jge    f01030f9 <debuginfo_eip+0x238>
		for (lline = lfun + 1;
f01030ad:	8d 42 01             	lea    0x1(%edx),%eax
f01030b0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01030b3:	89 c2                	mov    %eax,%edx
f01030b5:	6b c0 0c             	imul   $0xc,%eax,%eax
f01030b8:	05 b0 4f 10 f0       	add    $0xf0104fb0,%eax
f01030bd:	89 ce                	mov    %ecx,%esi
f01030bf:	eb 04                	jmp    f01030c5 <debuginfo_eip+0x204>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01030c1:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01030c5:	39 d6                	cmp    %edx,%esi
f01030c7:	7e 2b                	jle    f01030f4 <debuginfo_eip+0x233>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01030c9:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01030cd:	83 c2 01             	add    $0x1,%edx
f01030d0:	83 c0 0c             	add    $0xc,%eax
f01030d3:	80 f9 a0             	cmp    $0xa0,%cl
f01030d6:	74 e9                	je     f01030c1 <debuginfo_eip+0x200>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01030d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01030dd:	eb 1a                	jmp    f01030f9 <debuginfo_eip+0x238>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01030df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01030e4:	eb 13                	jmp    f01030f9 <debuginfo_eip+0x238>
f01030e6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01030eb:	eb 0c                	jmp    f01030f9 <debuginfo_eip+0x238>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01030ed:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01030f2:	eb 05                	jmp    f01030f9 <debuginfo_eip+0x238>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01030f4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01030f9:	83 c4 3c             	add    $0x3c,%esp
f01030fc:	5b                   	pop    %ebx
f01030fd:	5e                   	pop    %esi
f01030fe:	5f                   	pop    %edi
f01030ff:	5d                   	pop    %ebp
f0103100:	c3                   	ret    
f0103101:	66 90                	xchg   %ax,%ax
f0103103:	66 90                	xchg   %ax,%ax
f0103105:	66 90                	xchg   %ax,%ax
f0103107:	66 90                	xchg   %ax,%ax
f0103109:	66 90                	xchg   %ax,%ax
f010310b:	66 90                	xchg   %ax,%ax
f010310d:	66 90                	xchg   %ax,%ax
f010310f:	90                   	nop

f0103110 <printnum>:
  *使用指定的putch函数和相关的指针putdat。
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103110:	55                   	push   %ebp
f0103111:	89 e5                	mov    %esp,%ebp
f0103113:	57                   	push   %edi
f0103114:	56                   	push   %esi
f0103115:	53                   	push   %ebx
f0103116:	83 ec 3c             	sub    $0x3c,%esp
f0103119:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010311c:	89 d7                	mov    %edx,%edi
f010311e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103121:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103124:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103127:	89 c3                	mov    %eax,%ebx
f0103129:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010312c:	8b 45 10             	mov    0x10(%ebp),%eax
f010312f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	//首先递归打印所有前面的（更重要的）数字
	if (num >= base) {
f0103132:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103137:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010313a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010313d:	39 d9                	cmp    %ebx,%ecx
f010313f:	72 05                	jb     f0103146 <printnum+0x36>
f0103141:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103144:	77 69                	ja     f01031af <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103146:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0103149:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010314d:	83 ee 01             	sub    $0x1,%esi
f0103150:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103154:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103158:	8b 44 24 08          	mov    0x8(%esp),%eax
f010315c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103160:	89 c3                	mov    %eax,%ebx
f0103162:	89 d6                	mov    %edx,%esi
f0103164:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103167:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010316a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010316e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103172:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103175:	89 04 24             	mov    %eax,(%esp)
f0103178:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010317b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010317f:	e8 bc 09 00 00       	call   f0103b40 <__udivdi3>
f0103184:	89 d9                	mov    %ebx,%ecx
f0103186:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010318a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010318e:	89 04 24             	mov    %eax,(%esp)
f0103191:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103195:	89 fa                	mov    %edi,%edx
f0103197:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010319a:	e8 71 ff ff ff       	call   f0103110 <printnum>
f010319f:	eb 1b                	jmp    f01031bc <printnum+0xac>
	} else {
		//在第一个数字之前打印任何所需的填充字符
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01031a1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01031a5:	8b 45 18             	mov    0x18(%ebp),%eax
f01031a8:	89 04 24             	mov    %eax,(%esp)
f01031ab:	ff d3                	call   *%ebx
f01031ad:	eb 03                	jmp    f01031b2 <printnum+0xa2>
f01031af:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		//在第一个数字之前打印任何所需的填充字符
		// print any needed pad characters before first digit
		while (--width > 0)
f01031b2:	83 ee 01             	sub    $0x1,%esi
f01031b5:	85 f6                	test   %esi,%esi
f01031b7:	7f e8                	jg     f01031a1 <printnum+0x91>
f01031b9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01031bc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01031c0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01031c4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01031c7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01031ca:	89 44 24 08          	mov    %eax,0x8(%esp)
f01031ce:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01031d2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031d5:	89 04 24             	mov    %eax,(%esp)
f01031d8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01031db:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031df:	e8 8c 0a 00 00       	call   f0103c70 <__umoddi3>
f01031e4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01031e8:	0f be 80 89 4d 10 f0 	movsbl -0xfefb277(%eax),%eax
f01031ef:	89 04 24             	mov    %eax,(%esp)
f01031f2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031f5:	ff d0                	call   *%eax
//首先递归打印所有前面的（更重要的）数字
//在第一个数字之前打印任何所需的填充字符
//然后打印这个（最不重要的）数字
}
f01031f7:	83 c4 3c             	add    $0x3c,%esp
f01031fa:	5b                   	pop    %ebx
f01031fb:	5e                   	pop    %esi
f01031fc:	5f                   	pop    %edi
f01031fd:	5d                   	pop    %ebp
f01031fe:	c3                   	ret    

f01031ff <getuint>:
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
//从varargs列表中获取各种可能大小的unsigned int，具体取决于lflag参数。
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01031ff:	55                   	push   %ebp
f0103200:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103202:	83 fa 01             	cmp    $0x1,%edx
f0103205:	7e 0e                	jle    f0103215 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103207:	8b 10                	mov    (%eax),%edx
f0103209:	8d 4a 08             	lea    0x8(%edx),%ecx
f010320c:	89 08                	mov    %ecx,(%eax)
f010320e:	8b 02                	mov    (%edx),%eax
f0103210:	8b 52 04             	mov    0x4(%edx),%edx
f0103213:	eb 22                	jmp    f0103237 <getuint+0x38>
	else if (lflag)
f0103215:	85 d2                	test   %edx,%edx
f0103217:	74 10                	je     f0103229 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103219:	8b 10                	mov    (%eax),%edx
f010321b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010321e:	89 08                	mov    %ecx,(%eax)
f0103220:	8b 02                	mov    (%edx),%eax
f0103222:	ba 00 00 00 00       	mov    $0x0,%edx
f0103227:	eb 0e                	jmp    f0103237 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103229:	8b 10                	mov    (%eax),%edx
f010322b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010322e:	89 08                	mov    %ecx,(%eax)
f0103230:	8b 02                	mov    (%edx),%eax
f0103232:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103237:	5d                   	pop    %ebp
f0103238:	c3                   	ret    

f0103239 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103239:	55                   	push   %ebp
f010323a:	89 e5                	mov    %esp,%ebp
f010323c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010323f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103243:	8b 10                	mov    (%eax),%edx
f0103245:	3b 50 04             	cmp    0x4(%eax),%edx
f0103248:	73 0a                	jae    f0103254 <sprintputch+0x1b>
		*b->buf++ = ch;
f010324a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010324d:	89 08                	mov    %ecx,(%eax)
f010324f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103252:	88 02                	mov    %al,(%edx)
}
f0103254:	5d                   	pop    %ebp
f0103255:	c3                   	ret    

f0103256 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103256:	55                   	push   %ebp
f0103257:	89 e5                	mov    %esp,%ebp
f0103259:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010325c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010325f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103263:	8b 45 10             	mov    0x10(%ebp),%eax
f0103266:	89 44 24 08          	mov    %eax,0x8(%esp)
f010326a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010326d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103271:	8b 45 08             	mov    0x8(%ebp),%eax
f0103274:	89 04 24             	mov    %eax,(%esp)
f0103277:	e8 02 00 00 00       	call   f010327e <vprintfmt>
	va_end(ap);
}
f010327c:	c9                   	leave  
f010327d:	c3                   	ret    

f010327e <vprintfmt>:
// Main function to format and print a string.
//格式化和打印字符串的主要功能。
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010327e:	55                   	push   %ebp
f010327f:	89 e5                	mov    %esp,%ebp
f0103281:	57                   	push   %edi
f0103282:	56                   	push   %esi
f0103283:	53                   	push   %ebx
f0103284:	83 ec 3c             	sub    $0x3c,%esp
f0103287:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010328a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010328d:	eb 14                	jmp    f01032a3 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010328f:	85 c0                	test   %eax,%eax
f0103291:	0f 84 b3 03 00 00    	je     f010364a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0103297:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010329b:	89 04 24             	mov    %eax,(%esp)
f010329e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01032a1:	89 f3                	mov    %esi,%ebx
f01032a3:	8d 73 01             	lea    0x1(%ebx),%esi
f01032a6:	0f b6 03             	movzbl (%ebx),%eax
f01032a9:	83 f8 25             	cmp    $0x25,%eax
f01032ac:	75 e1                	jne    f010328f <vprintfmt+0x11>
f01032ae:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f01032b2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01032b9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f01032c0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f01032c7:	ba 00 00 00 00       	mov    $0x0,%edx
f01032cc:	eb 1d                	jmp    f01032eb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032ce:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f01032d0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f01032d4:	eb 15                	jmp    f01032eb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032d6:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01032d8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f01032dc:	eb 0d                	jmp    f01032eb <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01032de:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032e1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01032e4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032eb:	8d 5e 01             	lea    0x1(%esi),%ebx
f01032ee:	0f b6 0e             	movzbl (%esi),%ecx
f01032f1:	0f b6 c1             	movzbl %cl,%eax
f01032f4:	83 e9 23             	sub    $0x23,%ecx
f01032f7:	80 f9 55             	cmp    $0x55,%cl
f01032fa:	0f 87 2a 03 00 00    	ja     f010362a <vprintfmt+0x3ac>
f0103300:	0f b6 c9             	movzbl %cl,%ecx
f0103303:	ff 24 8d 20 4e 10 f0 	jmp    *-0xfefb1e0(,%ecx,4)
f010330a:	89 de                	mov    %ebx,%esi
f010330c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103311:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0103314:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0103318:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010331b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f010331e:	83 fb 09             	cmp    $0x9,%ebx
f0103321:	77 36                	ja     f0103359 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103323:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103326:	eb e9                	jmp    f0103311 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103328:	8b 45 14             	mov    0x14(%ebp),%eax
f010332b:	8d 48 04             	lea    0x4(%eax),%ecx
f010332e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103331:	8b 00                	mov    (%eax),%eax
f0103333:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103336:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103338:	eb 22                	jmp    f010335c <vprintfmt+0xde>
f010333a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010333d:	85 c9                	test   %ecx,%ecx
f010333f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103344:	0f 49 c1             	cmovns %ecx,%eax
f0103347:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010334a:	89 de                	mov    %ebx,%esi
f010334c:	eb 9d                	jmp    f01032eb <vprintfmt+0x6d>
f010334e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103350:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0103357:	eb 92                	jmp    f01032eb <vprintfmt+0x6d>
f0103359:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f010335c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103360:	79 89                	jns    f01032eb <vprintfmt+0x6d>
f0103362:	e9 77 ff ff ff       	jmp    f01032de <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103367:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010336a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010336c:	e9 7a ff ff ff       	jmp    f01032eb <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap,int),putdat);
f0103371:	8b 45 14             	mov    0x14(%ebp),%eax
f0103374:	8d 50 04             	lea    0x4(%eax),%edx
f0103377:	89 55 14             	mov    %edx,0x14(%ebp)
f010337a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010337e:	8b 00                	mov    (%eax),%eax
f0103380:	89 04 24             	mov    %eax,(%esp)
f0103383:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103386:	e9 18 ff ff ff       	jmp    f01032a3 <vprintfmt+0x25>
		// error message
		case 'e':
			err = va_arg(ap, int);
f010338b:	8b 45 14             	mov    0x14(%ebp),%eax
f010338e:	8d 50 04             	lea    0x4(%eax),%edx
f0103391:	89 55 14             	mov    %edx,0x14(%ebp)
f0103394:	8b 00                	mov    (%eax),%eax
f0103396:	99                   	cltd   
f0103397:	31 d0                	xor    %edx,%eax
f0103399:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010339b:	83 f8 07             	cmp    $0x7,%eax
f010339e:	7f 0b                	jg     f01033ab <vprintfmt+0x12d>
f01033a0:	8b 14 85 80 4f 10 f0 	mov    -0xfefb080(,%eax,4),%edx
f01033a7:	85 d2                	test   %edx,%edx
f01033a9:	75 20                	jne    f01033cb <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f01033ab:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033af:	c7 44 24 08 a1 4d 10 	movl   $0xf0104da1,0x8(%esp)
f01033b6:	f0 
f01033b7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01033bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01033be:	89 04 24             	mov    %eax,(%esp)
f01033c1:	e8 90 fe ff ff       	call   f0103256 <printfmt>
f01033c6:	e9 d8 fe ff ff       	jmp    f01032a3 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f01033cb:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01033cf:	c7 44 24 08 32 43 10 	movl   $0xf0104332,0x8(%esp)
f01033d6:	f0 
f01033d7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01033db:	8b 45 08             	mov    0x8(%ebp),%eax
f01033de:	89 04 24             	mov    %eax,(%esp)
f01033e1:	e8 70 fe ff ff       	call   f0103256 <printfmt>
f01033e6:	e9 b8 fe ff ff       	jmp    f01032a3 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01033eb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01033ee:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01033f1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01033f4:	8b 45 14             	mov    0x14(%ebp),%eax
f01033f7:	8d 50 04             	lea    0x4(%eax),%edx
f01033fa:	89 55 14             	mov    %edx,0x14(%ebp)
f01033fd:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01033ff:	85 f6                	test   %esi,%esi
f0103401:	b8 9a 4d 10 f0       	mov    $0xf0104d9a,%eax
f0103406:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0103409:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010340d:	0f 84 97 00 00 00    	je     f01034aa <vprintfmt+0x22c>
f0103413:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0103417:	0f 8e 9b 00 00 00    	jle    f01034b8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010341d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103421:	89 34 24             	mov    %esi,(%esp)
f0103424:	e8 9f 03 00 00       	call   f01037c8 <strnlen>
f0103429:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010342c:	29 c2                	sub    %eax,%edx
f010342e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0103431:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0103435:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103438:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010343b:	8b 75 08             	mov    0x8(%ebp),%esi
f010343e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103441:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103443:	eb 0f                	jmp    f0103454 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0103445:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103449:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010344c:	89 04 24             	mov    %eax,(%esp)
f010344f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103451:	83 eb 01             	sub    $0x1,%ebx
f0103454:	85 db                	test   %ebx,%ebx
f0103456:	7f ed                	jg     f0103445 <vprintfmt+0x1c7>
f0103458:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010345b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010345e:	85 d2                	test   %edx,%edx
f0103460:	b8 00 00 00 00       	mov    $0x0,%eax
f0103465:	0f 49 c2             	cmovns %edx,%eax
f0103468:	29 c2                	sub    %eax,%edx
f010346a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010346d:	89 d7                	mov    %edx,%edi
f010346f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103472:	eb 50                	jmp    f01034c4 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103474:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103478:	74 1e                	je     f0103498 <vprintfmt+0x21a>
f010347a:	0f be d2             	movsbl %dl,%edx
f010347d:	83 ea 20             	sub    $0x20,%edx
f0103480:	83 fa 5e             	cmp    $0x5e,%edx
f0103483:	76 13                	jbe    f0103498 <vprintfmt+0x21a>
					putch('?', putdat);
f0103485:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103488:	89 44 24 04          	mov    %eax,0x4(%esp)
f010348c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103493:	ff 55 08             	call   *0x8(%ebp)
f0103496:	eb 0d                	jmp    f01034a5 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0103498:	8b 55 0c             	mov    0xc(%ebp),%edx
f010349b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010349f:	89 04 24             	mov    %eax,(%esp)
f01034a2:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01034a5:	83 ef 01             	sub    $0x1,%edi
f01034a8:	eb 1a                	jmp    f01034c4 <vprintfmt+0x246>
f01034aa:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01034ad:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01034b0:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01034b3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01034b6:	eb 0c                	jmp    f01034c4 <vprintfmt+0x246>
f01034b8:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01034bb:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01034be:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01034c1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01034c4:	83 c6 01             	add    $0x1,%esi
f01034c7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01034cb:	0f be c2             	movsbl %dl,%eax
f01034ce:	85 c0                	test   %eax,%eax
f01034d0:	74 27                	je     f01034f9 <vprintfmt+0x27b>
f01034d2:	85 db                	test   %ebx,%ebx
f01034d4:	78 9e                	js     f0103474 <vprintfmt+0x1f6>
f01034d6:	83 eb 01             	sub    $0x1,%ebx
f01034d9:	79 99                	jns    f0103474 <vprintfmt+0x1f6>
f01034db:	89 f8                	mov    %edi,%eax
f01034dd:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01034e0:	8b 75 08             	mov    0x8(%ebp),%esi
f01034e3:	89 c3                	mov    %eax,%ebx
f01034e5:	eb 1a                	jmp    f0103501 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01034e7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01034eb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01034f2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01034f4:	83 eb 01             	sub    $0x1,%ebx
f01034f7:	eb 08                	jmp    f0103501 <vprintfmt+0x283>
f01034f9:	89 fb                	mov    %edi,%ebx
f01034fb:	8b 75 08             	mov    0x8(%ebp),%esi
f01034fe:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103501:	85 db                	test   %ebx,%ebx
f0103503:	7f e2                	jg     f01034e7 <vprintfmt+0x269>
f0103505:	89 75 08             	mov    %esi,0x8(%ebp)
f0103508:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010350b:	e9 93 fd ff ff       	jmp    f01032a3 <vprintfmt+0x25>
// because of sign extension
//与getuint相同但已签名 - 由于符号扩展而无法使用getuint
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103510:	83 fa 01             	cmp    $0x1,%edx
f0103513:	7e 16                	jle    f010352b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0103515:	8b 45 14             	mov    0x14(%ebp),%eax
f0103518:	8d 50 08             	lea    0x8(%eax),%edx
f010351b:	89 55 14             	mov    %edx,0x14(%ebp)
f010351e:	8b 50 04             	mov    0x4(%eax),%edx
f0103521:	8b 00                	mov    (%eax),%eax
f0103523:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103526:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103529:	eb 32                	jmp    f010355d <vprintfmt+0x2df>
	else if (lflag)
f010352b:	85 d2                	test   %edx,%edx
f010352d:	74 18                	je     f0103547 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010352f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103532:	8d 50 04             	lea    0x4(%eax),%edx
f0103535:	89 55 14             	mov    %edx,0x14(%ebp)
f0103538:	8b 30                	mov    (%eax),%esi
f010353a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010353d:	89 f0                	mov    %esi,%eax
f010353f:	c1 f8 1f             	sar    $0x1f,%eax
f0103542:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103545:	eb 16                	jmp    f010355d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0103547:	8b 45 14             	mov    0x14(%ebp),%eax
f010354a:	8d 50 04             	lea    0x4(%eax),%edx
f010354d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103550:	8b 30                	mov    (%eax),%esi
f0103552:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0103555:	89 f0                	mov    %esi,%eax
f0103557:	c1 f8 1f             	sar    $0x1f,%eax
f010355a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010355d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103560:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103563:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103568:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010356c:	0f 89 80 00 00 00    	jns    f01035f2 <vprintfmt+0x374>
				putch('-', putdat);
f0103572:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103576:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010357d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103580:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103583:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103586:	f7 d8                	neg    %eax
f0103588:	83 d2 00             	adc    $0x0,%edx
f010358b:	f7 da                	neg    %edx
			}
			base = 10;
f010358d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103592:	eb 5e                	jmp    f01035f2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103594:	8d 45 14             	lea    0x14(%ebp),%eax
f0103597:	e8 63 fc ff ff       	call   f01031ff <getuint>
			base = 10;
f010359c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01035a1:	eb 4f                	jmp    f01035f2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01035a3:	8d 45 14             	lea    0x14(%ebp),%eax
f01035a6:	e8 54 fc ff ff       	call   f01031ff <getuint>
			base = 8;
f01035ab:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01035b0:	eb 40                	jmp    f01035f2 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f01035b2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035b6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01035bd:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01035c0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035c4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01035cb:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01035ce:	8b 45 14             	mov    0x14(%ebp),%eax
f01035d1:	8d 50 04             	lea    0x4(%eax),%edx
f01035d4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01035d7:	8b 00                	mov    (%eax),%eax
f01035d9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01035de:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01035e3:	eb 0d                	jmp    f01035f2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01035e5:	8d 45 14             	lea    0x14(%ebp),%eax
f01035e8:	e8 12 fc ff ff       	call   f01031ff <getuint>
			base = 16;
f01035ed:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01035f2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f01035f6:	89 74 24 10          	mov    %esi,0x10(%esp)
f01035fa:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01035fd:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103601:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103605:	89 04 24             	mov    %eax,(%esp)
f0103608:	89 54 24 04          	mov    %edx,0x4(%esp)
f010360c:	89 fa                	mov    %edi,%edx
f010360e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103611:	e8 fa fa ff ff       	call   f0103110 <printnum>
			break;
f0103616:	e9 88 fc ff ff       	jmp    f01032a3 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010361b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010361f:	89 04 24             	mov    %eax,(%esp)
f0103622:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103625:	e9 79 fc ff ff       	jmp    f01032a3 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010362a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010362e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103635:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103638:	89 f3                	mov    %esi,%ebx
f010363a:	eb 03                	jmp    f010363f <vprintfmt+0x3c1>
f010363c:	83 eb 01             	sub    $0x1,%ebx
f010363f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0103643:	75 f7                	jne    f010363c <vprintfmt+0x3be>
f0103645:	e9 59 fc ff ff       	jmp    f01032a3 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010364a:	83 c4 3c             	add    $0x3c,%esp
f010364d:	5b                   	pop    %ebx
f010364e:	5e                   	pop    %esi
f010364f:	5f                   	pop    %edi
f0103650:	5d                   	pop    %ebp
f0103651:	c3                   	ret    

f0103652 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103652:	55                   	push   %ebp
f0103653:	89 e5                	mov    %esp,%ebp
f0103655:	83 ec 28             	sub    $0x28,%esp
f0103658:	8b 45 08             	mov    0x8(%ebp),%eax
f010365b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010365e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103661:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103665:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103668:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010366f:	85 c0                	test   %eax,%eax
f0103671:	74 30                	je     f01036a3 <vsnprintf+0x51>
f0103673:	85 d2                	test   %edx,%edx
f0103675:	7e 2c                	jle    f01036a3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103677:	8b 45 14             	mov    0x14(%ebp),%eax
f010367a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010367e:	8b 45 10             	mov    0x10(%ebp),%eax
f0103681:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103685:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103688:	89 44 24 04          	mov    %eax,0x4(%esp)
f010368c:	c7 04 24 39 32 10 f0 	movl   $0xf0103239,(%esp)
f0103693:	e8 e6 fb ff ff       	call   f010327e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103698:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010369b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010369e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01036a1:	eb 05                	jmp    f01036a8 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01036a3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01036a8:	c9                   	leave  
f01036a9:	c3                   	ret    

f01036aa <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01036aa:	55                   	push   %ebp
f01036ab:	89 e5                	mov    %esp,%ebp
f01036ad:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01036b0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01036b3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01036b7:	8b 45 10             	mov    0x10(%ebp),%eax
f01036ba:	89 44 24 08          	mov    %eax,0x8(%esp)
f01036be:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036c1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01036c8:	89 04 24             	mov    %eax,(%esp)
f01036cb:	e8 82 ff ff ff       	call   f0103652 <vsnprintf>
	va_end(ap);

	return rc;
}
f01036d0:	c9                   	leave  
f01036d1:	c3                   	ret    
f01036d2:	66 90                	xchg   %ax,%ax
f01036d4:	66 90                	xchg   %ax,%ax
f01036d6:	66 90                	xchg   %ax,%ax
f01036d8:	66 90                	xchg   %ax,%ax
f01036da:	66 90                	xchg   %ax,%ax
f01036dc:	66 90                	xchg   %ax,%ax
f01036de:	66 90                	xchg   %ax,%ax

f01036e0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01036e0:	55                   	push   %ebp
f01036e1:	89 e5                	mov    %esp,%ebp
f01036e3:	57                   	push   %edi
f01036e4:	56                   	push   %esi
f01036e5:	53                   	push   %ebx
f01036e6:	83 ec 1c             	sub    $0x1c,%esp
f01036e9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01036ec:	85 c0                	test   %eax,%eax
f01036ee:	74 10                	je     f0103700 <readline+0x20>
		cprintf("%s", prompt);
f01036f0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036f4:	c7 04 24 32 43 10 f0 	movl   $0xf0104332,(%esp)
f01036fb:	e8 ca f6 ff ff       	call   f0102dca <cprintf>

	i = 0;
	echoing = iscons(0);
f0103700:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103707:	e8 31 cf ff ff       	call   f010063d <iscons>
f010370c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010370e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103713:	e8 14 cf ff ff       	call   f010062c <getchar>
f0103718:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010371a:	85 c0                	test   %eax,%eax
f010371c:	79 17                	jns    f0103735 <readline+0x55>
			cprintf("read error: %e\n", c);
f010371e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103722:	c7 04 24 a0 4f 10 f0 	movl   $0xf0104fa0,(%esp)
f0103729:	e8 9c f6 ff ff       	call   f0102dca <cprintf>
			return NULL;
f010372e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103733:	eb 6d                	jmp    f01037a2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103735:	83 f8 7f             	cmp    $0x7f,%eax
f0103738:	74 05                	je     f010373f <readline+0x5f>
f010373a:	83 f8 08             	cmp    $0x8,%eax
f010373d:	75 19                	jne    f0103758 <readline+0x78>
f010373f:	85 f6                	test   %esi,%esi
f0103741:	7e 15                	jle    f0103758 <readline+0x78>
			if (echoing)
f0103743:	85 ff                	test   %edi,%edi
f0103745:	74 0c                	je     f0103753 <readline+0x73>
				cputchar('\b');
f0103747:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010374e:	e8 c9 ce ff ff       	call   f010061c <cputchar>
			i--;
f0103753:	83 ee 01             	sub    $0x1,%esi
f0103756:	eb bb                	jmp    f0103713 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103758:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010375e:	7f 1c                	jg     f010377c <readline+0x9c>
f0103760:	83 fb 1f             	cmp    $0x1f,%ebx
f0103763:	7e 17                	jle    f010377c <readline+0x9c>
			if (echoing)
f0103765:	85 ff                	test   %edi,%edi
f0103767:	74 08                	je     f0103771 <readline+0x91>
				cputchar(c);
f0103769:	89 1c 24             	mov    %ebx,(%esp)
f010376c:	e8 ab ce ff ff       	call   f010061c <cputchar>
			buf[i++] = c;
f0103771:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f0103777:	8d 76 01             	lea    0x1(%esi),%esi
f010377a:	eb 97                	jmp    f0103713 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010377c:	83 fb 0d             	cmp    $0xd,%ebx
f010377f:	74 05                	je     f0103786 <readline+0xa6>
f0103781:	83 fb 0a             	cmp    $0xa,%ebx
f0103784:	75 8d                	jne    f0103713 <readline+0x33>
			if (echoing)
f0103786:	85 ff                	test   %edi,%edi
f0103788:	74 0c                	je     f0103796 <readline+0xb6>
				cputchar('\n');
f010378a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103791:	e8 86 ce ff ff       	call   f010061c <cputchar>
			buf[i] = 0;
f0103796:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f010379d:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f01037a2:	83 c4 1c             	add    $0x1c,%esp
f01037a5:	5b                   	pop    %ebx
f01037a6:	5e                   	pop    %esi
f01037a7:	5f                   	pop    %edi
f01037a8:	5d                   	pop    %ebp
f01037a9:	c3                   	ret    
f01037aa:	66 90                	xchg   %ax,%ax
f01037ac:	66 90                	xchg   %ax,%ax
f01037ae:	66 90                	xchg   %ax,%ax

f01037b0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01037b0:	55                   	push   %ebp
f01037b1:	89 e5                	mov    %esp,%ebp
f01037b3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01037b6:	b8 00 00 00 00       	mov    $0x0,%eax
f01037bb:	eb 03                	jmp    f01037c0 <strlen+0x10>
		n++;
f01037bd:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01037c0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01037c4:	75 f7                	jne    f01037bd <strlen+0xd>
		n++;
	return n;
}
f01037c6:	5d                   	pop    %ebp
f01037c7:	c3                   	ret    

f01037c8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01037c8:	55                   	push   %ebp
f01037c9:	89 e5                	mov    %esp,%ebp
f01037cb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01037ce:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01037d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01037d6:	eb 03                	jmp    f01037db <strnlen+0x13>
		n++;
f01037d8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01037db:	39 d0                	cmp    %edx,%eax
f01037dd:	74 06                	je     f01037e5 <strnlen+0x1d>
f01037df:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01037e3:	75 f3                	jne    f01037d8 <strnlen+0x10>
		n++;
	return n;
}
f01037e5:	5d                   	pop    %ebp
f01037e6:	c3                   	ret    

f01037e7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01037e7:	55                   	push   %ebp
f01037e8:	89 e5                	mov    %esp,%ebp
f01037ea:	53                   	push   %ebx
f01037eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01037ee:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01037f1:	89 c2                	mov    %eax,%edx
f01037f3:	83 c2 01             	add    $0x1,%edx
f01037f6:	83 c1 01             	add    $0x1,%ecx
f01037f9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01037fd:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103800:	84 db                	test   %bl,%bl
f0103802:	75 ef                	jne    f01037f3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103804:	5b                   	pop    %ebx
f0103805:	5d                   	pop    %ebp
f0103806:	c3                   	ret    

f0103807 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103807:	55                   	push   %ebp
f0103808:	89 e5                	mov    %esp,%ebp
f010380a:	53                   	push   %ebx
f010380b:	83 ec 08             	sub    $0x8,%esp
f010380e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103811:	89 1c 24             	mov    %ebx,(%esp)
f0103814:	e8 97 ff ff ff       	call   f01037b0 <strlen>
	strcpy(dst + len, src);
f0103819:	8b 55 0c             	mov    0xc(%ebp),%edx
f010381c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103820:	01 d8                	add    %ebx,%eax
f0103822:	89 04 24             	mov    %eax,(%esp)
f0103825:	e8 bd ff ff ff       	call   f01037e7 <strcpy>
	return dst;
}
f010382a:	89 d8                	mov    %ebx,%eax
f010382c:	83 c4 08             	add    $0x8,%esp
f010382f:	5b                   	pop    %ebx
f0103830:	5d                   	pop    %ebp
f0103831:	c3                   	ret    

f0103832 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103832:	55                   	push   %ebp
f0103833:	89 e5                	mov    %esp,%ebp
f0103835:	56                   	push   %esi
f0103836:	53                   	push   %ebx
f0103837:	8b 75 08             	mov    0x8(%ebp),%esi
f010383a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010383d:	89 f3                	mov    %esi,%ebx
f010383f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103842:	89 f2                	mov    %esi,%edx
f0103844:	eb 0f                	jmp    f0103855 <strncpy+0x23>
		*dst++ = *src;
f0103846:	83 c2 01             	add    $0x1,%edx
f0103849:	0f b6 01             	movzbl (%ecx),%eax
f010384c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010384f:	80 39 01             	cmpb   $0x1,(%ecx)
f0103852:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103855:	39 da                	cmp    %ebx,%edx
f0103857:	75 ed                	jne    f0103846 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103859:	89 f0                	mov    %esi,%eax
f010385b:	5b                   	pop    %ebx
f010385c:	5e                   	pop    %esi
f010385d:	5d                   	pop    %ebp
f010385e:	c3                   	ret    

f010385f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010385f:	55                   	push   %ebp
f0103860:	89 e5                	mov    %esp,%ebp
f0103862:	56                   	push   %esi
f0103863:	53                   	push   %ebx
f0103864:	8b 75 08             	mov    0x8(%ebp),%esi
f0103867:	8b 55 0c             	mov    0xc(%ebp),%edx
f010386a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010386d:	89 f0                	mov    %esi,%eax
f010386f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103873:	85 c9                	test   %ecx,%ecx
f0103875:	75 0b                	jne    f0103882 <strlcpy+0x23>
f0103877:	eb 1d                	jmp    f0103896 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103879:	83 c0 01             	add    $0x1,%eax
f010387c:	83 c2 01             	add    $0x1,%edx
f010387f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103882:	39 d8                	cmp    %ebx,%eax
f0103884:	74 0b                	je     f0103891 <strlcpy+0x32>
f0103886:	0f b6 0a             	movzbl (%edx),%ecx
f0103889:	84 c9                	test   %cl,%cl
f010388b:	75 ec                	jne    f0103879 <strlcpy+0x1a>
f010388d:	89 c2                	mov    %eax,%edx
f010388f:	eb 02                	jmp    f0103893 <strlcpy+0x34>
f0103891:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0103893:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0103896:	29 f0                	sub    %esi,%eax
}
f0103898:	5b                   	pop    %ebx
f0103899:	5e                   	pop    %esi
f010389a:	5d                   	pop    %ebp
f010389b:	c3                   	ret    

f010389c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010389c:	55                   	push   %ebp
f010389d:	89 e5                	mov    %esp,%ebp
f010389f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01038a2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01038a5:	eb 06                	jmp    f01038ad <strcmp+0x11>
		p++, q++;
f01038a7:	83 c1 01             	add    $0x1,%ecx
f01038aa:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01038ad:	0f b6 01             	movzbl (%ecx),%eax
f01038b0:	84 c0                	test   %al,%al
f01038b2:	74 04                	je     f01038b8 <strcmp+0x1c>
f01038b4:	3a 02                	cmp    (%edx),%al
f01038b6:	74 ef                	je     f01038a7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01038b8:	0f b6 c0             	movzbl %al,%eax
f01038bb:	0f b6 12             	movzbl (%edx),%edx
f01038be:	29 d0                	sub    %edx,%eax
}
f01038c0:	5d                   	pop    %ebp
f01038c1:	c3                   	ret    

f01038c2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01038c2:	55                   	push   %ebp
f01038c3:	89 e5                	mov    %esp,%ebp
f01038c5:	53                   	push   %ebx
f01038c6:	8b 45 08             	mov    0x8(%ebp),%eax
f01038c9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01038cc:	89 c3                	mov    %eax,%ebx
f01038ce:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01038d1:	eb 06                	jmp    f01038d9 <strncmp+0x17>
		n--, p++, q++;
f01038d3:	83 c0 01             	add    $0x1,%eax
f01038d6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01038d9:	39 d8                	cmp    %ebx,%eax
f01038db:	74 15                	je     f01038f2 <strncmp+0x30>
f01038dd:	0f b6 08             	movzbl (%eax),%ecx
f01038e0:	84 c9                	test   %cl,%cl
f01038e2:	74 04                	je     f01038e8 <strncmp+0x26>
f01038e4:	3a 0a                	cmp    (%edx),%cl
f01038e6:	74 eb                	je     f01038d3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01038e8:	0f b6 00             	movzbl (%eax),%eax
f01038eb:	0f b6 12             	movzbl (%edx),%edx
f01038ee:	29 d0                	sub    %edx,%eax
f01038f0:	eb 05                	jmp    f01038f7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01038f2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01038f7:	5b                   	pop    %ebx
f01038f8:	5d                   	pop    %ebp
f01038f9:	c3                   	ret    

f01038fa <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01038fa:	55                   	push   %ebp
f01038fb:	89 e5                	mov    %esp,%ebp
f01038fd:	8b 45 08             	mov    0x8(%ebp),%eax
f0103900:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103904:	eb 07                	jmp    f010390d <strchr+0x13>
		if (*s == c)
f0103906:	38 ca                	cmp    %cl,%dl
f0103908:	74 0f                	je     f0103919 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010390a:	83 c0 01             	add    $0x1,%eax
f010390d:	0f b6 10             	movzbl (%eax),%edx
f0103910:	84 d2                	test   %dl,%dl
f0103912:	75 f2                	jne    f0103906 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103914:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103919:	5d                   	pop    %ebp
f010391a:	c3                   	ret    

f010391b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010391b:	55                   	push   %ebp
f010391c:	89 e5                	mov    %esp,%ebp
f010391e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103921:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103925:	eb 07                	jmp    f010392e <strfind+0x13>
		if (*s == c)
f0103927:	38 ca                	cmp    %cl,%dl
f0103929:	74 0a                	je     f0103935 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010392b:	83 c0 01             	add    $0x1,%eax
f010392e:	0f b6 10             	movzbl (%eax),%edx
f0103931:	84 d2                	test   %dl,%dl
f0103933:	75 f2                	jne    f0103927 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0103935:	5d                   	pop    %ebp
f0103936:	c3                   	ret    

f0103937 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103937:	55                   	push   %ebp
f0103938:	89 e5                	mov    %esp,%ebp
f010393a:	57                   	push   %edi
f010393b:	56                   	push   %esi
f010393c:	53                   	push   %ebx
f010393d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103940:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103943:	85 c9                	test   %ecx,%ecx
f0103945:	74 36                	je     f010397d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103947:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010394d:	75 28                	jne    f0103977 <memset+0x40>
f010394f:	f6 c1 03             	test   $0x3,%cl
f0103952:	75 23                	jne    f0103977 <memset+0x40>
		c &= 0xFF;
f0103954:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103958:	89 d3                	mov    %edx,%ebx
f010395a:	c1 e3 08             	shl    $0x8,%ebx
f010395d:	89 d6                	mov    %edx,%esi
f010395f:	c1 e6 18             	shl    $0x18,%esi
f0103962:	89 d0                	mov    %edx,%eax
f0103964:	c1 e0 10             	shl    $0x10,%eax
f0103967:	09 f0                	or     %esi,%eax
f0103969:	09 c2                	or     %eax,%edx
f010396b:	89 d0                	mov    %edx,%eax
f010396d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010396f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0103972:	fc                   	cld    
f0103973:	f3 ab                	rep stos %eax,%es:(%edi)
f0103975:	eb 06                	jmp    f010397d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103977:	8b 45 0c             	mov    0xc(%ebp),%eax
f010397a:	fc                   	cld    
f010397b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010397d:	89 f8                	mov    %edi,%eax
f010397f:	5b                   	pop    %ebx
f0103980:	5e                   	pop    %esi
f0103981:	5f                   	pop    %edi
f0103982:	5d                   	pop    %ebp
f0103983:	c3                   	ret    

f0103984 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103984:	55                   	push   %ebp
f0103985:	89 e5                	mov    %esp,%ebp
f0103987:	57                   	push   %edi
f0103988:	56                   	push   %esi
f0103989:	8b 45 08             	mov    0x8(%ebp),%eax
f010398c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010398f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103992:	39 c6                	cmp    %eax,%esi
f0103994:	73 35                	jae    f01039cb <memmove+0x47>
f0103996:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103999:	39 d0                	cmp    %edx,%eax
f010399b:	73 2e                	jae    f01039cb <memmove+0x47>
		s += n;
		d += n;
f010399d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01039a0:	89 d6                	mov    %edx,%esi
f01039a2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01039a4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01039aa:	75 13                	jne    f01039bf <memmove+0x3b>
f01039ac:	f6 c1 03             	test   $0x3,%cl
f01039af:	75 0e                	jne    f01039bf <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01039b1:	83 ef 04             	sub    $0x4,%edi
f01039b4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01039b7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01039ba:	fd                   	std    
f01039bb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01039bd:	eb 09                	jmp    f01039c8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01039bf:	83 ef 01             	sub    $0x1,%edi
f01039c2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01039c5:	fd                   	std    
f01039c6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01039c8:	fc                   	cld    
f01039c9:	eb 1d                	jmp    f01039e8 <memmove+0x64>
f01039cb:	89 f2                	mov    %esi,%edx
f01039cd:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01039cf:	f6 c2 03             	test   $0x3,%dl
f01039d2:	75 0f                	jne    f01039e3 <memmove+0x5f>
f01039d4:	f6 c1 03             	test   $0x3,%cl
f01039d7:	75 0a                	jne    f01039e3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01039d9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01039dc:	89 c7                	mov    %eax,%edi
f01039de:	fc                   	cld    
f01039df:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01039e1:	eb 05                	jmp    f01039e8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01039e3:	89 c7                	mov    %eax,%edi
f01039e5:	fc                   	cld    
f01039e6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01039e8:	5e                   	pop    %esi
f01039e9:	5f                   	pop    %edi
f01039ea:	5d                   	pop    %ebp
f01039eb:	c3                   	ret    

f01039ec <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01039ec:	55                   	push   %ebp
f01039ed:	89 e5                	mov    %esp,%ebp
f01039ef:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01039f2:	8b 45 10             	mov    0x10(%ebp),%eax
f01039f5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01039f9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039fc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a00:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a03:	89 04 24             	mov    %eax,(%esp)
f0103a06:	e8 79 ff ff ff       	call   f0103984 <memmove>
}
f0103a0b:	c9                   	leave  
f0103a0c:	c3                   	ret    

f0103a0d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103a0d:	55                   	push   %ebp
f0103a0e:	89 e5                	mov    %esp,%ebp
f0103a10:	56                   	push   %esi
f0103a11:	53                   	push   %ebx
f0103a12:	8b 55 08             	mov    0x8(%ebp),%edx
f0103a15:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103a18:	89 d6                	mov    %edx,%esi
f0103a1a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a1d:	eb 1a                	jmp    f0103a39 <memcmp+0x2c>
		if (*s1 != *s2)
f0103a1f:	0f b6 02             	movzbl (%edx),%eax
f0103a22:	0f b6 19             	movzbl (%ecx),%ebx
f0103a25:	38 d8                	cmp    %bl,%al
f0103a27:	74 0a                	je     f0103a33 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103a29:	0f b6 c0             	movzbl %al,%eax
f0103a2c:	0f b6 db             	movzbl %bl,%ebx
f0103a2f:	29 d8                	sub    %ebx,%eax
f0103a31:	eb 0f                	jmp    f0103a42 <memcmp+0x35>
		s1++, s2++;
f0103a33:	83 c2 01             	add    $0x1,%edx
f0103a36:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a39:	39 f2                	cmp    %esi,%edx
f0103a3b:	75 e2                	jne    f0103a1f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103a3d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103a42:	5b                   	pop    %ebx
f0103a43:	5e                   	pop    %esi
f0103a44:	5d                   	pop    %ebp
f0103a45:	c3                   	ret    

f0103a46 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103a46:	55                   	push   %ebp
f0103a47:	89 e5                	mov    %esp,%ebp
f0103a49:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a4c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103a4f:	89 c2                	mov    %eax,%edx
f0103a51:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103a54:	eb 07                	jmp    f0103a5d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103a56:	38 08                	cmp    %cl,(%eax)
f0103a58:	74 07                	je     f0103a61 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103a5a:	83 c0 01             	add    $0x1,%eax
f0103a5d:	39 d0                	cmp    %edx,%eax
f0103a5f:	72 f5                	jb     f0103a56 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103a61:	5d                   	pop    %ebp
f0103a62:	c3                   	ret    

f0103a63 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103a63:	55                   	push   %ebp
f0103a64:	89 e5                	mov    %esp,%ebp
f0103a66:	57                   	push   %edi
f0103a67:	56                   	push   %esi
f0103a68:	53                   	push   %ebx
f0103a69:	8b 55 08             	mov    0x8(%ebp),%edx
f0103a6c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103a6f:	eb 03                	jmp    f0103a74 <strtol+0x11>
		s++;
f0103a71:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103a74:	0f b6 0a             	movzbl (%edx),%ecx
f0103a77:	80 f9 09             	cmp    $0x9,%cl
f0103a7a:	74 f5                	je     f0103a71 <strtol+0xe>
f0103a7c:	80 f9 20             	cmp    $0x20,%cl
f0103a7f:	74 f0                	je     f0103a71 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103a81:	80 f9 2b             	cmp    $0x2b,%cl
f0103a84:	75 0a                	jne    f0103a90 <strtol+0x2d>
		s++;
f0103a86:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103a89:	bf 00 00 00 00       	mov    $0x0,%edi
f0103a8e:	eb 11                	jmp    f0103aa1 <strtol+0x3e>
f0103a90:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103a95:	80 f9 2d             	cmp    $0x2d,%cl
f0103a98:	75 07                	jne    f0103aa1 <strtol+0x3e>
		s++, neg = 1;
f0103a9a:	8d 52 01             	lea    0x1(%edx),%edx
f0103a9d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103aa1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0103aa6:	75 15                	jne    f0103abd <strtol+0x5a>
f0103aa8:	80 3a 30             	cmpb   $0x30,(%edx)
f0103aab:	75 10                	jne    f0103abd <strtol+0x5a>
f0103aad:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103ab1:	75 0a                	jne    f0103abd <strtol+0x5a>
		s += 2, base = 16;
f0103ab3:	83 c2 02             	add    $0x2,%edx
f0103ab6:	b8 10 00 00 00       	mov    $0x10,%eax
f0103abb:	eb 10                	jmp    f0103acd <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0103abd:	85 c0                	test   %eax,%eax
f0103abf:	75 0c                	jne    f0103acd <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103ac1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103ac3:	80 3a 30             	cmpb   $0x30,(%edx)
f0103ac6:	75 05                	jne    f0103acd <strtol+0x6a>
		s++, base = 8;
f0103ac8:	83 c2 01             	add    $0x1,%edx
f0103acb:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0103acd:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103ad2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103ad5:	0f b6 0a             	movzbl (%edx),%ecx
f0103ad8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0103adb:	89 f0                	mov    %esi,%eax
f0103add:	3c 09                	cmp    $0x9,%al
f0103adf:	77 08                	ja     f0103ae9 <strtol+0x86>
			dig = *s - '0';
f0103ae1:	0f be c9             	movsbl %cl,%ecx
f0103ae4:	83 e9 30             	sub    $0x30,%ecx
f0103ae7:	eb 20                	jmp    f0103b09 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0103ae9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0103aec:	89 f0                	mov    %esi,%eax
f0103aee:	3c 19                	cmp    $0x19,%al
f0103af0:	77 08                	ja     f0103afa <strtol+0x97>
			dig = *s - 'a' + 10;
f0103af2:	0f be c9             	movsbl %cl,%ecx
f0103af5:	83 e9 57             	sub    $0x57,%ecx
f0103af8:	eb 0f                	jmp    f0103b09 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0103afa:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0103afd:	89 f0                	mov    %esi,%eax
f0103aff:	3c 19                	cmp    $0x19,%al
f0103b01:	77 16                	ja     f0103b19 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0103b03:	0f be c9             	movsbl %cl,%ecx
f0103b06:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103b09:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0103b0c:	7d 0f                	jge    f0103b1d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0103b0e:	83 c2 01             	add    $0x1,%edx
f0103b11:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0103b15:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0103b17:	eb bc                	jmp    f0103ad5 <strtol+0x72>
f0103b19:	89 d8                	mov    %ebx,%eax
f0103b1b:	eb 02                	jmp    f0103b1f <strtol+0xbc>
f0103b1d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0103b1f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103b23:	74 05                	je     f0103b2a <strtol+0xc7>
		*endptr = (char *) s;
f0103b25:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103b28:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0103b2a:	f7 d8                	neg    %eax
f0103b2c:	85 ff                	test   %edi,%edi
f0103b2e:	0f 44 c3             	cmove  %ebx,%eax
}
f0103b31:	5b                   	pop    %ebx
f0103b32:	5e                   	pop    %esi
f0103b33:	5f                   	pop    %edi
f0103b34:	5d                   	pop    %ebp
f0103b35:	c3                   	ret    
f0103b36:	66 90                	xchg   %ax,%ax
f0103b38:	66 90                	xchg   %ax,%ax
f0103b3a:	66 90                	xchg   %ax,%ax
f0103b3c:	66 90                	xchg   %ax,%ax
f0103b3e:	66 90                	xchg   %ax,%ax

f0103b40 <__udivdi3>:
f0103b40:	55                   	push   %ebp
f0103b41:	57                   	push   %edi
f0103b42:	56                   	push   %esi
f0103b43:	83 ec 0c             	sub    $0xc,%esp
f0103b46:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103b4a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0103b4e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0103b52:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103b56:	85 c0                	test   %eax,%eax
f0103b58:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103b5c:	89 ea                	mov    %ebp,%edx
f0103b5e:	89 0c 24             	mov    %ecx,(%esp)
f0103b61:	75 2d                	jne    f0103b90 <__udivdi3+0x50>
f0103b63:	39 e9                	cmp    %ebp,%ecx
f0103b65:	77 61                	ja     f0103bc8 <__udivdi3+0x88>
f0103b67:	85 c9                	test   %ecx,%ecx
f0103b69:	89 ce                	mov    %ecx,%esi
f0103b6b:	75 0b                	jne    f0103b78 <__udivdi3+0x38>
f0103b6d:	b8 01 00 00 00       	mov    $0x1,%eax
f0103b72:	31 d2                	xor    %edx,%edx
f0103b74:	f7 f1                	div    %ecx
f0103b76:	89 c6                	mov    %eax,%esi
f0103b78:	31 d2                	xor    %edx,%edx
f0103b7a:	89 e8                	mov    %ebp,%eax
f0103b7c:	f7 f6                	div    %esi
f0103b7e:	89 c5                	mov    %eax,%ebp
f0103b80:	89 f8                	mov    %edi,%eax
f0103b82:	f7 f6                	div    %esi
f0103b84:	89 ea                	mov    %ebp,%edx
f0103b86:	83 c4 0c             	add    $0xc,%esp
f0103b89:	5e                   	pop    %esi
f0103b8a:	5f                   	pop    %edi
f0103b8b:	5d                   	pop    %ebp
f0103b8c:	c3                   	ret    
f0103b8d:	8d 76 00             	lea    0x0(%esi),%esi
f0103b90:	39 e8                	cmp    %ebp,%eax
f0103b92:	77 24                	ja     f0103bb8 <__udivdi3+0x78>
f0103b94:	0f bd e8             	bsr    %eax,%ebp
f0103b97:	83 f5 1f             	xor    $0x1f,%ebp
f0103b9a:	75 3c                	jne    f0103bd8 <__udivdi3+0x98>
f0103b9c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0103ba0:	39 34 24             	cmp    %esi,(%esp)
f0103ba3:	0f 86 9f 00 00 00    	jbe    f0103c48 <__udivdi3+0x108>
f0103ba9:	39 d0                	cmp    %edx,%eax
f0103bab:	0f 82 97 00 00 00    	jb     f0103c48 <__udivdi3+0x108>
f0103bb1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103bb8:	31 d2                	xor    %edx,%edx
f0103bba:	31 c0                	xor    %eax,%eax
f0103bbc:	83 c4 0c             	add    $0xc,%esp
f0103bbf:	5e                   	pop    %esi
f0103bc0:	5f                   	pop    %edi
f0103bc1:	5d                   	pop    %ebp
f0103bc2:	c3                   	ret    
f0103bc3:	90                   	nop
f0103bc4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103bc8:	89 f8                	mov    %edi,%eax
f0103bca:	f7 f1                	div    %ecx
f0103bcc:	31 d2                	xor    %edx,%edx
f0103bce:	83 c4 0c             	add    $0xc,%esp
f0103bd1:	5e                   	pop    %esi
f0103bd2:	5f                   	pop    %edi
f0103bd3:	5d                   	pop    %ebp
f0103bd4:	c3                   	ret    
f0103bd5:	8d 76 00             	lea    0x0(%esi),%esi
f0103bd8:	89 e9                	mov    %ebp,%ecx
f0103bda:	8b 3c 24             	mov    (%esp),%edi
f0103bdd:	d3 e0                	shl    %cl,%eax
f0103bdf:	89 c6                	mov    %eax,%esi
f0103be1:	b8 20 00 00 00       	mov    $0x20,%eax
f0103be6:	29 e8                	sub    %ebp,%eax
f0103be8:	89 c1                	mov    %eax,%ecx
f0103bea:	d3 ef                	shr    %cl,%edi
f0103bec:	89 e9                	mov    %ebp,%ecx
f0103bee:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103bf2:	8b 3c 24             	mov    (%esp),%edi
f0103bf5:	09 74 24 08          	or     %esi,0x8(%esp)
f0103bf9:	89 d6                	mov    %edx,%esi
f0103bfb:	d3 e7                	shl    %cl,%edi
f0103bfd:	89 c1                	mov    %eax,%ecx
f0103bff:	89 3c 24             	mov    %edi,(%esp)
f0103c02:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103c06:	d3 ee                	shr    %cl,%esi
f0103c08:	89 e9                	mov    %ebp,%ecx
f0103c0a:	d3 e2                	shl    %cl,%edx
f0103c0c:	89 c1                	mov    %eax,%ecx
f0103c0e:	d3 ef                	shr    %cl,%edi
f0103c10:	09 d7                	or     %edx,%edi
f0103c12:	89 f2                	mov    %esi,%edx
f0103c14:	89 f8                	mov    %edi,%eax
f0103c16:	f7 74 24 08          	divl   0x8(%esp)
f0103c1a:	89 d6                	mov    %edx,%esi
f0103c1c:	89 c7                	mov    %eax,%edi
f0103c1e:	f7 24 24             	mull   (%esp)
f0103c21:	39 d6                	cmp    %edx,%esi
f0103c23:	89 14 24             	mov    %edx,(%esp)
f0103c26:	72 30                	jb     f0103c58 <__udivdi3+0x118>
f0103c28:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103c2c:	89 e9                	mov    %ebp,%ecx
f0103c2e:	d3 e2                	shl    %cl,%edx
f0103c30:	39 c2                	cmp    %eax,%edx
f0103c32:	73 05                	jae    f0103c39 <__udivdi3+0xf9>
f0103c34:	3b 34 24             	cmp    (%esp),%esi
f0103c37:	74 1f                	je     f0103c58 <__udivdi3+0x118>
f0103c39:	89 f8                	mov    %edi,%eax
f0103c3b:	31 d2                	xor    %edx,%edx
f0103c3d:	e9 7a ff ff ff       	jmp    f0103bbc <__udivdi3+0x7c>
f0103c42:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103c48:	31 d2                	xor    %edx,%edx
f0103c4a:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c4f:	e9 68 ff ff ff       	jmp    f0103bbc <__udivdi3+0x7c>
f0103c54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103c58:	8d 47 ff             	lea    -0x1(%edi),%eax
f0103c5b:	31 d2                	xor    %edx,%edx
f0103c5d:	83 c4 0c             	add    $0xc,%esp
f0103c60:	5e                   	pop    %esi
f0103c61:	5f                   	pop    %edi
f0103c62:	5d                   	pop    %ebp
f0103c63:	c3                   	ret    
f0103c64:	66 90                	xchg   %ax,%ax
f0103c66:	66 90                	xchg   %ax,%ax
f0103c68:	66 90                	xchg   %ax,%ax
f0103c6a:	66 90                	xchg   %ax,%ax
f0103c6c:	66 90                	xchg   %ax,%ax
f0103c6e:	66 90                	xchg   %ax,%ax

f0103c70 <__umoddi3>:
f0103c70:	55                   	push   %ebp
f0103c71:	57                   	push   %edi
f0103c72:	56                   	push   %esi
f0103c73:	83 ec 14             	sub    $0x14,%esp
f0103c76:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103c7a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103c7e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0103c82:	89 c7                	mov    %eax,%edi
f0103c84:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c88:	8b 44 24 30          	mov    0x30(%esp),%eax
f0103c8c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103c90:	89 34 24             	mov    %esi,(%esp)
f0103c93:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103c97:	85 c0                	test   %eax,%eax
f0103c99:	89 c2                	mov    %eax,%edx
f0103c9b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103c9f:	75 17                	jne    f0103cb8 <__umoddi3+0x48>
f0103ca1:	39 fe                	cmp    %edi,%esi
f0103ca3:	76 4b                	jbe    f0103cf0 <__umoddi3+0x80>
f0103ca5:	89 c8                	mov    %ecx,%eax
f0103ca7:	89 fa                	mov    %edi,%edx
f0103ca9:	f7 f6                	div    %esi
f0103cab:	89 d0                	mov    %edx,%eax
f0103cad:	31 d2                	xor    %edx,%edx
f0103caf:	83 c4 14             	add    $0x14,%esp
f0103cb2:	5e                   	pop    %esi
f0103cb3:	5f                   	pop    %edi
f0103cb4:	5d                   	pop    %ebp
f0103cb5:	c3                   	ret    
f0103cb6:	66 90                	xchg   %ax,%ax
f0103cb8:	39 f8                	cmp    %edi,%eax
f0103cba:	77 54                	ja     f0103d10 <__umoddi3+0xa0>
f0103cbc:	0f bd e8             	bsr    %eax,%ebp
f0103cbf:	83 f5 1f             	xor    $0x1f,%ebp
f0103cc2:	75 5c                	jne    f0103d20 <__umoddi3+0xb0>
f0103cc4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0103cc8:	39 3c 24             	cmp    %edi,(%esp)
f0103ccb:	0f 87 e7 00 00 00    	ja     f0103db8 <__umoddi3+0x148>
f0103cd1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103cd5:	29 f1                	sub    %esi,%ecx
f0103cd7:	19 c7                	sbb    %eax,%edi
f0103cd9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103cdd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103ce1:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103ce5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103ce9:	83 c4 14             	add    $0x14,%esp
f0103cec:	5e                   	pop    %esi
f0103ced:	5f                   	pop    %edi
f0103cee:	5d                   	pop    %ebp
f0103cef:	c3                   	ret    
f0103cf0:	85 f6                	test   %esi,%esi
f0103cf2:	89 f5                	mov    %esi,%ebp
f0103cf4:	75 0b                	jne    f0103d01 <__umoddi3+0x91>
f0103cf6:	b8 01 00 00 00       	mov    $0x1,%eax
f0103cfb:	31 d2                	xor    %edx,%edx
f0103cfd:	f7 f6                	div    %esi
f0103cff:	89 c5                	mov    %eax,%ebp
f0103d01:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103d05:	31 d2                	xor    %edx,%edx
f0103d07:	f7 f5                	div    %ebp
f0103d09:	89 c8                	mov    %ecx,%eax
f0103d0b:	f7 f5                	div    %ebp
f0103d0d:	eb 9c                	jmp    f0103cab <__umoddi3+0x3b>
f0103d0f:	90                   	nop
f0103d10:	89 c8                	mov    %ecx,%eax
f0103d12:	89 fa                	mov    %edi,%edx
f0103d14:	83 c4 14             	add    $0x14,%esp
f0103d17:	5e                   	pop    %esi
f0103d18:	5f                   	pop    %edi
f0103d19:	5d                   	pop    %ebp
f0103d1a:	c3                   	ret    
f0103d1b:	90                   	nop
f0103d1c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d20:	8b 04 24             	mov    (%esp),%eax
f0103d23:	be 20 00 00 00       	mov    $0x20,%esi
f0103d28:	89 e9                	mov    %ebp,%ecx
f0103d2a:	29 ee                	sub    %ebp,%esi
f0103d2c:	d3 e2                	shl    %cl,%edx
f0103d2e:	89 f1                	mov    %esi,%ecx
f0103d30:	d3 e8                	shr    %cl,%eax
f0103d32:	89 e9                	mov    %ebp,%ecx
f0103d34:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d38:	8b 04 24             	mov    (%esp),%eax
f0103d3b:	09 54 24 04          	or     %edx,0x4(%esp)
f0103d3f:	89 fa                	mov    %edi,%edx
f0103d41:	d3 e0                	shl    %cl,%eax
f0103d43:	89 f1                	mov    %esi,%ecx
f0103d45:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103d49:	8b 44 24 10          	mov    0x10(%esp),%eax
f0103d4d:	d3 ea                	shr    %cl,%edx
f0103d4f:	89 e9                	mov    %ebp,%ecx
f0103d51:	d3 e7                	shl    %cl,%edi
f0103d53:	89 f1                	mov    %esi,%ecx
f0103d55:	d3 e8                	shr    %cl,%eax
f0103d57:	89 e9                	mov    %ebp,%ecx
f0103d59:	09 f8                	or     %edi,%eax
f0103d5b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0103d5f:	f7 74 24 04          	divl   0x4(%esp)
f0103d63:	d3 e7                	shl    %cl,%edi
f0103d65:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103d69:	89 d7                	mov    %edx,%edi
f0103d6b:	f7 64 24 08          	mull   0x8(%esp)
f0103d6f:	39 d7                	cmp    %edx,%edi
f0103d71:	89 c1                	mov    %eax,%ecx
f0103d73:	89 14 24             	mov    %edx,(%esp)
f0103d76:	72 2c                	jb     f0103da4 <__umoddi3+0x134>
f0103d78:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0103d7c:	72 22                	jb     f0103da0 <__umoddi3+0x130>
f0103d7e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103d82:	29 c8                	sub    %ecx,%eax
f0103d84:	19 d7                	sbb    %edx,%edi
f0103d86:	89 e9                	mov    %ebp,%ecx
f0103d88:	89 fa                	mov    %edi,%edx
f0103d8a:	d3 e8                	shr    %cl,%eax
f0103d8c:	89 f1                	mov    %esi,%ecx
f0103d8e:	d3 e2                	shl    %cl,%edx
f0103d90:	89 e9                	mov    %ebp,%ecx
f0103d92:	d3 ef                	shr    %cl,%edi
f0103d94:	09 d0                	or     %edx,%eax
f0103d96:	89 fa                	mov    %edi,%edx
f0103d98:	83 c4 14             	add    $0x14,%esp
f0103d9b:	5e                   	pop    %esi
f0103d9c:	5f                   	pop    %edi
f0103d9d:	5d                   	pop    %ebp
f0103d9e:	c3                   	ret    
f0103d9f:	90                   	nop
f0103da0:	39 d7                	cmp    %edx,%edi
f0103da2:	75 da                	jne    f0103d7e <__umoddi3+0x10e>
f0103da4:	8b 14 24             	mov    (%esp),%edx
f0103da7:	89 c1                	mov    %eax,%ecx
f0103da9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0103dad:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0103db1:	eb cb                	jmp    f0103d7e <__umoddi3+0x10e>
f0103db3:	90                   	nop
f0103db4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103db8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0103dbc:	0f 82 0f ff ff ff    	jb     f0103cd1 <__umoddi3+0x61>
f0103dc2:	e9 1a ff ff ff       	jmp    f0103ce1 <__umoddi3+0x71>
