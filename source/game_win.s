.global CheckGameWin

//Check if mario has made it past the flag pole
//on the last screen
CheckGameWin:
	push {r4, r5, r6, lr}
	
	ldr r0, =cur_background_idx
	ldr r0, [r0]
	cmp r0, #7			//last screen
	bne end_check		//if not on last screen the return
	
	ldr r0, =mario_data
	ldmia r0, {r1, r2, r5, r6}		//get mario's current x and y and delta's
	
	
	ldr r3, =655			//flag x
	ldr r4, =328			//flag y			
	
	cmp r1, r3
	blo end_check				//if x is less than flag x
	
	cmp r2, r4					//if mario y is less than flags y
	sublo r6, r4, r2			//update delta y	
	movlo r2, r4				//teleport him to top of pole
	
	stmia r0, {r1, r2, r5, r6}			//store his x and y back and delta's
	bl moveThing				//draw mario
	
	pop {r4, r5, r6, lr}				//return the stuff on the stack
	b GameWinScreen
	
end_check:
	pop {r4, r5, r6, pc}
	
GameWinScreen:
	bl clearScreen		//clears the screem to black
	ldr r0, =400
	ldr r1, =346
	ldr r2, =game_win_pic
	bl drawPicture
	
	//Show the hud titles
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
	
	//The following functions only draw if score has changed
	bl renderScore
	bl renderCoinsCount
	bl renderLives
	
	b wait_button_press
	
//wait until a single button is pressed
//then reset game and go to main menu	
wait_button_press:
	bl ReadSNES			//returns in r0 the buttons pressed	
	ldr r1, =0xFFFF
	cmp r0, r1			//if equal then no button presed
	beq wait_button_press
	
	bl restart_game		//in restart.s
	
	b start_screen		//go back to beginning of the at the game menu
	
	
	
	