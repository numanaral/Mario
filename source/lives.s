.global decrementLives
.global incrementLives
.global renderLives
.global renderLivesTitle
.global lives
.global lives_changed
.global setLives

.section .text
//=========================================
//decrements the lives by 1
//=========================================
decrementLives:
	push {lr}

	//update the lives
	ldr r1, =lives
	ldr r2, [r1]
	sub r2, #1
	str	r2, [r1]
	
	//change lives_changed to true
	ldr r1, =lives_changed
	mov r2, #1					//1 is true, the lives changed
	str r2, [r1]
	
	pop {pc}

//==================================
//Increment Lives by 1
//==================================
incrementLives:
	push {lr}

	//update the lives
	ldr r1, =lives
	ldr r2, [r1]
	add r2, #1
	str	r2, [r1]
	
	//change lives_changed to true
	ldr r1, =lives_changed
	mov r2, #1					//1 is true, the lives changed
	str r2, [r1]
	
	pop {pc}
	
//===================================
//sets the lives to the value in r0
//and automatically sets lives changed to true
//==================================
setLives:
	push {lr}

	//update the lives
	ldr r1, =lives
	str	r0, [r1]
	
	//change lives_changed to true
	ldr r1, =lives_changed
	mov r2, #1					//1 is true, the lives changed
	str r2, [r1]
	
	pop {pc}

	
//======================================
//Renders the lives only if the lives has
//changed
//=======================================
renderLives:
	push {r4-r8, lr}
	
	ldr r0, =lives_changed
	ldr r1, [r0]
	cmp r1, #0					//if lives hasn't changed
	beq return					//then return from function
	
	mov r1, #0					//else update lives_changed to false
	str r1, [r0]				//and store it
	
	//Render the lives to the screen
	//Overwrite previous lives with blue rectangle first
	ldr r5, =lives_pos
	ldr r0, [r5]			//x pos
	ldr r1, [r5, #4]		//y pos
	ldr r2, =bg_colour
	ldrh r2, [r2]			//colour
	ldr r3, =38				//width
	ldr r4, =25				//height
	bl drawRectangle
	
	//draw six digits, starting with the ones
	mov r4, #10				//mod by 10 to get last digit
	mov r6, #0				//will mod by 10 6 times to get 6 digits
	ldr r5, =lives
	ldr r5, [r5]

mod10:
	cmp r6, #2
	bhs print_lives				//print if signed less than or equal
	mov r7, #0				//keep adding 10 to r7 until r7 > r5
	mov r3, #0				//the counter for how many times we add 10 to r7
store_last_digit:
	add r3, #1
	add r7, #10
	cmp r7, r5
	bls store_last_digit
	
	sub r3, #1				//r3 overcounts by 1. Now r3 = r5/10
	
	//Take the mod of r5 to get the last digit and push it onto a stack.
	//Then divide r5 by 10 to remove last digit and loop again
	
	sub r7, r5			//r7 = 10*(r3+1) - r5
	mov r8, #10
	sub r8, r7			//r8 = r9 MOD 10
	push {r8}			//push last digit onto stack

	mov r5, r3			//r3 = r5/10. Removes last digit
	add r6, #1			//counted 1 more digit
	b mod10
	
print_lives:
	mov r6, #0			//six digits stored on stack, so pop six times
	
print_lives_loop:
	cmp r6, #2
	bhs	return
	pop {r5}
	
	//load the address of the digit's pic into r4
	cmp r5, #0
	ldreq r2, =no_0_pic
	
	cmp r5, #1
	ldreq r2, =no_1_pic
	
	cmp r5, #2
	ldreq r2, =no_2_pic
	
	cmp r5, #3
	ldreq r2, =no_3_pic
	
	cmp r5, #4
	ldreq r2, =no_4_pic
	
	cmp r5, #5
	ldreq r2, =no_5_pic
	
	cmp r5, #6
	ldreq r2, =no_6_pic
	
	cmp r5, #7
	ldreq r2, =no_7_pic
	
	cmp r5, #8
	ldreq r2, =no_8_pic
	
	cmp r5, #9
	ldreq r2, =no_9_pic
	
	ldr r4, =lives_pos		
	ldr r0, [r4]				//x pos
	ldr r1, [r4, #4]			//y pos				
	ldr r3, =digit_dimension
	ldr r3, [r3]
	mul r3, r3, r6				//move digit by offset amount
	add r0, r3					//by multiplying by loop counter
	bl drawPicture
	
	add r6, #1	
	b print_lives_loop
	
return:
	pop {r4-r8, pc}
	
	
renderLivesTitle:
	push {lr}
	ldr r0, =508
	mov r1, #40
	ldr r2, =lives_title_pic
	bl drawPicture
	pop {pc}
	
	
.section .data
bg_colour:				.ascii "\237\224"
.align 4

lives_changed:			.int 1				//0 false, 1 true
lives:					.int 3
lives_pos:				.int 660, 40			//x, y of where to draw first digit
digit_dimension:		.int 19, 25			//width height of each digit's image







