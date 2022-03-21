GHDL_FLAGS = --std=08 --work=work -fsynopsys

all: packages registers alu businterface control clockdiv cpu32

packages:
	ghdl -a $(GHDL_FLAGS) p_registers.vhd p_alu.vhd p_control.vhd p_businterface.vhd

clockdiv:
	ghdl -a $(GHDL_FLAGS) clockdiv.vhd
registers:
	ghdl -a $(GHDL_FLAGS) registers.vhd tb/registers_tb.vhd
alu:
	ghdl -a $(GHDL_FLAGS) alu.vhd tb/alu_tb.vhd
control:
	ghdl -a $(GHDL_FLAGS) control.vhd
businterface:
	ghdl -a $(GHDL_FLAGS) businterface.vhd tb/businterface_tb.vhd
cpu32:
	ghdl -a $(GHDL_FLAGS) cpu32.vhd tb/intram.vhd #tb/cpu_tb.vhd

tests: registers_tests programcounter_tests temporary_tests alu_tests businterface_tests #cpu_tests

registers_tests:
	ghdl -e $(GHDL_FLAGS) registers_tb
	ghdl -r $(GHDL_FLAGS) registers_tb
programcounter_tests:
	ghdl -e $(GHDL_FLAGS) programcounter_tb
	ghdl -r $(GHDL_FLAGS) programcounter_tb
temporary_tests:
	ghdl -e $(GHDL_FLAGS) temporary_tb
	ghdl -r $(GHDL_FLAGS) temporary_tb
alu_tests:
	ghdl -e $(GHDL_FLAGS) alu_tb
	ghdl -r $(GHDL_FLAGS) alu_tb
businterface_tests:
	ghdl -e $(GHDL_FLAGS) businterface_tb
	ghdl -r $(GHDL_FLAGS) businterface_tb
cpu_tests:
	ghdl -e $(GHDL_FLAGS) businterface_tb
	ghdl -r $(GHDL_FLAGS) cpu_tb
