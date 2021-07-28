#!/bin/bash

set -ex


## Generate test case

if ! test -f test.S; then
	cd riscv-torture
	./sbt generator/run
	cp output/test.S ../test.S
	cd ..
fi


## Compile test case and create reference

riscv32-unknown-elf-gcc -m32 -march=RV32IMC -ffreestanding -nostdlib -Wl,-Bstatic,-T,sections.lds -o test.elf test.S
LD_LIBRARY_PATH="./riscv-isa-sim:./riscv-fesvr" ./riscv-isa-sim/spike test.elf > test.ref
riscv32-unknown-elf-objcopy -O binary test.elf test.bin
python3 ../../firmware/makehex.py test.bin 4096 > test.hex


## Run test

iverilog -o test.vvp testbench.v ../../picorv32.v
vvp test.vvp +vcd +hex=test.hex +ref=test.ref

