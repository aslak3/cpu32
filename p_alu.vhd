library IEEE;
use IEEE.STD_LOGIC_1164.all;

package P_ALU is
	subtype T_ALU_OP is STD_LOGIC_VECTOR (4 downto 0);

	constant OP_ADD :			T_ALU_OP := '0' & x"0";
end package;

