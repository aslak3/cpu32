# 32 bit processor in VHDL

This is of course a work in progress.

# Summary of planned features

* 32 bit address and databuses
* 32 bit opcodes
* Long, Word and Byte size memory accesses, with signed/unsigned extension on byte reads
  - Bus error signal on unaligned word transfers
* Some opcodes (like LOADI, JUMPs, BRANCHes, ALUMI, CALLs) have one following immediate value/address
* 16 x 32 bit general purpose registers
* 32 bit Program Counter
* Load an immediate 32 bit quantity at the following address
* Load the upper or lower 16 bit portion in one instruction word
* Load and store instructions operate either through a register, an immediate address or a register with an immediate displacement, or the program counter with an immediate displacement
* Clear instruction
* Simple status bits: zero, negative, carry and overflow
* ALU operations including
  - add, add with carry, subtract, subtract with carry, signed and unsigned 8 bit to 16 bit multiply, increment, decrement, and, or, xor, not, shift left, shift right, copy, negation, etc
* ALU operations are of the form DEST <= OPERAND1 op OPERAND2, or DEST <= op OPERAND
  - ALUMI operates with an immediate operand, eg. add r0,r1,#123
  - ALUMQ operates with a truncated immediate inside the instruciton word, eg. addq r0,r1,#2
* Conditional and uncoditional jumps and branches: always, on each flag set or clear with don't cares
* Nop and Halt instructions
* Stacking: call/return
  - conditional using the same mechanism as branching, eg callbranchz subroutine
* Stacking: push and pop multiple registers eg: push r0,r1+r3+r5 - push r1, r3 and r5 onto r0.
* No microcode: a coded state machine is used
* CustomASM (https://github.com/hlorenzi/customasm) is the current assembler

# TODO

* Everything.

# Instruction formats

## Base

* 31 downto 24 : opcode (NOP)

## Load Immedaite Long, Upper/Lower and Clear

* 31 downto 24 : opcode (LOADLI, LOADUWI, LOADLWI, CLEAR)
* 19 downto 16 : destination register
* 15 downto 0 : what to load (not CLEAR, LOADLI)

## Other Load and Stores

* 31 downto 24 : opcode (LOADR, STORER, LOADM, STORM, LOADRD, STORERD, LOADPCD, STOREPCD)
* 23 downto 20 : address register (not LOADM, STOREM, LOADPCD, STOREPCD)
* 19 downto 16 : register
* 15 downto 13 : transfer type

## Jump and Branch with Conditionals (including subroutine call/return)

* 31 downto 24 : opcode (BRANCH, JUMP, CALLBRANCH, CALLJUMP, RETURN)
* 23 downto 20 : stack register (for CALLBRANCH, CALLJUMP, RETURN)
* 15 downto 12 : flag mask
* 11 downto 8 : flag match

## ALU operations

* 31 downto 24 : opcode (ALUM, ALUMI, ALUMQ, ALUS)
* 23 downto 20 : destination register
* 19 downto 16 : operand register1
* 15 downto 12 : operand register2 (ALUM only)
* 11 downto 8 : operation code
* 7 downto 0 : quick immediate value (ALUMQ only)

## Push and Pop Multiple

* 31 downto 24 : opcode (PUSH, POP)
* 23 downto 20 : stack register
* 15 downto 0 : register mask

# Opcode details

<table>
<tr>
<th>Opcode</th>
<th>VHDL code</th>
<th>Extension word function</th>
<th>Description</th>
</tr>
<tr>
<td>0x00</td>
<td>NOP</td>
<td>-</td>
<td>Does nothing for one instruction</td>
</tr>
<tr>
<td>0x01</td>
<td>LOADLI</td>
<td>VALUE</td>
<td>rN := #xx</td>
</tr>
<tr>
<td>0x02</td>
<td>LOADUWI</td>
<td>-</td>
<td>rN := #xx & 0x0000</td>
</tr>
<tr>
<td>0x03</td>
<td>LOADLWI</td>
<td>-</td>
<td>rN := 0x0000 & #xx</td>
</tr>
<tr>
<td>0x04</td>
<td>CLEAR</td>
<td>-</td>
<td>rN := 0</td>
</tr>
<tr>
<td>0x05</td>
<td>LOADR</td>
<td>-</td>
<td>rN := (rM)</td>
</tr>
<tr>
<td>0x06</td>
<td>STORER</td>
<td>-</td>
<td>(rA) := (rN)</td>
</tr>
<tr>
<td>0x07</td>
<td>LOADM</td>
<td>Memory address</td>
<td>rN := (Memory address)</td>
</tr>
<tr>
<td>0x08</td>
<td>STOREM</td>
<td>Memory address</td>
<td>(Memory address) := rN</td>
</tr>
<tr>
<td>0x09</td>
<td>LOADRD</td>
<td>Memory displacement</td>
<td>rN := (rA + Memory displacement)</td>
</tr>
<tr>
<td>0x0a</td>
<td>STORERD</td>
<td>Memory dispalcement</td>
<td>(rA + Memory displacement) := rN</td>
</tr>
<tr>
<td>0x0b</td>
<td>LOADPCD</td>
<td>Memory displacement</td>
<td>rN := (PC + Memory displacement)</td>
</tr>
<tr>
<td>0x0c</td>
<td>STOREPCD</td>
<td>Memory dispalcement</td>
<td>(PC + Memory displacement) := rN</td>
</tr>
<tr>
<td>...</td>
<td>...</td>
<td>...</td>
<td>...</td>
</tr>
</table>

## Flag cares and flag polarity

<table>
<tr>
<td>3</td>
<td>2</td>
<td>1</td>
<td>0</td>
</tr>
<td>Overflow</td>
<td>Carry</td>
<td>Zero</td>
<td>Negative</td>
</tr>
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
<td>Byte uigned</td>
</tr>
<tr>
<td>0b101</td>
<td>Word signed</td>
</tr>
<tr>
<td>0b110</td>
<td>Long signed</td>
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
<td>Subtract with cary</td>
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
<td>Copy</td>
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
<td>Unsigned 8 bit to 16 bit multiply</td>
</tr>
<tr>
<td>0b1011</td>
<td>Signed 8 bit to 16 bit multiply</td>
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
<td>Double increment</td>
</tr>
<tr>
<td>0b0011</td>
<td>Double decrement</td>
</tr>
<tr>
<td>0b0100</td>
<td>Bitwise NOT</td>
</tr>
<tr>
<td>0b0101</td>
<td>Left shift</td>
</tr>
<tr>
<td>0b0110</td>
<td>Right shift</td>
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
<td>0b1010-0b1111
<td>Unused</td>
</tr>
</table>

# Sample code

The currently used [CustomASM](https://github.com/hlorenzi/customasm) CPU definition makes it possible to
write very presentable assembly by, for example, combing LOADI, LOADM, LOADR and LOADRD into a single "load"
mnemonic with the width represented by .w, .bu or .bs. ALU operations are similarly represented.

```asm
; ... TODO ..
