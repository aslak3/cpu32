library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use STD.TEXTIO.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use work.P_CONTROL.all;
use work.P_INTRAM.all;

entity cpu32_tb is
end entity;

architecture behavioral of cpu32_tb is
	signal clock50m : STD_LOGIC;
	signal clock : STD_LOGIC;
	signal clock_main : STD_LOGIC;
	signal reset : STD_LOGIC := '0';

	signal address : STD_LOGIC_VECTOR (29 downto 0);
	signal data_in : STD_LOGIC_VECTOR (31 downto 0);
	signal data_out : STD_LOGIC_VECTOR (31 downto 0);
	signal data_strobes : STD_LOGIC_VECTOR (3 downto 0);
	signal bus_error : STD_LOGIC;
	signal halted : STD_LOGIC;
	signal read : STD_LOGIC;
	signal write : STD_LOGIC;

	signal ram_data_in : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
	signal ram_data_out : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
	signal ram_write : STD_LOGIC;

	signal ledr : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
	signal sevenseg_data : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
	signal vga_data_in : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
begin
	process
	begin
		clock50m <= '0';
		wait for 1 ns;
		clock50m <= '1';
		wait for 1 ns;
	end process;

	intram: entity work.intram port map (
		address => address (7 downto 0),
		byteena => data_strobes,
		clock => clock50m,
		data => ram_data_in,
		wren => ram_write,
		q => ram_data_out
	);

	dut: entity work.cpu32 port map (
		clock => clock50m,
		clock_main => clock_main,
		reset => reset,
		address => address,
		data_in => data_in,
		data_out => data_out,
		data_strobes => data_strobes,
		bus_error => bus_error,
		read => read,
		write => write,
		halted => halted
	);

	ram_data_in <= data_out when (write = '1' and address (14 downto 12) = "000") else x"00000000";
	ram_write <= '1' when (write = '1' and address (14 downto 12) = "000") else '0';
	ledr <= data_out when (write = '1' and address (29 downto 26) = x"f");
	sevenseg_data <= data_out when (write = '1' and address (14 downto 7) = x"81");
	vga_data_in <= data_out when (write = '1' and address (14) = '1');

	data_in <= ram_data_out when (read = '1' and address (14 downto 12) = "000") else x"00000000";

	process (ledr)
	begin
		report "LED now at " & to_hstring(ledr);
	end process;

	process (sevenseg_data)
	begin
		report "7 segment now at " & to_hstring(sevenseg_data);
	end process;

	process (vga_data_in)
	begin
		report "VGA write " & to_hstring(address) & "=" & to_hstring(vga_data_in);
	end process;

	process (read, write)
	begin
		if (read = '1' or write = '1') then
		--	report "address=" & to_hstring(address & "00") & " read=" & STD_LOGIC'Image(read) &
		--		" write=" & STD_LOGIC'Image(write) & " data_in=" & to_hstring(data_in) &
		--		" data_out=" & to_hstring(data_out) & " data_strobes=" & to_string(data_strobes);
		end if;
	end process;

	process
		procedure clock_delay is
		begin
			wait until (clock_main = '0');
			wait until (clock_main = '1');
		end procedure;

		variable my_line : LINE;  -- type 'line' comes from textio
	begin
		reset <= '1';
		wait for 1 us;
		reset <= '0';

		for C in 0 to 8000 loop
			clock_delay;
			if (bus_error = '1' or halted = '1') then
				exit;
			end if;
		end loop;

		dump_ram_data;

		if (bus_error = '1') then
			report "Bus error at " & to_hstring(address & "00");
		elsif (halted = '1') then
			report "Processor HALT at " & to_hstring(address & "00");
		else
			report "Processor terminated due to excessive cycles at " & to_hstring(address & "00");
		end if;

		std.env.finish;
	end process;
end architecture;
