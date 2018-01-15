# --------------------------------------------------------------
#      Author: Priyanka Makin
#  Assignment: homework5
#        Date: 12/03/2017
#      System: DE10-Lite PDS Computer
# Description: Offensive programming for NOR flash (lol)
# --------------------------------------------------------------

		# ---------------------------------------------------------
		# TEXT SECTION 
		# ---------------------------------------------------------
		.text							
		
		.include 	"address_map_nios2.s"	
		.include	"data.s"
		.equ		newLine, 0x0A
		.equ		WT, 0xFFFFFFFF
										
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
		
#Let's start!
#------------------------------------
# 1
#------------------------------------
	#initialization
	movia		r7, startString
	movia		r6, UART_BASE
	
#-----------------------------------
# 2
#-----------------------------------
	#print initial statement
	call 		printStatement
	movi		r7, newLine
	#wait around for enter key
	call		pressEnter
	
#-----------------------------------
# 3
#-----------------------------------
	#disable sector 1
	movia		r15, ONCHIP_FLASH_CSR_CONTROL
	#load control value into r14
	ldwio		r14, (r15)
	#bitmask
	andhi		r14, r14, 0xFF7F
	#set control reg from 1 to 0
	stwio		r14, (r15)
	
#-----------------------------------
# 4 
#-----------------------------------
	#wait for idle, erase sector 1, then wait for idle again
	call 		idle
	movia		r15, ONCHIP_FLASH_CSR_CONTROL
	ldbio		r14, 2(r15)
	ori			r14, r14, 0b00010000
	andi		r14, r14, 0b10011111
	stbio		r14, 2(r15)
	call 		idle
	
#-----------------------------------
# 5
#-----------------------------------
	#check for erase successful status
	movia		r15, ONCHIP_FLASH_CSR_STATUS
	ldbio		r14, (r15)
	#bitmask for erase successful bit
	movi		r13, 0b00010000
	and			r14, r14, r13
	#if erase operation failed
	bne			r14, r13, eraseFailed
	br			checkSec
	
eraseFailed:
	#print error message
	movia		r7, eraseFailString
	movia		r6, UART_BASE
	call		printStatement
	break
	
#-----------------------------------
# 6
#-----------------------------------
#check if all bits written
checkSec:
	movia		r15, ONCHIP_FLASH_SECTOR1_BASE
	ldwio		r14, (r15)
	#compare sector 1 value to WT to see if empty
	movia		r13, WT
	bne			r14, r13, eraseBitsFailed
	br			writeData
	
eraseBitsFailed:
	#print error message
	movia		r7, eraseBitFailString
	movia		r6, UART_BASE
	call		printStatement
	break
	
#------------------------------------
# 7
#------------------------------------
#write into NOR flash
writeData:
	#create a counter
	mov			r15, r0
	movi		r14, 16
	movia		r13, ONCHIP_FLASH_SECTOR1_BASE
	#r12 -> holds data address of item to be written into flash
	movia		r12, the_data

writeDataNext:
	call		idle
	#load word
	ldwio		r11, (r12)
	call		idle
	#store word
	stwio		r11, (r13)
	
	checkWrite:
		movia		r10, ONCHIP_FLASH_CSR_STATUS
		ldwio		r9, (r10)
		#bitmask for write successful
		movi		r8, 0b1000
		and 		r9, r9, r8
		#if write successful
		beq			r9, r8, successfulWrite
		
		printWriteErrorString:
			#print error message
			movia		r7, programFailString
			movia		r6, UART_BASE
			call		printStatement
			break
			
	successfulWrite:
		#move flash address
		addi		r13, r13, 4
		#move data address
		addi		r12, r12, 4
		#increment
		addi		r15, r15, 1
		ldbio		r9, (r10)
		#clear write successful
		andi		r9, r9, 0b11110111
		#re-enable
		beq			r15, r14, secProtect
		br			writeDataNext
		
#-------------------------------------
# 8
#-------------------------------------
secProtect:
	movia		r15, ONCHIP_FLASH_CSR_CONTROL
	ldbio		r14, 2(r15)
	#toggle protection bit
	xori		r14, r14, 0b10000000
	#set protection bit
	stbio		r14, 2(r15)
	
#-------------------------------------
# 9
#-------------------------------------
#print end statement
movia		r7, endString
movia		r6, UART_BASE
call		printStatement

#-------------------------------------
# 10
#-------------------------------------
#all done!
done:
	br		done
	
printStatement:
	#r7 -- address of print string
	#r6 -- UART_BASE
	#load char
	ldbio		r23, (r7)
	ldwio		r5, 4(r6)
	andhi		r5, r5, 0xFFFF
	#wait for space
	beq			r5, r0, printStatement
	stbio		r23, (r6)
	addi		r7, r7, 1
	ldbio		r23, (r7)
	bne			r23, r0, printStatement
	ret

pressEnter:
	#r7 -- address of print string
	#r6 -- 	UART_BASE
	#read value
	ldwio		r23, (r6)
	#copy value
	mov			r21, r23
	andi		r21, r21, 0x8000
	#if not valid, keep on checking
	beq			r21, r0, pressEnter
	andi		r23, r23, 0xFF
	bne			r23, r7, pressEnter
	ret
	
#wait until flash is idle	
idle:
	movia		r21, ONCHIP_FLASH_CSR_STATUS
	ldbio		r23, (r21)
	#only look at first two bits
	andi		r23, r23, 0x03
	#loop back until not idle
	bne			r23, r0, idle
	ret
	
	
		# ---------------------------------------------------------
		# DATA SECTION 
		# ---------------------------------------------------------
		.data							
		
	startString:		.asciz	"Ready to program NOR flash, press the enter key to begin\n"
	eraseFailString:	.asciz	"Erase operation failed\n"
	eraseBitFailString:	.asciz	"Erase operation failed to set all bits to 1\n"
	programFailString:	.asciz	"A programming operation failed\n"
	endString:			.asciz	"NOR flash programming complete\n"
	
		.end							# end of assembly.
	