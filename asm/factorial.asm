			#d32 start

start:		load.l r15,#0x200
			loadq.ws r0,#1
			loadq.ws r3,#9
			load.l r2,#table
loop:		calljump factorial
			store.l (r2),r1
			addq r2,#4
			addq r0,#1
			compare r0,r3
			branchqne loop
			halt

factorial:	push (r15),r0
			copy r1,r0
l:			subq r0,#1
			branchzs factorialo
			mulu r1,r0,r1
			branch l
factorialo:	pop r0,(r15)
			return

			#d32 -1
table: