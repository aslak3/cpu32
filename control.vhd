library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.P_ALU.all;
use work.P_REGISTERS.all;
use work.P_CONTROL.all;
use work.P_BUSINTERFACE.all;

entity control is
	port (
		clock : in STD_LOGIC;
		reset : in STD_LOGIC;
		read : out STD_LOGIC;
		write : out STD_LOGIC;
		cycle_width : out T_CYCLE_WIDTH;
		cycle_signed : out STD_LOGIC;
		halted : out STD_LOGIC;

		alu_reg2_mux_sel : out T_ALU_REG2_MUX_SEL;
		alu_reg3_mux_sel : out T_ALU_REG3_MUX_SEL;
		alu_op_mux_sel : out T_ALU_OP_MUX_SEL;
		regs_input_mux_sel : out T_REGS_INPUT_MUX_SEL;
		regs_write_index_mux_sel : out T_REGS_WRITE_INDEX_MUX_SEL;
		regs_read_reg1_index_mux_sel : out T_REGS_READ_REG1_INDEX_MUX_SEL;
		pc_input_mux_sel : out T_PC_INPUT_MUX_SEL;
		temporary_input_mux_sel : out T_TEMPORARY_INPUT_MUX_SEL;
		address_mux_sel : out T_ADDRESS_MUX_SEL;
		data_out_mux_sel : out T_DATA_OUT_MUX_SEL;
		sized_cycle_mux_sel : out STD_LOGIC;

		stack_multi_reg_index : out T_REG_INDEX;

		instruction_write : out STD_LOGIC;
		instruction_opcode : in T_OPCODE;
		instruction_condition : in T_CONDITION;
		instruction_quick_word : in STD_LOGIC_VECTOR (15 downto 0);

		alu_carry_in : out STD_LOGIC;
		alu_carry_out : in STD_LOGIC;
		alu_zero_out : in STD_LOGIC;
		alu_neg_out : in STD_LOGIC;
		alu_over_out : in STD_LOGIC;

		regs_clear : out STD_LOGIC;
		regs_write : out STD_LOGIC;
		regs_inc : out STD_LOGIC;
		regs_dec : out STD_LOGIC;

		pc_jump : out STD_LOGIC;
		pc_increment : out STD_LOGIC;

		temporary_write : out STD_LOGIC;
		temporary_output : in T_REG
);
end entity;

architecture behavioural of control is
	-- Base:
	-- 31 downto 24 : opcode
	constant OPCODE_ILLEGAL :		T_OPCODE := x"00";
	constant OPCODE_NOP :			T_OPCODE := x"01";
	constant OPCODE_HALT :			T_OPCODE := x"02";
	constant OPCODE_ORFLAGS :		T_OPCODE := x"03";
	constant OPCODE_ANDFLAGS :		T_OPCODE := x"04";

	-- Load immediate and clear:
	-- 31 downto 24 : opcode (LOADLI, LOADUWI, LOADLWI)
	-- 23 downto 20 : left: destination register (not ORLFAGS, ANDFLAGS)
	-- 15 downto 0 : what to load (LOADWSQ, ORFLAGS, ANDFLAGS)
	constant OPCODE_LOADLI :		T_OPCODE := x"10";
	constant OPCODE_LOADWSQ :		T_OPCODE := x"11";

	-- Load and store:
	-- 31 downto 24 : opcode (LOADR, STORER, LOADM, STORM, LOADRD, STORERD, LOADRDQ, STORERQD, LOADPCD, STOREPCD, LOADPCDQ, STOREPCDQ)
	-- 23 downto 20 : register to read/write
	-- 19 downto 16 : address register (not LOADM, STOREM, LOADPCD, STOREPCD, LOADPCDQ, STOREPCDQ)
	-- 15 downto 14 : transfer type
	-- 13 : signed
	-- 11 downto 0 : displacement (LOADRDQ, STORERDQ, LOADPCDQ, STOREPCDQ)
	constant OPCODE_LOADR :			T_OPCODE := x"20";
	constant OPCODE_STORER :		T_OPCODE := x"21";
	constant OPCODE_LOADM :			T_OPCODE := x"22";
	constant OPCODE_STOREM :		T_OPCODE := x"23";
	constant OPCODE_LOADRD :		T_OPCODE := x"24";
	constant OPCODE_STORERD :		T_OPCODE := x"25";
	constant OPCODE_LOADRDQ :		T_OPCODE := x"26";
	constant OPCODE_STORERDQ :		T_OPCODE := x"27";
	constant OPCODE_LOADPCD :		T_OPCODE := x"28";
	constant OPCODE_STOREPCD :		T_OPCODE := x"29";
	constant OPCODE_LOADPCDQ :		T_OPCODE := x"2a";
	constant OPCODE_STOREPCDQ :		T_OPCODE := x"2b";

	-- Flow control:
	-- 31 downto 24 : opcode (BRANCH, JUMP, CALLBRANCH, CALLJUMP, JUMPR, CALLJUMPR, RETURN)
	-- 23 downto 20 : target register (for JUMPR)
	-- 19 downto 16 : stack register (for CALLBRANCH, CALLJUMP, RETURN, CALLJUMPR)
	-- 15 downto 12 : flag mask (not RETURN)
	-- 11 downto 8 : flag match (not RETURN)
	constant OPCODE_JUMP :			T_OPCODE := x"30";
	constant OPCODE_BRANCH :		T_OPCODE := x"31";
	constant OPCODE_BRANCHQ :		T_OPCODE := x"32";
	constant OPCODE_CALLJUMP :		T_OPCODE := x"33";
	constant OPCODE_CALLBRANCH :	T_OPCODE := x"34";
	constant OPCODE_CALLBRANCHQ :	T_OPCODE := x"35";
	constant OPCODE_JUMPR :			T_OPCODE := x"36";
	constant OPCODE_CALLJUMPR :		T_OPCODE := x"37";
	constant OPCODE_RETURN :		T_OPCODE := x"38";

	-- ALU:
	-- 31 downto 24 : opcode (ALUM, ALUMI, ALUS)
	-- 23 downto 20 : destination register
	-- 19 downto 16 : operand register1
	-- 24, 15 downto 12 : operation code
	-- 11 downto 8 : operand register2 (ALUM only)
	constant OPCODE_ALUM :			T_OPCODE := x"40";
	constant OPCODE_ALUMI :			T_OPCODE := x"42";
	constant OPCODE_ALUS :			T_OPCODE := x"49";

	-- ALU quick:
	-- 31 downto 24 : opcode (ALUMQ)
	-- 23 downto 20 : destination register
	-- 19 downto 16 : operand register1
	-- 24, 15 downto 12 : operation code
	-- 11 downto 0 : quick operand
	constant OPCODE_ALUMQ :			T_OPCODE := x"50";

	-- Push and pop:
	-- 31 downto 24 : opcode (PUSH, POP, PUSHMULTI, POPMULTI)
	-- 23 downto 20 : what to push/pop (PUSH, POP)
	-- 19 downto 16 : stack register
	-- 15 downto 0 : register mask (PUSHMULTI, POPMULTI)
	constant OPCODE_PUSH :			T_OPCODE := x"60";
	constant OPCODE_POP :			T_OPCODE := x"61";
	constant OPCODE_PUSHMULTI :		T_OPCODE := x"62";
	constant OPCODE_POPMULTI :		T_OPCODE := x"63";

	-- Register copy:
	-- 31 downto 24 : opcode (COPY)
	-- 23 downto 20 : destination register
	-- 19 downto 16 : source register
	constant OPCODE_COPY :			T_OPCODE := x"70";

	-- Used by and/or of flags
	constant FLOWTYPE_CARRY :		integer := 3;
	constant FLOWTYPE_ZERO :		integer := 2;
	constant FLOWTYPE_NEG :			integer := 1;
	constant FLOWTYPE_OVER :		integer := 0;

	-- Used by jump etc
	constant COND_AL :			T_CONDITION := x"0"; -- always
	constant COND_EQ :			T_CONDITION := x"1"; -- equal AKA zero set
	constant COND_NE :			T_CONDITION := x"2"; -- not equal AKA zero clear
	constant COND_CS :			T_CONDITION := x"3"; -- carry set
	constant COND_CC :			T_CONDITION := x"4"; -- carry clear
	constant COND_MI :			T_CONDITION := x"5"; -- minus
	constant COND_PL :			T_CONDITION := x"6"; -- plus
	constant COND_VS :			T_CONDITION := x"7"; -- overflow set
	constant COND_VC :			T_CONDITION := x"8"; -- overflow clear
	constant COND_HI :			T_CONDITION := x"9"; -- unsigned higher
	constant COND_LS :			T_CONDITION := x"a"; -- unsigned lower than or same
	constant COND_GE :			T_CONDITION := x"b"; -- signed greater than or equal
	constant COND_LT :			T_CONDITION := x"c"; -- signed less than
	constant COND_GT :			T_CONDITION := x"d"; -- signe greater than
	constant COND_LE :			T_CONDITION := x"e"; -- signed less than or equal

	type T_STATE is (
		S_START1,
		S_FETCH1, S_FETCH2,
		S_DECODE,
		S_HALT1,
		S_LOADM1, S_STOREM1,
		S_LOADRD1, S_STORERD1,
		S_BRANCH1,
		S_CALL1, S_CALL2,
		S_PUSH1,
		S_PUSHMULTI1, S_PUSHMULTI2, S_POPMULTI1, S_POPMULTI2
	);
begin
	process (RESET, CLOCK)
		variable state : T_STATE := S_FETCH1;
		variable last_alu_carry_out : STD_LOGIC := '0';
		variable last_alu_zero_out : STD_LOGIC := '0';
		variable last_alu_neg_out : STD_LOGIC := '0';
		variable last_alu_over_out : STD_LOGIC := '0';
		variable stacked : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
		variable cond_true : STD_LOGIC := '0';
	begin
		if (reset = '1') then
			state := S_START1;
			halted <= '0';

			alu_reg2_mux_sel <= S_INSTRUCTION_REG2;
			alu_reg3_mux_sel <= S_INSTRUCTION_REG3;
			alu_op_mux_sel <= S_INSTRUCTION_ALU_OP;
			regs_input_mux_sel <= S_ALU_RESULT;
			regs_write_index_mux_sel <= S_INSTRUCTION_REG1;
			regs_read_reg1_index_mux_sel <= S_INSTRUCTION_REG1;
			pc_input_mux_sel <= S_DATA_IN;
			temporary_input_mux_sel <= S_ALU_RESULT;
			address_mux_sel <= S_PC;
			data_out_mux_sel <= S_PC;
		elsif (clock'Event and clock = '1') then
			alu_carry_in <= '0';
			sized_cycle_mux_sel <= '0';

			read <= '0';
			write <= '0';
			instruction_write <= '0';
			pc_jump <= '0';
			pc_increment <= '0';
			regs_clear <= '0';
			regs_write <= '0';
			regs_inc <= '0';
			regs_dec <= '0';
			temporary_write <= '0';

			stack_multi_reg_index <= (others => '0');

			case state is
				when S_START1 =>
					report "In S_START1";
					address_mux_sel <= S_PC;
					read <= '1';
					pc_input_mux_sel <= S_DATA_IN;
					pc_jump <= '1';
					state := S_FETCH1;

				when S_FETCH1 =>
					report "In S_FETCH1";
					case instruction_opcode is
						when OPCODE_ALUM | OPCODE_ALUS | OPCODE_ALUMI | OPCODE_ALUMQ =>
							last_alu_carry_out := alu_carry_out;
							last_alu_zero_out := alu_zero_out;
							last_alu_neg_out := alu_neg_out;
							last_alu_over_out := alu_over_out;
							alu_carry_in <= alu_carry_out;

						when OPCODE_POP =>
							regs_inc <= '1';

						when others =>
					end case;

					address_mux_sel <= S_PC;
					read <= '1';
					pc_increment <= '1';
					instruction_write <= '1';
					state := S_FETCH2;

				when S_FETCH2 =>
					report "in S_FETCH2";
					state := S_DECODE;

				when S_DECODE =>
					case instruction_opcode is
						when OPCODE_NOP =>
							report "Control: Opcode NOP";
							state := S_FETCH1;

						when OPCODE_HALT =>
							report "Control: Opcode HALT";
							halted <= '1';
							state := S_HALT1;

						when OPCODE_ORFLAGS =>
--pragma synthesis_off
							report "Control: Opcode ORFLAGS with " & to_string(instruction_quick_word);
--pragma synthesis_on
							last_alu_carry_out := last_alu_carry_out or instruction_quick_word (FLOWTYPE_CARRY);
							last_alu_zero_out := alu_zero_out or instruction_quick_word (FLOWTYPE_ZERO);
							last_alu_neg_out := alu_neg_out or instruction_quick_word (FLOWTYPE_NEG);
							last_alu_over_out := alu_over_out or instruction_quick_word (FLOWTYPE_OVER);
							state := S_FETCH1;

						when OPCODE_ANDFLAGS =>
--pragma synthesis_off
							report "Control: Opcode ANDFLAGS with " & to_string(instruction_quick_word);
--pragma synthesis_on
							last_alu_carry_out := last_alu_carry_out and instruction_quick_word (FLOWTYPE_CARRY);
							last_alu_zero_out := alu_zero_out and instruction_quick_word (FLOWTYPE_ZERO);
							last_alu_neg_out := alu_neg_out and instruction_quick_word (FLOWTYPE_NEG);
							last_alu_over_out := alu_over_out and instruction_quick_word (FLOWTYPE_OVER);
							state := S_FETCH1;

						when OPCODE_LOADLI =>
							report "Control: Opcode LOADLI";
							address_mux_sel <= S_PC;
							read <= '1';
							pc_increment <= '1';
							regs_input_mux_sel <= S_DATA_IN;
							regs_write_index_mux_sel <= S_INSTRUCTION_REG1;
							regs_write <= '1';
							state := S_FETCH1;

						when OPCODE_LOADWSQ =>
							report "Control: Opcode LOADWSQ";
							regs_input_mux_sel <= S_INSTRUCTION_QUICK_WORD;
							regs_write_index_mux_sel <= S_INSTRUCTION_REG1;
							regs_write <= '1';
							state := S_FETCH1;

						when OPCODE_LOADR =>
							report "Control: Opcode LOADR";
							address_mux_sel <= S_INSTRUCTION_REG2;
							sized_cycle_mux_sel <= '1';
							read <= '1';
							regs_input_mux_sel <= S_DATA_IN;
							regs_write_index_mux_sel <= S_INSTRUCTION_REG1;
							regs_write <= '1';
							state := S_FETCH1;

						when OPCODE_STORER =>
							report "Control: Opcode STORER";
							address_mux_sel <= S_INSTRUCTION_REG2;
							data_out_mux_sel <= S_INSTRUCTION_REG1;
							sized_cycle_mux_sel <= '1';
							write <= '1';
							state := S_FETCH1;

						when OPCODE_LOADM =>
							report "Control: Opcode LOADM";
							address_mux_sel <= S_PC;
							read <= '1';
							temporary_input_mux_sel <= S_DATA_IN;
							temporary_write <= '1';
							state := S_LOADM1;

						when OPCODE_STOREM =>
							report "Control: Opcode STOREM";
							address_mux_sel <= S_PC;
							read <= '1';
							temporary_input_mux_sel <= S_DATA_IN;
							temporary_write <= '1';
							state := S_STOREM1;

						when OPCODE_LOADRD | OPCODE_STORERD | OPCODE_LOADPCD | OPCODE_STOREPCD |
							OPCODE_LOADRDQ | OPCODE_STORERDQ | OPCODE_LOADPCDQ | OPCODE_STOREPCDQ
						=>
							report "Control: Opcode LOADRD/STORERD/LOADPCD/STOREPCD/LOADQRD/STOREQRD/LOADPCD/STOREQPCD";
							if (instruction_opcode = OPCODE_LOADRD or instruction_opcode = OPCODE_STORERD or
								instruction_opcode = OPCODE_LOADPCD or instruction_opcode = OPCODE_STOREPCD)
							then
								-- Not quick
								alu_reg3_mux_sel <= S_DATA_IN;
								address_mux_sel <= S_PC;
								read <= '1';
							else
								-- Quick
								alu_reg3_mux_sel <= S_INSTRUCTION_QUICK_BYTENYBBLE;
							end if;
							if (instruction_opcode = OPCODE_LOADRD or instruction_opcode = OPCODE_STORERD or
								instruction_opcode = OPCODE_LOADRDQ or instruction_opcode = OPCODE_STORERDQ
							) then
								-- Register base
								alu_reg2_mux_sel <= S_INSTRUCTION_REG2;
							else
								-- Program Counter base
								alu_reg2_mux_sel <= S_PC;
							end if;
							alu_op_mux_sel <= S_ADD;
							temporary_input_mux_sel <= S_ALU_RESULT;
							temporary_write <= '1';
							if (instruction_opcode = OPCODE_LOADRD or instruction_opcode = OPCODE_LOADPCD or
								instruction_opcode = OPCODE_LOADRDQ or instruction_opcode = OPCODE_LOADPCDQ)
							then
								-- Loading
								state := S_LOADRD1;
							else
								-- Storing
								state := S_STORERD1;
							end if;

						when OPCODE_JUMP | OPCODE_JUMPR | OPCODE_BRANCH | OPCODE_BRANCHQ | OPCODE_CALLJUMP | OPCODE_CALLJUMPR |
							OPCODE_CALLBRANCH | OPCODE_CALLBRANCHQ | OPCODE_RETURN
						=>
--pragma synthesis_off
							report "Control: Jumping/Branching/Return: Condition=" & to_hstring(instruction_condition);
--pragma synthesis_on
							case instruction_condition is
								when COND_EQ =>
									cond_true := last_alu_zero_out;
								when COND_NE =>
									cond_true := not last_alu_zero_out;
								when COND_CS =>
									cond_true := last_alu_carry_out;
								when COND_CC =>
									cond_true := not last_alu_carry_out;
								when COND_MI =>
									cond_true := last_alu_neg_out;
								when COND_PL =>
									cond_true := not last_alu_neg_out;
								when COND_VS =>
									cond_true := last_alu_over_out;
								when COND_VC =>
									cond_true := not last_alu_over_out;
								when COND_HI =>
									cond_true := not last_alu_carry_out and not last_alu_zero_out;
								when COND_LS =>
									cond_true := last_alu_carry_out or last_alu_zero_out;
								when COND_GE =>
									cond_true := last_alu_neg_out xnor last_alu_over_out;
								when COND_LT =>
									cond_true := last_alu_neg_out xor last_alu_over_out;
								when COND_GT =>
									cond_true := not last_alu_zero_out and
										(last_alu_neg_out xnor last_alu_over_out);
								when COND_LE =>
									cond_true := last_alu_zero_out or
										(last_alu_neg_out xor last_alu_over_out);
								when others =>
									cond_true := '1';
							end case;

							if (cond_true = '1') then
								if (instruction_opcode = OPCODE_JUMP) then
									report "Control: Jump taken";
									address_mux_sel <= S_PC;
									read <= '1';
									pc_input_mux_sel <= S_DATA_IN;
									pc_jump <= '1';
									state := S_FETCH1;
								elsif (instruction_opcode = OPCODE_JUMPR) then
									report "Control: Jump through reg taken";
									pc_input_mux_sel <= S_INSTRUCTION_REG1;
									regs_read_reg1_index_mux_sel <= S_INSTRUCTION_REG1;
									pc_jump <= '1';
									state := S_FETCH1;
								elsif (instruction_opcode = OPCODE_BRANCH or
									instruction_opcode = OPCODE_BRANCHQ)
								then
									report "Control: Branch(Q) taken";
									alu_reg2_mux_sel <= S_PC;
									if (instruction_opcode = OPCODE_BRANCH) then
										address_mux_sel <= S_PC;
										read <= '1';
										alu_reg3_mux_sel <= S_DATA_IN;
									else
										alu_reg3_mux_sel <= S_INSTRUCTION_QUICK_BYTENYBBLE;
									end if;
									alu_op_mux_sel <= S_ADD;
									temporary_input_mux_sel <= S_ALU_RESULT;
									temporary_write <= '1';
									state := S_BRANCH1;
								elsif (instruction_opcode = OPCODE_CALLJUMP) then
									report "Control: CallJump taken";
									address_mux_sel <= S_PC;
									read <= '1';
									temporary_input_mux_sel <= S_DATA_IN;
									temporary_write <= '1';
									pc_increment <= '1';
									state := S_CALL1;
								elsif (instruction_opcode = OPCODE_CALLJUMPR) then
									report "Control: CallJumpR taken";
									state := S_CALL1;
								elsif (instruction_opcode = OPCODE_CALLBRANCH or
									instruction_opcode = OPCODE_CALLBRANCHQ)
								then
									report "Control: CallBranch(Q) taken";
									alu_reg2_mux_sel <= S_PC;
									if (instruction_opcode = OPCODE_CALLBRANCH) then
										address_mux_sel <= S_PC;
										read <= '1';
										alu_reg3_mux_sel <= S_DATA_IN;
										pc_increment <= '1';
									else
										alu_reg3_mux_sel <= S_INSTRUCTION_QUICK_BYTENYBBLE;
									end if;
									alu_op_mux_sel <= S_ADD;
									temporary_input_mux_sel <= S_ALU_RESULT;
									temporary_write <= '1';
									state := S_CALL1;
								elsif (instruction_opcode = OPCODE_RETURN) then
									report "Control: Return taken";
									address_mux_sel <= S_INSTRUCTION_REG2;
									read <= '1';
									regs_inc <= '1';
									pc_input_mux_sel <= S_DATA_IN;
									pc_jump <= '1';
									state := S_FETCH1;
								end if;
							else
								report "Control: Jump/Branch/Return NOT taken";
								if (not (instruction_opcode = OPCODE_JUMPR or instruction_opcode = OPCODE_CALLJUMPR or
									instruction_opcode = OPCODE_BRANCHQ or instruction_opcode = OPCODE_CALLBRANCHQ or
									instruction_opcode = OPCODE_RETURN))
								then
									pc_increment <= '1';
								end if;
								state := S_FETCH1;
							end if;

						when OPCODE_ALUM | OPCODE_ALUS | OPCODE_ALUMI | OPCODE_ALUMQ =>
							alu_reg2_mux_sel <= S_INSTRUCTION_REG2;
							if (instruction_opcode = OPCODE_ALUMI) then
								report "Control: Opcode ALUMI";
								pc_increment <= '1';
								read <= '1';
								alu_reg3_mux_sel <= S_DATA_IN;
							elsif (instruction_opcode = OPCODE_ALUMQ) then
								report "Control: Opcode ALUMQ";
								alu_reg3_mux_sel <= S_INSTRUCTION_QUICK_BYTENYBBLE;
							else
								report "Control: Opcode ALUM/ALUS";
								alu_reg3_mux_sel <= S_INSTRUCTION_REG3;
							end if;
							alu_op_mux_sel <= S_INSTRUCTION_ALU_OP;
							regs_input_mux_sel <= S_ALU_RESULT;
							regs_write_index_mux_sel <= S_INSTRUCTION_REG1;
							regs_write <= '1';
							alu_carry_in <= ALU_CARRY_OUT;
							state := S_FETCH1;

						when OPCODE_PUSH =>
							report "Control: Opcode PUSH";
							address_mux_sel <= S_INSTRUCTION_REG2;
							data_out_mux_sel <= S_INSTRUCTION_REG1;
							regs_read_reg1_index_mux_sel <= S_INSTRUCTION_REG1;
							regs_dec <= '1';
							state := S_PUSH1;

						when OPCODE_POP =>
							report "Control: Opcode POP";
							address_mux_sel <= S_INSTRUCTION_REG2;
							read <= '1';
							regs_input_mux_sel <= S_DATA_IN;
							regs_write_index_mux_sel <= S_INSTRUCTION_REG1;
							regs_write <= '1';
							state := S_FETCH1;

						when OPCODE_PUSHMULTI =>
							report "Control: Opcode PUSHMULTI";
							stacked := (others => '0');
							state := S_PUSHMULTI1;

						when OPCODE_POPMULTI =>
							report "Control: Opcode POPMULTI";
							stacked := (others => '0');
							state := S_POPMULTI1;

						when OPCODE_COPY =>
							report "Control: Opcode COPY";
							regs_input_mux_sel <= S_INSTRUCTION_REG2;
							regs_write_index_mux_sel <= S_INSTRUCTION_REG1;
							regs_write <= '1';
							state := S_FETCH1;

						when others =>
							report "Control: No opcode match!";
--pragma synthesis_off
							std.env.finish;
--pragma synthesis_on
							state := S_FETCH1;
					end case;

				when S_HALT1 =>
					state := S_HALT1;

				when S_LOADM1 =>
					address_mux_sel <= S_TEMPORARY_OUTPUT;
					sized_cycle_mux_sel <= '1';
					read <= '1';
					regs_input_mux_sel <= S_DATA_IN;
					pc_increment <= '1';
					regs_write_index_mux_sel <= S_INSTRUCTION_REG1;
					regs_write <= '1';
					state := S_FETCH1;

				when S_STOREM1 =>
					address_mux_sel <= S_TEMPORARY_OUTPUT;
					data_out_mux_sel <= S_INSTRUCTION_REG1;
					regs_read_reg1_index_mux_sel <= S_INSTRUCTION_REG1;
					sized_cycle_mux_sel <= '1';
					write <= '1';
					pc_increment <= '1';
					state := S_FETCH1;

				when S_LOADRD1 =>
					address_mux_sel <= S_TEMPORARY_OUTPUT;
					sized_cycle_mux_sel <= '1';
					read <= '1';
					regs_input_mux_sel <= S_DATA_IN;
					regs_write <= '1';
					if (instruction_opcode = OPCODE_LOADRD or instruction_opcode = OPCODE_LOADPCD) then
						pc_increment <= '1';
					end if;
					state := S_FETCH1;

				when S_STORERD1 =>
					address_mux_sel <= S_TEMPORARY_OUTPUT;
					regs_read_reg1_index_mux_sel <= S_INSTRUCTION_REG1;
					data_out_mux_sel <= S_INSTRUCTION_REG1;
					sized_cycle_mux_sel <= '1';
					write <= '1';
					if (instruction_opcode = OPCODE_STORERD or instruction_opcode = OPCODE_STOREPCD) then
						pc_increment <= '1';
					end if;
					state := S_FETCH1;

				when S_BRANCH1 =>
					pc_input_mux_sel <= S_TEMPORARY_OUTPUT;
					pc_jump <= '1';
					state := S_FETCH1;

				when S_CALL1 =>
					address_mux_sel <= S_INSTRUCTION_REG2;
					data_out_mux_sel <= S_PC;
					regs_dec <= '1';
					state := S_CALL2;

				when S_CALL2 =>
					write <= '1';
					if (instruction_opcode = OPCODE_CALLJUMPR) then
						pc_input_mux_sel <= S_INSTRUCTION_REG1;
					else
						pc_input_mux_sel <= S_TEMPORARY_OUTPUT;
					end if;
					pc_jump <= '1';
					state := S_FETCH1;

				when S_PUSH1 =>
					write <= '1';
					state := S_FETCH1;

				when S_PUSHMULTI1 =>
					-- First cycle of a multi push is to decrement the stack pointer
					regs_dec <= '1';
					state := S_PUSHMULTI2;

				when S_PUSHMULTI2 =>
					-- Second cycle is the actual write
					for reg_number in 0 to 15 loop
						if (instruction_quick_word (reg_number) = '1' and stacked (reg_number) = '0') then
							-- Get the first register we have not yet stacked
							stack_multi_reg_index <= STD_LOGIC_VECTOR (to_unsigned(reg_number, 4));
							-- Mark this register as stacked
							stacked (reg_number) := '1';
							regs_read_reg1_index_mux_sel <= S_STACK_MULTI;
							address_mux_sel <= S_INSTRUCTION_REG2;
							data_out_mux_sel <= S_INSTRUCTION_REG1;
							write <= '1';
							exit;
						end if;
					end loop;

					if (instruction_quick_word = stacked) then
						state := S_FETCH1;
					else
						state := S_PUSHMULTI1;
					end if;

				when S_POPMULTI1 =>
					for reg_number in 15 downto 0 loop
						if (instruction_quick_word (reg_number) = '1' and stacked (reg_number) = '0') then
							-- Get the first register we haven't yet unstacked. This is done in then
							-- reverse order to the push operation
							stack_multi_reg_index <= STD_LOGIC_VECTOR (to_unsigned(reg_number, 4));
							stacked (reg_number) := '1';
							address_mux_sel <= S_INSTRUCTION_REG2;
							read <= '1';
							regs_input_mux_sel <= S_DATA_IN;
							regs_write_index_mux_sel <= S_STACK_MULTI;
							regs_write <= '1';
							exit;
						end if;
					end loop;
					STATE := S_POPMULTI2;

				when S_POPMULTI2 =>
					regs_inc <= '1';
					if (instruction_quick_word = stacked) then
						state := S_FETCH1;
					else
						state := S_POPMULTI1;
					end if;

			end case;
		end if;
	end process;
end architecture;
