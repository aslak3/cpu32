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
* Load the lower 16 bit portion in one instruction word, sign extended to 32 bits
* Load and store instructions operate either through a register, an immediate address or a register with an immediate displacement, or the program counter with an immediate displacement. Immediate displacements may either be a following long or an integrated byte, which is sign extended.
* Clear instruction
* Simple status bits: zero, negative, carry and overflow
* ALU operations including
  - add, add with carry, subtract, subtract with carry, signed and unsigned 8 bit to 16 bit multiply, increment, decrement, and, or, xor, not, shift left, shift right, copy, negation, etc
* ALU operations are of the form DEST <= OPERAND1 op OPERAND2, or DEST <= op OPERAND
  - ALUMI operates with an immediate operand, eg. add r0,r1,#123
  - ALUMQ operates with an integrated sign exteded byte inside the instruciton word, eg. addq r0,r1,#2
* Conditional and uncoditional jumps and branches: always, on each flag set or clear with don't cares
* Nop and Halt instructions
* Stacking: call/return
  - conditional using the same mechanism as branching, eg callbranchz subroutine
* Stacking: psuh and pop a single register, push and pop multiple registers eg: push r0,r1+r3+r5 - push r1, r3 and r5 onto r0.
* No microcode: a coded state machine is used
* CustomASM (https://github.com/hlorenzi/customasm) is the current assembler

# Started

* Register File, Program Counter, Instruction Register
* ALU
* Bus Interface
* Control Unit (no testbench as yet)
* DataPath and external entity
* Simulation environment

# TODO

* Expose condition code register and allow it to be altered by code/stacked
* ...
* Test bench for control unit
* Integration into FPGA environment

# Instruction formats

## Base - Prefix 0x0

* 31 downto 24 : opcode (NOP, HALT)

## Load Immedaite Long, Word quick and Clear - Prefix 0x1

* 31 downto 24 : opcode (LOADLI, LOADWSQ, CLEAR)
* 23 downto 20 : destination register
* 15 downto 0 : what to load (LOADWSQ)

## Other Load and Stores - Prefix 0x2

* 31 downto 24 : opcode (LOADR, STORER, LOADM, STORM, LOADRD, STORERD, LOADPCD, STOREPCD, LOADRDQ, STORERDQ, LOADQPCD, STOREPCDQ)
* 23 downto 20 : register
* 19 downto 16 : address register (not LOADM, STOREM, LOADPCD*, STOREPCD*)
* 15 downto 13 : transfer type
* 7 downto 0 : quick displacement (Q only)

## Flow control - Prefix 0x3

* 31 downto 24 : opcode (JUMP, BRANCH, JUMPR, CALLJUMP, CALLBRANCH, CALLJUMPR, RETURN)
* 23 downto 20 : new program counter register (JUMPR, CALLJUMPR)
* 19 downto 16 : stack register (for CALL*, RETURN)
* 15 downto 12 : flag mask
* 11 downto 8 : flag match

## ALU operations - Prefix 0x4

* 31 downto 24 : opcode (ALUM, ALUMI, ALUMQ, ALUS)
* 23 downto 20 : destination register
* 19 downto 16 : operand register2
* 15 downto 12 : operand register3 (ALUM only)
* 11 downto 8 : operation code
* 7 downto 0 : quick immediate value (ALUMQ only)

## Push and Pop including Multiple - Prefix 0x5

* 31 downto 24 : opcode (PUSH, POP, PUSHMULTI, POPMULTI)
* 23 downto 20 : what to push/pop (PUSH, POP)
* 19 downto 16 : stack register
* 15 downto 0 : register mask (PUSHMULTI, POPMULTI)

# Opcode details

<table>
<tr>
<th>Opcode</th>
<th>VHDL code</th>
<th>Extension word function</th>
<th>Description</th>
</tr>
<tr>
<td>0x01</td>
<td>NOP</td>
<td>-</td>
<td>Does nothing for one instruction</td>
</tr>
<tr>
<tr>
<td>0x02</td>
<td>HALT</td>
<td>-</td>
<td>Stops the processor and asserts HALT signal</td>
</tr>
<tr>
<td>0x10</td>
<td>LOADLI</td>
<td>VALUE</td>
<td>rN := #xx long</td>
</tr>
<tr>
<td>0x11</td>
<td>LOADQWS</td>
<td>-</td>
<td>rN := sign extended embedded #xx word</td>
</tr>
<td>0x12</td>
<td>CLEAR</td>
<td>-</td>
<td>rN := 0</td>
</tr>
<tr>
<td>0x20</td>
<td>LOADR</td>
<td>-</td>
<td>rN := (rM)</td>
</tr>
<tr>
<td>0x21</td>
<td>STORER</td>
<td>-</td>
<td>(rA) := (rN)</td>
</tr>
<tr>
<td>0x22</td>
<td>LOADM</td>
<td>Memory address</td>
<td>rN := (Memory address)</td>
</tr>
<tr>
<td>0x23</td>
<td>STOREM</td>
<td>Memory address</td>
<td>(Memory address) := rN</td>
</tr>
<tr>
<td>0x24</td>
<td>LOADRD</td>
<td>Memory displacement</td>
<td>rN := (rA + Memory displacement)</td>
</tr>
<tr>
<td>0x25</td>
<td>STORERD</td>
<td>Memory dispalcement</td>
<td>(rA + Memory displacement) := rN</td>
</tr>
<tr>
<td>0x26</td>
<td>LOADRDQ</td>
<td>-</td>
<td>rN := (rA + embedded memory displacement)</td>
</tr>
<tr>
<td>0x27</td>
<td>STORERDQ</td>
<td>-</td>
<td>(rA + Embedded memory displacement) := rN</td>
</tr>
<tr>
<td>0x28</td>
<td>LOADPCD</td>
<td>Memory displacement</td>
<td>rN := (PC + Memory displacement)</td>
</tr>
<tr>
<td>0x29</td>
<td>STOREPCD</td>
<td>Memory dispalcement</td>
<td>(PC + Memory displacement) := rN</td>
</tr>
<tr>
<td>0x2a</td>
<td>LOADPCDQ</td>
<td>-</td>
<td>rN := (PC + Embedded memory displacement)</td>
</tr>
<tr>
<td>0x2b</td>
<td>STOREPCDQ</td>
<td>-</td>
<td>(PC + Embedded memory displacement) := rN</td>
</tr>
<tr>
<td>0x30</td>
<td>JUMP</td>
<td>Memory address</td>
<td>If conditioncodes and mask = required -> PC := Memory address</td>
</tr>
<tr>
<td>0x31</td>
<td>BRANCH</td>
<td>Memory displacement</td>
<td>If conditioncodes and mask = required -> PC := PC + Memory displacement</td>
</tr>
<tr>
<td>0x32</td>
<td>CALLJUMP</td>
<td>Memory address</td>
<td>If conditioncodes and mask = required -> rSP := rSP - 4 ; (rSP) := PC ; PC := Memory address</td>
</tr>
<tr>
<td>0x33</td>
<td>CALLBRANCH</td>
<td>Memory displacement</td>
<td>If conditioncodes and mask = required -> rSP := rSP - 4 ; (rSP) := PC ; PC := PC + Memory displacement</td>
</tr>
<tr>
<td>0x34</td>
<td>JUMPR</td>
<td>-</td>
<td>If conditioncodes and mask = required -> PC := rN</td>
</tr>
<tr>
<td>0x35</td>
<td>CALLJUMPR</td>
<td>-</td>
<td>If conditioncodes and mask = required -> rSP := rSP - 4 ; (rSP) := PC ; PC := rN</td>
</tr>
<tr>
<td>0x36</td>
<td>RETURN</td>
<td>-</td>
<td>If conditioncodes and mask = required -> PC := (rSP) rSP := SP + 4 </td>
</tr>
<tr>
<td>0x40</td>
<td>ALUM</td>
<td>-</td>
<td>rD := rOP2 operation rOP3</td>
</tr>
<tr>
<td>0x41</td>
<td>ALUMI</td>
<td>Immediate operand</td>
<td>rD := rOP2 operation Immediate operand</td>
</tr>
<tr>
<td>0x42</td>
<td>ALUMQ</td>
<td>-</td>
<td>rD := rOP2 operation Quick operand</td>
</tr>
<tr>
<td>0x43</td>
<td>ALUMS</td>
<td>-</td>
<td>rD := operation rOP2</td>
</tr>
<tr>
<td>0x50</td>
<td>PUSH</td>
<td>-</td>
<td>rSP := rSP - 4 ; (rSP) := rN</td>
</tr>
<td>0x51</td>
<td>POP</td>
<td>-</td>
<td>rN := r(SP) ; rSP := rSP + 4</td>
</tr>
<tr>
<td>0x52</td>
<td>PUSHMULTI</td>
<td>-</td>
<td>for each rN set do: rSP := rSP - 4 ; (rSP) := rN</td>
</tr>
<td>0x51</td>
<td>POPMULTI</td>
<td>-</td>
<td>for each rN set do: rN := r(SP) ; rSP := rSP + 4</td>
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
mnemonic with the width represented by .l, .ws, .wu, .bs or .bu. ALU operations are similarly represented.

```asm
; ... TODO ..
