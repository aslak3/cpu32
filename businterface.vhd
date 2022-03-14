library IEEE;
use IEEE.STD_LOGIC_1164.all;

package P_BUSINTERFACE is
	subtype T_CYCLE_WIDTH is STD_LOGIC_VECTOR (1 downto 0);

	constant CW_BYTE :	T_CYCLE_WIDTH := "00";
	constant CW_WORD :	T_CYCLE_WIDTH := "01";
	constant CW_LONG :	T_CYCLE_WIDTH := "10";
	constant CW_NULL :	T_CYCLE_WIDTH := "11";
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.P_BUSINTERFACE.all;

entity businterface is
	port (
		clock : in STD_LOGIC;
		reset : in STD_LOGIC;

		cpu_address : in STD_LOGIC_VECTOR (31 downto 0);
		cpu_bus_active : in STD_LOGIC;
		cpu_cycle_width : in T_CYCLE_WIDTH;
		cpu_data_out : in STD_LOGIC_VECTOR (31 downto 0);
		cpu_data_in : out STD_LOGIC_VECTOR (31 downto 0);
		cpu_read : in STD_LOGIC;
		cpu_write : in STD_LOGIC;

		businterface_address : out STD_LOGIC_VECTOR (31 downto 2);
		businterface_data_in : in STD_LOGIC_VECTOR (31 downto 0);
		businterface_data_out : out STD_LOGIC_VECTOR (31 downto 0);
		businterface_data_strobes : out STD_LOGIC_VECTOR (3 downto 0);
		businterface_error : out STD_LOGIC;
		businterface_read : out STD_LOGIC;
		businterface_write : out STD_LOGIC
	);
end entity;

architecture behavioral of businterface is
begin
	process (clock)
	begin
		if (clock'Event and clock = '1') then
			businterface_data_strobes <= (others => '0');
			businterface_error <= '0';

			businterface_address <= cpu_address (31 downto 2);
			if (cpu_cycle_width = CW_BYTE) then
				case cpu_address (1 downto 0) is
					when "00" =>
						businterface_data_strobes <= "1000";
						businterface_data_out <= cpu_data_out (7 downto 0) & x"ff" & x"ff" & x"ff";
						cpu_data_in <= x"ff" & x"ff" & x"ff" & businterface_data_in (31 downto 24);					
					when "01" =>
						businterface_data_strobes <= "0100";
						businterface_data_out <= x"ff" & cpu_data_out (7 downto 0) & x"ff" & x"ff";
						cpu_data_in <= x"ff" & x"ff" & x"ff" & businterface_data_in (23 downto 16);
					when "10" =>
						businterface_data_strobes <= "0010";
						businterface_data_out <= x"ff" & x"ff" & cpu_data_out (7 downto 0) & x"ff";
						cpu_data_in <= x"ff" & x"ff" & x"ff" & businterface_data_in (15 downto 8);
					when "11" =>
						businterface_data_strobes <= "0001";
						businterface_data_out <= x"ff" & x"ff" & x"ff" & cpu_data_out (7 downto 0);
						cpu_data_in <= x"ff" & x"ff" & x"ff" & businterface_data_in (7 downto 0);
					when others =>
				end case;
			elsif (cpu_cycle_width = CW_WORD) then
				case cpu_address (1 downto 0) is
					when "00" =>
						businterface_data_strobes <= "1100";
						businterface_data_out <= cpu_data_out (15 downto 0) & x"ffff";
						cpu_data_in <= x"ffff" & businterface_data_in (31 downto 16);						
					when "01" =>
						businterface_error <= '1';
					when "10" =>
						businterface_data_strobes <= "0011";
						businterface_data_out <= x"ffff" & cpu_data_out (15 downto 0);
						cpu_data_in <= x"ffff" & businterface_data_in (15 downto 0);						
					when "11" =>
						businterface_error <= '1';
					when others =>
				end case;
			elsif (cpu_cycle_width = CW_LONG) then
				case cpu_address (1 downto 0) is
					when "00" =>
						businterface_data_strobes <= "1111";
						businterface_data_out <= cpu_data_out (31 downto 0);
						cpu_data_in <= businterface_data_in (31 downto 0);						
					when "01" =>
						businterface_error <= '1';
					when "10" =>
						businterface_error <= '1';
					when "11" =>
						businterface_error <= '1';
					when others =>
				end case;
			else
				businterface_data_out <= x"ffffffff";
				cpu_data_in <= x"ffffffff";
			end if;

			-- could short these in the upper level, but will need them when multi-
			-- cycle operation is implemented.
			businterface_read <= cpu_read;
			businterface_write <= cpu_write;
		end if;
	end process;
end architecture;
