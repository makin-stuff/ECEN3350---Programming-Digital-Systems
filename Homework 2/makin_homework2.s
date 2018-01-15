# This is a bank template to use for your homework assignments

# --------------------------------------------------------------
#      Author: Priyanka Makin
#  Assignment: homework2
#        Date: 10/22/2017
#      System: DE10-Lite PDS Computer
# Description: Prints out statements and waits for the user to press the enter key.
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
		
		
#The next time I do this I want to properly implement function calls.
#I could not figure it out in time for this homework.
		
		#Init stack and frame pointers first
		movia			sp, SDRAM_CTRL_END
		movia			fp, SDRAM_CTRL_END
		
		#perform initialization
		movia			r16, UART_BASE
		#compare value to check new line character
		addi			r20, r0, 0x0A
		#registers pointing to the strings needed
		movia 			r8, press_ent_str
		movia			r10, hello_world_str
		movia			r11, ent_to_continue_str
		movia			r12, done_str

#modeled after pseudocode Professor Sluiter wrote on 10/20/2017
_tx_string:
		ldb				r9, (r8)
		#if we have transmitted all of the characters, branch to wait for return character
		beq				r9, r0, _rx_ret1
		stbio			r9, (r16)
		#increments through the characters of the string
		addi			r8, r8, 1
		br				_tx_string

#an exact replica of the rx code Professor Sluiter wrote in class
_rx_ret1:
		ldwio			r17, (r16)			#[15] = RVALID, ==1 we have a !empty FIFO
											#the character will be in [7:0]
		mov				r18, r17			#make a copy to test for RVALID set
		andi			r18, r18, 0x8000	#AND off everyting but the RVALID bit
		beq				r18, r0, _rx_ret1	#if r18 == 0, no character recieved
		#if we get here, we have recieved a character in r17 bits [7:0]
		#mask off everything but the last 8 bits
		andi			r17, r17, 0xFF
		#not sure why I need this line but the comparison does not work without it
		bne				r17, r20, _rx_ret1
		#if a new line character was recieved transmit the next string
		beq				r17, r20, _tx_string2
		
#the rest of the code goes on the same way as the first part
_tx_string2:
		ldb				r9, (r10)
		beq				r9, r0, _tx_string3
		stbio			r9, (r16)
		addi			r10, r10, 1
		br				_tx_string2
		
_tx_string3:
		ldb				r9, (r11)
		beq				r9, r0, _rx_ret2
		stbio			r9, (r16)
		addi			r11, r11, 1
		br				_tx_string3	

_rx_ret2:
		ldwio			r17, (r16)			#[15] = RVALID, ==1 we have a !empty FIFO
											#the character will be in [7:0]
		mov				r18, r17			#make a copy to test for RVALID set
		andi			r18, r18, 0x8000	#AND off everyting but the RVALID bit
		beq				r18, r0, _rx_ret2	#if r18 == 0, no character recieved
		#if we get here, we have recieved a character in r17 bits [7:0]
		#mask off everything but the last 8 bits
		andi			r17, r17, 0xFF
		bne				r17, r20, _rx_ret2
		beq				r17, r20, _tx_string4
		
_tx_string4:
		ldb				r9, (r12)
		beq				r9, r0, away
		stbio			r9, (r16)
		addi			r12, r12, 1
		br				_tx_string4

#end loop
away:
		br 				away
		
		
		# ---------------------------------------------------------
		# DATA SECTION 
		# ---------------------------------------------------------
		.data							

		#All the null (0) terminated strings we need.
#press_ent_str:			.asciz			"A\n"		#For debugging
press_ent_str:			.asciz			"Press the enter key to begin\n"
hello_world_str:		.asciz			"Hello World!\n"
ent_to_continue_str:	.asciz			"Press the enter key to continue\n"
done_str:				.asciz			"We are done!"	

		
		.end							# end of assembly.
	