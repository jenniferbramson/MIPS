# Jennifer Bramson
# jib41@pitt.edu

.data
	endMsg:		.asciiz	"The game score is "
	divider:	.asciiz	" : "
	newLine:	.asciiz	"\n"
	error:		.asciiz	"\nSorry, queue overflow occurred. Please try again.\n"

.text

# $s0 = x of player
# $s1 = y of player
# $s2 = pointer to 4 before the first item in the queue
# $s3 = pointer to the last item in the queue
# $s4 = original time stamp
# $s5 = 100s to compare against
# $s6 = number of bugs hit
# $s7 = number of shots made

poll:	la	$v0,0xffff0000		# address for reading key press status
	lw	$t0,0($v0)		# read the key press status
	andi	$t0,$t0,1
	beq	$t0,$0,_timeCheck	# no key pressed
	lw	$t0,4($v0)		# read key value
upkey:	addi	$v0, $t0, -224		# check for up key press
	bne	$v0, $0, dkey		# wasn't right key, so check for down key
	addi	$s7, $s7, 1		# tally up a shot made in $s7
	move	$a0, $s0		# x of new shot = the same as the player's
	li	$a1, 60			# y of new shot = one above the player
	li	$a2, 1			# color = red
	jal	_setLED
	li	$a2, 1
	li	$a3, 0			# $a3 = radius - no idea what this is yet
	jal	_insert_q		# add shot to queue
	j	_timeCheck
dkey:	addi	$v0, $t0, -225		# check for down key press
	bne	$v0, $0, lkey		# wasn't down key, so try left key
	j	endGame			# go end the game and give score
lkey:	addi	$v0,$t0,-226		# check for left key press
	bne	$v0,$0,rkey		# wasn't left key, so try right key
	# turn off the player point at the current location
	li	$a2, 0			# change color to 'off'
	move	$a0, $s0
	move	$a1, $s1
	jal	_setLED
	# turn on a light at the new (+1 to the left) player point
	li	$a2, 2			# change color to orange
	subi	$s0, $s0, 1		# decrement x-value
	andi	$s0, $s0, 63		# mask the high bits of the x-value to make sure the value is not too high
	move	$a0, $s0
	jal	_setLED
	j	_timeCheck
rkey:	addi	$v0,$t0,-227		# check for right key press
	bne	$v0,$0,bkey		# wasn't right key, so check for center key
	# turn off the player point at the current location
	li	$a2, 0			# change color to 'off'
	move	$a0, $s0
	move	$a1, $s1
	jal	_setLED
	# turn on a light at the new (+1 to the right) player point
	li	$a2, 2			# change color to orange
	addi	$s0, $s0, 1		# increment x-value
	andi	$s0, $s0, 63		# mask the high bits of the x-value to make sure the vlaue is not too high
	move	$a0, $s0
	jal	_setLED
	j	_timeCheck
bkey:	addi	$v0,$t0,-66		# check for center key press
	bne	$v0,$0,_timeCheck	# invalid key, ignore it
	# initialize person in the middle of the bottom row
	li	$a2, 2			# set color to orange
	li	$s0, 32			# set x to the middle column
	li	$s1, 63			# set y to the bottom row
	move	$a0, $s0
	move	$a1, $s1
	jal	_setLED
	# queue:
	# queue size = 2^9. 512>>2 = 128, so the queue can potentially hold up to 128 items (I'll leave last blank to prevent
	# ambiguity between a full queue and empty qeueue)
	# starting at 10020000 allows .data to be at 10010000 and the LED take up FFFF0000-FFFFFFFF
	la	$s2,0x10020000 		# base address of queue (pointer to 4 before first item in queue - makes counting easier)
	move	$s3, $s2		# copy 	base address (pointer to last item in queue)
	li	$t9, 4000		# for bug adding timing
	move	$t8, $t9		# for first bug time test
	li	$s5, 100
	# start game
	li	$v0, 30			# to get original time stamp
	syscall
	move	$s4, $a0		# save original time stamp in $s4
	# checks to see if 100 ms have passed to move the items in the queue
	# checks to see if 2 minutes haves passed to end the game
	# trashes $t0-$t2, $t4. $t5, $t8-$t9
	# uses $s4 (original time stamp), $s5 (total number of milliseconds that have passed), no returns
_timeCheck:
	beq	$s4, 0, poll	# if $s4 = 0, then center key hasn't been pressed yet to start game
	li	$v0, 30		# to get time stamp
	syscall
	sub	$t0, $a0, $s4		# time that has passed since the last time stamp
	lui	$t1, 0x0001		# upper part of 120000 (2 minutes) in base 16
	ori	$t1, $t1, 0xD4C0	# lower part of 120000 in base 16
	slt	$t2, $t0, $t1		# if $t0 = 1, less than two minutes have passed
	beq	$t2, $0, endGame	# if two minutes have passed, end the game
	slt	$t1, $t0, $s5		# $t1 = 1 if 100 ms haven't passed
	beq	$t1, 1, poll
	addi	$s5, $s5, 100		# add for next time measure
	jal	_itemLoop
	slt	$t1, $t0, $t8		# $t1 = 1 if less than x (variable) ms have passed (still using updated time from _timeCheck)
	beq	$t1, 1, poll		# if not enough time has passed, skip back to poll
	add	$t8, $t8, $t9		# add variable x to time measure
	addi	$t9, $t9, -55		# this increases the difficulty over time
	# adds new bugs
	# uses $s5 (total ms passed)
	# trashes $t0-$t4, $t8
_addBugs:
	add	$t4, $zero, $zero
	li	$a1, 2			# upper range of x-value (between 0 and 1)
	li	$v0, 42
	syscall
	addi	$t5, $a0, 3		# this randomizes whether it adds 3 or 4 buggs
	addBugLoop:
		beq	$t4, $t5, poll
		addi	$t4, $t4, 1		# increment loop index
		li	$a1, 64			# upper range of x-value (0<=x<64)
		li	$v0, 42
		syscall
		# x-value now in $a0
		li	$a1, 0			# y of spider = top of page
		li	$a2, 3			# color = green
		jal	_setLED
		jal	_insert_q
		j	addBugLoop

	# loops through the items in the queue
	# trashes $t4-$t6
	# calls _setLED and _getLED which trashes $t0-$t3 while iterating through the loop
_itemLoop:
	subi	$sp, $sp, 16
	sw	$ra, ($sp)	# save return address, otherwise it will be overwritten by _setLED, _getLED, etc.
	sw	$t8, 4($sp)	# save data for adding bugs
	sw	$t9, 8($sp)	# save data for adding bugs
	sw	$t0, 12($sp)	# time passed since last time stamp
	jal	_size_q		# get the logical size of the loop
	move	$t4, $v0	# logical size in $t4
	add	$t5, $0, $0	# zero out $t1, it will be the loop index
	itemLooping:
		beq	$t5, $t4, endItemLoop	# end the loop when reach the end of the logical list
		addi	$t5, $t5, 1	# incremenet loop index
		jal	_remove_q
		move	$t6, $v0	# save item that was removed in $t6
		andi	$a2, $t6, 0xFF	# load byte containing the event type
		srl	$t6, $t6, 8	# to get x-value
		andi	$a0, $t6, 0xFF	# load byte containing the x-value
		srl	$t6, $t6, 8	# to get y-value
		andi	$a1, $t6, 0xFF	# load byte containing the y-value
		beq	$a2, 1, shotsFired	# 1 = shot	(easy to remember because red = 1)
		beq	$a2, 3, bugsCrawling	# 3 = bug	(easy to remember because green = 3)
		slti	$t0, $a2, 4		# if the item type is greater than 4, $t0 = 0 and it is a wave part
		beq	$t0, $0, waveMoving
		j	itemLooping
	endItemLoop:
		lw	$ra, ($sp)	# saved data for adding bugs
		lw	$t8, 4($sp)	# saved data for adding bugs
		lw	$t9, 8($sp)	# saved data for adding bugs
		lw	$t0, 12($sp)	# time passed since last time stamp
		addi	$sp, $sp, 8
		jr	$ra
	# moves the shots that were fired up a y-value and removes them when necessary
	shotsFired:
		jal	_getLED		# see what color the LED in the current spot is
		li	$a2, 0
		jal	_setLED		# turn off the light at current location
		beq	$a1, $0, itemLooping	# shot is at top of window, so delete shot by not re-adding it to queue
		beq	$v0, 3, newWave	# if the current spot is green, bullet hit a bug, so make a wave
		beq	$v0, 0, itemLooping	# bullet no longer exists, so don't readd to queue, just return to itemLooping
		addi	$a1, $a1, -1	# moves light up a y-value
		li	$a2, 1
		jal	_setLED		# turn on new light
		jal	_insert_q	# add to the queue
		j	itemLooping	# continue to loop
	# moves bugs down a y-value and removes them when necessary
	bugsCrawling:
		jal	_getLED		# see what color the LED in the current spot is
		li	$a2, 0
		jal	_setLED		# turn off the light at current location
		beq	$a1, 62, itemLooping	# remove item from queue when one above player
		beq	$v0, 1, newWave	# if the current spot red, a bullet hit a spider, so make a wave
		beq	$v0, $0, itemLooping	# spider no longer exists, so don't readd to queue, just return to itemLooping
		addi	$a1, $a1, 1	# moves light down a y-value
		li	$a2, 3
		jal	_setLED		# turn on new light
		jal	_insert_q	
		j	itemLooping	# continue to loop
	# moves a wave diagonally, horizontally, and veritcally
	waveMoving:
		srl	$a3, $t6, 8		# load radius
		andi	$a3, $a3, 0xFF	# load byte containing the event type
		jal	_getLED
		slti	$t0, $a3, 1		# if the radius is > 0, $t0 = 0
		and	$t0, $t0, $v0		# if radius is 0 and color is off
		beq	$t0, 1, itemLooping	# if the radius is >=1 and the color is off, delete item
		move	$t6, $a2		# no longer need $t6, so can temporarily store item type in it
		li	$a2, 0			# turn color to black (off)
		jal	_setLED			# turn of current light
		beq	$v0, 3, newWave		# if the spot is green, the shot hit a bug, make a new wave
		beq	$a3, 11, itemLooping	# delete wave item if radius = 11 (above 10)
		addi	$a3, $a3, 1		# increase radius
		beq	$t6, 4, waveMovingUp	# 4 = wave top vertical LED
		beq	$t6, 5, waveMovingDown	# 5 = wave bottom vertical LED
		beq	$t6, 6, waveMovingUL	# 6 = wave upper left LED
		beq	$t6, 7, waveMovingBL	# 7 = wave bottom left LED
		beq	$t6, 8, waveMovingUR	# 8 = wave upper right LED
		beq	$t6, 9, waveMovingBR	# 9 = wave bottom right LED
		beq	$t6, 10, waveMovingL	# 10 = wave left horizontal LED
		beq	$t6, 11, waveMovingR	# 11 = wave right horizontal LED
		# shouldn't ever reach this point

		waveMovingUp:
			addi	$a1, $a1, -1	# moves light up a y-value
			j	finishWaveMove
		waveMovingDown:
			addi	$a1, $a1, 1	# moves light down a y-value
			j	finishWaveMove
		waveMovingUL:
			addi	$a0, $a0, -1	# moves light left an x-value
			addi	$a1, $a1, -1	# moves light up a y-value
			j	finishWaveMove
		waveMovingBL:
			addi	$a0, $a0, -1	# moves light left an x-value
			addi	$a1, $a1, 1	# moves light down a y-value
			j	finishWaveMove
		waveMovingUR:
			addi	$a0, $a0, 1	# moves light right an x-value
			addi	$a1, $a1, -1	# moves light up a y-value
			j	finishWaveMove
		waveMovingBR:
			addi	$a0, $a0, 1	# moves light right an x-value
			addi	$a1, $a1, 1	# moves light down a y-value
			j	finishWaveMove
		waveMovingL:
			addi	$a0, $a0, -1	# moves light left an x-value
			j	finishWaveMove
		waveMovingR:
			addi	$a0, $a0, 1	# moves light left an x-value
			j	finishWaveMove
		finishWaveMove:
			slt	$t0, $a0, $0	# see if x-value is less than 0
			beq	$t0, 1, itemLooping	# delete item if out of range
			slti	$t0, $a0, 64	# see if x-value is more than 64
			beqz	$t0, itemLooping	# delete item if out of range
			slt	$t0, $a1, $0	# see if x-value is less than 0
			beq	$t0, 1, itemLooping	# delete item if out of range
			slti	$t0, $a1, 63	# see if y-value is more than 63 (line 63 is reserved for the player)
			beqz	$t0, itemLooping	# delete item if out of range
			li	$a2, 1
			jal	_setLED
			move	$a2, $t6		# move back item type
			jal	_insert_q
			j	itemLooping
	newWave:	# creates a new wave
		addi	$s6, $s6, 1	# $s6 = number of spiders shot, add 1 and start a wave
		li	$a2, 4		# item type = Top vertical (TV)
		li	$a3, 0		# radius starts off as 0
		jal	_insert_q
		li	$a2, 5		# item type = Bottom vertical (BV)
		li	$a3, 0		# radius starts off as 0
		jal	_insert_q
		li	$a2, 6		# item type = UL
		li	$a3, 0		# radius starts off as 0
		jal	_insert_q
		li	$a2, 7		# item type = BL
		li	$a3, 0		# radius starts off as 0
		jal	_insert_q
		li	$a2, 8		# item type = UR
		li	$a3, 0		# radius starts off as 0
		jal	_insert_q
		li	$a2, 9		# item type = BR
		li	$a3, 0		# radius starts off as 0
		jal	_insert_q
		li	$a2, 10		# item type = left
		li	$a3, 0		# radius starts off as 0
		jal	_insert_q
		li	$a2, 11		# item type = right
		li	$a3, 0		# radius starts off as 0
		jal	_insert_q
		j	itemLooping

	# insert event at the end of queue
	# $a0 = x, $a1 = y, $a2 = event type, $a3 = radius
_insert_q:
	addi	$t0, $s3, 4
	beq	$t0, $s2, overflow	# if the pointer to end now is at the same point as the pointer to 4 before the 
					#first item, then there is overflow
	add	$s3, $s3, 4		# change the last item pointer
	andi	$s3, $s3, 0x100201FF	# mask to stay within the bounds - this is the max value
	sb	$a2, 0($s3) 		# byte 3 is event type
	sb	$a0, 1($s3)		# byte 2 is 'x'
	sb	$a1, 2($s3)		# byte 1 is 'y'
	sb	$a3, 3,($s3)		# byte 0 is radius (distance from coordinate where a pulse hit a bug)
	jr	$ra

_remove_q:	# removes and returns an event from the head of the queue
	addi	$s2, $s2, 4	# increment the pointer to the new beginning of the queue
	andi	$s2, $s2, 0x100201FF	# mask to stay within the bounds - this is the max value
	lw	$v0, ($s2)	# event to return (because of endianness, event type is the lsbyte)
	jr	$ra

_size_q:	# returns (in $v0) number of events in queue
	sub	$t0, $s3, $s2	# find distance between pointer to last item and pointer to first item
	andi	$t0, $t0, 0x1FF	# biggest value possible, corrects for when start is at a greater memory address than end
	srl	$t0, $t0, 2	# each item is one word, so to measure size, needs to be moved by 4
	add	$v0, $zero, $t0
	jr	$ra


	# void _setLED(int x, int y, int color)
	#   sets the LED at (x,y) to color
	#   color: 0=off, 1=red, 2=orange, 3=green
	#
	# warning:   x, y and color are assumed to be legal values (0-63,0-63,0-3)
	# arguments: $a0 is x, $a1 is y, $a2 is color
	# trashes:   $t0-$t3
	# returns:   none
	#
_setLED:
	# byte offset into display = y * 16 bytes + (x / 4)
	sll	$t0,$a1,4      # y * 16 bytes
	srl	$t1,$a0,2      # x / 4
	add	$t0,$t0,$t1    # byte offset into display
	li	$t2,0xffff0008	# base address of LED display
	add	$t0,$t2,$t0    # address of byte with the LED
	# now, compute led position in the byte and the mask for it
	andi	$t1,$a0,0x3    # remainder is led position in byte
	neg	$t1,$t1        # negate position for subtraction
	addi	$t1,$t1,3      # bit positions in reverse order
	sll	$t1,$t1,1      # led is 2 bits
	# compute two masks: one to clear field, one to set new color
	li	$t2,3
	sllv	$t2,$t2,$t1
	not	$t2,$t2        # bit mask for clearing current color
	sllv	$t1,$a2,$t1    # bit mask for setting color
	# get current LED value, set the new field, store it back to LED
	lbu	$t3,0($t0)     # read current LED value
	and	$t3,$t3,$t2    # clear the field for the color
	or	$t3,$t3,$t1    # set color field
	sb	$t3,0($t0)     # update display
	jr	$ra

	# int _getLED(int x, int y)
	#   returns the value of the LED at position (x,y)
	#
	#  arguments: $a0 holds x, $a1 holds y
	#  trashes:   $t0-$t2
	#  returns:   $v0 holds the value of the LED (0, 1, 2 or 3)
	#
_getLED:
	# byte offset into display = y * 16 bytes + (x / 4)
	sll  $t0,$a1,4      # y * 16 bytes
	srl  $t1,$a0,2      # x / 4
	add  $t0,$t0,$t1    # byte offset into display
	la   $t2,0xffff0008
	add  $t0,$t2,$t0    # address of byte with the LED
	# now, compute bit position in the byte and the mask for it
	andi $t1,$a0,0x3    # remainder is bit position in byte
	neg  $t1,$t1        # negate position for subtraction
	addi $t1,$t1,3      # bit positions in reverse order
    	sll  $t1,$t1,1      # led is 2 bits
	# load LED value, get the desired bit in the loaded byte
	lbu  $t2,0($t0)
	srlv $t2,$t2,$t1    # shift LED value to lsb position
	andi $v0,$t2,0x3    # mask off any remaining upper bits
	jr   $ra

endGame:
	la	$a0, newLine		# new line
	li	$v0, 4
	syscall
	la	$a0, endMsg		# "The game score is "
	li	$v0, 4
	syscall
	move	$a0, $s6		# print the number of bugs hits
	li	$v0, 1
	syscall
	la	$a0, divider		# " : "
	li	$v0, 4
	syscall
	move	$a0, $s7		# print the number of shots made
	li	$v0, 1
	syscall
	la	$a0, newLine		# new line
	li	$v0, 4
	syscall
	li	$v0,10			# terminate program
	syscall				# exit game

overflow:
	la	$a0, error
	li	$v0, 4
	syscall
	li	$v0, 10
	syscall
