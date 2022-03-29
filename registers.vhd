library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.P_REGISTERS.all;

entity registers is
	port (
		clock : in STD_LOGIC;
		reset : in STD_LOGIC;
		clear : in STD_LOGIC;
		write : in STD_LOGIC;
		inc : in STD_LOGIC;
		dec : in STD_LOGIC;
		read_reg1_index : in T_REG_INDEX;
		read_reg2_index : in T_REG_INDEX;
		read_reg3_index : in T_REG_INDEX;
		write_index : in T_REG_INDEX;
		incdec_index : in T_REG_INDEX;
		input : in T_REG;
		reg1_output : out T_REG;
		reg2_output : out T_REG;
		reg3_output : out T_REG
	);
end entity;

architecture behavioral of registers is
	signal register_file : T_REGS := (others => DEFAULT_REG);
begin
	process (reset, clock)
	begin
		if (reset = '1') then
			register_file <= (others => DEFAULT_REG);
		elsif (clock'Event and clock = '1') then
			if (clear = '1') then
--pragma synthesis_off
				report "Registers: Clearing reg " & to_hstring(write_index);
--pragma synthesis_on
				register_file (to_integer(unsigned(write_index))) <= DEFAULT_REG;
			elsif (write = '1') then
				report "Registers: Writing " & to_hstring(input) & " into reg " & to_hstring(write_index);
				--pragma synthesis_on
				register_file (to_integer(unsigned(write_index))) <= input;
				--pragma synthesis_off
			end if;
			if (inc = '1') then
--pragma synthesis_off
				report "Registers: Incrementing reg " & to_hstring(incdec_index);
--pragma synthesis_on
				register_file (to_integer(unsigned(incdec_index))) <=
					register_file (to_integer(unsigned(incdec_index))) + 4;
			elsif (dec = '1') then
--pragma synthesis_off
				report "Registers: Decrementing reg " & to_hstring(incdec_index);
--pragma synthesis_on
				register_file (to_integer(unsigned(incdec_index))) <=
					register_file (to_integer(unsigned(incdec_index))) - 4;
			end if;
		end if;
	end process;

	reg1_output <= register_file (to_integer(unsigned(read_reg1_index)));
	reg2_output <= register_file (to_integer(unsigned(read_reg2_index)));
	reg3_output <= register_file (to_integer(unsigned(read_reg3_index)));
end architecture;

---

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.P_REGISTERS.all;

entity programcounter is
	port (
		clock : in STD_LOGIC;
		reset : in STD_LOGIC;
		jump : in STD_LOGIC;
		input : in T_REG;
		increment : in STD_LOGIC;
		output : out T_REG
	);
end entity;

architecture behavioral of programcounter is
	signal pc : T_REG := DEFAULT_PC;
begin
	process (reset, clock)
	begin
		if (reset = '1') then
			pc <= DEFAULT_PC;
		elsif (clock'Event and clock = '1') then
			if (jump = '1') then
--pragma synthesis_off
				report "PC: jumping to " & to_hstring(input);
--pragma synthesis_on
				pc <= input;
			elsif (increment = '1') then
				pc <= pc + 4;
--pragma synthesis_off
				report "PC: incrementing from " & to_hstring(pc);
--pragma synthesis_on
			end if;
		end if;
	end process;

	output <= pc;
end architecture;

---

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.P_REGISTERS.all;

entity temporary is
	port (
		clock : in STD_LOGIC;
		reset : in STD_LOGIC;
		write : in STD_LOGIC;
		input : in T_REG;
		output : out T_REG
	);
end entity;

architecture behavioral of temporary is
	signal temp : T_REG := DEFAULT_REG;
begin
	process (reset, clock)
	begin
		if (reset = '1') then
			temp <= default_reg;
		elsif (clock'Event and clock = '1') then
			if (write = '1') then
--pragma synthesis_off
				report "Temporary: Writing " & to_hstring(input);
--pragma synthesis_on
				temp <= input;
			end if;
		end if;
	end process;

	output <= temp;
end architecture;

---

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.P_REGISTERS.all;
use work.P_CONTROL.all;
use work.P_ALU.all;
use work.P_BUSINTERFACE.all;

entity instruction is
	port (
		reset : in STD_LOGIC;
		clock : in STD_LOGIC;
		write : in STD_LOGIC;
		input : in T_REG;
		opcode : out T_OPCODE;
		quick_word : out STD_LOGIC_VECTOR (15 downto 0);
		quick_bytenybble : out STD_LOGIC_VECTOR (11 downto 0);
		reg1_index : out T_REG_INDEX;
		reg2_index : out T_REG_INDEX;
		reg3_index : out T_REG_INDEX;
		cycle_width : out T_CYCLE_WIDTH;
		cycle_signed : out STD_LOGIC;
		condition : out T_CONDITION;
		alu_op : out T_ALU_OP
	);
end entity;

architecture behavioral of instruction is
	signal instruction_register : T_REG := DEFAULT_REG;
begin
	process (reset, clock)
	begin
		if (reset = '1') then
			instruction_register <= DEFAULT_REG;
		elsif (clock'event and clock = '1') then
			if (write = '1') then
--pragma synthesis_off
				report "instruction: writing " & to_hstring(input);
--pragma synthesis_on
				instruction_register <= input;
			end if;
		end if;
	end process;

	-- shared
	opcode <= instruction_register (31 downto 24);
	reg1_index <= instruction_register (23 downto 20);
	reg2_index <= instruction_register (19 downto 16);
	reg3_index <= instruction_register (11 downto 8);
	quick_word <= instruction_register (15 downto 0);
	quick_bytenybble <= instruction_register (11 downto 0);

	cycle_width <= instruction_register (15 downto 14);
	cycle_signed <= instruction_register (13);

	condition <= instruction_register (15 downto 12);

	-- LSB of opcode; 0=multi, 1=single
	alu_op <= instruction_register (24) & instruction_register (15 downto 12);

end architecture;