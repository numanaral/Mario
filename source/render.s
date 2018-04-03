.global RenderCoin
.global RenderBackground 

//====================================
//RenderCoin
//Renders the coin 
//Returns: void 
//====================================
RenderCoin:

	push {r4, r5, r6, r7, lr}
	
	ldr r0, =coin_coordinate 
	ldmia r0, {r4, r5, r6, r7}		//Store the data in memory 
	
	cmp r4, #0						//What should we do?
	bgt RC_create					//Create a coin 
	blt RC_delete					//Delete a coin
	
	b RC_end						//Do nothing

RC_create:
	mov r0, r5						//Arg1: x location			
	mov r1, r6						//Arg2: y location
	ldr r2, =coin_pic 				//Arg3: pointer to coin data 
	
	bl drawPicture					//Call drawPicture
	
	b RC_end						//Branch to RC_end 
	
RC_delete:

	mov r0, r5						//Arg1: x location 
	mov r1, r6						//Arg2: y location 
	ldr r2, =sky_pic 				//Arg3: replace the coin with the sky 
	
	bl drawPicture 					//Call drawPicture 
	
	b RC_end						//Branch to REC_end 
	
RC_end:
	ldr r0, =coin_coordinate 
	mov r1, #0						//Clear coin status 
	str r1, [r0]


	pop {r4, r5, r6, r7, lr}
	bx lr 

//====================================
//void RenderBackground()
//Check if a new screen has been entered and draw the new background if necessary
//Returns: void 
//====================================
RenderBackground:
	push {r4, r5, r6, r7, r8, lr}
	
	ldr r0, =background_changed
	ldr r1, [r0]
	cmp r1, #1			//If not changed
	beq RB_end			//then return
	
	mov r1, #1			//Otherwise store that it has changed
	str r1, [r0]
	
	//Get the background flag 
	ldr r0, =background_flag 
	ldr r4, [r0]
	
	//Check if the background flag has been set 
	//cmp r4, #0
	//beq RB_end 	//If not set, then branch to end 
	
	//Clear the background flag 
	mov r1, #0
	str r1, [r0]
	
	//Get the current background number 
	ldr r1, =cur_background_idx 
	ldr r5, [r1] 
	
	//Update the current background 
	add r5, r4
	
	//If we were at the first background, do nothing if we move backwards 
	cmp r5, #1 
	blt RB_end 
	
	//If we were at the last background, do nothing if we move forewards 
	cmp r5, #7
	bgt RB_end
	
	//Store the current background number 
	str r5, [r1]
	
	//Start backgrounds at index 0 
	sub r5, #1			
	
	//Update the lookup table
	ldr r6, =cur_lookup
	ldr r7, =lookup_array
	ldr r8, [r7, r5, LSL#2]
	
	str r8, [r6]
	
	//Update blocks in memory 
	ldr r6, =cur_blocks
	ldr r7, =blocks_array
	ldr r8, [r7, r5, LSL#2]
	
	str r8, [r6]
	
	//Update mobs in memory 
	
	ldr r6, =cur_mobs
	ldr r7, =mob_array
	ldr r8, [r7, r5, LSL#2]
	
	str r8, [r6]
	
	ldr r0, =cur_lookup
	ldr r0, [r0]
	
	ldr r1, =cur_background
	ldr r1, [r1]
	
	ldr r2, =blocks_1 
	ldr r2, [r2]
	
	bl DrawBackground 
	
	//draw the hud elements on the new background
	bl renderScoreTitle
	bl renderCoinsTitle
	bl renderLivesTitle
	
	//redraw the score too
	ldr r0, =score_changed			//changed score changed to true
	mov r1, #1
	str r1, [r0]
	
	//redraw the coins too
	ldr r0, =coins_count_changed			//changed coins count changed to true
	mov r1, #1
	str r1, [r0]
	
	//redraw the lives too
	ldr r0, =lives_changed			//changed lives changed to true
	mov r1, #1
	str r1, [r0]
	
	bl ValuePackOffScreen				//let the value pack know that it is off screen
									//so another one can be drawn
	
	//copy dynamic frame into the current background 
	mov r0, #0
	mov r1, #0
	ldr r2, =background_1 
	ldr r3, =dyn_background
	bl ReplaceBlockBG
	
	//Set the mob's position
	ldr r0, =mob1_data
	
	ldr r1, =cur_mobs 		//Get pointer to current mobs 
	ldr r1, [r1]
	add r1, #8				//Get mob's initial start position and type 
	ldmia r1, {r2, r3, r4}	//Get x(r2) y(r3) type (r4)
	
	stmia r0!, {r2, r3}		//Set mob's initial position 
	
	//Set delta to 0 
	mov r1, #0
	mov r2, #0
	stmia r0!, {r1, r2}	//Reset delta positions to 0.  r0 now points the address of the picture 
	
	cmp r4, #1				//Is it a gumba?
	ldreq r2, =gumba 		//Set address to picture of gumba 
	ldrne r2, =turtle_addr	//Else, set address to picture of turtle 
	str	r2, [r0]
	
	
	
RB_end:
	pop {r4, r5, r6, r7, r8, lr}
	bx lr 
	
	