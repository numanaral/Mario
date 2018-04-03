.global CheckGameOver

//No need to return from here because one this
//is reached it should automatically bring player
//back to main menu
GameOverScreen:	
	bl clearScreen		//clears the screem to black
	ldr r0, =400
	ldr r1, =346
	ldr r2, =game_over_pic
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
	
//check if mario's lives are 0. If so then game over	
CheckGameOver:
	push {lr}
		
	ldr r0, =lives
	ldr r0, [r0]
	cmp r0, #0
	pople {lr}			//remove lr from stack because we won't be returning
	ble GameOverScreen	
	
	pop {pc}