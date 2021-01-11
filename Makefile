
TEST_OBJS = $(addsuffix .o,$(basename $(wildcard tests/*.S)))
FIRMWARE_OBJS = firmware/start.o firmware/irq.o firmware/print.o firmware/sieve.o firmware/multest.o firmware/stats.o
GCC_WARNS = -Wall -Wextra -Wshadow -Wundef

test: testbench.exe firmware/firmware.hex
	vvp -N testbench.exe

testbench.vcd: testbench.exe firmware/firmware.hex
	vvp -N $< +vcd

testbench_view: testbench.vcd
	gtkwave $< testbench.gtkw

test_sp: testbench_sp.exe firmware/firmware.hex
	vvp -N testbench_sp.exe

test_axi: testbench_axi.exe firmware/firmware.hex
	vvp -N testbench_axi.exe

test_synth: testbench_synth.exe firmware/firmware.hex
	vvp -N testbench_synth.exe

testbench.exe: testbench.v picorv32.v
	iverilog -o testbench.exe testbench.v picorv32.v
	chmod -x testbench.exe

testbench_sp.exe: testbench.v picorv32.v
	iverilog -o testbench_sp.exe -DSP_TEST testbench.v picorv32.v
	chmod -x testbench_sp.exe

testbench_axi.exe: testbench.v picorv32.v
	iverilog -o testbench_axi.exe -DAXI_TEST testbench.v picorv32.v
	chmod -x testbench_axi.exe

testbench_synth.exe: testbench.v synth.v
	iverilog -o testbench_synth.exe testbench.v synth.v
	chmod -x testbench_synth.exe

synth.v: picorv32.v scripts/yosys/synth_sim.ys
	yosys -qv3 -l synth.log scripts/yosys/synth_sim.ys

firmware/firmware.hex: firmware/firmware.bin firmware/makehex.py
	python3 firmware/makehex.py $< > $@

firmware/firmware.bin: firmware/firmware.elf
	riscv64-unknown-elf-objcopy -O binary $< $@
	chmod -x $@

firmware/firmware.elf: $(FIRMWARE_OBJS) $(TEST_OBJS) firmware/sections.lds
	riscv64-unknown-elf-gcc -Os -m32 -ffreestanding -nostdlib -o $@ \
		-Wl,-Bstatic,-T,firmware/sections.lds,-Map,firmware/firmware.map,--strip-debug \
		$(FIRMWARE_OBJS) $(TEST_OBJS) -lgcc
	chmod -x $@

firmware/start.o: firmware/start.S
	riscv64-unknown-elf-gcc -c -m32 -o $@ $<

firmware/%.o: firmware/%.c
	riscv64-unknown-elf-gcc -c -m32 -march=RV32I -Os $(GCC_WARNS) -ffreestanding -nostdlib -o $@ $<

tests/%.o: tests/%.S tests/riscv_test.h tests/test_macros.h
	riscv64-unknown-elf-gcc -c -m32 -o $@ -DTEST_FUNC_NAME=$(notdir $(basename $<)) \
		-DTEST_FUNC_TXT='"$(notdir $(basename $<))"' -DTEST_FUNC_RET=$(notdir $(basename $<))_ret $<

toc:
	gawk '/^-+$$/ { y=tolower(x); gsub("[^a-z0-9]+", "-", y); gsub("-$$", "", y); printf("- [%s](#%s)\n", x, y); } { x=$$0; }' README.md

clean:
	rm -vrf $(FIRMWARE_OBJS) $(TEST_OBJS) \
		firmware/firmware.{elf,bin,hex,map} synth.v \
		testbench.exe testbench_sp.exe testbench_axi.exe testbench_synth.exe testbench.vcd

.PHONY: test test_sp test_axi test_sync toc clean

