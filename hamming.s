# This program will take a user input "32-bit" string, and compare it to 32
# 32-bit integers, printing the index of the array that is the closest match.
# A match is defined as having 7 or fewer bits of difference. If no match is
# found, this program will print "-1".

# Really liked programming this one, troubleshooting in MIPS can be a real
# challenge, and so I'm always way less daring than when working in high level
# languages. I ran into a problem where int_match wouldnt look past the first
# pattern - after putting in some debug code I realized that I only pushed $ra
# to the stack before calling int_compare, and my t registers were getting
# wiped out. Anyway, it was neat doing this in MIPS because I had to pay
# closer attention to the binary patterns than in C++. Really let me see how
# radically different the given patterns are from each other.

.text
main:	#introduce and get user input "32-bit" string
	li	$v0, 4		# code for print_string
	la	$a0, s_intro	# print intro
	syscall
	li	$v0, 8		#code for read_string
	la	$a0, user_pattern # read string into user_pattern
	li	$a1, 64		# space for the "32-bit" string, plus null term
	syscall
	
	# turn user input string into an integer	
	la	$a0, user_pattern 
	jal	str_to_int	# int str_to_int(user_pattern)
	move	$s0, $v0	# s0 = str_to_int(user_pattern)
	
	# pass user integer for comparison
	move	$a0, $s0	# load userint into arguments
	la	$a1, patterns	# load patterns[0] into arguments
	la	$s1, size_patterns
	lw	$a2, 0($s1)	# load size into argument
	jal	int_match	# int_match(userint, patterns[], size)

	# print index of closest match (or -1 if no match) and exit
	move	$a0, $v0	# a0 = int_match(u,p[],s)	
	li	$v0, 1		# code for print int
	syscall				
	jal	newline		# print newline
	li	$v0, 10		#code for exit
	syscall	

# function str_to_int, tested, working
# pre-cond: $a0 is the address of a length 32 string composed of 0s and 1s 
# postcond: $v0 is an an integer representation of the string in argument
# $t0 is the integer to be returned
# $t2 is the end of the string
# $t3 is used to hold the character for analysis
# $t4 = $a0, the base address of the string
str_to_int:
	li	$t0, 0		# t0 = 0
	move	$t4, $a0	# t4 = base address of string
	addi	$t2, $t4, 32	# t2 = the end of the 32char string	
sti_loop:
	lb	$t3, 0($t4)		# t3 = string[i]
	sll	$t0, $t0, 1		# shift t0 left by 1		
	andi	$t3, $t3, 1		# t3 = 1 if lsb t3 is 1, else 0
	beq	$t3, $0, sti_iszero	# if lsb is 0, go to iszero
	addi	$t0, $t0, 1		# t0 += 1		
sti_iszero:
	addi	$t4, $t4, 1		# increment by 1 character
	bne	$t2, $t4, sti_loop	# loop until final address of string 						# is reached
	move	$v0, $t0		# return t0	
	jr	$ra

# function int_match, tested, working
# calls function int_compare
# pre-cond: $a0 is an integer, $a1 is the address of an array of integers, $a2 # 	    is the size of the array.
# postcond: $v0 returns the index of the first member of the array where
#           int_compare returns <=7. if int_compare iterates through the whole
#	    array without returning <=7, then int_match returns -1
# $t0 = $a0, the integer to be matched
# $t1 = $a1, the address of the array
# $t2 = $a2, the size of the array
# $t3 is a loop iterator, also the current index of array[]
# $t4 = int_compare(a0,a1)
int_match:
	move	$t0, $a0	# t0 = a0, the integer to be matched
	move	$t1, $a1	# t1 = a1, the base address of the array
	move	$t2, $a2	# t2 = a2, the size of the array
	li	$t3, 0		# t3 = i = 0
	
im_loop:
	lw	$a0, 0($t1)	# a0 = array[i]
	move	$a1, $t0	# a1 = user integer		

	addi	$sp, $sp, -4	# make room on the stack
	sw	$ra, 0($sp)	# push $ra onto the stack
	addi	$sp, $sp, -4	# make room
	sw	$t0, 0($sp)	# push $t0
	addi	$sp, $sp, -4	# make room
	sw	$t1, 0($sp)	# push $t1
	addi	$sp, $sp, -4	# make room
	sw	$t2, 0($sp)	# push $t2
	addi	$sp, $sp, -4	# make room
	sw	$t3, 0($sp)	# push $t3

	jal	int_compare	# call int_compare(t0, array[i])
	move	$t4, $v0	# t4 = int_compare(t0, array[i])

	lw	$t3, 0($sp)	# pop $t3 from stack
	addi	$sp, $sp, 4	# shrink stack
	lw	$t2, 0($sp)	# pop $t2 from stack
	addi	$sp, $sp, 4	# shrink stack
	lw	$t1, 0($sp)	# pop $t1 from stack
	addi	$sp, $sp, 4	# shrink stack
	lw	$t0, 0($sp)	# pop $t0 from stack
	addi	$sp, $sp, 4	# shrink stack
	lw	$ra, 0($sp)	# pop $ra
	addi	$sp, $sp, 4	# shrink stack
	
	slti	$t4, $t4, 8		# if t4 <= 7, t4 = 1
	bne	$t4, $0, im_match	# if t4 <= 7, branch to im_match
	beq	$t3, $t2, im_nomatch	# if i = size, branch to im_nomatch
	addi	$t3, $t3, 1		# i++
	addi	$t1, $t1, 4		# array[i+1]
	j	im_loop

im_match:			# a match was found
	move	$v0, $t3	# return t3
	jr	$ra
im_nomatch:			# no match found
	li	$v0, -1		# return -1
	jr	$ra

# function int_compare, tested, working
# this function does a bit-by-bit comparison of two integers, and returns the
# number of bits that they differ by
# pre-cond: $a0 and $a1 are 32-bit integers
# postcond: $v0 returns the number of bits that $a0 and $a1 differ by, from
#	    0 to 31. 
# $t0 = $a0, then t0 is the xor of $t0 and $t1
# $t1 = $a1, then the number of differing bits between $a0 and $a1
# $t2 is the number of bits, or 32, and acts as a loop iterator
int_compare:
	move	$t0, $a0
	move	$t1, $a1
	xor	$t0, $t0, $t1	# t0 has as many 1s as diffs b/w t0 and t1
	li	$t1, 0		# t1 = 0
	li	$t2, 32		# t2 = 32, loop iterator
ic_loop:
	andi	$t4, $t0, 1		# t4 = 1 if lsb t0 = 1
	beq	$t4, $0, ic_iszero	# if lsb is 0, go to ic_iszero
	addi	$t1, $t1, 1		# if lsb is 1, t1++
ic_iszero:
	srl	$t0, $t0, 1		# srl t0 by 1 to advance lsb
	addi	$t2, $t2, -1		# t2--
	bne	$t2, $0, ic_loop 	# if t2!=0, continue loop	
	
	move	$v0, $t1		# return the number of differences
	jr	$ra	
	
# void function, prints a new line
newline:
	li	$v0, 4		# code for print string
	la	$a0, s_newline	# print a newline
	syscall
	jr $ra			#return to caller

.data
s_intro:	.asciiz "Enter your 32-bit pattern: \n"
s_newline:	.asciiz	"\n"
user_pattern:	.space	64		# string for the user pattern plus
					# null terminator. plenty of space here
size_patterns:	.word	32		# the size of the pattern array
patterns:	.word	0		# 32 element integer array
		.word	1431655765
		.word	858993459
		.word	1717986918
		.word	252645135
		.word	1515870810
		.word	1010580540
		.word	1768515945
		.word	16711935
		.word	1437226410
		.word	869020620
		.word	1721329305
		.word	267390960
		.word	1520786085
		.word	1019428035
		.word	1771465110
		.word	65535
		.word	1431677610
		.word	859032780
		.word	1718000025
		.word	252702960
		.word	1515890085
		.word	1010615235
		.word	1769576086
		.word	16776960
		.word	1437248085
		.word	869059635
		.word	1721342310
		.word	267448335
		.word	1520805210
		.word	1019462460
		.word	1771476585
