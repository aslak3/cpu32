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
			jumpnc (r1)
			halt

addfour:	addq r0,#4
			pushmulti (r15),R0|R1|R15
			addq r15,#3*4
			return

myvar:		#d32 0
