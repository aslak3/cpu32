			#d32 start

			halt
start:		load.l r0, #0x80
			load.l r1, #loop
			load.l r15, #0x200
			load.l r9, #addfour
			calljump (r9)
			copy r10, r15
loop:		store.l (myvar, r0), r0
			subq r0, #4
			jumpnn (r1)
			halt

addfour:	addq r0,#4
			push (r15), r0
			pop r14, (r15)
			return

myvar:		#d32 0
