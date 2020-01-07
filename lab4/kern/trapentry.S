/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>

#include <kern/picirq.h>


###################################################################
# exceptions/interrupts
###################################################################

#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text


/* 从这里开始顺序执行*/

/* 通过调用 TRAPHANDLER、 TRAPHANDLER_NOEC 宏，不断往数据段加入东西*/
  TRAPHANDLER_NOEC(divide_error,T_DIVIDE)		#0
  TRAPHANDLER_NOEC(debug_exception,T_DEBUG)		#1
  TRAPHANDLER_NOEC(non_maskable_interrupt,T_NMI)	#2 can't find it in 80386 manual
  TRAPHANDLER_NOEC(_breakpoint,T_BRKPT)			#3
  TRAPHANDLER_NOEC(overflow,T_OFLOW)			#4
  TRAPHANDLER_NOEC(bounds_check,T_BOUND)		#5
  TRAPHANDLER_NOEC(illegal_opcode,T_ILLOP)		#6
  TRAPHANDLER_NOEC(device_not_available,T_DEVICE)	#7
  TRAPHANDLER(double_fault,T_DBLFLT)			#8
  TRAPHANDLER(invalid_task_switch_segment,T_TSS)	#10
  TRAPHANDLER(segment_not_present,T_SEGNP)		#11
  TRAPHANDLER(stack_exception,T_STACK)			#12
  TRAPHANDLER(general_protection_fault,T_GPFLT)		#13
  TRAPHANDLER(page_fault,T_PGFLT)			#14
  TRAPHANDLER_NOEC(floating_point_error,T_FPERR)	#16
  TRAPHANDLER_NOEC(alignment_check,T_ALIGN)		#17
  TRAPHANDLER_NOEC(machine_check,T_MCHK)		#18
  TRAPHANDLER_NOEC(SIMD_floating_point_error,T_SIMDERR)	#19
  TRAPHANDLER_NOEC(system_call,T_SYSCALL)		#48

  /* lab4 ex13 */
  TRAPHANDLER_NOEC(irq_handler32,IRQ_OFFSET+IRQ_TIMER)		#32
  TRAPHANDLER_NOEC(irq_handler33,IRQ_OFFSET+IRQ_KBD)		#33
  TRAPHANDLER_NOEC(irq_handler36,IRQ_OFFSET+IRQ_SERIAL)	#36
  TRAPHANDLER_NOEC(irq_handler39,IRQ_OFFSET+IRQ_SPURIOUS)	#39
  TRAPHANDLER_NOEC(irq_handler46,IRQ_OFFSET+IRQ_IDE)		#46
  TRAPHANDLER_NOEC(irq_handler51,IRQ_OFFSET+IRQ_ERROR)	
  

/*
 * Lab 3: Your code here for _alltraps
 */
 _alltraps:
		pushw $0x0 # 16bits
		pushw %ds # 16bits
		pushw $0x0 # 16bits
		pushw %es # 16bits

		pushal

		movl $GD_KD,%eax
		movw %ax,%ds
		movw %ax,%es
		
		pushl %esp # 32bits
		
		movl	$0x0,%ebp
		
		call trap

 
 
 
 
 
 
