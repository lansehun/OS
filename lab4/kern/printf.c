// Simple implementation of cprintf console output for the kernel,
// based on printfmt() and the kernel console's cputchar().
//基于printfmt（）和内核控制台的cputchar（），为内核简单实现cprintf控制台输出。

#include <inc/types.h>
#include <inc/stdio.h>
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
	cputchar(ch);
//调用了console.c中的cputchar程序
	*cnt++;
}

int
vcprintf(const char *fmt, va_list ap)
{
	int cnt = 0;

	vprintfmt((void*)putch, &cnt, fmt, ap);
//调用了printfmt.c中的vprintfmt（）
	return cnt;
}

int
cprintf(const char *fmt, ...)
{
	va_list ap;
	int cnt;

	va_start(ap, fmt);
	cnt = vcprintf(fmt, ap);
	va_end(ap);

	return cnt;
}

