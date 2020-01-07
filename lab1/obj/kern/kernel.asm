
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
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/monitor.h>
#include <kern/console.h>
// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 20 1a 10 f0 	movl   $0xf0101a20,(%esp)
f0100055:	e8 b3 09 00 00       	call   f0100a0d <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 54 07 00 00       	call   f01007db <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 3c 1a 10 f0 	movl   $0xf0101a3c,(%esp)
f0100092:	e8 76 09 00 00       	call   f0100a0d <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 b2 14 00 00       	call   f0101577 <memset>
	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 c0 04 00 00       	call   f010058a <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 57 1a 10 f0 	movl   $0xf0101a57,(%esp)
f01000d9:	e8 2f 09 00 00       	call   f0100a0d <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 9e 07 00 00       	call   f0100894 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 72 1a 10 f0 	movl   $0xf0101a72,(%esp)
f010012c:	e8 dc 08 00 00       	call   f0100a0d <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 9d 08 00 00       	call   f01009da <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 ae 1a 10 f0 	movl   $0xf0101aae,(%esp)
f0100144:	e8 c4 08 00 00       	call   f0100a0d <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 3f 07 00 00       	call   f0100894 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 8a 1a 10 f0 	movl   $0xf0101a8a,(%esp)
f0100176:	e8 92 08 00 00       	call   f0100a0d <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 50 08 00 00       	call   f01009da <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 ae 1a 10 f0 	movl   $0xf0101aae,(%esp)
f0100191:	e8 77 08 00 00       	call   f0100a0d <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 24 25 11 f0    	mov    %ecx,0xf0112524
f01001d9:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 ef 00 00 00    	je     f01002fd <kbd_proc_data+0xfd>
f010020e:	b2 60                	mov    $0x60,%dl
f0100210:	ec                   	in     (%dx),%al
f0100211:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100213:	3c e0                	cmp    $0xe0,%al
f0100215:	75 0d                	jne    f0100224 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100217:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f010021e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100223:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	53                   	push   %ebx
f0100228:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010022b:	84 c0                	test   %al,%al
f010022d:	79 37                	jns    f0100266 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010022f:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100235:	89 cb                	mov    %ecx,%ebx
f0100237:	83 e3 40             	and    $0x40,%ebx
f010023a:	83 e0 7f             	and    $0x7f,%eax
f010023d:	85 db                	test   %ebx,%ebx
f010023f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100242:	0f b6 d2             	movzbl %dl,%edx
f0100245:	0f b6 82 00 1c 10 f0 	movzbl -0xfefe400(%edx),%eax
f010024c:	83 c8 40             	or     $0x40,%eax
f010024f:	0f b6 c0             	movzbl %al,%eax
f0100252:	f7 d0                	not    %eax
f0100254:	21 c1                	and    %eax,%ecx
f0100256:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
		return 0;
f010025c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100261:	e9 9d 00 00 00       	jmp    f0100303 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100266:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010026c:	f6 c1 40             	test   $0x40,%cl
f010026f:	74 0e                	je     f010027f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100271:	83 c8 80             	or     $0xffffff80,%eax
f0100274:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100276:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100279:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010027f:	0f b6 d2             	movzbl %dl,%edx
f0100282:	0f b6 82 00 1c 10 f0 	movzbl -0xfefe400(%edx),%eax
f0100289:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f010028f:	0f b6 8a 00 1b 10 f0 	movzbl -0xfefe500(%edx),%ecx
f0100296:	31 c8                	xor    %ecx,%eax
f0100298:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f010029d:	89 c1                	mov    %eax,%ecx
f010029f:	83 e1 03             	and    $0x3,%ecx
f01002a2:	8b 0c 8d e0 1a 10 f0 	mov    -0xfefe520(,%ecx,4),%ecx
f01002a9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ad:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b0:	a8 08                	test   $0x8,%al
f01002b2:	74 1b                	je     f01002cf <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002b4:	89 da                	mov    %ebx,%edx
f01002b6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002b9:	83 f9 19             	cmp    $0x19,%ecx
f01002bc:	77 05                	ja     f01002c3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01002be:	83 eb 20             	sub    $0x20,%ebx
f01002c1:	eb 0c                	jmp    f01002cf <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002c3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002c9:	83 fa 19             	cmp    $0x19,%edx
f01002cc:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cf:	f7 d0                	not    %eax
f01002d1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d5:	f6 c2 06             	test   $0x6,%dl
f01002d8:	75 29                	jne    f0100303 <kbd_proc_data+0x103>
f01002da:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e0:	75 21                	jne    f0100303 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002e2:	c7 04 24 a4 1a 10 f0 	movl   $0xf0101aa4,(%esp)
f01002e9:	e8 1f 07 00 00       	call   f0100a0d <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f9:	89 d8                	mov    %ebx,%eax
f01002fb:	eb 06                	jmp    f0100303 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100302:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100303:	83 c4 14             	add    $0x14,%esp
f0100306:	5b                   	pop    %ebx
f0100307:	5d                   	pop    %ebp
f0100308:	c3                   	ret    

f0100309 <cons_putc>:

// output a character to the console
//将一个字符输出到控制台
static void
cons_putc(int c)
{
f0100309:	55                   	push   %ebp
f010030a:	89 e5                	mov    %esp,%ebp
f010030c:	57                   	push   %edi
f010030d:	56                   	push   %esi
f010030e:	53                   	push   %ebx
f010030f:	83 ec 1c             	sub    $0x1c,%esp
f0100312:	89 c7                	mov    %eax,%edi
f0100314:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100319:	be fd 03 00 00       	mov    $0x3fd,%esi
f010031e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100323:	eb 06                	jmp    f010032b <cons_putc+0x22>
f0100325:	89 ca                	mov    %ecx,%edx
f0100327:	ec                   	in     (%dx),%al
f0100328:	ec                   	in     (%dx),%al
f0100329:	ec                   	in     (%dx),%al
f010032a:	ec                   	in     (%dx),%al
f010032b:	89 f2                	mov    %esi,%edx
f010032d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010032e:	a8 20                	test   $0x20,%al
f0100330:	75 05                	jne    f0100337 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100332:	83 eb 01             	sub    $0x1,%ebx
f0100335:	75 ee                	jne    f0100325 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100337:	89 f8                	mov    %edi,%eax
f0100339:	0f b6 c0             	movzbl %al,%eax
f010033c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010033f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100344:	ee                   	out    %al,(%dx)
f0100345:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010034a:	be 79 03 00 00       	mov    $0x379,%esi
f010034f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100354:	eb 06                	jmp    f010035c <cons_putc+0x53>
f0100356:	89 ca                	mov    %ecx,%edx
f0100358:	ec                   	in     (%dx),%al
f0100359:	ec                   	in     (%dx),%al
f010035a:	ec                   	in     (%dx),%al
f010035b:	ec                   	in     (%dx),%al
f010035c:	89 f2                	mov    %esi,%edx
f010035e:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010035f:	84 c0                	test   %al,%al
f0100361:	78 05                	js     f0100368 <cons_putc+0x5f>
f0100363:	83 eb 01             	sub    $0x1,%ebx
f0100366:	75 ee                	jne    f0100356 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100368:	ba 78 03 00 00       	mov    $0x378,%edx
f010036d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100371:	ee                   	out    %al,(%dx)
f0100372:	b2 7a                	mov    $0x7a,%dl
f0100374:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100379:	ee                   	out    %al,(%dx)
f010037a:	b8 08 00 00 00       	mov    $0x8,%eax
f010037f:	ee                   	out    %al,(%dx)
static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	//如果没有给出属性，则在白色上使用黑色
	if (!(c & ~0xFF)) 
f0100380:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f0100386:	75 34                	jne    f01003bc <cons_putc+0xb3>
	{
   		 char ch = c & 0x0FF;
   		 if (ch > 47 && ch < 58) 
f0100388:	89 fa                	mov    %edi,%edx
f010038a:	8d 47 d0             	lea    -0x30(%edi),%eax
f010038d:	3c 09                	cmp    $0x9,%al
f010038f:	77 08                	ja     f0100399 <cons_putc+0x90>
		 { 
     		    c |= 0x0800;
f0100391:	81 cf 00 08 00 00    	or     $0x800,%edi
f0100397:	eb 23                	jmp    f01003bc <cons_putc+0xb3>
    		 } 
		 else if (ch > 64 && ch < 91) 
f0100399:	8d 47 bf             	lea    -0x41(%edi),%eax
f010039c:	3c 19                	cmp    $0x19,%al
f010039e:	77 08                	ja     f01003a8 <cons_putc+0x9f>
		 {
     		    c |= 0x0700;
f01003a0:	81 cf 00 07 00 00    	or     $0x700,%edi
f01003a6:	eb 14                	jmp    f01003bc <cons_putc+0xb3>
    		 } 
 		 else if (ch > 96 && ch < 123) 
f01003a8:	83 ea 61             	sub    $0x61,%edx
		 {
                    c |= 0x0a00;
f01003ab:	89 f8                	mov    %edi,%eax
f01003ad:	80 cc 0a             	or     $0xa,%ah
f01003b0:	81 cf 00 01 00 00    	or     $0x100,%edi
f01003b6:	80 fa 19             	cmp    $0x19,%dl
f01003b9:	0f 46 f8             	cmovbe %eax,%edi
		 else 
		 {
        	    c |= 0x0100;
    		 }
	}
	switch (c & 0xff) {
f01003bc:	89 f8                	mov    %edi,%eax
f01003be:	0f b6 c0             	movzbl %al,%eax
f01003c1:	83 f8 09             	cmp    $0x9,%eax
f01003c4:	74 77                	je     f010043d <cons_putc+0x134>
f01003c6:	83 f8 09             	cmp    $0x9,%eax
f01003c9:	7f 0a                	jg     f01003d5 <cons_putc+0xcc>
f01003cb:	83 f8 08             	cmp    $0x8,%eax
f01003ce:	74 17                	je     f01003e7 <cons_putc+0xde>
f01003d0:	e9 9c 00 00 00       	jmp    f0100471 <cons_putc+0x168>
f01003d5:	83 f8 0a             	cmp    $0xa,%eax
f01003d8:	74 3d                	je     f0100417 <cons_putc+0x10e>
f01003da:	83 f8 0d             	cmp    $0xd,%eax
f01003dd:	8d 76 00             	lea    0x0(%esi),%esi
f01003e0:	74 3d                	je     f010041f <cons_putc+0x116>
f01003e2:	e9 8a 00 00 00       	jmp    f0100471 <cons_putc+0x168>
	case '\b':
		if (crt_pos > 0) {
f01003e7:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003ee:	66 85 c0             	test   %ax,%ax
f01003f1:	0f 84 e5 00 00 00    	je     f01004dc <cons_putc+0x1d3>
			crt_pos--;
f01003f7:	83 e8 01             	sub    $0x1,%eax
f01003fa:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100400:	0f b7 c0             	movzwl %ax,%eax
f0100403:	66 81 e7 00 ff       	and    $0xff00,%di
f0100408:	83 cf 20             	or     $0x20,%edi
f010040b:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100411:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100415:	eb 78                	jmp    f010048f <cons_putc+0x186>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100417:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f010041e:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010041f:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100426:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010042c:	c1 e8 16             	shr    $0x16,%eax
f010042f:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100432:	c1 e0 04             	shl    $0x4,%eax
f0100435:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f010043b:	eb 52                	jmp    f010048f <cons_putc+0x186>
		break;
	case '\t':
		cons_putc(' ');
f010043d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100442:	e8 c2 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100447:	b8 20 00 00 00       	mov    $0x20,%eax
f010044c:	e8 b8 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100451:	b8 20 00 00 00       	mov    $0x20,%eax
f0100456:	e8 ae fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010045b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100460:	e8 a4 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100465:	b8 20 00 00 00       	mov    $0x20,%eax
f010046a:	e8 9a fe ff ff       	call   f0100309 <cons_putc>
f010046f:	eb 1e                	jmp    f010048f <cons_putc+0x186>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100471:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100478:	8d 50 01             	lea    0x1(%eax),%edx
f010047b:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100482:	0f b7 c0             	movzwl %ax,%eax
f0100485:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f010048b:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010048f:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f0100496:	cf 07 
f0100498:	76 42                	jbe    f01004dc <cons_putc+0x1d3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010049a:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f010049f:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01004a6:	00 
f01004a7:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004ad:	89 54 24 04          	mov    %edx,0x4(%esp)
f01004b1:	89 04 24             	mov    %eax,(%esp)
f01004b4:	e8 0b 11 00 00       	call   f01015c4 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01004b9:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004bf:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01004c4:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004ca:	83 c0 01             	add    $0x1,%eax
f01004cd:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004d2:	75 f0                	jne    f01004c4 <cons_putc+0x1bb>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004d4:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004db:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004dc:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004e2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004e7:	89 ca                	mov    %ecx,%edx
f01004e9:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004ea:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004f1:	8d 71 01             	lea    0x1(%ecx),%esi
f01004f4:	89 d8                	mov    %ebx,%eax
f01004f6:	66 c1 e8 08          	shr    $0x8,%ax
f01004fa:	89 f2                	mov    %esi,%edx
f01004fc:	ee                   	out    %al,(%dx)
f01004fd:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100502:	89 ca                	mov    %ecx,%edx
f0100504:	ee                   	out    %al,(%dx)
f0100505:	89 d8                	mov    %ebx,%eax
f0100507:	89 f2                	mov    %esi,%edx
f0100509:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);//把一个字符输出给串口
	lpt_putc(c);//把一个字符输出给并口
	cga_putc(c);//把字符输出到cga（彩色适配器，即显示器）上
}
f010050a:	83 c4 1c             	add    $0x1c,%esp
f010050d:	5b                   	pop    %ebx
f010050e:	5e                   	pop    %esi
f010050f:	5f                   	pop    %edi
f0100510:	5d                   	pop    %ebp
f0100511:	c3                   	ret    

f0100512 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100512:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f0100519:	74 11                	je     f010052c <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010051b:	55                   	push   %ebp
f010051c:	89 e5                	mov    %esp,%ebp
f010051e:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100521:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f0100526:	e8 91 fc ff ff       	call   f01001bc <cons_intr>
}
f010052b:	c9                   	leave  
f010052c:	f3 c3                	repz ret 

f010052e <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010052e:	55                   	push   %ebp
f010052f:	89 e5                	mov    %esp,%ebp
f0100531:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100534:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f0100539:	e8 7e fc ff ff       	call   f01001bc <cons_intr>
}
f010053e:	c9                   	leave  
f010053f:	c3                   	ret    

f0100540 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100540:	55                   	push   %ebp
f0100541:	89 e5                	mov    %esp,%ebp
f0100543:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100546:	e8 c7 ff ff ff       	call   f0100512 <serial_intr>
	kbd_intr();
f010054b:	e8 de ff ff ff       	call   f010052e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100550:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f0100555:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f010055b:	74 26                	je     f0100583 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f010055d:	8d 50 01             	lea    0x1(%eax),%edx
f0100560:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f0100566:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f010056d:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010056f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100575:	75 11                	jne    f0100588 <cons_getc+0x48>
			cons.rpos = 0;
f0100577:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f010057e:	00 00 00 
f0100581:	eb 05                	jmp    f0100588 <cons_getc+0x48>
		return c;
	}
	return 0;
f0100583:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100588:	c9                   	leave  
f0100589:	c3                   	ret    

f010058a <cons_init>:
// initialize the console device
//初始化控制台设备

void
cons_init(void)
{
f010058a:	55                   	push   %ebp
f010058b:	89 e5                	mov    %esp,%ebp
f010058d:	57                   	push   %edi
f010058e:	56                   	push   %esi
f010058f:	53                   	push   %ebx
f0100590:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100593:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010059a:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005a1:	5a a5 
	if (*cp != 0xA55A) {
f01005a3:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005aa:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005ae:	74 11                	je     f01005c1 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01005b0:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f01005b7:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005ba:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01005bf:	eb 16                	jmp    f01005d7 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005c1:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005c8:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005cf:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005d2:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005d7:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01005dd:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005e2:	89 ca                	mov    %ecx,%edx
f01005e4:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005e5:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e8:	89 da                	mov    %ebx,%edx
f01005ea:	ec                   	in     (%dx),%al
f01005eb:	0f b6 f0             	movzbl %al,%esi
f01005ee:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005f1:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005f6:	89 ca                	mov    %ecx,%edx
f01005f8:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005f9:	89 da                	mov    %ebx,%edx
f01005fb:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005fc:	89 3d 2c 25 11 f0    	mov    %edi,0xf011252c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100602:	0f b6 d8             	movzbl %al,%ebx
f0100605:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100607:	66 89 35 28 25 11 f0 	mov    %si,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010060e:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100613:	b8 00 00 00 00       	mov    $0x0,%eax
f0100618:	89 f2                	mov    %esi,%edx
f010061a:	ee                   	out    %al,(%dx)
f010061b:	b2 fb                	mov    $0xfb,%dl
f010061d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100622:	ee                   	out    %al,(%dx)
f0100623:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100628:	b8 0c 00 00 00       	mov    $0xc,%eax
f010062d:	89 da                	mov    %ebx,%edx
f010062f:	ee                   	out    %al,(%dx)
f0100630:	b2 f9                	mov    $0xf9,%dl
f0100632:	b8 00 00 00 00       	mov    $0x0,%eax
f0100637:	ee                   	out    %al,(%dx)
f0100638:	b2 fb                	mov    $0xfb,%dl
f010063a:	b8 03 00 00 00       	mov    $0x3,%eax
f010063f:	ee                   	out    %al,(%dx)
f0100640:	b2 fc                	mov    $0xfc,%dl
f0100642:	b8 00 00 00 00       	mov    $0x0,%eax
f0100647:	ee                   	out    %al,(%dx)
f0100648:	b2 f9                	mov    $0xf9,%dl
f010064a:	b8 01 00 00 00       	mov    $0x1,%eax
f010064f:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100650:	b2 fd                	mov    $0xfd,%dl
f0100652:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100653:	3c ff                	cmp    $0xff,%al
f0100655:	0f 95 c1             	setne  %cl
f0100658:	88 0d 34 25 11 f0    	mov    %cl,0xf0112534
f010065e:	89 f2                	mov    %esi,%edx
f0100660:	ec                   	in     (%dx),%al
f0100661:	89 da                	mov    %ebx,%edx
f0100663:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100664:	84 c9                	test   %cl,%cl
f0100666:	75 0c                	jne    f0100674 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f0100668:	c7 04 24 b0 1a 10 f0 	movl   $0xf0101ab0,(%esp)
f010066f:	e8 99 03 00 00       	call   f0100a0d <cprintf>
}
f0100674:	83 c4 1c             	add    $0x1c,%esp
f0100677:	5b                   	pop    %ebx
f0100678:	5e                   	pop    %esi
f0100679:	5f                   	pop    %edi
f010067a:	5d                   	pop    %ebp
f010067b:	c3                   	ret    

f010067c <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.
//`高级控制台I / O. 由readline和cprintf使用。
void
cputchar(int c)
{
f010067c:	55                   	push   %ebp
f010067d:	89 e5                	mov    %esp,%ebp
f010067f:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100682:	8b 45 08             	mov    0x8(%ebp),%eax
f0100685:	e8 7f fc ff ff       	call   f0100309 <cons_putc>
}
f010068a:	c9                   	leave  
f010068b:	c3                   	ret    

f010068c <getchar>:

int
getchar(void)
{
f010068c:	55                   	push   %ebp
f010068d:	89 e5                	mov    %esp,%ebp
f010068f:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100692:	e8 a9 fe ff ff       	call   f0100540 <cons_getc>
f0100697:	85 c0                	test   %eax,%eax
f0100699:	74 f7                	je     f0100692 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010069b:	c9                   	leave  
f010069c:	c3                   	ret    

f010069d <iscons>:

int
iscons(int fdnum)
{
f010069d:	55                   	push   %ebp
f010069e:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01006a0:	b8 01 00 00 00       	mov    $0x1,%eax
f01006a5:	5d                   	pop    %ebp
f01006a6:	c3                   	ret    
f01006a7:	66 90                	xchg   %ax,%ax
f01006a9:	66 90                	xchg   %ax,%ax
f01006ab:	66 90                	xchg   %ax,%ax
f01006ad:	66 90                	xchg   %ax,%ax
f01006af:	90                   	nop

f01006b0 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006b0:	55                   	push   %ebp
f01006b1:	89 e5                	mov    %esp,%ebp
f01006b3:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006b6:	c7 44 24 08 00 1d 10 	movl   $0xf0101d00,0x8(%esp)
f01006bd:	f0 
f01006be:	c7 44 24 04 1e 1d 10 	movl   $0xf0101d1e,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 23 1d 10 f0 	movl   $0xf0101d23,(%esp)
f01006cd:	e8 3b 03 00 00       	call   f0100a0d <cprintf>
f01006d2:	c7 44 24 08 d8 1d 10 	movl   $0xf0101dd8,0x8(%esp)
f01006d9:	f0 
f01006da:	c7 44 24 04 2c 1d 10 	movl   $0xf0101d2c,0x4(%esp)
f01006e1:	f0 
f01006e2:	c7 04 24 23 1d 10 f0 	movl   $0xf0101d23,(%esp)
f01006e9:	e8 1f 03 00 00       	call   f0100a0d <cprintf>
f01006ee:	c7 44 24 08 d8 1d 10 	movl   $0xf0101dd8,0x8(%esp)
f01006f5:	f0 
f01006f6:	c7 44 24 04 35 1d 10 	movl   $0xf0101d35,0x4(%esp)
f01006fd:	f0 
f01006fe:	c7 04 24 23 1d 10 f0 	movl   $0xf0101d23,(%esp)
f0100705:	e8 03 03 00 00       	call   f0100a0d <cprintf>
	return 0;
}
f010070a:	b8 00 00 00 00       	mov    $0x0,%eax
f010070f:	c9                   	leave  
f0100710:	c3                   	ret    

f0100711 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100711:	55                   	push   %ebp
f0100712:	89 e5                	mov    %esp,%ebp
f0100714:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100717:	c7 04 24 3f 1d 10 f0 	movl   $0xf0101d3f,(%esp)
f010071e:	e8 ea 02 00 00       	call   f0100a0d <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100723:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010072a:	00 
f010072b:	c7 04 24 00 1e 10 f0 	movl   $0xf0101e00,(%esp)
f0100732:	e8 d6 02 00 00       	call   f0100a0d <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100737:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010073e:	00 
f010073f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100746:	f0 
f0100747:	c7 04 24 28 1e 10 f0 	movl   $0xf0101e28,(%esp)
f010074e:	e8 ba 02 00 00       	call   f0100a0d <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100753:	c7 44 24 08 07 1a 10 	movl   $0x101a07,0x8(%esp)
f010075a:	00 
f010075b:	c7 44 24 04 07 1a 10 	movl   $0xf0101a07,0x4(%esp)
f0100762:	f0 
f0100763:	c7 04 24 4c 1e 10 f0 	movl   $0xf0101e4c,(%esp)
f010076a:	e8 9e 02 00 00       	call   f0100a0d <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010076f:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100776:	00 
f0100777:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010077e:	f0 
f010077f:	c7 04 24 70 1e 10 f0 	movl   $0xf0101e70,(%esp)
f0100786:	e8 82 02 00 00       	call   f0100a0d <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010078b:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100792:	00 
f0100793:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f010079a:	f0 
f010079b:	c7 04 24 94 1e 10 f0 	movl   $0xf0101e94,(%esp)
f01007a2:	e8 66 02 00 00       	call   f0100a0d <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01007a7:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f01007ac:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01007b1:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007b6:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01007bc:	85 c0                	test   %eax,%eax
f01007be:	0f 48 c2             	cmovs  %edx,%eax
f01007c1:	c1 f8 0a             	sar    $0xa,%eax
f01007c4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007c8:	c7 04 24 b8 1e 10 f0 	movl   $0xf0101eb8,(%esp)
f01007cf:	e8 39 02 00 00       	call   f0100a0d <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01007d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01007d9:	c9                   	leave  
f01007da:	c3                   	ret    

f01007db <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007db:	55                   	push   %ebp
f01007dc:	89 e5                	mov    %esp,%ebp
f01007de:	57                   	push   %edi
f01007df:	56                   	push   %esi
f01007e0:	53                   	push   %ebx
f01007e1:	83 ec 4c             	sub    $0x4c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01007e4:	89 ee                	mov    %ebp,%esi
	// Your code here.
      uint32_t ebp,eip;
        ebp = read_ebp();
        cprintf("Stack backtrace:\n");
f01007e6:	c7 04 24 58 1d 10 f0 	movl   $0xf0101d58,(%esp)
f01007ed:	e8 1b 02 00 00       	call   f0100a0d <cprintf>
        uint32_t esp = ebp;
	struct Eipdebuginfo eipinfo;
        while (ebp)
f01007f2:	e9 88 00 00 00       	jmp    f010087f <mon_backtrace+0xa4>
        {
                eip = *(uint32_t*)(ebp + 4);
f01007f7:	8b 7e 04             	mov    0x4(%esi),%edi
                cprintf("ebp %08x eip %08x args ",ebp,eip);
f01007fa:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01007fe:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100802:	c7 04 24 6a 1d 10 f0 	movl   $0xf0101d6a,(%esp)
f0100809:	e8 ff 01 00 00       	call   f0100a0d <cprintf>
                ebp = *(uint32_t*)(esp);
f010080e:	8b 06                	mov    (%esi),%eax
f0100810:	89 45 c4             	mov    %eax,-0x3c(%ebp)
                esp += 8;
f0100813:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100816:	83 c6 1c             	add    $0x1c,%esi
		int i = 1;
                for(i = 1;i < 6;i++)
                {
                        cprintf("%08x ",*(uint32_t*)(esp));
f0100819:	8b 03                	mov    (%ebx),%eax
f010081b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010081f:	c7 04 24 82 1d 10 f0 	movl   $0xf0101d82,(%esp)
f0100826:	e8 e2 01 00 00       	call   f0100a0d <cprintf>
                        esp += 4;
f010082b:	83 c3 04             	add    $0x4,%ebx
                eip = *(uint32_t*)(ebp + 4);
                cprintf("ebp %08x eip %08x args ",ebp,eip);
                ebp = *(uint32_t*)(esp);
                esp += 8;
		int i = 1;
                for(i = 1;i < 6;i++)
f010082e:	39 f3                	cmp    %esi,%ebx
f0100830:	75 e7                	jne    f0100819 <mon_backtrace+0x3e>
                {
                        cprintf("%08x ",*(uint32_t*)(esp));
                        esp += 4;
                }
		debuginfo_eip(eip,&eipinfo);
f0100832:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100835:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100839:	89 3c 24             	mov    %edi,(%esp)
f010083c:	e8 c3 02 00 00       	call   f0100b04 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n",eipinfo.eip_file,eipinfo.eip_line,
f0100841:	2b 7d e0             	sub    -0x20(%ebp),%edi
f0100844:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0100848:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010084b:	89 44 24 10          	mov    %eax,0x10(%esp)
f010084f:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100852:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100856:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100859:	89 44 24 08          	mov    %eax,0x8(%esp)
f010085d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100860:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100864:	c7 04 24 88 1d 10 f0 	movl   $0xf0101d88,(%esp)
f010086b:	e8 9d 01 00 00       	call   f0100a0d <cprintf>
			eipinfo.eip_fn_namelen,eipinfo.eip_fn_name,
			eip-eipinfo.eip_fn_addr);
                cprintf("\n");
f0100870:	c7 04 24 ae 1a 10 f0 	movl   $0xf0101aae,(%esp)
f0100877:	e8 91 01 00 00       	call   f0100a0d <cprintf>
	struct Eipdebuginfo eipinfo;
        while (ebp)
        {
                eip = *(uint32_t*)(ebp + 4);
                cprintf("ebp %08x eip %08x args ",ebp,eip);
                ebp = *(uint32_t*)(esp);
f010087c:	8b 75 c4             	mov    -0x3c(%ebp),%esi
      uint32_t ebp,eip;
        ebp = read_ebp();
        cprintf("Stack backtrace:\n");
        uint32_t esp = ebp;
	struct Eipdebuginfo eipinfo;
        while (ebp)
f010087f:	85 f6                	test   %esi,%esi
f0100881:	0f 85 70 ff ff ff    	jne    f01007f7 <mon_backtrace+0x1c>
			eip-eipinfo.eip_fn_addr);
                cprintf("\n");
                esp = ebp;
        }
 	return 0;
}
f0100887:	b8 00 00 00 00       	mov    $0x0,%eax
f010088c:	83 c4 4c             	add    $0x4c,%esp
f010088f:	5b                   	pop    %ebx
f0100890:	5e                   	pop    %esi
f0100891:	5f                   	pop    %edi
f0100892:	5d                   	pop    %ebp
f0100893:	c3                   	ret    

f0100894 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100894:	55                   	push   %ebp
f0100895:	89 e5                	mov    %esp,%ebp
f0100897:	57                   	push   %edi
f0100898:	56                   	push   %esi
f0100899:	53                   	push   %ebx
f010089a:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010089d:	c7 04 24 e4 1e 10 f0 	movl   $0xf0101ee4,(%esp)
f01008a4:	e8 64 01 00 00       	call   f0100a0d <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008a9:	c7 04 24 08 1f 10 f0 	movl   $0xf0101f08,(%esp)
f01008b0:	e8 58 01 00 00       	call   f0100a0d <cprintf>


	while (1) {
		buf = readline("K> ");
f01008b5:	c7 04 24 99 1d 10 f0 	movl   $0xf0101d99,(%esp)
f01008bc:	e8 5f 0a 00 00       	call   f0101320 <readline>
f01008c1:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008c3:	85 c0                	test   %eax,%eax
f01008c5:	74 ee                	je     f01008b5 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008c7:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008ce:	be 00 00 00 00       	mov    $0x0,%esi
f01008d3:	eb 0a                	jmp    f01008df <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008d5:	c6 03 00             	movb   $0x0,(%ebx)
f01008d8:	89 f7                	mov    %esi,%edi
f01008da:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008dd:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008df:	0f b6 03             	movzbl (%ebx),%eax
f01008e2:	84 c0                	test   %al,%al
f01008e4:	74 63                	je     f0100949 <monitor+0xb5>
f01008e6:	0f be c0             	movsbl %al,%eax
f01008e9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008ed:	c7 04 24 9d 1d 10 f0 	movl   $0xf0101d9d,(%esp)
f01008f4:	e8 41 0c 00 00       	call   f010153a <strchr>
f01008f9:	85 c0                	test   %eax,%eax
f01008fb:	75 d8                	jne    f01008d5 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01008fd:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100900:	74 47                	je     f0100949 <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100902:	83 fe 0f             	cmp    $0xf,%esi
f0100905:	75 16                	jne    f010091d <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100907:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010090e:	00 
f010090f:	c7 04 24 a2 1d 10 f0 	movl   $0xf0101da2,(%esp)
f0100916:	e8 f2 00 00 00       	call   f0100a0d <cprintf>
f010091b:	eb 98                	jmp    f01008b5 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f010091d:	8d 7e 01             	lea    0x1(%esi),%edi
f0100920:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100924:	eb 03                	jmp    f0100929 <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100926:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100929:	0f b6 03             	movzbl (%ebx),%eax
f010092c:	84 c0                	test   %al,%al
f010092e:	74 ad                	je     f01008dd <monitor+0x49>
f0100930:	0f be c0             	movsbl %al,%eax
f0100933:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100937:	c7 04 24 9d 1d 10 f0 	movl   $0xf0101d9d,(%esp)
f010093e:	e8 f7 0b 00 00       	call   f010153a <strchr>
f0100943:	85 c0                	test   %eax,%eax
f0100945:	74 df                	je     f0100926 <monitor+0x92>
f0100947:	eb 94                	jmp    f01008dd <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f0100949:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100950:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100951:	85 f6                	test   %esi,%esi
f0100953:	0f 84 5c ff ff ff    	je     f01008b5 <monitor+0x21>
f0100959:	bb 00 00 00 00       	mov    $0x0,%ebx
f010095e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100961:	8b 04 85 40 1f 10 f0 	mov    -0xfefe0c0(,%eax,4),%eax
f0100968:	89 44 24 04          	mov    %eax,0x4(%esp)
f010096c:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010096f:	89 04 24             	mov    %eax,(%esp)
f0100972:	e8 65 0b 00 00       	call   f01014dc <strcmp>
f0100977:	85 c0                	test   %eax,%eax
f0100979:	75 24                	jne    f010099f <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f010097b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010097e:	8b 55 08             	mov    0x8(%ebp),%edx
f0100981:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100985:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100988:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010098c:	89 34 24             	mov    %esi,(%esp)
f010098f:	ff 14 85 48 1f 10 f0 	call   *-0xfefe0b8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100996:	85 c0                	test   %eax,%eax
f0100998:	78 25                	js     f01009bf <monitor+0x12b>
f010099a:	e9 16 ff ff ff       	jmp    f01008b5 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010099f:	83 c3 01             	add    $0x1,%ebx
f01009a2:	83 fb 03             	cmp    $0x3,%ebx
f01009a5:	75 b7                	jne    f010095e <monitor+0xca>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01009a7:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01009aa:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009ae:	c7 04 24 bf 1d 10 f0 	movl   $0xf0101dbf,(%esp)
f01009b5:	e8 53 00 00 00       	call   f0100a0d <cprintf>
f01009ba:	e9 f6 fe ff ff       	jmp    f01008b5 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009bf:	83 c4 5c             	add    $0x5c,%esp
f01009c2:	5b                   	pop    %ebx
f01009c3:	5e                   	pop    %esi
f01009c4:	5f                   	pop    %edi
f01009c5:	5d                   	pop    %ebp
f01009c6:	c3                   	ret    

f01009c7 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009c7:	55                   	push   %ebp
f01009c8:	89 e5                	mov    %esp,%ebp
f01009ca:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01009cd:	8b 45 08             	mov    0x8(%ebp),%eax
f01009d0:	89 04 24             	mov    %eax,(%esp)
f01009d3:	e8 a4 fc ff ff       	call   f010067c <cputchar>
//调用了console.c中的cputchar程序
	*cnt++;
}
f01009d8:	c9                   	leave  
f01009d9:	c3                   	ret    

f01009da <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009da:	55                   	push   %ebp
f01009db:	89 e5                	mov    %esp,%ebp
f01009dd:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009e0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009e7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009ea:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01009f1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009f5:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009f8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009fc:	c7 04 24 c7 09 10 f0 	movl   $0xf01009c7,(%esp)
f0100a03:	e8 b6 04 00 00       	call   f0100ebe <vprintfmt>
//调用了printfmt.c中的vprintfmt（）
	return cnt;
}
f0100a08:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a0b:	c9                   	leave  
f0100a0c:	c3                   	ret    

f0100a0d <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a0d:	55                   	push   %ebp
f0100a0e:	89 e5                	mov    %esp,%ebp
f0100a10:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a13:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a16:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a1a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a1d:	89 04 24             	mov    %eax,(%esp)
f0100a20:	e8 b5 ff ff ff       	call   f01009da <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a25:	c9                   	leave  
f0100a26:	c3                   	ret    

f0100a27 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a27:	55                   	push   %ebp
f0100a28:	89 e5                	mov    %esp,%ebp
f0100a2a:	57                   	push   %edi
f0100a2b:	56                   	push   %esi
f0100a2c:	53                   	push   %ebx
f0100a2d:	83 ec 10             	sub    $0x10,%esp
f0100a30:	89 c6                	mov    %eax,%esi
f0100a32:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a35:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a38:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a3b:	8b 1a                	mov    (%edx),%ebx
f0100a3d:	8b 01                	mov    (%ecx),%eax
f0100a3f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a42:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100a49:	eb 77                	jmp    f0100ac2 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a4b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a4e:	01 d8                	add    %ebx,%eax
f0100a50:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a55:	99                   	cltd   
f0100a56:	f7 f9                	idiv   %ecx
f0100a58:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a5a:	eb 01                	jmp    f0100a5d <stab_binsearch+0x36>
			m--;
f0100a5c:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a5d:	39 d9                	cmp    %ebx,%ecx
f0100a5f:	7c 1d                	jl     f0100a7e <stab_binsearch+0x57>
f0100a61:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a64:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a69:	39 fa                	cmp    %edi,%edx
f0100a6b:	75 ef                	jne    f0100a5c <stab_binsearch+0x35>
f0100a6d:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a70:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a73:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a77:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a7a:	73 18                	jae    f0100a94 <stab_binsearch+0x6d>
f0100a7c:	eb 05                	jmp    f0100a83 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a7e:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a81:	eb 3f                	jmp    f0100ac2 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a83:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a86:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100a88:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a8b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a92:	eb 2e                	jmp    f0100ac2 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a94:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a97:	73 15                	jae    f0100aae <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a99:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a9c:	48                   	dec    %eax
f0100a9d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100aa0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100aa3:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100aa5:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100aac:	eb 14                	jmp    f0100ac2 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100aae:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100ab1:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100ab4:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100ab6:	ff 45 0c             	incl   0xc(%ebp)
f0100ab9:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100abb:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100ac2:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100ac5:	7e 84                	jle    f0100a4b <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100ac7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100acb:	75 0d                	jne    f0100ada <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100acd:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100ad0:	8b 00                	mov    (%eax),%eax
f0100ad2:	48                   	dec    %eax
f0100ad3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ad6:	89 07                	mov    %eax,(%edi)
f0100ad8:	eb 22                	jmp    f0100afc <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ada:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100add:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100adf:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100ae2:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ae4:	eb 01                	jmp    f0100ae7 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100ae6:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ae7:	39 c1                	cmp    %eax,%ecx
f0100ae9:	7d 0c                	jge    f0100af7 <stab_binsearch+0xd0>
f0100aeb:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100aee:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100af3:	39 fa                	cmp    %edi,%edx
f0100af5:	75 ef                	jne    f0100ae6 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100af7:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100afa:	89 07                	mov    %eax,(%edi)
	}
}
f0100afc:	83 c4 10             	add    $0x10,%esp
f0100aff:	5b                   	pop    %ebx
f0100b00:	5e                   	pop    %esi
f0100b01:	5f                   	pop    %edi
f0100b02:	5d                   	pop    %ebp
f0100b03:	c3                   	ret    

f0100b04 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b04:	55                   	push   %ebp
f0100b05:	89 e5                	mov    %esp,%ebp
f0100b07:	57                   	push   %edi
f0100b08:	56                   	push   %esi
f0100b09:	53                   	push   %ebx
f0100b0a:	83 ec 3c             	sub    $0x3c,%esp
f0100b0d:	8b 75 08             	mov    0x8(%ebp),%esi
f0100b10:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b13:	c7 03 64 1f 10 f0    	movl   $0xf0101f64,(%ebx)
	info->eip_line = 0;
f0100b19:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b20:	c7 43 08 64 1f 10 f0 	movl   $0xf0101f64,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b27:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b2e:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b31:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b38:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b3e:	76 12                	jbe    f0100b52 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b40:	b8 71 74 10 f0       	mov    $0xf0107471,%eax
f0100b45:	3d 59 5b 10 f0       	cmp    $0xf0105b59,%eax
f0100b4a:	0f 86 d2 01 00 00    	jbe    f0100d22 <debuginfo_eip+0x21e>
f0100b50:	eb 1c                	jmp    f0100b6e <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b52:	c7 44 24 08 6e 1f 10 	movl   $0xf0101f6e,0x8(%esp)
f0100b59:	f0 
f0100b5a:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b61:	00 
f0100b62:	c7 04 24 7b 1f 10 f0 	movl   $0xf0101f7b,(%esp)
f0100b69:	e8 8a f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b6e:	80 3d 70 74 10 f0 00 	cmpb   $0x0,0xf0107470
f0100b75:	0f 85 ae 01 00 00    	jne    f0100d29 <debuginfo_eip+0x225>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b7b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b82:	b8 58 5b 10 f0       	mov    $0xf0105b58,%eax
f0100b87:	2d b0 21 10 f0       	sub    $0xf01021b0,%eax
f0100b8c:	c1 f8 02             	sar    $0x2,%eax
f0100b8f:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b95:	83 e8 01             	sub    $0x1,%eax
f0100b98:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b9b:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b9f:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100ba6:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100ba9:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100bac:	b8 b0 21 10 f0       	mov    $0xf01021b0,%eax
f0100bb1:	e8 71 fe ff ff       	call   f0100a27 <stab_binsearch>
	if (lfile == 0)
f0100bb6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bb9:	85 c0                	test   %eax,%eax
f0100bbb:	0f 84 6f 01 00 00    	je     f0100d30 <debuginfo_eip+0x22c>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100bc1:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100bc4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bc7:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100bca:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bce:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100bd5:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100bd8:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bdb:	b8 b0 21 10 f0       	mov    $0xf01021b0,%eax
f0100be0:	e8 42 fe ff ff       	call   f0100a27 <stab_binsearch>

	if (lfun <= rfun) {
f0100be5:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100be8:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100beb:	39 d0                	cmp    %edx,%eax
f0100bed:	7f 3d                	jg     f0100c2c <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bef:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100bf2:	8d b9 b0 21 10 f0    	lea    -0xfefde50(%ecx),%edi
f0100bf8:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100bfb:	8b 89 b0 21 10 f0    	mov    -0xfefde50(%ecx),%ecx
f0100c01:	bf 71 74 10 f0       	mov    $0xf0107471,%edi
f0100c06:	81 ef 59 5b 10 f0    	sub    $0xf0105b59,%edi
f0100c0c:	39 f9                	cmp    %edi,%ecx
f0100c0e:	73 09                	jae    f0100c19 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c10:	81 c1 59 5b 10 f0    	add    $0xf0105b59,%ecx
f0100c16:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c19:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100c1c:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100c1f:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100c22:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100c24:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100c27:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100c2a:	eb 0f                	jmp    f0100c3b <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c2c:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c2f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c32:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c35:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c38:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c3b:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c42:	00 
f0100c43:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c46:	89 04 24             	mov    %eax,(%esp)
f0100c49:	e8 0d 09 00 00       	call   f010155b <strfind>
f0100c4e:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c51:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100c54:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c58:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100c5f:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c62:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c65:	b8 b0 21 10 f0       	mov    $0xf01021b0,%eax
f0100c6a:	e8 b8 fd ff ff       	call   f0100a27 <stab_binsearch>
	if(lline <= rline) {
f0100c6f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c72:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100c75:	7f 0f                	jg     f0100c86 <debuginfo_eip+0x182>
  		info->eip_line = stabs[lline].n_desc;
f0100c77:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c7a:	0f b7 80 b6 21 10 f0 	movzwl -0xfefde4a(%eax),%eax
f0100c81:	89 43 04             	mov    %eax,0x4(%ebx)
f0100c84:	eb 07                	jmp    f0100c8d <debuginfo_eip+0x189>
	}
	else info->eip_line = -1;
f0100c86:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c8d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c90:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100c93:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c96:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100c99:	81 c2 b0 21 10 f0    	add    $0xf01021b0,%edx
f0100c9f:	eb 06                	jmp    f0100ca7 <debuginfo_eip+0x1a3>
f0100ca1:	83 e8 01             	sub    $0x1,%eax
f0100ca4:	83 ea 0c             	sub    $0xc,%edx
f0100ca7:	89 c6                	mov    %eax,%esi
f0100ca9:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100cac:	7f 33                	jg     f0100ce1 <debuginfo_eip+0x1dd>
	       && stabs[lline].n_type != N_SOL
f0100cae:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100cb2:	80 f9 84             	cmp    $0x84,%cl
f0100cb5:	74 0b                	je     f0100cc2 <debuginfo_eip+0x1be>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cb7:	80 f9 64             	cmp    $0x64,%cl
f0100cba:	75 e5                	jne    f0100ca1 <debuginfo_eip+0x19d>
f0100cbc:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100cc0:	74 df                	je     f0100ca1 <debuginfo_eip+0x19d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cc2:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100cc5:	8b 86 b0 21 10 f0    	mov    -0xfefde50(%esi),%eax
f0100ccb:	ba 71 74 10 f0       	mov    $0xf0107471,%edx
f0100cd0:	81 ea 59 5b 10 f0    	sub    $0xf0105b59,%edx
f0100cd6:	39 d0                	cmp    %edx,%eax
f0100cd8:	73 07                	jae    f0100ce1 <debuginfo_eip+0x1dd>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100cda:	05 59 5b 10 f0       	add    $0xf0105b59,%eax
f0100cdf:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100ce1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ce4:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ce7:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cec:	39 ca                	cmp    %ecx,%edx
f0100cee:	7d 4c                	jge    f0100d3c <debuginfo_eip+0x238>
		for (lline = lfun + 1;
f0100cf0:	8d 42 01             	lea    0x1(%edx),%eax
f0100cf3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100cf6:	89 c2                	mov    %eax,%edx
f0100cf8:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100cfb:	05 b0 21 10 f0       	add    $0xf01021b0,%eax
f0100d00:	89 ce                	mov    %ecx,%esi
f0100d02:	eb 04                	jmp    f0100d08 <debuginfo_eip+0x204>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100d04:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d08:	39 d6                	cmp    %edx,%esi
f0100d0a:	7e 2b                	jle    f0100d37 <debuginfo_eip+0x233>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d0c:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100d10:	83 c2 01             	add    $0x1,%edx
f0100d13:	83 c0 0c             	add    $0xc,%eax
f0100d16:	80 f9 a0             	cmp    $0xa0,%cl
f0100d19:	74 e9                	je     f0100d04 <debuginfo_eip+0x200>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d1b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d20:	eb 1a                	jmp    f0100d3c <debuginfo_eip+0x238>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100d22:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d27:	eb 13                	jmp    f0100d3c <debuginfo_eip+0x238>
f0100d29:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d2e:	eb 0c                	jmp    f0100d3c <debuginfo_eip+0x238>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100d30:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d35:	eb 05                	jmp    f0100d3c <debuginfo_eip+0x238>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d37:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d3c:	83 c4 3c             	add    $0x3c,%esp
f0100d3f:	5b                   	pop    %ebx
f0100d40:	5e                   	pop    %esi
f0100d41:	5f                   	pop    %edi
f0100d42:	5d                   	pop    %ebp
f0100d43:	c3                   	ret    
f0100d44:	66 90                	xchg   %ax,%ax
f0100d46:	66 90                	xchg   %ax,%ax
f0100d48:	66 90                	xchg   %ax,%ax
f0100d4a:	66 90                	xchg   %ax,%ax
f0100d4c:	66 90                	xchg   %ax,%ax
f0100d4e:	66 90                	xchg   %ax,%ax

f0100d50 <printnum>:
  *使用指定的putch函数和相关的指针putdat。
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d50:	55                   	push   %ebp
f0100d51:	89 e5                	mov    %esp,%ebp
f0100d53:	57                   	push   %edi
f0100d54:	56                   	push   %esi
f0100d55:	53                   	push   %ebx
f0100d56:	83 ec 3c             	sub    $0x3c,%esp
f0100d59:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d5c:	89 d7                	mov    %edx,%edi
f0100d5e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d61:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d64:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d67:	89 c3                	mov    %eax,%ebx
f0100d69:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100d6c:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d6f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	//首先递归打印所有前面的（更重要的）数字
	if (num >= base) {
f0100d72:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d77:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d7a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d7d:	39 d9                	cmp    %ebx,%ecx
f0100d7f:	72 05                	jb     f0100d86 <printnum+0x36>
f0100d81:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100d84:	77 69                	ja     f0100def <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d86:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100d89:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100d8d:	83 ee 01             	sub    $0x1,%esi
f0100d90:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d94:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d98:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100d9c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100da0:	89 c3                	mov    %eax,%ebx
f0100da2:	89 d6                	mov    %edx,%esi
f0100da4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100da7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100daa:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100dae:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100db2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100db5:	89 04 24             	mov    %eax,(%esp)
f0100db8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100dbb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dbf:	e8 bc 09 00 00       	call   f0101780 <__udivdi3>
f0100dc4:	89 d9                	mov    %ebx,%ecx
f0100dc6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100dca:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100dce:	89 04 24             	mov    %eax,(%esp)
f0100dd1:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100dd5:	89 fa                	mov    %edi,%edx
f0100dd7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dda:	e8 71 ff ff ff       	call   f0100d50 <printnum>
f0100ddf:	eb 1b                	jmp    f0100dfc <printnum+0xac>
	} else {
		//在第一个数字之前打印任何所需的填充字符
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100de1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100de5:	8b 45 18             	mov    0x18(%ebp),%eax
f0100de8:	89 04 24             	mov    %eax,(%esp)
f0100deb:	ff d3                	call   *%ebx
f0100ded:	eb 03                	jmp    f0100df2 <printnum+0xa2>
f0100def:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		//在第一个数字之前打印任何所需的填充字符
		// print any needed pad characters before first digit
		while (--width > 0)
f0100df2:	83 ee 01             	sub    $0x1,%esi
f0100df5:	85 f6                	test   %esi,%esi
f0100df7:	7f e8                	jg     f0100de1 <printnum+0x91>
f0100df9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100dfc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e00:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100e04:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100e07:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e0a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e0e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100e12:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e15:	89 04 24             	mov    %eax,(%esp)
f0100e18:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e1b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e1f:	e8 8c 0a 00 00       	call   f01018b0 <__umoddi3>
f0100e24:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e28:	0f be 80 89 1f 10 f0 	movsbl -0xfefe077(%eax),%eax
f0100e2f:	89 04 24             	mov    %eax,(%esp)
f0100e32:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e35:	ff d0                	call   *%eax
//首先递归打印所有前面的（更重要的）数字
//在第一个数字之前打印任何所需的填充字符
//然后打印这个（最不重要的）数字
}
f0100e37:	83 c4 3c             	add    $0x3c,%esp
f0100e3a:	5b                   	pop    %ebx
f0100e3b:	5e                   	pop    %esi
f0100e3c:	5f                   	pop    %edi
f0100e3d:	5d                   	pop    %ebp
f0100e3e:	c3                   	ret    

f0100e3f <getuint>:
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
//从varargs列表中获取各种可能大小的unsigned int，具体取决于lflag参数。
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e3f:	55                   	push   %ebp
f0100e40:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e42:	83 fa 01             	cmp    $0x1,%edx
f0100e45:	7e 0e                	jle    f0100e55 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e47:	8b 10                	mov    (%eax),%edx
f0100e49:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e4c:	89 08                	mov    %ecx,(%eax)
f0100e4e:	8b 02                	mov    (%edx),%eax
f0100e50:	8b 52 04             	mov    0x4(%edx),%edx
f0100e53:	eb 22                	jmp    f0100e77 <getuint+0x38>
	else if (lflag)
f0100e55:	85 d2                	test   %edx,%edx
f0100e57:	74 10                	je     f0100e69 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e59:	8b 10                	mov    (%eax),%edx
f0100e5b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e5e:	89 08                	mov    %ecx,(%eax)
f0100e60:	8b 02                	mov    (%edx),%eax
f0100e62:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e67:	eb 0e                	jmp    f0100e77 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e69:	8b 10                	mov    (%eax),%edx
f0100e6b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e6e:	89 08                	mov    %ecx,(%eax)
f0100e70:	8b 02                	mov    (%edx),%eax
f0100e72:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e77:	5d                   	pop    %ebp
f0100e78:	c3                   	ret    

f0100e79 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e79:	55                   	push   %ebp
f0100e7a:	89 e5                	mov    %esp,%ebp
f0100e7c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e7f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e83:	8b 10                	mov    (%eax),%edx
f0100e85:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e88:	73 0a                	jae    f0100e94 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e8a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e8d:	89 08                	mov    %ecx,(%eax)
f0100e8f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e92:	88 02                	mov    %al,(%edx)
}
f0100e94:	5d                   	pop    %ebp
f0100e95:	c3                   	ret    

f0100e96 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e96:	55                   	push   %ebp
f0100e97:	89 e5                	mov    %esp,%ebp
f0100e99:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e9c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e9f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ea3:	8b 45 10             	mov    0x10(%ebp),%eax
f0100ea6:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100eaa:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ead:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100eb1:	8b 45 08             	mov    0x8(%ebp),%eax
f0100eb4:	89 04 24             	mov    %eax,(%esp)
f0100eb7:	e8 02 00 00 00       	call   f0100ebe <vprintfmt>
	va_end(ap);
}
f0100ebc:	c9                   	leave  
f0100ebd:	c3                   	ret    

f0100ebe <vprintfmt>:
// Main function to format and print a string.
//格式化和打印字符串的主要功能。
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100ebe:	55                   	push   %ebp
f0100ebf:	89 e5                	mov    %esp,%ebp
f0100ec1:	57                   	push   %edi
f0100ec2:	56                   	push   %esi
f0100ec3:	53                   	push   %ebx
f0100ec4:	83 ec 3c             	sub    $0x3c,%esp
f0100ec7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100eca:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100ecd:	eb 14                	jmp    f0100ee3 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100ecf:	85 c0                	test   %eax,%eax
f0100ed1:	0f 84 b3 03 00 00    	je     f010128a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0100ed7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100edb:	89 04 24             	mov    %eax,(%esp)
f0100ede:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ee1:	89 f3                	mov    %esi,%ebx
f0100ee3:	8d 73 01             	lea    0x1(%ebx),%esi
f0100ee6:	0f b6 03             	movzbl (%ebx),%eax
f0100ee9:	83 f8 25             	cmp    $0x25,%eax
f0100eec:	75 e1                	jne    f0100ecf <vprintfmt+0x11>
f0100eee:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100ef2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0100ef9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100f00:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100f07:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f0c:	eb 1d                	jmp    f0100f2b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f0e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100f10:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100f14:	eb 15                	jmp    f0100f2b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f16:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f18:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100f1c:	eb 0d                	jmp    f0100f2b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100f1e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f21:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100f24:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f2b:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100f2e:	0f b6 0e             	movzbl (%esi),%ecx
f0100f31:	0f b6 c1             	movzbl %cl,%eax
f0100f34:	83 e9 23             	sub    $0x23,%ecx
f0100f37:	80 f9 55             	cmp    $0x55,%cl
f0100f3a:	0f 87 2a 03 00 00    	ja     f010126a <vprintfmt+0x3ac>
f0100f40:	0f b6 c9             	movzbl %cl,%ecx
f0100f43:	ff 24 8d 20 20 10 f0 	jmp    *-0xfefdfe0(,%ecx,4)
f0100f4a:	89 de                	mov    %ebx,%esi
f0100f4c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f51:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100f54:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100f58:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100f5b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100f5e:	83 fb 09             	cmp    $0x9,%ebx
f0100f61:	77 36                	ja     f0100f99 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f63:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100f66:	eb e9                	jmp    f0100f51 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f68:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f6b:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f6e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f71:	8b 00                	mov    (%eax),%eax
f0100f73:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f76:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f78:	eb 22                	jmp    f0100f9c <vprintfmt+0xde>
f0100f7a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100f7d:	85 c9                	test   %ecx,%ecx
f0100f7f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f84:	0f 49 c1             	cmovns %ecx,%eax
f0100f87:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f8a:	89 de                	mov    %ebx,%esi
f0100f8c:	eb 9d                	jmp    f0100f2b <vprintfmt+0x6d>
f0100f8e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f90:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0100f97:	eb 92                	jmp    f0100f2b <vprintfmt+0x6d>
f0100f99:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f0100f9c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100fa0:	79 89                	jns    f0100f2b <vprintfmt+0x6d>
f0100fa2:	e9 77 ff ff ff       	jmp    f0100f1e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100fa7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100faa:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100fac:	e9 7a ff ff ff       	jmp    f0100f2b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap,int),putdat);
f0100fb1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fb4:	8d 50 04             	lea    0x4(%eax),%edx
f0100fb7:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fba:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fbe:	8b 00                	mov    (%eax),%eax
f0100fc0:	89 04 24             	mov    %eax,(%esp)
f0100fc3:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100fc6:	e9 18 ff ff ff       	jmp    f0100ee3 <vprintfmt+0x25>
		// error message
		case 'e':
			err = va_arg(ap, int);
f0100fcb:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fce:	8d 50 04             	lea    0x4(%eax),%edx
f0100fd1:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fd4:	8b 00                	mov    (%eax),%eax
f0100fd6:	99                   	cltd   
f0100fd7:	31 d0                	xor    %edx,%eax
f0100fd9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fdb:	83 f8 07             	cmp    $0x7,%eax
f0100fde:	7f 0b                	jg     f0100feb <vprintfmt+0x12d>
f0100fe0:	8b 14 85 80 21 10 f0 	mov    -0xfefde80(,%eax,4),%edx
f0100fe7:	85 d2                	test   %edx,%edx
f0100fe9:	75 20                	jne    f010100b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f0100feb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fef:	c7 44 24 08 a1 1f 10 	movl   $0xf0101fa1,0x8(%esp)
f0100ff6:	f0 
f0100ff7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ffb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ffe:	89 04 24             	mov    %eax,(%esp)
f0101001:	e8 90 fe ff ff       	call   f0100e96 <printfmt>
f0101006:	e9 d8 fe ff ff       	jmp    f0100ee3 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010100b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010100f:	c7 44 24 08 aa 1f 10 	movl   $0xf0101faa,0x8(%esp)
f0101016:	f0 
f0101017:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010101b:	8b 45 08             	mov    0x8(%ebp),%eax
f010101e:	89 04 24             	mov    %eax,(%esp)
f0101021:	e8 70 fe ff ff       	call   f0100e96 <printfmt>
f0101026:	e9 b8 fe ff ff       	jmp    f0100ee3 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010102b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010102e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101031:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101034:	8b 45 14             	mov    0x14(%ebp),%eax
f0101037:	8d 50 04             	lea    0x4(%eax),%edx
f010103a:	89 55 14             	mov    %edx,0x14(%ebp)
f010103d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010103f:	85 f6                	test   %esi,%esi
f0101041:	b8 9a 1f 10 f0       	mov    $0xf0101f9a,%eax
f0101046:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0101049:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010104d:	0f 84 97 00 00 00    	je     f01010ea <vprintfmt+0x22c>
f0101053:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101057:	0f 8e 9b 00 00 00    	jle    f01010f8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010105d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101061:	89 34 24             	mov    %esi,(%esp)
f0101064:	e8 9f 03 00 00       	call   f0101408 <strnlen>
f0101069:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010106c:	29 c2                	sub    %eax,%edx
f010106e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0101071:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0101075:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101078:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010107b:	8b 75 08             	mov    0x8(%ebp),%esi
f010107e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101081:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101083:	eb 0f                	jmp    f0101094 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0101085:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101089:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010108c:	89 04 24             	mov    %eax,(%esp)
f010108f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101091:	83 eb 01             	sub    $0x1,%ebx
f0101094:	85 db                	test   %ebx,%ebx
f0101096:	7f ed                	jg     f0101085 <vprintfmt+0x1c7>
f0101098:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010109b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010109e:	85 d2                	test   %edx,%edx
f01010a0:	b8 00 00 00 00       	mov    $0x0,%eax
f01010a5:	0f 49 c2             	cmovns %edx,%eax
f01010a8:	29 c2                	sub    %eax,%edx
f01010aa:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010ad:	89 d7                	mov    %edx,%edi
f01010af:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01010b2:	eb 50                	jmp    f0101104 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010b4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01010b8:	74 1e                	je     f01010d8 <vprintfmt+0x21a>
f01010ba:	0f be d2             	movsbl %dl,%edx
f01010bd:	83 ea 20             	sub    $0x20,%edx
f01010c0:	83 fa 5e             	cmp    $0x5e,%edx
f01010c3:	76 13                	jbe    f01010d8 <vprintfmt+0x21a>
					putch('?', putdat);
f01010c5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010cc:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01010d3:	ff 55 08             	call   *0x8(%ebp)
f01010d6:	eb 0d                	jmp    f01010e5 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f01010d8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01010db:	89 54 24 04          	mov    %edx,0x4(%esp)
f01010df:	89 04 24             	mov    %eax,(%esp)
f01010e2:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010e5:	83 ef 01             	sub    $0x1,%edi
f01010e8:	eb 1a                	jmp    f0101104 <vprintfmt+0x246>
f01010ea:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010ed:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01010f0:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010f3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01010f6:	eb 0c                	jmp    f0101104 <vprintfmt+0x246>
f01010f8:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010fb:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01010fe:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101101:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101104:	83 c6 01             	add    $0x1,%esi
f0101107:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010110b:	0f be c2             	movsbl %dl,%eax
f010110e:	85 c0                	test   %eax,%eax
f0101110:	74 27                	je     f0101139 <vprintfmt+0x27b>
f0101112:	85 db                	test   %ebx,%ebx
f0101114:	78 9e                	js     f01010b4 <vprintfmt+0x1f6>
f0101116:	83 eb 01             	sub    $0x1,%ebx
f0101119:	79 99                	jns    f01010b4 <vprintfmt+0x1f6>
f010111b:	89 f8                	mov    %edi,%eax
f010111d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101120:	8b 75 08             	mov    0x8(%ebp),%esi
f0101123:	89 c3                	mov    %eax,%ebx
f0101125:	eb 1a                	jmp    f0101141 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101127:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010112b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101132:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101134:	83 eb 01             	sub    $0x1,%ebx
f0101137:	eb 08                	jmp    f0101141 <vprintfmt+0x283>
f0101139:	89 fb                	mov    %edi,%ebx
f010113b:	8b 75 08             	mov    0x8(%ebp),%esi
f010113e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101141:	85 db                	test   %ebx,%ebx
f0101143:	7f e2                	jg     f0101127 <vprintfmt+0x269>
f0101145:	89 75 08             	mov    %esi,0x8(%ebp)
f0101148:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010114b:	e9 93 fd ff ff       	jmp    f0100ee3 <vprintfmt+0x25>
// because of sign extension
//与getuint相同但已签名 - 由于符号扩展而无法使用getuint
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101150:	83 fa 01             	cmp    $0x1,%edx
f0101153:	7e 16                	jle    f010116b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0101155:	8b 45 14             	mov    0x14(%ebp),%eax
f0101158:	8d 50 08             	lea    0x8(%eax),%edx
f010115b:	89 55 14             	mov    %edx,0x14(%ebp)
f010115e:	8b 50 04             	mov    0x4(%eax),%edx
f0101161:	8b 00                	mov    (%eax),%eax
f0101163:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101166:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101169:	eb 32                	jmp    f010119d <vprintfmt+0x2df>
	else if (lflag)
f010116b:	85 d2                	test   %edx,%edx
f010116d:	74 18                	je     f0101187 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010116f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101172:	8d 50 04             	lea    0x4(%eax),%edx
f0101175:	89 55 14             	mov    %edx,0x14(%ebp)
f0101178:	8b 30                	mov    (%eax),%esi
f010117a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010117d:	89 f0                	mov    %esi,%eax
f010117f:	c1 f8 1f             	sar    $0x1f,%eax
f0101182:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101185:	eb 16                	jmp    f010119d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0101187:	8b 45 14             	mov    0x14(%ebp),%eax
f010118a:	8d 50 04             	lea    0x4(%eax),%edx
f010118d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101190:	8b 30                	mov    (%eax),%esi
f0101192:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0101195:	89 f0                	mov    %esi,%eax
f0101197:	c1 f8 1f             	sar    $0x1f,%eax
f010119a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010119d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01011a0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01011a3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01011a8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01011ac:	0f 89 80 00 00 00    	jns    f0101232 <vprintfmt+0x374>
				putch('-', putdat);
f01011b2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011b6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01011bd:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01011c0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01011c3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01011c6:	f7 d8                	neg    %eax
f01011c8:	83 d2 00             	adc    $0x0,%edx
f01011cb:	f7 da                	neg    %edx
			}
			base = 10;
f01011cd:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01011d2:	eb 5e                	jmp    f0101232 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01011d4:	8d 45 14             	lea    0x14(%ebp),%eax
f01011d7:	e8 63 fc ff ff       	call   f0100e3f <getuint>
			base = 10;
f01011dc:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01011e1:	eb 4f                	jmp    f0101232 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01011e3:	8d 45 14             	lea    0x14(%ebp),%eax
f01011e6:	e8 54 fc ff ff       	call   f0100e3f <getuint>
			base = 8;
f01011eb:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01011f0:	eb 40                	jmp    f0101232 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f01011f2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011f6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01011fd:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101200:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101204:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010120b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010120e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101211:	8d 50 04             	lea    0x4(%eax),%edx
f0101214:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101217:	8b 00                	mov    (%eax),%eax
f0101219:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010121e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101223:	eb 0d                	jmp    f0101232 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101225:	8d 45 14             	lea    0x14(%ebp),%eax
f0101228:	e8 12 fc ff ff       	call   f0100e3f <getuint>
			base = 16;
f010122d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101232:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0101236:	89 74 24 10          	mov    %esi,0x10(%esp)
f010123a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010123d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101241:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101245:	89 04 24             	mov    %eax,(%esp)
f0101248:	89 54 24 04          	mov    %edx,0x4(%esp)
f010124c:	89 fa                	mov    %edi,%edx
f010124e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101251:	e8 fa fa ff ff       	call   f0100d50 <printnum>
			break;
f0101256:	e9 88 fc ff ff       	jmp    f0100ee3 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010125b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010125f:	89 04 24             	mov    %eax,(%esp)
f0101262:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101265:	e9 79 fc ff ff       	jmp    f0100ee3 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010126a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010126e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101275:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101278:	89 f3                	mov    %esi,%ebx
f010127a:	eb 03                	jmp    f010127f <vprintfmt+0x3c1>
f010127c:	83 eb 01             	sub    $0x1,%ebx
f010127f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0101283:	75 f7                	jne    f010127c <vprintfmt+0x3be>
f0101285:	e9 59 fc ff ff       	jmp    f0100ee3 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010128a:	83 c4 3c             	add    $0x3c,%esp
f010128d:	5b                   	pop    %ebx
f010128e:	5e                   	pop    %esi
f010128f:	5f                   	pop    %edi
f0101290:	5d                   	pop    %ebp
f0101291:	c3                   	ret    

f0101292 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101292:	55                   	push   %ebp
f0101293:	89 e5                	mov    %esp,%ebp
f0101295:	83 ec 28             	sub    $0x28,%esp
f0101298:	8b 45 08             	mov    0x8(%ebp),%eax
f010129b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010129e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01012a1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01012a5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01012a8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01012af:	85 c0                	test   %eax,%eax
f01012b1:	74 30                	je     f01012e3 <vsnprintf+0x51>
f01012b3:	85 d2                	test   %edx,%edx
f01012b5:	7e 2c                	jle    f01012e3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01012b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01012ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012be:	8b 45 10             	mov    0x10(%ebp),%eax
f01012c1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012c5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01012c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012cc:	c7 04 24 79 0e 10 f0 	movl   $0xf0100e79,(%esp)
f01012d3:	e8 e6 fb ff ff       	call   f0100ebe <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01012d8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012db:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01012de:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012e1:	eb 05                	jmp    f01012e8 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01012e3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01012e8:	c9                   	leave  
f01012e9:	c3                   	ret    

f01012ea <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01012ea:	55                   	push   %ebp
f01012eb:	89 e5                	mov    %esp,%ebp
f01012ed:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01012f0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01012f3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012f7:	8b 45 10             	mov    0x10(%ebp),%eax
f01012fa:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012fe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101301:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101305:	8b 45 08             	mov    0x8(%ebp),%eax
f0101308:	89 04 24             	mov    %eax,(%esp)
f010130b:	e8 82 ff ff ff       	call   f0101292 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101310:	c9                   	leave  
f0101311:	c3                   	ret    
f0101312:	66 90                	xchg   %ax,%ax
f0101314:	66 90                	xchg   %ax,%ax
f0101316:	66 90                	xchg   %ax,%ax
f0101318:	66 90                	xchg   %ax,%ax
f010131a:	66 90                	xchg   %ax,%ax
f010131c:	66 90                	xchg   %ax,%ax
f010131e:	66 90                	xchg   %ax,%ax

f0101320 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101320:	55                   	push   %ebp
f0101321:	89 e5                	mov    %esp,%ebp
f0101323:	57                   	push   %edi
f0101324:	56                   	push   %esi
f0101325:	53                   	push   %ebx
f0101326:	83 ec 1c             	sub    $0x1c,%esp
f0101329:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010132c:	85 c0                	test   %eax,%eax
f010132e:	74 10                	je     f0101340 <readline+0x20>
		cprintf("%s", prompt);
f0101330:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101334:	c7 04 24 aa 1f 10 f0 	movl   $0xf0101faa,(%esp)
f010133b:	e8 cd f6 ff ff       	call   f0100a0d <cprintf>

	i = 0;
	echoing = iscons(0);
f0101340:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101347:	e8 51 f3 ff ff       	call   f010069d <iscons>
f010134c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010134e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101353:	e8 34 f3 ff ff       	call   f010068c <getchar>
f0101358:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010135a:	85 c0                	test   %eax,%eax
f010135c:	79 17                	jns    f0101375 <readline+0x55>
			cprintf("read error: %e\n", c);
f010135e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101362:	c7 04 24 a0 21 10 f0 	movl   $0xf01021a0,(%esp)
f0101369:	e8 9f f6 ff ff       	call   f0100a0d <cprintf>
			return NULL;
f010136e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101373:	eb 6d                	jmp    f01013e2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101375:	83 f8 7f             	cmp    $0x7f,%eax
f0101378:	74 05                	je     f010137f <readline+0x5f>
f010137a:	83 f8 08             	cmp    $0x8,%eax
f010137d:	75 19                	jne    f0101398 <readline+0x78>
f010137f:	85 f6                	test   %esi,%esi
f0101381:	7e 15                	jle    f0101398 <readline+0x78>
			if (echoing)
f0101383:	85 ff                	test   %edi,%edi
f0101385:	74 0c                	je     f0101393 <readline+0x73>
				cputchar('\b');
f0101387:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010138e:	e8 e9 f2 ff ff       	call   f010067c <cputchar>
			i--;
f0101393:	83 ee 01             	sub    $0x1,%esi
f0101396:	eb bb                	jmp    f0101353 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101398:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010139e:	7f 1c                	jg     f01013bc <readline+0x9c>
f01013a0:	83 fb 1f             	cmp    $0x1f,%ebx
f01013a3:	7e 17                	jle    f01013bc <readline+0x9c>
			if (echoing)
f01013a5:	85 ff                	test   %edi,%edi
f01013a7:	74 08                	je     f01013b1 <readline+0x91>
				cputchar(c);
f01013a9:	89 1c 24             	mov    %ebx,(%esp)
f01013ac:	e8 cb f2 ff ff       	call   f010067c <cputchar>
			buf[i++] = c;
f01013b1:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01013b7:	8d 76 01             	lea    0x1(%esi),%esi
f01013ba:	eb 97                	jmp    f0101353 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01013bc:	83 fb 0d             	cmp    $0xd,%ebx
f01013bf:	74 05                	je     f01013c6 <readline+0xa6>
f01013c1:	83 fb 0a             	cmp    $0xa,%ebx
f01013c4:	75 8d                	jne    f0101353 <readline+0x33>
			if (echoing)
f01013c6:	85 ff                	test   %edi,%edi
f01013c8:	74 0c                	je     f01013d6 <readline+0xb6>
				cputchar('\n');
f01013ca:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01013d1:	e8 a6 f2 ff ff       	call   f010067c <cputchar>
			buf[i] = 0;
f01013d6:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01013dd:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01013e2:	83 c4 1c             	add    $0x1c,%esp
f01013e5:	5b                   	pop    %ebx
f01013e6:	5e                   	pop    %esi
f01013e7:	5f                   	pop    %edi
f01013e8:	5d                   	pop    %ebp
f01013e9:	c3                   	ret    
f01013ea:	66 90                	xchg   %ax,%ax
f01013ec:	66 90                	xchg   %ax,%ax
f01013ee:	66 90                	xchg   %ax,%ax

f01013f0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013f0:	55                   	push   %ebp
f01013f1:	89 e5                	mov    %esp,%ebp
f01013f3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01013fb:	eb 03                	jmp    f0101400 <strlen+0x10>
		n++;
f01013fd:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101400:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101404:	75 f7                	jne    f01013fd <strlen+0xd>
		n++;
	return n;
}
f0101406:	5d                   	pop    %ebp
f0101407:	c3                   	ret    

f0101408 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101408:	55                   	push   %ebp
f0101409:	89 e5                	mov    %esp,%ebp
f010140b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010140e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101411:	b8 00 00 00 00       	mov    $0x0,%eax
f0101416:	eb 03                	jmp    f010141b <strnlen+0x13>
		n++;
f0101418:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010141b:	39 d0                	cmp    %edx,%eax
f010141d:	74 06                	je     f0101425 <strnlen+0x1d>
f010141f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101423:	75 f3                	jne    f0101418 <strnlen+0x10>
		n++;
	return n;
}
f0101425:	5d                   	pop    %ebp
f0101426:	c3                   	ret    

f0101427 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101427:	55                   	push   %ebp
f0101428:	89 e5                	mov    %esp,%ebp
f010142a:	53                   	push   %ebx
f010142b:	8b 45 08             	mov    0x8(%ebp),%eax
f010142e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101431:	89 c2                	mov    %eax,%edx
f0101433:	83 c2 01             	add    $0x1,%edx
f0101436:	83 c1 01             	add    $0x1,%ecx
f0101439:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010143d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101440:	84 db                	test   %bl,%bl
f0101442:	75 ef                	jne    f0101433 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101444:	5b                   	pop    %ebx
f0101445:	5d                   	pop    %ebp
f0101446:	c3                   	ret    

f0101447 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101447:	55                   	push   %ebp
f0101448:	89 e5                	mov    %esp,%ebp
f010144a:	53                   	push   %ebx
f010144b:	83 ec 08             	sub    $0x8,%esp
f010144e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101451:	89 1c 24             	mov    %ebx,(%esp)
f0101454:	e8 97 ff ff ff       	call   f01013f0 <strlen>
	strcpy(dst + len, src);
f0101459:	8b 55 0c             	mov    0xc(%ebp),%edx
f010145c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101460:	01 d8                	add    %ebx,%eax
f0101462:	89 04 24             	mov    %eax,(%esp)
f0101465:	e8 bd ff ff ff       	call   f0101427 <strcpy>
	return dst;
}
f010146a:	89 d8                	mov    %ebx,%eax
f010146c:	83 c4 08             	add    $0x8,%esp
f010146f:	5b                   	pop    %ebx
f0101470:	5d                   	pop    %ebp
f0101471:	c3                   	ret    

f0101472 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101472:	55                   	push   %ebp
f0101473:	89 e5                	mov    %esp,%ebp
f0101475:	56                   	push   %esi
f0101476:	53                   	push   %ebx
f0101477:	8b 75 08             	mov    0x8(%ebp),%esi
f010147a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010147d:	89 f3                	mov    %esi,%ebx
f010147f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101482:	89 f2                	mov    %esi,%edx
f0101484:	eb 0f                	jmp    f0101495 <strncpy+0x23>
		*dst++ = *src;
f0101486:	83 c2 01             	add    $0x1,%edx
f0101489:	0f b6 01             	movzbl (%ecx),%eax
f010148c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010148f:	80 39 01             	cmpb   $0x1,(%ecx)
f0101492:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101495:	39 da                	cmp    %ebx,%edx
f0101497:	75 ed                	jne    f0101486 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101499:	89 f0                	mov    %esi,%eax
f010149b:	5b                   	pop    %ebx
f010149c:	5e                   	pop    %esi
f010149d:	5d                   	pop    %ebp
f010149e:	c3                   	ret    

f010149f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010149f:	55                   	push   %ebp
f01014a0:	89 e5                	mov    %esp,%ebp
f01014a2:	56                   	push   %esi
f01014a3:	53                   	push   %ebx
f01014a4:	8b 75 08             	mov    0x8(%ebp),%esi
f01014a7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014aa:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01014ad:	89 f0                	mov    %esi,%eax
f01014af:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01014b3:	85 c9                	test   %ecx,%ecx
f01014b5:	75 0b                	jne    f01014c2 <strlcpy+0x23>
f01014b7:	eb 1d                	jmp    f01014d6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01014b9:	83 c0 01             	add    $0x1,%eax
f01014bc:	83 c2 01             	add    $0x1,%edx
f01014bf:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01014c2:	39 d8                	cmp    %ebx,%eax
f01014c4:	74 0b                	je     f01014d1 <strlcpy+0x32>
f01014c6:	0f b6 0a             	movzbl (%edx),%ecx
f01014c9:	84 c9                	test   %cl,%cl
f01014cb:	75 ec                	jne    f01014b9 <strlcpy+0x1a>
f01014cd:	89 c2                	mov    %eax,%edx
f01014cf:	eb 02                	jmp    f01014d3 <strlcpy+0x34>
f01014d1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01014d3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01014d6:	29 f0                	sub    %esi,%eax
}
f01014d8:	5b                   	pop    %ebx
f01014d9:	5e                   	pop    %esi
f01014da:	5d                   	pop    %ebp
f01014db:	c3                   	ret    

f01014dc <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01014dc:	55                   	push   %ebp
f01014dd:	89 e5                	mov    %esp,%ebp
f01014df:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014e2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01014e5:	eb 06                	jmp    f01014ed <strcmp+0x11>
		p++, q++;
f01014e7:	83 c1 01             	add    $0x1,%ecx
f01014ea:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01014ed:	0f b6 01             	movzbl (%ecx),%eax
f01014f0:	84 c0                	test   %al,%al
f01014f2:	74 04                	je     f01014f8 <strcmp+0x1c>
f01014f4:	3a 02                	cmp    (%edx),%al
f01014f6:	74 ef                	je     f01014e7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01014f8:	0f b6 c0             	movzbl %al,%eax
f01014fb:	0f b6 12             	movzbl (%edx),%edx
f01014fe:	29 d0                	sub    %edx,%eax
}
f0101500:	5d                   	pop    %ebp
f0101501:	c3                   	ret    

f0101502 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101502:	55                   	push   %ebp
f0101503:	89 e5                	mov    %esp,%ebp
f0101505:	53                   	push   %ebx
f0101506:	8b 45 08             	mov    0x8(%ebp),%eax
f0101509:	8b 55 0c             	mov    0xc(%ebp),%edx
f010150c:	89 c3                	mov    %eax,%ebx
f010150e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101511:	eb 06                	jmp    f0101519 <strncmp+0x17>
		n--, p++, q++;
f0101513:	83 c0 01             	add    $0x1,%eax
f0101516:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101519:	39 d8                	cmp    %ebx,%eax
f010151b:	74 15                	je     f0101532 <strncmp+0x30>
f010151d:	0f b6 08             	movzbl (%eax),%ecx
f0101520:	84 c9                	test   %cl,%cl
f0101522:	74 04                	je     f0101528 <strncmp+0x26>
f0101524:	3a 0a                	cmp    (%edx),%cl
f0101526:	74 eb                	je     f0101513 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101528:	0f b6 00             	movzbl (%eax),%eax
f010152b:	0f b6 12             	movzbl (%edx),%edx
f010152e:	29 d0                	sub    %edx,%eax
f0101530:	eb 05                	jmp    f0101537 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101532:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101537:	5b                   	pop    %ebx
f0101538:	5d                   	pop    %ebp
f0101539:	c3                   	ret    

f010153a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010153a:	55                   	push   %ebp
f010153b:	89 e5                	mov    %esp,%ebp
f010153d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101540:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101544:	eb 07                	jmp    f010154d <strchr+0x13>
		if (*s == c)
f0101546:	38 ca                	cmp    %cl,%dl
f0101548:	74 0f                	je     f0101559 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010154a:	83 c0 01             	add    $0x1,%eax
f010154d:	0f b6 10             	movzbl (%eax),%edx
f0101550:	84 d2                	test   %dl,%dl
f0101552:	75 f2                	jne    f0101546 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101554:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101559:	5d                   	pop    %ebp
f010155a:	c3                   	ret    

f010155b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010155b:	55                   	push   %ebp
f010155c:	89 e5                	mov    %esp,%ebp
f010155e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101561:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101565:	eb 07                	jmp    f010156e <strfind+0x13>
		if (*s == c)
f0101567:	38 ca                	cmp    %cl,%dl
f0101569:	74 0a                	je     f0101575 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010156b:	83 c0 01             	add    $0x1,%eax
f010156e:	0f b6 10             	movzbl (%eax),%edx
f0101571:	84 d2                	test   %dl,%dl
f0101573:	75 f2                	jne    f0101567 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0101575:	5d                   	pop    %ebp
f0101576:	c3                   	ret    

f0101577 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101577:	55                   	push   %ebp
f0101578:	89 e5                	mov    %esp,%ebp
f010157a:	57                   	push   %edi
f010157b:	56                   	push   %esi
f010157c:	53                   	push   %ebx
f010157d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101580:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101583:	85 c9                	test   %ecx,%ecx
f0101585:	74 36                	je     f01015bd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101587:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010158d:	75 28                	jne    f01015b7 <memset+0x40>
f010158f:	f6 c1 03             	test   $0x3,%cl
f0101592:	75 23                	jne    f01015b7 <memset+0x40>
		c &= 0xFF;
f0101594:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101598:	89 d3                	mov    %edx,%ebx
f010159a:	c1 e3 08             	shl    $0x8,%ebx
f010159d:	89 d6                	mov    %edx,%esi
f010159f:	c1 e6 18             	shl    $0x18,%esi
f01015a2:	89 d0                	mov    %edx,%eax
f01015a4:	c1 e0 10             	shl    $0x10,%eax
f01015a7:	09 f0                	or     %esi,%eax
f01015a9:	09 c2                	or     %eax,%edx
f01015ab:	89 d0                	mov    %edx,%eax
f01015ad:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01015af:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01015b2:	fc                   	cld    
f01015b3:	f3 ab                	rep stos %eax,%es:(%edi)
f01015b5:	eb 06                	jmp    f01015bd <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01015b7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015ba:	fc                   	cld    
f01015bb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01015bd:	89 f8                	mov    %edi,%eax
f01015bf:	5b                   	pop    %ebx
f01015c0:	5e                   	pop    %esi
f01015c1:	5f                   	pop    %edi
f01015c2:	5d                   	pop    %ebp
f01015c3:	c3                   	ret    

f01015c4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01015c4:	55                   	push   %ebp
f01015c5:	89 e5                	mov    %esp,%ebp
f01015c7:	57                   	push   %edi
f01015c8:	56                   	push   %esi
f01015c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01015cc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015cf:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01015d2:	39 c6                	cmp    %eax,%esi
f01015d4:	73 35                	jae    f010160b <memmove+0x47>
f01015d6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01015d9:	39 d0                	cmp    %edx,%eax
f01015db:	73 2e                	jae    f010160b <memmove+0x47>
		s += n;
		d += n;
f01015dd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01015e0:	89 d6                	mov    %edx,%esi
f01015e2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015e4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01015ea:	75 13                	jne    f01015ff <memmove+0x3b>
f01015ec:	f6 c1 03             	test   $0x3,%cl
f01015ef:	75 0e                	jne    f01015ff <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01015f1:	83 ef 04             	sub    $0x4,%edi
f01015f4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01015f7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01015fa:	fd                   	std    
f01015fb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015fd:	eb 09                	jmp    f0101608 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01015ff:	83 ef 01             	sub    $0x1,%edi
f0101602:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101605:	fd                   	std    
f0101606:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101608:	fc                   	cld    
f0101609:	eb 1d                	jmp    f0101628 <memmove+0x64>
f010160b:	89 f2                	mov    %esi,%edx
f010160d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010160f:	f6 c2 03             	test   $0x3,%dl
f0101612:	75 0f                	jne    f0101623 <memmove+0x5f>
f0101614:	f6 c1 03             	test   $0x3,%cl
f0101617:	75 0a                	jne    f0101623 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101619:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010161c:	89 c7                	mov    %eax,%edi
f010161e:	fc                   	cld    
f010161f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101621:	eb 05                	jmp    f0101628 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101623:	89 c7                	mov    %eax,%edi
f0101625:	fc                   	cld    
f0101626:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101628:	5e                   	pop    %esi
f0101629:	5f                   	pop    %edi
f010162a:	5d                   	pop    %ebp
f010162b:	c3                   	ret    

f010162c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010162c:	55                   	push   %ebp
f010162d:	89 e5                	mov    %esp,%ebp
f010162f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101632:	8b 45 10             	mov    0x10(%ebp),%eax
f0101635:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101639:	8b 45 0c             	mov    0xc(%ebp),%eax
f010163c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101640:	8b 45 08             	mov    0x8(%ebp),%eax
f0101643:	89 04 24             	mov    %eax,(%esp)
f0101646:	e8 79 ff ff ff       	call   f01015c4 <memmove>
}
f010164b:	c9                   	leave  
f010164c:	c3                   	ret    

f010164d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010164d:	55                   	push   %ebp
f010164e:	89 e5                	mov    %esp,%ebp
f0101650:	56                   	push   %esi
f0101651:	53                   	push   %ebx
f0101652:	8b 55 08             	mov    0x8(%ebp),%edx
f0101655:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101658:	89 d6                	mov    %edx,%esi
f010165a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010165d:	eb 1a                	jmp    f0101679 <memcmp+0x2c>
		if (*s1 != *s2)
f010165f:	0f b6 02             	movzbl (%edx),%eax
f0101662:	0f b6 19             	movzbl (%ecx),%ebx
f0101665:	38 d8                	cmp    %bl,%al
f0101667:	74 0a                	je     f0101673 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101669:	0f b6 c0             	movzbl %al,%eax
f010166c:	0f b6 db             	movzbl %bl,%ebx
f010166f:	29 d8                	sub    %ebx,%eax
f0101671:	eb 0f                	jmp    f0101682 <memcmp+0x35>
		s1++, s2++;
f0101673:	83 c2 01             	add    $0x1,%edx
f0101676:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101679:	39 f2                	cmp    %esi,%edx
f010167b:	75 e2                	jne    f010165f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010167d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101682:	5b                   	pop    %ebx
f0101683:	5e                   	pop    %esi
f0101684:	5d                   	pop    %ebp
f0101685:	c3                   	ret    

f0101686 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101686:	55                   	push   %ebp
f0101687:	89 e5                	mov    %esp,%ebp
f0101689:	8b 45 08             	mov    0x8(%ebp),%eax
f010168c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010168f:	89 c2                	mov    %eax,%edx
f0101691:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101694:	eb 07                	jmp    f010169d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101696:	38 08                	cmp    %cl,(%eax)
f0101698:	74 07                	je     f01016a1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010169a:	83 c0 01             	add    $0x1,%eax
f010169d:	39 d0                	cmp    %edx,%eax
f010169f:	72 f5                	jb     f0101696 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01016a1:	5d                   	pop    %ebp
f01016a2:	c3                   	ret    

f01016a3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01016a3:	55                   	push   %ebp
f01016a4:	89 e5                	mov    %esp,%ebp
f01016a6:	57                   	push   %edi
f01016a7:	56                   	push   %esi
f01016a8:	53                   	push   %ebx
f01016a9:	8b 55 08             	mov    0x8(%ebp),%edx
f01016ac:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016af:	eb 03                	jmp    f01016b4 <strtol+0x11>
		s++;
f01016b1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016b4:	0f b6 0a             	movzbl (%edx),%ecx
f01016b7:	80 f9 09             	cmp    $0x9,%cl
f01016ba:	74 f5                	je     f01016b1 <strtol+0xe>
f01016bc:	80 f9 20             	cmp    $0x20,%cl
f01016bf:	74 f0                	je     f01016b1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01016c1:	80 f9 2b             	cmp    $0x2b,%cl
f01016c4:	75 0a                	jne    f01016d0 <strtol+0x2d>
		s++;
f01016c6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01016c9:	bf 00 00 00 00       	mov    $0x0,%edi
f01016ce:	eb 11                	jmp    f01016e1 <strtol+0x3e>
f01016d0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01016d5:	80 f9 2d             	cmp    $0x2d,%cl
f01016d8:	75 07                	jne    f01016e1 <strtol+0x3e>
		s++, neg = 1;
f01016da:	8d 52 01             	lea    0x1(%edx),%edx
f01016dd:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016e1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f01016e6:	75 15                	jne    f01016fd <strtol+0x5a>
f01016e8:	80 3a 30             	cmpb   $0x30,(%edx)
f01016eb:	75 10                	jne    f01016fd <strtol+0x5a>
f01016ed:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01016f1:	75 0a                	jne    f01016fd <strtol+0x5a>
		s += 2, base = 16;
f01016f3:	83 c2 02             	add    $0x2,%edx
f01016f6:	b8 10 00 00 00       	mov    $0x10,%eax
f01016fb:	eb 10                	jmp    f010170d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f01016fd:	85 c0                	test   %eax,%eax
f01016ff:	75 0c                	jne    f010170d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101701:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101703:	80 3a 30             	cmpb   $0x30,(%edx)
f0101706:	75 05                	jne    f010170d <strtol+0x6a>
		s++, base = 8;
f0101708:	83 c2 01             	add    $0x1,%edx
f010170b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010170d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101712:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101715:	0f b6 0a             	movzbl (%edx),%ecx
f0101718:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010171b:	89 f0                	mov    %esi,%eax
f010171d:	3c 09                	cmp    $0x9,%al
f010171f:	77 08                	ja     f0101729 <strtol+0x86>
			dig = *s - '0';
f0101721:	0f be c9             	movsbl %cl,%ecx
f0101724:	83 e9 30             	sub    $0x30,%ecx
f0101727:	eb 20                	jmp    f0101749 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0101729:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010172c:	89 f0                	mov    %esi,%eax
f010172e:	3c 19                	cmp    $0x19,%al
f0101730:	77 08                	ja     f010173a <strtol+0x97>
			dig = *s - 'a' + 10;
f0101732:	0f be c9             	movsbl %cl,%ecx
f0101735:	83 e9 57             	sub    $0x57,%ecx
f0101738:	eb 0f                	jmp    f0101749 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010173a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010173d:	89 f0                	mov    %esi,%eax
f010173f:	3c 19                	cmp    $0x19,%al
f0101741:	77 16                	ja     f0101759 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0101743:	0f be c9             	movsbl %cl,%ecx
f0101746:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101749:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010174c:	7d 0f                	jge    f010175d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010174e:	83 c2 01             	add    $0x1,%edx
f0101751:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0101755:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0101757:	eb bc                	jmp    f0101715 <strtol+0x72>
f0101759:	89 d8                	mov    %ebx,%eax
f010175b:	eb 02                	jmp    f010175f <strtol+0xbc>
f010175d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010175f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101763:	74 05                	je     f010176a <strtol+0xc7>
		*endptr = (char *) s;
f0101765:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101768:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010176a:	f7 d8                	neg    %eax
f010176c:	85 ff                	test   %edi,%edi
f010176e:	0f 44 c3             	cmove  %ebx,%eax
}
f0101771:	5b                   	pop    %ebx
f0101772:	5e                   	pop    %esi
f0101773:	5f                   	pop    %edi
f0101774:	5d                   	pop    %ebp
f0101775:	c3                   	ret    
f0101776:	66 90                	xchg   %ax,%ax
f0101778:	66 90                	xchg   %ax,%ax
f010177a:	66 90                	xchg   %ax,%ax
f010177c:	66 90                	xchg   %ax,%ax
f010177e:	66 90                	xchg   %ax,%ax

f0101780 <__udivdi3>:
f0101780:	55                   	push   %ebp
f0101781:	57                   	push   %edi
f0101782:	56                   	push   %esi
f0101783:	83 ec 0c             	sub    $0xc,%esp
f0101786:	8b 44 24 28          	mov    0x28(%esp),%eax
f010178a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010178e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101792:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101796:	85 c0                	test   %eax,%eax
f0101798:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010179c:	89 ea                	mov    %ebp,%edx
f010179e:	89 0c 24             	mov    %ecx,(%esp)
f01017a1:	75 2d                	jne    f01017d0 <__udivdi3+0x50>
f01017a3:	39 e9                	cmp    %ebp,%ecx
f01017a5:	77 61                	ja     f0101808 <__udivdi3+0x88>
f01017a7:	85 c9                	test   %ecx,%ecx
f01017a9:	89 ce                	mov    %ecx,%esi
f01017ab:	75 0b                	jne    f01017b8 <__udivdi3+0x38>
f01017ad:	b8 01 00 00 00       	mov    $0x1,%eax
f01017b2:	31 d2                	xor    %edx,%edx
f01017b4:	f7 f1                	div    %ecx
f01017b6:	89 c6                	mov    %eax,%esi
f01017b8:	31 d2                	xor    %edx,%edx
f01017ba:	89 e8                	mov    %ebp,%eax
f01017bc:	f7 f6                	div    %esi
f01017be:	89 c5                	mov    %eax,%ebp
f01017c0:	89 f8                	mov    %edi,%eax
f01017c2:	f7 f6                	div    %esi
f01017c4:	89 ea                	mov    %ebp,%edx
f01017c6:	83 c4 0c             	add    $0xc,%esp
f01017c9:	5e                   	pop    %esi
f01017ca:	5f                   	pop    %edi
f01017cb:	5d                   	pop    %ebp
f01017cc:	c3                   	ret    
f01017cd:	8d 76 00             	lea    0x0(%esi),%esi
f01017d0:	39 e8                	cmp    %ebp,%eax
f01017d2:	77 24                	ja     f01017f8 <__udivdi3+0x78>
f01017d4:	0f bd e8             	bsr    %eax,%ebp
f01017d7:	83 f5 1f             	xor    $0x1f,%ebp
f01017da:	75 3c                	jne    f0101818 <__udivdi3+0x98>
f01017dc:	8b 74 24 04          	mov    0x4(%esp),%esi
f01017e0:	39 34 24             	cmp    %esi,(%esp)
f01017e3:	0f 86 9f 00 00 00    	jbe    f0101888 <__udivdi3+0x108>
f01017e9:	39 d0                	cmp    %edx,%eax
f01017eb:	0f 82 97 00 00 00    	jb     f0101888 <__udivdi3+0x108>
f01017f1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017f8:	31 d2                	xor    %edx,%edx
f01017fa:	31 c0                	xor    %eax,%eax
f01017fc:	83 c4 0c             	add    $0xc,%esp
f01017ff:	5e                   	pop    %esi
f0101800:	5f                   	pop    %edi
f0101801:	5d                   	pop    %ebp
f0101802:	c3                   	ret    
f0101803:	90                   	nop
f0101804:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101808:	89 f8                	mov    %edi,%eax
f010180a:	f7 f1                	div    %ecx
f010180c:	31 d2                	xor    %edx,%edx
f010180e:	83 c4 0c             	add    $0xc,%esp
f0101811:	5e                   	pop    %esi
f0101812:	5f                   	pop    %edi
f0101813:	5d                   	pop    %ebp
f0101814:	c3                   	ret    
f0101815:	8d 76 00             	lea    0x0(%esi),%esi
f0101818:	89 e9                	mov    %ebp,%ecx
f010181a:	8b 3c 24             	mov    (%esp),%edi
f010181d:	d3 e0                	shl    %cl,%eax
f010181f:	89 c6                	mov    %eax,%esi
f0101821:	b8 20 00 00 00       	mov    $0x20,%eax
f0101826:	29 e8                	sub    %ebp,%eax
f0101828:	89 c1                	mov    %eax,%ecx
f010182a:	d3 ef                	shr    %cl,%edi
f010182c:	89 e9                	mov    %ebp,%ecx
f010182e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101832:	8b 3c 24             	mov    (%esp),%edi
f0101835:	09 74 24 08          	or     %esi,0x8(%esp)
f0101839:	89 d6                	mov    %edx,%esi
f010183b:	d3 e7                	shl    %cl,%edi
f010183d:	89 c1                	mov    %eax,%ecx
f010183f:	89 3c 24             	mov    %edi,(%esp)
f0101842:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101846:	d3 ee                	shr    %cl,%esi
f0101848:	89 e9                	mov    %ebp,%ecx
f010184a:	d3 e2                	shl    %cl,%edx
f010184c:	89 c1                	mov    %eax,%ecx
f010184e:	d3 ef                	shr    %cl,%edi
f0101850:	09 d7                	or     %edx,%edi
f0101852:	89 f2                	mov    %esi,%edx
f0101854:	89 f8                	mov    %edi,%eax
f0101856:	f7 74 24 08          	divl   0x8(%esp)
f010185a:	89 d6                	mov    %edx,%esi
f010185c:	89 c7                	mov    %eax,%edi
f010185e:	f7 24 24             	mull   (%esp)
f0101861:	39 d6                	cmp    %edx,%esi
f0101863:	89 14 24             	mov    %edx,(%esp)
f0101866:	72 30                	jb     f0101898 <__udivdi3+0x118>
f0101868:	8b 54 24 04          	mov    0x4(%esp),%edx
f010186c:	89 e9                	mov    %ebp,%ecx
f010186e:	d3 e2                	shl    %cl,%edx
f0101870:	39 c2                	cmp    %eax,%edx
f0101872:	73 05                	jae    f0101879 <__udivdi3+0xf9>
f0101874:	3b 34 24             	cmp    (%esp),%esi
f0101877:	74 1f                	je     f0101898 <__udivdi3+0x118>
f0101879:	89 f8                	mov    %edi,%eax
f010187b:	31 d2                	xor    %edx,%edx
f010187d:	e9 7a ff ff ff       	jmp    f01017fc <__udivdi3+0x7c>
f0101882:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101888:	31 d2                	xor    %edx,%edx
f010188a:	b8 01 00 00 00       	mov    $0x1,%eax
f010188f:	e9 68 ff ff ff       	jmp    f01017fc <__udivdi3+0x7c>
f0101894:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101898:	8d 47 ff             	lea    -0x1(%edi),%eax
f010189b:	31 d2                	xor    %edx,%edx
f010189d:	83 c4 0c             	add    $0xc,%esp
f01018a0:	5e                   	pop    %esi
f01018a1:	5f                   	pop    %edi
f01018a2:	5d                   	pop    %ebp
f01018a3:	c3                   	ret    
f01018a4:	66 90                	xchg   %ax,%ax
f01018a6:	66 90                	xchg   %ax,%ax
f01018a8:	66 90                	xchg   %ax,%ax
f01018aa:	66 90                	xchg   %ax,%ax
f01018ac:	66 90                	xchg   %ax,%ax
f01018ae:	66 90                	xchg   %ax,%ax

f01018b0 <__umoddi3>:
f01018b0:	55                   	push   %ebp
f01018b1:	57                   	push   %edi
f01018b2:	56                   	push   %esi
f01018b3:	83 ec 14             	sub    $0x14,%esp
f01018b6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01018ba:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01018be:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f01018c2:	89 c7                	mov    %eax,%edi
f01018c4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018c8:	8b 44 24 30          	mov    0x30(%esp),%eax
f01018cc:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01018d0:	89 34 24             	mov    %esi,(%esp)
f01018d3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018d7:	85 c0                	test   %eax,%eax
f01018d9:	89 c2                	mov    %eax,%edx
f01018db:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018df:	75 17                	jne    f01018f8 <__umoddi3+0x48>
f01018e1:	39 fe                	cmp    %edi,%esi
f01018e3:	76 4b                	jbe    f0101930 <__umoddi3+0x80>
f01018e5:	89 c8                	mov    %ecx,%eax
f01018e7:	89 fa                	mov    %edi,%edx
f01018e9:	f7 f6                	div    %esi
f01018eb:	89 d0                	mov    %edx,%eax
f01018ed:	31 d2                	xor    %edx,%edx
f01018ef:	83 c4 14             	add    $0x14,%esp
f01018f2:	5e                   	pop    %esi
f01018f3:	5f                   	pop    %edi
f01018f4:	5d                   	pop    %ebp
f01018f5:	c3                   	ret    
f01018f6:	66 90                	xchg   %ax,%ax
f01018f8:	39 f8                	cmp    %edi,%eax
f01018fa:	77 54                	ja     f0101950 <__umoddi3+0xa0>
f01018fc:	0f bd e8             	bsr    %eax,%ebp
f01018ff:	83 f5 1f             	xor    $0x1f,%ebp
f0101902:	75 5c                	jne    f0101960 <__umoddi3+0xb0>
f0101904:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101908:	39 3c 24             	cmp    %edi,(%esp)
f010190b:	0f 87 e7 00 00 00    	ja     f01019f8 <__umoddi3+0x148>
f0101911:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101915:	29 f1                	sub    %esi,%ecx
f0101917:	19 c7                	sbb    %eax,%edi
f0101919:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010191d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101921:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101925:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101929:	83 c4 14             	add    $0x14,%esp
f010192c:	5e                   	pop    %esi
f010192d:	5f                   	pop    %edi
f010192e:	5d                   	pop    %ebp
f010192f:	c3                   	ret    
f0101930:	85 f6                	test   %esi,%esi
f0101932:	89 f5                	mov    %esi,%ebp
f0101934:	75 0b                	jne    f0101941 <__umoddi3+0x91>
f0101936:	b8 01 00 00 00       	mov    $0x1,%eax
f010193b:	31 d2                	xor    %edx,%edx
f010193d:	f7 f6                	div    %esi
f010193f:	89 c5                	mov    %eax,%ebp
f0101941:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101945:	31 d2                	xor    %edx,%edx
f0101947:	f7 f5                	div    %ebp
f0101949:	89 c8                	mov    %ecx,%eax
f010194b:	f7 f5                	div    %ebp
f010194d:	eb 9c                	jmp    f01018eb <__umoddi3+0x3b>
f010194f:	90                   	nop
f0101950:	89 c8                	mov    %ecx,%eax
f0101952:	89 fa                	mov    %edi,%edx
f0101954:	83 c4 14             	add    $0x14,%esp
f0101957:	5e                   	pop    %esi
f0101958:	5f                   	pop    %edi
f0101959:	5d                   	pop    %ebp
f010195a:	c3                   	ret    
f010195b:	90                   	nop
f010195c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101960:	8b 04 24             	mov    (%esp),%eax
f0101963:	be 20 00 00 00       	mov    $0x20,%esi
f0101968:	89 e9                	mov    %ebp,%ecx
f010196a:	29 ee                	sub    %ebp,%esi
f010196c:	d3 e2                	shl    %cl,%edx
f010196e:	89 f1                	mov    %esi,%ecx
f0101970:	d3 e8                	shr    %cl,%eax
f0101972:	89 e9                	mov    %ebp,%ecx
f0101974:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101978:	8b 04 24             	mov    (%esp),%eax
f010197b:	09 54 24 04          	or     %edx,0x4(%esp)
f010197f:	89 fa                	mov    %edi,%edx
f0101981:	d3 e0                	shl    %cl,%eax
f0101983:	89 f1                	mov    %esi,%ecx
f0101985:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101989:	8b 44 24 10          	mov    0x10(%esp),%eax
f010198d:	d3 ea                	shr    %cl,%edx
f010198f:	89 e9                	mov    %ebp,%ecx
f0101991:	d3 e7                	shl    %cl,%edi
f0101993:	89 f1                	mov    %esi,%ecx
f0101995:	d3 e8                	shr    %cl,%eax
f0101997:	89 e9                	mov    %ebp,%ecx
f0101999:	09 f8                	or     %edi,%eax
f010199b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010199f:	f7 74 24 04          	divl   0x4(%esp)
f01019a3:	d3 e7                	shl    %cl,%edi
f01019a5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01019a9:	89 d7                	mov    %edx,%edi
f01019ab:	f7 64 24 08          	mull   0x8(%esp)
f01019af:	39 d7                	cmp    %edx,%edi
f01019b1:	89 c1                	mov    %eax,%ecx
f01019b3:	89 14 24             	mov    %edx,(%esp)
f01019b6:	72 2c                	jb     f01019e4 <__umoddi3+0x134>
f01019b8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f01019bc:	72 22                	jb     f01019e0 <__umoddi3+0x130>
f01019be:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01019c2:	29 c8                	sub    %ecx,%eax
f01019c4:	19 d7                	sbb    %edx,%edi
f01019c6:	89 e9                	mov    %ebp,%ecx
f01019c8:	89 fa                	mov    %edi,%edx
f01019ca:	d3 e8                	shr    %cl,%eax
f01019cc:	89 f1                	mov    %esi,%ecx
f01019ce:	d3 e2                	shl    %cl,%edx
f01019d0:	89 e9                	mov    %ebp,%ecx
f01019d2:	d3 ef                	shr    %cl,%edi
f01019d4:	09 d0                	or     %edx,%eax
f01019d6:	89 fa                	mov    %edi,%edx
f01019d8:	83 c4 14             	add    $0x14,%esp
f01019db:	5e                   	pop    %esi
f01019dc:	5f                   	pop    %edi
f01019dd:	5d                   	pop    %ebp
f01019de:	c3                   	ret    
f01019df:	90                   	nop
f01019e0:	39 d7                	cmp    %edx,%edi
f01019e2:	75 da                	jne    f01019be <__umoddi3+0x10e>
f01019e4:	8b 14 24             	mov    (%esp),%edx
f01019e7:	89 c1                	mov    %eax,%ecx
f01019e9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f01019ed:	1b 54 24 04          	sbb    0x4(%esp),%edx
f01019f1:	eb cb                	jmp    f01019be <__umoddi3+0x10e>
f01019f3:	90                   	nop
f01019f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019f8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f01019fc:	0f 82 0f ff ff ff    	jb     f0101911 <__umoddi3+0x61>
f0101a02:	e9 1a ff ff ff       	jmp    f0101921 <__umoddi3+0x71>
