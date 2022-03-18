library IEEE;
use IEEE.STD_LOGIC_1164.all;

package P_REGISTERS is
	subtype T_REG is STD_LOGIC_VECTOR (31 downto 0);
	type T_REGS is ARRAY (0 to 15) of T_REG;
	subtype T_REG_INDEX is STD_LOGIC_VECTOR (3 downto 0);

	constant DEFAULT_REG : T_REG := (others => '0');
	constant DEFAULT_PC : T_REG := (others => '0');
end package;
