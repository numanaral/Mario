.section    .text
.globl	InitGPIOSNES
.globl	ReadSNES 

    
.section .text
	

InitGPIOSNES:
	push {lr}
	//set pin 9's (latch) function to output
	mov r0, #9
	mov r1, #1
	bl Init_GPIO

	//set pin 10's (data) function to output
	mov r0, #10
	mov r1, #0
	bl Init_GPIO

	//set pin 11's (clock) function to output
	mov r0, #11
	mov r1, #1
	bl Init_GPIO
	pop {pc}

	/*
ReadSNES:
	push {r9, r10, lr}
	Buttons .req r10				//r10 will hold the number of which buttons are pressed
	Previous_Buttons .req r9			//r9 holds the value of the previous buttons pressed
	
	mov Previous_Buttons, #1			//initially no buttons are pressed
	lsl Previous_Buttons, #16
	sub Previous_Buttons, #1			//Previous_Buttons = 2^16 - 1 = 0xFFFF
	mov Buttons, Previous_Buttons
//	bl prompt_press_btn
	b Read_SNES
//	b halt*/

/************************************
Parameters:
	r0 is the pin number
	r1 is the function code
*************************************/
Init_GPIO:
	push {r4, r5, r6}			//r4, r5 and r6 will be used

	offset .req r2
	mov offset, r0				//will be divided by 10 to get GPFSEL register
	mov r6, #10
	udiv offset, r6
	mov r6, #4
	mul offset, r6				//4 bytes per address of the GPFSEL register
mod10:	
	cmp r0, #9
	subhi r0, #10
	bhi mod10


	ldr r3, =GPFSEL0			//GPFSEL hold the address of base register	
	ldr r5, [r3, offset]			//r2 is the offset
	mov r4, #7				// b0111
	mov r6, #3
	mul r0, r6				//3 bits per pin
	lsl r4, r0				//align to the pin
	bic r5, r4				//will clear only pin given in r0

	lsl r1, r0				//align function code to pin
	orr r5, r1				//set function code for pin
	str r5, [r3, offset]			//store in GPFSEL0 + offset

	pop {r4, r5, r6}
	.unreq offset

	mov pc, lr				//return

	
/***************************************************
Writes to to screen prompting user to press a button
****************************************************/
/*
prompt_press_btn:
	ldr r0, =press_btn_msg
	mov r1, #23
	push {lr}				//WriteString will overwrite lr
	bl Print_Message
	pop {pc}*/

/**************************************************
Main SNES loop. Keeps reading from data line which
buttons are pressed. Then writes the appropriate
output
Returns in r0 the 16-bit value of which buttons were
pressed
**************************************************/
ReadSNES:
	push {r6, r10, lr}
	Buttons .req r10
	
//	mov Previous_Buttons, Buttons		//the update previous buttons
	
	mov r1, #1
	bl Write_Clock		//write 1 to pin 11(clock)

	mov r1, #1
	bl Write_Latch		//write 1 to pin 9(latch)

	mov r0, #12
	bl Wait			//wait 12 microseconds

	mov r1, #0
	bl Write_Latch		//write 0 to pin 9 (latch)

	mov r6, #0		//r6 is the loop counter
	mov Buttons, #0		//clear buttons
Read_SNES_Loop:
	cmp r6, #16
	moveq r0, r10
	popeq {r6, r10, pc}	//return in r0
	//beq Read_SNES

	mov r1, #1
	bl Write_Clock
	mov r0, #6
	bl Wait			//wait 6 microseconds
	mov r1, #0
	bl Write_Clock		//write 0 to clock
	mov r0, #6
	bl Wait			//wait 6 microseconds
	bl Read_Data		//read current bit from Data line and return in r0
	
	lsl r0, r6		//r6 is loop counter
	orr Buttons, r0
	add r6, #1
	
	b Read_SNES_Loop


/******************************************
Paramteres:
	r0 is the pin to write too
	r1 is value to write, either 0 or 1
*******************************************/
	
Write_GPIO:
	cmp r1, #0
	ldreq r2, =GPCLR0		//write 0
	ldrne r2, =GPSET0		//write 1
	mov r3, #1			//r3 will set the pin to 1 for either GPCLR0 or GPSET0
	lsl r3, r0			//aligns to the pin
	str r3, [r2]			//stores to either GLCLR0 or GPSET0
	mov pc, lr
/***********************************************
Parameters:
	r1 is the value to write, either 1 or 0
***********************************************/
Write_Clock:
	mov r0, #11			//clock is pin 11
	push {lr}			//Write_GPIO will overwrite the lr that called this subroutine
	bl Write_GPIO
	pop {pc}			//return

/**********************************************
Parameters:
	r1 is the value to write, either 1 or 0
***********************************************/
Write_Latch:
	mov r0, #9			//latch is pin 9
	push {lr}			//Write_GPIO will overwrite the lr that called this subroutine
	bl Write_GPIO
	pop {pc}			//return

/***********************************************
Parameters:
	r0 = microseconds to wait
************************************************/	
Wait:
	delta .req r0
	current_time .req r3

	ldr r1, =CLO
	ldr r2, [r1]			//get current time
	add r2, delta			//add the delta to current time
wait_loop:
	ldr current_time, [r1]
	cmp current_time, r2
	bls wait_loop			//if current <= time_to_wait then keep waiting

	.unreq delta
	.unreq current_time
	mov pc, lr			//else return

/*************************************************
Return:
	returns in r0 the single bit that was read
	for current iteration
**************************************************/
Read_Data:
	mov r0, #10			//pin 10 is Data
	ldr r1, =GPLEV0
	ldr r2, [r1]			//r2 holds the status of pins 0 to 31
	mov r3, #1
	lsl r3, r0			//align to pin 10
	and r2, r3			//mask everything but bit 10
	cmp r2, #0			
	moveq r0, #0			//if bit 10 wasn't set, return 0. SNES is opposite
	movne r0, #1			//else return 1

	mov pc, lr



.section .set
	GPFSEL0 = 0x3F200000 			//GPIO function select 0. Set pin to input or output
	GPSET0 = 0x3F20001C			//used to write 1 to pin
	GPCLR0 = 0x3F200028			//used to write 0 to pin
	GPLEV0 = 0x3F200034			//used to read a pin
	CLO = 0x3F003004			//Clock register
