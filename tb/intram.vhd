library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use work.P_RAM_DATA.all;

entity intram is
	port (
		address : in STD_LOGIC_VECTOR (7 downto 0);
		byteena	 : in STD_LOGIC_VECTOR (3 downto 0);
		clock : in STD_LOGIC;
		data : in STD_LOGIC_VECTOR (31 downto 0);
		wren : in STD_LOGIC;
		q : out STD_LOGIC_VECTOR (31 downto 0)
	);
end entity;

architecture behavioral of intram is
begin
	process (clock)
	begin
		if (clock'Event and clock = '1') then
			if (wren = '1') then
				if (byteena (3) = '1') then
					ram_data (to_integer (unsigned (address))) (31 downto 24) <= data (31 downto 24);
				end if;
				if (byteena (2) = '1') then
					ram_data (to_integer (unsigned (address))) (23 downto 16) <= data (23 downto 16);
				end if;
				if (byteena (1) = '1') then
					ram_data (to_integer (unsigned (address))) (15 downto 8) <= data (15 downto 8);
				end if;
				if (byteena (0) = '1') then
					ram_data (to_integer (unsigned (address))) (7 downto 0) <= data (7 downto 0);
				end if;				
			end if;
			q <= ram_data (to_integer (unsigned (address)));
		end if;
	end process;
end architecture;
