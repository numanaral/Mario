.global irqISR
.global spawn_value_pack
.global renderValuePack
.global setValuePackPos
.global ValuePackOffScreen
.global value_pack_pos
.global updateTimer

irqISR:
	push {r0-r12, lr}

	ldr r0, =0x3F00B204		//GPU pending register 1
	ldr r1, [r0]
	tst r1, #0x2			//0010b check C1
	beq not_draw			//if not set return
	
	//FUNCTION START
	//===========================================
	ldr r0, =spawn_value_pack
	mov r1, #0
	str r1, [r0]
	//============================================
	//FUNCTION END
	
	bl updateTimer
	b irqISREnd

not_draw:
	ldr r0, =spawn_value_pack
	mov r1, #1
	str r1, [r0]	

irqISREnd:
	pop {r0-r12, lr}
	subs pc, lr, #4			//how to return from IRQ
	

updateTimer:
	push {lr}
	
	//disble timer
	ldr r0, =0x3F003000		//CS register
	ldr r1, [r0]
	bic r1, #2
	str r1, [r0]
	
	//update time in c1 to 15 seconds timer
	ldr r0, =0x3F003004		//Register for CLO
	ldr r1, [r0]
	
	//Make r1 = current time + delay
	mov r2, #1
	lsl r2, #25			//approx 30 000 000 micro sec = 30 sec
	add r1, r2
	
	ldr r0, =0x3F003010		//register for C1
	str r1, [r0]			//update C1 with delay
	
	//enable timer
	ldr r0, =0x3F003000		//CS register
	mov r1, #2				//0010b, sets C1 which clears it
	str r1, [r0]
	
	pop {pc}

//==================================
//Sets the x to a random position
//and the y to the ground. Only sets the positoin
//if there currently is not a value pack on screen
//===================================
setValuePackPos:
	push {r4-r8, lr}
	
	ldr r0, =value_pack_on_screen
	ldr r1, [r0]
	cmp r1, #0				//if on screen
	beq end_set_pos			//then don't spawn another one
	mov r1, #0				//set the flag to be true
	str r1, [r0]
	
	//r4 will be the random number
	ldr r3, =random_numbs
	ldmia r3, {r5-r8}		//load w, x, y, and z
	mov r4, r5
	eor r4, r4, r4, lsl #11
	eor r4, r4, r4, lsl #8
	
	mov r5, r6
	mov r6, r7
	mov r7, r8
	eor r8, r8, r8, lsl #19
	eor r8, r4
	
	stmia r3, {r5-r8}
			
	mov r2, r4	
	ldr r3, =1000000		//divide the randome number by 2 till its lower than 1 mil
							//this is to decrease the cycles when we mod 992
dec_cycles:				
	cmp r2, r3
	bls end_dec_cycles
	lsr r2, #1
	b dec_cycles
	
end_dec_cycles:	


	//mod r2 by 992 to that it is in the range
	ldr r1, =992
mod992:
	cmp r2, r1				//if less than 992 then it contains the mod
	blo endMod
	sub r2, r1
	b mod992
	
endMod:	
	ldr r3, =value_pack_pos
	str r2, [r3]			//store x
	//str r1, [r0, #4]		//store y
	
	ldr r3, =spawn_value_pack		//don't spawn another value pack
	mov r2, #1						//until timer goes off
	str r2, [r3]
	
	ldr r3, =new_position_set		//let renderer know that it should
	mov r2, #0						//draw the value pack
	str r2, [r3]
end_set_pos:	
	pop {r4-r8, pc}

//=====================================================
//Render the value pack only if render_value_pack == 0
//=====================================================	
renderValuePack:
	push {lr}
	
	//check if we should draw value pack
	ldr r0, =new_position_set
	ldr r1, [r0]
	cmp r1, #0
	mov r1, #1
	str r1, [r0]				//set new_position_set to false
	bne end_render				//if spawn == 0 then render it
	
	//render
	ldr r3, =value_pack_pos
	ldr r0, [r3]			//x
	ldr r1, [r3, #4]		//y
	ldr r2, =star_pic
	bl drawPicture

end_render:
	pop {pc}
	
	
ValuePackOffScreen:
	push {lr}
	ldr r0, =value_pack_on_screen
	mov r1, #1
	str r1, [r0]				//set the flag to false
	pop {pc}
		
.section .data
colour_test:			.int 15

//if set to 0 then we should call setValuePackPos
//with a random x and set y to the ground
spawn_value_pack:		.int 1
new_position_set:		.int 1			//only renders if new position set from setPosition		
value_pack_on_screen:	.int 1			//0 if on screen, 1 if not
value_pack_pos:			.int 0, 480
random_numbs:			.int 79843, 981723, 18975, 8178954


