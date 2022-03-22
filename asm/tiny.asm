			#d32 start

			halt
start:		load.l r0, #3
			load.l r1, #loop
			inc r1
loop:		store.b (myvar, r0), r0
			subq r0, #1
			jumpnn (r1)
			halt

myvar:		#d32 0
