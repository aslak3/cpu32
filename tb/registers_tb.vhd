library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.P_REGISTERS.all;

entity registers_tb is
end entity;

architecture behavioral of registers_tb is
	signal clock : STD_LOGIC := '0';
	signal reset : STD_LOGIC := '0';
	signal regs_clear : STD_LOGIC := '0';
	signal regs_write : STD_LOGIC := '0';
	signal regs_inc : STD_LOGIC := '0';
	signal regs_dec : STD_LOGIC := '0';
	signal regs_read_reg1_index : T_REG_INDEX := (others => '0');
	signal regs_read_reg2_index : T_REG_INDEX := (others => '0');
	signal regs_read_reg3_index : T_REG_INDEX := (others => '0');
	signal regs_write_index : T_REG_INDEX := (others => '0');
	signal regs_incdec_index : T_REG_INDEX := (others => '0');
	signal regs_reg1_output : T_REG;
	signal regs_reg2_output : T_REG;
	signal regs_reg3_output : T_REG;
	signal regs_input : T_REG := (others => '0');
begin
dut: entity work.registers port map (
	clock => clock,
	reset => reset,
	clear => regs_clear,
	write => regs_write,
	inc => regs_inc,
	dec => regs_dec,
	read_reg1_index => regs_read_reg1_index,
	read_reg2_index => regs_read_reg2_index,
	read_reg3_index => regs_read_reg3_index,
	write_index => regs_write_index,
	incdec_index => regs_incdec_index,
	reg1_output => regs_reg1_output,
	reg2_output => regs_reg2_output,
	reg3_output => regs_reg3_output,
	input => regs_input
);

	process
		procedure clock_delay is
		begin
			clock <= '0';
			wait for 1 ns;
			clock <= '1';
			wait for 1 ns;
		end procedure;
	begin
		reset <= '1';
		wait for 1 ns;
		reset <= '0';

		regs_read_reg1_index <= "0000";
		regs_read_reg2_index <= "0001";
		regs_read_reg3_index <= "0010";

		clock_delay;

		assert regs_reg1_output = x"00000000" and regs_reg2_output = x"00000000" and regs_reg2_output = x"00000000"
			report "reset failed" severity failure;

		regs_input <= x"12345678";
		regs_write <= '1';
		regs_write_index <= "0000";

		clock_delay;

		regs_read_reg1_index <= "0000";
		regs_read_reg2_index <= "0000";
		regs_read_reg3_index <= "0000";
		regs_write <= '0';

		clock_delay;

		assert regs_reg1_output = x"12345678" and regs_reg2_output = x"12345678" and regs_reg2_output = x"12345678"
			report "read/write of reg 0 failed" severity failure;

		regs_clear <= '1';
		regs_write_index <= "0000";

		clock_delay;

		regs_clear <= '0';
		regs_read_reg1_index <= "0000";
		regs_read_reg2_index <= "0000";
		regs_write <= '0';

		clock_delay;

		assert regs_reg1_output = x"00000000" and regs_reg2_output = x"00000000" and regs_reg3_output = x"00000000"
			report "read/clear of reg 0 failed" severity failure;

		regs_inc <= '1';
		regs_incdec_index <= "0000";

		clock_delay;

		regs_inc <= '0';
		regs_read_reg1_index <= "0000";
		regs_read_reg2_index <= "0000";
		regs_read_reg3_index <= "0000";
		regs_write <= '0';

		clock_delay;

		assert regs_reg1_output = x"00000004" and regs_reg2_output = x"00000004" and regs_reg3_output = x"00000004"
			report "increment of reg 0 failed" severity failure;
		regs_dec <= '1';
		regs_incdec_index <= "0000";

		clock_delay;

		regs_dec <= '0';
		regs_read_reg1_index <= "0000";
		regs_read_reg2_index <= "0000";
		regs_read_reg3_index <= "0000";
		regs_write <= '0';

		clock_delay;

		assert regs_reg1_output = x"00000000" and regs_reg2_output = x"00000000" and regs_reg3_output = x"00000000"
			report "decrement of reg 0 failed" severity failure;

		regs_inc <= '1';
		regs_incdec_index <= "0000";
		regs_write <= '1';
		regs_write_index <= "0001";
		regs_input <= x"87654321";

		clock_delay;

		regs_inc <= '0';
		regs_read_reg1_index <= "0000";
		regs_read_reg2_index <= "0001";
		regs_read_reg3_index <= "0000";
		regs_write <= '0';

		clock_delay;

		assert regs_reg1_output = x"00000004" and regs_reg2_output = x"87654321" and regs_reg3_output = x"00000004"
			report "simultainius increment of reg 0 / write of reg 1 failed" severity failure;

		report "+++all good";
		std.env.finish;
	end process;
end architecture;

---

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.P_REGISTERS.all;

entity programcounter_tb is
end entity;

architecture behavioral of programcounter_tb is
	signal clock : STD_LOGIC;
	signal reset : STD_LOGIC;
	signal pc_jump : STD_LOGIC := '0';
	signal pc_input : T_REG := (others => '0');
	signal pc_increment : STD_LOGIC := '0';
	signal pc_output : T_REG;
begin
	dut: entity work.programcounter port map (
		clock => clock,
		reset => reset,
		jump => pc_jump,
		input => pc_input,
		increment => pc_increment,
		output => pc_output
	);

	process
		procedure clock_delay is
		begin
			clock <= '1';
			wait for 1 ns;
			clock <= '0';
			wait for 1 ns;
		end procedure;
	begin
		reset <= '1';
		wait for 1 ns;
		reset <= '0';

		clock_delay;

		assert pc_output = x"00000000"
			report "pc reset" severity failure;

		pc_increment <= '1';
		clock_delay;
		pc_increment <= '0';

		assert pc_output = x"00000004"
			report "pc increment" severity failure;

		pc_jump <= '1';
		pc_input <= x"12345678";
		clock_delay;
		pc_jump <= '0';

		assert pc_output = x"12345678"
			report "pc jump" severity failure;

		clock_delay;

		report "+++all good";
		std.env.finish;
	end process;
end architecture;

---

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.P_REGISTERS.all;

entity temporary_tb is
end entity;

architecture behavioral of temporary_tb is
	signal clock : STD_LOGIC;
	signal reset : STD_LOGIC;
	signal temporary_write : STD_LOGIC := '0';
	signal temporary_input : T_REG := (others => '0');
	signal temporary_output : T_REG;
begin
	dut: entity work.temporary port map (
		clock => clock,
		reset => reset,
		write => temporary_write,
		input => temporary_input,
		output => temporary_output
	);

	process
		procedure clock_delay is
		begin
			clock <= '1';
			wait for 1 ns;
			clock <= '0';
			wait for 1 ns;
		end procedure;
	begin
		reset <= '1';
		wait for 1 ns;
		reset <= '0';

		clock_delay;

		assert temporary_output = x"00000000"
			report "temporary reset" severity failure;

		temporary_write <= '1';
		temporary_input <= x"12345678";
		clock_delay;
		temporary_write <= '0';

		assert temporary_output = x"12345678"
			report "temporary set" severity failure;

		report "+++all good";
		std.env.finish;
	end process;
end architecture;
