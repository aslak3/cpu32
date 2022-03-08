library IEEE;
use IEEE.STD_LOGIC_1164.all;

package P_REGS is
	subtype T_REG is STD_LOGIC_VECTOR (31 downto 0);
	type T_REGS is ARRAY (0 to 15) of T_REG;
	subtype T_REG_INDEX is STD_LOGIC_VECTOR (3 downto 0);

	constant DEFAULT_REG : T_REG := (others => '0');
	constant DEFAULT_PC : T_REG := (others => '0');
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.P_REGS.all;

entity registers is
	port (
		clock : in STD_LOGIC;
		reset : in STD_LOGIC;
		clear : in STD_LOGIC;
		write : in STD_LOGIC;
		inc : in STD_LOGIC;
		dec : in STD_LOGIC;
		read_left_index : in T_REG_INDEX;
		read_right_index : in T_REG_INDEX;
		write_index : in T_REG_INDEX;
		incdec_index : in T_REG_INDEX;
		input : in T_REG;
		left_output : out T_REG;
		right_output : out T_REG
	);
end entity;

architecture behavioral of registers is
	signal registers : T_REGS := (others => DEFAULT_REG);
begin
	process (reset, clock)
	begin
		if (reset = '1') then
			registers <= (others => DEFAULT_REG);
		elsif (clock'Event and clock = '1') then
			if (clear = '1') then
--pragma synthesis_off
				report "Registers: Clearing reg " & to_hstring(write_index);
--pragma synthesis_on
				registers (to_integer(unsigned(write_index))) <= DEFAULT_REG;
			elsif (write = '1') then
--pragma synthesis_off
				report "Registers: Writing " & to_hstring(input) & " into reg " & to_hstring(write_index);
--pragma synthesis_on
				registers (to_integer(unsigned(write_index))) <= input;
			end if;
			if (inc = '1') then
--pragma synthesis_off
				report "Registers: Incrementing reg " & to_hstring(incdec_index);
--pragma synthesis_on
				registers (to_integer(unsigned(incdec_index))) <=
					registers (to_integer(unsigned(incdec_index))) + 4;
			elsif (dec = '1') then
--pragma synthesis_off
				report "Registers: Decrementing reg " & to_hstring(incdec_index);
--pragma synthesis_on
				registers (to_integer(unsigned(incdec_index))) <=
					registers (to_integer(unsigned(incdec_index))) - 4;
			end if;
		end if;
	end process;

	left_output <= registers (to_integer(unsigned(read_left_index)));
	right_output <= registers (to_integer(unsigned(read_right_index)));

end architecture;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.P_REGS.all;

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
--pragma synthesis_off
				report "PC: incrementing";
--pragma synthesis_on
				pc <= pc + 4;
			end if;
		end if;
	end process;

	output <= pc;
end architecture;

---

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.P_REGS.all;

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
use work.P_REGS.all;
--use work.P_CONTROL.all;
--use work.P_ALU.all;

entity instruction is
	port (
		instruction : in T_REG;
--		opcode : out T_OPCODE;
		immediate_word : out STD_LOGIC_VECTOR (15 downto 0);
		address_index : out T_REG_INDEX;
--		transfer_type : out T_TRANSFER_TYPE;
--		flow_cares : out T_FLOWTYPE;
--		flow_polarity : out T_FLOWTYPE;
		destination_index : out T_REG_INDEX;
		left_index : out T_REG_INDEX;
		right_index : out T_REG_INDEX;
		alu_op : out STD_LOGIC_VECTOR (3 downto 0);
		alu_immediate : out STD_LOGIC_VECTOR (7 downto 0);
		register_mask : out STD_LOGIC_VECTOR (15 downto 0)
	);
end entity;

architecture behavioral of instruction is
begin
--	opcode <= instruction (31 downto 24);

	destination_index <= instruction (19 downto 16);
	immediate_word <= instruction (15 downto 0);

	address_index <= instruction (23 downto 20);
--	transfer_type <= instruction (15 downto 13);

--	flow_cares <= instruction (15 downto 12);
--	flow_polarity <= instruction (11 downto 8);

	destination_index <= instruction (23 downto 20);
	left_index <= instruction (19 downto 16);
	right_index <= instruction (15 downto 12);
	alu_op <= instruction (11 downto 8);
	alu_immediate <= instruction (7 downto 0);

	register_mask <= instruction (15 downto 0);
end architecture;
