.global menu_select

.section .text
menu_select:
	push {r4, r5, lr}
	mov r5, #0				//r5 stores which selection the player made
							//0 means have selctor on play button, 1 mean exit
	
menu_select_loop:
	mov r0, r5
	bl draw_menu_selector
	
	bl ReadSNES				//returns in r0 the buttons that are pressed
	
// Check if A is pressed
	tst r0, #0x100			//0001 0000 0000b A button has been pressed? 
	cmpeq r5, #0			//if current selection is play
	beq end_menu_select		//then return
	
	tst r0, #0x100			//check again if A was pressed
	cmpeq r5, #1			//check if current selection is exit
	beq exit_game				//r5 must contain 1 so exit
	
	tst r0, #0x10			//0001 0000b D-PAD UP pressed?
	moveq r5, #0			//move selector to play
	
	tst r0, #0x20			//0010 000b D-PAD DOWN pressed?
	moveq r5, #1			//move selector to exit
	
	b menu_select_loop

end_menu_select:
	pop {r4, r5, pc}
	
	
	
//=================================================
//Parameters:
//	r0 - If r0 is 0 then draw menu selector at play
//		 if r0 is 1 then draw menu selctor at exit
//==========	===================================
draw_menu_selector:
	push {r4, lr}
	
	ldr r2, =menu_selector_pic		//the data structure for the menu selector

draw_on_exit:
	cmp r0, #1						//if exit button selected
	bne draw_on_play				//if not selected then draw on play
	ldr r4, =exit_option
	ldr r0, [r4]					// x position of where to draw selector
	ldr r1, [r4, #4] 				// y position of where to draw selector
	bl drawPicture
	
	//Draw background over the play button selector
	ldr r4, =play_option
	ldr r0, [r4]					//x pos
	ldr r1, [r4, #4]				//y pos
	ldr r2, =bg_colour
	ldrh r2, [r2]					//background colour
	ldr r3, =27						//width
	ldr r4, =26						//height
	bl drawRectangle
	
	b end_draw_menu_selector
	
draw_on_play:
	ldr r4, =play_option			//if r3 != 1 draw the selector at the play button
	ldr r0, [r4]
	ldr r1, [r4, #4]
	bl drawPicture
	
	//Draw background over the exit button selector
	ldr r4, =exit_option
	ldr r0, [r4]					//x pos
	ldr r1, [r4, #4]				//y pos
	ldr r2, =bg_colour
	ldrh r2, [r2]					//background colour
	ldr r3, =27						//width
	ldr r4, =26						//height
	bl drawRectangle
	
end_draw_menu_selector:
	pop {r4, pc}
	
//=============================================
// This function draws the exit screen and then
// goes to a halt loop
//==============================================
exit_game:
	bl clearScreen					//clears the screen to black
	ldr r0, =262						// x pos 
	ldr r1, =359						// y pos
	ldr r2, =exit_screen_pic
	bl drawPicture
	b haltLoop$
haltLoop$:
	b haltLoop$
	
	
.section .data
.align 4
bg_colour:		.ascii "?l"			//background color sky blue
.align 4

play_option:	.int 385, 420		//x and y location of play button
exit_option:	.int 385, 480		//x and y location of exit button

