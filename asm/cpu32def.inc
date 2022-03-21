#bits 8

#subruledef reg
{
	r0 => 0
	r1 => 1
	r2 => 2
	r3 => 3
	r4 => 4
	r5 => 5
	r6 => 6
	r7 => 7
	r8 => 8
	r9 => 9
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
	l =>  0b100
}
#subruledef storetype
{
	w => 0b000
	b => 0b010
	l => 0b100
}
#subruledef condition
{
	nz => 0b01000000
	z => 0b01000100
	nc => 0b10000000
	c => 0b10001000
	nn => 0b00100000
	n => 0b00100010
}
#subruledef twoargalu
{
	add => 0x0
	addc => 0x1
	sub => 0x2
	subc => 0x3
	and => 0x4
	or => 0x5
	xor => 0x6
	copy => 0x7
	compare => 0x8
	bit => 0x9
	mulu => 0xa
	muls => 0xb
}
#subruledef oneargalu
{
	inc => 0x0
	dec => 0x1
	not => 0x2
	logicleft => 0x3
	logicright => 0x4
	arithleft => 0x5
	arithright => 0x6
	negate => 0x7
	swap => 0x8
	test => 0x9
}

#ruledef
	{
	nop => 0x00 @ 0x000000
	halt => 0x01 @ 0x000000

	load.l {dst:reg}, #{value} =>
		0x10 @ dst[3:0] @ 0x0 @ 0x0000 @ value[31:0]
	loadq.u {dst:reg}, #{value} =>
		0x11 @ dst[3:0] @ 0x0 @ value[15:0]
	loadq.l {dst:reg}, #{value} =>
		0x12 @ dst[3:0] @ 0x0 @ value[15:0]
	clear {dst:reg}, #{value} =>
		0x13 @ dst[3:0] @ 0x0 @ 0x0000

	load.{width:loadtype} {dst:reg}, ({src:reg}) =>
		0x20 @ dst[3:0] @ src[3:0] @ width[2:0] @ 0b0 @ 0x00
	store.{width:loadtype} ({dst:reg}), {src:reg} =>
		0x21 @ src[3:0] @ dst[3:0] @ width[2:0] @ 0b0 @ 0x00
	load.{width:loadtype} {dst:reg}, {addr} =>
		0x22 @ dst[3:0] @ 0x0 @ width[2:0] @ 0b0 @ 0x00 @ addr[31:0]
	store.{width:loadtype} {ddr}, {src:reg} =>
		0x23 @ src[3:0] @ 0x0 @ width[2:0] @ 0b0 @ 0x00 @ addr[31:0]
	load.{width:loadtype} {dst:reg}, ({offset},{src:reg}) =>
		0x24 @ dst[3:0] @ src[3:0] @ width[2:0] @ 0b0 @ 0x00 @ offset[31:0]
	store.{width:loadtype} ({offset},{dst:reg}), {src:reg} =>
		0x25 @ src[3:0] @ dst[3:0] @ width[2:0] @ 0b0 @ 0x00 @ offset[31:0]
	loadq.{width:loadtype} {dst:reg}, ({offset},{src:reg}) =>
		0x26 @ dst[3:0] @ src[3:0] @ width[2:0] @ 0b0 @ offset[7:0]
	storeq.{width:loadtype} ({offset},{dst:reg}), {src:reg} =>
		0x27 @ src[3:0] @ dst[3:0] @ width[2:0] @ 0b0 @ offset[7:0]
	load.{width:loadtype} {dst:reg}, ({offset},pc) =>
		0x28 @ dst[3:0] @ 0x0 @ width[2:0] @ 0b0 @ 0x00 @ offset[31:0]
	store.{width:loadtype} ({offset},pc), {src:reg} =>
		0x29 @ src[3:0] @ 0x0 @ width[2:0] @ 0b0 @ 0x00 @ offset[31:0]
	loadq.{width:loadtype} {dst:reg}, ({offset},pc) =>
		0x2a @ dst[3:0] @ 0x0 @ width[2:0] @ 0b0 @ offset[7:0]
	storeq.{width:loadtype} ({offset},pc), {src:reg} =>
		0x2b @ src[3:0] @ 0x0 @ width[2:0] @ 0b0 @ offset[7:0]

	jump {target} =>
		0x30 @ 0x0 @ 0x0 @ 0x00 @ 0x00 @ target[31:0]
	branch {target} =>
		0x31 @ 0x0 @ 0x0 @ 0x00 @ 0x00 @ { target - pc - 4}[31:0]
	jump{test:condition} {target} =>
		0x30 @ 0x0 @ 0x0 @ test[3:0] @ 0x00 @ target[31:0]
	branch{test:condition} {target} =>
		0x31 @ 0x0 @ 0x0 @ test[3:0] @ 0x00 @ { target - pc - 4}[31:0]
	; 0xf - use r15
	calljump {target} =>
		0x32 @ 0x0 @ 0xf @ 0x00 @ target[31:0]
	callbranch {target} =>
		0x33 @ 0x0 @ 0xf @ 0x00 @ { target - pc - 4 }[31:0]
	jump ({dst:reg}) =>
		0x34 @ dst[3:0] @ 0x0 @ 0x00 @ 0x00
	calljump ({dst:reg}) =>
		0x35 @ dst[3:0] @ 0xf @ 0x00 @ 0x00
	jump{test:condition} ({dst:reg}) =>
		0x34 @ dst[3:0] @ 0x0 @ test[3:0] @ 0x00
	calljump{test:condition} ({dst:reg}) =>
		0x35 @ dst[3:0] @ 0xf @ test[3:0] @ 0x00
	return =>
		0x36 @ 0x0 @ 0xf @ 0x00 @ 0x00

	{aluop:twoargalu} {dst:reg}, {operand2:reg}, {operand3:reg} =>
		0x40 @ dst[3:0] @ operand2[3:0] @ operand3[3:0] @ aluop[3:0] @ 0x00
	{aluop:twoargalu} {dst:reg}, {operand2:reg}, #{value} =>
		0x42 @ dst[3:0] @ operand2[3:0] @ 0x0 @ aluop[3:0] @ 0x00 @ value[31:0]
	{aluop:twoargalu}q {dst:reg}, {operand2:reg}, #{value} =>
		0x44 @ dst[3:0] @ operand2[3:0] @ 0x0 @ aluop[3:0] @ value[7:0]
	{aluop:oneargalu} {dst:reg}, {operand2:reg} =>
		0x49 @ dst[3:0] @ operand2[3:0] @ 0x0 @ aluop[3:0] @ 0x00

	{aluop:twoargalu} {dst:reg}, {operand3:reg} =>
		0x40 @ dst[3:0] @ dst @ operand3[3:0] @ aluop[3:0] @ 0x00
	{aluop:twoargalu} {dst:reg}, #{value} =>
		0x42 @ dst[3:0] @ dst @ 0x0 @ aluop[3:0] @ 0x00 @ value[31:0]
	{aluop:twoargalu}q {dst:reg}, #{value} =>
		0x44 @ dst[3:0] @ dst[3:0] @ 0x0 @ aluop[3:0] @ value[7:0]
	{aluop:oneargalu} {dst:reg} =>
		0x49 @ dst[3:0] @ dst[3:0] @ 0x0 @ aluop[3:0] @ 0x00

	push ({dst:reg}), {src:reg} =>
		0x50 @ src[3:0] @ dst[3:0] @ 0x0000
	pop {dst:reg}, ({src:reg}) =>
		0x51 @ src[3:0] @ dst[3:0] @ 0x0000
}
