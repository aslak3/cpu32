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
* Load an immediate 32 bit quantity at the following longword address in the instruction stream
* Load the lower 16 bit portion in one instruction longword, sign extended to 32 bits
* Load and store instructions operate either through a register, a register with an immediate displacement, the program counter with an immediate displacement, or an immediate memory address. Displacements may either be found in the following longword or an integrated (termed "quick" in the ISA) byte, which is sign extended.
* Clear instruction as assembler nicety, which uses a quick load of zero
* Simple status bits: zero, negative, carry and overflow
* ALU operations including
  - add, add with carry, subtract, subtract with carry, signed and unsigned 8 bit to 16 bit multiply, and, or, xor, not, shift left, shift right, copy, negation, etc
* ALU operations are of the form DEST <= OPERAND1 op OPERAND2, or DEST <= op OPERAND
  - ALUMI operates with an immediate longword operand extrated from the instruction stream, eg. add r0,r1,#123
  - ALUMQ operates with an embedded sign exteded byte inside the instruction word, eg. addq r0,r1,#2
  - Assembler provides shorthand versions, eg: add r0,#123 is the same as: add r0,r0,#123
* Conditional and uncoditional flow control, including calling subroutines and return: always, on each flag set or clear with don't cares
* Flags (currently just the four condition codes) can be manually ORed/ANDed
* Nop and Halt instructions

## Stack

* Push and pop a single register eg: push (r15),r0 pushes r0 onto r15
* push and pop multiple registers eg: push (r0),R1|R3|R5 - pushes r1, r3 and r5 onto r15.

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
<td>rN := immediate long</td>
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
<td>If conditioncodes and mask = required -> PC := Memory address</td>
</tr>
<tr>
<td>0x31</td>
<td>BRANCH</td>
<td>Memory displacement</td>
<td>4</td>
<td>If conditioncodes and mask = required -> PC := PC + Memory displacement</td>
</tr>
<tr>
<td>0x32</td>
<td>CALLJUMP</td>
<td>Memory address</td>
<td>5</td>
<td>If conditioncodes and mask = required -> rSP := rSP - 4 ; (rSP) := PC ; PC := Memory address</td>
</tr>
<tr>
<td>0x33</td>
<td>CALLBRANCH</td>
<td>Memory displacement</td>
<td>5</td>
<td>If conditioncodes and mask = required -> rSP := rSP - 4 ; (rSP) := PC ; PC := PC + Memory displacement</td>
</tr>
<tr>
<td>0x34</td>
<td>JUMPR</td>
<td>-</td>
<td>3</td>
<td>If conditioncodes and mask = required -> PC := rN</td>
</tr>
<tr>
<td>0x35</td>
<td>CALLJUMPR</td>
<td>-</td>
<td>5</td>
<td>If conditioncodes and mask = required -> rSP := rSP - 4 ; (rSP) := PC ; PC := rN</td>
</tr>
<tr>
<td>0x36</td>
<td>RETURN</td>
<td>-</td>
<td>3</td>
<td>If conditioncodes and mask = required -> PC := (rSP) rSP := SP + 4 </td>
</tr>
<tr>
<td>0x40</td>
<td>ALUM</td>
<td>-</td>
<td>3</td>
<td>rD := rOP2 operation rOP3</td>
</tr>
<tr>
<td>0x41</td>
<td>ALUMI</td>
<td>Immediate operand</td>
<td>3</td>
<td>rD := rOP2 operation Immediate operand</td>
</tr>
<tr>
<td>0x42</td>
<td>ALUMQ</td>
<td>-</td>
<td>3</td>
<td>rD := rOP2 operation Quick operand</td>
</tr>
<tr>
<td>0x43</td>
<td>ALUMS</td>
<td>-</td>
<td>3</td>
<td>rD := operation rOP2</td>
</tr>
<tr>
<td>0x50</td>
<td>PUSH</td>
<td>-</td>
<td>4</td>
<td>rSP := rSP - 4 ; (rSP) := rN</td>
</tr>
<td>0x51</td>
<td>POP</td>
<td>-</td>
<td>3</td>
<td>rN := r(SP) ; rSP := rSP + 4</td>
</tr>
<tr>
<td>0x52</td>
<td>PUSHMULTI</td>
<td>-</td>
<td>3 + rN count * 2</td>
<td>for each rN set do: rSP := rSP - 4 ; (rSP) := rN</td>
</tr>
<td>0x51</td>
<td>POPMULTI</td>
<td>-</td>
<td>3 + rN count * 2</td>
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
<td>Left shift</td>
</tr>
<tr>
<td>0b0100</td>
<td>Right shift</td>
</tr>
<tr>
<td>0b0101</td>
<td>Negation</td>
</tr>
<tr>
<td>0b0110</td>
<td>Byte swap</td>
</tr>
<tr>
<td>0b0111</td>
<td>Compare with zero</td>
</tr>
<tr>
<td>0b1000-0b1111
<td>Unused</td>
</tr>
</table>

# Sample code

The currently used [CustomASM](https://github.com/hlorenzi/customasm) CPU definition makes it possible to
write very presentable assembly by, for example, combing LOADI, LOADM, LOADR and LOADRD into a single "load"
mnemonic with the width represented by .l, .ws, .wu, .bs or .bu. ALU operations are similarly represented.

```asm
; ... TODO ..
