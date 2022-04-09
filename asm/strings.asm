; calling conventions:
; r0-r7: parameters (maybe stacked)
; r8-13: temps (always stacked)
; r13: optional additional return value
; r14: return value
; r15: stack pointer

; compare the strings at r0 and r1, setting zero if they are the same. r0 and
; r1 are preserved. r14 will bave 0 for match, 1 otherwise.

strcmp:			pushmulti (r15),R0|R1|R8|R9
.nextchar:		load.bu r8,(r0)						; get a char off first
				addq r0,#1							; next char on first
				test r8								; looking for nulls
				branchqeq .endcheck					; end of first?
				load.bu r9,(r1)						; get a char off second
				addq r1,#1							; next char on second
				compare r8,r9						; looking for same
				brancheq .nextchar					; keep looking
.nomatch:		andflags #0b1011					; clear zero: no match
				loadq.ws r14,#1						; set 1 in result
				branchq .strcmpo					; done
.samestr:		orflags #0b0100						; set zero: match
				clear r14							; set 0 in result
.strcmpo:		popmulti R0|R1|R8|R9,(r15)
				return
.endcheck:		load.bu r9,(r1)						; get the end of second
				test r9								; looking for a null
				branchqne .nomatch					; not a null
				branchq .samestr					; found null, matched

; return the length of the string at r0 in r14

strlen:			pushmulti (r15),R0|R8				; save the params plus temp
				copy r14,r0							; record string pointer on start
.loop:			load.bu r8,(r0)						; get the char
				test r8								; looking for nulls
				branchqeq .strleno					; got a null, done
				addq r0,#1							; inc pointer
				branchq .loop						; back to the next char
.strleno:		sub r14,r0,r14						; calculate length using saved ptr
				popmulti R0|R8,(r15)				; restore param and temp
				return

; converts the string at r0 to a integer. r14 will hold the value, r13 will hold
; the type (1=byte, 2=word, 3=long). on error r13 will be 0. r0 will point to
; to the first non printable char.

asciitoint:		pushmulti (r15),R8
				clear r8							; set resul to zero
				clear r13							; clear digit counter
				clear r14
				branchq .three						; branch into loop
.one:			subq r8,#0x30						; subtract '0'
				branchqlt .four						; <0? bad
				compare r8,#9						; <=9?
				branchqls .two						; yes? we are dne with this
				subq r8,#7							; A - :
				branchqlt .four						; <0? bad
				compare r8,#0x10					; see if its uppercase
				branchqlt .two						; was uppercase
				subq r8,#0x20						; a - A
				compare r8,#0x10					; compare with upper range
				branchqge .four						; >15? bad
.two:			logicleft r14
				logicleft r14
				logicleft r14
				logicleft r14						; shift result to next nybble
				add r14,r8							; accumulate number
				addq r13,#1							; inc digit counter
				nop
				compare r13,#8						; too many digits?
				branchqgt .four						; yes? bad
.three:			load.bu r8,(r0)						; get the next character
				addq r0,#1							; move pointer along
				compare r8,#0x21					; see if its a nonwsp char
				branchqls .five						; yes? then we are done
				branchq .one						; back for more igits
.four:			clear r13							; mark 0 digits
				clear r14							; set result to 0 as well
.five:			load.bu r13,(datatypes,r13)			; translate to type
				subq r0,#1							; wind back to space char
				popmulti R8,(r15)
				return
			
datatypes:		#d8 0								; 0

				#d8 1								; 1
				#d8 1								; 2

				#d8 2								; 3
				#d8 2								; 4

				#d8 3								; 5
				#d8 3								; 6
				#d8 3								; 7
				#d8 3								; 8
				
				#align 32

; converts the byte in r0 to hex, writing it into r1 and advancing it two bytes.
; r0 is stacked.
				
bytetoascii:	push (r15),r0
				logicright r0						; get the left most nybble
				logicright r0
				logicright r0
				logicright r0
				compare r0,#10						; seeing if < 10
				branchqlt .one						; yes?
				addq r0,#0x31-10					; add 'a' less '0' less 10
.one:			addq r0,#0x30						; add '0' too
				store.b (r1),r0						; save the digit
				addq r1,#1							; advance pointer
				load.l r0,(r15)						; get byte back
				andq r0,#0x0f						; mask off the already done left nyb
				compare r0,#10						; less than 10?
				branchqlt .two						; yes, only add '0'
				addq r0,#0x31-10					; add 'a' less '0' less 10
.two:			addq r0,#0x30						; add '0' too
				store.b (r1),r0						; save the digit
				addq r1,#1							; advance pointer
				clear r0							; add a null..
				store.b (r1),r0						; but don't advance
				pop r0,(r15)
				return
				
; convert the word in r0 to hex, writing it into r1 and adnvancing it four bytes.
; r0 is stacked

wordtoascii:	push (r15),r0
				logicright r0						; get the left most byte
				logicright r0
				logicright r0
				logicright r0
				logicright r0
				logicright r0
				logicright r0
				logicright r0
				callbranchq bytetoascii				; convert that byte
				load.l r0,(r15)						; get the word back
				callbranchq bytetoascii				; convert that byte
				pop r0,(r15)
				return

; convert the long in r0 to hex, writing it into r1 and adnvancing it four bytes.
; r0 is stacked

longtoascii:	push (r15),r0
				swap r0								; exchange halves
				callbranchq wordtoascii				; convert that byte
				load.l r0,(r15)						; get the word back
				callbranchq wordtoascii				; convert that byte
				pop r0,(r15)
				return

