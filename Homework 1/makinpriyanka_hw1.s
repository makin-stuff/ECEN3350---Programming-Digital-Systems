# This is a bank template to use for your homework assignments

# --------------------------------------------------------------
#      Author: <Priyanka Makin>
#  Assignment: homework1  <change N to the appropriate value>
#        Date: <10/08/2017>
#      System: DE10-Lite PDS Computer
# Description: <Blinking an LED up and down LED0 to LED9>
# --------------------------------------------------------------
 
 		.include 	"address_map_nios2.s"
		
		#delay value determined by trial and error
		.equ 		DELAY_VALUE, 500000
		
		.text							
	
		.global 	_start					

_start:									
		#initialization code: insert your code here -- not sure what this is yet
		movia		sp, SDRAM_CTRL_END
		movia		fp, SDRAM_CTRL_END
		
		movia		r15, LED_OUT_BASE
		
		#compare values
		addi		r16, r0, 0b0000000000
		addi		r17, r0, 0b1000000000
		
		addi		r18, r0, 0b0000000001
		addi		r19, r0, 0b1000000000
		
left:
		stwio		r18, (r15)
		#left shift
		slli		r18, r18, 1
		movia		r10, DELAY_VALUE
		
		beq			r18, r17, right
		
l_delayinit:
		movia		r10, DELAY_VALUE
l_delayloop:
		subi		r10, r10, 1
		bne			r10, r0, l_delayloop
		
		#when r10 == 0, branch back to the top of the loop and do it all again
		br left
		
	
right:
		stwio		r19, (r15)
		#right shift
		srli		r19, r19, 1
		movia		r10, DELAY_VALUE
		
		#subi		r19, r19, 1
		beq			r19, r16, left_setup
		
r_delayinit:
		movia		r10, DELAY_VALUE
r_delayloop:
		subi		r10, r10, 1
		bne			r10, r0, r_delayloop
		
		#when r10 == 0, branch back to the top of the loop and do it again
		br right
		
left_setup:
		addi		r18, r0, 0b0000000001
		addi		r19, r0, 0b1000000000
		br left

/*r_check:
		beq			r19, r16, right	
*/
		
		
		.data

		.end							# end of assembly.
	