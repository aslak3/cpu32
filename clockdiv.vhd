library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity clockdiv is
	port (
		clock : in STD_LOGIC;
		clock_main : out STD_LOGIC
	);
end entity;

architecture behavioral of clockdiv is
	signal counter : STD_LOGIC_VECTOR (2 downto 0) := (others => '0');
begin
	process (clock)
	begin
		if (clock'Event and clock = '1') then
			counter <= counter + 1;
		end if;
	end process;
	clock_main <= counter (2);
end architecture;
