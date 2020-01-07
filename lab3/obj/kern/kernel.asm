
obj/kern/kernel:     file format elf32-i386


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
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 a0 11 00       	mov    $0x11a000,%eax
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
f0100034:	bc 00 a0 11 f0       	mov    $0xf011a000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


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
f0100046:	b8 30 ec 17 f0       	mov    $0xf017ec30,%eax
f010004b:	2d 26 dd 17 f0       	sub    $0xf017dd26,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 26 dd 17 f0 	movl   $0xf017dd26,(%esp)
f0100063:	e8 8b 4c 00 00       	call   f0104cf3 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 b0 04 00 00       	call   f010051d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 00 52 10 f0 	movl   $0xf0105200,(%esp)
f010007c:	e8 0b 37 00 00       	call   f010378c <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 41 11 00 00       	call   f01011c7 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100086:	e8 6b 30 00 00       	call   f01030f6 <env_init>
	trap_init();
f010008b:	90                   	nop
f010008c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100090:	e8 78 37 00 00       	call   f010380d <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100095:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010009c:	00 
f010009d:	c7 04 24 c6 2b 13 f0 	movl   $0xf0132bc6,(%esp)
f01000a4:	e8 43 32 00 00       	call   f01032ec <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a9:	a1 8c df 17 f0       	mov    0xf017df8c,%eax
f01000ae:	89 04 24             	mov    %eax,(%esp)
f01000b1:	e8 f9 35 00 00       	call   f01036af <env_run>

f01000b6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000b6:	55                   	push   %ebp
f01000b7:	89 e5                	mov    %esp,%ebp
f01000b9:	56                   	push   %esi
f01000ba:	53                   	push   %ebx
f01000bb:	83 ec 10             	sub    $0x10,%esp
f01000be:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000c1:	83 3d 20 ec 17 f0 00 	cmpl   $0x0,0xf017ec20
f01000c8:	75 3d                	jne    f0100107 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000ca:	89 35 20 ec 17 f0    	mov    %esi,0xf017ec20

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000d0:	fa                   	cli    
f01000d1:	fc                   	cld    

	va_start(ap, fmt);
f01000d2:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000d8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01000df:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000e3:	c7 04 24 1b 52 10 f0 	movl   $0xf010521b,(%esp)
f01000ea:	e8 9d 36 00 00       	call   f010378c <cprintf>
	vcprintf(fmt, ap);
f01000ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000f3:	89 34 24             	mov    %esi,(%esp)
f01000f6:	e8 5e 36 00 00       	call   f0103759 <vcprintf>
	cprintf("\n");
f01000fb:	c7 04 24 88 5f 10 f0 	movl   $0xf0105f88,(%esp)
f0100102:	e8 85 36 00 00       	call   f010378c <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100107:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010010e:	e8 e3 06 00 00       	call   f01007f6 <monitor>
f0100113:	eb f2                	jmp    f0100107 <_panic+0x51>

f0100115 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100115:	55                   	push   %ebp
f0100116:	89 e5                	mov    %esp,%ebp
f0100118:	53                   	push   %ebx
f0100119:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010011c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010011f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100122:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100126:	8b 45 08             	mov    0x8(%ebp),%eax
f0100129:	89 44 24 04          	mov    %eax,0x4(%esp)
f010012d:	c7 04 24 33 52 10 f0 	movl   $0xf0105233,(%esp)
f0100134:	e8 53 36 00 00       	call   f010378c <cprintf>
	vcprintf(fmt, ap);
f0100139:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010013d:	8b 45 10             	mov    0x10(%ebp),%eax
f0100140:	89 04 24             	mov    %eax,(%esp)
f0100143:	e8 11 36 00 00       	call   f0103759 <vcprintf>
	cprintf("\n");
f0100148:	c7 04 24 88 5f 10 f0 	movl   $0xf0105f88,(%esp)
f010014f:	e8 38 36 00 00       	call   f010378c <cprintf>
	va_end(ap);
}
f0100154:	83 c4 14             	add    $0x14,%esp
f0100157:	5b                   	pop    %ebx
f0100158:	5d                   	pop    %ebp
f0100159:	c3                   	ret    
f010015a:	66 90                	xchg   %ax,%ax
f010015c:	66 90                	xchg   %ax,%ax
f010015e:	66 90                	xchg   %ax,%ax

f0100160 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100160:	55                   	push   %ebp
f0100161:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100163:	ba 84 00 00 00       	mov    $0x84,%edx
f0100168:	ec                   	in     (%dx),%al
f0100169:	ec                   	in     (%dx),%al
f010016a:	ec                   	in     (%dx),%al
f010016b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010016c:	5d                   	pop    %ebp
f010016d:	c3                   	ret    

f010016e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010016e:	55                   	push   %ebp
f010016f:	89 e5                	mov    %esp,%ebp
f0100171:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100176:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100177:	a8 01                	test   $0x1,%al
f0100179:	74 08                	je     f0100183 <serial_proc_data+0x15>
f010017b:	b2 f8                	mov    $0xf8,%dl
f010017d:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010017e:	0f b6 c0             	movzbl %al,%eax
f0100181:	eb 05                	jmp    f0100188 <serial_proc_data+0x1a>
		return -1;
f0100183:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f0100188:	5d                   	pop    %ebp
f0100189:	c3                   	ret    

f010018a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010018a:	55                   	push   %ebp
f010018b:	89 e5                	mov    %esp,%ebp
f010018d:	53                   	push   %ebx
f010018e:	83 ec 04             	sub    $0x4,%esp
f0100191:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100193:	eb 26                	jmp    f01001bb <cons_intr+0x31>
		if (c == 0)
f0100195:	85 d2                	test   %edx,%edx
f0100197:	74 22                	je     f01001bb <cons_intr+0x31>
			continue;
		cons.buf[cons.wpos++] = c;
f0100199:	a1 64 df 17 f0       	mov    0xf017df64,%eax
f010019e:	88 90 60 dd 17 f0    	mov    %dl,-0xfe822a0(%eax)
f01001a4:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f01001a7:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01001b2:	0f 44 d0             	cmove  %eax,%edx
f01001b5:	89 15 64 df 17 f0    	mov    %edx,0xf017df64
	while ((c = (*proc)()) != -1) {
f01001bb:	ff d3                	call   *%ebx
f01001bd:	89 c2                	mov    %eax,%edx
f01001bf:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001c2:	75 d1                	jne    f0100195 <cons_intr+0xb>
	}
}
f01001c4:	83 c4 04             	add    $0x4,%esp
f01001c7:	5b                   	pop    %ebx
f01001c8:	5d                   	pop    %ebp
f01001c9:	c3                   	ret    

f01001ca <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001ca:	55                   	push   %ebp
f01001cb:	89 e5                	mov    %esp,%ebp
f01001cd:	57                   	push   %edi
f01001ce:	56                   	push   %esi
f01001cf:	53                   	push   %ebx
f01001d0:	83 ec 2c             	sub    $0x2c,%esp
f01001d3:	89 c7                	mov    %eax,%edi
f01001d5:	bb 01 32 00 00       	mov    $0x3201,%ebx
f01001da:	be fd 03 00 00       	mov    $0x3fd,%esi
f01001df:	eb 05                	jmp    f01001e6 <cons_putc+0x1c>
		delay();
f01001e1:	e8 7a ff ff ff       	call   f0100160 <delay>
f01001e6:	89 f2                	mov    %esi,%edx
f01001e8:	ec                   	in     (%dx),%al
	for (i = 0;
f01001e9:	a8 20                	test   $0x20,%al
f01001eb:	75 05                	jne    f01001f2 <cons_putc+0x28>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001ed:	83 eb 01             	sub    $0x1,%ebx
f01001f0:	75 ef                	jne    f01001e1 <cons_putc+0x17>
	outb(COM1 + COM_TX, c);
f01001f2:	89 f8                	mov    %edi,%eax
f01001f4:	25 ff 00 00 00       	and    $0xff,%eax
f01001f9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001fc:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100201:	ee                   	out    %al,(%dx)
f0100202:	bb 01 32 00 00       	mov    $0x3201,%ebx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100207:	be 79 03 00 00       	mov    $0x379,%esi
f010020c:	eb 05                	jmp    f0100213 <cons_putc+0x49>
		delay();
f010020e:	e8 4d ff ff ff       	call   f0100160 <delay>
f0100213:	89 f2                	mov    %esi,%edx
f0100215:	ec                   	in     (%dx),%al
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100216:	84 c0                	test   %al,%al
f0100218:	78 05                	js     f010021f <cons_putc+0x55>
f010021a:	83 eb 01             	sub    $0x1,%ebx
f010021d:	75 ef                	jne    f010020e <cons_putc+0x44>
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010021f:	ba 78 03 00 00       	mov    $0x378,%edx
f0100224:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100228:	ee                   	out    %al,(%dx)
f0100229:	b2 7a                	mov    $0x7a,%dl
f010022b:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100230:	ee                   	out    %al,(%dx)
f0100231:	b8 08 00 00 00       	mov    $0x8,%eax
f0100236:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100237:	89 fa                	mov    %edi,%edx
f0100239:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010023f:	89 f8                	mov    %edi,%eax
f0100241:	80 cc 07             	or     $0x7,%ah
f0100244:	85 d2                	test   %edx,%edx
f0100246:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f0100249:	89 f8                	mov    %edi,%eax
f010024b:	25 ff 00 00 00       	and    $0xff,%eax
f0100250:	83 f8 09             	cmp    $0x9,%eax
f0100253:	74 7a                	je     f01002cf <cons_putc+0x105>
f0100255:	83 f8 09             	cmp    $0x9,%eax
f0100258:	7f 0b                	jg     f0100265 <cons_putc+0x9b>
f010025a:	83 f8 08             	cmp    $0x8,%eax
f010025d:	0f 85 a0 00 00 00    	jne    f0100303 <cons_putc+0x139>
f0100263:	eb 13                	jmp    f0100278 <cons_putc+0xae>
f0100265:	83 f8 0a             	cmp    $0xa,%eax
f0100268:	74 3f                	je     f01002a9 <cons_putc+0xdf>
f010026a:	83 f8 0d             	cmp    $0xd,%eax
f010026d:	8d 76 00             	lea    0x0(%esi),%esi
f0100270:	0f 85 8d 00 00 00    	jne    f0100303 <cons_putc+0x139>
f0100276:	eb 39                	jmp    f01002b1 <cons_putc+0xe7>
		if (crt_pos > 0) {
f0100278:	0f b7 05 74 df 17 f0 	movzwl 0xf017df74,%eax
f010027f:	66 85 c0             	test   %ax,%ax
f0100282:	0f 84 e5 00 00 00    	je     f010036d <cons_putc+0x1a3>
			crt_pos--;
f0100288:	83 e8 01             	sub    $0x1,%eax
f010028b:	66 a3 74 df 17 f0    	mov    %ax,0xf017df74
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100291:	0f b7 c0             	movzwl %ax,%eax
f0100294:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f010029a:	83 cf 20             	or     $0x20,%edi
f010029d:	8b 15 70 df 17 f0    	mov    0xf017df70,%edx
f01002a3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002a7:	eb 77                	jmp    f0100320 <cons_putc+0x156>
		crt_pos += CRT_COLS;
f01002a9:	66 83 05 74 df 17 f0 	addw   $0x50,0xf017df74
f01002b0:	50 
		crt_pos -= (crt_pos % CRT_COLS);
f01002b1:	0f b7 05 74 df 17 f0 	movzwl 0xf017df74,%eax
f01002b8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002be:	c1 e8 16             	shr    $0x16,%eax
f01002c1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002c4:	c1 e0 04             	shl    $0x4,%eax
f01002c7:	66 a3 74 df 17 f0    	mov    %ax,0xf017df74
f01002cd:	eb 51                	jmp    f0100320 <cons_putc+0x156>
		cons_putc(' ');
f01002cf:	b8 20 00 00 00       	mov    $0x20,%eax
f01002d4:	e8 f1 fe ff ff       	call   f01001ca <cons_putc>
		cons_putc(' ');
f01002d9:	b8 20 00 00 00       	mov    $0x20,%eax
f01002de:	e8 e7 fe ff ff       	call   f01001ca <cons_putc>
		cons_putc(' ');
f01002e3:	b8 20 00 00 00       	mov    $0x20,%eax
f01002e8:	e8 dd fe ff ff       	call   f01001ca <cons_putc>
		cons_putc(' ');
f01002ed:	b8 20 00 00 00       	mov    $0x20,%eax
f01002f2:	e8 d3 fe ff ff       	call   f01001ca <cons_putc>
		cons_putc(' ');
f01002f7:	b8 20 00 00 00       	mov    $0x20,%eax
f01002fc:	e8 c9 fe ff ff       	call   f01001ca <cons_putc>
f0100301:	eb 1d                	jmp    f0100320 <cons_putc+0x156>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100303:	0f b7 05 74 df 17 f0 	movzwl 0xf017df74,%eax
f010030a:	0f b7 c8             	movzwl %ax,%ecx
f010030d:	8b 15 70 df 17 f0    	mov    0xf017df70,%edx
f0100313:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100317:	83 c0 01             	add    $0x1,%eax
f010031a:	66 a3 74 df 17 f0    	mov    %ax,0xf017df74
	if (crt_pos >= CRT_SIZE) {
f0100320:	66 81 3d 74 df 17 f0 	cmpw   $0x7cf,0xf017df74
f0100327:	cf 07 
f0100329:	76 42                	jbe    f010036d <cons_putc+0x1a3>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010032b:	a1 70 df 17 f0       	mov    0xf017df70,%eax
f0100330:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100337:	00 
f0100338:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010033e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100342:	89 04 24             	mov    %eax,(%esp)
f0100345:	e8 07 4a 00 00       	call   f0104d51 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010034a:	8b 15 70 df 17 f0    	mov    0xf017df70,%edx
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100350:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100355:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010035b:	83 c0 01             	add    $0x1,%eax
f010035e:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100363:	75 f0                	jne    f0100355 <cons_putc+0x18b>
		crt_pos -= CRT_COLS;
f0100365:	66 83 2d 74 df 17 f0 	subw   $0x50,0xf017df74
f010036c:	50 
	outb(addr_6845, 14);
f010036d:	8b 0d 6c df 17 f0    	mov    0xf017df6c,%ecx
f0100373:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100378:	89 ca                	mov    %ecx,%edx
f010037a:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010037b:	0f b7 1d 74 df 17 f0 	movzwl 0xf017df74,%ebx
f0100382:	8d 71 01             	lea    0x1(%ecx),%esi
f0100385:	89 d8                	mov    %ebx,%eax
f0100387:	66 c1 e8 08          	shr    $0x8,%ax
f010038b:	89 f2                	mov    %esi,%edx
f010038d:	ee                   	out    %al,(%dx)
f010038e:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100393:	89 ca                	mov    %ecx,%edx
f0100395:	ee                   	out    %al,(%dx)
f0100396:	89 d8                	mov    %ebx,%eax
f0100398:	89 f2                	mov    %esi,%edx
f010039a:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010039b:	83 c4 2c             	add    $0x2c,%esp
f010039e:	5b                   	pop    %ebx
f010039f:	5e                   	pop    %esi
f01003a0:	5f                   	pop    %edi
f01003a1:	5d                   	pop    %ebp
f01003a2:	c3                   	ret    

f01003a3 <kbd_proc_data>:
{
f01003a3:	55                   	push   %ebp
f01003a4:	89 e5                	mov    %esp,%ebp
f01003a6:	53                   	push   %ebx
f01003a7:	83 ec 14             	sub    $0x14,%esp
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003aa:	ba 64 00 00 00       	mov    $0x64,%edx
f01003af:	ec                   	in     (%dx),%al
	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01003b0:	a8 01                	test   $0x1,%al
f01003b2:	0f 84 e5 00 00 00    	je     f010049d <kbd_proc_data+0xfa>
f01003b8:	b2 60                	mov    $0x60,%dl
f01003ba:	ec                   	in     (%dx),%al
f01003bb:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01003bd:	3c e0                	cmp    $0xe0,%al
f01003bf:	75 11                	jne    f01003d2 <kbd_proc_data+0x2f>
		shift |= E0ESC;
f01003c1:	83 0d 68 df 17 f0 40 	orl    $0x40,0xf017df68
		return 0;
f01003c8:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003cd:	e9 d0 00 00 00       	jmp    f01004a2 <kbd_proc_data+0xff>
	} else if (data & 0x80) {
f01003d2:	84 c0                	test   %al,%al
f01003d4:	79 37                	jns    f010040d <kbd_proc_data+0x6a>
		data = (shift & E0ESC ? data : data & 0x7F);
f01003d6:	8b 0d 68 df 17 f0    	mov    0xf017df68,%ecx
f01003dc:	89 cb                	mov    %ecx,%ebx
f01003de:	83 e3 40             	and    $0x40,%ebx
f01003e1:	83 e0 7f             	and    $0x7f,%eax
f01003e4:	85 db                	test   %ebx,%ebx
f01003e6:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003e9:	0f b6 d2             	movzbl %dl,%edx
f01003ec:	0f b6 82 80 52 10 f0 	movzbl -0xfefad80(%edx),%eax
f01003f3:	83 c8 40             	or     $0x40,%eax
f01003f6:	0f b6 c0             	movzbl %al,%eax
f01003f9:	f7 d0                	not    %eax
f01003fb:	21 c1                	and    %eax,%ecx
f01003fd:	89 0d 68 df 17 f0    	mov    %ecx,0xf017df68
		return 0;
f0100403:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100408:	e9 95 00 00 00       	jmp    f01004a2 <kbd_proc_data+0xff>
	} else if (shift & E0ESC) {
f010040d:	8b 0d 68 df 17 f0    	mov    0xf017df68,%ecx
f0100413:	f6 c1 40             	test   $0x40,%cl
f0100416:	74 0e                	je     f0100426 <kbd_proc_data+0x83>
		data |= 0x80;
f0100418:	89 c2                	mov    %eax,%edx
f010041a:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010041d:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100420:	89 0d 68 df 17 f0    	mov    %ecx,0xf017df68
	shift |= shiftcode[data];
f0100426:	0f b6 d2             	movzbl %dl,%edx
f0100429:	0f b6 82 80 52 10 f0 	movzbl -0xfefad80(%edx),%eax
f0100430:	0b 05 68 df 17 f0    	or     0xf017df68,%eax
	shift ^= togglecode[data];
f0100436:	0f b6 8a 80 53 10 f0 	movzbl -0xfefac80(%edx),%ecx
f010043d:	31 c8                	xor    %ecx,%eax
f010043f:	a3 68 df 17 f0       	mov    %eax,0xf017df68
	c = charcode[shift & (CTL | SHIFT)][data];
f0100444:	89 c1                	mov    %eax,%ecx
f0100446:	83 e1 03             	and    $0x3,%ecx
f0100449:	8b 0c 8d 80 54 10 f0 	mov    -0xfefab80(,%ecx,4),%ecx
f0100450:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100454:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100457:	a8 08                	test   $0x8,%al
f0100459:	74 1b                	je     f0100476 <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f010045b:	89 da                	mov    %ebx,%edx
f010045d:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100460:	83 f9 19             	cmp    $0x19,%ecx
f0100463:	77 05                	ja     f010046a <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f0100465:	83 eb 20             	sub    $0x20,%ebx
f0100468:	eb 0c                	jmp    f0100476 <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f010046a:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010046d:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100470:	83 fa 19             	cmp    $0x19,%edx
f0100473:	0f 46 d9             	cmovbe %ecx,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100476:	f7 d0                	not    %eax
f0100478:	a8 06                	test   $0x6,%al
f010047a:	75 26                	jne    f01004a2 <kbd_proc_data+0xff>
f010047c:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100482:	75 1e                	jne    f01004a2 <kbd_proc_data+0xff>
		cprintf("Rebooting!\n");
f0100484:	c7 04 24 4d 52 10 f0 	movl   $0xf010524d,(%esp)
f010048b:	e8 fc 32 00 00       	call   f010378c <cprintf>
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100490:	ba 92 00 00 00       	mov    $0x92,%edx
f0100495:	b8 03 00 00 00       	mov    $0x3,%eax
f010049a:	ee                   	out    %al,(%dx)
f010049b:	eb 05                	jmp    f01004a2 <kbd_proc_data+0xff>
		return -1;
f010049d:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
}
f01004a2:	89 d8                	mov    %ebx,%eax
f01004a4:	83 c4 14             	add    $0x14,%esp
f01004a7:	5b                   	pop    %ebx
f01004a8:	5d                   	pop    %ebp
f01004a9:	c3                   	ret    

f01004aa <serial_intr>:
	if (serial_exists)
f01004aa:	80 3d 40 dd 17 f0 00 	cmpb   $0x0,0xf017dd40
f01004b1:	74 11                	je     f01004c4 <serial_intr+0x1a>
{
f01004b3:	55                   	push   %ebp
f01004b4:	89 e5                	mov    %esp,%ebp
f01004b6:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01004b9:	b8 6e 01 10 f0       	mov    $0xf010016e,%eax
f01004be:	e8 c7 fc ff ff       	call   f010018a <cons_intr>
}
f01004c3:	c9                   	leave  
f01004c4:	f3 c3                	repz ret 

f01004c6 <kbd_intr>:
{
f01004c6:	55                   	push   %ebp
f01004c7:	89 e5                	mov    %esp,%ebp
f01004c9:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004cc:	b8 a3 03 10 f0       	mov    $0xf01003a3,%eax
f01004d1:	e8 b4 fc ff ff       	call   f010018a <cons_intr>
}
f01004d6:	c9                   	leave  
f01004d7:	c3                   	ret    

f01004d8 <cons_getc>:
{
f01004d8:	55                   	push   %ebp
f01004d9:	89 e5                	mov    %esp,%ebp
f01004db:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f01004de:	e8 c7 ff ff ff       	call   f01004aa <serial_intr>
	kbd_intr();
f01004e3:	e8 de ff ff ff       	call   f01004c6 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01004e8:	8b 15 60 df 17 f0    	mov    0xf017df60,%edx
f01004ee:	3b 15 64 df 17 f0    	cmp    0xf017df64,%edx
f01004f4:	74 20                	je     f0100516 <cons_getc+0x3e>
		c = cons.buf[cons.rpos++];
f01004f6:	0f b6 82 60 dd 17 f0 	movzbl -0xfe822a0(%edx),%eax
f01004fd:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f0100500:	81 fa 00 02 00 00    	cmp    $0x200,%edx
		c = cons.buf[cons.rpos++];
f0100506:	b9 00 00 00 00       	mov    $0x0,%ecx
f010050b:	0f 44 d1             	cmove  %ecx,%edx
f010050e:	89 15 60 df 17 f0    	mov    %edx,0xf017df60
f0100514:	eb 05                	jmp    f010051b <cons_getc+0x43>
	return 0;
f0100516:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010051b:	c9                   	leave  
f010051c:	c3                   	ret    

f010051d <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f010051d:	55                   	push   %ebp
f010051e:	89 e5                	mov    %esp,%ebp
f0100520:	57                   	push   %edi
f0100521:	56                   	push   %esi
f0100522:	53                   	push   %ebx
f0100523:	83 ec 1c             	sub    $0x1c,%esp
	was = *cp;
f0100526:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010052d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100534:	5a a5 
	if (*cp != 0xA55A) {
f0100536:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010053d:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100541:	74 11                	je     f0100554 <cons_init+0x37>
		addr_6845 = MONO_BASE;
f0100543:	c7 05 6c df 17 f0 b4 	movl   $0x3b4,0xf017df6c
f010054a:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010054d:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100552:	eb 16                	jmp    f010056a <cons_init+0x4d>
		*cp = was;
f0100554:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010055b:	c7 05 6c df 17 f0 d4 	movl   $0x3d4,0xf017df6c
f0100562:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100565:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
	outb(addr_6845, 14);
f010056a:	8b 0d 6c df 17 f0    	mov    0xf017df6c,%ecx
f0100570:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100575:	89 ca                	mov    %ecx,%edx
f0100577:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100578:	8d 59 01             	lea    0x1(%ecx),%ebx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057b:	89 da                	mov    %ebx,%edx
f010057d:	ec                   	in     (%dx),%al
f010057e:	0f b6 f0             	movzbl %al,%esi
f0100581:	c1 e6 08             	shl    $0x8,%esi
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100584:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100589:	89 ca                	mov    %ecx,%edx
f010058b:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010058c:	89 da                	mov    %ebx,%edx
f010058e:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010058f:	89 3d 70 df 17 f0    	mov    %edi,0xf017df70
	pos |= inb(addr_6845 + 1);
f0100595:	0f b6 d8             	movzbl %al,%ebx
f0100598:	09 de                	or     %ebx,%esi
	crt_pos = pos;
f010059a:	66 89 35 74 df 17 f0 	mov    %si,0xf017df74
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005a1:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ab:	89 f2                	mov    %esi,%edx
f01005ad:	ee                   	out    %al,(%dx)
f01005ae:	b2 fb                	mov    $0xfb,%dl
f01005b0:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005bb:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005c0:	89 da                	mov    %ebx,%edx
f01005c2:	ee                   	out    %al,(%dx)
f01005c3:	b2 f9                	mov    $0xf9,%dl
f01005c5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ca:	ee                   	out    %al,(%dx)
f01005cb:	b2 fb                	mov    $0xfb,%dl
f01005cd:	b8 03 00 00 00       	mov    $0x3,%eax
f01005d2:	ee                   	out    %al,(%dx)
f01005d3:	b2 fc                	mov    $0xfc,%dl
f01005d5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005da:	ee                   	out    %al,(%dx)
f01005db:	b2 f9                	mov    $0xf9,%dl
f01005dd:	b8 01 00 00 00       	mov    $0x1,%eax
f01005e2:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e3:	b2 fd                	mov    $0xfd,%dl
f01005e5:	ec                   	in     (%dx),%al
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005e6:	3c ff                	cmp    $0xff,%al
f01005e8:	0f 95 c1             	setne  %cl
f01005eb:	88 0d 40 dd 17 f0    	mov    %cl,0xf017dd40
f01005f1:	89 f2                	mov    %esi,%edx
f01005f3:	ec                   	in     (%dx),%al
f01005f4:	89 da                	mov    %ebx,%edx
f01005f6:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005f7:	84 c9                	test   %cl,%cl
f01005f9:	75 0c                	jne    f0100607 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f01005fb:	c7 04 24 59 52 10 f0 	movl   $0xf0105259,(%esp)
f0100602:	e8 85 31 00 00       	call   f010378c <cprintf>
}
f0100607:	83 c4 1c             	add    $0x1c,%esp
f010060a:	5b                   	pop    %ebx
f010060b:	5e                   	pop    %esi
f010060c:	5f                   	pop    %edi
f010060d:	5d                   	pop    %ebp
f010060e:	c3                   	ret    

f010060f <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010060f:	55                   	push   %ebp
f0100610:	89 e5                	mov    %esp,%ebp
f0100612:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100615:	8b 45 08             	mov    0x8(%ebp),%eax
f0100618:	e8 ad fb ff ff       	call   f01001ca <cons_putc>
}
f010061d:	c9                   	leave  
f010061e:	c3                   	ret    

f010061f <getchar>:

int
getchar(void)
{
f010061f:	55                   	push   %ebp
f0100620:	89 e5                	mov    %esp,%ebp
f0100622:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100625:	e8 ae fe ff ff       	call   f01004d8 <cons_getc>
f010062a:	85 c0                	test   %eax,%eax
f010062c:	74 f7                	je     f0100625 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010062e:	c9                   	leave  
f010062f:	c3                   	ret    

f0100630 <iscons>:

int
iscons(int fdnum)
{
f0100630:	55                   	push   %ebp
f0100631:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100633:	b8 01 00 00 00       	mov    $0x1,%eax
f0100638:	5d                   	pop    %ebp
f0100639:	c3                   	ret    
f010063a:	66 90                	xchg   %ax,%ax
f010063c:	66 90                	xchg   %ax,%ax
f010063e:	66 90                	xchg   %ax,%ax

f0100640 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100646:	c7 04 24 90 54 10 f0 	movl   $0xf0105490,(%esp)
f010064d:	e8 3a 31 00 00       	call   f010378c <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100652:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100659:	00 
f010065a:	c7 04 24 60 55 10 f0 	movl   $0xf0105560,(%esp)
f0100661:	e8 26 31 00 00       	call   f010378c <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100666:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010066d:	00 
f010066e:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100675:	f0 
f0100676:	c7 04 24 88 55 10 f0 	movl   $0xf0105588,(%esp)
f010067d:	e8 0a 31 00 00       	call   f010378c <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100682:	c7 44 24 08 ff 51 10 	movl   $0x1051ff,0x8(%esp)
f0100689:	00 
f010068a:	c7 44 24 04 ff 51 10 	movl   $0xf01051ff,0x4(%esp)
f0100691:	f0 
f0100692:	c7 04 24 ac 55 10 f0 	movl   $0xf01055ac,(%esp)
f0100699:	e8 ee 30 00 00       	call   f010378c <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010069e:	c7 44 24 08 26 dd 17 	movl   $0x17dd26,0x8(%esp)
f01006a5:	00 
f01006a6:	c7 44 24 04 26 dd 17 	movl   $0xf017dd26,0x4(%esp)
f01006ad:	f0 
f01006ae:	c7 04 24 d0 55 10 f0 	movl   $0xf01055d0,(%esp)
f01006b5:	e8 d2 30 00 00       	call   f010378c <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ba:	c7 44 24 08 30 ec 17 	movl   $0x17ec30,0x8(%esp)
f01006c1:	00 
f01006c2:	c7 44 24 04 30 ec 17 	movl   $0xf017ec30,0x4(%esp)
f01006c9:	f0 
f01006ca:	c7 04 24 f4 55 10 f0 	movl   $0xf01055f4,(%esp)
f01006d1:	e8 b6 30 00 00       	call   f010378c <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006d6:	b8 2f f0 17 f0       	mov    $0xf017f02f,%eax
f01006db:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01006e0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006e5:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006eb:	85 c0                	test   %eax,%eax
f01006ed:	0f 48 c2             	cmovs  %edx,%eax
f01006f0:	c1 f8 0a             	sar    $0xa,%eax
f01006f3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006f7:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01006fe:	e8 89 30 00 00       	call   f010378c <cprintf>
	return 0;
}
f0100703:	b8 00 00 00 00       	mov    $0x0,%eax
f0100708:	c9                   	leave  
f0100709:	c3                   	ret    

f010070a <mon_help>:
{
f010070a:	55                   	push   %ebp
f010070b:	89 e5                	mov    %esp,%ebp
f010070d:	83 ec 18             	sub    $0x18,%esp
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100710:	c7 44 24 08 a9 54 10 	movl   $0xf01054a9,0x8(%esp)
f0100717:	f0 
f0100718:	c7 44 24 04 c7 54 10 	movl   $0xf01054c7,0x4(%esp)
f010071f:	f0 
f0100720:	c7 04 24 cc 54 10 f0 	movl   $0xf01054cc,(%esp)
f0100727:	e8 60 30 00 00       	call   f010378c <cprintf>
f010072c:	c7 44 24 08 44 56 10 	movl   $0xf0105644,0x8(%esp)
f0100733:	f0 
f0100734:	c7 44 24 04 d5 54 10 	movl   $0xf01054d5,0x4(%esp)
f010073b:	f0 
f010073c:	c7 04 24 cc 54 10 f0 	movl   $0xf01054cc,(%esp)
f0100743:	e8 44 30 00 00       	call   f010378c <cprintf>
}
f0100748:	b8 00 00 00 00       	mov    $0x0,%eax
f010074d:	c9                   	leave  
f010074e:	c3                   	ret    

f010074f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010074f:	55                   	push   %ebp
f0100750:	89 e5                	mov    %esp,%ebp
f0100752:	57                   	push   %edi
f0100753:	56                   	push   %esi
f0100754:	53                   	push   %ebx
f0100755:	83 ec 4c             	sub    $0x4c,%esp
	// Your code here.
	struct Eipdebuginfo info;
	uint32_t *ebp = (uint32_t *) read_ebp();
f0100758:	89 ee                	mov    %ebp,%esi
	cprintf("Stack backtrace:\n");
f010075a:	c7 04 24 de 54 10 f0 	movl   $0xf01054de,(%esp)
f0100761:	e8 26 30 00 00       	call   f010378c <cprintf>
	    cprintf(" ebp %08x eip %08x args", ebp, ebp[1]);
            int j;
	    for (j = 2; j != 7; ++j) {
		cprintf(" %08x", ebp[j]);   
	    }
	    debuginfo_eip(ebp[1], &info);
f0100766:	8d 7d d0             	lea    -0x30(%ebp),%edi
	while (ebp) {
f0100769:	eb 7a                	jmp    f01007e5 <mon_backtrace+0x96>
	    cprintf(" ebp %08x eip %08x args", ebp, ebp[1]);
f010076b:	8b 46 04             	mov    0x4(%esi),%eax
f010076e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100772:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100776:	c7 04 24 f0 54 10 f0 	movl   $0xf01054f0,(%esp)
f010077d:	e8 0a 30 00 00       	call   f010378c <cprintf>
	    for (j = 2; j != 7; ++j) {
f0100782:	bb 02 00 00 00       	mov    $0x2,%ebx
		cprintf(" %08x", ebp[j]);   
f0100787:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f010078a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010078e:	c7 04 24 08 55 10 f0 	movl   $0xf0105508,(%esp)
f0100795:	e8 f2 2f 00 00       	call   f010378c <cprintf>
	    for (j = 2; j != 7; ++j) {
f010079a:	83 c3 01             	add    $0x1,%ebx
f010079d:	83 fb 07             	cmp    $0x7,%ebx
f01007a0:	75 e5                	jne    f0100787 <mon_backtrace+0x38>
	    debuginfo_eip(ebp[1], &info);
f01007a2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007a6:	8b 46 04             	mov    0x4(%esi),%eax
f01007a9:	89 04 24             	mov    %eax,(%esp)
f01007ac:	e8 00 3a 00 00       	call   f01041b1 <debuginfo_eip>
	    cprintf("\n     %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, ebp[1] - info.eip_fn_addr);
f01007b1:	8b 46 04             	mov    0x4(%esi),%eax
f01007b4:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01007b7:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007bb:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007be:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007c2:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01007c5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007c9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007cc:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007d0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007d3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007d7:	c7 04 24 0e 55 10 f0 	movl   $0xf010550e,(%esp)
f01007de:	e8 a9 2f 00 00       	call   f010378c <cprintf>
	    ebp = (uint32_t *) (*ebp);
f01007e3:	8b 36                	mov    (%esi),%esi
	while (ebp) {
f01007e5:	85 f6                	test   %esi,%esi
f01007e7:	75 82                	jne    f010076b <mon_backtrace+0x1c>
	}

	return 0;
}
f01007e9:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ee:	83 c4 4c             	add    $0x4c,%esp
f01007f1:	5b                   	pop    %ebx
f01007f2:	5e                   	pop    %esi
f01007f3:	5f                   	pop    %edi
f01007f4:	5d                   	pop    %ebp
f01007f5:	c3                   	ret    

f01007f6 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007f6:	55                   	push   %ebp
f01007f7:	89 e5                	mov    %esp,%ebp
f01007f9:	57                   	push   %edi
f01007fa:	56                   	push   %esi
f01007fb:	53                   	push   %ebx
f01007fc:	83 ec 5c             	sub    $0x5c,%esp
f01007ff:	8b 7d 08             	mov    0x8(%ebp),%edi
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100802:	c7 04 24 6c 56 10 f0 	movl   $0xf010566c,(%esp)
f0100809:	e8 7e 2f 00 00       	call   f010378c <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010080e:	c7 04 24 90 56 10 f0 	movl   $0xf0105690,(%esp)
f0100815:	e8 72 2f 00 00       	call   f010378c <cprintf>

	if (tf != NULL)
f010081a:	85 ff                	test   %edi,%edi
f010081c:	74 08                	je     f0100826 <monitor+0x30>
		print_trapframe(tf);
f010081e:	89 3c 24             	mov    %edi,(%esp)
f0100821:	e8 c9 33 00 00       	call   f0103bef <print_trapframe>

	while (1) {
		buf = readline("K> ");
f0100826:	c7 04 24 24 55 10 f0 	movl   $0xf0105524,(%esp)
f010082d:	e8 6e 42 00 00       	call   f0104aa0 <readline>
f0100832:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100834:	85 c0                	test   %eax,%eax
f0100836:	74 ee                	je     f0100826 <monitor+0x30>
	argv[argc] = 0;
f0100838:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f010083f:	be 00 00 00 00       	mov    $0x0,%esi
f0100844:	eb 06                	jmp    f010084c <monitor+0x56>
			*buf++ = 0;
f0100846:	c6 03 00             	movb   $0x0,(%ebx)
f0100849:	83 c3 01             	add    $0x1,%ebx
		while (*buf && strchr(WHITESPACE, *buf))
f010084c:	0f b6 03             	movzbl (%ebx),%eax
f010084f:	84 c0                	test   %al,%al
f0100851:	74 63                	je     f01008b6 <monitor+0xc0>
f0100853:	0f be c0             	movsbl %al,%eax
f0100856:	89 44 24 04          	mov    %eax,0x4(%esp)
f010085a:	c7 04 24 28 55 10 f0 	movl   $0xf0105528,(%esp)
f0100861:	e8 50 44 00 00       	call   f0104cb6 <strchr>
f0100866:	85 c0                	test   %eax,%eax
f0100868:	75 dc                	jne    f0100846 <monitor+0x50>
		if (*buf == 0)
f010086a:	80 3b 00             	cmpb   $0x0,(%ebx)
f010086d:	74 47                	je     f01008b6 <monitor+0xc0>
		if (argc == MAXARGS-1) {
f010086f:	83 fe 0f             	cmp    $0xf,%esi
f0100872:	75 16                	jne    f010088a <monitor+0x94>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100874:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010087b:	00 
f010087c:	c7 04 24 2d 55 10 f0 	movl   $0xf010552d,(%esp)
f0100883:	e8 04 2f 00 00       	call   f010378c <cprintf>
f0100888:	eb 9c                	jmp    f0100826 <monitor+0x30>
		argv[argc++] = buf;
f010088a:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010088e:	83 c6 01             	add    $0x1,%esi
f0100891:	eb 03                	jmp    f0100896 <monitor+0xa0>
			buf++;
f0100893:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f0100896:	0f b6 03             	movzbl (%ebx),%eax
f0100899:	84 c0                	test   %al,%al
f010089b:	74 af                	je     f010084c <monitor+0x56>
f010089d:	0f be c0             	movsbl %al,%eax
f01008a0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008a4:	c7 04 24 28 55 10 f0 	movl   $0xf0105528,(%esp)
f01008ab:	e8 06 44 00 00       	call   f0104cb6 <strchr>
f01008b0:	85 c0                	test   %eax,%eax
f01008b2:	74 df                	je     f0100893 <monitor+0x9d>
f01008b4:	eb 96                	jmp    f010084c <monitor+0x56>
	argv[argc] = 0;
f01008b6:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008bd:	00 
	if (argc == 0)
f01008be:	85 f6                	test   %esi,%esi
f01008c0:	0f 84 60 ff ff ff    	je     f0100826 <monitor+0x30>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008c6:	c7 44 24 04 c7 54 10 	movl   $0xf01054c7,0x4(%esp)
f01008cd:	f0 
f01008ce:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008d1:	89 04 24             	mov    %eax,(%esp)
f01008d4:	e8 7f 43 00 00       	call   f0104c58 <strcmp>
f01008d9:	85 c0                	test   %eax,%eax
f01008db:	74 1b                	je     f01008f8 <monitor+0x102>
f01008dd:	c7 44 24 04 d5 54 10 	movl   $0xf01054d5,0x4(%esp)
f01008e4:	f0 
f01008e5:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008e8:	89 04 24             	mov    %eax,(%esp)
f01008eb:	e8 68 43 00 00       	call   f0104c58 <strcmp>
f01008f0:	85 c0                	test   %eax,%eax
f01008f2:	75 2c                	jne    f0100920 <monitor+0x12a>
f01008f4:	b0 01                	mov    $0x1,%al
f01008f6:	eb 05                	jmp    f01008fd <monitor+0x107>
f01008f8:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008fd:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100900:	01 d0                	add    %edx,%eax
f0100902:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0100906:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100909:	89 54 24 04          	mov    %edx,0x4(%esp)
f010090d:	89 34 24             	mov    %esi,(%esp)
f0100910:	ff 14 85 c0 56 10 f0 	call   *-0xfefa940(,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100917:	85 c0                	test   %eax,%eax
f0100919:	78 1d                	js     f0100938 <monitor+0x142>
f010091b:	e9 06 ff ff ff       	jmp    f0100826 <monitor+0x30>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100920:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100923:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100927:	c7 04 24 4a 55 10 f0 	movl   $0xf010554a,(%esp)
f010092e:	e8 59 2e 00 00       	call   f010378c <cprintf>
f0100933:	e9 ee fe ff ff       	jmp    f0100826 <monitor+0x30>
				break;
	}
}
f0100938:	83 c4 5c             	add    $0x5c,%esp
f010093b:	5b                   	pop    %ebx
f010093c:	5e                   	pop    %esi
f010093d:	5f                   	pop    %edi
f010093e:	5d                   	pop    %ebp
f010093f:	c3                   	ret    

f0100940 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100940:	89 d1                	mov    %edx,%ecx
f0100942:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100945:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100948:	a8 01                	test   $0x1,%al
f010094a:	74 5d                	je     f01009a9 <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010094c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100951:	89 c1                	mov    %eax,%ecx
f0100953:	c1 e9 0c             	shr    $0xc,%ecx
f0100956:	3b 0d 24 ec 17 f0    	cmp    0xf017ec24,%ecx
f010095c:	72 26                	jb     f0100984 <check_va2pa+0x44>
{
f010095e:	55                   	push   %ebp
f010095f:	89 e5                	mov    %esp,%ebp
f0100961:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100964:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100968:	c7 44 24 08 d0 56 10 	movl   $0xf01056d0,0x8(%esp)
f010096f:	f0 
f0100970:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0100977:	00 
f0100978:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f010097f:	e8 32 f7 ff ff       	call   f01000b6 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100984:	c1 ea 0c             	shr    $0xc,%edx
f0100987:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010098d:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100994:	89 c2                	mov    %eax,%edx
f0100996:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100999:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010099e:	85 d2                	test   %edx,%edx
f01009a0:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009a5:	0f 44 c2             	cmove  %edx,%eax
f01009a8:	c3                   	ret    
		return ~0;
f01009a9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f01009ae:	c3                   	ret    

f01009af <boot_alloc>:
{
f01009af:	89 c2                	mov    %eax,%edx
	if (!nextfree) {
f01009b1:	a1 7c df 17 f0       	mov    0xf017df7c,%eax
f01009b6:	85 c0                	test   %eax,%eax
f01009b8:	75 50                	jne    f0100a0a <boot_alloc+0x5b>
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009ba:	b8 2f fc 17 f0       	mov    $0xf017fc2f,%eax
f01009bf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009c4:	a3 7c df 17 f0       	mov    %eax,0xf017df7c
	if (n == 0)
f01009c9:	85 d2                	test   %edx,%edx
f01009cb:	74 41                	je     f0100a0e <boot_alloc+0x5f>
	    nextfree = ROUNDUP(result+n,PGSIZE);
f01009cd:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f01009d4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009da:	89 15 7c df 17 f0    	mov    %edx,0xf017df7c
	    if ((uint32_t)nextfree > 0xF0400000)
f01009e0:	81 fa 00 00 40 f0    	cmp    $0xf0400000,%edx
f01009e6:	76 26                	jbe    f0100a0e <boot_alloc+0x5f>
{
f01009e8:	55                   	push   %ebp
f01009e9:	89 e5                	mov    %esp,%ebp
f01009eb:	83 ec 18             	sub    $0x18,%esp
		panic("Wrong,out of memory!\n");
f01009ee:	c7 44 24 08 99 5e 10 	movl   $0xf0105e99,0x8(%esp)
f01009f5:	f0 
f01009f6:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
f01009fd:	00 
f01009fe:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0100a05:	e8 ac f6 ff ff       	call   f01000b6 <_panic>
	if (n == 0)
f0100a0a:	85 d2                	test   %edx,%edx
f0100a0c:	75 bf                	jne    f01009cd <boot_alloc+0x1e>
}
f0100a0e:	f3 c3                	repz ret 

f0100a10 <nvram_read>:
{
f0100a10:	55                   	push   %ebp
f0100a11:	89 e5                	mov    %esp,%ebp
f0100a13:	83 ec 18             	sub    $0x18,%esp
f0100a16:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100a19:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100a1c:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a1e:	89 04 24             	mov    %eax,(%esp)
f0100a21:	e8 f5 2c 00 00       	call   f010371b <mc146818_read>
f0100a26:	89 c6                	mov    %eax,%esi
f0100a28:	83 c3 01             	add    $0x1,%ebx
f0100a2b:	89 1c 24             	mov    %ebx,(%esp)
f0100a2e:	e8 e8 2c 00 00       	call   f010371b <mc146818_read>
f0100a33:	c1 e0 08             	shl    $0x8,%eax
f0100a36:	09 f0                	or     %esi,%eax
}
f0100a38:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100a3b:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100a3e:	89 ec                	mov    %ebp,%esp
f0100a40:	5d                   	pop    %ebp
f0100a41:	c3                   	ret    

f0100a42 <check_page_free_list>:
{
f0100a42:	55                   	push   %ebp
f0100a43:	89 e5                	mov    %esp,%ebp
f0100a45:	57                   	push   %edi
f0100a46:	56                   	push   %esi
f0100a47:	53                   	push   %ebx
f0100a48:	83 ec 4c             	sub    $0x4c,%esp
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a4b:	84 c0                	test   %al,%al
f0100a4d:	0f 85 04 03 00 00    	jne    f0100d57 <check_page_free_list+0x315>
f0100a53:	e9 11 03 00 00       	jmp    f0100d69 <check_page_free_list+0x327>
		panic("'page_free_list' is a null pointer!");
f0100a58:	c7 44 24 08 f4 56 10 	movl   $0xf01056f4,0x8(%esp)
f0100a5f:	f0 
f0100a60:	c7 44 24 04 6b 02 00 	movl   $0x26b,0x4(%esp)
f0100a67:	00 
f0100a68:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0100a6f:	e8 42 f6 ff ff       	call   f01000b6 <_panic>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a74:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a77:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a7a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a7d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a80:	89 c2                	mov    %eax,%edx
f0100a82:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a88:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a8e:	0f 95 c2             	setne  %dl
f0100a91:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a94:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a98:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a9a:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a9e:	8b 00                	mov    (%eax),%eax
f0100aa0:	85 c0                	test   %eax,%eax
f0100aa2:	75 dc                	jne    f0100a80 <check_page_free_list+0x3e>
		*tp[1] = 0;
f0100aa4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100aa7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100aad:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ab0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ab3:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ab5:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ab8:	a3 80 df 17 f0       	mov    %eax,0xf017df80
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100abd:	be 01 00 00 00       	mov    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ac2:	8b 1d 80 df 17 f0    	mov    0xf017df80,%ebx
f0100ac8:	eb 63                	jmp    f0100b2d <check_page_free_list+0xeb>
f0100aca:	89 d8                	mov    %ebx,%eax
f0100acc:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0100ad2:	c1 f8 03             	sar    $0x3,%eax
f0100ad5:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100ad8:	89 c2                	mov    %eax,%edx
f0100ada:	c1 ea 16             	shr    $0x16,%edx
f0100add:	39 f2                	cmp    %esi,%edx
f0100adf:	73 4a                	jae    f0100b2b <check_page_free_list+0xe9>
	if (PGNUM(pa) >= npages)
f0100ae1:	89 c2                	mov    %eax,%edx
f0100ae3:	c1 ea 0c             	shr    $0xc,%edx
f0100ae6:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0100aec:	72 20                	jb     f0100b0e <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100aee:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100af2:	c7 44 24 08 d0 56 10 	movl   $0xf01056d0,0x8(%esp)
f0100af9:	f0 
f0100afa:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100b01:	00 
f0100b02:	c7 04 24 af 5e 10 f0 	movl   $0xf0105eaf,(%esp)
f0100b09:	e8 a8 f5 ff ff       	call   f01000b6 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b0e:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b15:	00 
f0100b16:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b1d:	00 
	return (void *)(pa + KERNBASE);
f0100b1e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b23:	89 04 24             	mov    %eax,(%esp)
f0100b26:	e8 c8 41 00 00       	call   f0104cf3 <memset>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b2b:	8b 1b                	mov    (%ebx),%ebx
f0100b2d:	85 db                	test   %ebx,%ebx
f0100b2f:	75 99                	jne    f0100aca <check_page_free_list+0x88>
	first_free_page = (char *) boot_alloc(0);
f0100b31:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b36:	e8 74 fe ff ff       	call   f01009af <boot_alloc>
f0100b3b:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b3e:	8b 15 80 df 17 f0    	mov    0xf017df80,%edx
		assert(pp >= pages);
f0100b44:	8b 0d 2c ec 17 f0    	mov    0xf017ec2c,%ecx
		assert(pp < pages + npages);
f0100b4a:	a1 24 ec 17 f0       	mov    0xf017ec24,%eax
f0100b4f:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b52:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100b55:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b58:	89 4d d0             	mov    %ecx,-0x30(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b5b:	bf 00 00 00 00       	mov    $0x0,%edi
f0100b60:	89 4d c0             	mov    %ecx,-0x40(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b63:	e9 97 01 00 00       	jmp    f0100cff <check_page_free_list+0x2bd>
		assert(pp >= pages);
f0100b68:	3b 55 c0             	cmp    -0x40(%ebp),%edx
f0100b6b:	73 24                	jae    f0100b91 <check_page_free_list+0x14f>
f0100b6d:	c7 44 24 0c bd 5e 10 	movl   $0xf0105ebd,0xc(%esp)
f0100b74:	f0 
f0100b75:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0100b7c:	f0 
f0100b7d:	c7 44 24 04 85 02 00 	movl   $0x285,0x4(%esp)
f0100b84:	00 
f0100b85:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0100b8c:	e8 25 f5 ff ff       	call   f01000b6 <_panic>
		assert(pp < pages + npages);
f0100b91:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100b94:	72 24                	jb     f0100bba <check_page_free_list+0x178>
f0100b96:	c7 44 24 0c de 5e 10 	movl   $0xf0105ede,0xc(%esp)
f0100b9d:	f0 
f0100b9e:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0100ba5:	f0 
f0100ba6:	c7 44 24 04 86 02 00 	movl   $0x286,0x4(%esp)
f0100bad:	00 
f0100bae:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0100bb5:	e8 fc f4 ff ff       	call   f01000b6 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bba:	89 d0                	mov    %edx,%eax
f0100bbc:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100bbf:	a8 07                	test   $0x7,%al
f0100bc1:	74 24                	je     f0100be7 <check_page_free_list+0x1a5>
f0100bc3:	c7 44 24 0c 18 57 10 	movl   $0xf0105718,0xc(%esp)
f0100bca:	f0 
f0100bcb:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0100bd2:	f0 
f0100bd3:	c7 44 24 04 87 02 00 	movl   $0x287,0x4(%esp)
f0100bda:	00 
f0100bdb:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0100be2:	e8 cf f4 ff ff       	call   f01000b6 <_panic>
	return (pp - pages) << PGSHIFT;
f0100be7:	c1 f8 03             	sar    $0x3,%eax
f0100bea:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100bed:	85 c0                	test   %eax,%eax
f0100bef:	75 24                	jne    f0100c15 <check_page_free_list+0x1d3>
f0100bf1:	c7 44 24 0c f2 5e 10 	movl   $0xf0105ef2,0xc(%esp)
f0100bf8:	f0 
f0100bf9:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0100c00:	f0 
f0100c01:	c7 44 24 04 8a 02 00 	movl   $0x28a,0x4(%esp)
f0100c08:	00 
f0100c09:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0100c10:	e8 a1 f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c15:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c1a:	75 24                	jne    f0100c40 <check_page_free_list+0x1fe>
f0100c1c:	c7 44 24 0c 03 5f 10 	movl   $0xf0105f03,0xc(%esp)
f0100c23:	f0 
f0100c24:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0100c2b:	f0 
f0100c2c:	c7 44 24 04 8b 02 00 	movl   $0x28b,0x4(%esp)
f0100c33:	00 
f0100c34:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0100c3b:	e8 76 f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c40:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c45:	75 24                	jne    f0100c6b <check_page_free_list+0x229>
f0100c47:	c7 44 24 0c 4c 57 10 	movl   $0xf010574c,0xc(%esp)
f0100c4e:	f0 
f0100c4f:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0100c56:	f0 
f0100c57:	c7 44 24 04 8c 02 00 	movl   $0x28c,0x4(%esp)
f0100c5e:	00 
f0100c5f:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0100c66:	e8 4b f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c6b:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c70:	75 24                	jne    f0100c96 <check_page_free_list+0x254>
f0100c72:	c7 44 24 0c 1c 5f 10 	movl   $0xf0105f1c,0xc(%esp)
f0100c79:	f0 
f0100c7a:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0100c81:	f0 
f0100c82:	c7 44 24 04 8d 02 00 	movl   $0x28d,0x4(%esp)
f0100c89:	00 
f0100c8a:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0100c91:	e8 20 f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c96:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100c9b:	76 58                	jbe    f0100cf5 <check_page_free_list+0x2b3>
	if (PGNUM(pa) >= npages)
f0100c9d:	89 c1                	mov    %eax,%ecx
f0100c9f:	c1 e9 0c             	shr    $0xc,%ecx
f0100ca2:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100ca5:	77 20                	ja     f0100cc7 <check_page_free_list+0x285>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ca7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100cab:	c7 44 24 08 d0 56 10 	movl   $0xf01056d0,0x8(%esp)
f0100cb2:	f0 
f0100cb3:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100cba:	00 
f0100cbb:	c7 04 24 af 5e 10 f0 	movl   $0xf0105eaf,(%esp)
f0100cc2:	e8 ef f3 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0100cc7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ccc:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100ccf:	76 29                	jbe    f0100cfa <check_page_free_list+0x2b8>
f0100cd1:	c7 44 24 0c 70 57 10 	movl   $0xf0105770,0xc(%esp)
f0100cd8:	f0 
f0100cd9:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0100ce0:	f0 
f0100ce1:	c7 44 24 04 8e 02 00 	movl   $0x28e,0x4(%esp)
f0100ce8:	00 
f0100ce9:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0100cf0:	e8 c1 f3 ff ff       	call   f01000b6 <_panic>
			++nfree_basemem;
f0100cf5:	83 c3 01             	add    $0x1,%ebx
f0100cf8:	eb 03                	jmp    f0100cfd <check_page_free_list+0x2bb>
			++nfree_extmem;
f0100cfa:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cfd:	8b 12                	mov    (%edx),%edx
f0100cff:	85 d2                	test   %edx,%edx
f0100d01:	0f 85 61 fe ff ff    	jne    f0100b68 <check_page_free_list+0x126>
	assert(nfree_basemem > 0);
f0100d07:	85 db                	test   %ebx,%ebx
f0100d09:	7f 24                	jg     f0100d2f <check_page_free_list+0x2ed>
f0100d0b:	c7 44 24 0c 36 5f 10 	movl   $0xf0105f36,0xc(%esp)
f0100d12:	f0 
f0100d13:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0100d1a:	f0 
f0100d1b:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
f0100d22:	00 
f0100d23:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0100d2a:	e8 87 f3 ff ff       	call   f01000b6 <_panic>
	assert(nfree_extmem > 0);
f0100d2f:	85 ff                	test   %edi,%edi
f0100d31:	7f 4d                	jg     f0100d80 <check_page_free_list+0x33e>
f0100d33:	c7 44 24 0c 48 5f 10 	movl   $0xf0105f48,0xc(%esp)
f0100d3a:	f0 
f0100d3b:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0100d42:	f0 
f0100d43:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
f0100d4a:	00 
f0100d4b:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0100d52:	e8 5f f3 ff ff       	call   f01000b6 <_panic>
	if (!page_free_list)
f0100d57:	a1 80 df 17 f0       	mov    0xf017df80,%eax
f0100d5c:	85 c0                	test   %eax,%eax
f0100d5e:	0f 85 10 fd ff ff    	jne    f0100a74 <check_page_free_list+0x32>
f0100d64:	e9 ef fc ff ff       	jmp    f0100a58 <check_page_free_list+0x16>
f0100d69:	83 3d 80 df 17 f0 00 	cmpl   $0x0,0xf017df80
f0100d70:	0f 84 e2 fc ff ff    	je     f0100a58 <check_page_free_list+0x16>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d76:	be 00 04 00 00       	mov    $0x400,%esi
f0100d7b:	e9 42 fd ff ff       	jmp    f0100ac2 <check_page_free_list+0x80>
}
f0100d80:	83 c4 4c             	add    $0x4c,%esp
f0100d83:	5b                   	pop    %ebx
f0100d84:	5e                   	pop    %esi
f0100d85:	5f                   	pop    %edi
f0100d86:	5d                   	pop    %ebp
f0100d87:	c3                   	ret    

f0100d88 <page_init>:
{
f0100d88:	55                   	push   %ebp
f0100d89:	89 e5                	mov    %esp,%ebp
f0100d8b:	56                   	push   %esi
f0100d8c:	53                   	push   %ebx
f0100d8d:	83 ec 10             	sub    $0x10,%esp
	pages[0].pp_ref = 1;
f0100d90:	a1 2c ec 17 f0       	mov    0xf017ec2c,%eax
f0100d95:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	for(i = 1; i < npages_basemem; i++) {
f0100d9b:	8b 35 78 df 17 f0    	mov    0xf017df78,%esi
f0100da1:	8b 1d 80 df 17 f0    	mov    0xf017df80,%ebx
f0100da7:	b8 01 00 00 00       	mov    $0x1,%eax
f0100dac:	eb 22                	jmp    f0100dd0 <page_init+0x48>
page_init(void)
f0100dae:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100db5:	8b 0d 2c ec 17 f0    	mov    0xf017ec2c,%ecx
f0100dbb:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = page_free_list;
f0100dc2:	89 1c c1             	mov    %ebx,(%ecx,%eax,8)
		page_free_list = &pages[i];
f0100dc5:	8b 1d 2c ec 17 f0    	mov    0xf017ec2c,%ebx
f0100dcb:	01 d3                	add    %edx,%ebx
	for(i = 1; i < npages_basemem; i++) {
f0100dcd:	83 c0 01             	add    $0x1,%eax
f0100dd0:	39 f0                	cmp    %esi,%eax
f0100dd2:	72 da                	jb     f0100dae <page_init+0x26>
f0100dd4:	89 1d 80 df 17 f0    	mov    %ebx,0xf017df80
		pages[i].pp_ref = 1;
f0100dda:	a1 2c ec 17 f0       	mov    0xf017ec2c,%eax
f0100ddf:	bb a0 00 00 00       	mov    $0xa0,%ebx
f0100de4:	66 c7 44 d8 04 01 00 	movw   $0x1,0x4(%eax,%ebx,8)
	for(i = IO_PHY; i < EXT_PHY; i++) {
f0100deb:	83 c3 01             	add    $0x1,%ebx
f0100dee:	81 fb 00 01 00 00    	cmp    $0x100,%ebx
f0100df4:	75 ee                	jne    f0100de4 <page_init+0x5c>
	size_t first_free_page_address = PADDR(boot_alloc(0))/PGSIZE;
f0100df6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dfb:	e8 af fb ff ff       	call   f01009af <boot_alloc>
	if ((uint32_t)kva < KERNBASE)
f0100e00:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100e05:	77 20                	ja     f0100e27 <page_init+0x9f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100e07:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e0b:	c7 44 24 08 b8 57 10 	movl   $0xf01057b8,0x8(%esp)
f0100e12:	f0 
f0100e13:	c7 44 24 04 20 01 00 	movl   $0x120,0x4(%esp)
f0100e1a:	00 
f0100e1b:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0100e22:	e8 8f f2 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100e27:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100e2d:	c1 ea 0c             	shr    $0xc,%edx
		pages[i].pp_ref = 1;
f0100e30:	a1 2c ec 17 f0       	mov    0xf017ec2c,%eax
	for(i = EXT_PHY; i < first_free_page_address; i++) {
f0100e35:	eb 0a                	jmp    f0100e41 <page_init+0xb9>
		pages[i].pp_ref = 1;
f0100e37:	66 c7 44 d8 04 01 00 	movw   $0x1,0x4(%eax,%ebx,8)
	for(i = EXT_PHY; i < first_free_page_address; i++) {
f0100e3e:	83 c3 01             	add    $0x1,%ebx
f0100e41:	39 d3                	cmp    %edx,%ebx
f0100e43:	72 f2                	jb     f0100e37 <page_init+0xaf>
f0100e45:	8b 1d 80 df 17 f0    	mov    0xf017df80,%ebx
f0100e4b:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
f0100e52:	eb 1e                	jmp    f0100e72 <page_init+0xea>
		pages[i].pp_ref = 0;
f0100e54:	8b 0d 2c ec 17 f0    	mov    0xf017ec2c,%ecx
f0100e5a:	66 c7 44 01 04 00 00 	movw   $0x0,0x4(%ecx,%eax,1)
		pages[i].pp_link = page_free_list;
f0100e61:	89 1c 01             	mov    %ebx,(%ecx,%eax,1)
		page_free_list = &pages[i];
f0100e64:	8b 1d 2c ec 17 f0    	mov    0xf017ec2c,%ebx
f0100e6a:	01 c3                	add    %eax,%ebx
	for (i = first_free_page_address; i < npages; i++) {
f0100e6c:	83 c2 01             	add    $0x1,%edx
f0100e6f:	83 c0 08             	add    $0x8,%eax
f0100e72:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0100e78:	72 da                	jb     f0100e54 <page_init+0xcc>
f0100e7a:	89 1d 80 df 17 f0    	mov    %ebx,0xf017df80
}
f0100e80:	83 c4 10             	add    $0x10,%esp
f0100e83:	5b                   	pop    %ebx
f0100e84:	5e                   	pop    %esi
f0100e85:	5d                   	pop    %ebp
f0100e86:	c3                   	ret    

f0100e87 <page_alloc>:
{
f0100e87:	55                   	push   %ebp
f0100e88:	89 e5                	mov    %esp,%ebp
f0100e8a:	53                   	push   %ebx
f0100e8b:	83 ec 14             	sub    $0x14,%esp
	if (page_free_list == NULL) {
f0100e8e:	8b 1d 80 df 17 f0    	mov    0xf017df80,%ebx
f0100e94:	85 db                	test   %ebx,%ebx
f0100e96:	74 6b                	je     f0100f03 <page_alloc+0x7c>
	page_free_list = allocated_page->pp_link;
f0100e98:	8b 03                	mov    (%ebx),%eax
f0100e9a:	a3 80 df 17 f0       	mov    %eax,0xf017df80
	allocated_page->pp_link = NULL;
f0100e9f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO) {
f0100ea5:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ea9:	74 58                	je     f0100f03 <page_alloc+0x7c>
	return (pp - pages) << PGSHIFT;
f0100eab:	89 d8                	mov    %ebx,%eax
f0100ead:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0100eb3:	c1 f8 03             	sar    $0x3,%eax
f0100eb6:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100eb9:	89 c2                	mov    %eax,%edx
f0100ebb:	c1 ea 0c             	shr    $0xc,%edx
f0100ebe:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0100ec4:	72 20                	jb     f0100ee6 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ec6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100eca:	c7 44 24 08 d0 56 10 	movl   $0xf01056d0,0x8(%esp)
f0100ed1:	f0 
f0100ed2:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100ed9:	00 
f0100eda:	c7 04 24 af 5e 10 f0 	movl   $0xf0105eaf,(%esp)
f0100ee1:	e8 d0 f1 ff ff       	call   f01000b6 <_panic>
		memset(page2kva(allocated_page), '\0', PGSIZE);
f0100ee6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100eed:	00 
f0100eee:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100ef5:	00 
	return (void *)(pa + KERNBASE);
f0100ef6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100efb:	89 04 24             	mov    %eax,(%esp)
f0100efe:	e8 f0 3d 00 00       	call   f0104cf3 <memset>
}
f0100f03:	89 d8                	mov    %ebx,%eax
f0100f05:	83 c4 14             	add    $0x14,%esp
f0100f08:	5b                   	pop    %ebx
f0100f09:	5d                   	pop    %ebp
f0100f0a:	c3                   	ret    

f0100f0b <page_free>:
{
f0100f0b:	55                   	push   %ebp
f0100f0c:	89 e5                	mov    %esp,%ebp
f0100f0e:	83 ec 18             	sub    $0x18,%esp
f0100f11:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_ref != 0 || pp->pp_link != NULL) {
f0100f14:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f19:	75 05                	jne    f0100f20 <page_free+0x15>
f0100f1b:	83 38 00             	cmpl   $0x0,(%eax)
f0100f1e:	74 1c                	je     f0100f3c <page_free+0x31>
		panic("The page can not be free ");
f0100f20:	c7 44 24 08 59 5f 10 	movl   $0xf0105f59,0x8(%esp)
f0100f27:	f0 
f0100f28:	c7 44 24 04 55 01 00 	movl   $0x155,0x4(%esp)
f0100f2f:	00 
f0100f30:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0100f37:	e8 7a f1 ff ff       	call   f01000b6 <_panic>
	pp->pp_link = page_free_list;
f0100f3c:	8b 15 80 df 17 f0    	mov    0xf017df80,%edx
f0100f42:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f44:	a3 80 df 17 f0       	mov    %eax,0xf017df80
}
f0100f49:	c9                   	leave  
f0100f4a:	c3                   	ret    

f0100f4b <page_decref>:
{
f0100f4b:	55                   	push   %ebp
f0100f4c:	89 e5                	mov    %esp,%ebp
f0100f4e:	83 ec 18             	sub    $0x18,%esp
f0100f51:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100f54:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0100f58:	83 ea 01             	sub    $0x1,%edx
f0100f5b:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100f5f:	66 85 d2             	test   %dx,%dx
f0100f62:	75 08                	jne    f0100f6c <page_decref+0x21>
		page_free(pp);
f0100f64:	89 04 24             	mov    %eax,(%esp)
f0100f67:	e8 9f ff ff ff       	call   f0100f0b <page_free>
}
f0100f6c:	c9                   	leave  
f0100f6d:	c3                   	ret    

f0100f6e <pgdir_walk>:
{
f0100f6e:	55                   	push   %ebp
f0100f6f:	89 e5                	mov    %esp,%ebp
f0100f71:	56                   	push   %esi
f0100f72:	53                   	push   %ebx
f0100f73:	83 ec 10             	sub    $0x10,%esp
f0100f76:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	uint32_t pg_tab_idx = PTX(va);
f0100f79:	89 de                	mov    %ebx,%esi
f0100f7b:	c1 ee 0c             	shr    $0xc,%esi
f0100f7e:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	uint32_t pg_dir_idx = PDX(va);
f0100f84:	c1 eb 16             	shr    $0x16,%ebx
	if (pgdir[pg_dir_idx] & PTE_P) {
f0100f87:	c1 e3 02             	shl    $0x2,%ebx
f0100f8a:	03 5d 08             	add    0x8(%ebp),%ebx
f0100f8d:	f6 03 01             	testb  $0x1,(%ebx)
f0100f90:	75 2c                	jne    f0100fbe <pgdir_walk+0x50>
		if (!create) {
f0100f92:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100f96:	74 63                	je     f0100ffb <pgdir_walk+0x8d>
		       struct PageInfo *page = page_alloc(ALLOC_ZERO);
f0100f98:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100f9f:	e8 e3 fe ff ff       	call   f0100e87 <page_alloc>
		       if(!page) {
f0100fa4:	85 c0                	test   %eax,%eax
f0100fa6:	74 5a                	je     f0101002 <pgdir_walk+0x94>
		       page->pp_ref += 1;
f0100fa8:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0100fad:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0100fb3:	c1 f8 03             	sar    $0x3,%eax
f0100fb6:	c1 e0 0c             	shl    $0xc,%eax
		       pgdir[pg_dir_idx] = page2pa(page) | PTE_P | PTE_W | PTE_U;
f0100fb9:	83 c8 07             	or     $0x7,%eax
f0100fbc:	89 03                	mov    %eax,(%ebx)
	pg_addr_tab = KADDR(PTE_ADDR(pgdir[pg_dir_idx]));
f0100fbe:	8b 03                	mov    (%ebx),%eax
f0100fc0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0100fc5:	89 c2                	mov    %eax,%edx
f0100fc7:	c1 ea 0c             	shr    $0xc,%edx
f0100fca:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0100fd0:	72 20                	jb     f0100ff2 <pgdir_walk+0x84>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fd2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fd6:	c7 44 24 08 d0 56 10 	movl   $0xf01056d0,0x8(%esp)
f0100fdd:	f0 
f0100fde:	c7 44 24 04 91 01 00 	movl   $0x191,0x4(%esp)
f0100fe5:	00 
f0100fe6:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0100fed:	e8 c4 f0 ff ff       	call   f01000b6 <_panic>
	return &pg_addr_tab[pg_tab_idx];
f0100ff2:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100ff9:	eb 0c                	jmp    f0101007 <pgdir_walk+0x99>
				return NULL;
f0100ffb:	b8 00 00 00 00       	mov    $0x0,%eax
f0101000:	eb 05                	jmp    f0101007 <pgdir_walk+0x99>
					return NULL;
f0101002:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101007:	83 c4 10             	add    $0x10,%esp
f010100a:	5b                   	pop    %ebx
f010100b:	5e                   	pop    %esi
f010100c:	5d                   	pop    %ebp
f010100d:	c3                   	ret    

f010100e <boot_map_region>:
{
f010100e:	55                   	push   %ebp
f010100f:	89 e5                	mov    %esp,%ebp
f0101011:	57                   	push   %edi
f0101012:	56                   	push   %esi
f0101013:	53                   	push   %ebx
f0101014:	83 ec 2c             	sub    $0x2c,%esp
f0101017:	89 c7                	mov    %eax,%edi
f0101019:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010101c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
	for (add_size = 0; add_size < size ; add_size += PGSIZE) {
f010101f:	bb 00 00 00 00       	mov    $0x0,%ebx
		*pg_pte = pa | perm | PTE_P;
f0101024:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101027:	83 c8 01             	or     $0x1,%eax
f010102a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (add_size = 0; add_size < size ; add_size += PGSIZE) {
f010102d:	eb 44                	jmp    f0101073 <boot_map_region+0x65>
		pg_pte = pgdir_walk(pgdir,(void*)va,1);
f010102f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101036:	00 
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f0101037:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010103a:	01 d8                	add    %ebx,%eax
		pg_pte = pgdir_walk(pgdir,(void*)va,1);
f010103c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101040:	89 3c 24             	mov    %edi,(%esp)
f0101043:	e8 26 ff ff ff       	call   f0100f6e <pgdir_walk>
		if (!pg_pte) {
f0101048:	85 c0                	test   %eax,%eax
f010104a:	75 1c                	jne    f0101068 <boot_map_region+0x5a>
				panic("Wrong,out of memory! \n");
f010104c:	c7 44 24 08 73 5f 10 	movl   $0xf0105f73,0x8(%esp)
f0101053:	f0 
f0101054:	c7 44 24 04 a8 01 00 	movl   $0x1a8,0x4(%esp)
f010105b:	00 
f010105c:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101063:	e8 4e f0 ff ff       	call   f01000b6 <_panic>
		*pg_pte = pa | perm | PTE_P;
f0101068:	0b 75 e4             	or     -0x1c(%ebp),%esi
f010106b:	89 30                	mov    %esi,(%eax)
	for (add_size = 0; add_size < size ; add_size += PGSIZE) {
f010106d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f0101073:	8b 75 08             	mov    0x8(%ebp),%esi
f0101076:	01 de                	add    %ebx,%esi
	for (add_size = 0; add_size < size ; add_size += PGSIZE) {
f0101078:	39 5d e0             	cmp    %ebx,-0x20(%ebp)
f010107b:	77 b2                	ja     f010102f <boot_map_region+0x21>
}
f010107d:	83 c4 2c             	add    $0x2c,%esp
f0101080:	5b                   	pop    %ebx
f0101081:	5e                   	pop    %esi
f0101082:	5f                   	pop    %edi
f0101083:	5d                   	pop    %ebp
f0101084:	c3                   	ret    

f0101085 <page_lookup>:
{
f0101085:	55                   	push   %ebp
f0101086:	89 e5                	mov    %esp,%ebp
f0101088:	53                   	push   %ebx
f0101089:	83 ec 14             	sub    $0x14,%esp
f010108c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pg_pte = pgdir_walk(pgdir, va, 0);
f010108f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101096:	00 
f0101097:	8b 45 0c             	mov    0xc(%ebp),%eax
f010109a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010109e:	8b 45 08             	mov    0x8(%ebp),%eax
f01010a1:	89 04 24             	mov    %eax,(%esp)
f01010a4:	e8 c5 fe ff ff       	call   f0100f6e <pgdir_walk>
	if (!pg_pte) {
f01010a9:	85 c0                	test   %eax,%eax
f01010ab:	74 3a                	je     f01010e7 <page_lookup+0x62>
		if (pte_store) {
f01010ad:	85 db                	test   %ebx,%ebx
f01010af:	74 02                	je     f01010b3 <page_lookup+0x2e>
	       		*pte_store = pg_pte;
f01010b1:	89 03                	mov    %eax,(%ebx)
		return pa2page(PTE_ADDR(*pg_pte));
f01010b3:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010b5:	c1 e8 0c             	shr    $0xc,%eax
f01010b8:	3b 05 24 ec 17 f0    	cmp    0xf017ec24,%eax
f01010be:	72 1c                	jb     f01010dc <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f01010c0:	c7 44 24 08 dc 57 10 	movl   $0xf01057dc,0x8(%esp)
f01010c7:	f0 
f01010c8:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f01010cf:	00 
f01010d0:	c7 04 24 af 5e 10 f0 	movl   $0xf0105eaf,(%esp)
f01010d7:	e8 da ef ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f01010dc:	8b 15 2c ec 17 f0    	mov    0xf017ec2c,%edx
f01010e2:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01010e5:	eb 05                	jmp    f01010ec <page_lookup+0x67>
		return NULL;
f01010e7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01010ec:	83 c4 14             	add    $0x14,%esp
f01010ef:	5b                   	pop    %ebx
f01010f0:	5d                   	pop    %ebp
f01010f1:	c3                   	ret    

f01010f2 <tlb_invalidate>:
{
f01010f2:	55                   	push   %ebp
f01010f3:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01010f5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010f8:	0f 01 38             	invlpg (%eax)
}
f01010fb:	5d                   	pop    %ebp
f01010fc:	c3                   	ret    

f01010fd <page_remove>:
{
f01010fd:	55                   	push   %ebp
f01010fe:	89 e5                	mov    %esp,%ebp
f0101100:	83 ec 28             	sub    $0x28,%esp
f0101103:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0101106:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0101109:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010110c:	8b 75 0c             	mov    0xc(%ebp),%esi
	struct PageInfo *pginfo = page_lookup(pgdir, va, &pg_pte);
f010110f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101112:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101116:	89 74 24 04          	mov    %esi,0x4(%esp)
f010111a:	89 1c 24             	mov    %ebx,(%esp)
f010111d:	e8 63 ff ff ff       	call   f0101085 <page_lookup>
	if (!pginfo) {
f0101122:	85 c0                	test   %eax,%eax
f0101124:	74 1d                	je     f0101143 <page_remove+0x46>
	page_decref(pginfo);
f0101126:	89 04 24             	mov    %eax,(%esp)
f0101129:	e8 1d fe ff ff       	call   f0100f4b <page_decref>
	*pg_pte = 0;
f010112e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101131:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f0101137:	89 74 24 04          	mov    %esi,0x4(%esp)
f010113b:	89 1c 24             	mov    %ebx,(%esp)
f010113e:	e8 af ff ff ff       	call   f01010f2 <tlb_invalidate>
}
f0101143:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0101146:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0101149:	89 ec                	mov    %ebp,%esp
f010114b:	5d                   	pop    %ebp
f010114c:	c3                   	ret    

f010114d <page_insert>:
{
f010114d:	55                   	push   %ebp
f010114e:	89 e5                	mov    %esp,%ebp
f0101150:	83 ec 28             	sub    $0x28,%esp
f0101153:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0101156:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101159:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010115c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010115f:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pg_pte = pgdir_walk(pgdir, va, 1);
f0101162:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101169:	00 
f010116a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010116e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101171:	89 04 24             	mov    %eax,(%esp)
f0101174:	e8 f5 fd ff ff       	call   f0100f6e <pgdir_walk>
f0101179:	89 c3                	mov    %eax,%ebx
	if (!pg_pte) {
f010117b:	85 c0                	test   %eax,%eax
f010117d:	74 36                	je     f01011b5 <page_insert+0x68>
	pp->pp_ref++;
f010117f:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	if (*pg_pte & PTE_P) {
f0101184:	f6 00 01             	testb  $0x1,(%eax)
f0101187:	74 0f                	je     f0101198 <page_insert+0x4b>
		page_remove(pgdir, va);
f0101189:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010118d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101190:	89 04 24             	mov    %eax,(%esp)
f0101193:	e8 65 ff ff ff       	call   f01010fd <page_remove>
	*pg_pte = page2pa(pp) | perm | PTE_P;
f0101198:	8b 45 14             	mov    0x14(%ebp),%eax
f010119b:	83 c8 01             	or     $0x1,%eax
	return (pp - pages) << PGSHIFT;
f010119e:	2b 35 2c ec 17 f0    	sub    0xf017ec2c,%esi
f01011a4:	c1 fe 03             	sar    $0x3,%esi
f01011a7:	c1 e6 0c             	shl    $0xc,%esi
f01011aa:	09 c6                	or     %eax,%esi
f01011ac:	89 33                	mov    %esi,(%ebx)
	return 0;
f01011ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01011b3:	eb 05                	jmp    f01011ba <page_insert+0x6d>
		return -E_NO_MEM;
f01011b5:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f01011ba:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01011bd:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01011c0:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01011c3:	89 ec                	mov    %ebp,%esp
f01011c5:	5d                   	pop    %ebp
f01011c6:	c3                   	ret    

f01011c7 <mem_init>:
{
f01011c7:	55                   	push   %ebp
f01011c8:	89 e5                	mov    %esp,%ebp
f01011ca:	57                   	push   %edi
f01011cb:	56                   	push   %esi
f01011cc:	53                   	push   %ebx
f01011cd:	83 ec 3c             	sub    $0x3c,%esp
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01011d0:	b8 15 00 00 00       	mov    $0x15,%eax
f01011d5:	e8 36 f8 ff ff       	call   f0100a10 <nvram_read>
f01011da:	c1 e0 0a             	shl    $0xa,%eax
f01011dd:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01011e3:	85 c0                	test   %eax,%eax
f01011e5:	0f 48 c2             	cmovs  %edx,%eax
f01011e8:	c1 f8 0c             	sar    $0xc,%eax
f01011eb:	a3 78 df 17 f0       	mov    %eax,0xf017df78
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01011f0:	b8 17 00 00 00       	mov    $0x17,%eax
f01011f5:	e8 16 f8 ff ff       	call   f0100a10 <nvram_read>
f01011fa:	c1 e0 0a             	shl    $0xa,%eax
f01011fd:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101203:	85 c0                	test   %eax,%eax
f0101205:	0f 48 c2             	cmovs  %edx,%eax
f0101208:	c1 f8 0c             	sar    $0xc,%eax
	if (npages_extmem)
f010120b:	85 c0                	test   %eax,%eax
f010120d:	74 0e                	je     f010121d <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010120f:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101215:	89 15 24 ec 17 f0    	mov    %edx,0xf017ec24
f010121b:	eb 0c                	jmp    f0101229 <mem_init+0x62>
		npages = npages_basemem;
f010121d:	8b 15 78 df 17 f0    	mov    0xf017df78,%edx
f0101223:	89 15 24 ec 17 f0    	mov    %edx,0xf017ec24
		npages_extmem * PGSIZE / 1024);
f0101229:	c1 e0 0c             	shl    $0xc,%eax
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010122c:	c1 e8 0a             	shr    $0xa,%eax
f010122f:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages_basemem * PGSIZE / 1024,
f0101233:	a1 78 df 17 f0       	mov    0xf017df78,%eax
f0101238:	c1 e0 0c             	shl    $0xc,%eax
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010123b:	c1 e8 0a             	shr    $0xa,%eax
f010123e:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0101242:	a1 24 ec 17 f0       	mov    0xf017ec24,%eax
f0101247:	c1 e0 0c             	shl    $0xc,%eax
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010124a:	c1 e8 0a             	shr    $0xa,%eax
f010124d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101251:	c7 04 24 fc 57 10 f0 	movl   $0xf01057fc,(%esp)
f0101258:	e8 2f 25 00 00       	call   f010378c <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010125d:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101262:	e8 48 f7 ff ff       	call   f01009af <boot_alloc>
f0101267:	a3 28 ec 17 f0       	mov    %eax,0xf017ec28
	memset(kern_pgdir, 0, PGSIZE);
f010126c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101273:	00 
f0101274:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010127b:	00 
f010127c:	89 04 24             	mov    %eax,(%esp)
f010127f:	e8 6f 3a 00 00       	call   f0104cf3 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101284:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
	if ((uint32_t)kva < KERNBASE)
f0101289:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010128e:	77 20                	ja     f01012b0 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101290:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101294:	c7 44 24 08 b8 57 10 	movl   $0xf01057b8,0x8(%esp)
f010129b:	f0 
f010129c:	c7 44 24 04 99 00 00 	movl   $0x99,0x4(%esp)
f01012a3:	00 
f01012a4:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01012ab:	e8 06 ee ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01012b0:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01012b6:	83 ca 05             	or     $0x5,%edx
f01012b9:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
        pages = (struct PageInfo *) boot_alloc(sizeof(struct PageInfo)* npages);
f01012bf:	a1 24 ec 17 f0       	mov    0xf017ec24,%eax
f01012c4:	c1 e0 03             	shl    $0x3,%eax
f01012c7:	e8 e3 f6 ff ff       	call   f01009af <boot_alloc>
f01012cc:	a3 2c ec 17 f0       	mov    %eax,0xf017ec2c
	memset(pages,0,sizeof(struct PageInfo)* npages);
f01012d1:	8b 15 24 ec 17 f0    	mov    0xf017ec24,%edx
f01012d7:	c1 e2 03             	shl    $0x3,%edx
f01012da:	89 54 24 08          	mov    %edx,0x8(%esp)
f01012de:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012e5:	00 
f01012e6:	89 04 24             	mov    %eax,(%esp)
f01012e9:	e8 05 3a 00 00       	call   f0104cf3 <memset>
	envs = (struct Env *) boot_alloc(sizeof(struct Env)* NENV);
f01012ee:	b8 00 80 01 00       	mov    $0x18000,%eax
f01012f3:	e8 b7 f6 ff ff       	call   f01009af <boot_alloc>
f01012f8:	a3 8c df 17 f0       	mov    %eax,0xf017df8c
	memset(envs,0,sizeof(struct Env)* NENV);
f01012fd:	c7 44 24 08 00 80 01 	movl   $0x18000,0x8(%esp)
f0101304:	00 
f0101305:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010130c:	00 
f010130d:	89 04 24             	mov    %eax,(%esp)
f0101310:	e8 de 39 00 00       	call   f0104cf3 <memset>
	page_init();
f0101315:	e8 6e fa ff ff       	call   f0100d88 <page_init>
	check_page_free_list(1);
f010131a:	b8 01 00 00 00       	mov    $0x1,%eax
f010131f:	e8 1e f7 ff ff       	call   f0100a42 <check_page_free_list>
	if (!pages)
f0101324:	83 3d 2c ec 17 f0 00 	cmpl   $0x0,0xf017ec2c
f010132b:	75 1c                	jne    f0101349 <mem_init+0x182>
		panic("'pages' is a null pointer!");
f010132d:	c7 44 24 08 8a 5f 10 	movl   $0xf0105f8a,0x8(%esp)
f0101334:	f0 
f0101335:	c7 44 24 04 a8 02 00 	movl   $0x2a8,0x4(%esp)
f010133c:	00 
f010133d:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101344:	e8 6d ed ff ff       	call   f01000b6 <_panic>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101349:	a1 80 df 17 f0       	mov    0xf017df80,%eax
f010134e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101353:	eb 05                	jmp    f010135a <mem_init+0x193>
		++nfree;
f0101355:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101358:	8b 00                	mov    (%eax),%eax
f010135a:	85 c0                	test   %eax,%eax
f010135c:	75 f7                	jne    f0101355 <mem_init+0x18e>
	assert((pp0 = page_alloc(0)));
f010135e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101365:	e8 1d fb ff ff       	call   f0100e87 <page_alloc>
f010136a:	89 c7                	mov    %eax,%edi
f010136c:	85 c0                	test   %eax,%eax
f010136e:	75 24                	jne    f0101394 <mem_init+0x1cd>
f0101370:	c7 44 24 0c a5 5f 10 	movl   $0xf0105fa5,0xc(%esp)
f0101377:	f0 
f0101378:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f010137f:	f0 
f0101380:	c7 44 24 04 b0 02 00 	movl   $0x2b0,0x4(%esp)
f0101387:	00 
f0101388:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f010138f:	e8 22 ed ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101394:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010139b:	e8 e7 fa ff ff       	call   f0100e87 <page_alloc>
f01013a0:	89 c6                	mov    %eax,%esi
f01013a2:	85 c0                	test   %eax,%eax
f01013a4:	75 24                	jne    f01013ca <mem_init+0x203>
f01013a6:	c7 44 24 0c bb 5f 10 	movl   $0xf0105fbb,0xc(%esp)
f01013ad:	f0 
f01013ae:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01013b5:	f0 
f01013b6:	c7 44 24 04 b1 02 00 	movl   $0x2b1,0x4(%esp)
f01013bd:	00 
f01013be:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01013c5:	e8 ec ec ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f01013ca:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013d1:	e8 b1 fa ff ff       	call   f0100e87 <page_alloc>
f01013d6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013d9:	85 c0                	test   %eax,%eax
f01013db:	75 24                	jne    f0101401 <mem_init+0x23a>
f01013dd:	c7 44 24 0c d1 5f 10 	movl   $0xf0105fd1,0xc(%esp)
f01013e4:	f0 
f01013e5:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01013ec:	f0 
f01013ed:	c7 44 24 04 b2 02 00 	movl   $0x2b2,0x4(%esp)
f01013f4:	00 
f01013f5:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01013fc:	e8 b5 ec ff ff       	call   f01000b6 <_panic>
	assert(pp1 && pp1 != pp0);
f0101401:	39 f7                	cmp    %esi,%edi
f0101403:	75 24                	jne    f0101429 <mem_init+0x262>
f0101405:	c7 44 24 0c e7 5f 10 	movl   $0xf0105fe7,0xc(%esp)
f010140c:	f0 
f010140d:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101414:	f0 
f0101415:	c7 44 24 04 b5 02 00 	movl   $0x2b5,0x4(%esp)
f010141c:	00 
f010141d:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101424:	e8 8d ec ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101429:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010142c:	74 05                	je     f0101433 <mem_init+0x26c>
f010142e:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101431:	75 24                	jne    f0101457 <mem_init+0x290>
f0101433:	c7 44 24 0c 38 58 10 	movl   $0xf0105838,0xc(%esp)
f010143a:	f0 
f010143b:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101442:	f0 
f0101443:	c7 44 24 04 b6 02 00 	movl   $0x2b6,0x4(%esp)
f010144a:	00 
f010144b:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101452:	e8 5f ec ff ff       	call   f01000b6 <_panic>
	return (pp - pages) << PGSHIFT;
f0101457:	8b 15 2c ec 17 f0    	mov    0xf017ec2c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010145d:	a1 24 ec 17 f0       	mov    0xf017ec24,%eax
f0101462:	c1 e0 0c             	shl    $0xc,%eax
f0101465:	89 f9                	mov    %edi,%ecx
f0101467:	29 d1                	sub    %edx,%ecx
f0101469:	c1 f9 03             	sar    $0x3,%ecx
f010146c:	c1 e1 0c             	shl    $0xc,%ecx
f010146f:	39 c1                	cmp    %eax,%ecx
f0101471:	72 24                	jb     f0101497 <mem_init+0x2d0>
f0101473:	c7 44 24 0c f9 5f 10 	movl   $0xf0105ff9,0xc(%esp)
f010147a:	f0 
f010147b:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101482:	f0 
f0101483:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
f010148a:	00 
f010148b:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101492:	e8 1f ec ff ff       	call   f01000b6 <_panic>
f0101497:	89 f1                	mov    %esi,%ecx
f0101499:	29 d1                	sub    %edx,%ecx
f010149b:	c1 f9 03             	sar    $0x3,%ecx
f010149e:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01014a1:	39 c8                	cmp    %ecx,%eax
f01014a3:	77 24                	ja     f01014c9 <mem_init+0x302>
f01014a5:	c7 44 24 0c 16 60 10 	movl   $0xf0106016,0xc(%esp)
f01014ac:	f0 
f01014ad:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01014b4:	f0 
f01014b5:	c7 44 24 04 b8 02 00 	movl   $0x2b8,0x4(%esp)
f01014bc:	00 
f01014bd:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01014c4:	e8 ed eb ff ff       	call   f01000b6 <_panic>
f01014c9:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01014cc:	29 d1                	sub    %edx,%ecx
f01014ce:	89 ca                	mov    %ecx,%edx
f01014d0:	c1 fa 03             	sar    $0x3,%edx
f01014d3:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01014d6:	39 d0                	cmp    %edx,%eax
f01014d8:	77 24                	ja     f01014fe <mem_init+0x337>
f01014da:	c7 44 24 0c 33 60 10 	movl   $0xf0106033,0xc(%esp)
f01014e1:	f0 
f01014e2:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01014e9:	f0 
f01014ea:	c7 44 24 04 b9 02 00 	movl   $0x2b9,0x4(%esp)
f01014f1:	00 
f01014f2:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01014f9:	e8 b8 eb ff ff       	call   f01000b6 <_panic>
	fl = page_free_list;
f01014fe:	a1 80 df 17 f0       	mov    0xf017df80,%eax
f0101503:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101506:	c7 05 80 df 17 f0 00 	movl   $0x0,0xf017df80
f010150d:	00 00 00 
	assert(!page_alloc(0));
f0101510:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101517:	e8 6b f9 ff ff       	call   f0100e87 <page_alloc>
f010151c:	85 c0                	test   %eax,%eax
f010151e:	74 24                	je     f0101544 <mem_init+0x37d>
f0101520:	c7 44 24 0c 50 60 10 	movl   $0xf0106050,0xc(%esp)
f0101527:	f0 
f0101528:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f010152f:	f0 
f0101530:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
f0101537:	00 
f0101538:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f010153f:	e8 72 eb ff ff       	call   f01000b6 <_panic>
	page_free(pp0);
f0101544:	89 3c 24             	mov    %edi,(%esp)
f0101547:	e8 bf f9 ff ff       	call   f0100f0b <page_free>
	page_free(pp1);
f010154c:	89 34 24             	mov    %esi,(%esp)
f010154f:	e8 b7 f9 ff ff       	call   f0100f0b <page_free>
	page_free(pp2);
f0101554:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101557:	89 04 24             	mov    %eax,(%esp)
f010155a:	e8 ac f9 ff ff       	call   f0100f0b <page_free>
	assert((pp0 = page_alloc(0)));
f010155f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101566:	e8 1c f9 ff ff       	call   f0100e87 <page_alloc>
f010156b:	89 c6                	mov    %eax,%esi
f010156d:	85 c0                	test   %eax,%eax
f010156f:	75 24                	jne    f0101595 <mem_init+0x3ce>
f0101571:	c7 44 24 0c a5 5f 10 	movl   $0xf0105fa5,0xc(%esp)
f0101578:	f0 
f0101579:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101580:	f0 
f0101581:	c7 44 24 04 c7 02 00 	movl   $0x2c7,0x4(%esp)
f0101588:	00 
f0101589:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101590:	e8 21 eb ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101595:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010159c:	e8 e6 f8 ff ff       	call   f0100e87 <page_alloc>
f01015a1:	89 c7                	mov    %eax,%edi
f01015a3:	85 c0                	test   %eax,%eax
f01015a5:	75 24                	jne    f01015cb <mem_init+0x404>
f01015a7:	c7 44 24 0c bb 5f 10 	movl   $0xf0105fbb,0xc(%esp)
f01015ae:	f0 
f01015af:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01015b6:	f0 
f01015b7:	c7 44 24 04 c8 02 00 	movl   $0x2c8,0x4(%esp)
f01015be:	00 
f01015bf:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01015c6:	e8 eb ea ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f01015cb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015d2:	e8 b0 f8 ff ff       	call   f0100e87 <page_alloc>
f01015d7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015da:	85 c0                	test   %eax,%eax
f01015dc:	75 24                	jne    f0101602 <mem_init+0x43b>
f01015de:	c7 44 24 0c d1 5f 10 	movl   $0xf0105fd1,0xc(%esp)
f01015e5:	f0 
f01015e6:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01015ed:	f0 
f01015ee:	c7 44 24 04 c9 02 00 	movl   $0x2c9,0x4(%esp)
f01015f5:	00 
f01015f6:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01015fd:	e8 b4 ea ff ff       	call   f01000b6 <_panic>
	assert(pp1 && pp1 != pp0);
f0101602:	39 fe                	cmp    %edi,%esi
f0101604:	75 24                	jne    f010162a <mem_init+0x463>
f0101606:	c7 44 24 0c e7 5f 10 	movl   $0xf0105fe7,0xc(%esp)
f010160d:	f0 
f010160e:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101615:	f0 
f0101616:	c7 44 24 04 cb 02 00 	movl   $0x2cb,0x4(%esp)
f010161d:	00 
f010161e:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101625:	e8 8c ea ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010162a:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f010162d:	74 05                	je     f0101634 <mem_init+0x46d>
f010162f:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101632:	75 24                	jne    f0101658 <mem_init+0x491>
f0101634:	c7 44 24 0c 38 58 10 	movl   $0xf0105838,0xc(%esp)
f010163b:	f0 
f010163c:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101643:	f0 
f0101644:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
f010164b:	00 
f010164c:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101653:	e8 5e ea ff ff       	call   f01000b6 <_panic>
	assert(!page_alloc(0));
f0101658:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010165f:	e8 23 f8 ff ff       	call   f0100e87 <page_alloc>
f0101664:	85 c0                	test   %eax,%eax
f0101666:	74 24                	je     f010168c <mem_init+0x4c5>
f0101668:	c7 44 24 0c 50 60 10 	movl   $0xf0106050,0xc(%esp)
f010166f:	f0 
f0101670:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101677:	f0 
f0101678:	c7 44 24 04 cd 02 00 	movl   $0x2cd,0x4(%esp)
f010167f:	00 
f0101680:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101687:	e8 2a ea ff ff       	call   f01000b6 <_panic>
f010168c:	89 f0                	mov    %esi,%eax
f010168e:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0101694:	c1 f8 03             	sar    $0x3,%eax
f0101697:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010169a:	89 c2                	mov    %eax,%edx
f010169c:	c1 ea 0c             	shr    $0xc,%edx
f010169f:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f01016a5:	72 20                	jb     f01016c7 <mem_init+0x500>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016a7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016ab:	c7 44 24 08 d0 56 10 	movl   $0xf01056d0,0x8(%esp)
f01016b2:	f0 
f01016b3:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01016ba:	00 
f01016bb:	c7 04 24 af 5e 10 f0 	movl   $0xf0105eaf,(%esp)
f01016c2:	e8 ef e9 ff ff       	call   f01000b6 <_panic>
	memset(page2kva(pp0), 1, PGSIZE);
f01016c7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01016ce:	00 
f01016cf:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01016d6:	00 
	return (void *)(pa + KERNBASE);
f01016d7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01016dc:	89 04 24             	mov    %eax,(%esp)
f01016df:	e8 0f 36 00 00       	call   f0104cf3 <memset>
	page_free(pp0);
f01016e4:	89 34 24             	mov    %esi,(%esp)
f01016e7:	e8 1f f8 ff ff       	call   f0100f0b <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016ec:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016f3:	e8 8f f7 ff ff       	call   f0100e87 <page_alloc>
f01016f8:	85 c0                	test   %eax,%eax
f01016fa:	75 24                	jne    f0101720 <mem_init+0x559>
f01016fc:	c7 44 24 0c 5f 60 10 	movl   $0xf010605f,0xc(%esp)
f0101703:	f0 
f0101704:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f010170b:	f0 
f010170c:	c7 44 24 04 d2 02 00 	movl   $0x2d2,0x4(%esp)
f0101713:	00 
f0101714:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f010171b:	e8 96 e9 ff ff       	call   f01000b6 <_panic>
	assert(pp && pp0 == pp);
f0101720:	39 c6                	cmp    %eax,%esi
f0101722:	74 24                	je     f0101748 <mem_init+0x581>
f0101724:	c7 44 24 0c 7d 60 10 	movl   $0xf010607d,0xc(%esp)
f010172b:	f0 
f010172c:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101733:	f0 
f0101734:	c7 44 24 04 d3 02 00 	movl   $0x2d3,0x4(%esp)
f010173b:	00 
f010173c:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101743:	e8 6e e9 ff ff       	call   f01000b6 <_panic>
	return (pp - pages) << PGSHIFT;
f0101748:	89 f2                	mov    %esi,%edx
f010174a:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0101750:	c1 fa 03             	sar    $0x3,%edx
f0101753:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101756:	89 d0                	mov    %edx,%eax
f0101758:	c1 e8 0c             	shr    $0xc,%eax
f010175b:	3b 05 24 ec 17 f0    	cmp    0xf017ec24,%eax
f0101761:	72 20                	jb     f0101783 <mem_init+0x5bc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101763:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101767:	c7 44 24 08 d0 56 10 	movl   $0xf01056d0,0x8(%esp)
f010176e:	f0 
f010176f:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101776:	00 
f0101777:	c7 04 24 af 5e 10 f0 	movl   $0xf0105eaf,(%esp)
f010177e:	e8 33 e9 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0101783:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
mem_init(void)
f0101789:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f010178f:	80 38 00             	cmpb   $0x0,(%eax)
f0101792:	74 24                	je     f01017b8 <mem_init+0x5f1>
f0101794:	c7 44 24 0c 8d 60 10 	movl   $0xf010608d,0xc(%esp)
f010179b:	f0 
f010179c:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01017a3:	f0 
f01017a4:	c7 44 24 04 d6 02 00 	movl   $0x2d6,0x4(%esp)
f01017ab:	00 
f01017ac:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01017b3:	e8 fe e8 ff ff       	call   f01000b6 <_panic>
f01017b8:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01017bb:	39 d0                	cmp    %edx,%eax
f01017bd:	75 d0                	jne    f010178f <mem_init+0x5c8>
	page_free_list = fl;
f01017bf:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01017c2:	89 15 80 df 17 f0    	mov    %edx,0xf017df80
	page_free(pp0);
f01017c8:	89 34 24             	mov    %esi,(%esp)
f01017cb:	e8 3b f7 ff ff       	call   f0100f0b <page_free>
	page_free(pp1);
f01017d0:	89 3c 24             	mov    %edi,(%esp)
f01017d3:	e8 33 f7 ff ff       	call   f0100f0b <page_free>
	page_free(pp2);
f01017d8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017db:	89 04 24             	mov    %eax,(%esp)
f01017de:	e8 28 f7 ff ff       	call   f0100f0b <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017e3:	a1 80 df 17 f0       	mov    0xf017df80,%eax
f01017e8:	eb 05                	jmp    f01017ef <mem_init+0x628>
		--nfree;
f01017ea:	83 eb 01             	sub    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017ed:	8b 00                	mov    (%eax),%eax
f01017ef:	85 c0                	test   %eax,%eax
f01017f1:	75 f7                	jne    f01017ea <mem_init+0x623>
	assert(nfree == 0);
f01017f3:	85 db                	test   %ebx,%ebx
f01017f5:	74 24                	je     f010181b <mem_init+0x654>
f01017f7:	c7 44 24 0c 97 60 10 	movl   $0xf0106097,0xc(%esp)
f01017fe:	f0 
f01017ff:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101806:	f0 
f0101807:	c7 44 24 04 e3 02 00 	movl   $0x2e3,0x4(%esp)
f010180e:	00 
f010180f:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101816:	e8 9b e8 ff ff       	call   f01000b6 <_panic>
	cprintf("check_page_alloc() succeeded!\n");
f010181b:	c7 04 24 58 58 10 f0 	movl   $0xf0105858,(%esp)
f0101822:	e8 65 1f 00 00       	call   f010378c <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101827:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010182e:	e8 54 f6 ff ff       	call   f0100e87 <page_alloc>
f0101833:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101836:	85 c0                	test   %eax,%eax
f0101838:	75 24                	jne    f010185e <mem_init+0x697>
f010183a:	c7 44 24 0c a5 5f 10 	movl   $0xf0105fa5,0xc(%esp)
f0101841:	f0 
f0101842:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101849:	f0 
f010184a:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0101851:	00 
f0101852:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101859:	e8 58 e8 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f010185e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101865:	e8 1d f6 ff ff       	call   f0100e87 <page_alloc>
f010186a:	89 c3                	mov    %eax,%ebx
f010186c:	85 c0                	test   %eax,%eax
f010186e:	75 24                	jne    f0101894 <mem_init+0x6cd>
f0101870:	c7 44 24 0c bb 5f 10 	movl   $0xf0105fbb,0xc(%esp)
f0101877:	f0 
f0101878:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f010187f:	f0 
f0101880:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0101887:	00 
f0101888:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f010188f:	e8 22 e8 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0101894:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010189b:	e8 e7 f5 ff ff       	call   f0100e87 <page_alloc>
f01018a0:	89 c6                	mov    %eax,%esi
f01018a2:	85 c0                	test   %eax,%eax
f01018a4:	75 24                	jne    f01018ca <mem_init+0x703>
f01018a6:	c7 44 24 0c d1 5f 10 	movl   $0xf0105fd1,0xc(%esp)
f01018ad:	f0 
f01018ae:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01018b5:	f0 
f01018b6:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f01018bd:	00 
f01018be:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01018c5:	e8 ec e7 ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018ca:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01018cd:	75 24                	jne    f01018f3 <mem_init+0x72c>
f01018cf:	c7 44 24 0c e7 5f 10 	movl   $0xf0105fe7,0xc(%esp)
f01018d6:	f0 
f01018d7:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01018de:	f0 
f01018df:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f01018e6:	00 
f01018e7:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01018ee:	e8 c3 e7 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018f3:	39 c3                	cmp    %eax,%ebx
f01018f5:	74 05                	je     f01018fc <mem_init+0x735>
f01018f7:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01018fa:	75 24                	jne    f0101920 <mem_init+0x759>
f01018fc:	c7 44 24 0c 38 58 10 	movl   $0xf0105838,0xc(%esp)
f0101903:	f0 
f0101904:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f010190b:	f0 
f010190c:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f0101913:	00 
f0101914:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f010191b:	e8 96 e7 ff ff       	call   f01000b6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101920:	8b 3d 80 df 17 f0    	mov    0xf017df80,%edi
f0101926:	89 7d c8             	mov    %edi,-0x38(%ebp)
	page_free_list = 0;
f0101929:	c7 05 80 df 17 f0 00 	movl   $0x0,0xf017df80
f0101930:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101933:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010193a:	e8 48 f5 ff ff       	call   f0100e87 <page_alloc>
f010193f:	85 c0                	test   %eax,%eax
f0101941:	74 24                	je     f0101967 <mem_init+0x7a0>
f0101943:	c7 44 24 0c 50 60 10 	movl   $0xf0106050,0xc(%esp)
f010194a:	f0 
f010194b:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101952:	f0 
f0101953:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f010195a:	00 
f010195b:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101962:	e8 4f e7 ff ff       	call   f01000b6 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101967:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010196a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010196e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101975:	00 
f0101976:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f010197b:	89 04 24             	mov    %eax,(%esp)
f010197e:	e8 02 f7 ff ff       	call   f0101085 <page_lookup>
f0101983:	85 c0                	test   %eax,%eax
f0101985:	74 24                	je     f01019ab <mem_init+0x7e4>
f0101987:	c7 44 24 0c 78 58 10 	movl   $0xf0105878,0xc(%esp)
f010198e:	f0 
f010198f:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101996:	f0 
f0101997:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f010199e:	00 
f010199f:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01019a6:	e8 0b e7 ff ff       	call   f01000b6 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019ab:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01019b2:	00 
f01019b3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01019ba:	00 
f01019bb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01019bf:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f01019c4:	89 04 24             	mov    %eax,(%esp)
f01019c7:	e8 81 f7 ff ff       	call   f010114d <page_insert>
f01019cc:	85 c0                	test   %eax,%eax
f01019ce:	78 24                	js     f01019f4 <mem_init+0x82d>
f01019d0:	c7 44 24 0c b0 58 10 	movl   $0xf01058b0,0xc(%esp)
f01019d7:	f0 
f01019d8:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01019df:	f0 
f01019e0:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f01019e7:	00 
f01019e8:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01019ef:	e8 c2 e6 ff ff       	call   f01000b6 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019f4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019f7:	89 04 24             	mov    %eax,(%esp)
f01019fa:	e8 0c f5 ff ff       	call   f0100f0b <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019ff:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a06:	00 
f0101a07:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a0e:	00 
f0101a0f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101a13:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101a18:	89 04 24             	mov    %eax,(%esp)
f0101a1b:	e8 2d f7 ff ff       	call   f010114d <page_insert>
f0101a20:	85 c0                	test   %eax,%eax
f0101a22:	74 24                	je     f0101a48 <mem_init+0x881>
f0101a24:	c7 44 24 0c e0 58 10 	movl   $0xf01058e0,0xc(%esp)
f0101a2b:	f0 
f0101a2c:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101a33:	f0 
f0101a34:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f0101a3b:	00 
f0101a3c:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101a43:	e8 6e e6 ff ff       	call   f01000b6 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a48:	8b 3d 28 ec 17 f0    	mov    0xf017ec28,%edi
	return (pp - pages) << PGSHIFT;
f0101a4e:	8b 15 2c ec 17 f0    	mov    0xf017ec2c,%edx
f0101a54:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101a57:	8b 17                	mov    (%edi),%edx
f0101a59:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a5f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a62:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101a65:	c1 f8 03             	sar    $0x3,%eax
f0101a68:	c1 e0 0c             	shl    $0xc,%eax
f0101a6b:	39 c2                	cmp    %eax,%edx
f0101a6d:	74 24                	je     f0101a93 <mem_init+0x8cc>
f0101a6f:	c7 44 24 0c 10 59 10 	movl   $0xf0105910,0xc(%esp)
f0101a76:	f0 
f0101a77:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101a7e:	f0 
f0101a7f:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f0101a86:	00 
f0101a87:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101a8e:	e8 23 e6 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a93:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a98:	89 f8                	mov    %edi,%eax
f0101a9a:	e8 a1 ee ff ff       	call   f0100940 <check_va2pa>
f0101a9f:	89 da                	mov    %ebx,%edx
f0101aa1:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101aa4:	c1 fa 03             	sar    $0x3,%edx
f0101aa7:	c1 e2 0c             	shl    $0xc,%edx
f0101aaa:	39 d0                	cmp    %edx,%eax
f0101aac:	74 24                	je     f0101ad2 <mem_init+0x90b>
f0101aae:	c7 44 24 0c 38 59 10 	movl   $0xf0105938,0xc(%esp)
f0101ab5:	f0 
f0101ab6:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101abd:	f0 
f0101abe:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0101ac5:	00 
f0101ac6:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101acd:	e8 e4 e5 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f0101ad2:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ad7:	74 24                	je     f0101afd <mem_init+0x936>
f0101ad9:	c7 44 24 0c a2 60 10 	movl   $0xf01060a2,0xc(%esp)
f0101ae0:	f0 
f0101ae1:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101ae8:	f0 
f0101ae9:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f0101af0:	00 
f0101af1:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101af8:	e8 b9 e5 ff ff       	call   f01000b6 <_panic>
	assert(pp0->pp_ref == 1);
f0101afd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b00:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b05:	74 24                	je     f0101b2b <mem_init+0x964>
f0101b07:	c7 44 24 0c b3 60 10 	movl   $0xf01060b3,0xc(%esp)
f0101b0e:	f0 
f0101b0f:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101b16:	f0 
f0101b17:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f0101b1e:	00 
f0101b1f:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101b26:	e8 8b e5 ff ff       	call   f01000b6 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b2b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b32:	00 
f0101b33:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b3a:	00 
f0101b3b:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101b3f:	89 3c 24             	mov    %edi,(%esp)
f0101b42:	e8 06 f6 ff ff       	call   f010114d <page_insert>
f0101b47:	85 c0                	test   %eax,%eax
f0101b49:	74 24                	je     f0101b6f <mem_init+0x9a8>
f0101b4b:	c7 44 24 0c 68 59 10 	movl   $0xf0105968,0xc(%esp)
f0101b52:	f0 
f0101b53:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101b5a:	f0 
f0101b5b:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0101b62:	00 
f0101b63:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101b6a:	e8 47 e5 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b6f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b74:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101b79:	e8 c2 ed ff ff       	call   f0100940 <check_va2pa>
f0101b7e:	89 f2                	mov    %esi,%edx
f0101b80:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0101b86:	c1 fa 03             	sar    $0x3,%edx
f0101b89:	c1 e2 0c             	shl    $0xc,%edx
f0101b8c:	39 d0                	cmp    %edx,%eax
f0101b8e:	74 24                	je     f0101bb4 <mem_init+0x9ed>
f0101b90:	c7 44 24 0c a4 59 10 	movl   $0xf01059a4,0xc(%esp)
f0101b97:	f0 
f0101b98:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101b9f:	f0 
f0101ba0:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f0101ba7:	00 
f0101ba8:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101baf:	e8 02 e5 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101bb4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bb9:	74 24                	je     f0101bdf <mem_init+0xa18>
f0101bbb:	c7 44 24 0c c4 60 10 	movl   $0xf01060c4,0xc(%esp)
f0101bc2:	f0 
f0101bc3:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101bca:	f0 
f0101bcb:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f0101bd2:	00 
f0101bd3:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101bda:	e8 d7 e4 ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101bdf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101be6:	e8 9c f2 ff ff       	call   f0100e87 <page_alloc>
f0101beb:	85 c0                	test   %eax,%eax
f0101bed:	74 24                	je     f0101c13 <mem_init+0xa4c>
f0101bef:	c7 44 24 0c 50 60 10 	movl   $0xf0106050,0xc(%esp)
f0101bf6:	f0 
f0101bf7:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101bfe:	f0 
f0101bff:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f0101c06:	00 
f0101c07:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101c0e:	e8 a3 e4 ff ff       	call   f01000b6 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c13:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c1a:	00 
f0101c1b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c22:	00 
f0101c23:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c27:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101c2c:	89 04 24             	mov    %eax,(%esp)
f0101c2f:	e8 19 f5 ff ff       	call   f010114d <page_insert>
f0101c34:	85 c0                	test   %eax,%eax
f0101c36:	74 24                	je     f0101c5c <mem_init+0xa95>
f0101c38:	c7 44 24 0c 68 59 10 	movl   $0xf0105968,0xc(%esp)
f0101c3f:	f0 
f0101c40:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101c47:	f0 
f0101c48:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0101c4f:	00 
f0101c50:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101c57:	e8 5a e4 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c5c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c61:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101c66:	e8 d5 ec ff ff       	call   f0100940 <check_va2pa>
f0101c6b:	89 f2                	mov    %esi,%edx
f0101c6d:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0101c73:	c1 fa 03             	sar    $0x3,%edx
f0101c76:	c1 e2 0c             	shl    $0xc,%edx
f0101c79:	39 d0                	cmp    %edx,%eax
f0101c7b:	74 24                	je     f0101ca1 <mem_init+0xada>
f0101c7d:	c7 44 24 0c a4 59 10 	movl   $0xf01059a4,0xc(%esp)
f0101c84:	f0 
f0101c85:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101c8c:	f0 
f0101c8d:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f0101c94:	00 
f0101c95:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101c9c:	e8 15 e4 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101ca1:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ca6:	74 24                	je     f0101ccc <mem_init+0xb05>
f0101ca8:	c7 44 24 0c c4 60 10 	movl   $0xf01060c4,0xc(%esp)
f0101caf:	f0 
f0101cb0:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101cb7:	f0 
f0101cb8:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0101cbf:	00 
f0101cc0:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101cc7:	e8 ea e3 ff ff       	call   f01000b6 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101ccc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cd3:	e8 af f1 ff ff       	call   f0100e87 <page_alloc>
f0101cd8:	85 c0                	test   %eax,%eax
f0101cda:	74 24                	je     f0101d00 <mem_init+0xb39>
f0101cdc:	c7 44 24 0c 50 60 10 	movl   $0xf0106050,0xc(%esp)
f0101ce3:	f0 
f0101ce4:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101ceb:	f0 
f0101cec:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f0101cf3:	00 
f0101cf4:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101cfb:	e8 b6 e3 ff ff       	call   f01000b6 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d00:	8b 15 28 ec 17 f0    	mov    0xf017ec28,%edx
f0101d06:	8b 02                	mov    (%edx),%eax
f0101d08:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101d0d:	89 c1                	mov    %eax,%ecx
f0101d0f:	c1 e9 0c             	shr    $0xc,%ecx
f0101d12:	3b 0d 24 ec 17 f0    	cmp    0xf017ec24,%ecx
f0101d18:	72 20                	jb     f0101d3a <mem_init+0xb73>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d1a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d1e:	c7 44 24 08 d0 56 10 	movl   $0xf01056d0,0x8(%esp)
f0101d25:	f0 
f0101d26:	c7 44 24 04 70 03 00 	movl   $0x370,0x4(%esp)
f0101d2d:	00 
f0101d2e:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101d35:	e8 7c e3 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0101d3a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d3f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d42:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d49:	00 
f0101d4a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101d51:	00 
f0101d52:	89 14 24             	mov    %edx,(%esp)
f0101d55:	e8 14 f2 ff ff       	call   f0100f6e <pgdir_walk>
f0101d5a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101d5d:	83 c2 04             	add    $0x4,%edx
f0101d60:	39 d0                	cmp    %edx,%eax
f0101d62:	74 24                	je     f0101d88 <mem_init+0xbc1>
f0101d64:	c7 44 24 0c d4 59 10 	movl   $0xf01059d4,0xc(%esp)
f0101d6b:	f0 
f0101d6c:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101d73:	f0 
f0101d74:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f0101d7b:	00 
f0101d7c:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101d83:	e8 2e e3 ff ff       	call   f01000b6 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d88:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101d8f:	00 
f0101d90:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d97:	00 
f0101d98:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101d9c:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101da1:	89 04 24             	mov    %eax,(%esp)
f0101da4:	e8 a4 f3 ff ff       	call   f010114d <page_insert>
f0101da9:	85 c0                	test   %eax,%eax
f0101dab:	74 24                	je     f0101dd1 <mem_init+0xc0a>
f0101dad:	c7 44 24 0c 14 5a 10 	movl   $0xf0105a14,0xc(%esp)
f0101db4:	f0 
f0101db5:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101dbc:	f0 
f0101dbd:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f0101dc4:	00 
f0101dc5:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101dcc:	e8 e5 e2 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101dd1:	8b 3d 28 ec 17 f0    	mov    0xf017ec28,%edi
f0101dd7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ddc:	89 f8                	mov    %edi,%eax
f0101dde:	e8 5d eb ff ff       	call   f0100940 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101de3:	89 f2                	mov    %esi,%edx
f0101de5:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0101deb:	c1 fa 03             	sar    $0x3,%edx
f0101dee:	c1 e2 0c             	shl    $0xc,%edx
f0101df1:	39 d0                	cmp    %edx,%eax
f0101df3:	74 24                	je     f0101e19 <mem_init+0xc52>
f0101df5:	c7 44 24 0c a4 59 10 	movl   $0xf01059a4,0xc(%esp)
f0101dfc:	f0 
f0101dfd:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101e04:	f0 
f0101e05:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f0101e0c:	00 
f0101e0d:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101e14:	e8 9d e2 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101e19:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e1e:	74 24                	je     f0101e44 <mem_init+0xc7d>
f0101e20:	c7 44 24 0c c4 60 10 	movl   $0xf01060c4,0xc(%esp)
f0101e27:	f0 
f0101e28:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101e2f:	f0 
f0101e30:	c7 44 24 04 76 03 00 	movl   $0x376,0x4(%esp)
f0101e37:	00 
f0101e38:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101e3f:	e8 72 e2 ff ff       	call   f01000b6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e44:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e4b:	00 
f0101e4c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e53:	00 
f0101e54:	89 3c 24             	mov    %edi,(%esp)
f0101e57:	e8 12 f1 ff ff       	call   f0100f6e <pgdir_walk>
f0101e5c:	f6 00 04             	testb  $0x4,(%eax)
f0101e5f:	75 24                	jne    f0101e85 <mem_init+0xcbe>
f0101e61:	c7 44 24 0c 54 5a 10 	movl   $0xf0105a54,0xc(%esp)
f0101e68:	f0 
f0101e69:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101e70:	f0 
f0101e71:	c7 44 24 04 77 03 00 	movl   $0x377,0x4(%esp)
f0101e78:	00 
f0101e79:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101e80:	e8 31 e2 ff ff       	call   f01000b6 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e85:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101e8a:	f6 00 04             	testb  $0x4,(%eax)
f0101e8d:	75 24                	jne    f0101eb3 <mem_init+0xcec>
f0101e8f:	c7 44 24 0c d5 60 10 	movl   $0xf01060d5,0xc(%esp)
f0101e96:	f0 
f0101e97:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101e9e:	f0 
f0101e9f:	c7 44 24 04 78 03 00 	movl   $0x378,0x4(%esp)
f0101ea6:	00 
f0101ea7:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101eae:	e8 03 e2 ff ff       	call   f01000b6 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101eb3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101eba:	00 
f0101ebb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ec2:	00 
f0101ec3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101ec7:	89 04 24             	mov    %eax,(%esp)
f0101eca:	e8 7e f2 ff ff       	call   f010114d <page_insert>
f0101ecf:	85 c0                	test   %eax,%eax
f0101ed1:	74 24                	je     f0101ef7 <mem_init+0xd30>
f0101ed3:	c7 44 24 0c 68 59 10 	movl   $0xf0105968,0xc(%esp)
f0101eda:	f0 
f0101edb:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101ee2:	f0 
f0101ee3:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f0101eea:	00 
f0101eeb:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101ef2:	e8 bf e1 ff ff       	call   f01000b6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101ef7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101efe:	00 
f0101eff:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f06:	00 
f0101f07:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101f0c:	89 04 24             	mov    %eax,(%esp)
f0101f0f:	e8 5a f0 ff ff       	call   f0100f6e <pgdir_walk>
f0101f14:	f6 00 02             	testb  $0x2,(%eax)
f0101f17:	75 24                	jne    f0101f3d <mem_init+0xd76>
f0101f19:	c7 44 24 0c 88 5a 10 	movl   $0xf0105a88,0xc(%esp)
f0101f20:	f0 
f0101f21:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101f28:	f0 
f0101f29:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f0101f30:	00 
f0101f31:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101f38:	e8 79 e1 ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f3d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f44:	00 
f0101f45:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f4c:	00 
f0101f4d:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101f52:	89 04 24             	mov    %eax,(%esp)
f0101f55:	e8 14 f0 ff ff       	call   f0100f6e <pgdir_walk>
f0101f5a:	f6 00 04             	testb  $0x4,(%eax)
f0101f5d:	74 24                	je     f0101f83 <mem_init+0xdbc>
f0101f5f:	c7 44 24 0c bc 5a 10 	movl   $0xf0105abc,0xc(%esp)
f0101f66:	f0 
f0101f67:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101f6e:	f0 
f0101f6f:	c7 44 24 04 7d 03 00 	movl   $0x37d,0x4(%esp)
f0101f76:	00 
f0101f77:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101f7e:	e8 33 e1 ff ff       	call   f01000b6 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f83:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f8a:	00 
f0101f8b:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101f92:	00 
f0101f93:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f96:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101f9a:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101f9f:	89 04 24             	mov    %eax,(%esp)
f0101fa2:	e8 a6 f1 ff ff       	call   f010114d <page_insert>
f0101fa7:	85 c0                	test   %eax,%eax
f0101fa9:	78 24                	js     f0101fcf <mem_init+0xe08>
f0101fab:	c7 44 24 0c f4 5a 10 	movl   $0xf0105af4,0xc(%esp)
f0101fb2:	f0 
f0101fb3:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0101fba:	f0 
f0101fbb:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f0101fc2:	00 
f0101fc3:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0101fca:	e8 e7 e0 ff ff       	call   f01000b6 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101fcf:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101fd6:	00 
f0101fd7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101fde:	00 
f0101fdf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101fe3:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101fe8:	89 04 24             	mov    %eax,(%esp)
f0101feb:	e8 5d f1 ff ff       	call   f010114d <page_insert>
f0101ff0:	85 c0                	test   %eax,%eax
f0101ff2:	74 24                	je     f0102018 <mem_init+0xe51>
f0101ff4:	c7 44 24 0c 2c 5b 10 	movl   $0xf0105b2c,0xc(%esp)
f0101ffb:	f0 
f0101ffc:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102003:	f0 
f0102004:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f010200b:	00 
f010200c:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102013:	e8 9e e0 ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102018:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010201f:	00 
f0102020:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102027:	00 
f0102028:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f010202d:	89 04 24             	mov    %eax,(%esp)
f0102030:	e8 39 ef ff ff       	call   f0100f6e <pgdir_walk>
f0102035:	f6 00 04             	testb  $0x4,(%eax)
f0102038:	74 24                	je     f010205e <mem_init+0xe97>
f010203a:	c7 44 24 0c bc 5a 10 	movl   $0xf0105abc,0xc(%esp)
f0102041:	f0 
f0102042:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102049:	f0 
f010204a:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0102051:	00 
f0102052:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102059:	e8 58 e0 ff ff       	call   f01000b6 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010205e:	8b 3d 28 ec 17 f0    	mov    0xf017ec28,%edi
f0102064:	ba 00 00 00 00       	mov    $0x0,%edx
f0102069:	89 f8                	mov    %edi,%eax
f010206b:	e8 d0 e8 ff ff       	call   f0100940 <check_va2pa>
f0102070:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102073:	89 d8                	mov    %ebx,%eax
f0102075:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f010207b:	c1 f8 03             	sar    $0x3,%eax
f010207e:	c1 e0 0c             	shl    $0xc,%eax
f0102081:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102084:	74 24                	je     f01020aa <mem_init+0xee3>
f0102086:	c7 44 24 0c 68 5b 10 	movl   $0xf0105b68,0xc(%esp)
f010208d:	f0 
f010208e:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102095:	f0 
f0102096:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f010209d:	00 
f010209e:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01020a5:	e8 0c e0 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020aa:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020af:	89 f8                	mov    %edi,%eax
f01020b1:	e8 8a e8 ff ff       	call   f0100940 <check_va2pa>
f01020b6:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01020b9:	74 24                	je     f01020df <mem_init+0xf18>
f01020bb:	c7 44 24 0c 94 5b 10 	movl   $0xf0105b94,0xc(%esp)
f01020c2:	f0 
f01020c3:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01020ca:	f0 
f01020cb:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f01020d2:	00 
f01020d3:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01020da:	e8 d7 df ff ff       	call   f01000b6 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01020df:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f01020e4:	74 24                	je     f010210a <mem_init+0xf43>
f01020e6:	c7 44 24 0c eb 60 10 	movl   $0xf01060eb,0xc(%esp)
f01020ed:	f0 
f01020ee:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01020f5:	f0 
f01020f6:	c7 44 24 04 8a 03 00 	movl   $0x38a,0x4(%esp)
f01020fd:	00 
f01020fe:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102105:	e8 ac df ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f010210a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010210f:	74 24                	je     f0102135 <mem_init+0xf6e>
f0102111:	c7 44 24 0c fc 60 10 	movl   $0xf01060fc,0xc(%esp)
f0102118:	f0 
f0102119:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102120:	f0 
f0102121:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f0102128:	00 
f0102129:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102130:	e8 81 df ff ff       	call   f01000b6 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102135:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010213c:	e8 46 ed ff ff       	call   f0100e87 <page_alloc>
f0102141:	85 c0                	test   %eax,%eax
f0102143:	74 04                	je     f0102149 <mem_init+0xf82>
f0102145:	39 c6                	cmp    %eax,%esi
f0102147:	74 24                	je     f010216d <mem_init+0xfa6>
f0102149:	c7 44 24 0c c4 5b 10 	movl   $0xf0105bc4,0xc(%esp)
f0102150:	f0 
f0102151:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102158:	f0 
f0102159:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f0102160:	00 
f0102161:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102168:	e8 49 df ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010216d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102174:	00 
f0102175:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f010217a:	89 04 24             	mov    %eax,(%esp)
f010217d:	e8 7b ef ff ff       	call   f01010fd <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102182:	8b 3d 28 ec 17 f0    	mov    0xf017ec28,%edi
f0102188:	ba 00 00 00 00       	mov    $0x0,%edx
f010218d:	89 f8                	mov    %edi,%eax
f010218f:	e8 ac e7 ff ff       	call   f0100940 <check_va2pa>
f0102194:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102197:	74 24                	je     f01021bd <mem_init+0xff6>
f0102199:	c7 44 24 0c e8 5b 10 	movl   $0xf0105be8,0xc(%esp)
f01021a0:	f0 
f01021a1:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01021a8:	f0 
f01021a9:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f01021b0:	00 
f01021b1:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01021b8:	e8 f9 de ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01021bd:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021c2:	89 f8                	mov    %edi,%eax
f01021c4:	e8 77 e7 ff ff       	call   f0100940 <check_va2pa>
f01021c9:	89 da                	mov    %ebx,%edx
f01021cb:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f01021d1:	c1 fa 03             	sar    $0x3,%edx
f01021d4:	c1 e2 0c             	shl    $0xc,%edx
f01021d7:	39 d0                	cmp    %edx,%eax
f01021d9:	74 24                	je     f01021ff <mem_init+0x1038>
f01021db:	c7 44 24 0c 94 5b 10 	movl   $0xf0105b94,0xc(%esp)
f01021e2:	f0 
f01021e3:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01021ea:	f0 
f01021eb:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f01021f2:	00 
f01021f3:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01021fa:	e8 b7 de ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f01021ff:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102204:	74 24                	je     f010222a <mem_init+0x1063>
f0102206:	c7 44 24 0c a2 60 10 	movl   $0xf01060a2,0xc(%esp)
f010220d:	f0 
f010220e:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102215:	f0 
f0102216:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f010221d:	00 
f010221e:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102225:	e8 8c de ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f010222a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010222f:	74 24                	je     f0102255 <mem_init+0x108e>
f0102231:	c7 44 24 0c fc 60 10 	movl   $0xf01060fc,0xc(%esp)
f0102238:	f0 
f0102239:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102240:	f0 
f0102241:	c7 44 24 04 95 03 00 	movl   $0x395,0x4(%esp)
f0102248:	00 
f0102249:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102250:	e8 61 de ff ff       	call   f01000b6 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102255:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010225c:	00 
f010225d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102264:	00 
f0102265:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102269:	89 3c 24             	mov    %edi,(%esp)
f010226c:	e8 dc ee ff ff       	call   f010114d <page_insert>
f0102271:	85 c0                	test   %eax,%eax
f0102273:	74 24                	je     f0102299 <mem_init+0x10d2>
f0102275:	c7 44 24 0c 0c 5c 10 	movl   $0xf0105c0c,0xc(%esp)
f010227c:	f0 
f010227d:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102284:	f0 
f0102285:	c7 44 24 04 98 03 00 	movl   $0x398,0x4(%esp)
f010228c:	00 
f010228d:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102294:	e8 1d de ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref);
f0102299:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010229e:	75 24                	jne    f01022c4 <mem_init+0x10fd>
f01022a0:	c7 44 24 0c 0d 61 10 	movl   $0xf010610d,0xc(%esp)
f01022a7:	f0 
f01022a8:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01022af:	f0 
f01022b0:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f01022b7:	00 
f01022b8:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01022bf:	e8 f2 dd ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_link == NULL);
f01022c4:	83 3b 00             	cmpl   $0x0,(%ebx)
f01022c7:	74 24                	je     f01022ed <mem_init+0x1126>
f01022c9:	c7 44 24 0c 19 61 10 	movl   $0xf0106119,0xc(%esp)
f01022d0:	f0 
f01022d1:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01022d8:	f0 
f01022d9:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f01022e0:	00 
f01022e1:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01022e8:	e8 c9 dd ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01022ed:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01022f4:	00 
f01022f5:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f01022fa:	89 04 24             	mov    %eax,(%esp)
f01022fd:	e8 fb ed ff ff       	call   f01010fd <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102302:	8b 3d 28 ec 17 f0    	mov    0xf017ec28,%edi
f0102308:	ba 00 00 00 00       	mov    $0x0,%edx
f010230d:	89 f8                	mov    %edi,%eax
f010230f:	e8 2c e6 ff ff       	call   f0100940 <check_va2pa>
f0102314:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102317:	74 24                	je     f010233d <mem_init+0x1176>
f0102319:	c7 44 24 0c e8 5b 10 	movl   $0xf0105be8,0xc(%esp)
f0102320:	f0 
f0102321:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102328:	f0 
f0102329:	c7 44 24 04 9e 03 00 	movl   $0x39e,0x4(%esp)
f0102330:	00 
f0102331:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102338:	e8 79 dd ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010233d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102342:	89 f8                	mov    %edi,%eax
f0102344:	e8 f7 e5 ff ff       	call   f0100940 <check_va2pa>
f0102349:	83 f8 ff             	cmp    $0xffffffff,%eax
f010234c:	74 24                	je     f0102372 <mem_init+0x11ab>
f010234e:	c7 44 24 0c 44 5c 10 	movl   $0xf0105c44,0xc(%esp)
f0102355:	f0 
f0102356:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f010235d:	f0 
f010235e:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f0102365:	00 
f0102366:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f010236d:	e8 44 dd ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f0102372:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102377:	74 24                	je     f010239d <mem_init+0x11d6>
f0102379:	c7 44 24 0c 2e 61 10 	movl   $0xf010612e,0xc(%esp)
f0102380:	f0 
f0102381:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102388:	f0 
f0102389:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f0102390:	00 
f0102391:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102398:	e8 19 dd ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f010239d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01023a2:	74 24                	je     f01023c8 <mem_init+0x1201>
f01023a4:	c7 44 24 0c fc 60 10 	movl   $0xf01060fc,0xc(%esp)
f01023ab:	f0 
f01023ac:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01023b3:	f0 
f01023b4:	c7 44 24 04 a1 03 00 	movl   $0x3a1,0x4(%esp)
f01023bb:	00 
f01023bc:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01023c3:	e8 ee dc ff ff       	call   f01000b6 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01023c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01023cf:	e8 b3 ea ff ff       	call   f0100e87 <page_alloc>
f01023d4:	85 c0                	test   %eax,%eax
f01023d6:	74 04                	je     f01023dc <mem_init+0x1215>
f01023d8:	39 c3                	cmp    %eax,%ebx
f01023da:	74 24                	je     f0102400 <mem_init+0x1239>
f01023dc:	c7 44 24 0c 6c 5c 10 	movl   $0xf0105c6c,0xc(%esp)
f01023e3:	f0 
f01023e4:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01023eb:	f0 
f01023ec:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f01023f3:	00 
f01023f4:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01023fb:	e8 b6 dc ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102400:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102407:	e8 7b ea ff ff       	call   f0100e87 <page_alloc>
f010240c:	85 c0                	test   %eax,%eax
f010240e:	74 24                	je     f0102434 <mem_init+0x126d>
f0102410:	c7 44 24 0c 50 60 10 	movl   $0xf0106050,0xc(%esp)
f0102417:	f0 
f0102418:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f010241f:	f0 
f0102420:	c7 44 24 04 a7 03 00 	movl   $0x3a7,0x4(%esp)
f0102427:	00 
f0102428:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f010242f:	e8 82 dc ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102434:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102439:	8b 08                	mov    (%eax),%ecx
f010243b:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102441:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102444:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f010244a:	c1 fa 03             	sar    $0x3,%edx
f010244d:	c1 e2 0c             	shl    $0xc,%edx
f0102450:	39 d1                	cmp    %edx,%ecx
f0102452:	74 24                	je     f0102478 <mem_init+0x12b1>
f0102454:	c7 44 24 0c 10 59 10 	movl   $0xf0105910,0xc(%esp)
f010245b:	f0 
f010245c:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102463:	f0 
f0102464:	c7 44 24 04 aa 03 00 	movl   $0x3aa,0x4(%esp)
f010246b:	00 
f010246c:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102473:	e8 3e dc ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f0102478:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010247e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102481:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102486:	74 24                	je     f01024ac <mem_init+0x12e5>
f0102488:	c7 44 24 0c b3 60 10 	movl   $0xf01060b3,0xc(%esp)
f010248f:	f0 
f0102490:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102497:	f0 
f0102498:	c7 44 24 04 ac 03 00 	movl   $0x3ac,0x4(%esp)
f010249f:	00 
f01024a0:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01024a7:	e8 0a dc ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f01024ac:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01024af:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01024b5:	89 04 24             	mov    %eax,(%esp)
f01024b8:	e8 4e ea ff ff       	call   f0100f0b <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01024bd:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01024c4:	00 
f01024c5:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01024cc:	00 
f01024cd:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f01024d2:	89 04 24             	mov    %eax,(%esp)
f01024d5:	e8 94 ea ff ff       	call   f0100f6e <pgdir_walk>
f01024da:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01024dd:	8b 15 28 ec 17 f0    	mov    0xf017ec28,%edx
f01024e3:	8b 4a 04             	mov    0x4(%edx),%ecx
f01024e6:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01024ec:	89 4d cc             	mov    %ecx,-0x34(%ebp)
	if (PGNUM(pa) >= npages)
f01024ef:	8b 0d 24 ec 17 f0    	mov    0xf017ec24,%ecx
f01024f5:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01024f8:	c1 ef 0c             	shr    $0xc,%edi
f01024fb:	39 cf                	cmp    %ecx,%edi
f01024fd:	72 23                	jb     f0102522 <mem_init+0x135b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024ff:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102502:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102506:	c7 44 24 08 d0 56 10 	movl   $0xf01056d0,0x8(%esp)
f010250d:	f0 
f010250e:	c7 44 24 04 b3 03 00 	movl   $0x3b3,0x4(%esp)
f0102515:	00 
f0102516:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f010251d:	e8 94 db ff ff       	call   f01000b6 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102522:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102525:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f010252b:	39 f8                	cmp    %edi,%eax
f010252d:	74 24                	je     f0102553 <mem_init+0x138c>
f010252f:	c7 44 24 0c 3f 61 10 	movl   $0xf010613f,0xc(%esp)
f0102536:	f0 
f0102537:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f010253e:	f0 
f010253f:	c7 44 24 04 b4 03 00 	movl   $0x3b4,0x4(%esp)
f0102546:	00 
f0102547:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f010254e:	e8 63 db ff ff       	call   f01000b6 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102553:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f010255a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010255d:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0102563:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0102569:	c1 f8 03             	sar    $0x3,%eax
f010256c:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010256f:	89 c2                	mov    %eax,%edx
f0102571:	c1 ea 0c             	shr    $0xc,%edx
f0102574:	39 d1                	cmp    %edx,%ecx
f0102576:	77 20                	ja     f0102598 <mem_init+0x13d1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102578:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010257c:	c7 44 24 08 d0 56 10 	movl   $0xf01056d0,0x8(%esp)
f0102583:	f0 
f0102584:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010258b:	00 
f010258c:	c7 04 24 af 5e 10 f0 	movl   $0xf0105eaf,(%esp)
f0102593:	e8 1e db ff ff       	call   f01000b6 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102598:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010259f:	00 
f01025a0:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01025a7:	00 
	return (void *)(pa + KERNBASE);
f01025a8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025ad:	89 04 24             	mov    %eax,(%esp)
f01025b0:	e8 3e 27 00 00       	call   f0104cf3 <memset>
	page_free(pp0);
f01025b5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01025b8:	89 04 24             	mov    %eax,(%esp)
f01025bb:	e8 4b e9 ff ff       	call   f0100f0b <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01025c0:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01025c7:	00 
f01025c8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01025cf:	00 
f01025d0:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f01025d5:	89 04 24             	mov    %eax,(%esp)
f01025d8:	e8 91 e9 ff ff       	call   f0100f6e <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f01025dd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01025e0:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f01025e6:	c1 fa 03             	sar    $0x3,%edx
f01025e9:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01025ec:	89 d0                	mov    %edx,%eax
f01025ee:	c1 e8 0c             	shr    $0xc,%eax
f01025f1:	3b 05 24 ec 17 f0    	cmp    0xf017ec24,%eax
f01025f7:	72 20                	jb     f0102619 <mem_init+0x1452>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025f9:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01025fd:	c7 44 24 08 d0 56 10 	movl   $0xf01056d0,0x8(%esp)
f0102604:	f0 
f0102605:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010260c:	00 
f010260d:	c7 04 24 af 5e 10 f0 	movl   $0xf0105eaf,(%esp)
f0102614:	e8 9d da ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0102619:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010261f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mem_init(void)
f0102622:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102628:	f6 00 01             	testb  $0x1,(%eax)
f010262b:	74 24                	je     f0102651 <mem_init+0x148a>
f010262d:	c7 44 24 0c 57 61 10 	movl   $0xf0106157,0xc(%esp)
f0102634:	f0 
f0102635:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f010263c:	f0 
f010263d:	c7 44 24 04 be 03 00 	movl   $0x3be,0x4(%esp)
f0102644:	00 
f0102645:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f010264c:	e8 65 da ff ff       	call   f01000b6 <_panic>
f0102651:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f0102654:	39 d0                	cmp    %edx,%eax
f0102656:	75 d0                	jne    f0102628 <mem_init+0x1461>
	kern_pgdir[0] = 0;
f0102658:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f010265d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102663:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102666:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010266c:	8b 7d c8             	mov    -0x38(%ebp),%edi
f010266f:	89 3d 80 df 17 f0    	mov    %edi,0xf017df80

	// free the pages we took
	page_free(pp0);
f0102675:	89 04 24             	mov    %eax,(%esp)
f0102678:	e8 8e e8 ff ff       	call   f0100f0b <page_free>
	page_free(pp1);
f010267d:	89 1c 24             	mov    %ebx,(%esp)
f0102680:	e8 86 e8 ff ff       	call   f0100f0b <page_free>
	page_free(pp2);
f0102685:	89 34 24             	mov    %esi,(%esp)
f0102688:	e8 7e e8 ff ff       	call   f0100f0b <page_free>

	cprintf("check_page() succeeded!\n");
f010268d:	c7 04 24 6e 61 10 f0 	movl   $0xf010616e,(%esp)
f0102694:	e8 f3 10 00 00       	call   f010378c <cprintf>
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U|PTE_P);
f0102699:	a1 2c ec 17 f0       	mov    0xf017ec2c,%eax
	if ((uint32_t)kva < KERNBASE)
f010269e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026a3:	77 20                	ja     f01026c5 <mem_init+0x14fe>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026a5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01026a9:	c7 44 24 08 b8 57 10 	movl   $0xf01057b8,0x8(%esp)
f01026b0:	f0 
f01026b1:	c7 44 24 04 c0 00 00 	movl   $0xc0,0x4(%esp)
f01026b8:	00 
f01026b9:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01026c0:	e8 f1 d9 ff ff       	call   f01000b6 <_panic>
f01026c5:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01026cc:	00 
	return (physaddr_t)kva - KERNBASE;
f01026cd:	05 00 00 00 10       	add    $0x10000000,%eax
f01026d2:	89 04 24             	mov    %eax,(%esp)
f01026d5:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01026da:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01026df:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f01026e4:	e8 25 e9 ff ff       	call   f010100e <boot_map_region>
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U | PTE_P);
f01026e9:	a1 8c df 17 f0       	mov    0xf017df8c,%eax
	if ((uint32_t)kva < KERNBASE)
f01026ee:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026f3:	77 20                	ja     f0102715 <mem_init+0x154e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026f5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01026f9:	c7 44 24 08 b8 57 10 	movl   $0xf01057b8,0x8(%esp)
f0102700:	f0 
f0102701:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
f0102708:	00 
f0102709:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102710:	e8 a1 d9 ff ff       	call   f01000b6 <_panic>
f0102715:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f010271c:	00 
	return (physaddr_t)kva - KERNBASE;
f010271d:	05 00 00 00 10       	add    $0x10000000,%eax
f0102722:	89 04 24             	mov    %eax,(%esp)
f0102725:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010272a:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010272f:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102734:	e8 d5 e8 ff ff       	call   f010100e <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f0102739:	b8 00 20 11 f0       	mov    $0xf0112000,%eax
f010273e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102743:	77 20                	ja     f0102765 <mem_init+0x159e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102745:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102749:	c7 44 24 08 b8 57 10 	movl   $0xf01057b8,0x8(%esp)
f0102750:	f0 
f0102751:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
f0102758:	00 
f0102759:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102760:	e8 51 d9 ff ff       	call   f01000b6 <_panic>
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W|PTE_P);
f0102765:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f010276c:	00 
f010276d:	c7 04 24 00 20 11 00 	movl   $0x112000,(%esp)
f0102774:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102779:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010277e:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102783:	e8 86 e8 ff ff       	call   f010100e <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff-KERNBASE, 0,PTE_W|PTE_P);
f0102788:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f010278f:	00 
f0102790:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102797:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010279c:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01027a1:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f01027a6:	e8 63 e8 ff ff       	call   f010100e <boot_map_region>
	pgdir = kern_pgdir;
f01027ab:	8b 1d 28 ec 17 f0    	mov    0xf017ec28,%ebx
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01027b1:	8b 35 24 ec 17 f0    	mov    0xf017ec24,%esi
f01027b7:	89 75 c8             	mov    %esi,-0x38(%ebp)
f01027ba:	8d 04 f5 ff 0f 00 00 	lea    0xfff(,%esi,8),%eax
f01027c1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01027c6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01027c9:	8b 3d 2c ec 17 f0    	mov    0xf017ec2c,%edi
f01027cf:	89 7d cc             	mov    %edi,-0x34(%ebp)
	if ((uint32_t)kva < KERNBASE)
f01027d2:	89 7d d0             	mov    %edi,-0x30(%ebp)
	return (physaddr_t)kva - KERNBASE;
f01027d5:	81 c7 00 00 00 10    	add    $0x10000000,%edi
	for (i = 0; i < n; i += PGSIZE)
f01027db:	be 00 00 00 00       	mov    $0x0,%esi
f01027e0:	eb 6a                	jmp    f010284c <mem_init+0x1685>
mem_init(void)
f01027e2:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01027e8:	89 d8                	mov    %ebx,%eax
f01027ea:	e8 51 e1 ff ff       	call   f0100940 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f01027ef:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01027f6:	77 23                	ja     f010281b <mem_init+0x1654>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027f8:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01027fb:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01027ff:	c7 44 24 08 b8 57 10 	movl   $0xf01057b8,0x8(%esp)
f0102806:	f0 
f0102807:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
f010280e:	00 
f010280f:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102816:	e8 9b d8 ff ff       	call   f01000b6 <_panic>
mem_init(void)
f010281b:	8d 14 3e             	lea    (%esi,%edi,1),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010281e:	39 d0                	cmp    %edx,%eax
f0102820:	74 24                	je     f0102846 <mem_init+0x167f>
f0102822:	c7 44 24 0c 90 5c 10 	movl   $0xf0105c90,0xc(%esp)
f0102829:	f0 
f010282a:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102831:	f0 
f0102832:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
f0102839:	00 
f010283a:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102841:	e8 70 d8 ff ff       	call   f01000b6 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f0102846:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010284c:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f010284f:	77 91                	ja     f01027e2 <mem_init+0x161b>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102851:	8b 35 8c df 17 f0    	mov    0xf017df8c,%esi
	if ((uint32_t)kva < KERNBASE)
f0102857:	89 f7                	mov    %esi,%edi
f0102859:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010285e:	89 d8                	mov    %ebx,%eax
f0102860:	e8 db e0 ff ff       	call   f0100940 <check_va2pa>
f0102865:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f010286b:	77 20                	ja     f010288d <mem_init+0x16c6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010286d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102871:	c7 44 24 08 b8 57 10 	movl   $0xf01057b8,0x8(%esp)
f0102878:	f0 
f0102879:	c7 44 24 04 00 03 00 	movl   $0x300,0x4(%esp)
f0102880:	00 
f0102881:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102888:	e8 29 d8 ff ff       	call   f01000b6 <_panic>
	if ((uint32_t)kva < KERNBASE)
f010288d:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
mem_init(void)
f0102892:	81 c7 00 00 40 21    	add    $0x21400000,%edi
f0102898:	8d 14 37             	lea    (%edi,%esi,1),%edx
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010289b:	39 c2                	cmp    %eax,%edx
f010289d:	74 24                	je     f01028c3 <mem_init+0x16fc>
f010289f:	c7 44 24 0c c4 5c 10 	movl   $0xf0105cc4,0xc(%esp)
f01028a6:	f0 
f01028a7:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01028ae:	f0 
f01028af:	c7 44 24 04 00 03 00 	movl   $0x300,0x4(%esp)
f01028b6:	00 
f01028b7:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01028be:	e8 f3 d7 ff ff       	call   f01000b6 <_panic>
f01028c3:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
f01028c9:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f01028cf:	0f 85 d5 05 00 00    	jne    f0102eaa <mem_init+0x1ce3>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01028d5:	8b 7d c8             	mov    -0x38(%ebp),%edi
f01028d8:	c1 e7 0c             	shl    $0xc,%edi
f01028db:	be 00 00 00 00       	mov    $0x0,%esi
f01028e0:	eb 3b                	jmp    f010291d <mem_init+0x1756>
mem_init(void)
f01028e2:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01028e8:	89 d8                	mov    %ebx,%eax
f01028ea:	e8 51 e0 ff ff       	call   f0100940 <check_va2pa>
f01028ef:	39 c6                	cmp    %eax,%esi
f01028f1:	74 24                	je     f0102917 <mem_init+0x1750>
f01028f3:	c7 44 24 0c f8 5c 10 	movl   $0xf0105cf8,0xc(%esp)
f01028fa:	f0 
f01028fb:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102902:	f0 
f0102903:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f010290a:	00 
f010290b:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102912:	e8 9f d7 ff ff       	call   f01000b6 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102917:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010291d:	39 fe                	cmp    %edi,%esi
f010291f:	72 c1                	jb     f01028e2 <mem_init+0x171b>
f0102921:	be 00 80 ff ef       	mov    $0xefff8000,%esi
mem_init(void)
f0102926:	bf 00 20 11 f0       	mov    $0xf0112000,%edi
f010292b:	81 c7 00 80 00 20    	add    $0x20008000,%edi
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102931:	89 f2                	mov    %esi,%edx
f0102933:	89 d8                	mov    %ebx,%eax
f0102935:	e8 06 e0 ff ff       	call   f0100940 <check_va2pa>
mem_init(void)
f010293a:	8d 14 37             	lea    (%edi,%esi,1),%edx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010293d:	39 d0                	cmp    %edx,%eax
f010293f:	74 24                	je     f0102965 <mem_init+0x179e>
f0102941:	c7 44 24 0c 20 5d 10 	movl   $0xf0105d20,0xc(%esp)
f0102948:	f0 
f0102949:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102950:	f0 
f0102951:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
f0102958:	00 
f0102959:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102960:	e8 51 d7 ff ff       	call   f01000b6 <_panic>
f0102965:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010296b:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102971:	75 be                	jne    f0102931 <mem_init+0x176a>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102973:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102978:	89 d8                	mov    %ebx,%eax
f010297a:	e8 c1 df ff ff       	call   f0100940 <check_va2pa>
f010297f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102982:	0f 84 f3 00 00 00    	je     f0102a7b <mem_init+0x18b4>
f0102988:	c7 44 24 0c 68 5d 10 	movl   $0xf0105d68,0xc(%esp)
f010298f:	f0 
f0102990:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102997:	f0 
f0102998:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f010299f:	00 
f01029a0:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01029a7:	e8 0a d7 ff ff       	call   f01000b6 <_panic>
		switch (i) {
f01029ac:	8d 88 45 fc ff ff    	lea    -0x3bb(%eax),%ecx
f01029b2:	83 f9 04             	cmp    $0x4,%ecx
f01029b5:	77 39                	ja     f01029f0 <mem_init+0x1829>
f01029b7:	89 d7                	mov    %edx,%edi
f01029b9:	d3 e7                	shl    %cl,%edi
f01029bb:	89 f9                	mov    %edi,%ecx
f01029bd:	f6 c1 17             	test   $0x17,%cl
f01029c0:	74 2e                	je     f01029f0 <mem_init+0x1829>
			assert(pgdir[i] & PTE_P);
f01029c2:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01029c6:	0f 85 aa 00 00 00    	jne    f0102a76 <mem_init+0x18af>
f01029cc:	c7 44 24 0c 87 61 10 	movl   $0xf0106187,0xc(%esp)
f01029d3:	f0 
f01029d4:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f01029db:	f0 
f01029dc:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f01029e3:	00 
f01029e4:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f01029eb:	e8 c6 d6 ff ff       	call   f01000b6 <_panic>
			if (i >= PDX(KERNBASE)) {
f01029f0:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01029f5:	76 55                	jbe    f0102a4c <mem_init+0x1885>
				assert(pgdir[i] & PTE_P);
f01029f7:	8b 0c 83             	mov    (%ebx,%eax,4),%ecx
f01029fa:	f6 c1 01             	test   $0x1,%cl
f01029fd:	75 24                	jne    f0102a23 <mem_init+0x185c>
f01029ff:	c7 44 24 0c 87 61 10 	movl   $0xf0106187,0xc(%esp)
f0102a06:	f0 
f0102a07:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102a0e:	f0 
f0102a0f:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
f0102a16:	00 
f0102a17:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102a1e:	e8 93 d6 ff ff       	call   f01000b6 <_panic>
				assert(pgdir[i] & PTE_W);
f0102a23:	f6 c1 02             	test   $0x2,%cl
f0102a26:	75 4e                	jne    f0102a76 <mem_init+0x18af>
f0102a28:	c7 44 24 0c 98 61 10 	movl   $0xf0106198,0xc(%esp)
f0102a2f:	f0 
f0102a30:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102a37:	f0 
f0102a38:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0102a3f:	00 
f0102a40:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102a47:	e8 6a d6 ff ff       	call   f01000b6 <_panic>
				assert(pgdir[i] == 0);
f0102a4c:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102a50:	74 24                	je     f0102a76 <mem_init+0x18af>
f0102a52:	c7 44 24 0c a9 61 10 	movl   $0xf01061a9,0xc(%esp)
f0102a59:	f0 
f0102a5a:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102a61:	f0 
f0102a62:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f0102a69:	00 
f0102a6a:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102a71:	e8 40 d6 ff ff       	call   f01000b6 <_panic>
	for (i = 0; i < NPDENTRIES; i++) {
f0102a76:	83 c0 01             	add    $0x1,%eax
f0102a79:	eb 0a                	jmp    f0102a85 <mem_init+0x18be>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102a7b:	b8 00 00 00 00       	mov    $0x0,%eax
		switch (i) {
f0102a80:	ba 01 00 00 00       	mov    $0x1,%edx
	for (i = 0; i < NPDENTRIES; i++) {
f0102a85:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102a8a:	0f 85 1c ff ff ff    	jne    f01029ac <mem_init+0x17e5>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102a90:	c7 04 24 98 5d 10 f0 	movl   $0xf0105d98,(%esp)
f0102a97:	e8 f0 0c 00 00       	call   f010378c <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102a9c:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102aa1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102aa6:	77 20                	ja     f0102ac8 <mem_init+0x1901>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102aa8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102aac:	c7 44 24 08 b8 57 10 	movl   $0xf01057b8,0x8(%esp)
f0102ab3:	f0 
f0102ab4:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
f0102abb:	00 
f0102abc:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102ac3:	e8 ee d5 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102ac8:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102acd:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102ad0:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ad5:	e8 68 df ff ff       	call   f0100a42 <check_page_free_list>
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102ada:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102add:	83 e0 f3             	and    $0xfffffff3,%eax
f0102ae0:	0d 23 00 05 80       	or     $0x80050023,%eax
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102ae5:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102ae8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102aef:	e8 93 e3 ff ff       	call   f0100e87 <page_alloc>
f0102af4:	89 c3                	mov    %eax,%ebx
f0102af6:	85 c0                	test   %eax,%eax
f0102af8:	75 24                	jne    f0102b1e <mem_init+0x1957>
f0102afa:	c7 44 24 0c a5 5f 10 	movl   $0xf0105fa5,0xc(%esp)
f0102b01:	f0 
f0102b02:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102b09:	f0 
f0102b0a:	c7 44 24 04 d9 03 00 	movl   $0x3d9,0x4(%esp)
f0102b11:	00 
f0102b12:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102b19:	e8 98 d5 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0102b1e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b25:	e8 5d e3 ff ff       	call   f0100e87 <page_alloc>
f0102b2a:	89 c7                	mov    %eax,%edi
f0102b2c:	85 c0                	test   %eax,%eax
f0102b2e:	75 24                	jne    f0102b54 <mem_init+0x198d>
f0102b30:	c7 44 24 0c bb 5f 10 	movl   $0xf0105fbb,0xc(%esp)
f0102b37:	f0 
f0102b38:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102b3f:	f0 
f0102b40:	c7 44 24 04 da 03 00 	movl   $0x3da,0x4(%esp)
f0102b47:	00 
f0102b48:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102b4f:	e8 62 d5 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0102b54:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b5b:	e8 27 e3 ff ff       	call   f0100e87 <page_alloc>
f0102b60:	89 c6                	mov    %eax,%esi
f0102b62:	85 c0                	test   %eax,%eax
f0102b64:	75 24                	jne    f0102b8a <mem_init+0x19c3>
f0102b66:	c7 44 24 0c d1 5f 10 	movl   $0xf0105fd1,0xc(%esp)
f0102b6d:	f0 
f0102b6e:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102b75:	f0 
f0102b76:	c7 44 24 04 db 03 00 	movl   $0x3db,0x4(%esp)
f0102b7d:	00 
f0102b7e:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102b85:	e8 2c d5 ff ff       	call   f01000b6 <_panic>
	page_free(pp0);
f0102b8a:	89 1c 24             	mov    %ebx,(%esp)
f0102b8d:	e8 79 e3 ff ff       	call   f0100f0b <page_free>
	return (pp - pages) << PGSHIFT;
f0102b92:	89 f8                	mov    %edi,%eax
f0102b94:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0102b9a:	c1 f8 03             	sar    $0x3,%eax
f0102b9d:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102ba0:	89 c2                	mov    %eax,%edx
f0102ba2:	c1 ea 0c             	shr    $0xc,%edx
f0102ba5:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0102bab:	72 20                	jb     f0102bcd <mem_init+0x1a06>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bad:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102bb1:	c7 44 24 08 d0 56 10 	movl   $0xf01056d0,0x8(%esp)
f0102bb8:	f0 
f0102bb9:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102bc0:	00 
f0102bc1:	c7 04 24 af 5e 10 f0 	movl   $0xf0105eaf,(%esp)
f0102bc8:	e8 e9 d4 ff ff       	call   f01000b6 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102bcd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102bd4:	00 
f0102bd5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102bdc:	00 
	return (void *)(pa + KERNBASE);
f0102bdd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102be2:	89 04 24             	mov    %eax,(%esp)
f0102be5:	e8 09 21 00 00       	call   f0104cf3 <memset>
	return (pp - pages) << PGSHIFT;
f0102bea:	89 f0                	mov    %esi,%eax
f0102bec:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0102bf2:	c1 f8 03             	sar    $0x3,%eax
f0102bf5:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102bf8:	89 c2                	mov    %eax,%edx
f0102bfa:	c1 ea 0c             	shr    $0xc,%edx
f0102bfd:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0102c03:	72 20                	jb     f0102c25 <mem_init+0x1a5e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c05:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c09:	c7 44 24 08 d0 56 10 	movl   $0xf01056d0,0x8(%esp)
f0102c10:	f0 
f0102c11:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102c18:	00 
f0102c19:	c7 04 24 af 5e 10 f0 	movl   $0xf0105eaf,(%esp)
f0102c20:	e8 91 d4 ff ff       	call   f01000b6 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102c25:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c2c:	00 
f0102c2d:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102c34:	00 
	return (void *)(pa + KERNBASE);
f0102c35:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c3a:	89 04 24             	mov    %eax,(%esp)
f0102c3d:	e8 b1 20 00 00       	call   f0104cf3 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102c42:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102c49:	00 
f0102c4a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c51:	00 
f0102c52:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102c56:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102c5b:	89 04 24             	mov    %eax,(%esp)
f0102c5e:	e8 ea e4 ff ff       	call   f010114d <page_insert>
	assert(pp1->pp_ref == 1);
f0102c63:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102c68:	74 24                	je     f0102c8e <mem_init+0x1ac7>
f0102c6a:	c7 44 24 0c a2 60 10 	movl   $0xf01060a2,0xc(%esp)
f0102c71:	f0 
f0102c72:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102c79:	f0 
f0102c7a:	c7 44 24 04 e0 03 00 	movl   $0x3e0,0x4(%esp)
f0102c81:	00 
f0102c82:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102c89:	e8 28 d4 ff ff       	call   f01000b6 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102c8e:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102c95:	01 01 01 
f0102c98:	74 24                	je     f0102cbe <mem_init+0x1af7>
f0102c9a:	c7 44 24 0c b8 5d 10 	movl   $0xf0105db8,0xc(%esp)
f0102ca1:	f0 
f0102ca2:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102ca9:	f0 
f0102caa:	c7 44 24 04 e1 03 00 	movl   $0x3e1,0x4(%esp)
f0102cb1:	00 
f0102cb2:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102cb9:	e8 f8 d3 ff ff       	call   f01000b6 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102cbe:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102cc5:	00 
f0102cc6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ccd:	00 
f0102cce:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102cd2:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102cd7:	89 04 24             	mov    %eax,(%esp)
f0102cda:	e8 6e e4 ff ff       	call   f010114d <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102cdf:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102ce6:	02 02 02 
f0102ce9:	74 24                	je     f0102d0f <mem_init+0x1b48>
f0102ceb:	c7 44 24 0c dc 5d 10 	movl   $0xf0105ddc,0xc(%esp)
f0102cf2:	f0 
f0102cf3:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102cfa:	f0 
f0102cfb:	c7 44 24 04 e3 03 00 	movl   $0x3e3,0x4(%esp)
f0102d02:	00 
f0102d03:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102d0a:	e8 a7 d3 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0102d0f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102d14:	74 24                	je     f0102d3a <mem_init+0x1b73>
f0102d16:	c7 44 24 0c c4 60 10 	movl   $0xf01060c4,0xc(%esp)
f0102d1d:	f0 
f0102d1e:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102d25:	f0 
f0102d26:	c7 44 24 04 e4 03 00 	movl   $0x3e4,0x4(%esp)
f0102d2d:	00 
f0102d2e:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102d35:	e8 7c d3 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f0102d3a:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102d3f:	74 24                	je     f0102d65 <mem_init+0x1b9e>
f0102d41:	c7 44 24 0c 2e 61 10 	movl   $0xf010612e,0xc(%esp)
f0102d48:	f0 
f0102d49:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102d50:	f0 
f0102d51:	c7 44 24 04 e5 03 00 	movl   $0x3e5,0x4(%esp)
f0102d58:	00 
f0102d59:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102d60:	e8 51 d3 ff ff       	call   f01000b6 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102d65:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d6c:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102d6f:	89 f0                	mov    %esi,%eax
f0102d71:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0102d77:	c1 f8 03             	sar    $0x3,%eax
f0102d7a:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102d7d:	89 c2                	mov    %eax,%edx
f0102d7f:	c1 ea 0c             	shr    $0xc,%edx
f0102d82:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0102d88:	72 20                	jb     f0102daa <mem_init+0x1be3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d8a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d8e:	c7 44 24 08 d0 56 10 	movl   $0xf01056d0,0x8(%esp)
f0102d95:	f0 
f0102d96:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102d9d:	00 
f0102d9e:	c7 04 24 af 5e 10 f0 	movl   $0xf0105eaf,(%esp)
f0102da5:	e8 0c d3 ff ff       	call   f01000b6 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102daa:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102db1:	03 03 03 
f0102db4:	74 24                	je     f0102dda <mem_init+0x1c13>
f0102db6:	c7 44 24 0c 00 5e 10 	movl   $0xf0105e00,0xc(%esp)
f0102dbd:	f0 
f0102dbe:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102dc5:	f0 
f0102dc6:	c7 44 24 04 e7 03 00 	movl   $0x3e7,0x4(%esp)
f0102dcd:	00 
f0102dce:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102dd5:	e8 dc d2 ff ff       	call   f01000b6 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102dda:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102de1:	00 
f0102de2:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102de7:	89 04 24             	mov    %eax,(%esp)
f0102dea:	e8 0e e3 ff ff       	call   f01010fd <page_remove>
	assert(pp2->pp_ref == 0);
f0102def:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102df4:	74 24                	je     f0102e1a <mem_init+0x1c53>
f0102df6:	c7 44 24 0c fc 60 10 	movl   $0xf01060fc,0xc(%esp)
f0102dfd:	f0 
f0102dfe:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102e05:	f0 
f0102e06:	c7 44 24 04 e9 03 00 	movl   $0x3e9,0x4(%esp)
f0102e0d:	00 
f0102e0e:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102e15:	e8 9c d2 ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102e1a:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102e1f:	8b 08                	mov    (%eax),%ecx
f0102e21:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	return (pp - pages) << PGSHIFT;
f0102e27:	89 da                	mov    %ebx,%edx
f0102e29:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0102e2f:	c1 fa 03             	sar    $0x3,%edx
f0102e32:	c1 e2 0c             	shl    $0xc,%edx
f0102e35:	39 d1                	cmp    %edx,%ecx
f0102e37:	74 24                	je     f0102e5d <mem_init+0x1c96>
f0102e39:	c7 44 24 0c 10 59 10 	movl   $0xf0105910,0xc(%esp)
f0102e40:	f0 
f0102e41:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102e48:	f0 
f0102e49:	c7 44 24 04 ec 03 00 	movl   $0x3ec,0x4(%esp)
f0102e50:	00 
f0102e51:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102e58:	e8 59 d2 ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f0102e5d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102e63:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102e68:	74 24                	je     f0102e8e <mem_init+0x1cc7>
f0102e6a:	c7 44 24 0c b3 60 10 	movl   $0xf01060b3,0xc(%esp)
f0102e71:	f0 
f0102e72:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0102e79:	f0 
f0102e7a:	c7 44 24 04 ee 03 00 	movl   $0x3ee,0x4(%esp)
f0102e81:	00 
f0102e82:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0102e89:	e8 28 d2 ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f0102e8e:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102e94:	89 1c 24             	mov    %ebx,(%esp)
f0102e97:	e8 6f e0 ff ff       	call   f0100f0b <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102e9c:	c7 04 24 2c 5e 10 f0 	movl   $0xf0105e2c,(%esp)
f0102ea3:	e8 e4 08 00 00       	call   f010378c <cprintf>
f0102ea8:	eb 0e                	jmp    f0102eb8 <mem_init+0x1cf1>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102eaa:	89 f2                	mov    %esi,%edx
f0102eac:	89 d8                	mov    %ebx,%eax
f0102eae:	e8 8d da ff ff       	call   f0100940 <check_va2pa>
f0102eb3:	e9 e0 f9 ff ff       	jmp    f0102898 <mem_init+0x16d1>
}
f0102eb8:	83 c4 3c             	add    $0x3c,%esp
f0102ebb:	5b                   	pop    %ebx
f0102ebc:	5e                   	pop    %esi
f0102ebd:	5f                   	pop    %edi
f0102ebe:	5d                   	pop    %ebp
f0102ebf:	c3                   	ret    

f0102ec0 <user_mem_check>:
{
f0102ec0:	55                   	push   %ebp
f0102ec1:	89 e5                	mov    %esp,%ebp
f0102ec3:	57                   	push   %edi
f0102ec4:	56                   	push   %esi
f0102ec5:	53                   	push   %ebx
f0102ec6:	83 ec 2c             	sub    $0x2c,%esp
f0102ec9:	8b 7d 08             	mov    0x8(%ebp),%edi
	void *start = ROUNDDOWN((void *)va, PGSIZE);
f0102ecc:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ecf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102ed4:	89 45 e0             	mov    %eax,-0x20(%ebp)
	void *end = ROUNDUP((void *)va + len, PGSIZE);
f0102ed7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102eda:	03 45 10             	add    0x10(%ebp),%eax
f0102edd:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102ee2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102ee7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (current_va = start; current_va < end; current_va+=PGSIZE) {
f0102eea:	8b 5d e0             	mov    -0x20(%ebp),%ebx
		if (cur == NULL || (uintptr_t)current_va >= ULIM || (*cur & (perm|PTE_P)) != (perm|PTE_P)) {
f0102eed:	8b 75 14             	mov    0x14(%ebp),%esi
f0102ef0:	83 ce 01             	or     $0x1,%esi
	for (current_va = start; current_va < end; current_va+=PGSIZE) {
f0102ef3:	eb 54                	jmp    f0102f49 <user_mem_check+0x89>
		cur = pgdir_walk(env->env_pgdir, current_va, 0);
f0102ef5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102efc:	00 
f0102efd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102f01:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102f04:	89 04 24             	mov    %eax,(%esp)
f0102f07:	e8 62 e0 ff ff       	call   f0100f6e <pgdir_walk>
		if (cur == NULL || (uintptr_t)current_va >= ULIM || (*cur & (perm|PTE_P)) != (perm|PTE_P)) {
f0102f0c:	89 da                	mov    %ebx,%edx
f0102f0e:	85 c0                	test   %eax,%eax
f0102f10:	74 10                	je     f0102f22 <user_mem_check+0x62>
f0102f12:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102f18:	77 08                	ja     f0102f22 <user_mem_check+0x62>
f0102f1a:	8b 00                	mov    (%eax),%eax
f0102f1c:	21 f0                	and    %esi,%eax
f0102f1e:	39 c6                	cmp    %eax,%esi
f0102f20:	74 21                	je     f0102f43 <user_mem_check+0x83>
			if(current_va == start) {
f0102f22:	3b 5d e0             	cmp    -0x20(%ebp),%ebx
f0102f25:	75 0f                	jne    f0102f36 <user_mem_check+0x76>
				user_mem_check_addr = (uintptr_t)va;
f0102f27:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f2a:	a3 84 df 17 f0       	mov    %eax,0xf017df84
			return -E_FAULT;
f0102f2f:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102f34:	eb 1d                	jmp    f0102f53 <user_mem_check+0x93>
				user_mem_check_addr =(uintptr_t) current_va;
f0102f36:	89 15 84 df 17 f0    	mov    %edx,0xf017df84
			return -E_FAULT;
f0102f3c:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102f41:	eb 10                	jmp    f0102f53 <user_mem_check+0x93>
	for (current_va = start; current_va < end; current_va+=PGSIZE) {
f0102f43:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102f49:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102f4c:	72 a7                	jb     f0102ef5 <user_mem_check+0x35>
	return 0;
f0102f4e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102f53:	83 c4 2c             	add    $0x2c,%esp
f0102f56:	5b                   	pop    %ebx
f0102f57:	5e                   	pop    %esi
f0102f58:	5f                   	pop    %edi
f0102f59:	5d                   	pop    %ebp
f0102f5a:	c3                   	ret    

f0102f5b <user_mem_assert>:
{
f0102f5b:	55                   	push   %ebp
f0102f5c:	89 e5                	mov    %esp,%ebp
f0102f5e:	53                   	push   %ebx
f0102f5f:	83 ec 14             	sub    $0x14,%esp
f0102f62:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102f65:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f68:	83 c8 04             	or     $0x4,%eax
f0102f6b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102f6f:	8b 45 10             	mov    0x10(%ebp),%eax
f0102f72:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102f76:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f79:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f7d:	89 1c 24             	mov    %ebx,(%esp)
f0102f80:	e8 3b ff ff ff       	call   f0102ec0 <user_mem_check>
f0102f85:	85 c0                	test   %eax,%eax
f0102f87:	79 24                	jns    f0102fad <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102f89:	a1 84 df 17 f0       	mov    0xf017df84,%eax
f0102f8e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102f92:	8b 43 48             	mov    0x48(%ebx),%eax
f0102f95:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f99:	c7 04 24 58 5e 10 f0 	movl   $0xf0105e58,(%esp)
f0102fa0:	e8 e7 07 00 00       	call   f010378c <cprintf>
		env_destroy(env);	// may not return
f0102fa5:	89 1c 24             	mov    %ebx,(%esp)
f0102fa8:	e8 ab 06 00 00       	call   f0103658 <env_destroy>
}
f0102fad:	83 c4 14             	add    $0x14,%esp
f0102fb0:	5b                   	pop    %ebx
f0102fb1:	5d                   	pop    %ebp
f0102fb2:	c3                   	ret    

f0102fb3 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102fb3:	55                   	push   %ebp
f0102fb4:	89 e5                	mov    %esp,%ebp
f0102fb6:	57                   	push   %edi
f0102fb7:	56                   	push   %esi
f0102fb8:	53                   	push   %ebx
f0102fb9:	83 ec 1c             	sub    $0x1c,%esp
f0102fbc:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void* start = ROUNDDOWN((void *)va, PGSIZE);
f0102fbe:	89 d3                	mov    %edx,%ebx
f0102fc0:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void* end = ROUNDUP((void *)(va+len), PGSIZE);
f0102fc6:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102fcd:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	struct PageInfo *newPage;
	void* i = start;
	while(i < end) {
f0102fd3:	eb 6d                	jmp    f0103042 <region_alloc+0x8f>
		newPage =(struct PageInfo*)page_alloc(1);
f0102fd5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0102fdc:	e8 a6 de ff ff       	call   f0100e87 <page_alloc>
		if(!newPage) {
f0102fe1:	85 c0                	test   %eax,%eax
f0102fe3:	75 1c                	jne    f0103001 <region_alloc+0x4e>
			panic("no memory");
f0102fe5:	c7 44 24 08 b7 61 10 	movl   $0xf01061b7,0x8(%esp)
f0102fec:	f0 
f0102fed:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
f0102ff4:	00 
f0102ff5:	c7 04 24 c1 61 10 f0 	movl   $0xf01061c1,(%esp)
f0102ffc:	e8 b5 d0 ff ff       	call   f01000b6 <_panic>
		}
		int pi = page_insert(e->env_pgdir, newPage, i, PTE_W | PTE_U);
f0103001:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0103008:	00 
f0103009:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010300d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103011:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103014:	89 04 24             	mov    %eax,(%esp)
f0103017:	e8 31 e1 ff ff       	call   f010114d <page_insert>
		if(pi != 0) {
f010301c:	85 c0                	test   %eax,%eax
f010301e:	74 1c                	je     f010303c <region_alloc+0x89>
			panic("page_insert error");
f0103020:	c7 44 24 08 cc 61 10 	movl   $0xf01061cc,0x8(%esp)
f0103027:	f0 
f0103028:	c7 44 24 04 26 01 00 	movl   $0x126,0x4(%esp)
f010302f:	00 
f0103030:	c7 04 24 c1 61 10 f0 	movl   $0xf01061c1,(%esp)
f0103037:	e8 7a d0 ff ff       	call   f01000b6 <_panic>
		}
		i += PGSIZE;
f010303c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	while(i < end) {
f0103042:	39 f3                	cmp    %esi,%ebx
f0103044:	72 8f                	jb     f0102fd5 <region_alloc+0x22>
	}
		
}
f0103046:	83 c4 1c             	add    $0x1c,%esp
f0103049:	5b                   	pop    %ebx
f010304a:	5e                   	pop    %esi
f010304b:	5f                   	pop    %edi
f010304c:	5d                   	pop    %ebp
f010304d:	c3                   	ret    

f010304e <envid2env>:
{
f010304e:	55                   	push   %ebp
f010304f:	89 e5                	mov    %esp,%ebp
f0103051:	8b 45 08             	mov    0x8(%ebp),%eax
f0103054:	8b 4d 10             	mov    0x10(%ebp),%ecx
	if (envid == 0) {
f0103057:	85 c0                	test   %eax,%eax
f0103059:	75 11                	jne    f010306c <envid2env+0x1e>
		*env_store = curenv;
f010305b:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0103060:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103063:	89 02                	mov    %eax,(%edx)
		return 0;
f0103065:	b8 00 00 00 00       	mov    $0x0,%eax
f010306a:	eb 5e                	jmp    f01030ca <envid2env+0x7c>
	e = &envs[ENVX(envid)];
f010306c:	89 c2                	mov    %eax,%edx
f010306e:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0103074:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103077:	c1 e2 05             	shl    $0x5,%edx
f010307a:	03 15 8c df 17 f0    	add    0xf017df8c,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103080:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0103084:	74 05                	je     f010308b <envid2env+0x3d>
f0103086:	39 42 48             	cmp    %eax,0x48(%edx)
f0103089:	74 10                	je     f010309b <envid2env+0x4d>
		*env_store = 0;
f010308b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010308e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		return -E_BAD_ENV;
f0103094:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103099:	eb 2f                	jmp    f01030ca <envid2env+0x7c>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010309b:	84 c9                	test   %cl,%cl
f010309d:	74 21                	je     f01030c0 <envid2env+0x72>
f010309f:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f01030a4:	39 c2                	cmp    %eax,%edx
f01030a6:	74 18                	je     f01030c0 <envid2env+0x72>
f01030a8:	8b 48 48             	mov    0x48(%eax),%ecx
f01030ab:	39 4a 4c             	cmp    %ecx,0x4c(%edx)
f01030ae:	74 10                	je     f01030c0 <envid2env+0x72>
		*env_store = 0;
f01030b0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030b3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01030b9:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01030be:	eb 0a                	jmp    f01030ca <envid2env+0x7c>
	*env_store = e;
f01030c0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01030c3:	89 11                	mov    %edx,(%ecx)
	return 0;
f01030c5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01030ca:	5d                   	pop    %ebp
f01030cb:	c3                   	ret    

f01030cc <env_init_percpu>:
{
f01030cc:	55                   	push   %ebp
f01030cd:	89 e5                	mov    %esp,%ebp
	__asm __volatile("lgdt (%0)" : : "r" (p));
f01030cf:	b8 00 c3 11 f0       	mov    $0xf011c300,%eax
f01030d4:	0f 01 10             	lgdtl  (%eax)
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01030d7:	b8 23 00 00 00       	mov    $0x23,%eax
f01030dc:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01030de:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01030e0:	b0 10                	mov    $0x10,%al
f01030e2:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01030e4:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01030e6:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f01030e8:	ea ef 30 10 f0 08 00 	ljmp   $0x8,$0xf01030ef
	__asm __volatile("lldt %0" : : "r" (sel));
f01030ef:	b0 00                	mov    $0x0,%al
f01030f1:	0f 00 d0             	lldt   %ax
}
f01030f4:	5d                   	pop    %ebp
f01030f5:	c3                   	ret    

f01030f6 <env_init>:
{
f01030f6:	55                   	push   %ebp
f01030f7:	89 e5                	mov    %esp,%ebp
f01030f9:	56                   	push   %esi
f01030fa:	53                   	push   %ebx
		envs[i].env_id = 0;
f01030fb:	8b 35 8c df 17 f0    	mov    0xf017df8c,%esi
f0103101:	8b 0d 90 df 17 f0    	mov    0xf017df90,%ecx
env_init(void)
f0103107:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f010310d:	ba 00 04 00 00       	mov    $0x400,%edx
		envs[i].env_id = 0;
f0103112:	89 c3                	mov    %eax,%ebx
f0103114:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f010311b:	89 48 44             	mov    %ecx,0x44(%eax)
f010311e:	83 e8 60             	sub    $0x60,%eax
		env_free_list = &envs[i];
f0103121:	89 d9                	mov    %ebx,%ecx
	for(i = NENV - 1; i >= 0; i--) {
f0103123:	83 ea 01             	sub    $0x1,%edx
f0103126:	75 ea                	jne    f0103112 <env_init+0x1c>
f0103128:	89 35 90 df 17 f0    	mov    %esi,0xf017df90
	env_init_percpu();
f010312e:	e8 99 ff ff ff       	call   f01030cc <env_init_percpu>
}
f0103133:	5b                   	pop    %ebx
f0103134:	5e                   	pop    %esi
f0103135:	5d                   	pop    %ebp
f0103136:	c3                   	ret    

f0103137 <env_alloc>:
{
f0103137:	55                   	push   %ebp
f0103138:	89 e5                	mov    %esp,%ebp
f010313a:	53                   	push   %ebx
f010313b:	83 ec 14             	sub    $0x14,%esp
	if (!(e = env_free_list))
f010313e:	8b 1d 90 df 17 f0    	mov    0xf017df90,%ebx
f0103144:	85 db                	test   %ebx,%ebx
f0103146:	0f 84 8e 01 00 00    	je     f01032da <env_alloc+0x1a3>
	if (!(p = page_alloc(ALLOC_ZERO)))
f010314c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0103153:	e8 2f dd ff ff       	call   f0100e87 <page_alloc>
f0103158:	85 c0                	test   %eax,%eax
f010315a:	0f 84 81 01 00 00    	je     f01032e1 <env_alloc+0x1aa>
f0103160:	89 c2                	mov    %eax,%edx
f0103162:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0103168:	c1 fa 03             	sar    $0x3,%edx
f010316b:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010316e:	89 d1                	mov    %edx,%ecx
f0103170:	c1 e9 0c             	shr    $0xc,%ecx
f0103173:	3b 0d 24 ec 17 f0    	cmp    0xf017ec24,%ecx
f0103179:	72 20                	jb     f010319b <env_alloc+0x64>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010317b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010317f:	c7 44 24 08 d0 56 10 	movl   $0xf01056d0,0x8(%esp)
f0103186:	f0 
f0103187:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010318e:	00 
f010318f:	c7 04 24 af 5e 10 f0 	movl   $0xf0105eaf,(%esp)
f0103196:	e8 1b cf ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f010319b:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f01031a1:	89 53 5c             	mov    %edx,0x5c(%ebx)
	p->pp_ref++;
f01031a4:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	for(i = 0; i < PDX(UTOP); i++) {
f01031a9:	b8 00 00 00 00       	mov    $0x0,%eax
f01031ae:	ba 00 00 00 00       	mov    $0x0,%edx
		e->env_pgdir[i] = 0;
f01031b3:	8b 4b 5c             	mov    0x5c(%ebx),%ecx
f01031b6:	c7 04 91 00 00 00 00 	movl   $0x0,(%ecx,%edx,4)
	for(i = 0; i < PDX(UTOP); i++) {
f01031bd:	83 c0 01             	add    $0x1,%eax
f01031c0:	89 c2                	mov    %eax,%edx
f01031c2:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01031c7:	75 ea                	jne    f01031b3 <env_alloc+0x7c>
f01031c9:	66 b8 ec 0e          	mov    $0xeec,%ax
		e->env_pgdir[i] = kern_pgdir[i];
f01031cd:	8b 15 28 ec 17 f0    	mov    0xf017ec28,%edx
f01031d3:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f01031d6:	8b 53 5c             	mov    0x5c(%ebx),%edx
f01031d9:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f01031dc:	83 c0 04             	add    $0x4,%eax
	for(i = PDX(UTOP); i < NPDENTRIES; i++) {
f01031df:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01031e4:	75 e7                	jne    f01031cd <env_alloc+0x96>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01031e6:	8b 43 5c             	mov    0x5c(%ebx),%eax
	if ((uint32_t)kva < KERNBASE)
f01031e9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031ee:	77 20                	ja     f0103210 <env_alloc+0xd9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031f0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01031f4:	c7 44 24 08 b8 57 10 	movl   $0xf01057b8,0x8(%esp)
f01031fb:	f0 
f01031fc:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
f0103203:	00 
f0103204:	c7 04 24 c1 61 10 f0 	movl   $0xf01061c1,(%esp)
f010320b:	e8 a6 ce ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103210:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103216:	83 ca 05             	or     $0x5,%edx
f0103219:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f010321f:	8b 43 48             	mov    0x48(%ebx),%eax
f0103222:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103227:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f010322c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0103231:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103234:	89 da                	mov    %ebx,%edx
f0103236:	2b 15 8c df 17 f0    	sub    0xf017df8c,%edx
f010323c:	c1 fa 05             	sar    $0x5,%edx
f010323f:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0103245:	09 d0                	or     %edx,%eax
f0103247:	89 43 48             	mov    %eax,0x48(%ebx)
	e->env_parent_id = parent_id;
f010324a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010324d:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103250:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103257:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f010325e:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103265:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f010326c:	00 
f010326d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103274:	00 
f0103275:	89 1c 24             	mov    %ebx,(%esp)
f0103278:	e8 76 1a 00 00       	call   f0104cf3 <memset>
	e->env_tf.tf_ds = GD_UD | 3;
f010327d:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103283:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103289:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f010328f:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103296:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	env_free_list = e->env_link;
f010329c:	8b 43 44             	mov    0x44(%ebx),%eax
f010329f:	a3 90 df 17 f0       	mov    %eax,0xf017df90
	*newenv_store = e;
f01032a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01032a7:	89 18                	mov    %ebx,(%eax)
	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01032a9:	8b 53 48             	mov    0x48(%ebx),%edx
f01032ac:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f01032b1:	85 c0                	test   %eax,%eax
f01032b3:	74 05                	je     f01032ba <env_alloc+0x183>
f01032b5:	8b 40 48             	mov    0x48(%eax),%eax
f01032b8:	eb 05                	jmp    f01032bf <env_alloc+0x188>
f01032ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01032bf:	89 54 24 08          	mov    %edx,0x8(%esp)
f01032c3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01032c7:	c7 04 24 de 61 10 f0 	movl   $0xf01061de,(%esp)
f01032ce:	e8 b9 04 00 00       	call   f010378c <cprintf>
	return 0;
f01032d3:	b8 00 00 00 00       	mov    $0x0,%eax
f01032d8:	eb 0c                	jmp    f01032e6 <env_alloc+0x1af>
		return -E_NO_FREE_ENV;
f01032da:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01032df:	eb 05                	jmp    f01032e6 <env_alloc+0x1af>
		return -E_NO_MEM;
f01032e1:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f01032e6:	83 c4 14             	add    $0x14,%esp
f01032e9:	5b                   	pop    %ebx
f01032ea:	5d                   	pop    %ebp
f01032eb:	c3                   	ret    

f01032ec <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01032ec:	55                   	push   %ebp
f01032ed:	89 e5                	mov    %esp,%ebp
f01032ef:	57                   	push   %edi
f01032f0:	56                   	push   %esi
f01032f1:	53                   	push   %ebx
f01032f2:	83 ec 3c             	sub    $0x3c,%esp
f01032f5:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *env;
	if(env_alloc(&env, 0) != 0) {
f01032f8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01032ff:	00 
f0103300:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103303:	89 04 24             	mov    %eax,(%esp)
f0103306:	e8 2c fe ff ff       	call   f0103137 <env_alloc>
f010330b:	85 c0                	test   %eax,%eax
f010330d:	74 1c                	je     f010332b <env_create+0x3f>
		panic("env_allov error");
f010330f:	c7 44 24 08 f3 61 10 	movl   $0xf01061f3,0x8(%esp)
f0103316:	f0 
f0103317:	c7 44 24 04 95 01 00 	movl   $0x195,0x4(%esp)
f010331e:	00 
f010331f:	c7 04 24 c1 61 10 f0 	movl   $0xf01061c1,(%esp)
f0103326:	e8 8b cd ff ff       	call   f01000b6 <_panic>
	}
	env->env_type = type;
f010332b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010332e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103331:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103334:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103337:	89 42 50             	mov    %eax,0x50(%edx)
	if(elfHeader->e_magic != ELF_MAGIC) {
f010333a:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103340:	74 1c                	je     f010335e <env_create+0x72>
		panic("error, it is not a ELF file");
f0103342:	c7 44 24 08 03 62 10 	movl   $0xf0106203,0x8(%esp)
f0103349:	f0 
f010334a:	c7 44 24 04 66 01 00 	movl   $0x166,0x4(%esp)
f0103351:	00 
f0103352:	c7 04 24 c1 61 10 f0 	movl   $0xf01061c1,(%esp)
f0103359:	e8 58 cd ff ff       	call   f01000b6 <_panic>
	ph = (struct Proghdr *)(binary + elfHeader->e_phoff);
f010335e:	89 fb                	mov    %edi,%ebx
f0103360:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elfHeader->e_phnum;
f0103363:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103367:	c1 e6 05             	shl    $0x5,%esi
f010336a:	01 de                	add    %ebx,%esi
	lcr3(PADDR(e->env_pgdir));
f010336c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010336f:	8b 42 5c             	mov    0x5c(%edx),%eax
	if ((uint32_t)kva < KERNBASE)
f0103372:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103377:	77 20                	ja     f0103399 <env_create+0xad>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103379:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010337d:	c7 44 24 08 b8 57 10 	movl   $0xf01057b8,0x8(%esp)
f0103384:	f0 
f0103385:	c7 44 24 04 6b 01 00 	movl   $0x16b,0x4(%esp)
f010338c:	00 
f010338d:	c7 04 24 c1 61 10 f0 	movl   $0xf01061c1,(%esp)
f0103394:	e8 1d cd ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103399:	05 00 00 00 10       	add    $0x10000000,%eax
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010339e:	0f 22 d8             	mov    %eax,%cr3
f01033a1:	eb 71                	jmp    f0103414 <env_create+0x128>
		if(ph->p_type == ELF_PROG_LOAD) {
f01033a3:	83 3b 01             	cmpl   $0x1,(%ebx)
f01033a6:	75 69                	jne    f0103411 <env_create+0x125>
			if(ph->p_filesz > ph->p_memsz) {
f01033a8:	8b 4b 14             	mov    0x14(%ebx),%ecx
f01033ab:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f01033ae:	76 1c                	jbe    f01033cc <env_create+0xe0>
				panic("out of memory size");
f01033b0:	c7 44 24 08 1f 62 10 	movl   $0xf010621f,0x8(%esp)
f01033b7:	f0 
f01033b8:	c7 44 24 04 6f 01 00 	movl   $0x16f,0x4(%esp)
f01033bf:	00 
f01033c0:	c7 04 24 c1 61 10 f0 	movl   $0xf01061c1,(%esp)
f01033c7:	e8 ea cc ff ff       	call   f01000b6 <_panic>
			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f01033cc:	8b 53 08             	mov    0x8(%ebx),%edx
f01033cf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01033d2:	e8 dc fb ff ff       	call   f0102fb3 <region_alloc>
			memcpy((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f01033d7:	8b 43 10             	mov    0x10(%ebx),%eax
f01033da:	89 44 24 08          	mov    %eax,0x8(%esp)
f01033de:	89 f8                	mov    %edi,%eax
f01033e0:	03 43 04             	add    0x4(%ebx),%eax
f01033e3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01033e7:	8b 43 08             	mov    0x8(%ebx),%eax
f01033ea:	89 04 24             	mov    %eax,(%esp)
f01033ed:	e8 d8 19 00 00       	call   f0104dca <memcpy>
			memset((void *)ph->p_va + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
f01033f2:	8b 43 10             	mov    0x10(%ebx),%eax
f01033f5:	8b 53 14             	mov    0x14(%ebx),%edx
f01033f8:	29 c2                	sub    %eax,%edx
f01033fa:	89 54 24 08          	mov    %edx,0x8(%esp)
f01033fe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103405:	00 
f0103406:	03 43 08             	add    0x8(%ebx),%eax
f0103409:	89 04 24             	mov    %eax,(%esp)
f010340c:	e8 e2 18 00 00       	call   f0104cf3 <memset>
		ph++;
f0103411:	83 c3 20             	add    $0x20,%ebx
	while(ph < eph) {
f0103414:	39 de                	cmp    %ebx,%esi
f0103416:	77 8b                	ja     f01033a3 <env_create+0xb7>
	e->env_tf.tf_eip = elfHeader->e_entry;
f0103418:	8b 47 18             	mov    0x18(%edi),%eax
f010341b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010341e:	89 42 30             	mov    %eax,0x30(%edx)
	region_alloc(e, (void *)USTACKTOP - PGSIZE, PGSIZE);
f0103421:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103426:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f010342b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010342e:	e8 80 fb ff ff       	call   f0102fb3 <region_alloc>
	lcr3(PADDR(kern_pgdir));
f0103433:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
	if ((uint32_t)kva < KERNBASE)
f0103438:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010343d:	77 20                	ja     f010345f <env_create+0x173>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010343f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103443:	c7 44 24 08 b8 57 10 	movl   $0xf01057b8,0x8(%esp)
f010344a:	f0 
f010344b:	c7 44 24 04 85 01 00 	movl   $0x185,0x4(%esp)
f0103452:	00 
f0103453:	c7 04 24 c1 61 10 f0 	movl   $0xf01061c1,(%esp)
f010345a:	e8 57 cc ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010345f:	05 00 00 00 10       	add    $0x10000000,%eax
f0103464:	0f 22 d8             	mov    %eax,%cr3
	load_icode(env, binary);
}
f0103467:	83 c4 3c             	add    $0x3c,%esp
f010346a:	5b                   	pop    %ebx
f010346b:	5e                   	pop    %esi
f010346c:	5f                   	pop    %edi
f010346d:	5d                   	pop    %ebp
f010346e:	c3                   	ret    

f010346f <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f010346f:	55                   	push   %ebp
f0103470:	89 e5                	mov    %esp,%ebp
f0103472:	57                   	push   %edi
f0103473:	56                   	push   %esi
f0103474:	53                   	push   %ebx
f0103475:	83 ec 2c             	sub    $0x2c,%esp
f0103478:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f010347b:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0103480:	39 c7                	cmp    %eax,%edi
f0103482:	75 37                	jne    f01034bb <env_free+0x4c>
		lcr3(PADDR(kern_pgdir));
f0103484:	8b 15 28 ec 17 f0    	mov    0xf017ec28,%edx
	if ((uint32_t)kva < KERNBASE)
f010348a:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103490:	77 20                	ja     f01034b2 <env_free+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103492:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103496:	c7 44 24 08 b8 57 10 	movl   $0xf01057b8,0x8(%esp)
f010349d:	f0 
f010349e:	c7 44 24 04 a9 01 00 	movl   $0x1a9,0x4(%esp)
f01034a5:	00 
f01034a6:	c7 04 24 c1 61 10 f0 	movl   $0xf01061c1,(%esp)
f01034ad:	e8 04 cc ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01034b2:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f01034b8:	0f 22 da             	mov    %edx,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01034bb:	8b 57 48             	mov    0x48(%edi),%edx
f01034be:	85 c0                	test   %eax,%eax
f01034c0:	74 05                	je     f01034c7 <env_free+0x58>
f01034c2:	8b 40 48             	mov    0x48(%eax),%eax
f01034c5:	eb 05                	jmp    f01034cc <env_free+0x5d>
f01034c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01034cc:	89 54 24 08          	mov    %edx,0x8(%esp)
f01034d0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034d4:	c7 04 24 32 62 10 f0 	movl   $0xf0106232,(%esp)
f01034db:	e8 ac 02 00 00       	call   f010378c <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01034e0:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
env_free(struct Env *e)
f01034e7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01034ea:	c1 e0 02             	shl    $0x2,%eax
f01034ed:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01034f0:	8b 47 5c             	mov    0x5c(%edi),%eax
f01034f3:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01034f6:	8b 34 90             	mov    (%eax,%edx,4),%esi
f01034f9:	f7 c6 01 00 00 00    	test   $0x1,%esi
f01034ff:	0f 84 b7 00 00 00    	je     f01035bc <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103505:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	if (PGNUM(pa) >= npages)
f010350b:	89 f0                	mov    %esi,%eax
f010350d:	c1 e8 0c             	shr    $0xc,%eax
f0103510:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103513:	3b 05 24 ec 17 f0    	cmp    0xf017ec24,%eax
f0103519:	72 20                	jb     f010353b <env_free+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010351b:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010351f:	c7 44 24 08 d0 56 10 	movl   $0xf01056d0,0x8(%esp)
f0103526:	f0 
f0103527:	c7 44 24 04 b8 01 00 	movl   $0x1b8,0x4(%esp)
f010352e:	00 
f010352f:	c7 04 24 c1 61 10 f0 	movl   $0xf01061c1,(%esp)
f0103536:	e8 7b cb ff ff       	call   f01000b6 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010353b:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010353e:	c1 e2 16             	shl    $0x16,%edx
f0103541:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103544:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103549:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103550:	01 
f0103551:	74 17                	je     f010356a <env_free+0xfb>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103553:	89 d8                	mov    %ebx,%eax
f0103555:	c1 e0 0c             	shl    $0xc,%eax
f0103558:	0b 45 e4             	or     -0x1c(%ebp),%eax
f010355b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010355f:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103562:	89 04 24             	mov    %eax,(%esp)
f0103565:	e8 93 db ff ff       	call   f01010fd <page_remove>
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010356a:	83 c3 01             	add    $0x1,%ebx
f010356d:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103573:	75 d4                	jne    f0103549 <env_free+0xda>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103575:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103578:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010357b:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f0103582:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103585:	3b 05 24 ec 17 f0    	cmp    0xf017ec24,%eax
f010358b:	72 1c                	jb     f01035a9 <env_free+0x13a>
		panic("pa2page called with invalid pa");
f010358d:	c7 44 24 08 dc 57 10 	movl   $0xf01057dc,0x8(%esp)
f0103594:	f0 
f0103595:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f010359c:	00 
f010359d:	c7 04 24 af 5e 10 f0 	movl   $0xf0105eaf,(%esp)
f01035a4:	e8 0d cb ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f01035a9:	a1 2c ec 17 f0       	mov    0xf017ec2c,%eax
f01035ae:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01035b1:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f01035b4:	89 04 24             	mov    %eax,(%esp)
f01035b7:	e8 8f d9 ff ff       	call   f0100f4b <page_decref>
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01035bc:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01035c0:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f01035c7:	0f 85 1a ff ff ff    	jne    f01034e7 <env_free+0x78>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01035cd:	8b 47 5c             	mov    0x5c(%edi),%eax
	if ((uint32_t)kva < KERNBASE)
f01035d0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01035d5:	77 20                	ja     f01035f7 <env_free+0x188>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01035d7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035db:	c7 44 24 08 b8 57 10 	movl   $0xf01057b8,0x8(%esp)
f01035e2:	f0 
f01035e3:	c7 44 24 04 c6 01 00 	movl   $0x1c6,0x4(%esp)
f01035ea:	00 
f01035eb:	c7 04 24 c1 61 10 f0 	movl   $0xf01061c1,(%esp)
f01035f2:	e8 bf ca ff ff       	call   f01000b6 <_panic>
	e->env_pgdir = 0;
f01035f7:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f01035fe:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f0103603:	c1 e8 0c             	shr    $0xc,%eax
f0103606:	3b 05 24 ec 17 f0    	cmp    0xf017ec24,%eax
f010360c:	72 1c                	jb     f010362a <env_free+0x1bb>
		panic("pa2page called with invalid pa");
f010360e:	c7 44 24 08 dc 57 10 	movl   $0xf01057dc,0x8(%esp)
f0103615:	f0 
f0103616:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f010361d:	00 
f010361e:	c7 04 24 af 5e 10 f0 	movl   $0xf0105eaf,(%esp)
f0103625:	e8 8c ca ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f010362a:	8b 15 2c ec 17 f0    	mov    0xf017ec2c,%edx
f0103630:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f0103633:	89 04 24             	mov    %eax,(%esp)
f0103636:	e8 10 d9 ff ff       	call   f0100f4b <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f010363b:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103642:	a1 90 df 17 f0       	mov    0xf017df90,%eax
f0103647:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f010364a:	89 3d 90 df 17 f0    	mov    %edi,0xf017df90
}
f0103650:	83 c4 2c             	add    $0x2c,%esp
f0103653:	5b                   	pop    %ebx
f0103654:	5e                   	pop    %esi
f0103655:	5f                   	pop    %edi
f0103656:	5d                   	pop    %ebp
f0103657:	c3                   	ret    

f0103658 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0103658:	55                   	push   %ebp
f0103659:	89 e5                	mov    %esp,%ebp
f010365b:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f010365e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103661:	89 04 24             	mov    %eax,(%esp)
f0103664:	e8 06 fe ff ff       	call   f010346f <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0103669:	c7 04 24 54 62 10 f0 	movl   $0xf0106254,(%esp)
f0103670:	e8 17 01 00 00       	call   f010378c <cprintf>
	while (1)
		monitor(NULL);
f0103675:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010367c:	e8 75 d1 ff ff       	call   f01007f6 <monitor>
f0103681:	eb f2                	jmp    f0103675 <env_destroy+0x1d>

f0103683 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103683:	55                   	push   %ebp
f0103684:	89 e5                	mov    %esp,%ebp
f0103686:	83 ec 18             	sub    $0x18,%esp
	__asm __volatile("movl %0,%%esp\n"
f0103689:	8b 65 08             	mov    0x8(%ebp),%esp
f010368c:	61                   	popa   
f010368d:	07                   	pop    %es
f010368e:	1f                   	pop    %ds
f010368f:	83 c4 08             	add    $0x8,%esp
f0103692:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103693:	c7 44 24 08 48 62 10 	movl   $0xf0106248,0x8(%esp)
f010369a:	f0 
f010369b:	c7 44 24 04 ee 01 00 	movl   $0x1ee,0x4(%esp)
f01036a2:	00 
f01036a3:	c7 04 24 c1 61 10 f0 	movl   $0xf01061c1,(%esp)
f01036aa:	e8 07 ca ff ff       	call   f01000b6 <_panic>

f01036af <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f01036af:	55                   	push   %ebp
f01036b0:	89 e5                	mov    %esp,%ebp
f01036b2:	83 ec 18             	sub    $0x18,%esp
f01036b5:	8b 45 08             	mov    0x8(%ebp),%eax
	//	   4. Update its 'env_runs' counter,
	//	   5. Use lcr3() to switch to its address space.
	// Step 2: Use env_pop_tf() to restore the environment's
	//	   registers and drop into user mode in the
	//	   environment.
	if(curenv && curenv->env_status == ENV_RUNNING) {
f01036b8:	8b 15 88 df 17 f0    	mov    0xf017df88,%edx
f01036be:	85 d2                	test   %edx,%edx
f01036c0:	74 0d                	je     f01036cf <env_run+0x20>
f01036c2:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f01036c6:	75 07                	jne    f01036cf <env_run+0x20>
		curenv->env_status = ENV_RUNNABLE;
f01036c8:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}
	curenv = e;
f01036cf:	a3 88 df 17 f0       	mov    %eax,0xf017df88
	e->env_status = ENV_RUNNING;
f01036d4:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	e->env_runs++;
f01036db:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir));
f01036df:	8b 50 5c             	mov    0x5c(%eax),%edx
	if ((uint32_t)kva < KERNBASE)
f01036e2:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01036e8:	77 20                	ja     f010370a <env_run+0x5b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01036ea:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01036ee:	c7 44 24 08 b8 57 10 	movl   $0xf01057b8,0x8(%esp)
f01036f5:	f0 
f01036f6:	c7 44 24 04 0b 02 00 	movl   $0x20b,0x4(%esp)
f01036fd:	00 
f01036fe:	c7 04 24 c1 61 10 f0 	movl   $0xf01061c1,(%esp)
f0103705:	e8 ac c9 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010370a:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0103710:	0f 22 da             	mov    %edx,%cr3
	env_pop_tf(&e->env_tf);
f0103713:	89 04 24             	mov    %eax,(%esp)
f0103716:	e8 68 ff ff ff       	call   f0103683 <env_pop_tf>

f010371b <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010371b:	55                   	push   %ebp
f010371c:	89 e5                	mov    %esp,%ebp
void
mc146818_write(unsigned reg, unsigned datum)
{
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010371e:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103722:	ba 70 00 00 00       	mov    $0x70,%edx
f0103727:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103728:	b2 71                	mov    $0x71,%dl
f010372a:	ec                   	in     (%dx),%al
	return inb(IO_RTC+1);
f010372b:	0f b6 c0             	movzbl %al,%eax
}
f010372e:	5d                   	pop    %ebp
f010372f:	c3                   	ret    

f0103730 <mc146818_write>:
{
f0103730:	55                   	push   %ebp
f0103731:	89 e5                	mov    %esp,%ebp
}
f0103733:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103737:	ba 70 00 00 00       	mov    $0x70,%edx
f010373c:	ee                   	out    %al,(%dx)
f010373d:	0f b6 45 0c          	movzbl 0xc(%ebp),%eax
f0103741:	b2 71                	mov    $0x71,%dl
f0103743:	ee                   	out    %al,(%dx)
f0103744:	5d                   	pop    %ebp
f0103745:	c3                   	ret    

f0103746 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103746:	55                   	push   %ebp
f0103747:	89 e5                	mov    %esp,%ebp
f0103749:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010374c:	8b 45 08             	mov    0x8(%ebp),%eax
f010374f:	89 04 24             	mov    %eax,(%esp)
f0103752:	e8 b8 ce ff ff       	call   f010060f <cputchar>
	*cnt++;
}
f0103757:	c9                   	leave  
f0103758:	c3                   	ret    

f0103759 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103759:	55                   	push   %ebp
f010375a:	89 e5                	mov    %esp,%ebp
f010375c:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010375f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103766:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103769:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010376d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103770:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103774:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103777:	89 44 24 04          	mov    %eax,0x4(%esp)
f010377b:	c7 04 24 46 37 10 f0 	movl   $0xf0103746,(%esp)
f0103782:	e8 9e 0e 00 00       	call   f0104625 <vprintfmt>
	return cnt;
}
f0103787:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010378a:	c9                   	leave  
f010378b:	c3                   	ret    

f010378c <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010378c:	55                   	push   %ebp
f010378d:	89 e5                	mov    %esp,%ebp
f010378f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103792:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103795:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103799:	8b 45 08             	mov    0x8(%ebp),%eax
f010379c:	89 04 24             	mov    %eax,(%esp)
f010379f:	e8 b5 ff ff ff       	call   f0103759 <vcprintf>
	va_end(ap);

	return cnt;
}
f01037a4:	c9                   	leave  
f01037a5:	c3                   	ret    
f01037a6:	66 90                	xchg   %ax,%ax
f01037a8:	66 90                	xchg   %ax,%ax
f01037aa:	66 90                	xchg   %ax,%ax
f01037ac:	66 90                	xchg   %ax,%ax
f01037ae:	66 90                	xchg   %ax,%ax

f01037b0 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01037b0:	55                   	push   %ebp
f01037b1:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f01037b3:	c7 05 a4 e7 17 f0 00 	movl   $0xf0000000,0xf017e7a4
f01037ba:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f01037bd:	66 c7 05 a8 e7 17 f0 	movw   $0x10,0xf017e7a8
f01037c4:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f01037c6:	66 c7 05 48 c3 11 f0 	movw   $0x67,0xf011c348
f01037cd:	67 00 
f01037cf:	b8 a0 e7 17 f0       	mov    $0xf017e7a0,%eax
f01037d4:	66 a3 4a c3 11 f0    	mov    %ax,0xf011c34a
f01037da:	89 c2                	mov    %eax,%edx
f01037dc:	c1 ea 10             	shr    $0x10,%edx
f01037df:	88 15 4c c3 11 f0    	mov    %dl,0xf011c34c
f01037e5:	c6 05 4e c3 11 f0 40 	movb   $0x40,0xf011c34e
f01037ec:	c1 e8 18             	shr    $0x18,%eax
f01037ef:	a2 4f c3 11 f0       	mov    %al,0xf011c34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f01037f4:	c6 05 4d c3 11 f0 89 	movb   $0x89,0xf011c34d
	__asm __volatile("ltr %0" : : "r" (sel));
f01037fb:	b8 28 00 00 00       	mov    $0x28,%eax
f0103800:	0f 00 d8             	ltr    %ax
	__asm __volatile("lidt (%0)" : : "r" (p));
f0103803:	b8 50 c3 11 f0       	mov    $0xf011c350,%eax
f0103808:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f010380b:	5d                   	pop    %ebp
f010380c:	c3                   	ret    

f010380d <trap_init>:
{
f010380d:	55                   	push   %ebp
f010380e:	89 e5                	mov    %esp,%ebp
	SETGATE(idt[T_DIVIDE], 0, GD_KT, handler0, 0);
f0103810:	b8 42 3f 10 f0       	mov    $0xf0103f42,%eax
f0103815:	66 a3 a0 df 17 f0    	mov    %ax,0xf017dfa0
f010381b:	66 c7 05 a2 df 17 f0 	movw   $0x8,0xf017dfa2
f0103822:	08 00 
f0103824:	c6 05 a4 df 17 f0 00 	movb   $0x0,0xf017dfa4
f010382b:	c6 05 a5 df 17 f0 8e 	movb   $0x8e,0xf017dfa5
f0103832:	c1 e8 10             	shr    $0x10,%eax
f0103835:	66 a3 a6 df 17 f0    	mov    %ax,0xf017dfa6
	SETGATE(idt[T_DEBUG], 0, GD_KT, handler1, 0);
f010383b:	b8 48 3f 10 f0       	mov    $0xf0103f48,%eax
f0103840:	66 a3 a8 df 17 f0    	mov    %ax,0xf017dfa8
f0103846:	66 c7 05 aa df 17 f0 	movw   $0x8,0xf017dfaa
f010384d:	08 00 
f010384f:	c6 05 ac df 17 f0 00 	movb   $0x0,0xf017dfac
f0103856:	c6 05 ad df 17 f0 8e 	movb   $0x8e,0xf017dfad
f010385d:	c1 e8 10             	shr    $0x10,%eax
f0103860:	66 a3 ae df 17 f0    	mov    %ax,0xf017dfae
	SETGATE(idt[T_NMI], 0, GD_KT, handler2, 0);
f0103866:	b8 4e 3f 10 f0       	mov    $0xf0103f4e,%eax
f010386b:	66 a3 b0 df 17 f0    	mov    %ax,0xf017dfb0
f0103871:	66 c7 05 b2 df 17 f0 	movw   $0x8,0xf017dfb2
f0103878:	08 00 
f010387a:	c6 05 b4 df 17 f0 00 	movb   $0x0,0xf017dfb4
f0103881:	c6 05 b5 df 17 f0 8e 	movb   $0x8e,0xf017dfb5
f0103888:	c1 e8 10             	shr    $0x10,%eax
f010388b:	66 a3 b6 df 17 f0    	mov    %ax,0xf017dfb6
	SETGATE(idt[T_BRKPT], 0, GD_KT, handler3, 3);
f0103891:	b8 54 3f 10 f0       	mov    $0xf0103f54,%eax
f0103896:	66 a3 b8 df 17 f0    	mov    %ax,0xf017dfb8
f010389c:	66 c7 05 ba df 17 f0 	movw   $0x8,0xf017dfba
f01038a3:	08 00 
f01038a5:	c6 05 bc df 17 f0 00 	movb   $0x0,0xf017dfbc
f01038ac:	c6 05 bd df 17 f0 ee 	movb   $0xee,0xf017dfbd
f01038b3:	c1 e8 10             	shr    $0x10,%eax
f01038b6:	66 a3 be df 17 f0    	mov    %ax,0xf017dfbe
	SETGATE(idt[T_OFLOW], 0, GD_KT, handler4, 0);
f01038bc:	b8 5a 3f 10 f0       	mov    $0xf0103f5a,%eax
f01038c1:	66 a3 c0 df 17 f0    	mov    %ax,0xf017dfc0
f01038c7:	66 c7 05 c2 df 17 f0 	movw   $0x8,0xf017dfc2
f01038ce:	08 00 
f01038d0:	c6 05 c4 df 17 f0 00 	movb   $0x0,0xf017dfc4
f01038d7:	c6 05 c5 df 17 f0 8e 	movb   $0x8e,0xf017dfc5
f01038de:	c1 e8 10             	shr    $0x10,%eax
f01038e1:	66 a3 c6 df 17 f0    	mov    %ax,0xf017dfc6
	SETGATE(idt[T_BOUND], 0, GD_KT, handler5, 0);
f01038e7:	b8 60 3f 10 f0       	mov    $0xf0103f60,%eax
f01038ec:	66 a3 c8 df 17 f0    	mov    %ax,0xf017dfc8
f01038f2:	66 c7 05 ca df 17 f0 	movw   $0x8,0xf017dfca
f01038f9:	08 00 
f01038fb:	c6 05 cc df 17 f0 00 	movb   $0x0,0xf017dfcc
f0103902:	c6 05 cd df 17 f0 8e 	movb   $0x8e,0xf017dfcd
f0103909:	c1 e8 10             	shr    $0x10,%eax
f010390c:	66 a3 ce df 17 f0    	mov    %ax,0xf017dfce
	SETGATE(idt[T_ILLOP], 0, GD_KT, handler6, 0);
f0103912:	b8 66 3f 10 f0       	mov    $0xf0103f66,%eax
f0103917:	66 a3 d0 df 17 f0    	mov    %ax,0xf017dfd0
f010391d:	66 c7 05 d2 df 17 f0 	movw   $0x8,0xf017dfd2
f0103924:	08 00 
f0103926:	c6 05 d4 df 17 f0 00 	movb   $0x0,0xf017dfd4
f010392d:	c6 05 d5 df 17 f0 8e 	movb   $0x8e,0xf017dfd5
f0103934:	c1 e8 10             	shr    $0x10,%eax
f0103937:	66 a3 d6 df 17 f0    	mov    %ax,0xf017dfd6
	SETGATE(idt[T_DEVICE], 0, GD_KT, handler7, 0);
f010393d:	b8 6c 3f 10 f0       	mov    $0xf0103f6c,%eax
f0103942:	66 a3 d8 df 17 f0    	mov    %ax,0xf017dfd8
f0103948:	66 c7 05 da df 17 f0 	movw   $0x8,0xf017dfda
f010394f:	08 00 
f0103951:	c6 05 dc df 17 f0 00 	movb   $0x0,0xf017dfdc
f0103958:	c6 05 dd df 17 f0 8e 	movb   $0x8e,0xf017dfdd
f010395f:	c1 e8 10             	shr    $0x10,%eax
f0103962:	66 a3 de df 17 f0    	mov    %ax,0xf017dfde
	SETGATE(idt[T_DBLFLT], 0, GD_KT, handler8, 0);
f0103968:	b8 72 3f 10 f0       	mov    $0xf0103f72,%eax
f010396d:	66 a3 e0 df 17 f0    	mov    %ax,0xf017dfe0
f0103973:	66 c7 05 e2 df 17 f0 	movw   $0x8,0xf017dfe2
f010397a:	08 00 
f010397c:	c6 05 e4 df 17 f0 00 	movb   $0x0,0xf017dfe4
f0103983:	c6 05 e5 df 17 f0 8e 	movb   $0x8e,0xf017dfe5
f010398a:	c1 e8 10             	shr    $0x10,%eax
f010398d:	66 a3 e6 df 17 f0    	mov    %ax,0xf017dfe6
	SETGATE(idt[T_TSS], 0, GD_KT, handler10, 0);
f0103993:	b8 76 3f 10 f0       	mov    $0xf0103f76,%eax
f0103998:	66 a3 f0 df 17 f0    	mov    %ax,0xf017dff0
f010399e:	66 c7 05 f2 df 17 f0 	movw   $0x8,0xf017dff2
f01039a5:	08 00 
f01039a7:	c6 05 f4 df 17 f0 00 	movb   $0x0,0xf017dff4
f01039ae:	c6 05 f5 df 17 f0 8e 	movb   $0x8e,0xf017dff5
f01039b5:	c1 e8 10             	shr    $0x10,%eax
f01039b8:	66 a3 f6 df 17 f0    	mov    %ax,0xf017dff6
	SETGATE(idt[T_SEGNP], 0, GD_KT, handler11, 0);
f01039be:	b8 7a 3f 10 f0       	mov    $0xf0103f7a,%eax
f01039c3:	66 a3 f8 df 17 f0    	mov    %ax,0xf017dff8
f01039c9:	66 c7 05 fa df 17 f0 	movw   $0x8,0xf017dffa
f01039d0:	08 00 
f01039d2:	c6 05 fc df 17 f0 00 	movb   $0x0,0xf017dffc
f01039d9:	c6 05 fd df 17 f0 8e 	movb   $0x8e,0xf017dffd
f01039e0:	c1 e8 10             	shr    $0x10,%eax
f01039e3:	66 a3 fe df 17 f0    	mov    %ax,0xf017dffe
	SETGATE(idt[T_STACK], 0, GD_KT, handler12, 0);
f01039e9:	b8 7e 3f 10 f0       	mov    $0xf0103f7e,%eax
f01039ee:	66 a3 00 e0 17 f0    	mov    %ax,0xf017e000
f01039f4:	66 c7 05 02 e0 17 f0 	movw   $0x8,0xf017e002
f01039fb:	08 00 
f01039fd:	c6 05 04 e0 17 f0 00 	movb   $0x0,0xf017e004
f0103a04:	c6 05 05 e0 17 f0 8e 	movb   $0x8e,0xf017e005
f0103a0b:	c1 e8 10             	shr    $0x10,%eax
f0103a0e:	66 a3 06 e0 17 f0    	mov    %ax,0xf017e006
	SETGATE(idt[T_GPFLT], 0, GD_KT, handler13, 0);
f0103a14:	b8 82 3f 10 f0       	mov    $0xf0103f82,%eax
f0103a19:	66 a3 08 e0 17 f0    	mov    %ax,0xf017e008
f0103a1f:	66 c7 05 0a e0 17 f0 	movw   $0x8,0xf017e00a
f0103a26:	08 00 
f0103a28:	c6 05 0c e0 17 f0 00 	movb   $0x0,0xf017e00c
f0103a2f:	c6 05 0d e0 17 f0 8e 	movb   $0x8e,0xf017e00d
f0103a36:	c1 e8 10             	shr    $0x10,%eax
f0103a39:	66 a3 0e e0 17 f0    	mov    %ax,0xf017e00e
	SETGATE(idt[T_PGFLT], 0, GD_KT, handler14, 0);
f0103a3f:	b8 86 3f 10 f0       	mov    $0xf0103f86,%eax
f0103a44:	66 a3 10 e0 17 f0    	mov    %ax,0xf017e010
f0103a4a:	66 c7 05 12 e0 17 f0 	movw   $0x8,0xf017e012
f0103a51:	08 00 
f0103a53:	c6 05 14 e0 17 f0 00 	movb   $0x0,0xf017e014
f0103a5a:	c6 05 15 e0 17 f0 8e 	movb   $0x8e,0xf017e015
f0103a61:	c1 e8 10             	shr    $0x10,%eax
f0103a64:	66 a3 16 e0 17 f0    	mov    %ax,0xf017e016
	SETGATE(idt[T_FPERR], 0, GD_KT, handler16, 0);
f0103a6a:	b8 8a 3f 10 f0       	mov    $0xf0103f8a,%eax
f0103a6f:	66 a3 20 e0 17 f0    	mov    %ax,0xf017e020
f0103a75:	66 c7 05 22 e0 17 f0 	movw   $0x8,0xf017e022
f0103a7c:	08 00 
f0103a7e:	c6 05 24 e0 17 f0 00 	movb   $0x0,0xf017e024
f0103a85:	c6 05 25 e0 17 f0 8e 	movb   $0x8e,0xf017e025
f0103a8c:	c1 e8 10             	shr    $0x10,%eax
f0103a8f:	66 a3 26 e0 17 f0    	mov    %ax,0xf017e026
	SETGATE(idt[T_ALIGN], 0, GD_KT, handler17, 0);
f0103a95:	b8 90 3f 10 f0       	mov    $0xf0103f90,%eax
f0103a9a:	66 a3 28 e0 17 f0    	mov    %ax,0xf017e028
f0103aa0:	66 c7 05 2a e0 17 f0 	movw   $0x8,0xf017e02a
f0103aa7:	08 00 
f0103aa9:	c6 05 2c e0 17 f0 00 	movb   $0x0,0xf017e02c
f0103ab0:	c6 05 2d e0 17 f0 8e 	movb   $0x8e,0xf017e02d
f0103ab7:	c1 e8 10             	shr    $0x10,%eax
f0103aba:	66 a3 2e e0 17 f0    	mov    %ax,0xf017e02e
	SETGATE(idt[T_MCHK], 0, GD_KT, handler18, 0);
f0103ac0:	b8 94 3f 10 f0       	mov    $0xf0103f94,%eax
f0103ac5:	66 a3 30 e0 17 f0    	mov    %ax,0xf017e030
f0103acb:	66 c7 05 32 e0 17 f0 	movw   $0x8,0xf017e032
f0103ad2:	08 00 
f0103ad4:	c6 05 34 e0 17 f0 00 	movb   $0x0,0xf017e034
f0103adb:	c6 05 35 e0 17 f0 8e 	movb   $0x8e,0xf017e035
f0103ae2:	c1 e8 10             	shr    $0x10,%eax
f0103ae5:	66 a3 36 e0 17 f0    	mov    %ax,0xf017e036
	SETGATE(idt[T_SIMDERR], 0, GD_KT, handler19, 0);
f0103aeb:	b8 9a 3f 10 f0       	mov    $0xf0103f9a,%eax
f0103af0:	66 a3 38 e0 17 f0    	mov    %ax,0xf017e038
f0103af6:	66 c7 05 3a e0 17 f0 	movw   $0x8,0xf017e03a
f0103afd:	08 00 
f0103aff:	c6 05 3c e0 17 f0 00 	movb   $0x0,0xf017e03c
f0103b06:	c6 05 3d e0 17 f0 8e 	movb   $0x8e,0xf017e03d
f0103b0d:	c1 e8 10             	shr    $0x10,%eax
f0103b10:	66 a3 3e e0 17 f0    	mov    %ax,0xf017e03e
	SETGATE(idt[T_SYSCALL], 0, GD_KT, handler48, 3);
f0103b16:	b8 a0 3f 10 f0       	mov    $0xf0103fa0,%eax
f0103b1b:	66 a3 20 e1 17 f0    	mov    %ax,0xf017e120
f0103b21:	66 c7 05 22 e1 17 f0 	movw   $0x8,0xf017e122
f0103b28:	08 00 
f0103b2a:	c6 05 24 e1 17 f0 00 	movb   $0x0,0xf017e124
f0103b31:	c6 05 25 e1 17 f0 ee 	movb   $0xee,0xf017e125
f0103b38:	c1 e8 10             	shr    $0x10,%eax
f0103b3b:	66 a3 26 e1 17 f0    	mov    %ax,0xf017e126
	trap_init_percpu();
f0103b41:	e8 6a fc ff ff       	call   f01037b0 <trap_init_percpu>
}
f0103b46:	5d                   	pop    %ebp
f0103b47:	c3                   	ret    

f0103b48 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103b48:	55                   	push   %ebp
f0103b49:	89 e5                	mov    %esp,%ebp
f0103b4b:	53                   	push   %ebx
f0103b4c:	83 ec 14             	sub    $0x14,%esp
f0103b4f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103b52:	8b 03                	mov    (%ebx),%eax
f0103b54:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b58:	c7 04 24 8a 62 10 f0 	movl   $0xf010628a,(%esp)
f0103b5f:	e8 28 fc ff ff       	call   f010378c <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103b64:	8b 43 04             	mov    0x4(%ebx),%eax
f0103b67:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b6b:	c7 04 24 99 62 10 f0 	movl   $0xf0106299,(%esp)
f0103b72:	e8 15 fc ff ff       	call   f010378c <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103b77:	8b 43 08             	mov    0x8(%ebx),%eax
f0103b7a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b7e:	c7 04 24 a8 62 10 f0 	movl   $0xf01062a8,(%esp)
f0103b85:	e8 02 fc ff ff       	call   f010378c <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103b8a:	8b 43 0c             	mov    0xc(%ebx),%eax
f0103b8d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b91:	c7 04 24 b7 62 10 f0 	movl   $0xf01062b7,(%esp)
f0103b98:	e8 ef fb ff ff       	call   f010378c <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103b9d:	8b 43 10             	mov    0x10(%ebx),%eax
f0103ba0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ba4:	c7 04 24 c6 62 10 f0 	movl   $0xf01062c6,(%esp)
f0103bab:	e8 dc fb ff ff       	call   f010378c <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103bb0:	8b 43 14             	mov    0x14(%ebx),%eax
f0103bb3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bb7:	c7 04 24 d5 62 10 f0 	movl   $0xf01062d5,(%esp)
f0103bbe:	e8 c9 fb ff ff       	call   f010378c <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103bc3:	8b 43 18             	mov    0x18(%ebx),%eax
f0103bc6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bca:	c7 04 24 e4 62 10 f0 	movl   $0xf01062e4,(%esp)
f0103bd1:	e8 b6 fb ff ff       	call   f010378c <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103bd6:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0103bd9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bdd:	c7 04 24 f3 62 10 f0 	movl   $0xf01062f3,(%esp)
f0103be4:	e8 a3 fb ff ff       	call   f010378c <cprintf>
}
f0103be9:	83 c4 14             	add    $0x14,%esp
f0103bec:	5b                   	pop    %ebx
f0103bed:	5d                   	pop    %ebp
f0103bee:	c3                   	ret    

f0103bef <print_trapframe>:
{
f0103bef:	55                   	push   %ebp
f0103bf0:	89 e5                	mov    %esp,%ebp
f0103bf2:	56                   	push   %esi
f0103bf3:	53                   	push   %ebx
f0103bf4:	83 ec 10             	sub    $0x10,%esp
f0103bf7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103bfa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103bfe:	c7 04 24 43 64 10 f0 	movl   $0xf0106443,(%esp)
f0103c05:	e8 82 fb ff ff       	call   f010378c <cprintf>
	print_regs(&tf->tf_regs);
f0103c0a:	89 1c 24             	mov    %ebx,(%esp)
f0103c0d:	e8 36 ff ff ff       	call   f0103b48 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103c12:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103c16:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c1a:	c7 04 24 44 63 10 f0 	movl   $0xf0106344,(%esp)
f0103c21:	e8 66 fb ff ff       	call   f010378c <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103c26:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103c2a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c2e:	c7 04 24 57 63 10 f0 	movl   $0xf0106357,(%esp)
f0103c35:	e8 52 fb ff ff       	call   f010378c <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103c3a:	8b 43 28             	mov    0x28(%ebx),%eax
	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103c3d:	83 f8 13             	cmp    $0x13,%eax
f0103c40:	77 09                	ja     f0103c4b <print_trapframe+0x5c>
		return excnames[trapno];
f0103c42:	8b 14 85 20 66 10 f0 	mov    -0xfef99e0(,%eax,4),%edx
f0103c49:	eb 10                	jmp    f0103c5b <print_trapframe+0x6c>
		return "System call";
f0103c4b:	83 f8 30             	cmp    $0x30,%eax
f0103c4e:	ba 02 63 10 f0       	mov    $0xf0106302,%edx
f0103c53:	b9 0e 63 10 f0       	mov    $0xf010630e,%ecx
f0103c58:	0f 45 d1             	cmovne %ecx,%edx
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103c5b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103c5f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c63:	c7 04 24 6a 63 10 f0 	movl   $0xf010636a,(%esp)
f0103c6a:	e8 1d fb ff ff       	call   f010378c <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103c6f:	3b 1d 08 e8 17 f0    	cmp    0xf017e808,%ebx
f0103c75:	75 19                	jne    f0103c90 <print_trapframe+0xa1>
f0103c77:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103c7b:	75 13                	jne    f0103c90 <print_trapframe+0xa1>
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103c7d:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103c80:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c84:	c7 04 24 7c 63 10 f0 	movl   $0xf010637c,(%esp)
f0103c8b:	e8 fc fa ff ff       	call   f010378c <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0103c90:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103c93:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c97:	c7 04 24 8b 63 10 f0 	movl   $0xf010638b,(%esp)
f0103c9e:	e8 e9 fa ff ff       	call   f010378c <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f0103ca3:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103ca7:	75 51                	jne    f0103cfa <print_trapframe+0x10b>
			tf->tf_err & 1 ? "protection" : "not-present");
f0103ca9:	8b 43 2c             	mov    0x2c(%ebx),%eax
		cprintf(" [%s, %s, %s]\n",
f0103cac:	89 c2                	mov    %eax,%edx
f0103cae:	83 e2 01             	and    $0x1,%edx
f0103cb1:	ba 1d 63 10 f0       	mov    $0xf010631d,%edx
f0103cb6:	b9 28 63 10 f0       	mov    $0xf0106328,%ecx
f0103cbb:	0f 45 ca             	cmovne %edx,%ecx
f0103cbe:	89 c2                	mov    %eax,%edx
f0103cc0:	83 e2 02             	and    $0x2,%edx
f0103cc3:	ba 34 63 10 f0       	mov    $0xf0106334,%edx
f0103cc8:	be 3a 63 10 f0       	mov    $0xf010633a,%esi
f0103ccd:	0f 44 d6             	cmove  %esi,%edx
f0103cd0:	83 e0 04             	and    $0x4,%eax
f0103cd3:	b8 3f 63 10 f0       	mov    $0xf010633f,%eax
f0103cd8:	be 6e 64 10 f0       	mov    $0xf010646e,%esi
f0103cdd:	0f 44 c6             	cmove  %esi,%eax
f0103ce0:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103ce4:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103ce8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cec:	c7 04 24 99 63 10 f0 	movl   $0xf0106399,(%esp)
f0103cf3:	e8 94 fa ff ff       	call   f010378c <cprintf>
f0103cf8:	eb 0c                	jmp    f0103d06 <print_trapframe+0x117>
		cprintf("\n");
f0103cfa:	c7 04 24 88 5f 10 f0 	movl   $0xf0105f88,(%esp)
f0103d01:	e8 86 fa ff ff       	call   f010378c <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103d06:	8b 43 30             	mov    0x30(%ebx),%eax
f0103d09:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d0d:	c7 04 24 a8 63 10 f0 	movl   $0xf01063a8,(%esp)
f0103d14:	e8 73 fa ff ff       	call   f010378c <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103d19:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103d1d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d21:	c7 04 24 b7 63 10 f0 	movl   $0xf01063b7,(%esp)
f0103d28:	e8 5f fa ff ff       	call   f010378c <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103d2d:	8b 43 38             	mov    0x38(%ebx),%eax
f0103d30:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d34:	c7 04 24 ca 63 10 f0 	movl   $0xf01063ca,(%esp)
f0103d3b:	e8 4c fa ff ff       	call   f010378c <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103d40:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103d44:	74 27                	je     f0103d6d <print_trapframe+0x17e>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103d46:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103d49:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d4d:	c7 04 24 d9 63 10 f0 	movl   $0xf01063d9,(%esp)
f0103d54:	e8 33 fa ff ff       	call   f010378c <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103d59:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103d5d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d61:	c7 04 24 e8 63 10 f0 	movl   $0xf01063e8,(%esp)
f0103d68:	e8 1f fa ff ff       	call   f010378c <cprintf>
}
f0103d6d:	83 c4 10             	add    $0x10,%esp
f0103d70:	5b                   	pop    %ebx
f0103d71:	5e                   	pop    %esi
f0103d72:	5d                   	pop    %ebp
f0103d73:	c3                   	ret    

f0103d74 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103d74:	55                   	push   %ebp
f0103d75:	89 e5                	mov    %esp,%ebp
f0103d77:	53                   	push   %ebx
f0103d78:	83 ec 14             	sub    $0x14,%esp
f0103d7b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103d7e:	0f 20 d0             	mov    %cr2,%eax
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs & 3) == 0) {
f0103d81:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103d85:	75 1c                	jne    f0103da3 <page_fault_handler+0x2f>
		panic("Page fault in kernel code");
f0103d87:	c7 44 24 08 fb 63 10 	movl   $0xf01063fb,0x8(%esp)
f0103d8e:	f0 
f0103d8f:	c7 44 24 04 07 01 00 	movl   $0x107,0x4(%esp)
f0103d96:	00 
f0103d97:	c7 04 24 15 64 10 f0 	movl   $0xf0106415,(%esp)
f0103d9e:	e8 13 c3 ff ff       	call   f01000b6 <_panic>
	}
	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103da3:	8b 53 30             	mov    0x30(%ebx),%edx
f0103da6:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103daa:	89 44 24 08          	mov    %eax,0x8(%esp)
		curenv->env_id, fault_va, tf->tf_eip);
f0103dae:	a1 88 df 17 f0       	mov    0xf017df88,%eax
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103db3:	8b 40 48             	mov    0x48(%eax),%eax
f0103db6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103dba:	c7 04 24 b8 65 10 f0 	movl   $0xf01065b8,(%esp)
f0103dc1:	e8 c6 f9 ff ff       	call   f010378c <cprintf>
	print_trapframe(tf);
f0103dc6:	89 1c 24             	mov    %ebx,(%esp)
f0103dc9:	e8 21 fe ff ff       	call   f0103bef <print_trapframe>
	env_destroy(curenv);
f0103dce:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0103dd3:	89 04 24             	mov    %eax,(%esp)
f0103dd6:	e8 7d f8 ff ff       	call   f0103658 <env_destroy>
}
f0103ddb:	83 c4 14             	add    $0x14,%esp
f0103dde:	5b                   	pop    %ebx
f0103ddf:	5d                   	pop    %ebp
f0103de0:	c3                   	ret    

f0103de1 <trap>:
{
f0103de1:	55                   	push   %ebp
f0103de2:	89 e5                	mov    %esp,%ebp
f0103de4:	57                   	push   %edi
f0103de5:	56                   	push   %esi
f0103de6:	83 ec 20             	sub    $0x20,%esp
f0103de9:	8b 75 08             	mov    0x8(%ebp),%esi
	asm volatile("cld" ::: "cc");
f0103dec:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103ded:	9c                   	pushf  
f0103dee:	58                   	pop    %eax
	assert(!(read_eflags() & FL_IF));
f0103def:	f6 c4 02             	test   $0x2,%ah
f0103df2:	74 24                	je     f0103e18 <trap+0x37>
f0103df4:	c7 44 24 0c 21 64 10 	movl   $0xf0106421,0xc(%esp)
f0103dfb:	f0 
f0103dfc:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0103e03:	f0 
f0103e04:	c7 44 24 04 de 00 00 	movl   $0xde,0x4(%esp)
f0103e0b:	00 
f0103e0c:	c7 04 24 15 64 10 f0 	movl   $0xf0106415,(%esp)
f0103e13:	e8 9e c2 ff ff       	call   f01000b6 <_panic>
	cprintf("Incoming TRAP frame at %p\n", tf);
f0103e18:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103e1c:	c7 04 24 3a 64 10 f0 	movl   $0xf010643a,(%esp)
f0103e23:	e8 64 f9 ff ff       	call   f010378c <cprintf>
	if ((tf->tf_cs & 3) == 3) {
f0103e28:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103e2c:	83 e0 03             	and    $0x3,%eax
f0103e2f:	66 83 f8 03          	cmp    $0x3,%ax
f0103e33:	75 3c                	jne    f0103e71 <trap+0x90>
		assert(curenv);
f0103e35:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0103e3a:	85 c0                	test   %eax,%eax
f0103e3c:	75 24                	jne    f0103e62 <trap+0x81>
f0103e3e:	c7 44 24 0c 55 64 10 	movl   $0xf0106455,0xc(%esp)
f0103e45:	f0 
f0103e46:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0103e4d:	f0 
f0103e4e:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
f0103e55:	00 
f0103e56:	c7 04 24 15 64 10 f0 	movl   $0xf0106415,(%esp)
f0103e5d:	e8 54 c2 ff ff       	call   f01000b6 <_panic>
		curenv->env_tf = *tf;
f0103e62:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103e67:	89 c7                	mov    %eax,%edi
f0103e69:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		tf = &curenv->env_tf;
f0103e6b:	8b 35 88 df 17 f0    	mov    0xf017df88,%esi
	last_tf = tf;
f0103e71:	89 35 08 e8 17 f0    	mov    %esi,0xf017e808
	if (tf->tf_trapno == T_PGFLT) {
f0103e77:	8b 46 28             	mov    0x28(%esi),%eax
f0103e7a:	83 f8 0e             	cmp    $0xe,%eax
f0103e7d:	75 0a                	jne    f0103e89 <trap+0xa8>
		page_fault_handler(tf);
f0103e7f:	89 34 24             	mov    %esi,(%esp)
f0103e82:	e8 ed fe ff ff       	call   f0103d74 <page_fault_handler>
f0103e87:	eb 7e                	jmp    f0103f07 <trap+0x126>
	if (tf->tf_trapno == T_BRKPT) {
f0103e89:	83 f8 03             	cmp    $0x3,%eax
f0103e8c:	75 0a                	jne    f0103e98 <trap+0xb7>
		monitor(tf);
f0103e8e:	89 34 24             	mov    %esi,(%esp)
f0103e91:	e8 60 c9 ff ff       	call   f01007f6 <monitor>
f0103e96:	eb 6f                	jmp    f0103f07 <trap+0x126>
	if (tf->tf_trapno == T_SYSCALL) {
f0103e98:	83 f8 30             	cmp    $0x30,%eax
f0103e9b:	75 32                	jne    f0103ecf <trap+0xee>
		tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f0103e9d:	8b 46 04             	mov    0x4(%esi),%eax
f0103ea0:	89 44 24 14          	mov    %eax,0x14(%esp)
f0103ea4:	8b 06                	mov    (%esi),%eax
f0103ea6:	89 44 24 10          	mov    %eax,0x10(%esp)
f0103eaa:	8b 46 10             	mov    0x10(%esi),%eax
f0103ead:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103eb1:	8b 46 18             	mov    0x18(%esi),%eax
f0103eb4:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103eb8:	8b 46 14             	mov    0x14(%esi),%eax
f0103ebb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ebf:	8b 46 1c             	mov    0x1c(%esi),%eax
f0103ec2:	89 04 24             	mov    %eax,(%esp)
f0103ec5:	e8 f6 00 00 00       	call   f0103fc0 <syscall>
f0103eca:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103ecd:	eb 38                	jmp    f0103f07 <trap+0x126>
	print_trapframe(tf);
f0103ecf:	89 34 24             	mov    %esi,(%esp)
f0103ed2:	e8 18 fd ff ff       	call   f0103bef <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103ed7:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103edc:	75 1c                	jne    f0103efa <trap+0x119>
		panic("unhandled trap in kernel");
f0103ede:	c7 44 24 08 5c 64 10 	movl   $0xf010645c,0x8(%esp)
f0103ee5:	f0 
f0103ee6:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
f0103eed:	00 
f0103eee:	c7 04 24 15 64 10 f0 	movl   $0xf0106415,(%esp)
f0103ef5:	e8 bc c1 ff ff       	call   f01000b6 <_panic>
		env_destroy(curenv);
f0103efa:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0103eff:	89 04 24             	mov    %eax,(%esp)
f0103f02:	e8 51 f7 ff ff       	call   f0103658 <env_destroy>
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103f07:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0103f0c:	85 c0                	test   %eax,%eax
f0103f0e:	74 06                	je     f0103f16 <trap+0x135>
f0103f10:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103f14:	74 24                	je     f0103f3a <trap+0x159>
f0103f16:	c7 44 24 0c dc 65 10 	movl   $0xf01065dc,0xc(%esp)
f0103f1d:	f0 
f0103f1e:	c7 44 24 08 c9 5e 10 	movl   $0xf0105ec9,0x8(%esp)
f0103f25:	f0 
f0103f26:	c7 44 24 04 f6 00 00 	movl   $0xf6,0x4(%esp)
f0103f2d:	00 
f0103f2e:	c7 04 24 15 64 10 f0 	movl   $0xf0106415,(%esp)
f0103f35:	e8 7c c1 ff ff       	call   f01000b6 <_panic>
	env_run(curenv);
f0103f3a:	89 04 24             	mov    %eax,(%esp)
f0103f3d:	e8 6d f7 ff ff       	call   f01036af <env_run>

f0103f42 <handler0>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(handler0, T_DIVIDE)
f0103f42:	6a 00                	push   $0x0
f0103f44:	6a 00                	push   $0x0
f0103f46:	eb 5e                	jmp    f0103fa6 <_alltraps>

f0103f48 <handler1>:
TRAPHANDLER_NOEC(handler1, T_DEBUG)
f0103f48:	6a 00                	push   $0x0
f0103f4a:	6a 01                	push   $0x1
f0103f4c:	eb 58                	jmp    f0103fa6 <_alltraps>

f0103f4e <handler2>:
TRAPHANDLER_NOEC(handler2, T_NMI)
f0103f4e:	6a 00                	push   $0x0
f0103f50:	6a 02                	push   $0x2
f0103f52:	eb 52                	jmp    f0103fa6 <_alltraps>

f0103f54 <handler3>:
TRAPHANDLER_NOEC(handler3, T_BRKPT)
f0103f54:	6a 00                	push   $0x0
f0103f56:	6a 03                	push   $0x3
f0103f58:	eb 4c                	jmp    f0103fa6 <_alltraps>

f0103f5a <handler4>:
TRAPHANDLER_NOEC(handler4, T_OFLOW)
f0103f5a:	6a 00                	push   $0x0
f0103f5c:	6a 04                	push   $0x4
f0103f5e:	eb 46                	jmp    f0103fa6 <_alltraps>

f0103f60 <handler5>:
TRAPHANDLER_NOEC(handler5, T_BOUND)
f0103f60:	6a 00                	push   $0x0
f0103f62:	6a 05                	push   $0x5
f0103f64:	eb 40                	jmp    f0103fa6 <_alltraps>

f0103f66 <handler6>:
TRAPHANDLER_NOEC(handler6, T_ILLOP)
f0103f66:	6a 00                	push   $0x0
f0103f68:	6a 06                	push   $0x6
f0103f6a:	eb 3a                	jmp    f0103fa6 <_alltraps>

f0103f6c <handler7>:
TRAPHANDLER_NOEC(handler7, T_DEVICE)
f0103f6c:	6a 00                	push   $0x0
f0103f6e:	6a 07                	push   $0x7
f0103f70:	eb 34                	jmp    f0103fa6 <_alltraps>

f0103f72 <handler8>:
TRAPHANDLER(handler8, T_DBLFLT)
f0103f72:	6a 08                	push   $0x8
f0103f74:	eb 30                	jmp    f0103fa6 <_alltraps>

f0103f76 <handler10>:
TRAPHANDLER(handler10, T_TSS)
f0103f76:	6a 0a                	push   $0xa
f0103f78:	eb 2c                	jmp    f0103fa6 <_alltraps>

f0103f7a <handler11>:
TRAPHANDLER(handler11, T_SEGNP)
f0103f7a:	6a 0b                	push   $0xb
f0103f7c:	eb 28                	jmp    f0103fa6 <_alltraps>

f0103f7e <handler12>:
TRAPHANDLER(handler12, T_STACK)
f0103f7e:	6a 0c                	push   $0xc
f0103f80:	eb 24                	jmp    f0103fa6 <_alltraps>

f0103f82 <handler13>:
TRAPHANDLER(handler13, T_GPFLT)
f0103f82:	6a 0d                	push   $0xd
f0103f84:	eb 20                	jmp    f0103fa6 <_alltraps>

f0103f86 <handler14>:
TRAPHANDLER(handler14, T_PGFLT)
f0103f86:	6a 0e                	push   $0xe
f0103f88:	eb 1c                	jmp    f0103fa6 <_alltraps>

f0103f8a <handler16>:
TRAPHANDLER_NOEC(handler16, T_FPERR)
f0103f8a:	6a 00                	push   $0x0
f0103f8c:	6a 10                	push   $0x10
f0103f8e:	eb 16                	jmp    f0103fa6 <_alltraps>

f0103f90 <handler17>:
TRAPHANDLER(handler17, T_ALIGN)
f0103f90:	6a 11                	push   $0x11
f0103f92:	eb 12                	jmp    f0103fa6 <_alltraps>

f0103f94 <handler18>:
TRAPHANDLER_NOEC(handler18, T_MCHK)
f0103f94:	6a 00                	push   $0x0
f0103f96:	6a 12                	push   $0x12
f0103f98:	eb 0c                	jmp    f0103fa6 <_alltraps>

f0103f9a <handler19>:
TRAPHANDLER_NOEC(handler19, T_SIMDERR)
f0103f9a:	6a 00                	push   $0x0
f0103f9c:	6a 13                	push   $0x13
f0103f9e:	eb 06                	jmp    f0103fa6 <_alltraps>

f0103fa0 <handler48>:
TRAPHANDLER_NOEC(handler48, T_SYSCALL)
f0103fa0:	6a 00                	push   $0x0
f0103fa2:	6a 30                	push   $0x30
f0103fa4:	eb 00                	jmp    f0103fa6 <_alltraps>

f0103fa6 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds
f0103fa6:	1e                   	push   %ds
	pushl %es
f0103fa7:	06                   	push   %es
	pushal
f0103fa8:	60                   	pusha  

	movw $GD_KD, %ax
f0103fa9:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0103fad:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0103faf:	8e c0                	mov    %eax,%es

	pushl %esp
f0103fb1:	54                   	push   %esp
	call trap
f0103fb2:	e8 2a fe ff ff       	call   f0103de1 <trap>
f0103fb7:	66 90                	xchg   %ax,%ax
f0103fb9:	66 90                	xchg   %ax,%ax
f0103fbb:	66 90                	xchg   %ax,%ax
f0103fbd:	66 90                	xchg   %ax,%ax
f0103fbf:	90                   	nop

f0103fc0 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103fc0:	55                   	push   %ebp
f0103fc1:	89 e5                	mov    %esp,%ebp
f0103fc3:	83 ec 28             	sub    $0x28,%esp
f0103fc6:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno) {
f0103fc9:	83 f8 01             	cmp    $0x1,%eax
f0103fcc:	74 5c                	je     f010402a <syscall+0x6a>
f0103fce:	83 f8 01             	cmp    $0x1,%eax
f0103fd1:	72 10                	jb     f0103fe3 <syscall+0x23>
f0103fd3:	83 f8 02             	cmp    $0x2,%eax
f0103fd6:	74 5a                	je     f0104032 <syscall+0x72>
f0103fd8:	83 f8 03             	cmp    $0x3,%eax
f0103fdb:	0f 85 c7 00 00 00    	jne    f01040a8 <syscall+0xe8>
f0103fe1:	eb 59                	jmp    f010403c <syscall+0x7c>
       user_mem_assert(curenv, s, len, PTE_U);
f0103fe3:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0103fea:	00 
f0103feb:	8b 45 10             	mov    0x10(%ebp),%eax
f0103fee:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103ff2:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103ff5:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103ff9:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0103ffe:	89 04 24             	mov    %eax,(%esp)
f0104001:	e8 55 ef ff ff       	call   f0102f5b <user_mem_assert>
	cprintf("%.*s", len, s);
f0104006:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104009:	89 44 24 08          	mov    %eax,0x8(%esp)
f010400d:	8b 55 10             	mov    0x10(%ebp),%edx
f0104010:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104014:	c7 04 24 70 66 10 f0 	movl   $0xf0106670,(%esp)
f010401b:	e8 6c f7 ff ff       	call   f010378c <cprintf>
		return sys_env_destroy(a1);
		break; 
	default:
		return -E_INVAL;
	}
	return 0;
f0104020:	b8 00 00 00 00       	mov    $0x0,%eax
f0104025:	e9 83 00 00 00       	jmp    f01040ad <syscall+0xed>
	return cons_getc();
f010402a:	e8 a9 c4 ff ff       	call   f01004d8 <cons_getc>
		return sys_cgetc();
f010402f:	90                   	nop
f0104030:	eb 7b                	jmp    f01040ad <syscall+0xed>
	return curenv->env_id;
f0104032:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0104037:	8b 40 48             	mov    0x48(%eax),%eax
		return sys_getenvid();
f010403a:	eb 71                	jmp    f01040ad <syscall+0xed>
	if ((r = envid2env(envid, &e, 1)) < 0)
f010403c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104043:	00 
f0104044:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104047:	89 44 24 04          	mov    %eax,0x4(%esp)
f010404b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010404e:	89 04 24             	mov    %eax,(%esp)
f0104051:	e8 f8 ef ff ff       	call   f010304e <envid2env>
f0104056:	85 c0                	test   %eax,%eax
f0104058:	78 53                	js     f01040ad <syscall+0xed>
	if (e == curenv)
f010405a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010405d:	8b 15 88 df 17 f0    	mov    0xf017df88,%edx
f0104063:	39 d0                	cmp    %edx,%eax
f0104065:	75 15                	jne    f010407c <syscall+0xbc>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104067:	8b 40 48             	mov    0x48(%eax),%eax
f010406a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010406e:	c7 04 24 75 66 10 f0 	movl   $0xf0106675,(%esp)
f0104075:	e8 12 f7 ff ff       	call   f010378c <cprintf>
f010407a:	eb 1a                	jmp    f0104096 <syscall+0xd6>
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010407c:	8b 40 48             	mov    0x48(%eax),%eax
f010407f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104083:	8b 42 48             	mov    0x48(%edx),%eax
f0104086:	89 44 24 04          	mov    %eax,0x4(%esp)
f010408a:	c7 04 24 90 66 10 f0 	movl   $0xf0106690,(%esp)
f0104091:	e8 f6 f6 ff ff       	call   f010378c <cprintf>
	env_destroy(e);
f0104096:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104099:	89 04 24             	mov    %eax,(%esp)
f010409c:	e8 b7 f5 ff ff       	call   f0103658 <env_destroy>
	return 0;
f01040a1:	b8 00 00 00 00       	mov    $0x0,%eax
		return sys_env_destroy(a1);
f01040a6:	eb 05                	jmp    f01040ad <syscall+0xed>
		return -E_INVAL;
f01040a8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
f01040ad:	c9                   	leave  
f01040ae:	c3                   	ret    

f01040af <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01040af:	55                   	push   %ebp
f01040b0:	89 e5                	mov    %esp,%ebp
f01040b2:	57                   	push   %edi
f01040b3:	56                   	push   %esi
f01040b4:	53                   	push   %ebx
f01040b5:	83 ec 14             	sub    $0x14,%esp
f01040b8:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01040bb:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01040be:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01040c1:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f01040c4:	8b 1a                	mov    (%edx),%ebx
f01040c6:	8b 01                	mov    (%ecx),%eax
f01040c8:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01040cb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

	while (l <= r) {
f01040d2:	e9 88 00 00 00       	jmp    f010415f <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f01040d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01040da:	01 d8                	add    %ebx,%eax
f01040dc:	89 c7                	mov    %eax,%edi
f01040de:	c1 ef 1f             	shr    $0x1f,%edi
f01040e1:	01 c7                	add    %eax,%edi
f01040e3:	d1 ff                	sar    %edi

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01040e5:	8d 04 7f             	lea    (%edi,%edi,2),%eax
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01040e8:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01040eb:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
		int true_m = (l + r) / 2, m = true_m;
f01040ef:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f01040f1:	eb 03                	jmp    f01040f6 <stab_binsearch+0x47>
			m--;
f01040f3:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f01040f6:	39 c3                	cmp    %eax,%ebx
f01040f8:	7f 1e                	jg     f0104118 <stab_binsearch+0x69>
f01040fa:	0f b6 0a             	movzbl (%edx),%ecx
f01040fd:	83 ea 0c             	sub    $0xc,%edx
f0104100:	39 f1                	cmp    %esi,%ecx
f0104102:	75 ef                	jne    f01040f3 <stab_binsearch+0x44>
f0104104:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104107:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010410a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010410d:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104111:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104114:	76 18                	jbe    f010412e <stab_binsearch+0x7f>
f0104116:	eb 05                	jmp    f010411d <stab_binsearch+0x6e>
			l = true_m + 1;
f0104118:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f010411b:	eb 42                	jmp    f010415f <stab_binsearch+0xb0>
			*region_left = m;
f010411d:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0104120:	89 02                	mov    %eax,(%edx)
			l = true_m + 1;
f0104122:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f0104125:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f010412c:	eb 31                	jmp    f010415f <stab_binsearch+0xb0>
		} else if (stabs[m].n_value > addr) {
f010412e:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104131:	73 17                	jae    f010414a <stab_binsearch+0x9b>
			*region_right = m - 1;
f0104133:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0104136:	83 e9 01             	sub    $0x1,%ecx
f0104139:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010413c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010413f:	89 08                	mov    %ecx,(%eax)
		any_matches = 1;
f0104141:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0104148:	eb 15                	jmp    f010415f <stab_binsearch+0xb0>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010414a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010414d:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0104150:	89 0a                	mov    %ecx,(%edx)
			l = m;
			addr++;
f0104152:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104156:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f0104158:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
	while (l <= r) {
f010415f:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104162:	0f 8e 6f ff ff ff    	jle    f01040d7 <stab_binsearch+0x28>
		}
	}

	if (!any_matches)
f0104168:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010416c:	75 0f                	jne    f010417d <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f010416e:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0104171:	8b 02                	mov    (%edx),%eax
f0104173:	83 e8 01             	sub    $0x1,%eax
f0104176:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104179:	89 01                	mov    %eax,(%ecx)
f010417b:	eb 2c                	jmp    f01041a9 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010417d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104180:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104182:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0104185:	8b 0a                	mov    (%edx),%ecx
f0104187:	8d 14 40             	lea    (%eax,%eax,2),%edx
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f010418a:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f010418d:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		for (l = *region_right;
f0104191:	eb 03                	jmp    f0104196 <stab_binsearch+0xe7>
		     l--)
f0104193:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0104196:	39 c8                	cmp    %ecx,%eax
f0104198:	7e 0a                	jle    f01041a4 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f010419a:	0f b6 1a             	movzbl (%edx),%ebx
f010419d:	83 ea 0c             	sub    $0xc,%edx
f01041a0:	39 f3                	cmp    %esi,%ebx
f01041a2:	75 ef                	jne    f0104193 <stab_binsearch+0xe4>
			/* do nothing */;
		*region_left = l;
f01041a4:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01041a7:	89 02                	mov    %eax,(%edx)
	}
}
f01041a9:	83 c4 14             	add    $0x14,%esp
f01041ac:	5b                   	pop    %ebx
f01041ad:	5e                   	pop    %esi
f01041ae:	5f                   	pop    %edi
f01041af:	5d                   	pop    %ebp
f01041b0:	c3                   	ret    

f01041b1 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01041b1:	55                   	push   %ebp
f01041b2:	89 e5                	mov    %esp,%ebp
f01041b4:	57                   	push   %edi
f01041b5:	56                   	push   %esi
f01041b6:	53                   	push   %ebx
f01041b7:	83 ec 5c             	sub    $0x5c,%esp
f01041ba:	8b 75 08             	mov    0x8(%ebp),%esi
f01041bd:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01041c0:	c7 07 a8 66 10 f0    	movl   $0xf01066a8,(%edi)
	info->eip_line = 0;
f01041c6:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f01041cd:	c7 47 08 a8 66 10 f0 	movl   $0xf01066a8,0x8(%edi)
	info->eip_fn_namelen = 9;
f01041d4:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f01041db:	89 77 10             	mov    %esi,0x10(%edi)
	info->eip_fn_narg = 0;
f01041de:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01041e5:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01041eb:	0f 87 b2 00 00 00    	ja     f01042a3 <debuginfo_eip+0xf2>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
                if (user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U) < 0) {
f01041f1:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f01041f8:	00 
f01041f9:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0104200:	00 
f0104201:	c7 44 24 04 00 00 20 	movl   $0x200000,0x4(%esp)
f0104208:	00 
f0104209:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f010420e:	89 04 24             	mov    %eax,(%esp)
f0104211:	e8 aa ec ff ff       	call   f0102ec0 <user_mem_check>
f0104216:	85 c0                	test   %eax,%eax
f0104218:	0f 88 56 02 00 00    	js     f0104474 <debuginfo_eip+0x2c3>
			return -1;
		}
		stabs = usd->stabs;
f010421e:	8b 1d 00 00 20 00    	mov    0x200000,%ebx
f0104224:	89 5d c4             	mov    %ebx,-0x3c(%ebp)
		stab_end = usd->stab_end;
f0104227:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f010422d:	a1 08 00 20 00       	mov    0x200008,%eax
f0104232:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0104235:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f010423b:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, stab_end-stabs, PTE_U) < 0 || 
f010423e:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0104245:	00 
f0104246:	89 d8                	mov    %ebx,%eax
f0104248:	2b 45 c4             	sub    -0x3c(%ebp),%eax
f010424b:	c1 f8 02             	sar    $0x2,%eax
f010424e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0104254:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104258:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f010425b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010425f:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0104264:	89 04 24             	mov    %eax,(%esp)
f0104267:	e8 54 ec ff ff       	call   f0102ec0 <user_mem_check>
f010426c:	85 c0                	test   %eax,%eax
f010426e:	0f 88 07 02 00 00    	js     f010447b <debuginfo_eip+0x2ca>
	 	    user_mem_check(curenv, stabstr, stabstr_end-stabstr, PTE_U) < 0) {
f0104274:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f010427b:	00 
f010427c:	8b 45 bc             	mov    -0x44(%ebp),%eax
f010427f:	2b 45 c0             	sub    -0x40(%ebp),%eax
f0104282:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104286:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0104289:	89 44 24 04          	mov    %eax,0x4(%esp)
f010428d:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0104292:	89 04 24             	mov    %eax,(%esp)
f0104295:	e8 26 ec ff ff       	call   f0102ec0 <user_mem_check>
		if (user_mem_check(curenv, stabs, stab_end-stabs, PTE_U) < 0 || 
f010429a:	85 c0                	test   %eax,%eax
f010429c:	79 1f                	jns    f01042bd <debuginfo_eip+0x10c>
f010429e:	e9 df 01 00 00       	jmp    f0104482 <debuginfo_eip+0x2d1>
		stabstr_end = __STABSTR_END__;
f01042a3:	c7 45 bc b2 15 11 f0 	movl   $0xf01115b2,-0x44(%ebp)
		stabstr = __STABSTR_BEGIN__;
f01042aa:	c7 45 c0 9d ea 10 f0 	movl   $0xf010ea9d,-0x40(%ebp)
		stab_end = __STAB_END__;
f01042b1:	bb 9c ea 10 f0       	mov    $0xf010ea9c,%ebx
		stabs = __STAB_BEGIN__;
f01042b6:	c7 45 c4 d0 68 10 f0 	movl   $0xf01068d0,-0x3c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01042bd:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01042c0:	39 55 c0             	cmp    %edx,-0x40(%ebp)
f01042c3:	0f 83 c0 01 00 00    	jae    f0104489 <debuginfo_eip+0x2d8>
f01042c9:	80 7a ff 00          	cmpb   $0x0,-0x1(%edx)
f01042cd:	0f 85 bd 01 00 00    	jne    f0104490 <debuginfo_eip+0x2df>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01042d3:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01042da:	2b 5d c4             	sub    -0x3c(%ebp),%ebx
f01042dd:	c1 fb 02             	sar    $0x2,%ebx
f01042e0:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f01042e6:	83 e8 01             	sub    $0x1,%eax
f01042e9:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01042ec:	89 74 24 04          	mov    %esi,0x4(%esp)
f01042f0:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01042f7:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01042fa:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01042fd:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0104300:	e8 aa fd ff ff       	call   f01040af <stab_binsearch>
	if (lfile == 0)
f0104305:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104308:	85 c0                	test   %eax,%eax
f010430a:	0f 84 87 01 00 00    	je     f0104497 <debuginfo_eip+0x2e6>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104310:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104313:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104316:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104319:	89 74 24 04          	mov    %esi,0x4(%esp)
f010431d:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0104324:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104327:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010432a:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010432d:	e8 7d fd ff ff       	call   f01040af <stab_binsearch>

	if (lfun <= rfun) {
f0104332:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104335:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0104338:	39 c8                	cmp    %ecx,%eax
f010433a:	7f 32                	jg     f010436e <debuginfo_eip+0x1bd>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010433c:	8d 1c 40             	lea    (%eax,%eax,2),%ebx
f010433f:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0104342:	8d 1c 9a             	lea    (%edx,%ebx,4),%ebx
f0104345:	8b 13                	mov    (%ebx),%edx
f0104347:	89 55 b4             	mov    %edx,-0x4c(%ebp)
f010434a:	8b 55 bc             	mov    -0x44(%ebp),%edx
f010434d:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104350:	39 55 b4             	cmp    %edx,-0x4c(%ebp)
f0104353:	73 09                	jae    f010435e <debuginfo_eip+0x1ad>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104355:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f0104358:	03 55 c0             	add    -0x40(%ebp),%edx
f010435b:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010435e:	8b 53 08             	mov    0x8(%ebx),%edx
f0104361:	89 57 10             	mov    %edx,0x10(%edi)
		addr -= info->eip_fn_addr;
f0104364:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0104366:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104369:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f010436c:	eb 0f                	jmp    f010437d <debuginfo_eip+0x1cc>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010436e:	89 77 10             	mov    %esi,0x10(%edi)
		lline = lfile;
f0104371:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104374:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104377:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010437a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010437d:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0104384:	00 
f0104385:	8b 47 08             	mov    0x8(%edi),%eax
f0104388:	89 04 24             	mov    %eax,(%esp)
f010438b:	e8 47 09 00 00       	call   f0104cd7 <strfind>
f0104390:	2b 47 08             	sub    0x8(%edi),%eax
f0104393:	89 47 0c             	mov    %eax,0xc(%edi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	info->eip_file = stabstr + stabs[lfile].n_strx;
f0104396:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104399:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010439c:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f010439f:	8b 04 83             	mov    (%ebx,%eax,4),%eax
f01043a2:	03 45 c0             	add    -0x40(%ebp),%eax
f01043a5:	89 07                	mov    %eax,(%edi)

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01043a7:	89 74 24 04          	mov    %esi,0x4(%esp)
f01043ab:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f01043b2:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01043b5:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01043b8:	89 d8                	mov    %ebx,%eax
f01043ba:	e8 f0 fc ff ff       	call   f01040af <stab_binsearch>
	if (lline > rline) {
f01043bf:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01043c2:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01043c5:	0f 8f d3 00 00 00    	jg     f010449e <debuginfo_eip+0x2ed>
	    return -1;
	} else {
	    info->eip_line = stabs[rline].n_desc;
f01043cb:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01043ce:	0f b7 44 83 06       	movzwl 0x6(%ebx,%eax,4),%eax
f01043d3:	89 47 04             	mov    %eax,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01043d6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01043d9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01043dc:	8d 14 40             	lea    (%eax,%eax,2),%edx
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f01043df:	8d 54 93 08          	lea    0x8(%ebx,%edx,4),%edx
f01043e3:	89 7d b8             	mov    %edi,-0x48(%ebp)
f01043e6:	89 cf                	mov    %ecx,%edi
	while (lline >= lfile
f01043e8:	eb 06                	jmp    f01043f0 <debuginfo_eip+0x23f>
f01043ea:	83 e8 01             	sub    $0x1,%eax
f01043ed:	83 ea 0c             	sub    $0xc,%edx
f01043f0:	89 c6                	mov    %eax,%esi
f01043f2:	39 c7                	cmp    %eax,%edi
f01043f4:	7f 3b                	jg     f0104431 <debuginfo_eip+0x280>
	       && stabs[lline].n_type != N_SOL
f01043f6:	0f b6 4a fc          	movzbl -0x4(%edx),%ecx
f01043fa:	80 f9 84             	cmp    $0x84,%cl
f01043fd:	75 08                	jne    f0104407 <debuginfo_eip+0x256>
f01043ff:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0104402:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104405:	eb 10                	jmp    f0104417 <debuginfo_eip+0x266>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104407:	80 f9 64             	cmp    $0x64,%cl
f010440a:	75 de                	jne    f01043ea <debuginfo_eip+0x239>
f010440c:	83 3a 00             	cmpl   $0x0,(%edx)
f010440f:	74 d9                	je     f01043ea <debuginfo_eip+0x239>
f0104411:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0104414:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104417:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010441a:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f010441d:	8b 04 83             	mov    (%ebx,%eax,4),%eax
f0104420:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104423:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104426:	39 d0                	cmp    %edx,%eax
f0104428:	73 0a                	jae    f0104434 <debuginfo_eip+0x283>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010442a:	03 45 c0             	add    -0x40(%ebp),%eax
f010442d:	89 07                	mov    %eax,(%edi)
f010442f:	eb 03                	jmp    f0104434 <debuginfo_eip+0x283>
f0104431:	8b 7d b8             	mov    -0x48(%ebp),%edi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104434:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104437:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010443a:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f010443f:	39 da                	cmp    %ebx,%edx
f0104441:	7d 67                	jge    f01044aa <debuginfo_eip+0x2f9>
		for (lline = lfun + 1;
f0104443:	83 c2 01             	add    $0x1,%edx
f0104446:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104449:	89 d0                	mov    %edx,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010444b:	8d 14 52             	lea    (%edx,%edx,2),%edx
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f010444e:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0104451:	8d 54 91 04          	lea    0x4(%ecx,%edx,4),%edx
		for (lline = lfun + 1;
f0104455:	eb 04                	jmp    f010445b <debuginfo_eip+0x2aa>
			info->eip_fn_narg++;
f0104457:	83 47 14 01          	addl   $0x1,0x14(%edi)
		for (lline = lfun + 1;
f010445b:	39 c3                	cmp    %eax,%ebx
f010445d:	7e 46                	jle    f01044a5 <debuginfo_eip+0x2f4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010445f:	0f b6 0a             	movzbl (%edx),%ecx
f0104462:	83 c0 01             	add    $0x1,%eax
f0104465:	83 c2 0c             	add    $0xc,%edx
f0104468:	80 f9 a0             	cmp    $0xa0,%cl
f010446b:	74 ea                	je     f0104457 <debuginfo_eip+0x2a6>
	return 0;
f010446d:	b8 00 00 00 00       	mov    $0x0,%eax
f0104472:	eb 36                	jmp    f01044aa <debuginfo_eip+0x2f9>
			return -1;
f0104474:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104479:	eb 2f                	jmp    f01044aa <debuginfo_eip+0x2f9>
			return -1;
f010447b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104480:	eb 28                	jmp    f01044aa <debuginfo_eip+0x2f9>
f0104482:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104487:	eb 21                	jmp    f01044aa <debuginfo_eip+0x2f9>
		return -1;
f0104489:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010448e:	eb 1a                	jmp    f01044aa <debuginfo_eip+0x2f9>
f0104490:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104495:	eb 13                	jmp    f01044aa <debuginfo_eip+0x2f9>
		return -1;
f0104497:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010449c:	eb 0c                	jmp    f01044aa <debuginfo_eip+0x2f9>
	    return -1;
f010449e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01044a3:	eb 05                	jmp    f01044aa <debuginfo_eip+0x2f9>
	return 0;
f01044a5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01044aa:	83 c4 5c             	add    $0x5c,%esp
f01044ad:	5b                   	pop    %ebx
f01044ae:	5e                   	pop    %esi
f01044af:	5f                   	pop    %edi
f01044b0:	5d                   	pop    %ebp
f01044b1:	c3                   	ret    
f01044b2:	66 90                	xchg   %ax,%ax
f01044b4:	66 90                	xchg   %ax,%ax
f01044b6:	66 90                	xchg   %ax,%ax
f01044b8:	66 90                	xchg   %ax,%ax
f01044ba:	66 90                	xchg   %ax,%ax
f01044bc:	66 90                	xchg   %ax,%ax
f01044be:	66 90                	xchg   %ax,%ax

f01044c0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01044c0:	55                   	push   %ebp
f01044c1:	89 e5                	mov    %esp,%ebp
f01044c3:	57                   	push   %edi
f01044c4:	56                   	push   %esi
f01044c5:	53                   	push   %ebx
f01044c6:	83 ec 4c             	sub    $0x4c,%esp
f01044c9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01044cc:	89 d7                	mov    %edx,%edi
f01044ce:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01044d1:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01044d4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01044d7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01044da:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01044dd:	85 db                	test   %ebx,%ebx
f01044df:	75 08                	jne    f01044e9 <printnum+0x29>
f01044e1:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01044e4:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f01044e7:	77 6c                	ja     f0104555 <printnum+0x95>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01044e9:	8b 5d 18             	mov    0x18(%ebp),%ebx
f01044ec:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f01044f0:	83 ee 01             	sub    $0x1,%esi
f01044f3:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01044f7:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01044fa:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01044fe:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104502:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0104506:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104509:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010450c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0104513:	00 
f0104514:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0104517:	89 1c 24             	mov    %ebx,(%esp)
f010451a:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010451d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104521:	e8 fa 09 00 00       	call   f0104f20 <__udivdi3>
f0104526:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104529:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010452c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104530:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0104534:	89 04 24             	mov    %eax,(%esp)
f0104537:	89 54 24 04          	mov    %edx,0x4(%esp)
f010453b:	89 fa                	mov    %edi,%edx
f010453d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104540:	e8 7b ff ff ff       	call   f01044c0 <printnum>
f0104545:	eb 1b                	jmp    f0104562 <printnum+0xa2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104547:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010454b:	8b 45 18             	mov    0x18(%ebp),%eax
f010454e:	89 04 24             	mov    %eax,(%esp)
f0104551:	ff d3                	call   *%ebx
f0104553:	eb 03                	jmp    f0104558 <printnum+0x98>
f0104555:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
		while (--width > 0)
f0104558:	83 ee 01             	sub    $0x1,%esi
f010455b:	85 f6                	test   %esi,%esi
f010455d:	7f e8                	jg     f0104547 <printnum+0x87>
f010455f:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104562:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104566:	8b 7c 24 04          	mov    0x4(%esp),%edi
f010456a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010456d:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104571:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0104578:	00 
f0104579:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f010457c:	89 1c 24             	mov    %ebx,(%esp)
f010457f:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104582:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104586:	e8 e5 0a 00 00       	call   f0105070 <__umoddi3>
f010458b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010458f:	0f be 80 b2 66 10 f0 	movsbl -0xfef994e(%eax),%eax
f0104596:	89 04 24             	mov    %eax,(%esp)
f0104599:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010459c:	ff d0                	call   *%eax
}
f010459e:	83 c4 4c             	add    $0x4c,%esp
f01045a1:	5b                   	pop    %ebx
f01045a2:	5e                   	pop    %esi
f01045a3:	5f                   	pop    %edi
f01045a4:	5d                   	pop    %ebp
f01045a5:	c3                   	ret    

f01045a6 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01045a6:	55                   	push   %ebp
f01045a7:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01045a9:	83 fa 01             	cmp    $0x1,%edx
f01045ac:	7e 0e                	jle    f01045bc <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01045ae:	8b 10                	mov    (%eax),%edx
f01045b0:	8d 4a 08             	lea    0x8(%edx),%ecx
f01045b3:	89 08                	mov    %ecx,(%eax)
f01045b5:	8b 02                	mov    (%edx),%eax
f01045b7:	8b 52 04             	mov    0x4(%edx),%edx
f01045ba:	eb 22                	jmp    f01045de <getuint+0x38>
	else if (lflag)
f01045bc:	85 d2                	test   %edx,%edx
f01045be:	74 10                	je     f01045d0 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01045c0:	8b 10                	mov    (%eax),%edx
f01045c2:	8d 4a 04             	lea    0x4(%edx),%ecx
f01045c5:	89 08                	mov    %ecx,(%eax)
f01045c7:	8b 02                	mov    (%edx),%eax
f01045c9:	ba 00 00 00 00       	mov    $0x0,%edx
f01045ce:	eb 0e                	jmp    f01045de <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01045d0:	8b 10                	mov    (%eax),%edx
f01045d2:	8d 4a 04             	lea    0x4(%edx),%ecx
f01045d5:	89 08                	mov    %ecx,(%eax)
f01045d7:	8b 02                	mov    (%edx),%eax
f01045d9:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01045de:	5d                   	pop    %ebp
f01045df:	c3                   	ret    

f01045e0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01045e0:	55                   	push   %ebp
f01045e1:	89 e5                	mov    %esp,%ebp
f01045e3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01045e6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01045ea:	8b 10                	mov    (%eax),%edx
f01045ec:	3b 50 04             	cmp    0x4(%eax),%edx
f01045ef:	73 0a                	jae    f01045fb <sprintputch+0x1b>
		*b->buf++ = ch;
f01045f1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01045f4:	88 0a                	mov    %cl,(%edx)
f01045f6:	83 c2 01             	add    $0x1,%edx
f01045f9:	89 10                	mov    %edx,(%eax)
}
f01045fb:	5d                   	pop    %ebp
f01045fc:	c3                   	ret    

f01045fd <printfmt>:
{
f01045fd:	55                   	push   %ebp
f01045fe:	89 e5                	mov    %esp,%ebp
f0104600:	83 ec 18             	sub    $0x18,%esp
	va_start(ap, fmt);
f0104603:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104606:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010460a:	8b 45 10             	mov    0x10(%ebp),%eax
f010460d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104611:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104614:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104618:	8b 45 08             	mov    0x8(%ebp),%eax
f010461b:	89 04 24             	mov    %eax,(%esp)
f010461e:	e8 02 00 00 00       	call   f0104625 <vprintfmt>
}
f0104623:	c9                   	leave  
f0104624:	c3                   	ret    

f0104625 <vprintfmt>:
{
f0104625:	55                   	push   %ebp
f0104626:	89 e5                	mov    %esp,%ebp
f0104628:	57                   	push   %edi
f0104629:	56                   	push   %esi
f010462a:	53                   	push   %ebx
f010462b:	83 ec 4c             	sub    $0x4c,%esp
f010462e:	8b 75 08             	mov    0x8(%ebp),%esi
f0104631:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104634:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104637:	eb 11                	jmp    f010464a <vprintfmt+0x25>
			if (ch == '\0')
f0104639:	85 c0                	test   %eax,%eax
f010463b:	0f 84 cf 03 00 00    	je     f0104a10 <vprintfmt+0x3eb>
			putch(ch, putdat);
f0104641:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104645:	89 04 24             	mov    %eax,(%esp)
f0104648:	ff d6                	call   *%esi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010464a:	0f b6 07             	movzbl (%edi),%eax
f010464d:	83 c7 01             	add    $0x1,%edi
f0104650:	83 f8 25             	cmp    $0x25,%eax
f0104653:	75 e4                	jne    f0104639 <vprintfmt+0x14>
f0104655:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f0104659:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0104660:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0104667:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f010466e:	ba 00 00 00 00       	mov    $0x0,%edx
f0104673:	eb 2b                	jmp    f01046a0 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
f0104675:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
f0104678:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f010467c:	eb 22                	jmp    f01046a0 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
f010467e:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '0';
f0104681:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f0104685:	eb 19                	jmp    f01046a0 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
f0104687:	8b 7d e0             	mov    -0x20(%ebp),%edi
				width = 0;
f010468a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104691:	eb 0d                	jmp    f01046a0 <vprintfmt+0x7b>
				width = precision, precision = -1;
f0104693:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104696:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104699:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01046a0:	0f b6 07             	movzbl (%edi),%eax
f01046a3:	8d 4f 01             	lea    0x1(%edi),%ecx
f01046a6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01046a9:	0f b6 0f             	movzbl (%edi),%ecx
f01046ac:	83 e9 23             	sub    $0x23,%ecx
f01046af:	80 f9 55             	cmp    $0x55,%cl
f01046b2:	0f 87 3b 03 00 00    	ja     f01049f3 <vprintfmt+0x3ce>
f01046b8:	0f b6 c9             	movzbl %cl,%ecx
f01046bb:	ff 24 8d 40 67 10 f0 	jmp    *-0xfef98c0(,%ecx,4)
f01046c2:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01046c5:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01046cc:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01046cf:	ba 00 00 00 00       	mov    $0x0,%edx
				precision = precision * 10 + ch - '0';
f01046d4:	8d 14 92             	lea    (%edx,%edx,4),%edx
f01046d7:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f01046db:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f01046de:	8d 48 d0             	lea    -0x30(%eax),%ecx
f01046e1:	83 f9 09             	cmp    $0x9,%ecx
f01046e4:	77 2f                	ja     f0104715 <vprintfmt+0xf0>
			for (precision = 0; ; ++fmt) {
f01046e6:	83 c7 01             	add    $0x1,%edi
			}
f01046e9:	eb e9                	jmp    f01046d4 <vprintfmt+0xaf>
			precision = va_arg(ap, int);
f01046eb:	8b 45 14             	mov    0x14(%ebp),%eax
f01046ee:	8d 48 04             	lea    0x4(%eax),%ecx
f01046f1:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01046f4:	8b 00                	mov    (%eax),%eax
f01046f6:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01046f9:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto process_precision;
f01046fc:	eb 1d                	jmp    f010471b <vprintfmt+0xf6>
			if (width < 0)
f01046fe:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104702:	78 83                	js     f0104687 <vprintfmt+0x62>
		switch (ch = *(unsigned char *) fmt++) {
f0104704:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104707:	eb 97                	jmp    f01046a0 <vprintfmt+0x7b>
f0104709:	8b 7d e0             	mov    -0x20(%ebp),%edi
			altflag = 1;
f010470c:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0104713:	eb 8b                	jmp    f01046a0 <vprintfmt+0x7b>
f0104715:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104718:	8b 55 e0             	mov    -0x20(%ebp),%edx
			if (width < 0)
f010471b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010471f:	0f 89 7b ff ff ff    	jns    f01046a0 <vprintfmt+0x7b>
f0104725:	e9 69 ff ff ff       	jmp    f0104693 <vprintfmt+0x6e>
			lflag++;
f010472a:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
f010472d:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;
f0104730:	e9 6b ff ff ff       	jmp    f01046a0 <vprintfmt+0x7b>
			putch(va_arg(ap, int), putdat);
f0104735:	8b 45 14             	mov    0x14(%ebp),%eax
f0104738:	8d 50 04             	lea    0x4(%eax),%edx
f010473b:	89 55 14             	mov    %edx,0x14(%ebp)
f010473e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104742:	8b 00                	mov    (%eax),%eax
f0104744:	89 04 24             	mov    %eax,(%esp)
f0104747:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
f0104749:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
f010474c:	e9 f9 fe ff ff       	jmp    f010464a <vprintfmt+0x25>
			err = va_arg(ap, int);
f0104751:	8b 45 14             	mov    0x14(%ebp),%eax
f0104754:	8d 50 04             	lea    0x4(%eax),%edx
f0104757:	89 55 14             	mov    %edx,0x14(%ebp)
f010475a:	8b 00                	mov    (%eax),%eax
f010475c:	89 c2                	mov    %eax,%edx
f010475e:	c1 fa 1f             	sar    $0x1f,%edx
f0104761:	31 d0                	xor    %edx,%eax
f0104763:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104765:	83 f8 07             	cmp    $0x7,%eax
f0104768:	7f 0b                	jg     f0104775 <vprintfmt+0x150>
f010476a:	8b 14 85 a0 68 10 f0 	mov    -0xfef9760(,%eax,4),%edx
f0104771:	85 d2                	test   %edx,%edx
f0104773:	75 20                	jne    f0104795 <vprintfmt+0x170>
				printfmt(putch, putdat, "error %d", err);
f0104775:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104779:	c7 44 24 08 ca 66 10 	movl   $0xf01066ca,0x8(%esp)
f0104780:	f0 
f0104781:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104785:	89 34 24             	mov    %esi,(%esp)
f0104788:	e8 70 fe ff ff       	call   f01045fd <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
f010478d:	8b 7d e0             	mov    -0x20(%ebp),%edi
				printfmt(putch, putdat, "error %d", err);
f0104790:	e9 b5 fe ff ff       	jmp    f010464a <vprintfmt+0x25>
				printfmt(putch, putdat, "%s", p);
f0104795:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104799:	c7 44 24 08 db 5e 10 	movl   $0xf0105edb,0x8(%esp)
f01047a0:	f0 
f01047a1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01047a5:	89 34 24             	mov    %esi,(%esp)
f01047a8:	e8 50 fe ff ff       	call   f01045fd <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
f01047ad:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01047b0:	e9 95 fe ff ff       	jmp    f010464a <vprintfmt+0x25>
f01047b5:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01047b8:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01047bb:	89 7d cc             	mov    %edi,-0x34(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
f01047be:	8b 45 14             	mov    0x14(%ebp),%eax
f01047c1:	8d 50 04             	lea    0x4(%eax),%edx
f01047c4:	89 55 14             	mov    %edx,0x14(%ebp)
f01047c7:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01047c9:	85 ff                	test   %edi,%edi
f01047cb:	b8 c3 66 10 f0       	mov    $0xf01066c3,%eax
f01047d0:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01047d3:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f01047d7:	0f 84 9b 00 00 00    	je     f0104878 <vprintfmt+0x253>
f01047dd:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f01047e1:	0f 8e 9f 00 00 00    	jle    f0104886 <vprintfmt+0x261>
				for (width -= strnlen(p, precision); width > 0; width--)
f01047e7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01047eb:	89 3c 24             	mov    %edi,(%esp)
f01047ee:	e8 95 03 00 00       	call   f0104b88 <strnlen>
f01047f3:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01047f6:	29 c2                	sub    %eax,%edx
f01047f8:	89 55 d8             	mov    %edx,-0x28(%ebp)
					putch(padc, putdat);
f01047fb:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f01047ff:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0104802:	89 7d c8             	mov    %edi,-0x38(%ebp)
f0104805:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0104807:	eb 0f                	jmp    f0104818 <vprintfmt+0x1f3>
					putch(padc, putdat);
f0104809:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010480d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104810:	89 04 24             	mov    %eax,(%esp)
f0104813:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0104815:	83 ef 01             	sub    $0x1,%edi
f0104818:	85 ff                	test   %edi,%edi
f010481a:	7f ed                	jg     f0104809 <vprintfmt+0x1e4>
f010481c:	8b 7d c8             	mov    -0x38(%ebp),%edi
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
f010481f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104823:	b8 00 00 00 00       	mov    $0x0,%eax
f0104828:	0f 49 45 d8          	cmovns -0x28(%ebp),%eax
f010482c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010482f:	29 c2                	sub    %eax,%edx
f0104831:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0104834:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0104837:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010483a:	89 d3                	mov    %edx,%ebx
f010483c:	eb 54                	jmp    f0104892 <vprintfmt+0x26d>
				if (altflag && (ch < ' ' || ch > '~'))
f010483e:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0104842:	74 20                	je     f0104864 <vprintfmt+0x23f>
f0104844:	0f be d2             	movsbl %dl,%edx
f0104847:	83 ea 20             	sub    $0x20,%edx
f010484a:	83 fa 5e             	cmp    $0x5e,%edx
f010484d:	76 15                	jbe    f0104864 <vprintfmt+0x23f>
					putch('?', putdat);
f010484f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104852:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104856:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010485d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104860:	ff d0                	call   *%eax
f0104862:	eb 0f                	jmp    f0104873 <vprintfmt+0x24e>
					putch(ch, putdat);
f0104864:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104867:	89 54 24 04          	mov    %edx,0x4(%esp)
f010486b:	89 04 24             	mov    %eax,(%esp)
f010486e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0104871:	ff d1                	call   *%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104873:	83 eb 01             	sub    $0x1,%ebx
f0104876:	eb 1a                	jmp    f0104892 <vprintfmt+0x26d>
f0104878:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f010487b:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010487e:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0104881:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0104884:	eb 0c                	jmp    f0104892 <vprintfmt+0x26d>
f0104886:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0104889:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010488c:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010488f:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0104892:	0f b6 17             	movzbl (%edi),%edx
f0104895:	0f be c2             	movsbl %dl,%eax
f0104898:	83 c7 01             	add    $0x1,%edi
f010489b:	85 c0                	test   %eax,%eax
f010489d:	74 29                	je     f01048c8 <vprintfmt+0x2a3>
f010489f:	85 f6                	test   %esi,%esi
f01048a1:	78 9b                	js     f010483e <vprintfmt+0x219>
f01048a3:	83 ee 01             	sub    $0x1,%esi
f01048a6:	79 96                	jns    f010483e <vprintfmt+0x219>
f01048a8:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01048ab:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01048ae:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01048b1:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01048b4:	eb 1a                	jmp    f01048d0 <vprintfmt+0x2ab>
				putch(' ', putdat);
f01048b6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01048ba:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01048c1:	ff d6                	call   *%esi
			for (; width > 0; width--)
f01048c3:	83 ef 01             	sub    $0x1,%edi
f01048c6:	eb 08                	jmp    f01048d0 <vprintfmt+0x2ab>
f01048c8:	89 df                	mov    %ebx,%edi
f01048ca:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01048cd:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01048d0:	85 ff                	test   %edi,%edi
f01048d2:	7f e2                	jg     f01048b6 <vprintfmt+0x291>
		switch (ch = *(unsigned char *) fmt++) {
f01048d4:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01048d7:	e9 6e fd ff ff       	jmp    f010464a <vprintfmt+0x25>
	if (lflag >= 2)
f01048dc:	83 fa 01             	cmp    $0x1,%edx
f01048df:	7e 16                	jle    f01048f7 <vprintfmt+0x2d2>
		return va_arg(*ap, long long);
f01048e1:	8b 45 14             	mov    0x14(%ebp),%eax
f01048e4:	8d 50 08             	lea    0x8(%eax),%edx
f01048e7:	89 55 14             	mov    %edx,0x14(%ebp)
f01048ea:	8b 10                	mov    (%eax),%edx
f01048ec:	8b 48 04             	mov    0x4(%eax),%ecx
f01048ef:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01048f2:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01048f5:	eb 32                	jmp    f0104929 <vprintfmt+0x304>
	else if (lflag)
f01048f7:	85 d2                	test   %edx,%edx
f01048f9:	74 18                	je     f0104913 <vprintfmt+0x2ee>
		return va_arg(*ap, long);
f01048fb:	8b 45 14             	mov    0x14(%ebp),%eax
f01048fe:	8d 50 04             	lea    0x4(%eax),%edx
f0104901:	89 55 14             	mov    %edx,0x14(%ebp)
f0104904:	8b 00                	mov    (%eax),%eax
f0104906:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104909:	89 c1                	mov    %eax,%ecx
f010490b:	c1 f9 1f             	sar    $0x1f,%ecx
f010490e:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0104911:	eb 16                	jmp    f0104929 <vprintfmt+0x304>
		return va_arg(*ap, int);
f0104913:	8b 45 14             	mov    0x14(%ebp),%eax
f0104916:	8d 50 04             	lea    0x4(%eax),%edx
f0104919:	89 55 14             	mov    %edx,0x14(%ebp)
f010491c:	8b 00                	mov    (%eax),%eax
f010491e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104921:	89 c7                	mov    %eax,%edi
f0104923:	c1 ff 1f             	sar    $0x1f,%edi
f0104926:	89 7d d4             	mov    %edi,-0x2c(%ebp)
			num = getint(&ap, lflag);
f0104929:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010492c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			base = 10;
f010492f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
f0104934:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0104938:	79 7d                	jns    f01049b7 <vprintfmt+0x392>
				putch('-', putdat);
f010493a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010493e:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0104945:	ff d6                	call   *%esi
				num = -(long long) num;
f0104947:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010494a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010494d:	f7 d8                	neg    %eax
f010494f:	83 d2 00             	adc    $0x0,%edx
f0104952:	f7 da                	neg    %edx
			base = 10;
f0104954:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104959:	eb 5c                	jmp    f01049b7 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
f010495b:	8d 45 14             	lea    0x14(%ebp),%eax
f010495e:	e8 43 fc ff ff       	call   f01045a6 <getuint>
			base = 10;
f0104963:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104968:	eb 4d                	jmp    f01049b7 <vprintfmt+0x392>
			num=getuint(&ap,lflag);
f010496a:	8d 45 14             	lea    0x14(%ebp),%eax
f010496d:	e8 34 fc ff ff       	call   f01045a6 <getuint>
                        base=8;
f0104972:	b9 08 00 00 00       	mov    $0x8,%ecx
                        goto number;
f0104977:	eb 3e                	jmp    f01049b7 <vprintfmt+0x392>
			putch('0', putdat);
f0104979:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010497d:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0104984:	ff d6                	call   *%esi
			putch('x', putdat);
f0104986:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010498a:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0104991:	ff d6                	call   *%esi
				(uintptr_t) va_arg(ap, void *);
f0104993:	8b 45 14             	mov    0x14(%ebp),%eax
f0104996:	8d 50 04             	lea    0x4(%eax),%edx
f0104999:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
f010499c:	8b 00                	mov    (%eax),%eax
f010499e:	ba 00 00 00 00       	mov    $0x0,%edx
			base = 16;
f01049a3:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01049a8:	eb 0d                	jmp    f01049b7 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
f01049aa:	8d 45 14             	lea    0x14(%ebp),%eax
f01049ad:	e8 f4 fb ff ff       	call   f01045a6 <getuint>
			base = 16;
f01049b2:	b9 10 00 00 00       	mov    $0x10,%ecx
			printnum(putch, putdat, num, base, width, padc);
f01049b7:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f01049bb:	89 7c 24 10          	mov    %edi,0x10(%esp)
f01049bf:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01049c2:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01049c6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01049ca:	89 04 24             	mov    %eax,(%esp)
f01049cd:	89 54 24 04          	mov    %edx,0x4(%esp)
f01049d1:	89 da                	mov    %ebx,%edx
f01049d3:	89 f0                	mov    %esi,%eax
f01049d5:	e8 e6 fa ff ff       	call   f01044c0 <printnum>
			break;
f01049da:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01049dd:	e9 68 fc ff ff       	jmp    f010464a <vprintfmt+0x25>
			putch(ch, putdat);
f01049e2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01049e6:	89 04 24             	mov    %eax,(%esp)
f01049e9:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
f01049eb:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
f01049ee:	e9 57 fc ff ff       	jmp    f010464a <vprintfmt+0x25>
			putch('%', putdat);
f01049f3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01049f7:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01049fe:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104a00:	eb 03                	jmp    f0104a05 <vprintfmt+0x3e0>
f0104a02:	83 ef 01             	sub    $0x1,%edi
f0104a05:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104a09:	75 f7                	jne    f0104a02 <vprintfmt+0x3dd>
f0104a0b:	e9 3a fc ff ff       	jmp    f010464a <vprintfmt+0x25>
}
f0104a10:	83 c4 4c             	add    $0x4c,%esp
f0104a13:	5b                   	pop    %ebx
f0104a14:	5e                   	pop    %esi
f0104a15:	5f                   	pop    %edi
f0104a16:	5d                   	pop    %ebp
f0104a17:	c3                   	ret    

f0104a18 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104a18:	55                   	push   %ebp
f0104a19:	89 e5                	mov    %esp,%ebp
f0104a1b:	83 ec 28             	sub    $0x28,%esp
f0104a1e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a21:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104a24:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104a27:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104a2b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104a2e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104a35:	85 d2                	test   %edx,%edx
f0104a37:	7e 30                	jle    f0104a69 <vsnprintf+0x51>
f0104a39:	85 c0                	test   %eax,%eax
f0104a3b:	74 2c                	je     f0104a69 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104a3d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a40:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104a44:	8b 45 10             	mov    0x10(%ebp),%eax
f0104a47:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104a4b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104a4e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104a52:	c7 04 24 e0 45 10 f0 	movl   $0xf01045e0,(%esp)
f0104a59:	e8 c7 fb ff ff       	call   f0104625 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104a5e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104a61:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104a64:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104a67:	eb 05                	jmp    f0104a6e <vsnprintf+0x56>
		return -E_INVAL;
f0104a69:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
f0104a6e:	c9                   	leave  
f0104a6f:	c3                   	ret    

f0104a70 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104a70:	55                   	push   %ebp
f0104a71:	89 e5                	mov    %esp,%ebp
f0104a73:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104a76:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104a79:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104a7d:	8b 45 10             	mov    0x10(%ebp),%eax
f0104a80:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104a84:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104a87:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104a8b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a8e:	89 04 24             	mov    %eax,(%esp)
f0104a91:	e8 82 ff ff ff       	call   f0104a18 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104a96:	c9                   	leave  
f0104a97:	c3                   	ret    
f0104a98:	66 90                	xchg   %ax,%ax
f0104a9a:	66 90                	xchg   %ax,%ax
f0104a9c:	66 90                	xchg   %ax,%ax
f0104a9e:	66 90                	xchg   %ax,%ax

f0104aa0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104aa0:	55                   	push   %ebp
f0104aa1:	89 e5                	mov    %esp,%ebp
f0104aa3:	57                   	push   %edi
f0104aa4:	56                   	push   %esi
f0104aa5:	53                   	push   %ebx
f0104aa6:	83 ec 1c             	sub    $0x1c,%esp
f0104aa9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104aac:	85 c0                	test   %eax,%eax
f0104aae:	74 10                	je     f0104ac0 <readline+0x20>
		cprintf("%s", prompt);
f0104ab0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ab4:	c7 04 24 db 5e 10 f0 	movl   $0xf0105edb,(%esp)
f0104abb:	e8 cc ec ff ff       	call   f010378c <cprintf>

	i = 0;
	echoing = iscons(0);
f0104ac0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104ac7:	e8 64 bb ff ff       	call   f0100630 <iscons>
f0104acc:	89 c7                	mov    %eax,%edi
	i = 0;
f0104ace:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f0104ad3:	e8 47 bb ff ff       	call   f010061f <getchar>
f0104ad8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104ada:	85 c0                	test   %eax,%eax
f0104adc:	79 17                	jns    f0104af5 <readline+0x55>
			cprintf("read error: %e\n", c);
f0104ade:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ae2:	c7 04 24 c0 68 10 f0 	movl   $0xf01068c0,(%esp)
f0104ae9:	e8 9e ec ff ff       	call   f010378c <cprintf>
			return NULL;
f0104aee:	b8 00 00 00 00       	mov    $0x0,%eax
f0104af3:	eb 6d                	jmp    f0104b62 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104af5:	83 f8 7f             	cmp    $0x7f,%eax
f0104af8:	74 05                	je     f0104aff <readline+0x5f>
f0104afa:	83 f8 08             	cmp    $0x8,%eax
f0104afd:	75 19                	jne    f0104b18 <readline+0x78>
f0104aff:	85 f6                	test   %esi,%esi
f0104b01:	7e 15                	jle    f0104b18 <readline+0x78>
			if (echoing)
f0104b03:	85 ff                	test   %edi,%edi
f0104b05:	74 0c                	je     f0104b13 <readline+0x73>
				cputchar('\b');
f0104b07:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0104b0e:	e8 fc ba ff ff       	call   f010060f <cputchar>
			i--;
f0104b13:	83 ee 01             	sub    $0x1,%esi
f0104b16:	eb bb                	jmp    f0104ad3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104b18:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104b1e:	7f 1c                	jg     f0104b3c <readline+0x9c>
f0104b20:	83 fb 1f             	cmp    $0x1f,%ebx
f0104b23:	7e 17                	jle    f0104b3c <readline+0x9c>
			if (echoing)
f0104b25:	85 ff                	test   %edi,%edi
f0104b27:	74 08                	je     f0104b31 <readline+0x91>
				cputchar(c);
f0104b29:	89 1c 24             	mov    %ebx,(%esp)
f0104b2c:	e8 de ba ff ff       	call   f010060f <cputchar>
			buf[i++] = c;
f0104b31:	88 9e 20 e8 17 f0    	mov    %bl,-0xfe817e0(%esi)
f0104b37:	83 c6 01             	add    $0x1,%esi
f0104b3a:	eb 97                	jmp    f0104ad3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0104b3c:	83 fb 0d             	cmp    $0xd,%ebx
f0104b3f:	74 05                	je     f0104b46 <readline+0xa6>
f0104b41:	83 fb 0a             	cmp    $0xa,%ebx
f0104b44:	75 8d                	jne    f0104ad3 <readline+0x33>
			if (echoing)
f0104b46:	85 ff                	test   %edi,%edi
f0104b48:	74 0c                	je     f0104b56 <readline+0xb6>
				cputchar('\n');
f0104b4a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0104b51:	e8 b9 ba ff ff       	call   f010060f <cputchar>
			buf[i] = 0;
f0104b56:	c6 86 20 e8 17 f0 00 	movb   $0x0,-0xfe817e0(%esi)
			return buf;
f0104b5d:	b8 20 e8 17 f0       	mov    $0xf017e820,%eax
		}
	}
}
f0104b62:	83 c4 1c             	add    $0x1c,%esp
f0104b65:	5b                   	pop    %ebx
f0104b66:	5e                   	pop    %esi
f0104b67:	5f                   	pop    %edi
f0104b68:	5d                   	pop    %ebp
f0104b69:	c3                   	ret    
f0104b6a:	66 90                	xchg   %ax,%ax
f0104b6c:	66 90                	xchg   %ax,%ax
f0104b6e:	66 90                	xchg   %ax,%ax

f0104b70 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104b70:	55                   	push   %ebp
f0104b71:	89 e5                	mov    %esp,%ebp
f0104b73:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104b76:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b7b:	eb 03                	jmp    f0104b80 <strlen+0x10>
		n++;
f0104b7d:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0104b80:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104b84:	75 f7                	jne    f0104b7d <strlen+0xd>
	return n;
}
f0104b86:	5d                   	pop    %ebp
f0104b87:	c3                   	ret    

f0104b88 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104b88:	55                   	push   %ebp
f0104b89:	89 e5                	mov    %esp,%ebp
f0104b8b:	8b 4d 08             	mov    0x8(%ebp),%ecx
strnlen(const char *s, size_t size)
f0104b8e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104b91:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b96:	eb 03                	jmp    f0104b9b <strnlen+0x13>
		n++;
f0104b98:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104b9b:	39 d0                	cmp    %edx,%eax
f0104b9d:	74 06                	je     f0104ba5 <strnlen+0x1d>
f0104b9f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104ba3:	75 f3                	jne    f0104b98 <strnlen+0x10>
	return n;
}
f0104ba5:	5d                   	pop    %ebp
f0104ba6:	c3                   	ret    

f0104ba7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104ba7:	55                   	push   %ebp
f0104ba8:	89 e5                	mov    %esp,%ebp
f0104baa:	53                   	push   %ebx
f0104bab:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bae:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104bb1:	89 c2                	mov    %eax,%edx
f0104bb3:	0f b6 19             	movzbl (%ecx),%ebx
f0104bb6:	88 1a                	mov    %bl,(%edx)
f0104bb8:	83 c2 01             	add    $0x1,%edx
f0104bbb:	83 c1 01             	add    $0x1,%ecx
f0104bbe:	84 db                	test   %bl,%bl
f0104bc0:	75 f1                	jne    f0104bb3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104bc2:	5b                   	pop    %ebx
f0104bc3:	5d                   	pop    %ebp
f0104bc4:	c3                   	ret    

f0104bc5 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104bc5:	55                   	push   %ebp
f0104bc6:	89 e5                	mov    %esp,%ebp
f0104bc8:	53                   	push   %ebx
f0104bc9:	83 ec 08             	sub    $0x8,%esp
f0104bcc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104bcf:	89 1c 24             	mov    %ebx,(%esp)
f0104bd2:	e8 99 ff ff ff       	call   f0104b70 <strlen>
	strcpy(dst + len, src);
f0104bd7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104bda:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104bde:	01 d8                	add    %ebx,%eax
f0104be0:	89 04 24             	mov    %eax,(%esp)
f0104be3:	e8 bf ff ff ff       	call   f0104ba7 <strcpy>
	return dst;
}
f0104be8:	89 d8                	mov    %ebx,%eax
f0104bea:	83 c4 08             	add    $0x8,%esp
f0104bed:	5b                   	pop    %ebx
f0104bee:	5d                   	pop    %ebp
f0104bef:	c3                   	ret    

f0104bf0 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104bf0:	55                   	push   %ebp
f0104bf1:	89 e5                	mov    %esp,%ebp
f0104bf3:	56                   	push   %esi
f0104bf4:	53                   	push   %ebx
f0104bf5:	8b 75 08             	mov    0x8(%ebp),%esi
f0104bf8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104bfb:	89 f3                	mov    %esi,%ebx
f0104bfd:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104c00:	89 f2                	mov    %esi,%edx
f0104c02:	eb 0e                	jmp    f0104c12 <strncpy+0x22>
		*dst++ = *src;
f0104c04:	0f b6 01             	movzbl (%ecx),%eax
f0104c07:	88 02                	mov    %al,(%edx)
f0104c09:	83 c2 01             	add    $0x1,%edx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104c0c:	80 39 01             	cmpb   $0x1,(%ecx)
f0104c0f:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0104c12:	39 da                	cmp    %ebx,%edx
f0104c14:	75 ee                	jne    f0104c04 <strncpy+0x14>
	}
	return ret;
}
f0104c16:	89 f0                	mov    %esi,%eax
f0104c18:	5b                   	pop    %ebx
f0104c19:	5e                   	pop    %esi
f0104c1a:	5d                   	pop    %ebp
f0104c1b:	c3                   	ret    

f0104c1c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104c1c:	55                   	push   %ebp
f0104c1d:	89 e5                	mov    %esp,%ebp
f0104c1f:	56                   	push   %esi
f0104c20:	53                   	push   %ebx
f0104c21:	8b 75 08             	mov    0x8(%ebp),%esi
f0104c24:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c27:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104c2a:	89 f0                	mov    %esi,%eax
strlcpy(char *dst, const char *src, size_t size)
f0104c2c:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	if (size > 0) {
f0104c30:	85 c9                	test   %ecx,%ecx
f0104c32:	75 0a                	jne    f0104c3e <strlcpy+0x22>
f0104c34:	eb 1c                	jmp    f0104c52 <strlcpy+0x36>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104c36:	88 08                	mov    %cl,(%eax)
f0104c38:	83 c0 01             	add    $0x1,%eax
f0104c3b:	83 c2 01             	add    $0x1,%edx
		while (--size > 0 && *src != '\0')
f0104c3e:	39 d8                	cmp    %ebx,%eax
f0104c40:	74 0b                	je     f0104c4d <strlcpy+0x31>
f0104c42:	0f b6 0a             	movzbl (%edx),%ecx
f0104c45:	84 c9                	test   %cl,%cl
f0104c47:	75 ed                	jne    f0104c36 <strlcpy+0x1a>
f0104c49:	89 c2                	mov    %eax,%edx
f0104c4b:	eb 02                	jmp    f0104c4f <strlcpy+0x33>
f0104c4d:	89 c2                	mov    %eax,%edx
		*dst = '\0';
f0104c4f:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0104c52:	29 f0                	sub    %esi,%eax
}
f0104c54:	5b                   	pop    %ebx
f0104c55:	5e                   	pop    %esi
f0104c56:	5d                   	pop    %ebp
f0104c57:	c3                   	ret    

f0104c58 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104c58:	55                   	push   %ebp
f0104c59:	89 e5                	mov    %esp,%ebp
f0104c5b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104c5e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104c61:	eb 06                	jmp    f0104c69 <strcmp+0x11>
		p++, q++;
f0104c63:	83 c1 01             	add    $0x1,%ecx
f0104c66:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0104c69:	0f b6 01             	movzbl (%ecx),%eax
f0104c6c:	84 c0                	test   %al,%al
f0104c6e:	74 04                	je     f0104c74 <strcmp+0x1c>
f0104c70:	3a 02                	cmp    (%edx),%al
f0104c72:	74 ef                	je     f0104c63 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104c74:	0f b6 c0             	movzbl %al,%eax
f0104c77:	0f b6 12             	movzbl (%edx),%edx
f0104c7a:	29 d0                	sub    %edx,%eax
}
f0104c7c:	5d                   	pop    %ebp
f0104c7d:	c3                   	ret    

f0104c7e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104c7e:	55                   	push   %ebp
f0104c7f:	89 e5                	mov    %esp,%ebp
f0104c81:	53                   	push   %ebx
f0104c82:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c85:	8b 55 0c             	mov    0xc(%ebp),%edx
strncmp(const char *p, const char *q, size_t n)
f0104c88:	89 c3                	mov    %eax,%ebx
f0104c8a:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104c8d:	eb 06                	jmp    f0104c95 <strncmp+0x17>
		n--, p++, q++;
f0104c8f:	83 c0 01             	add    $0x1,%eax
f0104c92:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0104c95:	39 d8                	cmp    %ebx,%eax
f0104c97:	74 15                	je     f0104cae <strncmp+0x30>
f0104c99:	0f b6 08             	movzbl (%eax),%ecx
f0104c9c:	84 c9                	test   %cl,%cl
f0104c9e:	74 04                	je     f0104ca4 <strncmp+0x26>
f0104ca0:	3a 0a                	cmp    (%edx),%cl
f0104ca2:	74 eb                	je     f0104c8f <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104ca4:	0f b6 00             	movzbl (%eax),%eax
f0104ca7:	0f b6 12             	movzbl (%edx),%edx
f0104caa:	29 d0                	sub    %edx,%eax
f0104cac:	eb 05                	jmp    f0104cb3 <strncmp+0x35>
		return 0;
f0104cae:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104cb3:	5b                   	pop    %ebx
f0104cb4:	5d                   	pop    %ebp
f0104cb5:	c3                   	ret    

f0104cb6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104cb6:	55                   	push   %ebp
f0104cb7:	89 e5                	mov    %esp,%ebp
f0104cb9:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cbc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104cc0:	eb 07                	jmp    f0104cc9 <strchr+0x13>
		if (*s == c)
f0104cc2:	38 ca                	cmp    %cl,%dl
f0104cc4:	74 0f                	je     f0104cd5 <strchr+0x1f>
	for (; *s; s++)
f0104cc6:	83 c0 01             	add    $0x1,%eax
f0104cc9:	0f b6 10             	movzbl (%eax),%edx
f0104ccc:	84 d2                	test   %dl,%dl
f0104cce:	75 f2                	jne    f0104cc2 <strchr+0xc>
			return (char *) s;
	return 0;
f0104cd0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104cd5:	5d                   	pop    %ebp
f0104cd6:	c3                   	ret    

f0104cd7 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104cd7:	55                   	push   %ebp
f0104cd8:	89 e5                	mov    %esp,%ebp
f0104cda:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cdd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104ce1:	eb 07                	jmp    f0104cea <strfind+0x13>
		if (*s == c)
f0104ce3:	38 ca                	cmp    %cl,%dl
f0104ce5:	74 0a                	je     f0104cf1 <strfind+0x1a>
	for (; *s; s++)
f0104ce7:	83 c0 01             	add    $0x1,%eax
f0104cea:	0f b6 10             	movzbl (%eax),%edx
f0104ced:	84 d2                	test   %dl,%dl
f0104cef:	75 f2                	jne    f0104ce3 <strfind+0xc>
			break;
	return (char *) s;
}
f0104cf1:	5d                   	pop    %ebp
f0104cf2:	c3                   	ret    

f0104cf3 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104cf3:	55                   	push   %ebp
f0104cf4:	89 e5                	mov    %esp,%ebp
f0104cf6:	83 ec 0c             	sub    $0xc,%esp
f0104cf9:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0104cfc:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0104cff:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104d02:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104d05:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104d08:	85 c9                	test   %ecx,%ecx
f0104d0a:	74 36                	je     f0104d42 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104d0c:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104d12:	75 28                	jne    f0104d3c <memset+0x49>
f0104d14:	f6 c1 03             	test   $0x3,%cl
f0104d17:	75 23                	jne    f0104d3c <memset+0x49>
		c &= 0xFF;
f0104d19:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104d1d:	89 d3                	mov    %edx,%ebx
f0104d1f:	c1 e3 08             	shl    $0x8,%ebx
f0104d22:	89 d6                	mov    %edx,%esi
f0104d24:	c1 e6 18             	shl    $0x18,%esi
f0104d27:	89 d0                	mov    %edx,%eax
f0104d29:	c1 e0 10             	shl    $0x10,%eax
f0104d2c:	09 f0                	or     %esi,%eax
f0104d2e:	09 c2                	or     %eax,%edx
f0104d30:	89 d0                	mov    %edx,%eax
f0104d32:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104d34:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0104d37:	fc                   	cld    
f0104d38:	f3 ab                	rep stos %eax,%es:(%edi)
f0104d3a:	eb 06                	jmp    f0104d42 <memset+0x4f>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104d3c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104d3f:	fc                   	cld    
f0104d40:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104d42:	89 f8                	mov    %edi,%eax
f0104d44:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0104d47:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0104d4a:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104d4d:	89 ec                	mov    %ebp,%esp
f0104d4f:	5d                   	pop    %ebp
f0104d50:	c3                   	ret    

f0104d51 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104d51:	55                   	push   %ebp
f0104d52:	89 e5                	mov    %esp,%ebp
f0104d54:	83 ec 08             	sub    $0x8,%esp
f0104d57:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0104d5a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104d5d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d60:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104d63:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104d66:	39 c6                	cmp    %eax,%esi
f0104d68:	73 36                	jae    f0104da0 <memmove+0x4f>
f0104d6a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104d6d:	39 d0                	cmp    %edx,%eax
f0104d6f:	73 2f                	jae    f0104da0 <memmove+0x4f>
		s += n;
		d += n;
f0104d71:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104d74:	f6 c2 03             	test   $0x3,%dl
f0104d77:	75 1b                	jne    f0104d94 <memmove+0x43>
f0104d79:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104d7f:	75 13                	jne    f0104d94 <memmove+0x43>
f0104d81:	f6 c1 03             	test   $0x3,%cl
f0104d84:	75 0e                	jne    f0104d94 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104d86:	83 ef 04             	sub    $0x4,%edi
f0104d89:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104d8c:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0104d8f:	fd                   	std    
f0104d90:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104d92:	eb 09                	jmp    f0104d9d <memmove+0x4c>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104d94:	83 ef 01             	sub    $0x1,%edi
f0104d97:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0104d9a:	fd                   	std    
f0104d9b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104d9d:	fc                   	cld    
f0104d9e:	eb 20                	jmp    f0104dc0 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104da0:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104da6:	75 13                	jne    f0104dbb <memmove+0x6a>
f0104da8:	a8 03                	test   $0x3,%al
f0104daa:	75 0f                	jne    f0104dbb <memmove+0x6a>
f0104dac:	f6 c1 03             	test   $0x3,%cl
f0104daf:	75 0a                	jne    f0104dbb <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0104db1:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0104db4:	89 c7                	mov    %eax,%edi
f0104db6:	fc                   	cld    
f0104db7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104db9:	eb 05                	jmp    f0104dc0 <memmove+0x6f>
		else
			asm volatile("cld; rep movsb\n"
f0104dbb:	89 c7                	mov    %eax,%edi
f0104dbd:	fc                   	cld    
f0104dbe:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104dc0:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0104dc3:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104dc6:	89 ec                	mov    %ebp,%esp
f0104dc8:	5d                   	pop    %ebp
f0104dc9:	c3                   	ret    

f0104dca <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104dca:	55                   	push   %ebp
f0104dcb:	89 e5                	mov    %esp,%ebp
f0104dcd:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0104dd0:	8b 45 10             	mov    0x10(%ebp),%eax
f0104dd3:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104dd7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104dda:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104dde:	8b 45 08             	mov    0x8(%ebp),%eax
f0104de1:	89 04 24             	mov    %eax,(%esp)
f0104de4:	e8 68 ff ff ff       	call   f0104d51 <memmove>
}
f0104de9:	c9                   	leave  
f0104dea:	c3                   	ret    

f0104deb <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104deb:	55                   	push   %ebp
f0104dec:	89 e5                	mov    %esp,%ebp
f0104dee:	56                   	push   %esi
f0104def:	53                   	push   %ebx
f0104df0:	8b 55 08             	mov    0x8(%ebp),%edx
f0104df3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
memcmp(const void *v1, const void *v2, size_t n)
f0104df6:	89 d6                	mov    %edx,%esi
f0104df8:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104dfb:	eb 1a                	jmp    f0104e17 <memcmp+0x2c>
		if (*s1 != *s2)
f0104dfd:	0f b6 02             	movzbl (%edx),%eax
f0104e00:	0f b6 19             	movzbl (%ecx),%ebx
f0104e03:	38 d8                	cmp    %bl,%al
f0104e05:	74 0a                	je     f0104e11 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104e07:	0f b6 c0             	movzbl %al,%eax
f0104e0a:	0f b6 db             	movzbl %bl,%ebx
f0104e0d:	29 d8                	sub    %ebx,%eax
f0104e0f:	eb 0f                	jmp    f0104e20 <memcmp+0x35>
		s1++, s2++;
f0104e11:	83 c2 01             	add    $0x1,%edx
f0104e14:	83 c1 01             	add    $0x1,%ecx
	while (n-- > 0) {
f0104e17:	39 f2                	cmp    %esi,%edx
f0104e19:	75 e2                	jne    f0104dfd <memcmp+0x12>
	}

	return 0;
f0104e1b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104e20:	5b                   	pop    %ebx
f0104e21:	5e                   	pop    %esi
f0104e22:	5d                   	pop    %ebp
f0104e23:	c3                   	ret    

f0104e24 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104e24:	55                   	push   %ebp
f0104e25:	89 e5                	mov    %esp,%ebp
f0104e27:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e2a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0104e2d:	89 c2                	mov    %eax,%edx
f0104e2f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104e32:	eb 07                	jmp    f0104e3b <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104e34:	38 08                	cmp    %cl,(%eax)
f0104e36:	74 07                	je     f0104e3f <memfind+0x1b>
	for (; s < ends; s++)
f0104e38:	83 c0 01             	add    $0x1,%eax
f0104e3b:	39 d0                	cmp    %edx,%eax
f0104e3d:	72 f5                	jb     f0104e34 <memfind+0x10>
			break;
	return (void *) s;
}
f0104e3f:	5d                   	pop    %ebp
f0104e40:	c3                   	ret    

f0104e41 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104e41:	55                   	push   %ebp
f0104e42:	89 e5                	mov    %esp,%ebp
f0104e44:	57                   	push   %edi
f0104e45:	56                   	push   %esi
f0104e46:	53                   	push   %ebx
f0104e47:	83 ec 04             	sub    $0x4,%esp
f0104e4a:	8b 55 08             	mov    0x8(%ebp),%edx
f0104e4d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104e50:	eb 03                	jmp    f0104e55 <strtol+0x14>
		s++;
f0104e52:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f0104e55:	0f b6 02             	movzbl (%edx),%eax
f0104e58:	3c 09                	cmp    $0x9,%al
f0104e5a:	74 f6                	je     f0104e52 <strtol+0x11>
f0104e5c:	3c 20                	cmp    $0x20,%al
f0104e5e:	74 f2                	je     f0104e52 <strtol+0x11>

	// plus/minus sign
	if (*s == '+')
f0104e60:	3c 2b                	cmp    $0x2b,%al
f0104e62:	75 0a                	jne    f0104e6e <strtol+0x2d>
		s++;
f0104e64:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f0104e67:	bf 00 00 00 00       	mov    $0x0,%edi
f0104e6c:	eb 10                	jmp    f0104e7e <strtol+0x3d>
f0104e6e:	bf 00 00 00 00       	mov    $0x0,%edi
	else if (*s == '-')
f0104e73:	3c 2d                	cmp    $0x2d,%al
f0104e75:	75 07                	jne    f0104e7e <strtol+0x3d>
		s++, neg = 1;
f0104e77:	8d 52 01             	lea    0x1(%edx),%edx
f0104e7a:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104e7e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104e84:	75 15                	jne    f0104e9b <strtol+0x5a>
f0104e86:	80 3a 30             	cmpb   $0x30,(%edx)
f0104e89:	75 10                	jne    f0104e9b <strtol+0x5a>
f0104e8b:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0104e8f:	75 0a                	jne    f0104e9b <strtol+0x5a>
		s += 2, base = 16;
f0104e91:	83 c2 02             	add    $0x2,%edx
f0104e94:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104e99:	eb 10                	jmp    f0104eab <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0104e9b:	85 db                	test   %ebx,%ebx
f0104e9d:	75 0c                	jne    f0104eab <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104e9f:	b3 0a                	mov    $0xa,%bl
	else if (base == 0 && s[0] == '0')
f0104ea1:	80 3a 30             	cmpb   $0x30,(%edx)
f0104ea4:	75 05                	jne    f0104eab <strtol+0x6a>
		s++, base = 8;
f0104ea6:	83 c2 01             	add    $0x1,%edx
f0104ea9:	b3 08                	mov    $0x8,%bl
		base = 10;
f0104eab:	b8 00 00 00 00       	mov    $0x0,%eax
f0104eb0:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104eb3:	0f b6 0a             	movzbl (%edx),%ecx
f0104eb6:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0104eb9:	89 f3                	mov    %esi,%ebx
f0104ebb:	80 fb 09             	cmp    $0x9,%bl
f0104ebe:	77 08                	ja     f0104ec8 <strtol+0x87>
			dig = *s - '0';
f0104ec0:	0f be c9             	movsbl %cl,%ecx
f0104ec3:	83 e9 30             	sub    $0x30,%ecx
f0104ec6:	eb 22                	jmp    f0104eea <strtol+0xa9>
		else if (*s >= 'a' && *s <= 'z')
f0104ec8:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0104ecb:	89 f3                	mov    %esi,%ebx
f0104ecd:	80 fb 19             	cmp    $0x19,%bl
f0104ed0:	77 08                	ja     f0104eda <strtol+0x99>
			dig = *s - 'a' + 10;
f0104ed2:	0f be c9             	movsbl %cl,%ecx
f0104ed5:	83 e9 57             	sub    $0x57,%ecx
f0104ed8:	eb 10                	jmp    f0104eea <strtol+0xa9>
		else if (*s >= 'A' && *s <= 'Z')
f0104eda:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0104edd:	89 f3                	mov    %esi,%ebx
f0104edf:	80 fb 19             	cmp    $0x19,%bl
f0104ee2:	77 16                	ja     f0104efa <strtol+0xb9>
			dig = *s - 'A' + 10;
f0104ee4:	0f be c9             	movsbl %cl,%ecx
f0104ee7:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104eea:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0104eed:	7d 0f                	jge    f0104efe <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104eef:	83 c2 01             	add    $0x1,%edx
f0104ef2:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0104ef6:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0104ef8:	eb b9                	jmp    f0104eb3 <strtol+0x72>
		else if (*s >= 'A' && *s <= 'Z')
f0104efa:	89 c1                	mov    %eax,%ecx
f0104efc:	eb 02                	jmp    f0104f00 <strtol+0xbf>
		if (dig >= base)
f0104efe:	89 c1                	mov    %eax,%ecx

	if (endptr)
f0104f00:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104f04:	74 05                	je     f0104f0b <strtol+0xca>
		*endptr = (char *) s;
f0104f06:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104f09:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0104f0b:	89 ca                	mov    %ecx,%edx
f0104f0d:	f7 da                	neg    %edx
f0104f0f:	85 ff                	test   %edi,%edi
f0104f11:	0f 45 c2             	cmovne %edx,%eax
}
f0104f14:	83 c4 04             	add    $0x4,%esp
f0104f17:	5b                   	pop    %ebx
f0104f18:	5e                   	pop    %esi
f0104f19:	5f                   	pop    %edi
f0104f1a:	5d                   	pop    %ebp
f0104f1b:	c3                   	ret    
f0104f1c:	66 90                	xchg   %ax,%ax
f0104f1e:	66 90                	xchg   %ax,%ax

f0104f20 <__udivdi3>:
f0104f20:	83 ec 1c             	sub    $0x1c,%esp
f0104f23:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0104f27:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0104f2b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0104f2f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0104f33:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0104f37:	8b 6c 24 24          	mov    0x24(%esp),%ebp
f0104f3b:	85 c0                	test   %eax,%eax
f0104f3d:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104f41:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104f45:	89 ea                	mov    %ebp,%edx
f0104f47:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104f4b:	75 33                	jne    f0104f80 <__udivdi3+0x60>
f0104f4d:	39 e9                	cmp    %ebp,%ecx
f0104f4f:	77 6f                	ja     f0104fc0 <__udivdi3+0xa0>
f0104f51:	85 c9                	test   %ecx,%ecx
f0104f53:	89 ce                	mov    %ecx,%esi
f0104f55:	75 0b                	jne    f0104f62 <__udivdi3+0x42>
f0104f57:	b8 01 00 00 00       	mov    $0x1,%eax
f0104f5c:	31 d2                	xor    %edx,%edx
f0104f5e:	f7 f1                	div    %ecx
f0104f60:	89 c6                	mov    %eax,%esi
f0104f62:	31 d2                	xor    %edx,%edx
f0104f64:	89 e8                	mov    %ebp,%eax
f0104f66:	f7 f6                	div    %esi
f0104f68:	89 c5                	mov    %eax,%ebp
f0104f6a:	89 f8                	mov    %edi,%eax
f0104f6c:	f7 f6                	div    %esi
f0104f6e:	89 ea                	mov    %ebp,%edx
f0104f70:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104f74:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104f78:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104f7c:	83 c4 1c             	add    $0x1c,%esp
f0104f7f:	c3                   	ret    
f0104f80:	39 e8                	cmp    %ebp,%eax
f0104f82:	77 24                	ja     f0104fa8 <__udivdi3+0x88>
f0104f84:	0f bd c8             	bsr    %eax,%ecx
f0104f87:	83 f1 1f             	xor    $0x1f,%ecx
f0104f8a:	89 0c 24             	mov    %ecx,(%esp)
f0104f8d:	75 49                	jne    f0104fd8 <__udivdi3+0xb8>
f0104f8f:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104f93:	39 74 24 04          	cmp    %esi,0x4(%esp)
f0104f97:	0f 86 ab 00 00 00    	jbe    f0105048 <__udivdi3+0x128>
f0104f9d:	39 e8                	cmp    %ebp,%eax
f0104f9f:	0f 82 a3 00 00 00    	jb     f0105048 <__udivdi3+0x128>
f0104fa5:	8d 76 00             	lea    0x0(%esi),%esi
f0104fa8:	31 d2                	xor    %edx,%edx
f0104faa:	31 c0                	xor    %eax,%eax
f0104fac:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104fb0:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104fb4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104fb8:	83 c4 1c             	add    $0x1c,%esp
f0104fbb:	c3                   	ret    
f0104fbc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104fc0:	89 f8                	mov    %edi,%eax
f0104fc2:	f7 f1                	div    %ecx
f0104fc4:	31 d2                	xor    %edx,%edx
f0104fc6:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104fca:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104fce:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104fd2:	83 c4 1c             	add    $0x1c,%esp
f0104fd5:	c3                   	ret    
f0104fd6:	66 90                	xchg   %ax,%ax
f0104fd8:	0f b6 0c 24          	movzbl (%esp),%ecx
f0104fdc:	89 c6                	mov    %eax,%esi
f0104fde:	b8 20 00 00 00       	mov    $0x20,%eax
f0104fe3:	8b 6c 24 04          	mov    0x4(%esp),%ebp
f0104fe7:	2b 04 24             	sub    (%esp),%eax
f0104fea:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0104fee:	d3 e6                	shl    %cl,%esi
f0104ff0:	89 c1                	mov    %eax,%ecx
f0104ff2:	d3 ed                	shr    %cl,%ebp
f0104ff4:	0f b6 0c 24          	movzbl (%esp),%ecx
f0104ff8:	09 f5                	or     %esi,%ebp
f0104ffa:	8b 74 24 04          	mov    0x4(%esp),%esi
f0104ffe:	d3 e6                	shl    %cl,%esi
f0105000:	89 c1                	mov    %eax,%ecx
f0105002:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105006:	89 d6                	mov    %edx,%esi
f0105008:	d3 ee                	shr    %cl,%esi
f010500a:	0f b6 0c 24          	movzbl (%esp),%ecx
f010500e:	d3 e2                	shl    %cl,%edx
f0105010:	89 c1                	mov    %eax,%ecx
f0105012:	d3 ef                	shr    %cl,%edi
f0105014:	09 d7                	or     %edx,%edi
f0105016:	89 f2                	mov    %esi,%edx
f0105018:	89 f8                	mov    %edi,%eax
f010501a:	f7 f5                	div    %ebp
f010501c:	89 d6                	mov    %edx,%esi
f010501e:	89 c7                	mov    %eax,%edi
f0105020:	f7 64 24 04          	mull   0x4(%esp)
f0105024:	39 d6                	cmp    %edx,%esi
f0105026:	72 30                	jb     f0105058 <__udivdi3+0x138>
f0105028:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f010502c:	0f b6 0c 24          	movzbl (%esp),%ecx
f0105030:	d3 e5                	shl    %cl,%ebp
f0105032:	39 c5                	cmp    %eax,%ebp
f0105034:	73 04                	jae    f010503a <__udivdi3+0x11a>
f0105036:	39 d6                	cmp    %edx,%esi
f0105038:	74 1e                	je     f0105058 <__udivdi3+0x138>
f010503a:	89 f8                	mov    %edi,%eax
f010503c:	31 d2                	xor    %edx,%edx
f010503e:	e9 69 ff ff ff       	jmp    f0104fac <__udivdi3+0x8c>
f0105043:	90                   	nop
f0105044:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105048:	31 d2                	xor    %edx,%edx
f010504a:	b8 01 00 00 00       	mov    $0x1,%eax
f010504f:	e9 58 ff ff ff       	jmp    f0104fac <__udivdi3+0x8c>
f0105054:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105058:	8d 47 ff             	lea    -0x1(%edi),%eax
f010505b:	31 d2                	xor    %edx,%edx
f010505d:	8b 74 24 10          	mov    0x10(%esp),%esi
f0105061:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0105065:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0105069:	83 c4 1c             	add    $0x1c,%esp
f010506c:	c3                   	ret    
f010506d:	66 90                	xchg   %ax,%ax
f010506f:	90                   	nop

f0105070 <__umoddi3>:
f0105070:	83 ec 2c             	sub    $0x2c,%esp
f0105073:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0105077:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010507b:	89 74 24 20          	mov    %esi,0x20(%esp)
f010507f:	8b 74 24 38          	mov    0x38(%esp),%esi
f0105083:	89 7c 24 24          	mov    %edi,0x24(%esp)
f0105087:	8b 7c 24 34          	mov    0x34(%esp),%edi
f010508b:	85 c0                	test   %eax,%eax
f010508d:	89 c2                	mov    %eax,%edx
f010508f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
f0105093:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0105097:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010509b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010509f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f01050a3:	89 7c 24 18          	mov    %edi,0x18(%esp)
f01050a7:	75 1f                	jne    f01050c8 <__umoddi3+0x58>
f01050a9:	39 fe                	cmp    %edi,%esi
f01050ab:	76 63                	jbe    f0105110 <__umoddi3+0xa0>
f01050ad:	89 c8                	mov    %ecx,%eax
f01050af:	89 fa                	mov    %edi,%edx
f01050b1:	f7 f6                	div    %esi
f01050b3:	89 d0                	mov    %edx,%eax
f01050b5:	31 d2                	xor    %edx,%edx
f01050b7:	8b 74 24 20          	mov    0x20(%esp),%esi
f01050bb:	8b 7c 24 24          	mov    0x24(%esp),%edi
f01050bf:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f01050c3:	83 c4 2c             	add    $0x2c,%esp
f01050c6:	c3                   	ret    
f01050c7:	90                   	nop
f01050c8:	39 f8                	cmp    %edi,%eax
f01050ca:	77 64                	ja     f0105130 <__umoddi3+0xc0>
f01050cc:	0f bd e8             	bsr    %eax,%ebp
f01050cf:	83 f5 1f             	xor    $0x1f,%ebp
f01050d2:	75 74                	jne    f0105148 <__umoddi3+0xd8>
f01050d4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01050d8:	39 7c 24 10          	cmp    %edi,0x10(%esp)
f01050dc:	0f 87 0e 01 00 00    	ja     f01051f0 <__umoddi3+0x180>
f01050e2:	8b 7c 24 0c          	mov    0xc(%esp),%edi
f01050e6:	29 f1                	sub    %esi,%ecx
f01050e8:	19 c7                	sbb    %eax,%edi
f01050ea:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f01050ee:	89 7c 24 18          	mov    %edi,0x18(%esp)
f01050f2:	8b 44 24 14          	mov    0x14(%esp),%eax
f01050f6:	8b 54 24 18          	mov    0x18(%esp),%edx
f01050fa:	8b 74 24 20          	mov    0x20(%esp),%esi
f01050fe:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0105102:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0105106:	83 c4 2c             	add    $0x2c,%esp
f0105109:	c3                   	ret    
f010510a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105110:	85 f6                	test   %esi,%esi
f0105112:	89 f5                	mov    %esi,%ebp
f0105114:	75 0b                	jne    f0105121 <__umoddi3+0xb1>
f0105116:	b8 01 00 00 00       	mov    $0x1,%eax
f010511b:	31 d2                	xor    %edx,%edx
f010511d:	f7 f6                	div    %esi
f010511f:	89 c5                	mov    %eax,%ebp
f0105121:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0105125:	31 d2                	xor    %edx,%edx
f0105127:	f7 f5                	div    %ebp
f0105129:	89 c8                	mov    %ecx,%eax
f010512b:	f7 f5                	div    %ebp
f010512d:	eb 84                	jmp    f01050b3 <__umoddi3+0x43>
f010512f:	90                   	nop
f0105130:	89 c8                	mov    %ecx,%eax
f0105132:	89 fa                	mov    %edi,%edx
f0105134:	8b 74 24 20          	mov    0x20(%esp),%esi
f0105138:	8b 7c 24 24          	mov    0x24(%esp),%edi
f010513c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0105140:	83 c4 2c             	add    $0x2c,%esp
f0105143:	c3                   	ret    
f0105144:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105148:	8b 44 24 10          	mov    0x10(%esp),%eax
f010514c:	be 20 00 00 00       	mov    $0x20,%esi
f0105151:	89 e9                	mov    %ebp,%ecx
f0105153:	29 ee                	sub    %ebp,%esi
f0105155:	d3 e2                	shl    %cl,%edx
f0105157:	89 f1                	mov    %esi,%ecx
f0105159:	d3 e8                	shr    %cl,%eax
f010515b:	89 e9                	mov    %ebp,%ecx
f010515d:	09 d0                	or     %edx,%eax
f010515f:	89 fa                	mov    %edi,%edx
f0105161:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105165:	8b 44 24 10          	mov    0x10(%esp),%eax
f0105169:	d3 e0                	shl    %cl,%eax
f010516b:	89 f1                	mov    %esi,%ecx
f010516d:	89 44 24 10          	mov    %eax,0x10(%esp)
f0105171:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0105175:	d3 ea                	shr    %cl,%edx
f0105177:	89 e9                	mov    %ebp,%ecx
f0105179:	d3 e7                	shl    %cl,%edi
f010517b:	89 f1                	mov    %esi,%ecx
f010517d:	d3 e8                	shr    %cl,%eax
f010517f:	89 e9                	mov    %ebp,%ecx
f0105181:	09 f8                	or     %edi,%eax
f0105183:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0105187:	f7 74 24 0c          	divl   0xc(%esp)
f010518b:	d3 e7                	shl    %cl,%edi
f010518d:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0105191:	89 d7                	mov    %edx,%edi
f0105193:	f7 64 24 10          	mull   0x10(%esp)
f0105197:	39 d7                	cmp    %edx,%edi
f0105199:	89 c1                	mov    %eax,%ecx
f010519b:	89 54 24 14          	mov    %edx,0x14(%esp)
f010519f:	72 3b                	jb     f01051dc <__umoddi3+0x16c>
f01051a1:	39 44 24 18          	cmp    %eax,0x18(%esp)
f01051a5:	72 31                	jb     f01051d8 <__umoddi3+0x168>
f01051a7:	8b 44 24 18          	mov    0x18(%esp),%eax
f01051ab:	29 c8                	sub    %ecx,%eax
f01051ad:	19 d7                	sbb    %edx,%edi
f01051af:	89 e9                	mov    %ebp,%ecx
f01051b1:	89 fa                	mov    %edi,%edx
f01051b3:	d3 e8                	shr    %cl,%eax
f01051b5:	89 f1                	mov    %esi,%ecx
f01051b7:	d3 e2                	shl    %cl,%edx
f01051b9:	89 e9                	mov    %ebp,%ecx
f01051bb:	09 d0                	or     %edx,%eax
f01051bd:	89 fa                	mov    %edi,%edx
f01051bf:	d3 ea                	shr    %cl,%edx
f01051c1:	8b 74 24 20          	mov    0x20(%esp),%esi
f01051c5:	8b 7c 24 24          	mov    0x24(%esp),%edi
f01051c9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f01051cd:	83 c4 2c             	add    $0x2c,%esp
f01051d0:	c3                   	ret    
f01051d1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01051d8:	39 d7                	cmp    %edx,%edi
f01051da:	75 cb                	jne    f01051a7 <__umoddi3+0x137>
f01051dc:	8b 54 24 14          	mov    0x14(%esp),%edx
f01051e0:	89 c1                	mov    %eax,%ecx
f01051e2:	2b 4c 24 10          	sub    0x10(%esp),%ecx
f01051e6:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f01051ea:	eb bb                	jmp    f01051a7 <__umoddi3+0x137>
f01051ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01051f0:	3b 44 24 18          	cmp    0x18(%esp),%eax
f01051f4:	0f 82 e8 fe ff ff    	jb     f01050e2 <__umoddi3+0x72>
f01051fa:	e9 f3 fe ff ff       	jmp    f01050f2 <__umoddi3+0x82>
