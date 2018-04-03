.global getPixelColor
.global CollisionMarioBottom
.global CollisionMarioTop
.global CollisionMarioLeftRight
.global CollisionMonster

.equ sample_interval, 1	//Interval to sample colors 
.equ block_width, 32	//Block width in pixels
.equ block_height, 32	//Block height in pixels 
.equ check_delta, 16

//==============================================================
//short_int getPixelColor(int pixel_x, int pixel_y, int addr) 
//r0: pixel x position
//r1: pixel y position 
//r2: address of picture data in memory 
//Returns: 16 bit number representing the color, -1 if the specified coordinates are outside the picture 
//==============================================================
getPixelColor: 
	push {r3, r6,lr}
	
	ldr  r3, [r2]  						//r3: address of picture
	
	// offset = (y * 1024) + x = x + (y << 10)
	add		r6,	r0, r1, lsl #10
	// offset *= 2 (for 16 bits per pixel = 2 bytes per pixel)
	lsl		r6, #1
	
	ldrh r0, [r3, r6]					//Load the color at the picture address + offset 
	
	b get_pixel_end						//Return the pixel color 
	
//Coordinates are out of range 
get_pixel_oor:
	mov r0, #-1							//Return error code 
	
get_pixel_end:
	pop {r3, r6,lr}
	bx lr 

//==============================================================
//short_int getPixelMajority(int sprite_data)
//Check if sprite has hit an interactive box.  We will return the color that he is touching the most.  
//If mario is only touching one box, we return the color of the box.  If he is touching two boxes, we first 
//sample the right, then the left.  If they are the same color, we return the color.  If not, we sample the center color.  
//If we return the color that matches the center color 
//r0: sprite_data
//Returns: If a box was hit, the x position and y position 
//==============================================================
getPixelMajority: 

	push {r4, r5, r6, r7, r8, r9, r10, lr}

	x_pos			.req r4			//x position of the sprite 
	y_pos  			.req r5			//y position of the sprite
	width 			.req r6			//Height of the sprite 
	height  		.req r7			//Width of the sprite  
		
	//Load Mario's data from memory 
	ldr r0, =mario_data  
	ldmia r0!, {x_pos, y_pos}		//r4: x position, r5: y position 
		
	add r0, #12						//Address of mario_width 
	ldmia r0, {width, height}		//r6: width, r7: height 
	
	sub y_pos, y_pos, height		//Make the y location the top of Mario.  We only need to check different x positions.
	
	//Get color at Mario's top right location 
	
	sub r0, x_pos, #1				//arg1: right x position -1 (Do not check corners because if Mario is perfectly lined up with a block, the corners will not be the right color)
	mov r1, y_pos					//arg2: top y location 
	ldr r2, =dyn_background 		//arg3: pointer to current background 

	bl getPixelColor				//Call getPixelColor 
	
	mov r8, r0						//Save top right color in safe place 
	
	sub r0, x_pos, width			//left x position 
	add r0, #1						//arg1: left x position + 1 (Do not check corners because if Mario is perfectly lined up with a block, the corners will not be the right color)
	mov r1, y_pos					//arg2: top y location 
	ldr r2, =dyn_background 		//arg3: pointer to current background  

	
	bl getPixelColor				//Call getPixelColor 
	
	mov r9, r0						//Save top left color in safe place 
	
	mov r0, #2
	udiv r0, width, r0				//width/2 
	sub r0, y_pos, r0				//arg1: x position - width/2 
	mov r1, y_pos					//arg2: top y location 
	
	ldr r2, =dyn_background 		//arg3: pointer to current background  
	
	bl getPixelColor				//Call getPixelColor 
	
	mov r10, r0						//Save top center color in safe place 
	
	ldr r0, =hit_color				//Get question box color 
	ldr r0, [r0]
	
	ldr r1, =wood_color				//Get wood box color 
	ldr r1, [r1]
	
//Was there a question box on the right ?
gPM_right_check_qbox:	
				
	cmp r8, r0						//Top right hit question box?
	//moveq r3, #1 					//Set return value to 1 
	
	bne gPM_right_check_wbox		//Check if a wood box was hit 
	
	cmp r9, r1						//Top left hit a wood box? 
	beq gPM_tie_break				//Check the center to break the tie 
	bne gPM_right_set				//Only right hit significant 

//Was there a wood box on the right ? 
gPM_right_check_wbox:
	cmp r8, r1						//Top right hit wood box? 
	//moveq r3, #1 					//Set temporary return value to color of wood box
	
	bne gPM_left_only				//right is not touching a question box or a wood box, check the left 
	
	cmp r9, r0						//Top left hit a question box? 
	beq gPM_tie_break				//Check the center to break the tie 
	bne gPM_right_set				//Only right hit significant 
	
	
gPM_right_set:
			
	mov r0, #1						//Something was hit 
	mov r1, x_pos					//right x position
	mov r2, y_pos					//top y location 
	ldr r10, =hit_coordinate		//Return address 
	stmia r10, {r0, r1, r2}			//Store return results in memory 
	
	bne gPM_end						//If not, then we are only touching the wood box 

//There is no box on the right so just check the left 
gPM_left_only:

	cmp r9, r0						//Top left hit question box? 
	//moveq r3, #1					//Set return value to true 
	beq gPM_left_only_set			//Set return arguments 
	
	cmp r9, r1						//Top left hit wood box?  
	//moveq r3, #1					//Set return value to true
	beq gPM_left_only_set	
	bne gPM_end						//If nothing was hit, branch to the end 
	

gPM_left_only_set:
	mov r0, #1						//Something was hit 
	sub r1, x_pos, width			//arg1: left x position
	mov r2, y_pos					//arg2: top y location 
	ldr r10, =hit_coordinate		//Return address 
	stmia r10, {r0, r1, r2}			//Store return results in memory 

	b gPM_end						//Go to end of function 
	
//We go to this label if we are touching a wood box and a question box at the same time 
gPM_tie_break:
	
	mov r0, #1						//Something was hit 
	mov r1, #2
	udiv r1, width, r1				//width/2 
	sub r1, x_pos, r1				//arg1: x position - width/2 
	mov r2, y_pos					//arg2: top y location 
	ldr r10, =hit_coordinate		//Return address 
	stmia r10, {r0, r1, r2}			//Store return results in memory 
		

gPM_end:
	.unreq	x_pos 
	.unreq	y_pos 
	.unreq	width 
	.unreq	height 

	ldr r0, =hit_coordinate			//Address of return values in memory

	pop {r4, r5, r6, r7, r8, r9, r10, lr}
	bx lr 


//==============================================================
//boolean CollisionColorCheck(int sprite_data, int direction, int color)
//Checks whether a character is hitting a certain color in the specified direction
//r0: sprite_loc: pointer to the sprite's 
//r1: direction (1: top, 2:bottom, 3:right, 4:left 
//r2: color to check 
//Returns: 1 if the sprite is bordering the color, 0 otherwise.  Return -1 for invalid input
//==============================================================
CollisionColorCheck: 

	push {r4, r5, r6, r7, r8, r9, r10, lr} 

	width 			.req r4			//Height of the sprite 
	height  		.req r5			//Width of the sprite 
	x_pos			.req r6			//x position of the sprite 
	y_pos  			.req r7			//y position of the sprite 
	background		.req r8			//background to check
	arg_color		.req r9			//the color to check
	
	mov arg_color, r2				//Store the color to check in a safe place  
	
	ldmia r0!, {x_pos, y_pos}		//Load the spirte's x and y position from memory
	add r0, #12						//Set the pointer to point to the sprite's size 
	ldmia r0, {width, height}		//Load the sprite's width and height from memory 
	
	ldr background, =dyn_background //Get address of current background
			
	cmp r1, #1						//Check top?
	subeq y_pos, height				//y position = y position - height 
	beq CCC_top_bottom				//Branch to CCC_top
	
	cmp r1, #2						//Check bottom?
	beq CCC_top_bottom				//Branch to CCC_top
	
	cmp r1, #3						//Check right?
	beq CCC_right_left		
	
	cmp r1, #4						//Check left? 
	subeq x_pos, width				//x position = x position - width 
	beq CCC_right_left 
	
	b CCC_error						//An unacceptable direction has been entered, return error code 
	
CCC_top_bottom:
	x_pos_end		.req r10 	
	sub x_pos_end, x_pos, width  		//Last x position to check 
	
	//Is it the top?
	//addeq x_pos_end, #1				//Do not check bottom left corner 
	//subeq x_pos, #1					//Do not check bottom right corner 
	cmp r1, #2								//Is it the bottom?
	addeq x_pos_end, #2					//Do not check bottom left corner 
	subeq x_pos, #2						//Do not check bottom right corner 
	
	b CCC_top_bottom_loop_test			//Branch to CCC_top_loop_test
	
CCC_top_bottom_loop:
	
	mov r0, x_pos						//Arg1: x location to check
	mov r1, y_pos 						//Arg2: y location to check (top of the image) 
	mov r2, r8							//Arg3: Image to sample 
	
	bl getPixelColor 					//Call getPixelColor 
	
	cmp r0, arg_color 					//Is the color at (x,y) the color we want to detect? 
	moveq r0, #1						//If yes, return true 
	beq CCC_end 						//Branch to the end of the function 
	
	sub x_pos, #1						//Check the next x location 

CCC_top_bottom_loop_test:
	
	cmp x_pos, x_pos_end 				//Have all the x values been checked?
	bge CCC_top_bottom_loop				//If no, check the next x value 
	
	.unreq x_pos_end
	
	mov r0, #0							//Color has not been detected, return false 
	b CCC_end 							//Branch to the end of the function
	
CCC_right_left:
	
	y_pos_end		.req r10 
	sub y_pos_end, y_pos, height 		//Last y position to check 
	
	add y_pos_end, #1					//Do not check top corner
	sub y_pos, #1						//Do not check bottom corner 
	
	b CCC_right_left_loop_test			//Branch to CCC_right_left_loop_test 
	
CCC_right_left_loop:

	mov r0, x_pos 						//Arg1: x location to check
	mov r1, y_pos						//Arg2: y location to check
	mov r2, r8 							//Arg3: Image to sample 
	
	bl getPixelColor					//Call getPixelColor
	
	cmp r0, arg_color 					//Is the color at (x,y) the color we want to detect? 
	moveq r0, #1						//If yes, return true 
	beq CCC_end 						//Branch to the end of the function 	
	
	sub y_pos, #1						//Check the next y location 

CCC_right_left_loop_test: 

	cmp y_pos, y_pos_end				//Have all the y values been checked?
	bge CCC_right_left_loop				//If not, check the next y value 
	
	.unreq	y_pos_end 
	
	mov r0, #0							//Color has not been detected, return false
	b CCC_end 							//Branch to end of the function
	
CCC_error:
	mov r0, #-1
	
CCC_end:
	pop {r4, r5, r6, r7, r8, r9, r10, lr}
	bx lr 
	
	
//==============================================================
//void CollisionMarioBottom()
//Handle collisions from beneath Mario
//Returns: void 
//==============================================================
CollisionMarioBottom:
	push {r4, r5, r6, r7, lr}
	
	ldr r0, =mario_data					//Get address of mario_data
	ldmia r0, {r4, r5, r6, r7}			//Load mario x (r4), y (r5), delta x (r6), delta y (r7)
	
	//Check if mario fell into a pit 
	ldr r0, =0x2FE						//Decimal 766 - lowest point in the screen
	cmp r5, r0							//Has Mario fallen into a pit?
	blge CollisionMarioDead				//Mario has died 
	bge CMB_end 
	
	//MONSTER 
	ldr r0, =mario_data					//Arg1: address of mario data 
	mov r1, #2							//Arg2: check bottom
	bl isMonsterHit						//Has mario hit a monster?
	cmp r0, #1							
	beq CMB_monster						//Branch CMB_monster
	
	//FLOOR
	ldr r0, =mario_data 
	mov r1, #2							//Check the bottom 
	bl isCollisionImpassable			//Call isCollisionImpassable
	cmp r0, #1							//Has mario hit the floor? 
	beq CMB_floor 						//Branch to CMB_floor 
	
	//Clear the floor flag because mario is not touching the floor 
	ldr r0, =is_floor					//Else clear the floor flag 
	mov r1, #0							
	str r1, [r0]						//Clear floor flag in memory 
	//END_FLOOR 

	b CMB_end						
	
CMB_floor: 
	//Reverse the change made by the update function in the y direction 
	sub r5, r7							//Mario y = mario y - delta y
	mov r7, #0							//Clear delta_y
	
	ldr r0, =mario_data					//Get address of mario_data 
	stmia r0, {r4,r5,r6,r7}				//Update mario x,y,delta x,delta y in memory
	
	//Set the floor flag because mario is on the floor 
	ldr r0, =is_floor					//Set the floor flag 
	mov r1, #1							
	str r1, [r0]						//Set floor flag in memory 

	b CMB_end							//Branch to CMB_end 

CMB_monster: 

	ldr r2, =jump_flag					//Load address of jump_flag
	mov r0, #1							//Set jump flag to 1 
	str r0, [r2]						//Update jump_flag in memory 
	
	ldr r1, =jump_height				//Get address of jump_height 
	mov r0, #75							//Set jump height to 75 pixels 
	str r0, [r1]						//Update jump height in memory 
	
	bl killCurMonster					//Kill current monster
	
	mov r0, #100						//Add 100 to the score 
	bl updateScore

	b CMB_end 

CMB_end:
	pop {r4, r5, r6, r7, lr}
	bx lr 
	

//==============================================================
//void CollisionMarioTop()
//Handle collisions from above Mario 
//Returns:void
//==============================================================
CollisionMarioTop:
	push {lr}
	
	bl CollisionBox		//Handle bottom collisions

CMT_end:
	pop {lr}
	bx lr 

//==============================================================
//void CollisionMarioLeftRight()
//Handle collisions when mario moves left or right 
//Returns: void 
//==============================================================
CollisionMarioLeftRight:
	push {r4, r5, r6, r7, lr}
	
	ldr r0, =mario_data					//Get address of mario_data
	ldmia r0, {r4, r5, r6, r7}			//Load mario x (r4), y (r5), delta x (r6), delta y (r7)
	
	//Set a flag to move to the next background
	ldr r0, =0x3FF						//Decimal 1023 
	cmp r4, r0
	ldrge r0, =background_flag 
	movge r2, #1 
	strge r2, [r0]						//Set background flag in memory
	
	ldrge r0, =background_changed		//Let the renderer know that the background should change
	movge r1, #0
	strge r1, [r0] 
	bge CMLR_dif_screen					//Set Mario's initial position on the new screen

	
	//Set a flag to move to the previous background 
	cmp r4, #31
	ldrle r0, =background_flag 
	movle r2, #-1 
	strle r2, [r0]						//Set background flag in memory

	ldrle r0, =background_changed		//Let the renderer know that the background should change
	movge r1, #0
	strle r1, [r0] 
	ble CMLR_dif_screen					//Set Mario's initial position on the new screen

	
	//Check if mario hit an impassable object to the left 
	ldr r0, =mario_data 				//Arg1: address of mario_data
	mov r1, #4							//Arg2: Check the left
	bl isCollisionImpassable			//Call isCollisionImpassable
	
	cmp r0, #1							//Has mario hit the floor? 
	beq CMLR_impassable	 				//Branch to CMLR_impassable	 
	
	//Check if mario hit an impassable object to the right
	ldr r0, =mario_data 				//Arg1: address of mario_data
	mov r1, #3							//Arg2: Check the left
	bl isCollisionImpassable			//Call isCollisionImpassable
	
	cmp r0, #1							//Has mario hit the floor? 
	beq CMLR_impassable	 				//Branch to CMLR_impassable	
	
	//Check if mario hit a monster 
	ldr r0, =mario_data					//Arg1: address of mario data 
	mov r1, #3							//Arg2: check right
	bl isMonsterHit						//Has mario hit a monster?
	cmp r0, #1							
	
	bleq CollisionMarioDead				//Set Mario's position to his respawn position and remove a life 
	beq CMLR_end

	//Check if mario hit a monster 
	ldr r0, =mario_data					//Arg1: address of mario data 
	mov r1, #4							//Arg2: check left 
	bl isMonsterHit						//Has mario hit a monster?
	cmp r0, #1							
	bleq CollisionMarioDead				//Branch CMB_monster
	
	//If we are at the end of the screen, move to the next screen 
	
	b CMLR_end							//Branch to end of the function

CMLR_impassable:

	//Reverse the change made by the update function in the x direction 
	sub r4, r6							//Mario x = mario x - delta x 
	mov r6, #0							//Clear delta x 
	
	ldr r0, =mario_data					//Get address of mario_data 
	stmia r0, {r4,r5,r6,r7}				//Update mario x,y,delta x,delta y in memory
	
	b CMLR_end

CMLR_dif_screen:

	//Did mario move to the previous screen or the next screen
	cmp r2, #0
	ldr r0, =mario_data 
	blt CMLR_previous_screen
	
CMLR_next_screen:
	//If Mario moved to the next screen, set him at the start of the next screen 
	ldr r1, =0x22		//decimal 34
	ldr r2, =0x29E		//decimal 670
	
	b	CMLR_screen_position_set

CMLR_previous_screen:

	//If we are on the first screen, we should not be able to move backwards 
	ldr r3, =cur_background_idx 	
	ldr r3, [r3] 
	cmp r3, #1 
	beq CMLR_impassable 
	
	//If Mario moved to the last screen, set him at the end of that screen
	ldr r1, =0x3F4		//decimal 1012
	ldr r2, =0x29E		//decmial 670 
	
CMLR_screen_position_set:
	//Set Mario's new coordinates for the upcoming screen 
	stmia r0, {r1, r2} 
	
	//End Mario's jump if he is jumping 
	bl endJump

CMLR_end:
	pop {r4, r5, r6, r7, lr}
	bx lr 


//==============================================================
//int CollisionBox()
//Handle collisions when mario moves right 
//Returns: box that was destroyed {0: first box 1: second box ...} -1 if no box is destroyed 
//==============================================================
CollisionBox:
	push {r4, r5, r6, r7, r8, r9, r10, lr}

	ldr r0, =mario_data 
	bl getPixelMajority //Check if mario has hit a box 
	
	hit_x_pos			.req r4		//x position of the sprite 
	hit_y_pos  			.req r5		//y position of the sprite 
	
	ldr r1, [r0], #4				//Check if mario has hit something 
	cmp r1, #1						//Mario has hit something?
	bne CB_end						//If not branch to the end of the program  

	ldmia r0, {hit_x_pos, hit_y_pos}	//Get the position that mario hit 
	
	box_x_pos			.req r6		//x position of the block 
	box_y_pos  			.req r7		//y position of the block 
	box_type			.req r8		//type of block 
break111:
	ldr r9, =cur_blocks 			//Address of cur_blocks
	ldr r9, [r9] 					//Starting address of cur_blocks 
	ldr r10, [r9], #4				//Load number of blocks in this block set 
	
	b CB_loop_test

//Check which block was hit 
CB_loop:
	ldmia r9!, {box_x_pos, box_y_pos, box_type}
	
	add r0, box_x_pos, #block_width	//Get right x of block 
	cmp hit_x_pos, r0 				//Did Mario hit this block 
	bgt CB_loop_post				//Not this block 
	
	sub r0, hit_y_pos, #check_delta
	cmp r0, box_y_pos				//Did Mario hit this block
	
	blt CB_loop_post				//If yes, branch to CB_block_found
	
	add r1, box_y_pos, #block_height//Get bottom of the block
	cmp r0, r1
	blt CB_block_found 

CB_loop_post:
	
	add r9, #4						//Skip the status 
	sub r10, #1						//Decremenet number of blocks left to check 
	
CB_loop_test:
	cmp r10, #0						//Have we checked all the blocks?
	bgt CB_loop						//Continue to check blocks 
	
CB_block_found:
	bl endJump						//End Jump

	cmp box_type, #0				//Question block?
	beq CB_wbox
	
	cmp box_type, #1				//Wood block?
	beq CB_qbox
	
	cmp box_type, #2				//Solid block?
	beq CB_end
	
	b CB_end						//End 
	
CB_qbox:
	mov r0, box_x_pos 				//Arg1: x position to start draw from 
	mov r1, box_y_pos 				//Arg2: y position to start draw from 
	ldr r2, =qbox_after_pic			//Arg3: picture to draw 
	
	bl drawPicture					//Call drawPicture 
	
	mov r0, #2
	str r0, [r9, #-4] 			//Set box type to solid 
	
	mov r0,	box_x_pos				//Arg1: x position
	mov r1,	box_y_pos				//Arg2: y position
	ldr r2, =cur_background		
	ldr r2, [r2]					//Arg3: background 
	ldr r3, =qbox_after_pic 		//Arg4: picture to insert into background 
	bl ReplaceBlockBG 				//Delete the box from the background 
	
	ldr r0, =cur_lookup				//Arg1: current lookup table 
	ldr r0, [r0]
	lsr r1,	box_x_pos, #5			//Arg2: x position
	lsr r2,	box_y_pos, #5			//Arg3: y position
	mov r3, #5
	bl ModifyLookup
	
	mov r0, box_x_pos				//Arg1: x position
	mov r1, box_y_pos				//Arg2: y position
	bl coinInit						//Call coinInit
	
	mov r0, #50						//Add 50 to the score 
	bl updateScore					//Update score 
	bl incrementCoins				//add 1 coin
	
	b CB_end 						//Branch to end 

CB_wbox:

	mov r0, box_x_pos 				//Arg1: x position to start draw from 
	mov r1, box_y_pos 				//Arg2: y position to start draw from 
	ldr r2, =sky_pic				//Arg3: picture to draw 
	
	bl drawPicture					//Call drawPicture 
	
	//mov r0, #0
	//str r0, [r9] 					//Set box status to destroyed
	
	mov r0,	box_x_pos				//Arg1: x position
	mov r1,	box_y_pos				//Arg2: y position
	ldr r2, =cur_background		
	ldr r2, [r2]					//Arg3: background 
	ldr r3, =sky_pic 				//Arg4: picture to insert into background 
	bl ReplaceBlockBG 				//Delete the box from the background 
	
	ldr r0, =cur_lookup				//Arg1: current lookup table 
	ldr r0, [r0]
	lsr r1,	box_x_pos, #5			//Arg2: x position
	lsr r2,	box_y_pos, #5			//Arg3: y position
	mov r3, #0						//Arg4: sky box 
	bl ModifyLookup
	
	ldr r0, =mario_data					//Get address of mario_data
	ldmia r0, {r4, r5, r6, r7}			//Load mario x (r4), y (r5), delta x (r6), delta y (r7)
	
	b CB_end 						//Branch to end 
	
CB_end:

	ldr r0, =hit_coordinate 
	mov r1, #0
	mov r2, #0
	mov r3, #0
	
	stmia r0, {r1,r2,r3}			//Clear hit_coordinate 
	
	pop {r4, r5, r6, r7, r8, r9, r10, lr}
	bx lr 

//==============================================================
//boolean isCollisionImpassable(int spirte, int direction )
//Checks if the sprite is on the floor 
//r0: pointer to sprite_data 
//r1: direction to check 1:top, 2:bottom, 3:right, 4: left 
//Returns: true if the sprite is on the floor, false otherwise 
//==============================================================
isCollisionImpassable:

	push {r4, r5, r6, lr}

	mov r4, r0							//Save pointer to sprite data in safe place 
	mov r5, #0							//Set default return value to false
	mov r6, r1							//Save direction in a safe place 

	//Check Pink
	mov r0, r4							//Arg1: address of mario_data
	mov r1, r6							//Arg2: direction to check 
	ldr r2, =ground_color_1				
	ldr r2, [r2]						//Arg3: Check pink
	bl CollisionColorCheck
	
	cmp r0, #1 							//Sprite has hit a floor? 
	beq iCC_true 						//Branch to CMB_floor 
	
	//Check Black
	mov r0, r4							//Arg1: address of mario_data
	mov r1, r6							//Arg2: direction to check 
	ldr r2, =impassable_color			
	ldr r2, [r2]						//Arg3: Check black 
	bl CollisionColorCheck
	
	cmp r0, #1 							//Sprite has hit something? 
	beq iCC_true 						//Branch to CMB_floor 
	
	//Check Brown 
	mov r0, r4							//Arg1: address of sprite_data
	mov r1, r6							//Arg2: direction to check 
	ldr r2, =ground_color_2				
	ldr r2, [r2]						//Arg3: Check brown
	bl CollisionColorCheck
	
	cmp r0, #1 							//Sprite has hit a floor? 
	beq iCC_true						//Return true 	
	
	b iCC_end							//Sprite is not touching the floor so return false 
	
	
iCC_true:
	mov r0, #1							//Set return value to true 

iCC_end:
	
	pop {r4, r5, r6, lr}
	bx lr
	
//==============================================================
//boolean isMonsterHit(int spirte, int direction)
//Checks if sprite has hit the monster from specified direction.  Also checks if the star has been hit (in this case, return false)
//r0: pointer to sprite_data 
//r1: direction to check 1:top, 2:bottom, 3:right, 4: left 
//Returns: true if the sprite hit a monster, false otherwise 
//==============================================================
isMonsterHit:
	
	push {r4, r5, r6, lr}

	mov r4, r0							//Save pointer to sprite data in safe place 
	mov r5, #0							//Set default return value to false
	mov r6, r1							//Save direction in a safe place 
	
	cmp r6, #2 							//Checking the bottom should only look for hit colors 
	beq iMH_bottom	

iMH_left_right:
	//Check if the star has been hit 
	mov r0, r4 							//Arg1: address of mario_data 
	mov r1, r6							//Arg2: specified direction
	ldr r2, =star_color 				
	ldrh r2, [r2]						//Arg3: star color 
	bl CollisionColorCheck
	cmp r0, #1							//Has star been hit? 
	bleq CollisionStar					//Star has been hit 
	mov r0, #0 							//Clear return value 
	
	//Check if a gumba has been hit from side 
	mov r0, r4							//Arg1: address of mario_data
	mov r1, r6							//Arg2: Check the specified direction 
	ldr r2, =gumba_color 			
	ldr r2, [r2]						//Arg3: Check gumba color
	bl CollisionColorCheck
	cmp r0, #1							//If collided, skip other checks 
	beq iMH_end
	
	//Check if turtle has been hit from side (orange)
	mov r0, r4							//Arg1: address of mario_data
	mov r1, r6							//Arg2: Check the specified direction
	ldr r2, =turtle_color_o 			
	ldr r2, [r2] 						//Arg3: Orange turtle color 
	bl CollisionColorCheck  
	cmp r0, #1
	beq iMH_end							//If collided, skip other checks 
	
	//Check if turtle has been hit from side (green)
	mov r0, r4							//Arg1: address of mario_data
	mov r1, r6							//Arg2: Check the specified direction
	ldr r2, =turtle_color_g 			
	ldr r2, [r2] 						//Arg3: Green turtle color 
	bl CollisionColorCheck  
	cmp r0, #1
	beq iMH_end							//If collided, skip other checks 
	
	b iMH_end							//Branch to end 
	
iMH_bottom:

	//Check if a gumba has been hit from above
	mov r0, r4							//Arg1: address of mario_data
	mov r1, r6							//Arg2: Check the specified direction 
	ldr r2, =gumba_color_hit 			
	ldrh r2, [r2]						//Arg3: Check gumba color
	bl CollisionColorCheck
	cmp r0, #1							//If collided, skip other checks 
	beq iMH_end

	//Check if turtle has been hit from above 
	mov r0, r4							//Arg1: address of mario_data
	mov r1, r6							//Arg2: Check the specified direction
	ldr r2, =turtle_color_hit 			
	ldrh r2, [r2] 						//Arg3: White turtle color 
	bl CollisionColorCheck  
	cmp r0, #1
	beq iMH_end							//If collided, skip other checks 
	
iMH_end:
	pop {r4, r5, r6, lr}
	bx lr 

//==============================================================
//void CollisionMonster 
//Handles monster collisions
//Returns: void
//==============================================================
CollisionMonster:
	push {lr}
	
	ldr r0, =mob1_data
	bl CollisionMonsterBottom
	
	ldr r0, =mob1_data	
	bl CollisionMonsterLeftRight
	
	pop {lr}
	bx lr

//==============================================================
//void CollisionMonsterBottom(int data_pointer)
//Handle collisions from beneath monster
//Returns: void 
//==============================================================
CollisionMonsterBottom:
	push {r4, r5, r6, r7, r8, lr}
	
	mov r8, r0							//Save data pointer in safe place 
	
	ldmia r8, {r4, r5, r6, r7}			//Load mario x (r4), y (r5), delta x (r6), delta y (r7)
	
	//Check if fell into a pit 
	ldr r0, =0x2FE						//Decimal 766 - lowest point in the screen
	cmp r5, r0							//Has monster fallen into pit?
	blge killCurMonster					//Kill monster 
	bge CMOB_end 
	
	//FLOOR
	mov r0, r8 							//Arg1: data_pointer
	mov r1, #2							//Arg2: Check the bottom 
	bl isCollisionImpassable			//Call isCollisionImpassable
	cmp r0, #1							//Has monster hit the floor? 
	beq CMOB_floor 						//Branch to CMB_floor 

CMOB_drop:
	//If the monster is falling, then do not change the x direction 
	sub r4, r6							//monster x = monster x - delta x 
	mov r6, #0							//Clear delta_x 
	
	b CMOB_end							
	
CMOB_floor: 

	//Reverse the change made by the update function in the y direction 
	sub r5, r7							//monster y = monster y - delta y
	mov r7, #0							//Clear delta_y
	
	b CMOB_end							//Branch to CMB_end 

CMOB_end:
	stmia r8, {r4,r5,r6,r7}				//Update monster x,y,delta x,delta y in memory

	pop {r4, r5, r6, r7, r8, lr}
	bx lr 
	
//==============================================================
//void CollisionMonsterLeftRight(int data_pointer)
//Handle collisions on left and right on monster 
//Returns: void 
//==============================================================	
CollisionMonsterLeftRight:
	push {r4, r5, r6, r7, r8, lr}
	
	mov r8, r0							//Store data pointer in safe location 
	
	ldmia r8, {r4, r5, r6, r7}			//Load monster x (r4), y (r5), delta x (r6), delta y (r7)
	
	//Check if monster hit an impassable object to the left 
	mov r0, r8							//Arg1: address of data_pointer
	mov r1, #4							//Arg2: Check the left
	bl isCollisionImpassable			//Call isCollisionImpassable
	
	cmp r0, #1							//Has monster hit something to the left? 
	beq CMoLR_impassable	 			//Branch to CMoLR_impassable	 
	
	//Check if monster hit an impassable object to the right
	mov r0, r8							//Arg1: address of data_pointer
	mov r1, #3							//Arg2: Check the right
	bl isCollisionImpassable			//Call isCollisionImpassable
	
	cmp r0, #1							//Has monster hit something to the right?? 
	beq CMoLR_impassable	 			//Branch to CMoLR_impassable	
	
	//Check bounds left 
	cmp r4, #32							//Check if monster hit the left edge of the screen
	blt CMoLR_impassable 				//Bounce back 
	
	//Check bounds right 
	ldr r0, =0x3FF						//Check if monster hit the right edge of the screen (Decimal 1023) 
	cmp r5, r0 							//bgt CMoLR_impassable 
	bgt CMoLR_impassable 
	
	b CMoLR_end							//Branch to end of the function
	
CMoLR_impassable:
	
	ldr r0, =cur_mobs			//Get pointer to cur_mobs
	ldr r0, [r0]				//Get address of set of current mobs  
	
	add r0, #4					//Get address of monster direction 
	
	ldr r1, [r0]				//Get monster direction
	cmp r1, #1					//Going right?
	
	moveq r1, #-1				//Switch to left 
	movne r1, #1				//Switch to right 
	
	str r1, [r0]				//Store monster direction 
	
	//Reverse the change made by the update function in the x direction 
	sub r4, r6					//monster x = monster x - delta x 
	mov r6, r1					//switch direction 
	
	stmia r8, {r4,r5,r6,r7}				//Update monster x,y,delta x,delta y in memory
	
CMoLR_end:

	pop {r4, r5, r6, r7, r8, lr}
	bx lr 


//==================================================
//void CollisionMarioDead()
//Removes a life from Mario and sets his new spawn location
//Returns: void 
//==================================================
CollisionMarioDead:

	push {r4, r5, r6, r7, lr}
	
	ldr r0, =mario_data
	ldmia r0, {r4, r5, r6, r7}

	sub r4, r6							//Reverse x position changes made by update 
	sub r5, r7							//Reverse y position changes made by update 
	rsb r6, r4, #100					//Calculate delta between current x position and x position where mario will respawn
	rsb r7, r5,	#500					//Calculate delta between current y position and y position where mario will respawn
	mov r4, #100						//Set mario's original position
	mov r5,	#500						//Set mario's original position 

	ldr r0, =mario_data					//Get address of mario_data 
	stmia r0, {r4,r5,r6,r7}				//Update mario x,y,delta x,delta y in memory
	
	bl decrementLives					//Decrement number of lives 

	pop {r4, r5, r6, r7, lr}
	bx lr 

//==================================================
//void CollisionStar()
//Handle a star collision by erasing the star and implementing the value pack 
//Returns: void 
//==================================================
CollisionStar: 

	push {r4, lr}
	
	//Get coordinates of the star 
	ldr r0, =value_pack_pos			
	ldmia r0, {r1, r2} 					//r1(x) r2(y)
	
	//Get dimensions of the star 
	ldr r0, =star_pic						
	ldmib r0, {r3, r4} 					//r3(width), r4(height)
	
	//Redraw_Background_X(x_start, x_end, y_start, y_end)
	mov r0, r1							//Arg1: x_start
	add r1, r3 							//Arg2: x_end 
	
	//mov r2, r2 						//Arg3: y_start 
	add r3, r2							//Arg3: y_end 
	
	bl Redraw_Background_X				//Redraw background at star's location 
	
	//*******STAR FUNCTION GOES HERE***************//
	bl ValuePackOffScreen					//Now another star can be drawn
	bl incrementLives						//the value pack gives you another life
										
	pop {r4, lr}
	bx lr 



	