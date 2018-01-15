# --------------------------------------------------------------
#      Author: Kaitlin Mazotti
#  Assignment: homework4
#        Date: November 16, 2017
#      System: DE10-Lite PDS Computer
# Description: hw1 with interrupts and segment display counter
#              with a cute little rollover message
# --------------------------------------------------------------

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

    .include "bcd_function.s"

    .equ delayValue, 500000 # declares time of delay
    .equ LED0, 0x01  # declares LED0
    .equ LED9, 0x200 # declares LED9

    .equ clk, 10000000

    .global 	_start

_start:

# --------------------------------------------------------------
# Initialization code
# --------------------------------------------------------------
		# IMPORTANT: Set up the stack frame.
		# This is required if you will be calling subroutines/functions
		movia 	sp, SDRAM_CTRL_END
		movia 	fp, SDRAM_CTRL_END

		# main program initialization steps

    movia r7, TIMER_BASE # move TIMER_BASE into r7
    sthio r0, (r7) # stores lower halfword of 0 to TIMER_BASE
    movia r9, clk
    sthio r9, 8(r7)
    srli r9, r9, 16
    sthio r9, 12(r7)
    addi r9, r0, 4
    sthio r9, 4(r7)

# --------------------------------------------------------------
# Insert your ISR initialization code here
# --------------------------------------------------------------

		# ---------------------------------------------------
        # Configure devices to generate interrupts
		# ---------------------------------------------------

    # movia r15, KEYS_IN_IRQ_MASK
    movi r9, 0b0001
    stwio r9, 4(r7)

		# ---------------------------------------------------
		# Configure CPU to take external hardware interrupts
		# ---------------------------------------------------

    # enable the CPU to take an IRQ on irq[2] input
    movia r9, IRQ_TIMER_MASK
    wrctl ienable, r9

    # set CPU status[PIE] to enable the CPU to take the IRQ
    movi r9, 0b0001
    wrctl status, r9

    addi r3, r0, 0x03F3F # r3 -> seven segment display of 0
    movia r6, UART_BASE # r6 -> UART

    movia r4, segmentTable # segment table base
    mov r5, r0 # initial count value
    add r4, r4, r5 # point (offset) to char code in table
    ldbu r5, (r4) # get the char code from the table
    movia r4, (SEGA_OUT_BASE) # r4 -> HEX0 base
    stwio r3, (r4) # write the value to HEX0

# --------------------------------------------------------------
# main program
# -------------------------------------------------------------
    movia r16, LED_OUT_BASE
    addi r10, r0, LED0 # places LED0 into register r10
    addi r9, r0, LED9 # places LED9 into register r9

loop: # main loop

    addi r8, r0, 1 # adds one into r8
    stwio r8, (r16) # moves value of r8 into address of r16

lShift: # shifts left

      movia r11, delayValue # delays the LED change

      call delayLoop

      slli r8, r8, 1 # shifts bits to the left
      stwio r8, (r16) # stores r8 into the address of r16 (LED address)

      bne r8, r9, lShift # if the value is not LED9, shift left


rShift: # shifts right

      movia r11, delayValue # delays the LED change

      call delayLoop

      srli r8, r8, 1 # shifts bits to the right
      stwio r8, (r16) # stores r8 into the address of r16 (LED address)

      bne r8, r10, rShift # if the value is not LED0, shift right

br loop

delayLoop: # delay loop for left shift
    subi			r11, r11, 1
    bne				r11, r0, delayLoop
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

        stw         r4,  12(sp)		# save the registers we use in this routine
        stw         r5,  16(sp)
        stw         r6,  20(sp)
        stw         r2,  24(sp)
        stw         r3,  28(sp)


		# bail if IRQ is not external hardware interrupt
        beq         et, r0, end_isr     # interrupt is not external IRQ





        # -----------------------------------
        # do our stuff, service the interrupt
        # -----------------------------------

updateCount:
        # update the count in memory
        movia r4, count
        ldw r5, (r4)
        addi r5, r5, 1
        stw r5, (r4)
		# Service the interrupting device
        addi r4, r5, 0 # display lower 4-bits of the 32-bit count value

        call binary_to_bcd # calls the bcd_function file
        movia r4, segmentTable # move segmentTable address into r4 & r5
        movia r5, segmentTable

        add r4, r4, r2 # adds r4 to r2, which was returned from the binary_to_bcd
                       # function and is the least significant BCD value (1's place)
        ldbu r2, (r4) # loads r2 with r4's value
        add r5, r5, r3 # adds r5 to r3 which was returned from the binary_to_bcd
                       # 10's place
        ldbu r3, (r5) # loads r3 with r5's value

        # place both segment dislay registers into one in order to check for
        # rollover
        slli r3, r3, 8
        add r2, r2, r3

        # check if it rolled over
        addi r5, r0, 0x3F3F # check if it is 0
        beq r5, r2, printString # when r2 (our segment display register) is equal to
                           # 0 which is what was placed in r5, branch to printString

      storeIt:
          # Display
          movia r5, SEGA_OUT_BASE # r4 -> HEX0 base
          stwio r2, (r5) # write the HEX0

  		    # Clear the source of the interrupt
          movia r7, TIMER_BASE # base address of push button registers
          addi r5, r0, 1 # restarts TIMER
          stbio r5, (r7)

      br end_isr

printString:
        movia r5, printS # move print string address into r5
        addi r3, r0, 0x0A # add 10 to r3 register
    _printString:
          ldb r4, (r5) #
          stbio r4, (r6)
          addi r5, r5, 1
          bne r4, r3, _printString

      br storeIt

end_isr:
        addi r5, r0, 0b0101
        sthio r5, 4(r7)
        # restore registers we used
        ldw         et,  0(sp)
        ldw         ea,  4(sp)
        ldw         ra,  8(sp)
        ldw         r4,  12(sp)
        ldw         r5, 16(sp)

        ldw         r6, 20(sp)
        ldw         r2, 24(sp)
        ldw         r3, 28(sp)




        # free the stack frame
        addi        sp, sp, ISR_STACKSIZE


		eret		# return from exception

		# ---------------------------------------------------------
		# DATA SECTION
		# ---------------------------------------------------------
		.data

        .align 2	# align to 2^2=4 byte boundary

        count: .word 000000000

        segmentTable:
          .byte 0x3F3F # 0
          .byte 0x3F06 # 1
          .byte 0x5B # 2
          .byte 0x4F # 3

          .byte 0x66 # 4
          .byte 0x6D # 5
          .byte 0x7D # 6
          .byte 0x07 # 7

          .byte 0x7F # 8
          .byte 0x67 # 9
          .byte 0x77 # A
          .byte 0x7C # b

          .byte 0x39 # C
          .byte 0x5E # d
          .byte 0x79 # E
          .byte 0x71 # F

        hex:
          .byte					0b00000
          .byte					0b00001
          .byte					0b00010
          .byte					0b00011
          .byte					0b00100
          .byte					0b00101
          .byte					0b00110
          .byte					0b00111
          .byte					0b01000
          .byte					0b01001
          .byte					0b01010
          .byte					0b01011
          .byte					0b01100
          .byte					0b01101
          .byte					0b01110
          .byte					0b01111

        printS: .asciz "The counter has rolled over, good boy *woof*\n"


		.end		# end of assembly.
