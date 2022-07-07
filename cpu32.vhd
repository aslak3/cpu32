library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.P_ALU.all;
use work.P_REGISTERS.all;
use work.P_CONTROL.all;
use work.P_BUSINTERFACE.all;

entity cpu32 is
	port (
		clock : in STD_LOGIC;
		clock_main : out STD_LOGIC;
		reset : in STD_LOGIC;
		address : out STD_LOGIC_VECTOR (29 downto 0);
		data_strobes : out STD_LOGIC_VECTOR (3 downto 0);
		data_in : in STD_LOGIC_VECTOR (31 downto 0);
		data_out : out STD_LOGIC_VECTOR (31 downto 0);
		bus_error : out STD_LOGIC;
		read : out STD_LOGIC;
		write : out STD_LOGIC;
		halted : out STD_LOGIC
	);
end entity;

architecture behavioural of cpu32 is
	-- Clocks
	signal local_clock_main : STD_LOGIC := '0';

	-- The mux selectors
	signal alu_reg2_mux_sel : T_ALU_REG2_MUX_SEL := S_INSTRUCTION_REG2;
	signal alu_reg3_mux_sel : T_ALU_REG3_MUX_SEL := S_INSTRUCTION_REG3;
	signal alu_op_mux_sel : T_ALU_OP_MUX_SEL := S_INSTRUCTION_ALU_OP;
	signal regs_input_mux_sel :T_REGS_INPUT_MUX_SEL := S_ALU_RESULT;
	signal regs_write_index_mux_sel : T_REGS_WRITE_INDEX_MUX_SEL := S_INSTRUCTION_REG1;
	signal regs_read_reg1_index_mux_sel : T_REGS_READ_REG1_INDEX_MUX_SEL := S_INSTRUCTION_REG1;
	signal pc_input_mux_sel : T_PC_INPUT_MUX_SEL := S_DATA_IN;
	signal temporary_input_mux_sel : T_TEMPORARY_INPUT_MUX_SEL := S_ALU_RESULT;
	signal address_mux_sel : T_ADDRESS_MUX_SEL := S_PC;
	signal data_out_mux_sel : T_DATA_OUT_MUX_SEL := S_PC;
	signal sized_cycle_mux_sel : STD_LOGIC := '0';

	-- For push pop multi
	signal stack_multi_reg_index : T_REG_INDEX := (others => '0');

	-- Internal side of bus
	signal cpu_cycle_width : T_CYCLE_WIDTH := CW_NULL;
	signal cpu_cycle_signed : STD_LOGIC := '0';
	signal cpu_read : STD_LOGIC := '0';
	signal cpu_write : STD_LOGIC := '0';
	signal cpu_data_in_extended : T_REG := (others => '0');
	signal cpu_address : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
	signal cpu_bus_active : STD_LOGIC := '0';
	signal cpu_data_in : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
	signal cpu_data_out : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');

	-- Instruction
	signal instruction_write : STD_LOGIC := '0';
	signal instruction_opcode : T_OPCODE := (others => '0');
	signal instruction_alu_op : T_ALU_OP := (others => '0');
	signal instruction_condition : T_CONDITION := (others => '0');
	signal instruction_quick_word : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
	signal instruction_quick_bytenybble : STD_LOGIC_VECTOR (11 downto 0) := (others => '0');
	signal instruction_cycle_width : T_CYCLE_WIDTH := (others => '0');
	signal instruction_cycle_signed : STD_LOGIC := '0';
	signal instruction_reg1_index : T_REG_INDEX := (others => '0');
	signal instruction_reg2_index : T_REG_INDEX := (others => '0');
	signal instruction_reg3_index : T_REG_INDEX := (others => '0');

	-- ALU
	signal alu_op : T_ALU_OP := (others => '0');
	signal alu_reg2_in : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
	signal alu_reg3_in : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
	signal alu_carry_in : STD_LOGIC := '0';
	signal alu_result : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');  -- outputs
	signal alu_carry_out : STD_LOGIC := '0';
	signal alu_zero_out : STD_LOGIC := '0';
	signal alu_neg_out : STD_LOGIC := '0';
	signal alu_over_out : STD_LOGIC := '0';

	-- Registers
	signal regs_read_reg1_index : T_REG_INDEX := (others => '0');
	signal regs_clear : STD_LOGIC := '0';
	signal regs_write : STD_LOGIC := '0';
	signal regs_inc : STD_LOGIC := '0';
	signal regs_dec : STD_LOGIC := '0';
	signal regs_write_index : T_REG_INDEX := (others => '0');
	signal regs_reg1_output : T_REG := (others => '0');
	signal regs_reg2_output : T_REG := (others => '0');
	signal regs_reg3_output : T_REG := (others => '0');
	signal regs_input : T_REG  := (others => '0');

	-- PC
	signal pc_jump : STD_LOGIC := '0';
	signal pc_increment : STD_LOGIC := '0';
	signal pc_input : T_REG := (others => '0');
	signal pc_output : T_REG := (others => '0');

	-- Temporary
	signal temporary_write : STD_LOGIC := '0';
	signal temporary_input : T_REG := (others => '0');
	signal temporary_output : T_REG := (others => '0');
begin
	clockdiv: entity work.clockdiv port map (
		clock => clock,
		clock_main => local_clock_main
	);

	control: entity work.control port map (
		clock => local_clock_main,
		reset => reset,
		read => cpu_read,
		write => cpu_write,
		halted => halted,

		alu_reg2_mux_sel => alu_reg2_mux_sel,
		alu_reg3_mux_sel => alu_reg3_mux_sel,
		alu_op_mux_sel => alu_op_mux_sel,
		regs_input_mux_sel => regs_input_mux_sel,
		regs_write_index_mux_sel => regs_write_index_mux_sel,
		regs_read_reg1_index_mux_sel => regs_read_reg1_index_mux_sel,
		pc_input_mux_sel => pc_input_mux_sel,
		temporary_input_mux_sel => temporary_input_mux_sel,
		address_mux_sel => address_mux_sel,
		data_out_mux_sel => data_out_mux_sel,
		sized_cycle_mux_sel => sized_cycle_mux_sel,

		stack_multi_reg_index => stack_multi_reg_index,

		instruction_write => instruction_write,
		instruction_opcode => instruction_opcode,
		instruction_condition => instruction_condition,
		instruction_quick_word => instruction_quick_word,

		alu_carry_in => alu_carry_in,
		alu_carry_out => alu_carry_out,
		alu_zero_out => alu_zero_out,
		alu_neg_out => alu_neg_out,
		alu_over_out => alu_over_out,

		regs_clear => regs_clear,
		regs_write => regs_write,
		regs_inc => regs_inc,
		regs_dec => regs_dec,

		pc_jump => pc_jump,
		pc_increment => pc_increment,

		temporary_write => temporary_write,
		temporary_output => temporary_output
	);

	instruction: entity work.instruction port map (
		clock => local_clock_main,
		reset => reset,
		write => instruction_write,
		input => data_in,

		opcode => instruction_opcode,
		reg1_index => instruction_reg1_index,
		reg2_index => instruction_reg2_index,
		reg3_index => instruction_reg3_index,
		quick_word => instruction_quick_word,
		quick_bytenybble => instruction_quick_bytenybble,

		cycle_width => instruction_cycle_width,
		cycle_signed => instruction_cycle_signed,

		condition => instruction_condition,

		alu_op => instruction_alu_op
	);

	alu: entity work.alu port map (
		op => alu_op,
		reg2 => alu_reg2_in,
		reg3 => alu_reg3_in,
		carry_in => alu_carry_in,
		result => alu_result,
		carry_out => alu_carry_out,
		zero_out => alu_zero_out,
		neg_out => alu_neg_out,
		over_out => alu_over_out
	);

	registers: entity work.registers port map (
		clock => local_clock_main,
		reset => reset,
		clear => regs_clear,
		write => regs_write,
		inc => regs_inc,
		dec => regs_dec,
		read_reg1_index => regs_read_reg1_index,
		read_reg2_index => instruction_reg2_index,
		read_reg3_index => instruction_reg3_index,
		write_index => regs_write_index,
		incdec_index => instruction_reg2_index,
		reg1_output => regs_reg1_output,
		reg2_output => regs_reg2_output,
		reg3_output => regs_reg3_output,
		input => regs_input
	);

	programcounter: entity work.programcounter port map (
		clock => local_clock_main,
		reset => reset,
		jump => pc_jump,
		input => pc_input,
		increment => pc_increment,
		output => pc_output
	);

	temporary: entity work.temporary port map (
		clock => local_clock_main,
		reset => reset,
		write => temporary_write,
		input => temporary_input,
		output => temporary_output
	);

	businterface: entity work.businterface port map (
		clock => clock,
		reset => reset,

		cpu_address => cpu_address,
		cpu_bus_active => cpu_bus_active,
		cpu_cycle_width => cpu_cycle_width,
		cpu_data_out => cpu_data_out,
		cpu_data_in => cpu_data_in,
		cpu_read => cpu_read,
		cpu_write => cpu_write,

		businterface_address => address,
		businterface_data_in => data_in,
		businterface_data_out => data_out,
		businterface_data_strobes => data_strobes,
		businterface_error => bus_error,
		businterface_read => read,
		businterface_write => write
	);

	-- Sign extend for data into a register, ie. LOADR, etc
	cpu_data_in_extended <=
		(8 to 31 => cpu_data_in (7)) & cpu_data_in (7 downto 0) when
			(cpu_cycle_width = CW_BYTE and cpu_cycle_signed = '1') else
		(16 to 31 => cpu_data_in (15)) & cpu_data_in (15 downto 0) when
			(cpu_cycle_width = CW_WORD and cpu_cycle_signed = '1') else
		(8 to 31 => '0') & cpu_data_in (7 downto 0) when
			(cpu_cycle_width = CW_BYTE and cpu_cycle_signed = '0') else
		(16 to 31 => '0') & cpu_data_in (15 downto 0) when
			(cpu_cycle_width = CW_WORD and cpu_cycle_signed = '0') else
		cpu_data_in;

	alu_reg2_in <= 		regs_reg2_output when (alu_reg2_mux_sel = S_INSTRUCTION_REG2) else
						pc_output;
	alu_reg3_in <=		regs_reg3_output when (alu_reg3_mux_sel = S_INSTRUCTION_REG3) else
						(12 to 31 => instruction_quick_bytenybble (11)) & instruction_quick_bytenybble when (alu_reg3_mux_sel = S_INSTRUCTION_QUICK_BYTENYBBLE) else
						cpu_data_in;
	alu_op <= 			instruction_alu_op when (alu_op_mux_sel = S_INSTRUCTION_ALU_OP) else
						OP_ADD;
	regs_input <= 		alu_result when (regs_input_mux_sel = S_ALU_RESULT) else
						cpu_data_in_extended when (regs_input_mux_sel = S_DATA_IN) else
						regs_reg2_output when (regs_input_mux_sel = S_INSTRUCTION_REG2) else
						(16 to 31 => instruction_quick_word (15)) & instruction_quick_word;
	regs_write_index <=	instruction_reg1_index when (regs_write_index_mux_sel = S_INSTRUCTION_REG1) else
						stack_multi_reg_index;
	regs_read_reg1_index <=
						instruction_reg1_index when (regs_read_reg1_index_mux_sel = S_INSTRUCTION_REG1) else
						stack_multi_reg_index;
	pc_input <=			cpu_data_in when (pc_input_mux_sel = S_DATA_IN) else
						temporary_output when (pc_input_mux_sel = S_TEMPORARY_OUTPUT) else
						regs_reg1_output when (pc_input_mux_sel = S_INSTRUCTION_REG1) else
						alu_result;
	temporary_input <= 	cpu_data_in when (temporary_input_mux_sel = S_DATA_IN) else
						alu_result;
	cpu_address <=		pc_output when (address_mux_sel = S_PC) else
						regs_reg2_output when (address_mux_sel = S_INSTRUCTION_REG2) else
						alu_result when (address_mux_sel = S_ALU_RESULT) else
						temporary_output;
	cpu_data_out <=		pc_output when (data_out_mux_sel = S_PC) else
						regs_reg1_output;
	cpu_cycle_width <=	instruction_cycle_width when (sized_cycle_mux_sel = '1') else
						CW_LONG;
	cpu_cycle_signed <=	instruction_cycle_signed when (sized_cycle_mux_sel = '1') else
						'0';

	cpu_bus_active <= '1' when (cpu_read = '1' or cpu_write = '1') else '0';

	clock_main <= local_clock_main;

end architecture;
