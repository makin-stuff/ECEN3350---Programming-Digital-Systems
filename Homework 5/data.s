
		
		
		
# ----------------------------------------------------
# data section
# ----------------------------------------------------
			.data

			.align  2^2             # align to 4-byte boundary
			

the_data:      # 16 x 4-bytes = 64-bytes, data values to program into flash
            .word       0x03020100
            .word       0x07060504
            .word       0x0b0a0908
            .word       0x0f0e0d0c

            .word       0x13121110
            .word       0x17161514
            .word       0x1b1a1918
            .word       0x1f1e1d1c

            .word       0x23222120
            .word       0x27262524
            .word       0x2b2a2928
            .word       0x2f2e2d2c

            .word       0x33323130
            .word       0x37363534
            .word       0x3b3a3938
            .word       0x3f3e3d3c
			
			
            # Add your strings here.



