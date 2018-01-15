# This is a bank template to use for your homework assignments

# --------------------------------------------------------------
#      Author: Priyanka Makin
#  Assignment: homework3
#        Date: 11/25/2017
#      System: DE10-Lite PDS Computer
# Description: This code lights up one LED at a time and moves back
#				and forth from LED0 to LED9 and increments a counter
#				in using an interrupt and an ISR.
# --------------------------------------------------------------

# --------------------------------------------------------------------------------------
# This template is for developing code that implements interrupt driven IO.
# --------------------------------------------------------------------------------------
 
		# ---------------------------------------------------------
		# RESET SECTION
		# ---------------------------------------------------------
        # The Monitor Program places the ".reset" section at the reset location
        # specified in the CPU settings in Qsys.
        # Note: "ax" is REQUIRED to designate the section as allocatable and executable.
        
		
		# A real reset handler would fully initialize the CPU and then jump to start.
		# CPU's reset vector = 0x0000_0000
        .section    .reset, "ax"

reset: 
        movia       r2, _start
        jmp         r2
		
		
		# ---------------------------------------------------------
		# EXCEPTION SECTION 
		# ---------------------------------------------------------
        # The Monitor Program places the ".exceptions" section at the
        # exception location specified in the CPU settings in Qsys.
        # Note: "ax" is REQUIRED to designate the section as allocatable and executable.
        
		# CPU's exception vector = 0x0000_0020
        .section    .exceptions, "ax"
        
exception_handler:	
		jmpi 		interrupt_service_routine


		# ---------------------------------------------------------
		# TEXT SECTION 
		# ---------------------------------------------------------
		.text							
		
		.include 	"address_map_nios2.s"	
		.include	"bcd_function.s"
		
		#delay value determined by trial and error
		.equ 		DELAY_VALUE, 500000
		#Shifting LED compare values
		.equ		LED0, 0x01
		.equ		LED9, 0x200
		#clock speed
		.equ		clock, 10000000
										
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

# --------------------------------------------------------------
# Initialization code
# --------------------------------------------------------------			
		# IMPORTANT: Set up the stack frame.
		# This is required if you will be calling subroutines/functions
		movia 	sp, SDRAM_CTRL_END 
		movia 	fp, SDRAM_CTRL_END 
			
		#timer initialization steps
		movia		r4, TIMER_BASE		
		sthio		r0, (r4)
		movia		r8, clock
		sthio		r8, 8(r4)
		srli		r8, r8, 16
		sthio		r8, 12(r4)
		addi		r8, r0, 4
		sthio		r8, 4(r4)


# --------------------------------------------------------------
# Insert your ISR initialization code here
# --------------------------------------------------------------
	
		# ---------------------------------------------------
        # Configure devices to generate interrupts
		# ---------------------------------------------------
			movi		r8, 0b0001
			stwio		r8, 4(r4)
		
		 
		# ---------------------------------------------------
		# Configure CPU to take external hardware interrupts
		# ---------------------------------------------------
			#enable irq[2] input
			movia		r8, IRQ_TIMER_MASK
			wrctl		ienable, r8
			
			#set status[PIE] to take IRQ
			movi		r8, 0b0001
			wrctl		status, r8
			
			#initialize sev segment to 0, uart at r5
			addi		r3, r0, 0x3f3f
			movia		r5, UART_BASE
			
			#base of segment table
			movia		r6, sevSegTable
			#start count at the value of 0
			mov			r7, r0
			#offset to correct code in table
			add			r6, r6, r7
			#get the sev segment code
			ldbu		r7, (r6)
			#let r6 become the HEX0 base
			movia		r6, (SEGA_OUT_BASE)
			#write the value to the sev seg display
			stwio		r3, (r6)
		
		
# --------------------------------------------------------------
# main program
# --------------------------------------------------------------		
#cleaned this up from homework 1
		movia		r15, LED_OUT_BASE
		addi		r10, r0, LED0
		addi		r9, r0, LED9
		
loop:
		addi		r11, r0, 1
		stwio		r11, (r15)
		
lShift:
		movia		r12, DELAY_VALUE
		call 		delayLoop
		slli		r11, r11, 1
		stwio		r11, (r15)
		bne			r11, r9, lShift

rShift:
		movia		r12, DELAY_VALUE
		call delayLoop
		srli		r11, r11, 1
		stwio		r11, (r15)
		bne			r11, r10, rShift
		br			loop

delayLoop:
		subi		r12, r12, 1
		bne			r12, r0, delayLoop
		ret
	
	
# --------------------------------------------------------------
# End of main program
# --------------------------------------------------------------				
		
	
# ---------------------------------------------------------
# Exception Handler / Interrupt Service Routine
# ---------------------------------------------------------
interrupt_service_routine:

		# Adjust the size of the stack frame as needed by your code 
		.equ		ISR_STACKSIZE,	5*4 		# 5 32-bit words
		
        # make a stack frame
        subi        sp, sp, ISR_STACKSIZE

        # ---------------------------------
        # save the registers we use in here
        # --------------------------------- 
        stw         et,  0(sp)

        # check for internal vs. external IRQ
        # decrement ea for external IRQ      
        rdctl       et, ipending    # get all 32 bits that represent irq31 to irq0 
        beq         et, r0, skip_ea_dec

        subi        ea, ea, 4       # must decrement ea by one instruction
                                    # for external interrupts, so that the
                                    # interrupted instruction will be run after eret
skip_ea_dec:
        stw         ea,  4(sp)		# save the exception address
        stw         ra,  8(sp)		# save the current subrountine's ra 
									# save the registers we use in this routine
		stw			r6,  12(sp)		
		stw			r7,  16(sp)		
		stw			r5,  20(sp)		
		stw			r2,	 24(sp)		
		stw			r3,  28(sp)		

		# bail if IRQ is not external hardware interrupt
        beq         et, r0, end_isr     # interrupt is not external IRQ
		
		
        # -----------------------------------
        # do our stuff, service the interrupt                     
        # -----------------------------------
counterUpdate:
		#update counter in memory
		movia		r6, count
		ldw			r7, (r6)
		addi		r7, r7, 1
		stw			r7, (r6)
		#display last 4 bits of count value
		addi		r6, r7, 0
		
		#call bcd_function.s
		call binary_to_bcd
		#have digits pointing to sev segment table
		movia		r6, sevSegTable
		movia		r7, sevSegTable
		
		add			r6, r6, r2		#add r2 to r6, this is the 1's digit
		ldbu		r2, (r6)		#load r2 with r6
		add			r7, r7, r3		#add r3 to r7, this is the 10's digit
		ldbu		r3, (r7)		#load r3 with r7
		
		#roll over?? first concatenate registers
		slli		r3, r3, 8
		add			r2, r2, r3
		#secondly, actually check for roll over
		addi		r7, r0, 0x3f3f			#is it zero?
		beq			r7, r2, printRollover	#if r2 == 0, print string
		
		store:
				#display the digits
				#write the HEX0 digit
				movia			r7, SEGA_OUT_BASE
				stwio			r2, (r7)	
				
				#clear interrupt source
				movia			r4, TIMER_BASE
				#restart timer
				addi			r7, r0, 1
				stbio			r7, (r4)
				br				end_isr
				
printRollover:
		#move the string into r7
		movia		r7, rollOverPrint
		#add 10??
		addi		r3, r0, 0x0A	
		
		#do the loop-de-loop
		_printRollOver:
				ldb				r6, (r7)
				stbio			r6, (r5)
				addi			r7, r7, 1
				bne				r6, r3, _printRollOver
				br				store
				
end_isr:
		addi		r7, r0, 0b0101
		sthio		r7, 4(r4)

        # restore registers we used
        ldw         et,  0(sp)
        ldw         ea,  4(sp)
        ldw         ra,  8(sp)
		
        ldw			r6,  12(sp)
		ldw			r7,  16(sp)
		ldw			r5,  20(sp)
		ldw			r2,  24(sp)
		ldw			r3,  28(sp)
		

        # free the stack frame
        addi        sp, sp, ISR_STACKSIZE
		

		eret		# return from exception 


		# ---------------------------------------------------------
		# DATA SECTION 
		# ---------------------------------------------------------
		.data							

        .align 2	# align to 2^2=4 byte boundary

		#counter value -- start at zero obviously
		count:		.word		000000000
		
		sevSegTable:
			.byte		0x3f3f		#0
			.byte		0x3f06		#1
			.byte		0x5b		#2
			.byte		0x4f		#3
			.byte		0x66		#4
			.byte		0x6d		#5
			.byte		0x7d		#6
			.byte		0x07		#7
			.byte		0x7f		#8
			.byte		0x67		#9
			.byte		0x77		#A
			.byte		0x7c		#B
			.byte		0x39		#C
			.byte		0x5e		#D
			.byte		0x79		#E
			.byte		0x71		#F
			
		hex:
			.byte		0b0000		#0
			.byte		0b0001		#1
			.byte		0b0010		#2
			.byte		0b0011		#3	
			.byte		0b0100		#4
			.byte		0b0101		#5
			.byte		0b0110		#6
			.byte		0b0111		#7
			.byte		0b1000		#8
			.byte		0b1001		#9
			.byte		0b1010		#10
			.byte		0b1011		#11
			.byte		0b1100		#12
			.byte		0b1101		#13
			.byte		0b1110		#14
			.byte		0b1111		#15
			
		rollOverPrint:		
			.asciz		"The counter has rolled over\n"
		
		
		.end		# end of assembly.
	
