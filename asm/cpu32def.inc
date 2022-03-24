#bits 8

R0  = 0b0000000000000001
R1  = 0b0000000000000010
R2  = 0b0000000000000100
R3  = 0b0000000000001000
R4  = 0b0000000000010000
R5  = 0b0000000000100000
R6  = 0b0000000001000000
R7  = 0b0000000010000000
R8  = 0b0000000100000000
R9  = 0b0000001000000000
R10 = 0b0000010000000000
R11 = 0b0000100000000000
R12 = 0b0001000000000000
R13 = 0b0010000000000000
R14 = 0b0100000000000000
R15 = 0b1000000000000000

#subruledef reg
{
	r0  => 0
	r1  => 1
	r2  => 2
	r3  => 3
	r4  => 4
	r5  => 5
	r6  => 6
	r7  => 7
	r8  => 8
	r9  => 9
	r10 => 10
	r11 => 11
	r12 => 12
	r13 => 13
	r14 => 14
	r15 => 15
}
#subruledef loadtype
{
	bu => 0b000
	wu => 0b010
	bs => 0b001
	ws => 0b011
	l  => 0b100
}
#subruledef storetype
{
	b => 0b000
	w => 0b010
	l => 0b100
}
#subruledef condition
{
	nz => 0b01000000
	z  => 0b01000100
	nc => 0b10000000
	c  => 0b10001000
	nn => 0b00100000
	n  => 0b00100010
}
#subruledef twoargalu
{
	add     => 0x0
	addc    => 0x1
	sub     => 0x2
	subc    => 0x3
	and     => 0x4
	or      => 0x5
	xor     => 0x6
	copy    => 0x7
	compare => 0x8
	bit     => 0x9
	mulu    => 0xa
	muls    => 0xb
}
#subruledef oneargalu
{
	inc        => 0x0
	dec        => 0x1
	not        => 0x2
	logicleft  => 0x3
	logicright => 0x4
	arithleft  => 0x5
	arithright => 0x6
	negate     => 0x7
	swap       => 0x8
	test       => 0x9
}

#ruledef
{
	nop => 0x01 @ 0x000000
	halt => 0x02 @ 0x000000

	load.l {dst:reg}, #{value} =>
		0x10 @ dst[3:0] @ 0x0 @ 0x0000 @ value[31:0]
	loadq.ws {dst:reg}, #{value} =>
		0x11 @ dst[3:0] @ 0x0 @ value[15:0]
	clear {dst:reg} =>
		0x12 @ dst[3:0] @ 0x0 @ 0x0000

	load.{width:loadtype} {dst:reg}, ({src:reg}) =>
		0x20 @ dst[3:0] @ src[3:0] @ width[2:0] @ 0b0 @ 0x0 @ 0x00
	store.{width:storetype} ({dst:reg}), {src:reg} =>
		0x21 @ src[3:0] @ dst[3:0] @ width[2:0] @ 0b0 @ 0x0 @ 0x00
	load.{width:loadtype} {dst:reg}, {addr} =>
		0x22 @ dst[3:0] @ 0x0 @ width[2:0] @ 0b0 @ 0x0 @ 0x00 @ addr[31:0]
	store.{width:storetype} {addr}, {src:reg} =>
		0x23 @ src[3:0] @ 0x0 @ width[2:0] @ 0b0 @ 0x0 @ 0x00 @ addr[31:0]
	load.{width:loadtype} {dst:reg}, ({offset}, {src:reg}) =>
		0x24 @ dst[3:0] @ src[3:0] @ width[2:0] @ 0b0 @ 0x0 @ 0x00 @ offset[31:0]
	store.{width:storetype} ({offset}, {dst:reg}), {src:reg} =>
		0x25 @ src[3:0] @ dst[3:0] @ width[2:0] @ 0b0 @ 0x0 @ 0x00 @ offset[31:0]
	loadq.{width:loadtype} {dst:reg}, ({offset},{src:reg}) =>
		0x26 @ dst[3:0] @ src[3:0] @ width[2:0] @ 0b0 @ 0x0 @ offset[7:0]
	storeq.{width:storetype} ({offset}, {dst:reg}), {src:reg} =>
		0x27 @ src[3:0] @ dst[3:0] @ width[2:0] @ 0b0 @ 0x0 @ offset[7:0]
	load.{width:loadtype} {dst:reg}, ({offset}, pc) =>
		0x28 @ dst[3:0] @ 0x0 @ width[2:0] @ 0b0 @ 0x0 @ 0x00 @ offset[31:0]
	store.{width:storetype} ({offset}, pc), {src:reg} =>
		0x29 @ src[3:0] @ 0x0 @ width[2:0] @ 0b0 @ 0x0 @ 0x00 @ offset[31:0]
	loadq.{width:loadtype} {dst:reg}, ({offset}, pc) =>
		0x2a @ dst[3:0] @ 0x0 @ width[2:0] @ 0b0 @ 0x0 @ offset[7:0]
	storeq.{width:storetype} ({offset}, pc), {src:reg} =>
		0x2b @ src[3:0] @ 0x0 @ width[2:0] @ 0b0 @ 0x0 @ offset[7:0]

	; dst register of 0xf - use r15 to save typing in asm
	jump {target} =>
		0x30 @ 0x0 @ 0x0 @ 0x00 @ 0x00 @ target[31:0]
	jump{test:condition} {target} =>
		0x30 @ 0x0 @ 0x0 @ test[7:0] @ 0x00 @ target[31:0]
	branch {target} =>
		0x31 @ 0x0 @ 0x0 @ 0x00 @ 0x00 @ { target - pc - 4}[31:0]
	branch{test:condition} {target} =>
		0x31 @ 0x0 @ 0x0 @ test[7:0] @ 0x00 @ { target - pc - 4}[31:0]
	calljump {target} =>
		0x32 @ 0x0 @ 0xf @ 0x00 @0x00 @ target[31:0]
	calljump{test:condition} {target} =>
		0x32 @ 0x0 @ 0xf @ test[7:0] @ 0x00 @ target[31:0]
	callbranch {target} =>
		0x33 @ 0x0 @ 0xf @ 0x00 @ 0x00 @ { target - pc - 4 }[31:0]
	callbranch{test:condition} =>
		0x33 @ 0x0 @ 0xf @ test[7:0] @ x00 @ { target - pc - 4 }[31:0]
	jump ({dst:reg}) =>
		0x34 @ dst[3:0] @ 0x0 @ 0x00 @ 0x00
	jump{test:condition} ({dst:reg}) =>
		0x34 @ dst[3:0] @ 0x0 @ test[7:0] @ 0x00
	calljump ({dst:reg}) =>
		0x35 @ dst[3:0] @ 0xf @ 0x00 @ 0x00
	calljump{test:condition} ({dst:reg}) =>
		0x35 @ dst[3:0] @ 0xf @ test[7:0] @ 0x00
	return =>
		0x36 @ 0x0 @ 0xf @ 0x00 @ 0x00
	return{test:condition} =>
		0x36 @ 0x0 @ 0xf @ test[7:0] @ 0x00

	; long form ALU operations, ie. dest := op2 operation op3
	{aluop:twoargalu} {dst:reg}, {operand2:reg}, {operand3:reg} =>
		0x40 @ dst[3:0] @ operand2[3:0] @ operand3[3:0] @ aluop[3:0] @ 0x00
	{aluop:twoargalu} {dst:reg}, {operand2:reg}, #{value} =>
		0x42 @ dst[3:0] @ operand2[3:0] @ 0x0 @ aluop[3:0] @ 0x00 @ value[31:0]
	{aluop:twoargalu}q {dst:reg}, {operand2:reg}, #{value} =>
		0x44 @ dst[3:0] @ operand2[3:0] @ 0x0 @ aluop[3:0] @ value[7:0]
	; same but one operand, ie. dst := operantion op2
	{aluop:oneargalu} {dst:reg}, {operand2:reg} =>
		0x49 @ dst[3:0] @ operand2[3:0] @ 0x0 @ aluop[3:0] @ 0x00

	; short form ALU operations, ie. dst := dst operation op3
	{aluop:twoargalu} {dst:reg}, {operand3:reg} =>
		0x40 @ dst[3:0] @ dst[3:0] @ operand3[3:0] @ aluop[3:0] @ 0x00
	{aluop:twoargalu} {dst:reg}, #{value} =>
		0x42 @ dst[3:0] @ dst[3:0] @ 0x0 @ aluop[3:0] @ 0x00 @ value[31:0]
	{aluop:twoargalu}q {dst:reg}, #{value} =>
		0x44 @ dst[3:0] @ dst[3:0] @ 0x0 @ aluop[3:0] @ value[7:0]
	; same but only the destination, ie. dst := operation dst
	{aluop:oneargalu} {dst:reg} =>
		0x49 @ dst[3:0] @ dst[3:0] @ 0x0 @ aluop[3:0] @ 0x00

	push ({dst:reg}), {src:reg} =>
		0x50 @ src[3:0] @ dst[3:0] @ 0x0000
	pop {dst:reg}, ({src:reg}) =>
		0x51 @ dst[3:0] @ src[3:0] @ 0x0000
	pushmulti ({dst:reg}), {src:u16} =>
		0x52 @ 0x0 @ dst[3:0] @ src[15:0]
	popmulti {dst:u16}, ({src:reg}) =>
		0x53 @ 0x0 @ src[3:0] @ dst[15:0]
}
