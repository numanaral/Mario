.global MarioUpdate
.global CoinUpdate

	.equ mario_width, 32
	.equ mario_height, 32
	.equ jump_height, 180

//==========================================
//void Update 
MarioUpdate:
	push {r4, r5, r6, r7, r9, lr}
	bl ReadSNES
	
	ldr r1, =0xFFFF		//Bit mask 
	eor r4, r1, r0		//Flip bits so 0 means unpressed and 1 means pressed 
	
	bl check_START
	
	mov r5, #0			//Initialize delta_y = 0 

	ldr r2, =jump_flag	//Load address of jump_flag
	ldr r9, [r2]		//Load jump_flag
	
	cmp r9, #1			//Mario jumping?
	beq jumping			//Make mario jump
	
	blt check_A			//Check if we want him to jump 
	
jumping:
	ldr r0, =jump_cnt 	//Load address of jump_count 
	ldr r1, [r0]		//Load value of jump_count
	
	ldr r7, =jump_height//Get address of jump_height 
	ldr r7, [r7]
	cmp r1, r7			//Mario reached his max height?
	blgt endJump		//End Mario's jump	
	bgt move_left_right	//Branch to move_left_right 
	
	mov r5, #-2			//delta_y = -1   
	
	add r1, #1			//increment jump count 
	str r1, [r0]		//Store updated jump_count 
	
	b move_left_right 	//Branch to move_left_right
	
check_A:
	// check if A button pressed 
	tst r4, #0x100		//0001 0000 0000b A button has been pressed? 
	beq falling			//No, then branch to falling 
	
	ldr r0, =is_floor	//Check if Mario is on a floor, he can only jump if he is on a floor
	ldr r0, [r0]		//Load value of is_floor 
	cmp r0, #1			//Is Mario on a floor
	bne falling			//If not, do not jump again
	
	mov r0, #1			//Set jump flag to 1 
	str r0, [r2]		//Update jump_flag in memory 
	
	ldr r7, =jump_height//Get address of jump_height 
	mov r0, #90			//Set jump height to 180 pixels 
	str r0, [r7]
	
	b move_left_right	//Branch to move_left_right
	
check_START:
	//check if start button is pressed
	push {lr}
	tst r4, #0x8		//1000b 3rd bit is for START
	blne pause_menu		//if pressed go to pause menu
	pop {pc}
	
falling:

	mov r5, #2			//delta_y = 1 
	
move_left_right: 

	ldr r6, =mario_data //Load mario's data 
	ldmia r6, {r0, r1}	//Load mario current x and y location 
	mov r2, #0			//Init delta x = 0
	
	// check if right button pressed
	tst r4, #0x80		//1000 0000b
	movne r2, #2		//Arg0: delta x = 1

	// check if left button pressed
	tst r4, #0x40		//0100 0000b
	movne r2, #-2 		//Arg0: delta x = -1		
	
	mov r3, r5			//Arg1: delta y 
	
	//Update current position 
	add r0, r2			//current_x = current_x + delta_x 
	add r1, r3			//current_y = current_y + delta_y
	
	stmia r6, {r0, r1, r2, r3}	//Update mario's data in memory 
	
MU_end:
	pop {r4, r5, r6, r7, r9, lr}
	bx lr 
	
//==========================================
//CoinUpdate 
//Update the coin counter 
//Returns: void
//==========================================
CoinUpdate:

	push {lr}
	
	ldr r0, =coin_coordinate 
	add r1, r0, #12				//Get adderss for coin counter
	
	ldr r2, [r1]				//Get value of coin counter
	cmp r2, #0 					//Is counter 0? 
	beq CU_end					//Then do nothing and branch to CU_end 
	
	cmp r2, #1					//Should we delete the coin?
	moveq r3, #-1				//Set delete coin flag 
	streq r3, [r0]				//Store flag in memory  
	
	sub r2, #1					//Decrement the coin counter 
	str r2, [r1]				//Update the coin counter in memory

CU_end:
	pop {lr}
	bx lr 
	
	