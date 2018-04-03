.global endJump
.global coinInit

	.equ coin_pad_y, 50		//Distance between the top of a coin and it's associated block 

//============================================
//void endJump()
//End Mario's jump by setting flags 
//Returns void
//============================================
endJump:
	push {lr}

	ldr r0, =jump_flag					//Load address of jump_flag
	mov r1, #-1						//Set jump_flag to -1 
	str r1, [r0]						//Update jump_flag in memory	
	
	ldr r0, =jump_cnt 					//Load address of jump_count 
	mov r1, #0						//Reset jump counter to 0 
	str r1, [r0] 						//Reset jump counter in memory

	pop {lr}
	bx lr 

//===========================================
//coinInit(int x, int y) 
//Initialize a coin to be drawn by setting it's x and y coordinates
//Also initializes a counter determining now long the coin will remain present 
//r0: x coordinate of the BLOCK associated with the coin
//r1: y coordinate of the BLOCK associated with the coin 
//Returns void 
//============================================
coinInit:
	push {r4, r5, lr}
	
	mov r4, r0						//Save block x in safe location
	mov r5, r1						//Save block y in safe location 
	
	ldr r0, =coin_coordinate 		
	
	mov r1, #1 						//Coin will be displayed 
	mov r2, r4						//x position of the coin 
	sub r3, r5, #coin_pad_y			//y position of the coin 
	mov r4, #50						//Set coin counter 
	
	stmia r0, {r1, r2, r3, r4}		//Store the data in memory 
	
	pop {r4, r5, lr}
	bx lr 

//===========================================
//void setNextBackground(int change)
//set flag to change the background 
//r0: change in the background number 
//===========================================

