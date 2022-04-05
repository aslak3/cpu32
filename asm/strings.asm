SEVENSEG=0x10000000

			#d32 start

			halt
start:		load.l r15,#0x200

			load.l r0,#str1
			load.l r1,#str2
			calljump strcmp
			branchqeq match
			loadq.ws r0,#1
			branch out
match:		clear r0			
out:		store.l result,r0
			halt
			

; compare the strings at r0 and r1, setting zero if they are the same. r0 and
; r1 are preserved.

strcmp:		pushmulti (r15),R0|R1|R8|R9
.nextchar:	load.bu r8,(r0)						; get a char off first
			addq r0,#1							; next char on first
			test r8								; looking for nulls
			branchqeq .endcheck					; end of first?
			load.bu r9,(r1)						; get a char off second
			addq r1,#1							; next char on second
			compare r8,r9						; looking for same
			brancheq .nextchar					; keep looking
.nomatch:	andflags #0b1011					; clear zero: no match
			branchq .strcmpo					; done
.samestr:	orflags #0b0100						; set zero: match
.strcmpo:	popmulti R0|R1|R8|R9,(r15)
			return
.endcheck:	load.bu r9,(r1)						; get the end of second
			test r9								; looking for a null
			branchqne .nomatch					; not a null
			branchq .samestr					; found null, matched
			#d32 -1
result:		#d32 -1
			#d32 -1
str1:		#d "Test string 2\0"
str2:		#d "Test string 2\0"