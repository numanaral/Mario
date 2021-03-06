.global restart_game
.global restart_dup_pic
.global restart_restore_pic

.section .text
//=========================================
//This function resets all the values of 
//every object in the game to their initial
//values
//==========================================
restart_game:
	push {lr}
	
	bl ValuePackOffScreen		//another value pack can be drawn
	
	bl restart_restore_pic
	
	pop {pc}

//=========================================
//restart_dup_pic
//This function duplicates the original picture.s file into a template
//so that when the game restarts, we can reinitialize the picture.s file 
//to it's original state 
//==========================================
restart_dup_pic:
	push {lr}

	ldr r0, =pic_dup_start  //Address to start duplication
	ldr r1, =pic_dup_end 	//Address to end duplication
	ldr r2, =pic_template	//Address to store the duplicate 
	
rdp_loop:

	ldr r3, [r0], #4
	str r3, [r2], #4 
	cmp r0, r1 				//Have we reached pic_dup_end? 
	ble rdp_loop			//If not, duplicate the next value 
test2:	
	pop {lr}
	bx lr 
	
//=========================================
//restaurt_dup_pic
//This function restores the original picture.s file using the template generated by restart_dup_pic  
//==========================================
restart_restore_pic:
	push {lr}
	
	ldr r0, =pic_dup_start  //Address to start duplication
	ldr r1, =pic_dup_end 	//Address to end duplication
	ldr r2, =pic_template	//Address to store the duplicate 
	
rrp_loop:

	ldr r3, [r2], #4
	str r3, [r0], #4 
	cmp r0, r1 				//Have we reached pic_dup_end? 
	ble rrp_loop			//If not, restore the next value 
	
	pop {lr}
	bx lr 
	
	