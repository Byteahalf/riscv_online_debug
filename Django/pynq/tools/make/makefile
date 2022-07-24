TARGET ?= main
MARCH ?= rv32imc
ABI ?= ilp32
STKPTR ?= 0x8000

prefix = riscv-none-embed-

text_prefix = \033[0;32m
text_suffix = \033[0m

all: $(TARGET).bin load

%.elf: init.o %.o 
	@echo "${text_prefix}Combining object files $< to produce $@ ${text_suffix}"
	${prefix}gcc -O -ffreestanding -nostdlib -o $@ \
		-Wl,-Bstatic,-T,picorv32.ld -DSTKPTR=$(STKPTR)\
		$^ -lgcc -march=rv32im

%.o: %.c 
	@echo "${text_prefix}Building object file $@ for $< ${text_suffix} "
	${prefix}gcc -c -Qn -march=rv32im -o $@ -O --std=c99 $<

%.o: %.cpp
	@echo "${text_prefix}Building object file $@ for $< ${text_suffix}"
	${prefix}g++ -c -Qn -march=rv32im -o $@ -Os $< 

%.o: %.S
	@echo "${text_prefix}Building object file $@ for $< ${text_suffix} "
	${prefix}gcc -c -Qn -march=rv32im -DSTKPTR=$(STKPTR)\
		-o $@ -Os --std=c99 $< 

%.bin: %.elf
	@echo "${text_prefix}Converting .elf file $< into $@ ${text_suffix}"
	${prefix}objdump -d ${TARGET}.elf > asm.asm
	${prefix}objcopy -O binary $< $@

load:
	python3 set_bin.py

# Use .PRECIOUS to keep elf files so that objdump can be run (for debugging)
.PRECIOUS: %.elf %.o

clean:
	rm -rf *.hex *.bin *.elf *.o *.asm *.log
