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

		stack_multi_reg_index : out T_REG_INDEX;

		instruction_write : out STD_LOGIC;
		instruction_opcode : in T_OPCODE;
		instruction_flow_cares : in T_FLOWTYPE;
		instruction_flow_polarity : in T_FLOWTYPE;
		instruction_cycle_width : in T_CYCLE_WIDTH;
		instruction_cycle_signed : in STD_LOGIC;
		instruction_imm_word : in STD_LOGIC_VECTOR (15 downto 0);

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
	constant OPCODE_NOP :			T_OPCODE := x"00";
	constant OPCODE_HALT :			T_OPCODE := x"01";

	-- Load immediate and clear:
	-- 31 downto 24 : opcode (LOADLI, LOADUWI, LOADLWI, CLEAR)
	-- 23 downto 20 : left: destination register
	-- 15 downto 0 : what to load (not CLEAR, LOADLI)
	constant OPCODE_LOADLI :		T_OPCODE := x"10";
	constant OPCODE_LOADUWQ :		T_OPCODE := x"11";
	constant OPCODE_LOADLWQ :		T_OPCODE := x"12";
	constant OPCODE_CLEAR :			T_OPCODE := x"13";

	-- Load and store:
	-- 31 downto 24 : opcode (LOADR, STORER, LOADM, STORM, LOADRD, STORERD, LOADRDQ, STORERQD, LOADPCD, STOREPCD, LOADPCDQ, STOREPCDQ)
	-- 23 downto 20 : register to read/write
	-- 19 downto 16 : address register (not LOADM, STOREM, LOADPCD, STOREPCD, LOADPCDQ, STOREPCDQ)
	-- 15 downto 14 : transfer type
	-- 13 : signed
	-- 7 downto 0 : displacement (LOADRDQ, STORERDQ, LOADPCDQ, STOREPCDQ)
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
	constant OPCODE_CALLJUMP :		T_OPCODE := x"32";
	constant OPCODE_CALLBRANCH :	T_OPCODE := x"33";
	constant OPCODE_JUMPR :			T_OPCODE := x"34";
	constant OPCODE_CALLJUMPR :		T_OPCODE := x"35";
	constant OPCODE_RETURN :		T_OPCODE := x"36";

	-- ALU:
	-- 31 downto 24 : opcode (ALUM, ALUMI, ALUMQ, ALUS)
	-- 23 downto 20 : destination register
	-- 19 downto 16 : operand register1
	-- 15 downto 12 : operand register2 (ALUM only)
	-- 24, 11 downto 8 : operation code
	-- 7 downto 0 : quick immediate value (ALUMQ only)
	constant OPCODE_ALUM :			T_OPCODE := x"40";
	constant OPCODE_ALUMI :			T_OPCODE := x"42";
	constant OPCODE_ALUMQ :			T_OPCODE := x"44";
	constant OPCODE_ALUS :			T_OPCODE := x"49";

	-- Push and pop:
	-- 31 downto 24 : opcode (PUSH, POP, PUSHMULTI, POPMULTI)
	-- 23 downto 20 : what to push/pop (PUSH, POP)
	-- 19 downto 16 : stack register
	-- 15 downto 0 : register mask (PUSHMULTI, POPMULTI)
	constant OPCODE_PUSH :			T_OPCODE := x"50";
	constant OPCODE_POP :			T_OPCODE := x"51";
	constant OPCODE_PUSHMULTI :		T_OPCODE := x"52";
	constant OPCODE_POPMULTI :		T_OPCODE := x"53";

	-- Used by jump etc
	constant FLOWTYPE_CARRY :		integer := 3;
	constant FLOWTYPE_ZERO :		integer := 2;
	constant FLOWTYPE_NEG :			integer := 1;
	constant FLOWTYPE_OVER :		integer := 0;

	type T_STATE is (
		S_START1,
		S_FETCH1, S_FETCH2,
		S_DECODE,
		S_HALT1,
		S_LOADM1, S_STOREM1,
		S_LOADRD1, S_STORERD1,
		S_BRANCH1,
		S_ALU1,
		S_CALL1, S_CALL2,
		S_PUSH1, S_POP1,
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
			cycle_width <= CW_LONG;
			cycle_signed <= '0';

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
					address_mux_sel <= S_PC;
					read <= '1';
					pc_increment <= '1';
					instruction_write <= '1';
					state := S_FETCH2;

				when S_FETCH2 =>
					report "in S_FETCH2";
					state := S_DECODE;

				when S_DECODE =>
					case INSTRUCTION_OPCODE is
						when OPCODE_NOP =>
							report "Control: Opcode NOP";
							state := S_FETCH1;

						when OPCODE_HALT =>
							report "Control: Opcode HALT";
							halted <= '1';
							state := S_HALT1;

						when OPCODE_LOADLI =>
							report "Control: Opcode LOADLI";
							address_mux_sel <= S_PC;
							read <= '1';
							pc_increment <= '1';
							regs_input_mux_sel <= S_DATA_IN;
							regs_write_index_mux_sel <= S_INSTRUCTION_REG1;
							regs_write <= '1';
							state := S_FETCH1;

						when OPCODE_LOADUWQ | OPCODE_LOADLWQ =>
							report "Control: Opcode LOADUWQ/LOADLWQ";
							if (instruction_opcode = OPCODE_LOADUWQ) then
								regs_input_mux_sel <= S_INSTRUCTION_IMM_WORD_UPPER;
							else
								regs_input_mux_sel <= S_INSTRUCTION_IMM_WORD_LOWER;
							end if;
							regs_write_index_mux_sel <= S_INSTRUCTION_REG1;
							regs_write <= '1';
							state := S_FETCH1;

						when OPCODE_CLEAR =>
							report "Control: Opcode CLEAR";
							regs_clear <= '1';
							state := S_FETCH1;

						when OPCODE_LOADR =>
							report "Control: Opcode LOADR";
							address_mux_sel <= S_INSTRUCTION_REG2;
							read <= '1';
							cycle_width <= instruction_cycle_width;
							cycle_signed <= instruction_cycle_signed;
							regs_input_mux_sel <= S_DATA_IN;
							regs_write_index_mux_sel <= S_INSTRUCTION_REG1;
							regs_write <= '1';
							state := S_FETCH1;

						when OPCODE_STORER =>
							report "Control: Opcode STORER";
							address_mux_sel <= S_INSTRUCTION_REG2;
							data_out_mux_sel <= S_INSTRUCTION_REG1;
							write <= '1';
							cycle_width <= instruction_cycle_width;
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
							report "Control: Opcode LOADRD/STORERD/LOADPCD/STOREPCD/LOADRDQ/STORERDQ/LOADPCDQ/STOREPCDQ";
							if (instruction_opcode = OPCODE_LOADRD or instruction_opcode = OPCODE_STORERD or
								instruction_opcode = OPCODE_LOADPCD or instruction_opcode = OPCODE_STOREPCD)
							then
								-- Not quick
								alu_reg3_mux_sel <= S_DATA_IN;
								address_mux_sel <= S_PC;
								read <= '1';
							else
								-- Quick
								alu_reg3_mux_sel <= S_INSTRUCTION_IMM_BYTE;
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
								instruction_opcode = OPCODE_LOADPCD or instruction_opcode = OPCODE_LOADPCD)
							then
								-- Loading
								state := S_LOADRD1;
							else
								-- Storing
								state := S_STORERD1;
							end if;

						when OPCODE_JUMP | OPCODE_JUMPR | OPCODE_BRANCH | OPCODE_CALLJUMP | OPCODE_CALLJUMPR |
							OPCODE_CALLBRANCH | OPCODE_RETURN
						=>
--pragma synthesis_off
							report "Control: Jumping/Branching/Return: Cares=" & to_string(instruction_flow_cares) & " Polarity=" & to_string(instruction_flow_polarity);
--pragma synthesis_on
							if (
								( instruction_flow_cares = "0000" ) or
								(
								( ( instruction_flow_polarity(FLOWTYPE_CARRY) = LAST_ALU_CARRY_OUT ) or instruction_flow_cares(FLOWTYPE_CARRY) = '0' ) and
								( ( instruction_flow_polarity(FLOWTYPE_ZERO) = LAST_ALU_ZERO_OUT ) or instruction_flow_cares(FLOWTYPE_ZERO) = '0' ) and
								( ( instruction_flow_polarity(FLOWTYPE_NEG) = LAST_ALU_NEG_OUT ) or instruction_flow_cares(FLOWTYPE_NEG ) = '0' ) and
								( ( instruction_flow_polarity(FLOWTYPE_OVER) = LAST_ALU_OVER_OUT ) or instruction_flow_cares(FLOWTYPE_OVER ) = '0' )
								)
							) then
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
									pc_jump <= '1';
									state := S_FETCH1;
								elsif (instruction_opcode = OPCODE_BRANCH) then
									report "Control: Branch taken";
									address_mux_sel <= S_PC;
									read <= '1';
									alu_reg2_mux_sel <= S_PC;
									alu_reg3_mux_sel <= S_DATA_IN;
									alu_op_mux_sel <= S_ADD;
									temporary_input_mux_sel <= S_ALU_RESULT;
									temporary_write <= '1';
									state := S_BRANCH1;
								elsif (instruction_opcode = OPCODE_CALLJUMP) then
									report "Control: JumpR taken";
									address_mux_sel <= S_PC;
									read <= '1';
									temporary_input_mux_sel <= S_DATA_IN;
									temporary_write <= '1';
									pc_increment <= '1';
									state := S_CALL1;
								elsif (instruction_opcode = OPCODE_CALLJUMPR) then
									report "Control: CallJumpR taken";
									state := S_CALL1;
								elsif (instruction_opcode = OPCODE_CALLBRANCH) then
									report "Control: CallBranch taken";
									address_mux_sel <= S_PC;
									read <= '1';
									alu_reg2_mux_sel <= S_PC;
									alu_reg3_mux_sel <= S_DATA_IN;
									alu_op_mux_sel <= S_ADD;
									temporary_input_mux_sel <= S_ALU_RESULT;
									temporary_write <= '1';
									pc_increment <= '1';
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
								alu_reg3_mux_sel <= S_INSTRUCTION_IMM_BYTE;
							else
								report "Control: Opcode ALUM/ALUS";
								alu_reg3_mux_sel <= S_INSTRUCTION_REG3;
							end if;
							alu_op_mux_sel <= S_INSTRUCTION_ALU_OP;
							regs_input_mux_sel <= S_ALU_RESULT;
							regs_write_index_mux_sel <= S_INSTRUCTION_REG1;
							regs_write <= '1';
							alu_carry_in <= ALU_CARRY_OUT;
							state := S_ALU1;

						when OPCODE_PUSH =>
							report "Control: Opcode PUSH";
							address_mux_sel <= S_INSTRUCTION_REG2;
							data_out_mux_sel <= S_INSTRUCTION_REG1;
							regs_dec <= '1';
							state := S_PUSH1;

						when OPCODE_POP =>
							report "Control: Opcode POP";
							address_mux_sel <= S_INSTRUCTION_REG2;
							read <= '1';
							regs_input_mux_sel <= S_DATA_IN;
							regs_write_index_mux_sel <= S_INSTRUCTION_REG1;
							regs_write <= '1';
							state := S_POP1;

						when OPCODE_PUSHMULTI =>
							stacked := (others => '0');
							state := S_PUSHMULTI1;

						when OPCODE_POPMULTI =>
							stacked := (others => '0');
							state := S_POPMULTI1;

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
					read <= '1';
					regs_input_mux_sel <= S_DATA_IN;
					pc_increment <= '1';
					cycle_width <= instruction_cycle_width;
					cycle_signed <= instruction_cycle_signed;
					regs_write_index_mux_sel <= S_INSTRUCTION_REG1;
					regs_write <= '1';
					state := S_FETCH1;

				when S_STOREM1 =>
					address_mux_sel <= S_TEMPORARY_OUTPUT;
					data_out_mux_sel <= S_INSTRUCTION_REG1;
					write <= '1';
					cycle_width <= INSTRUCTION_CYCLE_WIDTH;
					pc_increment <= '1';
					state := S_FETCH1;

				when S_LOADRD1 =>
					address_mux_sel <= S_TEMPORARY_OUTPUT;
					read <= '1';
					cycle_width <= INSTRUCTION_CYCLE_WIDTH;
					cycle_signed <= instruction_cycle_signed;
					regs_input_mux_sel <= S_DATA_IN;
					regs_write <= '1';
					if (instruction_opcode = OPCODE_LOADRD) then
						pc_increment <= '1';
					end if;
					state := S_FETCH1;

				when S_STORERD1 =>
					address_mux_sel <= S_TEMPORARY_OUTPUT;
					data_out_mux_sel <= S_INSTRUCTION_REG1;
					write <= '1';
					cycle_width <= INSTRUCTION_CYCLE_WIDTH;
					if (instruction_opcode = OPCODE_STORERD) then
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

				when S_ALU1 =>
					last_alu_carry_out := alu_carry_out;
					last_alu_zero_out := alu_zero_out;
					last_alu_neg_out := alu_neg_out;
					last_alu_over_out := alu_over_out;
					alu_carry_in <= alu_carry_out;
					state := S_FETCH1;

				when S_PUSH1 =>
					write <= '1';
					state := S_FETCH1;

				when S_POP1 =>
					regs_inc <= '1';
					state := S_FETCH1;

				when S_PUSHMULTI1 =>
					-- First cycle of a multi push is to decrement the stack pointer
					regs_dec <= '1';
					state := S_PUSHMULTI2;

				when S_PUSHMULTI2 =>
					-- Second cycle is the actual write
					for reg_number in 0 to 15 loop
						if (instruction_imm_word (reg_number) = '1' and stacked (reg_number) = '0') then
							-- Get the first register we have not yet stacked
							stack_multi_reg_index <= STD_LOGIC_VECTOR (to_unsigned(reg_number, 4));
							-- Mark this register as stacked
							stacked (reg_number) := '1';
							regs_read_reg1_index_mux_sel <= S_INSTRUCTION_REG1;
							address_mux_sel <= S_INSTRUCTION_REG2;
							data_out_mux_sel <= S_INSTRUCTION_REG1;
							write <= '1';
							exit;
						end if;
					end loop;

					if (TEMPORARY_OUTPUT (15 downto 0) = STACKED) then
						state := S_FETCH1;
					else
						state := S_PUSHMULTI1;
					end if;

				when S_POPMULTI1 =>
					for reg_number in 15 downto 0 loop
						if (instruction_imm_word (reg_number) = '1' and stacked (reg_number) = '0') then
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
					if (instruction_imm_word = stacked) then
						state := S_FETCH1;
					else
						state := S_POPMULTI1;
					end if;

			end case;
		end if;
	end process;
end architecture;
