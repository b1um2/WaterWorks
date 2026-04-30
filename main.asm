.data
display: .space 524288
full_img_buff: .space 524288
level_data_buff: .space 8000

level1_img_path: .asciiz "D:/Downloads/AssemblyMARS/WaterWorks/level1.bin"
level1_data_path: .asciiz "D:/Downloads/AssemblyMARS/WaterWorks/level1_data.bin"

level2_img_path: .asciiz "D:/Downloads/AssemblyMARS/WaterWorks/level2.bin"
level2_data_path: .asciiz "D:/Downloads/AssemblyMARS/WaterWorks/level2_data.bin"

level3_img_path: .asciiz "D:/Downloads/AssemblyMARS/WaterWorks/level3.bin"
level3_data_path: .asciiz "D:/Downloads/AssemblyMARS/WaterWorks/level3_data.bin"

menu_img_path: .asciiz "D:/Downloads/AssemblyMARS/WaterWorks/menu.bin"
level_select_img_path: .asciiz "D:/Downloads/AssemblyMARS/WaterWorks/levelSelect.bin"
credits_img_path: .asciiz "D:/Downloads/AssemblyMARS/WaterWorks/credits.bin"
goodbye_img_path: .asciiz "D:/Downloads/AssemblyMARS/WaterWorks/goodbye.bin"

win_img_path: .asciiz "D:/Downloads/AssemblyMARS/WaterWorks/win.bin"
loss_img_path: .asciiz "D:/Downloads/AssemblyMARS/WaterWorks/loss.bin"

water_tint: .word 255
water_delay: .word 35

.text
.globl main
main:
	jal load_assets #initialise assets
	jal enter_menu_context #start game with the menu screen

	game_loop:
		lw $t0, 0xffff0000
		addi $t0, $t0, -1
		beq $t0, $0, input_given

		j game_loop

		input_given:
			lw $a0, 0xffff0004
			#jal play_click_sound
			#li $v0, 1
			#syscall
			jr $s0

	exit:
		la $a0, goodbye_img_path
		la $a1, full_img_buff
		jal load_image

		la $a0, full_img_buff
		la $a1, display
		li $a2, 524288
		jal copy_buffer
		
		li $v0, 10
		syscall

# READ:
# signatures of functions in this code should be read as follows:
# f(a, b, c, d) -> e correspond to putting the values in
# a = $a0, b = $a1, c = $a2, d = $a3
# e is the return value and it is returned in $v0

load_assets:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

menu_context_action: #ONLY CALL FROM INPUT LOOP
	beq $a0, 49, menu_context_equal_1
	beq $a0, 50, menu_context_equal_2
	beq $a0, 51, menu_context_equal_3
	
	menu_context_break:
		j game_loop
	menu_context_equal_1: 
		jal enter_level_select_context
		j menu_context_break
	menu_context_equal_2: 
		jal enter_credits_context
		j menu_context_break
	menu_context_equal_3:
		jal exit
		j menu_context_break
	
level_select_context_action: #ONLY CALL FROM INPUT LOOP
	beq $a0, 48, level_select_context_equal_0
	beq $a0, 49, level_select_context_equal_1
	beq $a0, 50, level_select_context_equal_2
	beq $a0, 51, level_select_context_equal_3
	
	level_select_context_break:
		j game_loop
	level_select_context_equal_0:
		jal enter_menu_context
		j level_select_context_break
	level_select_context_equal_1:
		la $a0, level1_img_path
		la $a1, level1_data_path
		jal enter_level_context
		j level_select_context_break
	level_select_context_equal_2:
		la $a0, level2_img_path
		la $a1, level2_data_path
		jal enter_level_context
		j level_select_context_break
	level_select_context_equal_3:
		la $a0, level3_img_path
		la $a1, level3_data_path
		jal enter_level_context
		j level_select_context_break
	
credits_context_action: #ONLY CALL FROM INPUT LOOP
	beq $a0, 48, credits_context_equal_0
	
	credits_context_break:
		j game_loop
	credits_context_equal_0:
		jal enter_menu_context
		j level_select_context_break
		
end_screen_context_action: #ONLY CALL FROM INPUT LOOP
	jal enter_level_select_context
	j game_loop

level_context_action: #ONLY CALL FROM INPUT LOOP
	addi $a0, $a0, -49
	bltz $a0, level_context_break
	
	la $t0, level_data_buff
	lw $t1, 0($t0) #pipe count
	
	bgt $a0, $t1, level_context_break #dont do anything if input > pipecount
	
	addi $t0, $t0, 16 #start of pipe data
	li $t2, 32
	mul $t2, $a0, $t2 
	add $t2, $t2, $t0 #t2 has start of THIS pipe's data
	
	lw $t3, 20($t2)
	bne $t3, $0, level_context_break
	
	lw $t3, 16($t2)
	add $s4, $t3, $s4 #add to current level water count
	
	lw $s3, 28($t2)
	
	lw $a0, 8($t2) #x pos of tank
	lw $a1, 12($t2) #y pos of tank
	jal drain_water
	
	beq $s3, 1, level_over
	
	level_context_break:
		j game_loop
		
	level_over:
		beq $s7, $s4, good_fill
		blt $s7, $s4, overfill
		j underfill
		
		good_fill:
		move $a0, $s5
		move $a1, $s6
		li $a2, 0
		jal fill_main_tank
		
		j end_screen_jumper
		
		overfill:
		move $a0, $s5
		move $a1, $s6
		li $a2, 16
		jal fill_main_tank
		j end_screen_jumper
		
		underfill:
		move $a0, $s5
		move $a1, $s6
		li $a2, -16
		jal fill_main_tank

		j end_screen_jumper
		
		end_screen_jumper:
		move $a0, $s4
		move $a1, $s7
		jal enter_end_screen_context
		
		j game_loop

enter_end_screen_context:
	addi $sp, $sp, -16
	sw $a0, 0($sp)
	sw $a1, 4($sp)
	sw $a2, 8($sp)
	sw $ra, 12($sp)
	
	beq $a0, $a1, win_screen_loader
	j loss_screen_loader
	
	win_screen_loader:
	la $a0, win_img_path
	la $a1, full_img_buff
	jal load_image
	jal play_win_sound
	j display_copy_end_screen
	
	loss_screen_loader:
	la $a0, loss_img_path
	la $a1, full_img_buff
	jal load_image
	jal play_lose_sound
	j display_copy_end_screen
	
	display_copy_end_screen:
	la $a0, full_img_buff
	la $a1, display
	li $a2, 524288
	jal copy_buffer

	la $s0, end_screen_context_action #the function that the input loop will jump to
	
	lw $ra, 12($sp)
	lw $a2, 8($sp)
	lw $a1, 4($sp)
	lw $a0, 0($sp)
	addi $sp, $sp, 16
	
	jr $ra

enter_level_context: #signature: f(level_image_path, level_data_path)
	addi $sp, $sp, -16
	sw $a0, 0($sp)
	sw $a1, 4($sp)
	sw $a2, 8($sp)
	sw $ra, 12($sp)

	la $a1, full_img_buff
	jal load_image

	la $a0, full_img_buff
	la $a1, display
	li $a2, 524288
	jal copy_buffer
	
	lw $a0, 4($sp)
	jal load_level_data
	
	la $s0, level_data_buff
	lw $s1, 0($s0) #valve count
	lw $s7, 4($s0) #initialise water needed to 0
	lw $s4, 8($s0) #x and y values of the main valve
	lw $s5, 12($s0)
	
	addi $s0, $s0, 16 #start of valve data
	
	
	
	level_loader_loop:
		beq $s1, 0, level_loaded
		addi $s1, $s1, -1
		li $t2, 32
		mul $t2, $t2, $s1
		add $t2, $s0, $t2 #get adrs of pipe data for specific valve
		
		#lw $t3, 16($t2) #get water in valve
		#add $s7, $s7, $t3 #and add it to the target water value
		
		lw $a0, 8($t2) #load x and y coords of tank tile
		lw $a1, 12($t2)
		jal fill_water
		
		j level_loader_loop
	level_loaded:
	
	la $s0, level_context_action #the function that the input loop will jump to
	li $s4, 0 #used to count water from valves
	
	lw $ra, 12($sp)
	lw $a2, 8($sp)
	lw $a1, 4($sp)
	lw $a0, 0($sp)
	addi $sp, $sp, 16
	
	jr $ra	

enter_menu_context: #signature: f()
	addi $sp, $sp, -16
	sw $a0, 0($sp)
	sw $a1, 4($sp)
	sw $a2, 8($sp)
	sw $ra, 12($sp)

	la $a0, menu_img_path
	la $a1, full_img_buff
	jal load_image

	la $a0, full_img_buff
	la $a1, display
	li $a2, 524288
	jal copy_buffer

	la $s0, menu_context_action #the function that the input loop will jump to
	
	lw $ra, 12($sp)
	lw $a2, 8($sp)
	lw $a1, 4($sp)
	lw $a0, 0($sp)
	addi $sp, $sp, 16
	
	jr $ra
	
enter_level_select_context: #signature: f()
	addi $sp, $sp, -16
	sw $a0, 0($sp)
	sw $a1, 4($sp)
	sw $a2, 8($sp)
	sw $ra, 12($sp)
	
	la $a0, level_select_img_path
	la $a1, full_img_buff
	jal load_image

	la $a0, full_img_buff
	la $a1, display
	li $a2, 524288
	jal copy_buffer
	
	la $s0, level_select_context_action #the function that the input loop will jump to
	
	lw $ra, 12($sp)
	lw $a2, 8($sp)
	lw $a1, 4($sp)
	lw $a0, 0($sp)
	addi $sp, $sp, 16
	
	jr $ra
	
enter_credits_context: #use to switch contexts
	addi $sp, $sp, -16
	sw $a0, 0($sp)
	sw $a1, 4($sp)
	sw $a2, 8($sp)
	sw $ra, 12($sp)
	
	la $a0, credits_img_path
	la $a1, full_img_buff
	jal load_image

	la $a0, full_img_buff
	la $a1, display
	li $a2, 524288
	jal copy_buffer
	
	la $s0, credits_context_action #the function that the input loop will jump to
	
	lw $ra, 12($sp)
	lw $a2, 8($sp)
	lw $a1, 4($sp)
	lw $a0, 0($sp)
	addi $sp, $sp, 16
	
	jr $ra
	
drain_water:
    	li $t0, 32
    	addi $a0, $a0, -1
    	mul $t0, $t0, $a0 #top right X coord of tile
    
    	li $t1, 32
    	addi $a1, $a1, -1
    	mul $t1, $t1, $a1 #top right Y coord of tile
    	li $t7, 32
    
    	drain_water_loop_y:
        	blez $t7, drain_water_loop_y_end
        
        	li $t2, 32 #to decrement in the x loop
        
        	la $t3, display #base + y*screenWidth*4 + xCoord*4
        	mul $t4, $t1, 512
        	add $t4, $t4, $t0
        	mul $t4, $t4, 4
        	add $t3, $t3, $t4
        
        	drain_water_loop_x:
            		addi $t3, $t3, 4
            		blez $t2, drain_water_loop_x_end
            
            		lw $t4, 0($t3) 
            
            		srl $t5, $t4, 24 #return the old value of the pixels here
            		andi $t4, $t4, 0xffffff00 #it got stored in the alpha channel when it was tinted
            		or $t4, $t4, $t5
            
            		sw $t4, 0($t3)

            		addi $t2, $t2, -1
            		j drain_water_loop_x
            
        	drain_water_loop_x_end:
            		li $v0, 32 #wait water_delay seconds to make water appear slowly
            		lw $a0, water_delay
            		syscall
            
            		addi $t1, $t1, 1
            		addi $t7, $t7, -1
            		j drain_water_loop_y
            
    	drain_water_loop_y_end:
        	jr $ra

fill_main_tank: #signature: f(tileX, tileY, extra) for a 32x32 px tile
	addi $a0, $a0, 8
	addi $a1, $a1, 4

	li $t0, 32
	mul $t0, $t0, $a0 #bottom right X coord of tile
	
	li $t1, 32
	mul $t1, $t1, $a1 #bottom right Y coord of tile
	
	li $t9, 64
	add $t9, $a2, $t9
	
	fill_main_tank_loop_y:
		blez $t9, fill_main_tank_loop_y_end
		
		li $t2, 64 #to decrement in the x loop
		
		la $t3, display #base + y*screenWidth*4 + xCoord*4
		mul $t4, $t1, 512
		add $t4, $t4, $t0
		mul $t4, $t4, 4
		add $t3, $t3, $t4
		
		fill_main_tank_loop_x:
			blez $t2, fill_main_tank_loop_x_end
			
			lw $t4, 0($t3) #slightly make pixels more blue in the next part here
			andi $t5, $t4, 0xff
			
			sll $t8, $t5, 24 #set the alpha bits to the value of the blue bits
			or $t4, $t4, $t8
			andi $t4, $t4, 0xffffff00
			
			lw $t6, water_tint
			add $t5, $t5, $t6 #tint by adding tint value to blue bits
			blt $t5, 0xff, blue_not_overloaded2 #next few lines check if the blue value is now greater than 255
			li $t5, 0xff
			
			blue_not_overloaded2:
			or $t4, $t4, $t5
			sw $t4, 0($t3)
			
			addi $t2, $t2, -1
			addi $t3, $t3, -4
			
			j fill_main_tank_loop_x
			
		fill_main_tank_loop_x_end:
			addi $t1, $t1, -1
			addi $t9, $t9, -1
			li $v0, 32 #wait water_delay seconds to make water appear slowly
			lw $a0, water_delay
			syscall
			
			j fill_main_tank_loop_y
			
	fill_main_tank_loop_y_end:
		jr $ra

fill_water: #signature: f(tileX, tileY) for a 32x32 px tile
	li $t0, 32
	mul $t0, $t0, $a0 #bottom right X coord of tile
	
	li $t1, 32
	mul $t1, $t1, $a1 #bottom right Y coord of tile
	
	li $t9, 32
	fill_water_loop_y:
		blez $t9, fill_water_loop_y_end
		
		li $t2, 32 #to decrement in the x loop
		
		la $t3, display #base + y*screenWidth*4 + xCoord*4
		mul $t4, $t1, 512
		add $t4, $t4, $t0
		mul $t4, $t4, 4
		add $t3, $t3, $t4
		
		fill_water_loop_x:
			blez $t2, fill_water_loop_x_end
			
			lw $t4, 0($t3) #slightly make pixels more blue in the next part here
			andi $t5, $t4, 0xff
			
			sll $t8, $t5, 24 #set the alpha bits to the value of the blue bits
			or $t4, $t4, $t8
			andi $t4, $t4, 0xffffff00
			
			lw $t6, water_tint
			add $t5, $t5, $t6 #tint by adding tint value to blue bits
			blt $t5, 0xff, blue_not_overloaded #next few lines check if the blue value is now greater than 255
			li $t5, 0xff
			
			blue_not_overloaded:
			or $t4, $t4, $t5
			sw $t4, 0($t3)
			
			addi $t2, $t2, -1
			addi $t3, $t3, -4
			
			j fill_water_loop_x
			
		fill_water_loop_x_end:
			addi $t1, $t1, -1
			addi $t9, $t9, -1
			li $v0, 32 #wait water_delay seconds to make water appear slowly
			lw $a0, water_delay
			syscall
			
			j fill_water_loop_y
			
	fill_water_loop_y_end:
		jr $ra

copy_buffer: # signature: f(source_addr, dest_addr, num_bytes)
    	add $t0, $a0, $a2	# calculate the end address ($t0 = source start + size)
    
	copy_loop:
		bge $a0, $t0, copy_done	# if current source pointer >= end address, exit
		
		lw  $t1, 0($a0)		# load 1 word (4 bytes) from source
		sw  $t1, 0($a1)		# store that word into destination
		
		addi $a0, $a0, 4	# increment source pointer by 4 bytes
		addi $a1, $a1, 4	# increment destination pointer by 4 bytes
		
		j copy_loop		# repeat for next pixel

	copy_done:
		jr $ra
		
load_level_data:      
	li   $v0, 13		# open file
	li   $a1, 0		# 0 for read
	li   $a2, 0		# ignored as stated in the mips syscall sheet
	syscall
	move $s6, $v0		# save file descriptor

	li   $v0, 14		# read file
	move $a0, $s6		# input from previous syscall (the file descriptor)
    
		
	la $a1, level_data_buff # restore the buffer address into $a1 
    
	li   $a2, 8000		# max read
	syscall

	li   $v0, 16		# close file
	move $a0, $s6		# file descriptor to close
	syscall
    
	jr $ra

load_image: #signature: f(path, buffer)
	move $t9, $a1       
    
	li   $v0, 13		# open file
	li   $a1, 0		# 0 for read
	li   $a2, 0		# ignored as stated in the mips syscall sheet
	syscall
	move $s6, $v0		# save file descriptor

	li   $v0, 14		# read file
	move $a0, $s6		# input from previous syscall (the file descriptor)
    
		
	move $a1, $t9 		# restore the buffer address into $a1 
    
	li   $a2, 524288	# max read
	syscall

	li   $v0, 16		# close file
	move $a0, $s6		# file descriptor to close
	syscall
    
	jr $ra
	
# --- Win Sound ---
# Plays a rising C-Major arpeggio (C4, E4, G4, C5)
play_win_sound:
    li $v0, 33          # Syscall 33: MIDI out synchronous
    li $a1, 500         # Duration in milliseconds
    li $a2, 0           # Instrument (0 = Piano)
    li $a3, 100         # Volume (0-127)

    li $a0, 60          # Pitch C4
    syscall
    li $a0, 64          # Pitch E4
    syscall
    li $a0, 67          # Pitch G4
    syscall
    li $a0, 72          # Pitch C5
    syscall
    jr $ra

# --- Lose Sound ---
# Plays a dissonant, descending "wa-wa-waaa" (D#4, D4, C#4)
play_lose_sound:
    li $v0, 33          # Syscall 33: MIDI out synchronous
    li $a1, 600         # Duration in milliseconds
    li $a2, 0           # Instrument (0 = Piano)
    li $a3, 100         # Volume (0-127)

    li $a0, 63          # Pitch Eb4
    syscall
    li $a0, 62          # Pitch D4
    syscall
    li $a1, 1000        # Make the last note longer
    li $a0, 61          # Pitch Db4
    syscall
    jr $ra
    
play_click_sound:
    li $v0, 31          # Syscall 31: MIDI out (asynchronous - doesn't pause code)
    li $a0, 75          # Pitch (High D#)
    li $a1, 50          # Duration (50ms - very short)
    li $a2, 115         # Instrument (115 = Woodblock/Percussive)
    li $a3, 127         # Volume (Max)
    syscall
    jr $ra