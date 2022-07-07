# 32 bit processor in VHDL

This is of course a work in progress.

# Rationale and motivation

I had a lot of fun working on my 16 bit softcore processor (https://github.com/aslak3/cpu), and thought it would be interesting to extend the design to a 32 bit processor.

* I'm one of those odd programmers who enjoys writing code in assembly. I want to produce an ISA which is pleasent to program in assembly, even if this means it does not perfom as well in other envirnoments, such as when it is the target of a C compiler.
* Saying that, it would be terrific to look at producing an LLVM target for this design. And with that in mind, it should have the necessary ISA features to make running C code reasonably efficent, providing it doesn't compromise the fun of writing code in assembly.
* Sitting between RISC and CISC is a nice place to be.
  * Stacking operations with multiple registers in one instruction is not very RISC like at all, and would certainly hinder a future pipelined design. None the less it's a big programmer convience.
  * On the other hand, being a load/store based processor has obvious benifits.
* I'm happy to borrow ideas from other designs.
* An eventual goal is to look at introducing a pipeline, though this may entail a partial or even complete redisgn of the ISA and a scrapping of most of this implementation itself.
  * This project is also a good place to explore my interest in processor design. For instance, it would be interesting to look at switching to a microcoded control unit, just for the experience of doing so.
* This seems like a nice logic block to use to explore other areas of computer systems design, such as memory controllers for SDRAM etc.

# Summary of features so far implemented

## General

* 32 bit address and databuses
* 32 bit instruction word
* 16 x 32 bit general purpose registers
* 32 bit Program Counter
* No microcode: a coded state machine is used
* CustomASM (https://github.com/hlorenzi/customasm) is the current assembler

## Memory

* Long, Word and Byte size memory accesses, with signed/unsigned extension on byte  and word reads
  - Bus error signal on unaligned word transfers
* Memory currenly must be 32 bits wide

## Instructions

* Some opcodes (like LOADI, JUMPs, BRANCHes, ALUMI, CALLs) have one following immediate value or address
* Load an immediate 32 bit quantity into a register found, the value being found at the following longword in the instruction stream
* Load the lower 16 bit portion into a register using a single instruction longword, the value is sign extended to 32 bits
* Load and store instructions operate either through a register, a register with an immediate displacement, the program counter with an immediate displacement, or an immediate memory address. Displacements may either be found in the following longword or an integrated (termed "quick" in the ISA) 12 bit quantity, which is sign extended.
* Clear instruction as assembler nicety, which uses a quick load of zero
* Simple status bits: zero, negative, carry and overflow
* ALU operations including
  - add, add with carry, subtract, subtract with carry, signed and unsigned 8 bit to 16 bit multiply, and, or, xor, not, shift left, shift right, copy, negation, sign extensions, etc
* ALU operations are of the form DEST <= OPERAND1 op OPERAND2, or DEST <= op OPERAND
  - ALUMI operates with an immediate longword operand extrated from the instruction stream, eg. add r0,r1,#123
  - ALUMQ operates with an embedded sign exteded 12 bit quantity inside the instruction word, eg. addq r0,r1,#2
  - Assembler provides shorthand versions, eg: add r0,#123 which is the same as: add r0,r0,#123
* Flow control, including calling subroutines and return: borrows the 15 conditions from ARM
  - Jump and call subroutine through register
  - Branch either with a 32 bit displacement or with a quick 12 bit displacement
  - Return can also be conditional
* Flags (currently just the four condition codes) can be manually ORed/ANDed
* Nop and Halt instructions
* Register to register copy

## Stack

* Push and pop a single register eg: push (r15),r0 pushes r0 onto r15
* push and pop multiple registers eg: pushmulti (r15),R1|R3|R5 - pushes r1, r3 and r5 onto r15 in sequence, decrementing it by 12

# Started

* Register File, Program Counter, Instruction Register
* ALU
* Bus Interface
* Control Unit (no testbench as yet)
* DataPath and external entity
* Simulation environment

# TODO

* Expose condition code register to allow it to be stacked/transferred to a register
* Test bench for control unit
* Integration into FPGA environment
* Interrupts
* Support for narrower then 32 bit IO/memory ports
* Start thinking about supervisor level access
* ...

# Instruction formats

## Base - Prefix 0x0

* 31 downto 24 : opcode (NOP, HALT, ORFLAGS, ANDFLAGS)
* 15 downto 0 : what to load (ORFLAGS, ANDFLAGS)

## Load Immedaite Long, Word quick - Prefix 0x1

* 31 downto 24 : opcode (LOADLI, LOADWSQ)
* 23 downto 20 : destination register
* 15 downto 0 : what to load (LOADWSQ)

## Other Load and Stores - Prefix 0x2

* 31 downto 24 : opcode (LOADR, STORER, LOADM, STORM, LOADRD, STORERD, LOADPCD, STOREPCD, LOADRDQ, STORERDQ, LOADQPCD, STOREPCDQ)
* 23 downto 20 : register
* 19 downto 16 : address register (not LOADM, STOREM, LOADPCD*, STOREPCD*)
* 15 downto 13 : transfer type
* 11 downto 0 : quick displacement (Q only)

## Flow control - Prefix 0x3

* 31 downto 24 : opcode (JUMP, BRANCH, BRANCHQ, JUMPR, CALLJUMP, CALLBRANCH, CALLBRANCHQ, CALLJUMPR, RETURN)
* 23 downto 20 : new program counter register (JUMPR, CALLJUMPR)
* 19 downto 16 : stack register (for CALL*, RETURN)
* 15 downto 12 : condition
* 11 downto 0 : quick displacement (BRANCHQ, CALLBRANCHQ ony)

## ALU operations - Prefix 0x4

* 31 downto 24 : opcode (ALUM, ALUMI, ALUS)
* 23 downto 20 : destination register
* 19 downto 16 : operand register2
* 15 downto 12 : operation code
* 11 downto 8 : operand register3 (ALUM only)

## ALUQ operations - Prefix 0x5

* 31 downto 24 : opcode (ALUMQ)
* 23 downto 20 : destination register
* 19 downto 16 : operand register2
* 15 downto 12 : operation code
* 11 downto 0 : quick immediate value

## Push and Pop including Multiple - Prefix 0x6

* 31 downto 24 : opcode (PUSH, POP, PUSHMULTI, POPMULTI)
* 23 downto 20 : what to push/pop (PUSH, POP)
* 19 downto 16 : stack register
* 15 downto 0 : register mask (PUSHMULTI, POPMULTI)

## Copy registers - Prefix 0x7

* 31 downto 24 : opcode (COPY)
* 23 downto 20 : destination
* 19 downto 16 : source

# Opcode details

<table>
<tr>
<th>Opcode</th>
<th>VHDL code</th>
<th>Extension longword</th>
<th>Processor cycles</th>
<th>Description</th>
</tr>
<tr>
<td>0x01</td>
<td>NOP</td>
<td>-</td>
<td>3</td>
<td>Does nothing for one instruction</td>
</tr>
<tr>
<tr>
<td>0x02</td>
<td>HALT</td>
<td>-</td>
<td>3 + forever</td>
<td>Stops the processor and asserts HALT signal</td>
</tr>
<tr>
<td>0x03</td>
<td>ORFLAGS</td>
<td>-</td>
<td>3</td>
<td>Flags := Flags OR quick value</td>
</tr>
<tr>
<td>0x04</td>
<td>ANDFLAGS</td>
<td>-</td>
<td>3</td>
<td>Flags := Flags AND quick value</td>
</tr>
<tr>
<td>0x10</td>
<td>LOADLI</td>
<td>Long value</td>
<td>3</td>
<td>rN := Long value</td>
</tr>
<tr>
<td>0x11</td>
<td>LOADQWS</td>
<td>-</td>
<td>3</td>
<td>rN := sign extended quick word</td>
<tr>
<td>0x20</td>
<td>LOADR</td>
<td>-</td>
<td>3</td>
<td>rN := (rA)</td>
</tr>
<tr>
<td>0x21</td>
<td>STORER</td>
<td>-</td>
<td>3</td>
<td>(rA) := (rN)</td>
</tr>
<tr>
<td>0x22</td>
<td>LOADM</td>
<td>Memory address</td>
<td>4</td>
<td>rN := (Memory address)</td>
</tr>
<tr>
<td>0x23</td>
<td>STOREM</td>
<td>Memory address</td>
<td>4</td>
<td>(Memory address) := rN</td>
</tr>
<tr>
<td>0x24</td>
<td>LOADRD</td>
<td>Memory displacement</td>
<td>4</td>
<td>rN := (rA + Memory displacement)</td>
</tr>
<tr>
<td>0x25</td>
<td>STORERD</td>
<td>Memory dispalcement</td>
<td>4</td>
<td>(rA + Memory displacement) := rN</td>
</tr>
<tr>
<td>0x26</td>
<td>LOADRDQ</td>
<td>-</td>
<td>4</td>
<td>rN := (rA + quick memory displacement)</td>
</tr>
<tr>
<td>0x27</td>
<td>STORERDQ</td>
<td>-</td>
<td>4</td>
<td>(rA + quick memory displacement) := rN</td>
</tr>
<tr>
<td>0x28</td>
<td>LOADPCD</td>
<td>Memory displacement</td>
<td>4</td>
<td>rN := (PC + Memory displacement)</td>
</tr>
<tr>
<td>0x29</td>
<td>STOREPCD</td>
<td>Memory dispalcement</td>
<td>4</td>
<td>(PC + Memory displacement) := rN</td>
</tr>
<tr>
<td>0x2a</td>
<td>LOADPCDQ</td>
<td>-</td>
<td>4</td>
<td>rN := (PC + quick memory displacement)</td>
</tr>
<tr>
<td>0x2b</td>
<td>STOREPCDQ</td>
<td>-</td>
<td>4</td>
<td>(PC + quick memory displacement) := rN</td>
</tr>
<tr>
<td>0x30</td>
<td>JUMP</td>
<td>Memory address</td>
<td>3</td>
<td>If condition -> PC := Memory address</td>
</tr>
<tr>
<td>0x31</td>
<td>BRANCH</td>
<td>Memory displacement</td>
<td>4</td>
<td>If condition -> PC := PC + Memory displacement</td>
</tr>
<tr>
<td>0x32</td>
<td>BRANCHQ</td>
<td>-</td>
<td>4</td>
<td>If condition -> PC := PC + quick memory displacement</td>
</tr>
<tr>
<td>0x33</td>
<td>CALLJUMP</td>
<td>Memory address</td>
<td>5</td>
<td>If condition -> rSP := rSP - 4 ; (rSP) := PC ; PC := Memory address</td>
</tr>
<tr>
<td>0x34</td>
<td>CALLBRANCH</td>
<td>Memory displacement</td>
<td>5</td>
<td>If condition -> rSP := rSP - 4 ; (rSP) := PC ; PC := PC + Memory displacement</td>
</tr>
<tr>
<td>0x35</td>
<td>CALLBRANCHQ</td>
<td>-</td>
<td>5</td>
<td>If condition -> rSP := rSP - 4 ; (rSP) := PC ; PC := PC + Quick memory displacement</td>
</tr>
<tr>
<td>0x36</td>
<td>JUMPR</td>
<td>-</td>
<td>3</td>
<td>If condition -> PC := rN</td>
</tr>
<tr>
<td>0x37</td>
<td>CALLJUMPR</td>
<td>-</td>
<td>5</td>
<td>If condition -> rSP := rSP - 4 ; (rSP) := PC ; PC := rN</td>
</tr>
<tr>
<td>0x38</td>
<td>RETURN</td>
<td>-</td>
<td>3</td>
<td>If condition -> PC := (rSP) ; rSP := rSP + 4 </td>
</tr>
<tr>
<td>0x40</td>
<td>ALUM</td>
<td>-</td>
<td>3</td>
<td>rD := rOP2 operation rOP3</td>
</tr>
<tr>
<td>0x42</td>
<td>ALUMI</td>
<td>Operand</td>
<td>3</td>
<td>rD := rOP2 operation operand</td>
</tr>
<tr>
<td>0x49</td>
<td>ALUMS</td>
<td>-</td>
<td>3</td>
<td>rD := operation rOP2</td>
</tr>
<tr>
<td>0x50</td>
<td>ALUMQ</td>
<td>-</td>
<td>3</td>
<td>rD := rOP2 operation Quick operand</td>
</tr>
<tr>
<td>0x60</td>
<td>PUSH</td>
<td>-</td>
<td>4</td>
<td>rSP := rSP - 4 ; (rSP) := rN</td>
</tr>
<td>0x61</td>
<td>POP</td>
<td>-</td>
<td>3</td>
<td>rN := r(SP) ; rSP := rSP + 4</td>
</tr>
<tr>
<td>0x62</td>
<td>PUSHMULTI</td>
<td>-</td>
<td>3 + rN count * 2</td>
<td>for each rN set do: rSP := rSP - 4 ; (rSP) := rN</td>
</tr>
<td>0x61</td>
<td>POPMULTI</td>
<td>-</td>
<td>3 + rN count * 2</td>
<td>for each rN set do: rN := r(SP) ; rSP := rSP + 4</td>
</tr>
</tr>
<td>0x70</td>
<td>COPY</td>
<td>-</td>
<td>3</td>
<td>rD := rS</td>
</tr>
</table>

## Condition flags

<table>
<tr>
<th>3</td>
<th>2</td>
<th>1</td>
<th>0</td>
</tr>
<td>V: Oerflow</td>
<td>C: Carry</td>
<td>Z: Zero</td>
<td>N: Negative</td>
</tr>
</table>

## Conditions (jumps, branches, and return)

<table>
<tr>
<th>Hex value</th>
<th>Assembly postfix</th>
<th>Description</th>
<th>Meaning</th>
</tr>
<tr>
<td>1</td>
<td>eq AKA zs</td>
<td>Equal / equals zero</td>
<td>Z</td>
</tr>
<tr>
<td>2</td>
<td>ne AKA zc</td>
<td>Not equal</td>
<td>!Z</td>
</tr>
<tr>
<td>3</td>
<td>cs</td>
<td>Carry set</td>
<td>C</td>
</tr>
<tr>
<td>4</td>
<td>cc</td>
<td>Carry clear</td>
<td>!C</td>
</tr>
<tr>
<td>5</td>
<td>mi</td>
<td>Minus</td>
<td>N</td>
</tr>
<tr>
<td>6</td>
<td>pl</td>
<td>Plus</td>
<td>!N</td>
</tr>
<tr>
<td>7</td>
<td>vs</td>
<td>Overflow</td>
<td>V</td>
</tr>
<tr>
<td>8</td>
<td>vc</td>
<td>No overflow</td>
<td>!V</td>
</tr>
<tr>
<td>9</td>
<td>hi</td>
<td>Unsigned higher</td>
<td>!C and !Z</td>
</tr>
<tr>
<td>A</td>
<td>ls</td>
<td>Unsigned lower or same</td>
<td>C or Z</td>
</tr>
<tr>
<td>B</td>
<td>ge</td>
<td>Signed greater than or equal</td>
<td>N == V</td>
</tr>
<tr>
<td>C</td>
<td>lt</td>
<td>Signed less than</td>
<td>N != V</td>
</tr>
<tr>
<td>D</td>
<td>gt</td>
<td>Signed greater than</td>
<td>!Z and (N == V)</td>
</tr>
<tr>
<td>E</td>
<td>le</td>
<td>Signed less than or equal</td>
<td>Z or (N != V)</td>
</tr>
<tr>
<td>0, F</td>
<td>al</td>
<td>Always</td>
<td>any</td>
</tr>
</tbody>
</table>

## Registers

<table>
<tr>
<td>0b0000</td>
<td>r0</td>
</tr>
<tr>
<td>0b0001</td>
<td>r1</td>
</tr>
<tr>
<td>...</td>
<td>...</td>
</tr>
<tr>
<td>0b1110</td>
<td>r14</td>
</tr>
<tr>
<td>0b1111</td>
<td>r15</td>
</tr>
</table>

## Transfer types

<table>
<tr>
<th>Value</th>
<th>Transfer size and extension mode (loads only)</th>
</tr>
<tr>
<td>0b000</td>
<td>Byte unsigned</td>
</tr>
<tr>
<td>0b001</td>
<td>Word unsigned</td>
</tr>
<tr>
<td>0b010</td>
<td>Long unsigned</td>
</tr>
<tr>
<td>0b011</td>
<td>Reserved</td>
</tr>
<tr>
<td>0b100</td>
<td>Byte unsigned</td>
</tr>
<tr>
<td>0b101</td>
<td>Word signed</td>
</tr>
<tr>
<td>0b110</td>
<td>Long</td>
</tr>
<tr>
<td>0b111</td>
<td>Reserved</td>
</tr>
</table>

## ALU multi (destination and operand) operations

<table>
<tr>
<td>0b0000</td>
<td>Add</td>
</tr>
<tr>
<td>0b0001</td>
<td>Add with cary</td>
</tr>
<tr>
<td>0b0010</td>
<td>Subtract</td>
</tr>
<tr>
<td>0b0011</td>
<td>Subtract with borrow</td>
</tr>
<tr>
<td>0b0100</td>
<td>Bitwise AND</td>
</tr>
<tr>
<td>0b0101</td>
<td>Bitwise OR</td>
</tr>
<tr>
<td>0b0110</td>
<td>Bitwise XOR</td>
</tr>
<tr>
<td>0b0111</td>
<td>Copy (does not update flags)</td>
</tr>
<tr>
<td>0b1000</td>
<td>Compare</td>
</tr>
<tr>
<td>0b1001</td>
<td>Bitwise test</td>
</tr>
<tr>
<td>0b1010</td>
<td>Unsigned 16 bit to 32 bit multiply</td>
</tr>
<tr>
<td>0b1011</td>
<td>Signed 16 bit to 32 bit multiply</td>
</tr>
<tr>
<td>0b1100-0b1111
<td>Unused</td>
</tr>
</table>

## ALU single (destination only) operations

<table>
<tr>
<td>0b0000</td>
<td>Increment</td>
</tr>
</tr>
<td>0b0001</td>
<td>Decrement</td>
</tr>
<tr>
<td>0b0010</td>
<td>Bitwise NOT</td>
</tr>
<tr>
<td>0b0011</td>
<td>Logic shift left</td>
</tr>
<tr>
<td>0b0100</td>
<td>Logic shift right</td>
</tr>
<tr>
<td>0b0101</td>
<td>Arithmetic shift left</td>
</tr>
<tr>
<td>0b0110</td>
<td>Arithmetic shift right</td>
</tr>
<tr>
<td>0b0111</td>
<td>Negation</td>
</tr>
<tr>
<td>0b1000</td>
<td>Byte swap</td>
</tr>
<tr>
<td>0b1001</td>
<td>Compare with zero</td>
</tr>
<tr>
<td>0b1010</td>
<td>Sign extend word</td>
</tr>
<tr>
<td>0b1011</td>
<td>Sign extend byte</td>
</tr>
<tr>
<td>0b1100-0b1111
<td>Unused</td>
</tr>
</table>

# Sample code

The currently used [CustomASM](https://github.com/hlorenzi/customasm) CPU definition makes it possible to
write very presentable assembly by, for example, combing LOADI, LOADM, LOADR and LOADRD into a single "load"
mnemonic with the width represented by .l, .ws, .wu, .bs or .bu. ALU operations are similarly represented.

```asm
            #d32 start                    ; reset vector

start:      load.l r15,#0x200             ; setup the stack pointer
            loadq.ws r0,#1                ; intiail factorial
            loadq.ws r3,#9                ; getting 1 to this number
            load.l r2,#table              ; output pointer
loop:       calljump factorial            ; get the factorial for r0 in r1
            store.l (r2),r1               ; save it in the table
            addq r2,#4                    ; move to the next row
            addq r0,#1                    ; inc the number we are calculating
            compare r0,r3                 ; got all the factorials?
            branchqne loop                ; no? loop again
            halt                          ; stop the proc

factorial:  push (r15),r0                 ; save the param, we will use it
            copy r1,r0                    ; start from this value
l:          subq r0,#1                    ; loop counter
            branchzs factorialo           ; done?
            mulu r1,r0,r1                 ; multiply running total by previous
            branch l                      ; get the next one
factorialo: pop r0,(r15)                  ; restore the original param
            return                        ; done

            #d32 -1                        ; start of table marker
table:                                     ; table of output goes here
