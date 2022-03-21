			#d32 start

			halt
start:		load.l r15,#0x12345678
loop:		inc r15
			branch loop

