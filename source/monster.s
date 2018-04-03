.global MonsterUpdate
.global killCurMonster

//====================================================
//moveMonster(int data_pointer, int delta_x, int delta_y)
//move monster in specified direction
//r0: data_pointer
//r1: delta_x 1: right, -1:left 
//r2: delta_y 1: down, -1:up
//Returns: void 
//====================================================
moveMonster:
	push {r4, r5, r6, r7, lr}
	
	ldmia r0, {r4, r5, r6, r7}	//Load monster x (r4), y (r5), delta x (r6), delta y (r7)
	
	add r4, r1 					//x = x + delta_x 
	add r5, r2 					//y = y + delta_y
	
	mov r6, r1 
	mov r7, r2
	
	stmia r0, {r4, r5, r6, r7}	//Store monster data 
	
mM_end:
	pop {r4, r5, r6, r7, lr}
	bx lr 
	
//====================================================
//updateMonster()
//update position of monsters 
//Returns: void 
//====================================================
MonsterUpdate:
	push {r4, r5, r9, lr}
	
	ldr r0, =cur_mobs			//Get pointer to cur_mobs
	ldr r9, [r0]				//Get address of set of current mobs  

	ldmia r9!, {r4, r5}			//Load monster 1's data r4: status r5: direction
	
	cmp r4, #0					//If monster is dead, branch to end 
	beq MoU_end
	
	ldr r0, =mob1_data			//Arg1: mob1_data
	mov r1, r5 					//Arg2: delta_x 
	mov r2, #2					//Arg3: delta_y (gravity)
	bl moveMonster				//Call moveMonster
	
MoU_end:
	
	pop {r4, r5, r9, lr}
	bx lr
	
//====================================================
//killCurMonster()
//set the status of the current monster to dead 
//Returns:void
//====================================================
killCurMonster:

	push {r4, r5, r6, r7, lr}

	ldr r0, =cur_mobs			//Get pointer to cur_mobs
	ldr r0, [r0]				//Get status the monster on the current screen
	
	mov r1, #0					//Set status to dead 
	str r1, [r0]				//Store status 
	
	ldr r0, =mob1_data			
	ldmia r0, {r4, r5, r6, r7}	//Get x(r4) and y(r5) delta x(r6) delta y (r7) positions of the monster on the current screen
	
	//Reverse any changes made by the update function 
	sub r4, r6 
	sub r5, r7
	mov r6, #0
	mov r7, #0
	stmia r0!, {r4, r5, r6, r7}
	
	add r0, #4					//Start address of the monster's dimensions 
	
	ldmia r0, {r8, r9}			//Get width (r6) and height (r7)
	
	sub r0, r4, r8				//Arg1: start x position
	mov r1, r4					//Arg2: end_x position
	sub r2, r5, r9				//Arg3: start y position
	mov r3, r5					//Arg4: end y position
	
	bl Redraw_Background_X		//Redraw the background 
	
	pop {r4, r5, r6, r7, lr}
	bx lr
	