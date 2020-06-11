#author: Zbigniew Szymanski
#data : 2018.05.07
#description : example program for reading, modifying and writing a BMP file 
#-------------------------------------------------------------------------------

#only 24-bits 600x50 pixels BMP files are supported
.eqv BMP_FILE_SIZE 230454
.eqv BYTES_PER_ROW 960


	.data

.align 4
res:	.space 2
image:	.space BMP_FILE_SIZE

array1: .word 0:6
array2: .word 0:6

fname:		.asciiz "C:/Users/jakub/OneDrive/Pulpit/mips_project/s05-2.bmp"
newLine:	.asciiz "\n"
no_shape_msg: 	.asciiz "couldn't find any shape on image"
shape1_msg: 	.asciiz "shape1"
shape2_msg: 	.asciiz "shape2"
Err:		.asciiz "no file"

	.text
main:
	
	jal	read_bmp	
	
	li	$a0, 0		#x
	li	$a1, 0		#y
	li 	$a3, 4
	

frame_1:	

	
	beq	$a1, 240, frame_2 
	jal	get_pixel
	beq	$s0, 0, sub1
	
	addiu	$a1, $a1, 1
	j frame_1
	
	
sub1:
	sub $a3, $a3, 1
	
	
frame_2:

	li	$a0, 0		#x
	li	$a1, 0
frame2a:		#y
	beq	$a0,  320, frame_3 
	jal	get_pixel
	beq	$s0,0, sub2
	addiu 	$a0, $a0, 1
	
	
	j	 frame2a
	
sub2:
	sub 	$a3, $a3, 1	
	
	
	
frame_3:
	li	$a0, 0		#x
	li	$a1, 239	#y
frame3a: 
	beq	$a0,  319, frame_4
	jal	get_pixel
	beq	$s0, 0, sub3
	addi 	$a0, $a0, 1
	
	j frame3a
sub3:
	
	sub     $a3, $a3, 1
	
	
frame_4: #right
	li	$a0, 319		#x
	li	$a1, 0			#y
frame4a:
	beq	$a1, 240, count_sciany
	jal	get_pixel
	beqz	$s0, sub4
	addi 	$a1, $a1, 1
	
	j frame4a
sub4:
	
	sub $a3, $a3, 1
	
	
count_sciany:
	li	$a0, 0		#x
	li	$a1, 0		#y
traverse_horiz:
	beq	$a1, 240, count_sciany2
	beq	$a0, 319, go_next_row
	jal	get_pixel
	addiu 	$a0, $a0, 1
	jal	get_pixel_2
	
	beq	$s0, $s1, traverse_horiz
	li	$a2, 0
check_array1:
	beq	$a2, 13, traverse_horiz	
	la	$s2, array1        # put address of list into $s2
	move	$s3, $a2          # put the index into $s3
	add 	$s3, $s3, $s3   # double the index
	add 	$s3, $s3, $s3   # double the index again (now 4x)
	add 	$s4, $s3, $s2    # combine the two components of the address
	lw	$s5, 0($s4)     
	
	bne	$a0, $s5, if_zero #check if we already found that wall and can put it in the array
	j	traverse_horiz

if_zero:

	beqz	$s5, new_wall
	addiu	$a2, $a2, 1
	j	check_array1

new_wall:
	sw	$a0, 0($s4)
	add	$t8, $t8, 1
	j	traverse_horiz	
		


go_next_row:
	addiu 	$a1, $a1, 1 
	li	$a0, 0
	j	traverse_horiz
			
count_sciany2:	
	li	$a0, 0		#x
	li	$a1, 0		#y
traverse_vert:
	beq	$a0, 320, shape_rec
	beq	$a1, 239, go_next_column
	jal	get_pixel
	addiu 	$a1 $a1, 1
	jal	get_pixel_2
	
	beq	$s0, $s1, traverse_vert
	li	$a2, 0
check_array2:
	beq	$a2, 7, traverse_vert	
	la	$s2, array2        # put address of list into $s2
	move	$s3, $a2          # put the index into $s3
	add 	$s3, $s3, $s3   # double the index
	add 	$s3, $s3, $s3   # double the index again (now 4x)
	add 	$s4, $s3, $s2    # combine the two components of the address
	lw	$s5, 0($s4)     
	
	bne	$a1, $s5, if_zero2 #check if we already found that wall and can put it in the array
	j	traverse_vert

if_zero2:

	beqz	$s5, new_wall2
	addiu	$a2, $a2, 1
	j	check_array2

new_wall2:
	sw	$a1, 0($s4)
	add	$t9, $t9, 1
	j	traverse_vert	
		


go_next_column:
	addi 	$a0, $a0, 1 
	li	$a1, 0
	j	traverse_vert


shape_rec:
	add	$t9, $t9, $t8
	sub	$t9, $t9, $a3
	blez	$t9, no_shape	
	blt	$t9, 7, shape_2
	j	shape_1	
	
no_shape:
	li	$v0, 4					
	la	$a0, no_shape_msg				
	syscall
	j 	exit

shape_1:
	li	$v0, 4					
	la	$a0, shape1_msg				
	syscall	
	j	exit

shape_2:
	li	$v0, 4					
	la	$a0, shape2_msg				
	syscall
		
exit:	
	li 	$v0,10		#Terminate the program
	syscall
	
path_error:
	li	$v0, 4					
	la	$a0, Err			
	syscall	
	j	exit

# ============================================================================
read_bmp:

	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,4($sp)
	sub $sp, $sp, 4		#push $s1
	sw $s1, 4($sp)
#open file
	li $v0, 13
        la $a0, fname		#file name 
        li $a1, 0		#flags: 0-read file
        li $a2, 0		#mode: ignored
        syscall
	move $s1, $v0      # save the file descriptor
	
#check for errors - if the file was opened
	blez $s1, path_error

#read file
	li $v0, 14
	move $a0, $s1
	la $a1, image
	li $a2, BMP_FILE_SIZE
	syscall

#close file
	li $v0, 16
	move $a0, $s1
        syscall
	
	lw $s1, 4($sp)		#restore (pop) $s1
	add $sp, $sp, 4
	lw $ra, 4($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra

# ============================================================================

get_pixel:

	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,4($sp)

	la $t1, image + 10	#adress of file offset to pixel array
	lw $t2, ($t1)		#file offset to pixel array in $t2
	la $t1, image		#adress of bitmap
	add $t2, $t1, $t2	#adress of pixel array in $t2
	
	#pixel address calculation
	mul $t1, $a1, BYTES_PER_ROW #t1= y*BYTES_PER_ROW
	move $t3, $a0		
	#sll $a0, $a0, 1
	add $t3, $t3, $a0
	add $t3, $t3, $a0	#$t3= 3*x
	add $t1, $t1, $t3	#$t1 = 3x + y*BYTES_PER_ROW
	add $t2, $t2, $t1	#pixel address 
	
	#get color
	lbu $s0,($t2)		#load B
	lbu $t1,1($t2)		#load G
	sll $t1,$t1,8
	or $s0, $s0, $t1
	lbu $t1,2($t2)		#load R
        sll $t1,$t1,16
	or $s0, $s0, $t1
					
	lw $ra, 4($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra

# ============================================================================
get_pixel_2:


	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,4($sp)

	la $t1, image + 10	#adress of file offset to pixel array
	lw $t2, ($t1)		#file offset to pixel array in $t2
	la $t1, image		#adress of bitmap
	add $t2, $t1, $t2	#adress of pixel array in $t2
	
	#pixel address calculation
	mul $t1, $a1, BYTES_PER_ROW #t1= y*BYTES_PER_ROW
	move $t3, $a0		
	#sll $a0, $a0, 1
	add $t3, $t3, $a0
	add $t3, $t3, $a0	#$t3= 3*x
	add $t1, $t1, $t3	#$t1 = 3x + y*BYTES_PER_ROW
	add $t2, $t2, $t1	#pixel address 
	
	#get color
	lbu $s1,($t2)		#load B
	lbu $t1,1($t2)		#load G
	sll $t1,$t1,8
	or $s1, $s1, $t1
	lbu $t1,2($t2)		#load R
        sll $t1,$t1,16
	or $s1, $s1, $t1
					
	lw $ra, 4($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra

