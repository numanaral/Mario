// Created by:
// Ahmet Numan Aral
// Anthony Tran
// Manjot Bal


.section    .init
.globl     _start
.global		start_screen

_start:
    b       main
    
.section .text


main:

	mov r0, #0xD3		//1101 0011b - Supervisor mode
	msr cpsr_c, r0		//set to irq so that it's lr is always used
	

   	bl 		InstallIntTable
    bl 		EnableC1IRQ
    
  //  mov sp, #0x8000
	bl		EnableJTAG

	bl		InitFrameBuffer
	bl		InitGPIOSNES
	
	bl		restart_dup_pic	

start_screen:
	bl 		clearScreen

	ldr r0, =210			// x location to draw start screen
	mov r1, #36				//y locatation to draw start screen
	ldr r2, =main_menu_pic
	bl drawPicture
	
	bl menu_select			//user selects either play or exit

play_game:
	bl RenderBackground

game_loop:
	bl update
	bl collision
	bl render
	
	b game_loop	

haltLoop$:
	b		haltLoop$

//==========================================
//void Update 
update:

	push {lr}

	bl CoinUpdate
	bl MarioUpdate
	bl MonsterUpdate
	
	bl CheckGameOver	//check if mario lost all his lives
	bl CheckGameWin		//check if mario made it to the end
	
	
	ldr r0, =spawn_value_pack
	ldr r0, [r0]
	cmp r0, #0
	bleq setValuePackPos
	
update_end:
	pop {lr}
	bx lr 
	
collision:
	push {lr}
	
	bl CollisionMarioBottom			//Handle bottom collisions
	bl CollisionMarioLeftRight		//Handle right left collisions 	
	bl CollisionMarioTop
	bl CollisionMonster				//Handle monster collisions 
	
	pop {lr}
	bx lr 

render: 
	push {lr}

	bl RenderBackground 

	ldr r0, =mario_data 
	bl moveThing 

	ldr r0, =mob1_data
	bl moveThing
	
	bl RenderCoin					//Render the coin if necessary 

	bl renderScore
	bl renderCoinsCount
	bl renderLives
	bl renderValuePack				//only renders once in the time interval
		
	pop {lr}
	bx lr 




