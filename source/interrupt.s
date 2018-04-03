.global InstallIntTable
.global EnableC1IRQ
.global DisableC1IRQ

//================================================
//Install Interrupt Vector Table
//================================================
InstallIntTable:
	//switch to IRQ mode and set stack pointer
	//do this mode second so that we always end of in 
	//irq mode. For some reason it works all the time
	//this way??????
	mov r0, #0xD2		//11010010b	IRQ mode
	msr cpsr_c, r0
	mov sp, #0x8000
	
	//switch to Supervisor mode and set stack pointer
	mov r0, #0xD3
	msr cpsr_c, r0
	ldr sp, =0x8000000
	
	ldr r0, =IntTable	//where to read vector table from
	mov r1, #0x0000		//where to write vector table
	
	//first 8 words
	ldmia r0!, {r2-r9}
	stmia r1!, {r2-r9}
	
	//seconds 8 words
	ldmia r0!, {r2-r9}
	stmia r1!, {r2-r9}
		
	bx lr		//return

//================================================
//Enable Counter 1 interrupt requests 
//================================================
EnableC1IRQ:
	//update time in c1 to 2 seconds timer
	ldr r0, =0x3F003004		//Register for CLO
	ldr r1, [r0]
	
	//Make r1 = current time + delay
	mov r2, #1
	lsl r2, #25				//approx 30 000 000 micro sec = 30 sec
	add r1, r2
	
	ldr r0, =0x3F003010		//register for C1
	str r1, [r0]			//update C1 with delay
	
	//Enable IRQ line 1 for C1
	ldr r0, =0x3F00B210
	mov r1, #10				//1010b, only enabling C1 and C3
	str r1, [r0]
	
	//Disbable all interrupts from register 2
	ldr r0, =0x3F00B214
	mov r1, #0
	str r1, [r0]
	
	mrs r0, cpsr		//move from status to register
	bic r0, #0x80		//1000 0000b, clear FIQ
	msr cpsr_c, r0		//move from register to status
	
	bx lr

//================================================
//Distable Counter 1 interrupt requests 
//================================================
DisableC1IRQ: 
	//Enable IRQ line 1 for C1
	ldr r0, =0x3F00B210
	mov r1, #0				//1010b, only enabling C1 and C3
	str r1, [r0]
	
	bx lr 
	
haltLoop$:
	b haltLoop$
	
			
.section .data  

IntTable:
	ldr pc, reset_handler
	ldr pc, undefined_handler
	ldr pc, swi_handler
	ldr pc, prefetch_handler
	ldr pc, data_handler
	ldr pc, unused_handler
	ldr pc, irq_handler
	ldr pc, fiq_handler

reset_handler:		.word InstallIntTable
undefined_handler:	.word haltLoop$
swi_handler:		.word haltLoop$
prefetch_handler:	.word haltLoop$
data_handler:		.word haltLoop$
unused_handler:		.word haltLoop$
irq_handler:		.word irqISR		//in value_pack.s
fiq_handler:		.word haltLoop$








