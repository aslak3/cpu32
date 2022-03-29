			#d32 realstart
dontcall:	#d32 0

outter:		loadq.ws r10,#0x1234
			load.l r11,#0x5678
			clear r0
			not r0
			calljumpzs dontcall		; should not call
			andflags #0b1011		; force z to 0
			calljumpzs dontcall		; should not call
			callbranchq start		; call the inner
			return					; back to "main"

realstart:	load.l r15,#zero		; getting the sp
			loadq.l r15,(4,r15)		; stack pointer via LOADQRD
			load.l r8,#outter
			test r8
			calljumpzc (r8)			; call the outter sub
			load.l r0,#0xdeadbeef
			store.l lastlong,r0		; so we know exit good
hop:		branchq hop				; on return, hop
			swap r0
			store.l lastlong,r0		; if we somehow got here...
			halt

start:		pushmulti (r15),R10|R11
			loadq.ws r0,#-1			; canary - r0 is a bomb
			load.l r5,#zero			; the running total
			load.wu r5,(r5)
			load.wu r1,(done+8,r5)	; initial value
			loadq.ws r3,#0			; destination counter
			load.wu r4,length		; space for our fibs
			push (r15),r4			; test for pushquick
			clear r4				; ...
			pop r4,(r15)			; pop everything back
loop:		copy r2,r1				; copy the last written value
			add r1,r5				; accumulate
			jumpcs done				; enough for 32 bit? out
			copy r5,r2				; copy it back over the running total
			store.w (fib,r3),r1  	; save it in fib table using dest counter
			subq r3,#-2				; increment alternative
			sub r4,#1				; decrement the space for fibs counter
			branchne loop			; back if we have more room
done:		popmulti R10|R11,(r15)
			return					; finished inner sub
			#d16 0x1				; initial value
length:		#d16 22					; and the length (words)
zero:		#d16 0
			#d16 0
			#d32 0x200				; initial sp
mark:		#d32 0xffffffff

fib:

			#addr 0x3fc
lastlong:	#d32 -1