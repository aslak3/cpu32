library IEEE;
use IEEE.STD_LOGIC_1164.all;

package P_ALU is
	subtype T_ALU_OP is STD_LOGIC_VECTOR (4 downto 0);

	constant OP_ADD :			T_ALU_OP := '0' & x"0";
	constant OP_ADDC :			T_ALU_OP := '0' & x"1";
	constant OP_SUB :			T_ALU_OP := '0' & x"2";
	constant OP_SUBC :			T_ALU_OP := '0' & x"3";
	constant OP_AND :			T_ALU_OP := '0' & x"4";
	constant OP_OR : 			T_ALU_OP := '0' & x"5";
	constant OP_XOR : 			T_ALU_OP := '0' & x"6";
	constant OP_COPY :			T_ALU_OP := '0' & x"7";
	constant OP_COMP :			T_ALU_OP := '0' & x"8";
	constant OP_BIT :			T_ALU_OP := '0' & x"9";
	constant OP_MULU :			T_ALU_OP := '0' & x"a";
	constant OP_MULS :			T_ALU_OP := '0' & x"b";

	constant OP_INC : 			T_ALU_OP := '1' & x"0";
	constant OP_DEC : 			T_ALU_OP := '1' & x"1";
	constant OP_NOT : 			T_ALU_OP := '1' & x"2";
	constant OP_LOGIC_LEFT : 	T_ALU_OP := '1' & x"3";
	constant OP_LOGIC_RIGHT :	T_ALU_OP := '1' & x"4";
	constant OP_ARITH_LEFT : 	T_ALU_OP := '1' & x"5";
	constant OP_ARITH_RIGHT :	T_ALU_OP := '1' & x"6";
	constant OP_NEG :			T_ALU_OP := '1' & x"7";
	constant OP_SWAP :			T_ALU_OP := '1' & x"8";
	constant OP_TEST :			T_ALU_OP := '1' & x"9";
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.P_ALU.all;

entity alu is
	port (
		op : in T_ALU_OP;
		reg2, reg3 : in STD_LOGIC_VECTOR (31 downto 0);
		carry_in : in STD_LOGIC;
		result : out STD_LOGIC_VECTOR (31 downto 0);
		carry_out : out STD_LOGIC;
		zero_out : out STD_LOGIC;
		neg_out : out STD_LOGIC;
		over_out : out STD_LOGIC
	);
end entity;

architecture behavioural of alu is
begin
	process (reg2, reg3, op, carry_in)
		variable temp_reg2  : STD_LOGIC_VECTOR (32 downto 0) := (others => '0');
		variable temp_reg3 : STD_LOGIC_VECTOR (32 downto 0) := (others => '0');
		variable temp_result : STD_LOGIC_VECTOR (32 downto 0) := (others => '0');
		variable give_result : STD_LOGIC := '0';
	begin
		give_result := '1';
		temp_reg2 := '0' & reg2 (31 downto 0);
		temp_reg3 := '0' & reg3 (31 downto 0);

		case OP is
			when OP_ADD =>
				temp_result := temp_reg3 + temp_reg2;
			when OP_ADDC =>
				temp_result := temp_reg3 + temp_reg2 + carry_in;
			when OP_SUB =>
				temp_result := temp_reg3 - temp_reg2;
			when OP_SUBC =>
				temp_result := temp_reg3 - temp_reg2 - carry_in;
			when OP_AND =>
				temp_result := temp_reg3 and temp_reg2;
			when OP_OR =>
				temp_result := temp_reg3 or temp_reg2;
			when OP_XOR =>
				temp_result := temp_reg3 xor temp_reg2;
			when OP_COPY =>
				temp_result := temp_reg2;
			when OP_COMP =>
				temp_result := temp_reg3 - temp_reg2;
				give_result := '0';
			when OP_BIT =>
				temp_result := temp_reg3 and temp_reg2;
				give_result := '0';
			when OP_MULU =>
				TEMP_RESULT := '0' & STD_LOGIC_VECTOR(unsigned(temp_reg3 (15 downto 0)) * unsigned(temp_reg2 (15 downto 0)));
			when OP_MULS =>
				TEMP_RESULT := '0' & STD_LOGIC_VECTOR(signed(temp_reg3 (15 downto 0)) * signed(temp_reg2 (15 downto 0)));

			when OP_INC =>
				temp_result := temp_reg3 + 1;
			when OP_DEC =>
				temp_result := temp_reg3 - 1;
			when OP_NOT =>
				temp_result := not ('1' & temp_reg3 (31 downto 0));
			when OP_LOGIC_LEFT =>
				temp_result := temp_reg3 (31 downto 0) & '0';
			when OP_LOGIC_RIGHT =>
				temp_result := temp_reg3 (0) & '0' & temp_reg3 (31 downto 1);
			when OP_ARITH_LEFT =>
				temp_result := temp_reg3 (31 downto 0) & '0';
			when OP_ARITH_RIGHT =>
				temp_result := temp_reg3 (0) & temp_reg3 (31) & temp_reg3 (31 downto 1);
			when OP_NEG =>
				temp_result := not temp_reg3 + 1;
			when OP_SWAP =>
				temp_result := '0' & temp_reg3 (15 downto 0) & temp_reg3 (31 downto 16);
			when OP_TEST =>
				temp_result := temp_reg3;
				give_result := '0';

			when others =>
				temp_result := (others => '0');
		end case;

		if (GIVE_RESULT = '1') then
			result <= temp_result (31 downto 0);
		else
			result <= reg3;
		end if;

		carry_out <= temp_result (32);

		if (temp_result (31 downto 0) = x"00000000") then
			zero_out <= '1';
		else
			zero_out <= '0';
		end if;

		neg_out <= temp_result (31);

		-- When adding then if sign of result is different to the sign of both the
		-- operands then it is an overflow condition
		if (OP = OP_ADD or OP = OP_ADDC) then
			if (temp_reg2 (31) /= temp_result (31) and temp_reg3 (31) /= temp_result (31)) then
				over_out <= '1';
			else
				over_out <= '0';
			end if;
		-- Likewise for sub, but invert the reg2 sign for test as its a subtract
		elsif (OP = OP_SUB or OP = OP_SUBC) then
			if (temp_reg2 (31) = temp_result (31) and temp_reg3 (31) /= temp_result (31)) then
				over_out <= '1';
			else
				over_out <= '0';
			end if;
		-- For arith shift reg2, if the sign changed then it is an overflow
		elsif (OP = OP_ARITH_LEFT) then
			if (temp_reg3 (31) /= temp_result (31)) then
				over_out <= '1';
			else
				over_out <= '0';
			end if;
		else
			over_out <= '0';
		end if;
	end process;
end architecture;
