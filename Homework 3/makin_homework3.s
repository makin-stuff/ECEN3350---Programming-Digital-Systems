# This is a bank template to use for your homework assignments

# --------------------------------------------------------------
#      Author: Priyanka Makin
#  Assignment: homework3
#        Date: 10/28/2017
#      System: DE10-Lite PDS Computer
# Description: Circular buffer
# --------------------------------------------------------------

# This is a comment line.

/*
     This is a comment block
 */
 
		# ---------------------------------------------------------
		# TEXT SECTION 
		# ---------------------------------------------------------
		.text							
		
		.include 	"address_map_nios2.s"	
										
		.global 	_start			
		.equ		BUFFER_SIZE, 32
		.equ		word_size, 8

_start:	
		# Nios II register usage convention
		#      r1     : assembler temporary, don't use this!
		#   r2-r3     : output from subroutine 
		#   r4-r7     : input to subroutine
		#   r8  - r15 : Caller saved.
		#   r16 - r23 : Callee saved. 
		#   r24 - r31 : Reserved/special function registers, stack pointer
		#               return address etc., don't use these as general
		#               purpose registers in the code you write! 
		
		#r2
		#r3
		#r4
		#r5
		#r6
		#r7
		#r8 -> pointer to dump string
		#r9 -> pointer to buffer first entry
		#r10 -> points to characters before \n character
		#r11 -> buffer tail
		#r12 -> holds characters from buffer to compare to dump string
		#r13 -> points to end of buffer
		#r14 -> filled buffer once? flag
		#r15 -> pointer used for special "p" cases
		#r16 -> uart base
		#r17 -> hard-coded character to compare to 
		#r18 -> printing counter
		#r19 -> keep track of if uart full
		#r20
		#r21 -> new line character
		#r22
		#r23 -> holds the recieved character
		
		#Initialize stack and frame pointer
		movia			sp, SDRAM_CTRL_END
		movia			fp, SDRAM_CTRL_END
		#UART base
		movia			r16, UART_BASE
		#store new line character in register
		addi			r21, r0, 0x0A
		#pointers
		movia			r8, dump_str
		movia			r9, buffer
		#pointers in buffer (r10 = head, r11 = tail)
		#movia			r10, buffer				I guess I don't need this after all
		movia			r11, buffer
		#register points to end of buffer
		addi			r13, r11, 31
		#filled buffer once? flag
		addi			r14, r0, 0
		
		
		#build stack frame -- did not end up using this
		subi			sp, sp, word_size
		#store buffer tail
		stw				r11, 0(sp)
		#store end of buffer
		stw				r13, 4(sp)

top:
		#just wait to recieve a character for the whole duration of the program
		br			_rx_char
		
		
_rx_char:
		ldwio		r17, (r16)				# [15] = RVALID, when ==1 we have a !empty RX FIFO
											# and the character will be in [7:0]
		mov			r18, r17				# make a copy to test for RVALID set
		andi		r23, r17, 0b11111111	#mask off the top bits, this is the actual value
		andi		r18, r18, 0x8000		# AND off everything but the RVALID bit
		beq			r18, r0, _rx_char		# if r18 == 0, no character received 
        # when we fall through to here
		# we have the received character in r17 bits [7:0]
		
		#NOTE: Gave up trying to use the stack and frame pointer
		#pull head/tail from stack
		#ldw			r10, 0(sp)
		#ldw			r11, 4(sp)
		
_tx_char:
		ldwio		r18, 4(r16)         # get WSPACE, is there space available in the
                                        # TX FIFO?
        andhi       r18, r18, 0xFFFF    # AND-off the lower 16-bits - this is the missing instruction
                                        # I referred to in class. Only look at the upper 16-bits.
		beq			r18, r0, _tx_char   # No space, wait for space to become available.
                                        # The hardware will eventually drain the FIFO to a point
										# where space in the TX FIFO is available.

										
		# OK, there is space in the TX FIFO, send the character to the host
		stbio		r17, (r16)
		
		
store:
		#first, put the recieved character in the tail of the buffer
		stb			r23, 0(r11)
		#are we at the end of the buffer? (tail == to end of buffer)
		#If we are, we need to wrap around
		beq			r11, r13, wrap_around
		#If not, just increment tail
		addi		r11, r11, 1
		br			check_for_return
		
wrap_around:
		#set flag - buffer filled up at least once!
		addi		r14, r0, 1
		#move the tail pointer back to the beginning of the buffer
		movia		r11, buffer
		br			check_for_return
		
check_for_return:
		addi		r21, r0, 0x0A
		#if the last recieved character was "\n" check for a preceding "dump"
		beq			r23, r21, check_for_dump
		#if the character was not "\n", continue as norma
		bne			r23, r21, top

		
check_for_dump:
		#NOTE: dump in ascii == 0x64756D70
		#r9 points to the beginning of the buffer
		#r10 helpful pointer
		#r11 is the buffer tail
		#r12 holds characters to compare to dump string
		#r13 points to the end of the buffer
		#r15 pointer for special "p" cases
		
		#look at most recent non \n char (two spots behind current tail pointer)
		subi		r10, r11, 2
		#intialize r12 to zero, will load the four characters before \n into this register
		mov			r12, r0
		
		#This is undoubtedly not the most efficient way to do this,
		#but we will check each character before \n one at a time
		p_check:
			#two wrap around cases: 
			#1)p is in first position of buffer or 2)p is in the last 
			bge		r10, r9, p_no_wrap
			#this is the memory right before the buffer
			subi 	r15, r9, 1
			#if p is at the end of the buffer branch (case #2)
			beq 	r15, r10, p_at_end
			#otherwise, case #1
			mov		r10, r13
			subi	r10, r10, 1
			ldb		r12, (r10)
			#"p" character
			addi	r17, r0, 0x70
			#check "m" character
			beq		r12, r17, m_check 
			br		top
			
			#"\n" at position 0 and "p" at position 31 (case #2)
			p_at_end:
				#r10 points to "p"
				mov			r10, r13
				#put "p" in r12
				ldb			r12, (r10)
				#r17 holds "p" ascii value
				addi		r17, r0, 0x70
				#compare r12 and r17 -- if equal start checking "m"
				beq			r12, r17, m_check
				br			top
			
			#"p" just somewhere in the middle of the buffer
			p_no_wrap:
				ldb			r12, (r10)
				addi		r17, r0, 0x70
				beq			r12, r17, m_check
				br 			top
			
		m_check:
			subi		r10, r10, 1
			bge			r10, r9, m_no_wrap
			mov			r10, r13
			ldb			r12, (r10)
			addi		r17, r0, 0x6D
			beq			r12, r17, u_check
			br			top
			
			m_no_wrap:
				ldb			r12, (r10)
				addi		r17, r0, 0x6D
				beq			r12, r17, u_check
				br			top
				
		u_check:
			subi		r10, r10, 1
			bge			r10, r9, u_no_wrap
			mov			r10, r13
			ldb			r12, (r10)
			addi		r17, r0, 0x75
			beq			r12, r17, d_check
			br			top
			
			u_no_wrap:
				ldb			r12, (r10)
				addi		r17, r0, 0x75
				beq			r12, r17, d_check
				br			top
		
		d_check:
			subi		r10, r10, 1
			bge			r10, r9, d_no_wrap
			mov			r10, r13
			ldb			r12, (r10)
			addi		r17, r0, 0x64
			beq			r12, r17, finished_comparison
			br			top
			
			d_no_wrap:
				ldb			r12, (r10)
				addi		r17, r0, 0x64
				beq			r12, r17, finished_comparison
				br			top
				
finished_comparison:
			#have r10 point to buffer tail
			mov			r10, r11
			#clear r12
			mov			r12, r0
			#reusing r21 -- value of 32 used to compare to printing counter
			addi		r21, r0, 32
			#reusing r18 -- clear it to repurpose as printing counter
			mov			r18, r0
			br			_tx_string
			
_tx_string:
		#r12 points to buffer index to print
		ldbio			r12, (r10)
		
		ldwio			r19, 4(r16)
		andhi			r19, r19, 0xFFFF
		#wait for space in the TX FIFO
		beq				r19, r0, _tx_string
		
		#send char to UART buffer
		stbio 			r12, (r16)
		#increment print counter
		addi			r18, r18, 1
		
		#return to main if printed whole buffer (32 values)
		beq				r18, r21, top
		
		#if we are at "end" of buffer (spot 31) wrap around
		beq				r10, r13, wrap_around_print
		#otherwise, just increment print pointer
		addi			r10, r10, 1
		ldbio			r12, 0(r10)
		#repeat
		br				_tx_string
		
		wrap_around_print:
			#move print pointer to start of buffer
			movia				r10, buffer
			ldbio				r12, 0(r10)
			#repeat
			br					_tx_string

			
		# ---------------------------------------------------------
		# DATA SECTION 
		# ---------------------------------------------------------
		.data							

		#dump string for comparison -- didn't end up using this
dump_str:				.asciz			"dump\n"
		#initialize buffer 32 bytes long
buffer:					.space			BUFFER_SIZE
	
	
	
	
		
		.end							# end of assembly.
	