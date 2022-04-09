SEVENSEG =		0x10000000
UARTSTATUS =	0x20000000
UARTDATA =		0x30000000

ASC_BS = 		0x08
ASC_LF =		0x0a
ASC_CR =		0x0d
ASC_SP =		0x20

				#d32 start

				#include "strings.asm"
				
				halt
start:			load.l r15,#0x2000
.loop:			load.l r0,#promptmsg
				calljump putstr
				load.l r0,#buffer
				calljump getstr
				load.l r0,#replymsg
				calljump putstr
				load.l r0,#buffer
				calljump putstr
				branchq .loop

;;;;;;;
	
putstr:			push (r15),r8
				copy r8,r0
.loop:			load.bu r0,(r8)
				callbranchq putchar
				addq r8,#1
				test r0
				branchne .loop
				pop r8,(r15)
				return

putchar:		push (r15),r8
.loop:			load.l r8,UARTSTATUS
				bit r8,#0x04
				branchqeq .loop
				store.b UARTDATA+3,r0
				pop r8,(r15)
				return

getstr:			pushmulti (r15),R8|R9
				clear r9								; the length
				copy r8,r0								; copy of arg
.loop:			callbranchq getchar						; get a char in r8
				compare r14,#ASC_CR						; looking for a new line
				branchqeq .out							; done
				compare r14,#ASC_LF						; looking for a new line
				branchqeq .out							; done
				compare r14,#ASC_BS						; backspace
				branchqeq .backspace					; handle it
				store.b (r8),r14						; save it in r0
				addq r8,#1								; move r8 along
				addq r9,#1								; increment the length
.echo:			copy r0,r14								; copy of what we read
				callbranchq putchar						; echo the char
				branchq .loop 							; back for more
.out:			clear r14								; writing a null
				store.b (r8),r14						; save the null
				load.l r0,#newlinemsg					; tidy up
				callbranchq putstr						; with a new line
				popmulti R8|R9,(r15)
				return
.backspace:		test r9									; got nothing
				branchqeq .loop							; yes? then nothing to do
				subq r9,#1								; make str shorter
				clear r14								; need a null
				store.b (r8),r14						; save it in the string
				subq r8,#1								; move pointer back
				loadq.ws r0,#ASC_BS						; set a backspace to send
				callbranchq putchar						; send it
				loadq.ws r0,#ASC_SP						; and a space
				callbranchq putchar						; send it
				loadq.ws r0,#ASC_BS						; another backspace to send
				callbranchq putchar						; send it
				branchq .loop							; more chars please

getchar:		load.l r14,UARTSTATUS					; get status
				bit r14,#0x01							; rx ready
				branchqeq getchar						; back for more
				load.bu r14,UARTDATA+3					; get the char
				return
			
promptmsg:		#d "\r\nEnter a string: \0"
replymsg:		#d "You typed: \0"
newlinemsg:		#d "\r\n\0"
buffer:			#res 256

				#d32 0
longword:		#d32 0
