# --------------------------------------------------------------------
# Subroutine to compute the BCD (0-9) value of the straight unsigned
# binary value in r4. The returned result can then be used
# to look up 7-segment character codes.
#   r4 = input, unsigned binary value, legal range is unsigned 0 to 99 decimal
# Returns the BCD values in:
#   r2 = [3:0] is the least significant BCD value, ie the ones place
#   r3 = [3:0] is the most significant BCD value, ie the tens place
#
# Example:
#   r4 = 0b10111 = decimal 23
#   Returns:
#   r2 = 0b0011 = decimal 3
#   r3 = 0b0010 = decimal 2
#
# Example:
#   r4 = 0b01100011 = decimal 99
#   Returns:
#   r2 = 0b1001 = decimal 9
#   r3 = 0b1001 = decimal 9
# --------------------------------------------------------------------

binary_to_bcd:

		.equ	BCD_STACKSIZE,		4*3 # words
		
        # We are not calling lower subroutines, so don't have to save ra.
        # Build a stack frame & save registers
bcd_build_stack:
		subi		sp,  sp, BCD_STACKSIZE
		stw			r16, 0(sp)
		stw			r17, 4(sp)
		stw			r18, 8(sp)
		
        # use the callee saved registers, r16-r23

		# init loop index, we look at the lower 8-bits of r4.
		movi		r16, 7    			# loop index
		add			r2, r0, r0			# init ones place 
		add			r3, r0, r0			# init tens place
		addi		r17, r0, 5 			# the 5 test value
		
bcd_loop:
		blt			r16, r0, bcd_done	# r16 = [7..0, -1 exits] ie branch if r16 < 0

bcd_check_tens:
		blt			r3, r17, bcd_skip_tens	# tens < 5
		addi		r3, r3, 3				# tens = tens + 3 if tens >= 5
bcd_skip_tens:

bcd_check_ones:
		blt			r2, r17, bcd_skip_ones	# ones < 5
		addi		r2, r2, 3				# ones = ones + 3 if ones >= 5
bcd_skip_ones:

bcd_shift_left:
		# tens = tens << 1
		slli		r3, r3, 1
		andi		r3, r3, 0x000F
		
		# shift ones[3] into tens[0]
		mov			r18, r2
		srli		r18, r18, 3				# ones >> 3,  gets [3] into [0]
		or			r3, r3, r18				# or in bit[0]
		
		# ones = ones << 1
		slli		r2, r2, 1
		andi		r2, r2, 0x000F
		
		# shift bit r4[index] into ones[0]
		mov			r18, r4
		srl 		r18, r18, r16			# r18 = r4 >> index
		andi		r18, r18, 0x0001		# leave just bit [0] for the or operation
		or			r2, r2, r18
		
bcd_inc_loop_index:		
		addi		r16, r16, -1			# index = index - 1
		br			bcd_loop
		
bcd_done:
		# when we get here:
		# r2 = ones place in BCD 0-9
		# r3 = tens place in BCD 0-9
		
        # tear down the stack frame
bcd_tear_stack:
		ldw			r16, 0(sp)
		ldw			r17, 4(sp)
		ldw			r18, 8(sp)
		addi		sp,  sp, BCD_STACKSIZE
		
        ret			# return, jump to (ra)
