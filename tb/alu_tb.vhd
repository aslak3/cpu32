library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.P_ALU.all;
use work.P_ALU_OPS.all;

entity alu_tb is
end entity;

architecture behavioral of alu_tb is
	signal alu_op : T_ALU_OP;
	signal alu_reg2, alu_reg3 : STD_LOGIC_VECTOR (31 downto 0);  -- inputs
	signal alu_carry_in : STD_LOGIC;
	signal alu_result : STD_LOGIC_VECTOR (31 downto 0);  -- outputs
	signal alu_carry_out : STD_LOGIC;
	signal alu_zero_out : STD_LOGIC;
	signal alu_neg_out : STD_LOGIC;
	signal alu_over_out : STD_LOGIC;

begin
	dut: entity work.alu port map (
		op => alu_op,
		reg2 => alu_reg2,
		reg3 => alu_reg3,
		carry_in => alu_carry_in,
		result => alu_result,
		carry_out => alu_carry_out,
		zero_out => alu_zero_out,
		neg_out => alu_neg_out,
		over_out => alu_over_out
	);

	process
		procedure run_test (
			op : T_ALU_OP;
			reg2 : STD_LOGIC_VECTOR (31 downto 0);
			reg3 : STD_LOGIC_VECTOR (31 downto 0);
			carry_in : STD_LOGIC;
			exp_result : STD_LOGIC_VECTOR (31 downto 0);
			exp_carry : STD_LOGIC;
			exp_zero : STD_LOGIC;
			exp_neg : STD_LOGIC;
			exp_over : STD_LOGIC
			) is
		begin
			report "op=" & to_string(op) & " reg2=" & to_hstring(reg2) &
				" reg3=" & to_hstring(reg3) & " carry=" & to_string(carry_in);

			alu_op <= op;
			alu_reg2 <= reg2;
			alu_reg3 <= reg3;
			alu_carry_in <= carry_in;

			wait for 1 ns;

			report "result=" & to_hstring(alu_result);
			report "carry=" & to_string(alu_carry_out) & " zero=" & to_string(alu_zero_out) &
				" neg=" & to_string(alu_neg_out) & " over=" & to_string(alu_over_out);

			assert alu_result = exp_result
				report "result got " & to_hstring(alu_result) & " expected " & to_hstring(exp_result) severity failure;
			assert alu_carry_out = exp_carry
				report "carry got " & to_string(alu_carry_out) & " expected " & to_string(exp_carry) severity failure;
			assert alu_zero_out = exp_zero
				report "zero got " & to_string(alu_zero_out) & " expected " & to_string(exp_zero) severity failure;
			assert alu_neg_out = exp_neg
				report "negative got  " & to_string(alu_neg_out) & " expected " & to_string(exp_neg) severity failure;
			assert alu_over_out = exp_over
				report "overflow got  " & to_string(alu_over_out) & " expected " & to_string(exp_over) severity failure;

		end procedure;
	begin
		-- One destination, one operand
		run_test(op_add,			x"00000001", x"00000002" ,'0',	x"00000003", '0', '0', '0', '0');
		run_test(op_addc,			x"00000001", x"00000002" ,'0',	x"00000003", '0', '0', '0', '0');
		run_test(op_addc,			x"00000001", x"00000002" ,'1',	x"00000004", '0', '0', '0', '0');
		run_test(op_add,			x"ffffffff", x"00000001" ,'0',	x"00000000", '1', '1', '0', '0');
		run_test(op_add,			x"40000000", x"40000000" ,'0',	x"80000000", '0', '0', '1', '1');
		run_test(op_addc,			x"ffffffff", x"00000000" ,'1',	x"00000000", '1', '1', '0', '0');
		run_test(op_addc,			x"80000000", x"7fffffff" ,'0',	x"ffffffff", '0', '0', '1', '0');
		run_test(op_addc,			x"7ffffffe", x"00000001" ,'1',	x"80000000", '0', '0', '1', '1');

		run_test(op_sub,			x"00000001", x"00000002", '0',	x"ffffffff", '1', '0', '1', '0');
		run_test(op_subc, 			x"00000001", x"00000002", '0',	x"ffffffff", '1', '0', '1', '0');
		run_test(op_subc,			x"00000001", x"00000002", '1',	x"fffffffe", '1', '0', '1', '0');
		run_test(op_sub,			x"ffffffff", x"00000001", '0',	x"fffffffe", '0', '0', '1', '0');
		run_test(op_sub,			x"80000000", x"00000001", '0',	x"7fffffff", '0', '0', '0', '1');
		run_test(op_subc,			x"ffffffff", x"00000000", '1',	x"fffffffe", '0', '0', '1', '0');
		run_test(op_subc,			x"ffffffff", x"ffffffff", '1',	x"ffffffff", '1', '0', '1', '0');
		run_test(op_subc,			x"ffffffff", x"ffffffff", '0',	x"00000000", '0', '1', '0', '0');
		run_test(op_subc,			x"00000000", x"80000000", '0',	x"80000000", '1', '0', '1', '1');
		run_test(op_subc,			x"00000000", x"7fffffff", '0',	x"80000001", '1', '0', '1', '0');

		run_test(op_and,			x"80808080", x"ff00ff00", '0',	x"80008000", '0', '0', '1', '0');
		run_test(op_and,			x"08800880", x"ff00ff00", '0',	x"08000800", '0', '0', '0', '0');
		run_test(op_and,			x"80808080", x"08080808", '0',	x"00000000", '0', '1', '0', '0');

		run_test(op_or,				x"80808080", x"ff00ff00", '0',	x"ff80ff80", '0', '0', '1', '0');
		run_test(op_or,				x"08800880", x"ff00ff00", '0',	x"ff80ff80", '0', '0', '1', '0');
		run_test(op_or,				x"80808080", x"08080808", '0',	x"88888888", '0', '0', '1', '0');
		run_test(op_or,				x"00000000", x"00000000", '0',	x"00000000", '0', '1', '0', '0');
		run_test(op_or,				x"10001000", x"00010001", '0',	x"10011001", '0', '0', '0', '0');

		run_test(op_xor,			x"80808080", x"ff00ff00", '0',	x"7f807f80", '0', '0', '0', '0');
		run_test(op_xor,			x"08800880", x"ff00ff00", '0',	x"f780f780", '0', '0', '1', '0');
		run_test(op_xor,			x"80808080", x"08080808", '0',	x"88888888", '0', '0', '1', '0');
		run_test(op_xor,			x"00000000", x"00000000", '0',	x"00000000", '0', '1', '0', '0');
		run_test(op_xor,			x"10001000", x"00010001", '0',	x"10011001", '0', '0', '0', '0');

		run_test(op_copy,			x"00000000", x"f0f0f0f0", '0',	x"f0f0f0f0", '0', '0', '1', '0');
		run_test(op_copy,			x"00000000", x"00000000", '0',	x"00000000", '0', '1', '0', '0');

		run_test(op_comp,			x"00000002", x"00000001", '0', x"00000002", '0', '0', '0', '0');
		run_test(op_comp,			x"00000001", x"00000002", '0', x"00000001", '1', '0', '1', '0');
		run_test(op_comp,			x"00000001", x"00000001", '0', x"00000001", '0', '1', '0', '0');
		run_test(op_comp,			x"80000000", x"00000000", '0', x"80000000", '0', '0', '1', '0');

		run_test(op_bit,			x"ff00ff00", x"80808080", '0',	x"ff00ff00", '0', '0', '1', '0');
		run_test(op_bit,			x"ff00ff00", x"08800880", '0',	x"ff00ff00", '0', '0', '0', '0');
		run_test(op_bit,			x"08080808", x"80808080", '0',	x"08080808", '0', '1', '0', '0');

		run_test(op_mulu,			x"00000004", x"00001000", '0', 	x"00004000", '0', '0', '0', '0');
		run_test(op_mulu,			x"0000ffff", x"00000000", '0', 	x"00000000", '0', '1', '0', '0');
		run_test(op_mulu,			x"00000000", x"00000001", '0', 	x"00000000", '0', '1', '0', '0');
		run_test(op_mulu,			x"0000ffff", x"0000ffff", '0', 	x"fffe0001", '0', '0', '1', '0');

		run_test(op_muls,			x"0000ffff", x"00000001", '0', 	x"ffffffff", '0', '0', '1', '0'); -- -1 * 1 = -1
		run_test(op_muls,			x"0000ffff", x"0000ffff", '0', 	x"00000001", '0', '0', '0', '0'); -- -1 * -1 = 1
		run_test(op_muls,			x"00000001", x"00000001", '0', 	x"00000001", '0', '0', '0', '0'); -- 1 * 1 = 1
		run_test(op_muls,			x"00007fff", x"00007fff", '0', 	x"3fff0001", '0', '0', '0', '0');
		run_test(op_muls,			x"00007fff", x"00008000", '0', 	x"c0008000", '0', '0', '1', '0');

		-- no operand
		run_test(op_inc,			x"00000000" ,x"00000000", '0',	x"00000001", '0', '0', '0', '0');
		run_test(op_inc,			x"7fffffff" ,x"00000000", '0',	x"80000000", '0', '0', '1', '0');
		run_test(op_inc,			x"ffffffff" ,x"00000000", '0',	x"00000000", '1', '1', '0', '0');

		run_test(op_dec,			x"00000000" ,x"00000000", '0',	x"ffffffff", '1', '0', '1', '0');
		run_test(op_dec,			x"00000001" ,x"00000000", '0',	x"00000000", '0', '1', '0', '0');
		run_test(op_dec,			x"ffffffff" ,x"00000000", '0',	x"fffffffe", '0', '0', '1', '0');

		run_test(op_not,			x"80808080", x"00000000", '0',	x"7f7f7f7f", '0', '0', '0', '0');
		run_test(op_not,			x"ffffffff", x"00000000", '0',	x"00000000", '0', '1', '0', '0');
		run_test(op_not,			x"00000000", x"00000000", '0',	x"ffffffff", '0', '0', '1', '0');

		run_test(op_logic_left,		x"80808080", x"00000000", '0',	x"01010100", '1', '0', '0', '0');
		run_test(op_logic_left,		x"ffffffff", x"00000000", '0',	x"fffffffe", '1', '0', '1', '0');
		run_test(op_logic_left,		x"00000000", x"00000000", '0',	x"00000000", '0', '1', '0', '0');
		run_test(op_logic_left,		x"00000001", x"00000000", '0',	x"00000002", '0', '0', '0', '0');

		run_test(op_logic_right,	x"80808080", x"00000000", '0',	x"40404040", '0', '0', '0', '0');
		run_test(op_logic_right,	x"ffffffff", x"00000000", '0',	x"7fffffff", '1', '0', '0', '0');
		run_test(op_logic_right,	x"00000000", x"00000000", '0',	x"00000000", '0', '1', '0', '0');

		run_test(op_arith_left,		x"80808080", x"00000000", '0',	x"01010100", '1', '0', '0', '1');
		run_test(op_arith_left,		x"ffffffff", x"00000000", '0',	x"fffffffe", '1', '0', '1', '0');
		run_test(op_arith_left,		x"00000000", x"00000000", '0',	x"00000000", '0', '1', '0', '0');
		run_test(op_arith_left,		x"00000001", x"00000000", '0',	x"00000002", '0', '0', '0', '0');

		run_test(op_arith_right,	x"80808080", x"00000000", '0',	x"c0404040", '0', '0', '1', '0');
		run_test(op_arith_right,	x"ffffffff", x"00000000", '0',	x"ffffffff", '1', '0', '1', '0');
		run_test(op_arith_right,	x"00000000", x"00000000", '0',	x"00000000", '0', '1', '0', '0');

		run_test(op_neg,			x"00000001", x"00000000", '0', x"ffffffff", '1', '0', '1', '0');
		run_test(op_neg,			x"ffffffff", x"00000000", '0', x"00000001", '1', '0', '0', '0');
		run_test(op_neg,			x"00000000", x"00000000", '0', x"00000000", '0', '1', '0', '0');

		run_test(op_test,			x"00000001", x"00000000", '0', x"00000001", '0', '0', '0', '0');
		run_test(op_test,			x"ffffffff", x"00000000", '0', x"ffffffff", '0', '0', '1', '0');
		run_test(op_test,			x"00000000", x"00000000", '0', x"00000000", '0', '1', '0', '0');

		report "+++all good";
		std.env.finish;
	end process;

end architecture;
