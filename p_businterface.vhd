library IEEE;
use IEEE.STD_LOGIC_1164.all;

package P_BUSINTERFACE is
	subtype T_CYCLE_WIDTH is STD_LOGIC_VECTOR (1 downto 0);

	constant CW_BYTE :	T_CYCLE_WIDTH := "00";
	constant CW_WORD :	T_CYCLE_WIDTH := "01";
	constant CW_LONG :	T_CYCLE_WIDTH := "10";
	constant CW_NULL :	T_CYCLE_WIDTH := "11";
end package;
