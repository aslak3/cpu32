			#d32 realstart
			halt

realstart:	load.l r0,#0xf00f		; canary - r0 is a bomb
			load.l r15,#0x200		; stack pointer(!)
			callbranch outter		; call the outter sub
hop:		branch hop				; on return, hop

outter:		calljump start			; call the inner
			return					; back to "main"

start:		load.l r5,#zero			; the running total
			load.wu r5,(r5)
			load.wu r1,(foo+4,r5)	; initial value
			load.l r3,#0			; destination counter
			load.wu r4,length		; space for our fibs
			push (r15),r4			; test for pushquick
			clear r4				; ...
			pop r4,(r15)			; pop everything back
loop:		copy r2,r1				; copy the last written value
			add r1,r5				; accumulate
			jumpc done				; overflow? out
			copy r5,r2				; copy it back over the running total
			store.w (fib,r3),r1  	; save it in fib table using dest counter
			add r3,#2				; increment alternative
			sub r4,#1				; decrement the space for fibs counter
			branchnz loop			; back if we have more room
done:		load.wu r5,(twoah,pc)	; just so we can test store
			store.w 0xc0,r5			; ...
			add r5,#0x0101
			store.w (twobee,pc),r5
			load.l r5,#0xaa55		; and storer
			load.l r1,#0x00c2		; ...
			store.w (r1),r5			; ...
foo:		return					; finished inner sub
			#d16 0x1				; initial value
length:		#d16 32					; and the length (words)
zero:		#d16 0
twoah:		#d16 0x2a2a
twobee:		#d16 0

fib:
