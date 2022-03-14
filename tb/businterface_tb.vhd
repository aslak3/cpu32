library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.P_BUSINTERFACE.all;

entity businterface_tb is
end entity;

architecture behavioral of businterface_tb is
	signal dut_clock : STD_LOGIC;
	signal dut_reset : STD_LOGIC;

	signal dut_cpu_address : STD_LOGIC_VECTOR (31 downto 0);
	signal dut_cpu_bus_active : STD_LOGIC;
	signal dut_cpu_cycle_width : T_CYCLE_WIDTH;
	signal dut_cpu_data_out : STD_LOGIC_VECTOR (31 downto 0);
	signal dut_cpu_data_in : STD_LOGIC_VECTOR (31 downto 0);
	signal dut_cpu_read : STD_LOGIC;
	signal dut_cpu_write : STD_LOGIC;

	signal dut_businterface_address : STD_LOGIC_VECTOR (31 downto 2);
	signal dut_businterface_data_in : STD_LOGIC_VECTOR (31 downto 0);
	signal dut_businterface_data_out : STD_LOGIC_VECTOR (31 downto 0);
	signal dut_businterface_data_strobes : STD_LOGIC_VECTOR (3 downto 0);
	signal dut_businterface_error : STD_LOGIC;
	signal dut_businterface_read : STD_LOGIC;
	signal dut_businterface_write : STD_LOGIC;
begin
	dut: entity work.businterface port map (
		clock => dut_clock,
		reset => dut_reset,

		cpu_address => dut_cpu_address,
		cpu_bus_active => dut_cpu_bus_active,
		cpu_cycle_width => dut_cpu_cycle_width,
		cpu_data_out => dut_cpu_data_out,
		cpu_data_in => dut_cpu_data_in,
		cpu_read => dut_cpu_read,
		cpu_write => dut_cpu_write,

		businterface_address => dut_businterface_address,
		businterface_data_in => dut_businterface_data_in,
		businterface_data_out => dut_businterface_data_out,
		businterface_data_strobes => dut_businterface_data_strobes,
		businterface_error => dut_businterface_error,
		businterface_read => dut_businterface_read,
		businterface_write => dut_businterface_write
	);

	process
		procedure run_test (
			cpu_address : STD_LOGIC_VECTOR (31 downto 0);
			cpu_bus_active : STD_LOGIC;
			cpu_cycle_width : T_CYCLE_WIDTH;
			cpu_data_out : STD_LOGIC_VECTOR (31 downto 0);
			cpu_read : STD_LOGIC;
			cpu_write : STD_LOGIC;
			businterface_data_in : STD_LOGIC_VECTOR (31 downto 0);
			
			exp_cpu_data_in : STD_LOGIC_VECTOR (31 downto 0);
			exp_businterface_address : STD_LOGIC_VECTOR (31 downto 0);
			exp_businterface_data_out : STD_LOGIC_VECTOR (31 downto 0);
			exp_businterface_data_strobes : STD_LOGIC_VECTOR (3 downto 0);
			exp_businterface_error : STD_LOGIC;
			exp_businterface_read : STD_LOGIC;
			exp_businterface_write : STD_LOGIC
			) is
		begin
			report "cpu_address=" & to_hstring(cpu_address) & " cpu_cycle_width=" & to_hstring(cpu_cycle_width) &
				" cpu_data_out=" & to_hstring(cpu_data_out) & " cpu_read=" & to_string(cpu_read) & " cpu_write=" & to_string(cpu_write) &
				" businterface_data_in=" & to_hstring(businterface_data_in);

			dut_cpu_address <= cpu_address;
			dut_cpu_cycle_width <= cpu_cycle_width;
			dut_cpu_data_out <= cpu_data_out;
			dut_cpu_read <= cpu_read;
			dut_cpu_write <= cpu_write;
			dut_businterface_data_in <= businterface_data_in;
	
			wait for 1 ns;
			dut_clock <= '1';
			wait for 1 ns;
			dut_clock <= '0';

			assert dut_businterface_error = exp_businterface_error
				report "businterface_error=" & to_string(dut_businterface_error) severity failure;

			-- if businterface_error, then don't bother checking the rest			
			if (dut_businterface_error = '0') then
				assert dut_cpu_data_in = exp_cpu_data_in
					report "cpu_data_in=" & to_hstring(dut_cpu_data_in) severity failure;
				assert dut_businterface_address = exp_businterface_address (31 downto 2)
					report "businterface_address=" & to_hstring(dut_businterface_address) severity failure;
				assert dut_businterface_data_out = exp_businterface_data_out
					report "businterface_data_out=" & to_hstring(dut_businterface_data_out) severity failure;
				assert dut_businterface_data_strobes = exp_businterface_data_strobes			
					report "businterface_data_strobes=" & to_string(dut_businterface_data_strobes) severity failure;
				assert dut_businterface_error = exp_businterface_error
					report "businterface_error=" & to_string(dut_businterface_error) severity failure;
				assert dut_businterface_read = exp_businterface_read
					report "businterface_read=" & to_string(dut_businterface_read) severity failure;
				assert dut_businterface_write = exp_businterface_write
					report "businterface_write=" & to_string(dut_businterface_write) severity failure;
			end if;
		end procedure;
	begin
		-- TODO: reset in businterface
		dut_reset <= '0';
		
		run_test(x"00000000", '1', CW_BYTE, x"000000ab", '1', '0', x"12345678",
			x"ffffff12", x"00000000", x"abffffff", "1000", '0', '1', '0');
		run_test(x"00000001", '1', CW_BYTE, x"000000ab", '1', '0', x"12345678",
			x"ffffff34", x"00000000", x"ffabffff", "0100", '0', '1', '0');
		run_test(x"00000002", '1', CW_BYTE, x"000000ab", '1', '0', x"12345678",
			x"ffffff56", x"00000000", x"ffffabff", "0010", '0', '1', '0');
		run_test(x"00000003", '1', CW_BYTE, x"000000ab", '1', '0', x"12345678",
			x"ffffff78", x"00000000", x"ffffffab", "0001", '0', '1', '0');

		run_test(x"00000000", '1', CW_WORD, x"0000abcd", '1', '0', x"12345678",
			x"ffff1234", x"00000000", x"abcdffff", "1100", '0', '1', '0');
		run_test(x"00000002", '1', CW_WORD, x"0000abcd", '1', '0', x"12345678",
			x"ffff5678", x"00000000", x"ffffabcd", "0011", '0', '1', '0');

		run_test(x"00000000", '1', CW_LONG, x"abcdef12", '1', '0', x"12345678",
			x"12345678", x"00000000", x"abcdef12", "1111", '0', '1', '0');

		run_test(x"00000001", '1', CW_WORD, x"12345678", '1', '0', x"12345678",
			x"12345678", x"00000000", x"ffffabcd", "0011", '1', '1', '0');
		run_test(x"00000003", '1', CW_WORD, x"12345678", '1', '0', x"12345678",
			x"12345678", x"00000000", x"ffffabcd", "0011", '1', '1', '0');
		run_test(x"00000001", '1', CW_LONG, x"abcdef12", '1', '0', x"12345678",
			x"12345678", x"00000000", x"abcdef12", "1111", '1', '1', '0');
		run_test(x"00000002", '1', CW_LONG, x"abcdef12", '1', '0', x"12345678",
			x"12345678", x"00000000", x"abcdef12", "1111", '1', '1', '0');
		run_test(x"00000003", '1', CW_LONG, x"abcdef12", '1', '0', x"12345678",
			x"12345678", x"00000000", x"abcdef12", "1111", '1', '1', '0');

		report "+++all good";
		std.env.finish;
	end process;

end architecture;
