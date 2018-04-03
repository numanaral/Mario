//Drawing functions 
.global moveThing
.global drawPicture
.global clearScreen
.global redrawBlocks
.global drawRectangle
.global ReplaceBlockBG
.global Redraw_Background_X
.global DrawBackground 
.global ModifyLookup
//======================================================
//void moveThing(int thing_pointer) 
//Draws something in new location.  Clears delta values 
//r0: pointer to the structure containing the data 
//Returns: void 
//======================================================
moveThing: 
	push {r4, r5, r6, r7, r8, r9, lr} 
	
	thing_x	.req r4 
	thing_y	.req r5
	delta_x .req r6
	delta_y	.req r7
	thing_old_x .req r8
	thing_old_y .req r9 
	addr 		.req r10 
	
	ldmia r0!, {thing_x, thing_y, delta_x, delta_y}
	mov addr, r0							//Address of thing		

	cmp delta_x, #0							//Has thing moved in the x direction? 
	bne movement 
									
	cmp delta_y, #0 						//Has thing moved in either direction? 
	beq move_end							//Thing has not moved anywhere so do not draw anything 

movement:
	sub thing_old_x, thing_x, delta_x		//Save thing's old position
	sub thing_old_y, thing_y, delta_y		//Save thing's old position
	
	.unreq thing_x 
	.unreq thing_y 
	
	width	.req r4					
	height	.req r5 
	
	ldmib r0, {width, height}		//Get width and height of character 

	add r0, thing_old_x, delta_x	//Get x_current
	sub r0, width					//Arg1: X position to start drawing Character  
	add r1, thing_old_y, delta_y	//Get y_current 
	sub r1, height 					//Arg2: Y position to start drawing Character 
	
	mov r2, addr 
	bl drawPicture					//Draw thing
	
	mov r2, #-1 					//Used to change negative numbers into positive numbers 
	
	//Check if background has to be completely redrawn because thing moved far 
	movs r0, delta_x				//Get absolute value of delta x
	mulmi r0, delta_x, r2
	
	movs r1, delta_y 				//Get absolute value of delta y
	mulmi r1, delta_y, r2			
	
	cmp r0, width					//thing moved greater than his size?
	bgt teleport 
	
	cmp r1, height					//thing moved greater than his size? 
	bgt teleport 
	
	//Redraw portion of background 
	cmp delta_x, #0					//Is thing moving backwards?
	blt move_backward				//Branch to move_backward
	b move_foreward					//Else branch to move_foreward
	
teleport: 
	sub r0, thing_old_x, width		//Arg1: x_start 
	mov r1, thing_old_x				//Arg2: x_end
	sub r2, thing_old_y, height		//Arg3: y_start 
	mov r3, thing_old_y				//Arg4: y_end 
	
	bl Redraw_Background_X			//Redraw the background behind thing 
	
	b move_end						//Branch to end 

move_foreward:
	//TODO: thing hit a wall
	sub r0, thing_old_x, width		//Arg1: x_start 
	add r1, r0, delta_x				//Arg2: x_end

	sub r2, thing_old_y, height		//Arg2: y_start 
	mov r3, thing_old_y				//Arg4: y_end 
	
	bl Redraw_Background_X 			//Redraw the background behind thing 
	
	cmp delta_y, #0					//Is thing moving up or down? 
	bgt move_down					//Branch to move_down 
	blt move_up						//Branch to move_up
	
move_backward:
	//TODO: thing hit a wall
	add r0, thing_old_x, delta_x	//Arg2: x_end
	mov r1, thing_old_x 			//Arg1: x_start
	
	sub r2, thing_old_y, height	//Arg3: y_start 
	mov r3, thing_old_y					//Arg4: y_end 
	
	bl Redraw_Background_X			//Redraw the background behind thing
	
	cmp delta_y, #0					//Is thing moving down? 
	bgt move_down 					//Branch to move_down

move_up:
	//TODO: thing hit a ceiling 
	add r2, thing_old_y, delta_y	//Arg3: y_start
	mov r3, thing_old_y				//Arg4: y_end 
	
	sub r0, thing_old_x, width		//Arg1	x_start 
	mov r1, thing_old_x				//Arg2 	x_end 
	
	bl Redraw_Background_Y			//Redraw the background below thing 
	
	b move_end						//Branch to move_end 

move_down:
	//TODO: thing hit ground 
	
	sub r2, thing_old_y, height		//Arg 3 y_start 
	add r3, r2, delta_y 			//Arg 4 y_end
	
	sub r0, thing_old_x, width		//Arg 1 x_start				
	mov r1, thing_old_x				//Arg 2 x_end 
	
	bl Redraw_Background_Y			//Redraw the background above thing 

move_end:

	sub addr, #8					//Get address of delta_x 
	
	mov r1, #0						//Set delta_x to 0 
	mov r2, #0						//Set delta_y to 0 
	
	stmia addr, {r1,r2}				//Update delta_x and delta_y in memory

	.unreq delta_x 
	.unreq delta_y 
	.unreq thing_old_x
	.unreq thing_old_y
	.unreq addr 

	pop	{r4, r5, r6, r7, r8, r9, lr} 
	bx lr 
	
//======================================================
//Redraw_Background_X(x_start, x_end, y_start, y_end)
//Redraws the background when mario moves horizontally
//r0: x_start
//r1: x_end
//r2: y_start
//r3: y_end
//======================================================
Redraw_Background_X:
	push {r4, r5, r6, r7, r8, r9, r10, lr}

	mov r4, r0	//Save x_start in safe place 
	mov r5, r1	//Save x_end in a safe place
	mov r6, r2	//Save y_start in a safe place
	mov r7, r3	//Save y_end in a safe place 
	
	x_start	.req r4
	x_end	.req r5
	y_start	.req r6
	y_end 	.req r7
	
	b rb_x_loop_test_0	//Branch to rb_x_loop_test_0
	
rb_x_loop_0:
	
	mov r8, y_start 	//Counter for y coordinate 
	b rb_x_loop_test_1	//Branch to rb_x_loop_test_1 
	
rb_x_loop_1:
	mov r0, x_start		//Arg1: x coordinate to draw 
	mov r1, r8 			//Arg2: y coordinate to draw 
	
	
	// offset = (y * 1024) + x = x + (y << 10)
	add		r9,	r0, r1, lsl #10
	// offset *= 2 (for 16 bits per pixel = 2 bytes per pixel)
	lsl		r9, #1
	
	ldr 	r10, =background_1 	//Get address of background_1 data structure 
	ldr		r10, [r10]			//Get pointer to the image 
	ldrh	r2, [r10, r9]		//Get pixel color at the background coordinate we want to draw 

	bl DrawPixel		//Call Draw Pixel
	
	add r8, #1 			//Increment y counter  

rb_x_loop_test_1:
	cmp r8, y_end 		//Have all the y been painted?
	blt rb_x_loop_1		//If not, draw the next y 

	add x_start, #1 	//Increment x counter 
rb_x_loop_test_0: 
	cmp x_start, x_end 	//Have all the x been painted? 
	blt rb_x_loop_0		//If not, draw the next x 

	.unreq x_start 
	.unreq x_end 
	.unreq y_start 
	.unreq y_end  

	pop {r4, r5, r6, r7, r8, r9, r10, lr}
	bx lr 


//======================================================
//RedrawBackground_Y(x_start, x_end, y_start, y_end)
//Redraws the background when Mario moves vertically 
//r0: x_start
//r1: x_end
//r2: y_start
//r3: y_end
//======================================================
Redraw_Background_Y:
	push {r4, r5, r6, r7, r8, r9, r10, lr}

	mov r4, r0	//Save x_start in safe place 
	mov r5, r1	//Save x_end in a safe place
	mov r6, r2	//Save y_start in a safe place
	mov r7, r3	//Save y_end in a safe place 
	
	x_start	.req r4
	x_end	.req r5
	y_start	.req r6
	y_end 	.req r7
	
	b rb_y_loop_test_0	//Branch to rb_y_loop_test_0
	
rb_y_loop_0:
	
	mov r8, x_start 	//Counter for x coordinate 
	b rb_y_loop_test_1	//Branch to rb_x_loop_test_1 
	
rb_y_loop_1:
	mov r0, r8			//Arg1: x coordinate to draw 
	mov r1, y_start 	//Arg2: y coordinate to draw 

	
	// offset = (y * 1024) + x = x + (y << 10)
	add		r9,	r0, r1, lsl #10
	// offset *= 2 (for 16 bits per pixel = 2 bytes per pixel)
	lsl		r9, #1
	
	ldr 	r10, =background_1 	//Get address of background_1 data structure 
	ldr		r10, [r10]			//Get pointer to the image 
	ldrh	r2, [r10, r9]		//Get pixel color at the background coordinate we want to draw 
	
	bl DrawPixel		//Call Draw Pixel
	
	add r8, #1 			//Increment x counter  

rb_y_loop_test_1:
	cmp r8, x_end 		//Have all the y been painted?
	blt rb_y_loop_1		//If not, draw the next y 

	add y_start, #1 	//Increment y counter 
rb_y_loop_test_0: 
	cmp y_start, y_end 	//Have all the x been painted? 
	blt rb_y_loop_0		//If not, draw the next x 

	.unreq x_start 
	.unreq x_end 
	.unreq y_start 
	.unreq y_end  
	
	pop {r4, r5, r6, r7, r8, r9, r10, lr}
	bx lr 

/* Draw Pixel
 *  r0 - x
 *  r1 - y
 *  r2 - color
 */

DrawPixel:
	push	{r4, r5}
	
	offset	.req	r4

	// offset = (y * 1024) + x = x + (y << 10)
	add		offset,	r0, r1, lsl #10
	// offset *= 2 (for 16 bits per pixel = 2 bytes per pixel)
	lsl		offset, #1
	
	cmp r2, #0xA			//Sprite's back ground color.  Draw background instead if we see this color 
	bne DP_normal
	ldr r5, =bg_1 
	ldrh r2, [r5, offset]
	
	// store the colour (half word) at framebuffer pointer + offset
DP_normal:
	//ldr r0, =dyn_background	//Is the color the same as what is already displayed
	//ldr r1, [r0]
	ldr r1, =dyn_frame
	ldrh r5, [r1, offset]
	
	cmp r5, r2
	beq DP_end 				//Skip drawing 

	ldr	r0, =FrameBufferPointer
	ldr	r0, [r0]
	strh	r2, [r0, offset]
	
	// store color in the dynamic frame 
	//ldr r1, =dyn_background	//Load address of dynamic background
	//ldr r1, [r1]			//load address of dynamic frame 
	strh r2, [r1, offset]

DP_end:
	pop		{r4, r5}
	bx		lr

//======================================================
//void DrawPicture(int x_start, int y_start, int addr)
//r0: x_start
//r1: y_start
//r2: pointer to a structure containing the picture's address and dimensions int[addr, width, height]
//Returns void 
//======================================================
drawPicture:
	push {r4,r5,r6,r7,r8,r9,lr}
	mov	r4,	r0					//Start X position of your picture (changes with each loop)
	mov	r5,	r1					//Start Y position of the picture  (changes with each loop)
	
	ldmia r2, {r6, r7, r8}		//Load the address, width and height of the picture 
	
	add r7, r4					//End x position of the picture 
	add	r8, r5					//End y position of the picture
	
	mov r9, r0					//Start X position (does not change)
drawPictureLoop:
	mov	r0,	r4			//passing x for ro which is used by the Draw pixel function 
	mov	r1,	r5			//passing y for r1 which is used by the Draw pixel formula 
	
	ldrh	r2,	[r6],#2	//setting pixel color by loading it from the data section. We load hald word
	bl	DrawPixel
	add	r4,	#1			//increment x position
	cmp	r4,	r7			//compare with image with
	blt	drawPictureLoop
	mov	r4,	r9			//reset x
	add	r5,	#1			//increment Y
	cmp	r5,	r8			//compare y with image height
	blt	drawPictureLoop	
	
	pop    {r4,r5,r6,r7,r8,r9,lr}
	mov	pc,	lr			//return

//=====================================================
//void clearScreen()
//Clears the screen
//=====================================================
clearScreen:
	push {r4,r5,r6,r7,r8,lr}

	mov	r4,	#0			//x value
	mov	r5,	#0			//Y value
	ldr	r6,	=0x0001		//black color
	ldr	r7,	=1023		//Width of screen
	ldr	r8,	=767		//Height of the screen
	
Looping:
	mov	r0,	r4			//Setting x 
	mov	r1,	r5			//Setting y
	mov	r2,	r6			//setting pixel color
	push {lr}
	bl	DrawPixel
	pop {lr}
	add	r4,	#1			//increment x by 1
	cmp	r4,	r7			//compare with width
	ble	Looping
	mov	r4,	#0			//reset x
	add	r5,	#1			//increment Y by 1
	cmp	r5,	r8			//compare with height
	ble	Looping
	
	pop {r4,r5,r6,r7,r8,lr}

	mov	pc,	lr			//return
	
//======================================================
//void redrawBlocks() 
//Checks for blocks that have been destroyed or modified and then redraws them
//Returns: void 
//======================================================
redrawBlocks:

	push {lr}
	
	//ldr r0, =cur_blocks 
	
	
	pop {lr}
	bx lr 

//===================================
// Draws a rectanlge
// Parameters:
//		r0 - x
//		r1 - y
//		r2 - color
//		r3 - width
//		r4 - height
//==================================	
drawRectangle:
	push {r7, r8, lr}
	mov r7, r0
	mov r6, r0
	mov r8, r1
	add r3, r7
	add r4, r8
rec_top:
	cmp r7, r3 		//once x == width
	bhs rec_next_line
	mov r0, r7
	mov r1, r8
	bl DrawPixel
	add r7, #1
	b rec_top
rec_next_line:
	cmp r8, r4
	pophi {r7, r8, pc}
	mov r7, r6
	add r8, #1
	b rec_top


//================================================
//ReplaceBlockBG(block_x, block_y, int bg_pointer, int replace_pointer)
//Replace a block from the background IN MEMORY
//r0: x coordinate of the block
//r1: y coordinate of the block 
//r2: pointer to the background 
//r3: pointer to replace the block with 
//Returns void
//================================================
ReplaceBlockBG:
	push {r4,r5,r6,r7,r8,r9,r10,lr}

	mov	r4,	r0					//Start X position of your picture (changes with each loop)
	mov	r5,	r1					//Start Y position of the picture  (changes with each loop)
	
	mov r10, r2					//Save pointer to the background in a safe location 
	
	ldmia r3, {r6, r7, r8}		//Load the address, width and height of the tile to put into the background 
	
	add r7, r4					//End x position of the picture 
	add	r8, r5					//End y position of the picture
	
	mov r9, r0					//Start X position (does not change)
RBBG_Loop:
	mov	r0,	r4					//passing x for ro which is used by the Draw pixel function 
	mov	r1,	r5					//passing y for r1 which is used by the Draw pixel formula 
	ldrh	r2,	[r6],#2			//setting pixel color by loading it from the data section. We load hald word
	mov r3, r10					//Pointer to the background
	
	bl	DrawPixelMemory
	add	r4,	#1					//increment x position
	cmp	r4,	r7					//compare with image with
	blt RBBG_Loop
	mov	r4,	r9					//reset x
	add	r5,	#1					//increment Y
	cmp	r5,	r8					//compare y with image height
	blt	RBBG_Loop
	
	pop    {r4,r5,r6,r7,r8,r9,r10,lr}
	bx lr 

DrawPixelMemory:
	push	{r4, lr}

	offset	.req	r4

	// offset = (y * 1024) + x = x + (y << 10)
	add		offset,	r0, r1, lsl #10
	// offset *= 2 (for 16 bits per pixel = 2 bytes per pixel)
	lsl		offset, #1

	// store the colour (half word) at framebuffer pointer + offset

	ldr	r0, [r3]
	strh	r2, [r0, offset]

	pop		{r4, lr}
	bx		lr



//================================================
//DrawBackground(tile array, background_addr, block_addr)
//A substitution function that reads the tile array, and then draws the appropriate block to the background.  
//r0: address of the tile array 
//r1: address of the the background to draw 
//r2: address of the blocks associated with the current background
//Returns: void  
//================================================
DrawBackground:

	push {r4, r5, r6, r7, r8, r9, r10, lr}

	mov r4, #0			//x index for tile array
	mov r5, #0			//y index for tile array
	mov r6, r0 			//tile array pointer 
	mov r8, r1			//background pointer 
	mov r9, r2			//block pointer 
	
	b DBG_loop_test_y
	
DBG_loop_y:

	mov r4, #0			//reset x index to start 
	b DBG_loop_test_x 	//check x 

DBG_loop_x:	

	//Get the offset in the tile array 
	mov r0, #32			
	mul r7, r5, r0
	add r7, r4 
	
	lsl r7, #2 
	
	//Read number from tile array
	ldr r3, [r6, r7]
	
	lsl r0, r4, #5		//Arg1: Every block is 32 pixels wide so shift 32 to get x location 
	lsl r1, r5, #5		//Arg2: Every block is 32 pixels high so shift 32 to get y location 
	
	//0: Sky block
	cmp r3, #0 
	beq DBG_sky
	
	//1: Ground block
	cmp r3, #1
	beq DBG_ground
	
	//2: Question box 
	cmp r3, #2
	beq DBG_qbox 
	
	//3: Wood box  
	cmp r3, #3
	beq DBG_wbox 
	
	//4: Stair box 
	cmp r3, #4
	beq DBG_sbox 
	
	//5: After question box 
	cmp r3, #5
	beq DBG_qbox_after
	
	//11: single pipe
	cmp r3, #11
	beq DBG_small_pipe
	
	//12: medium pipe
	cmp r3, #12
	beq DBG_medium_pipe
	
	//13: large pipe
	cmp r3, #13
	beq DBG_large_pipe
	
	//21: single cloud
	cmp r3, #21
	beq DBG_cloud_single
	
	//22: double cloud
	cmp r3, #22
	beq DBG_cloud_double
	
	//23: triple cloud 
	cmp r3, #23
	beq DBG_cloud_triple
	
	//31: castle
	cmp r3, #31
	beq DBG_castle
	
	//41: bush single
	cmp r3, #41
	beq DBG_bush_single
	
	//42: bush double 
	cmp r3, #42
	beq DBG_bush_double
	
	//43: bush triple
	cmp r3, #43
	beq DBG_bush_triple
	
	//51: mountain_small
	cmp r3, #51
	beq DBG_mountain_small
	
	//52: mountain_big 
	cmp r3, #52
	beq DBG_mountain_big
	
	b DBG_loop_x_end
	
DBG_sky:
	//Write a skyblock in memory 
	ldr r2, =sky_pic	//Arg4: pointer to picture to draw 
	bl drawPicture 
	
	b DBG_loop_x_end
	
DBG_ground:
	//Write a ground block in memory
	ldr r2, =ground_box_pic	//Arg4: pointer to picture to draw 
	bl drawPicture
	
	b DBG_loop_x_end
	
DBG_qbox:	
	ldr r2, =qbox_pic	//Arg4: pointer to picture to draw 
	bl drawPicture
	
	b DBG_loop_x_end

DBG_wbox:

	ldr r2, =wbox_pic
	bl drawPicture
	
	b DBG_loop_x_end
	
DBG_sbox:
	ldr r2, =sbox_pic
	bl drawPicture
	
	b DBG_loop_x_end
	
DBG_qbox_after:
	ldr r2, =qbox_after_pic
	bl drawPicture
	
	b DBG_loop_x_end

DBG_small_pipe:
	ldr r2, =pipe_small_pic
	bl drawPicture
	
	b DBG_loop_x_end

DBG_medium_pipe:
	ldr r2, =pipe_medium_pic
	bl drawPicture
	
	b DBG_loop_x_end

DBG_large_pipe:
	ldr r2, =pipe_large_pic
	bl drawPicture
	
	b DBG_loop_x_end

DBG_cloud_single:
	ldr r2, =cloud_single_pic
	bl drawPicture
	
	b DBG_loop_x_end

DBG_cloud_double:
	ldr r2, =cloud_double_pic
	bl drawPicture
	
	b DBG_loop_x_end

DBG_cloud_triple:
	ldr r2, =cloud_triple_pic
	bl drawPicture
	
	b DBG_loop_x_end
	
DBG_castle:
	ldr r2, =castle_pic
	bl drawPicture 
	
	b DBG_loop_x_end
	
DBG_bush_single:
	ldr r2, =bush_single_pic
	bl drawPicture 
	
	b DBG_loop_x_end
	
DBG_bush_double:
	ldr r2, =bush_double_pic
	bl drawPicture 
	
	b DBG_loop_x_end

DBG_bush_triple:
	ldr r2, =bush_triple_pic
	bl drawPicture 
	
	b DBG_loop_x_end
	
DBG_mountain_small:
	ldr r2, =mountain_small_pic
	bl drawPicture 
	
	b DBG_loop_x_end
	
DBG_mountain_big:
	ldr r2, =mountain_big_pic
	bl drawPicture
	
	b DBG_loop_x_end

DBG_loop_x_end:
	add r4, #1 
	
DBG_loop_test_x:

	cmp r4, #32 
	blt DBG_loop_x 
	add r5, #1 
	
DBG_loop_test_y:

	cmp r5, #24 
	blt DBG_loop_y 
	
	pop {r4, r5, r6, r7, r8, r9, r10, lr}
	bx lr 

//=====================================================================
//void ModifyLookup(int lookup_pointer, int x, int y, int new_value)
//modifity a value in the lookup data 
//r0: pointer to lookup 
//r1: x position
//r2: y position
//r3: new value to put in (x,y) in lookup table 
//=====================================================================
ModifyLookup:
	push {r4, r5, lr}
	
	//Get the offset in the tile array 
	mov r4, #32			
	mul r5, r2, r4
	add r5, r1 
	lsl r5, #2 
	
	str r3, [r0, r5]
	
ML_end:
	pop {r4, r5, lr}
	bx lr 

	



















