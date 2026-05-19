RTL = rtl/alu.sv rtl/regfile.sv rtl/forwarding_unit.sv rtl/hazard_unit.sv rtl/branch_unit.sv rtl/core.sv

.PHONY: sim formal cover ci clean

sim:
	mkdir -p build waveforms
	iverilog -g2012 -o build/tb.vvp $(RTL) sim/tb.sv
	vvp build/tb.vvp

formal:
	sby -f formal/riscv.sby

cover:
	sby -f formal/cover.sby

ci: formal cover sim

clean:
	rm -rf build waveforms/*.vcd formal/riscv formal/cover
