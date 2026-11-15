# RISC-V RV32I bare-metal build
#
#   make        compile and link        -> build/$(PROG).elf
#   make bin    raw machine code        -> build/$(PROG).bin
#   make asm    linked program as asm   -> build/$(PROG).s
#   make clean  remove build/
#
# C programs need start.s (sets sp, calls main, ebreak).
# Hand-written test programs start at address 0 on their own, so leave start.s out:
#   make bin PROG=jalr SRCS=test_jalr.s

PROG    ?= test
SRCS    ?= start.s $(wildcard *.c)
BUILD   := build

CC      := clang
LD      := ld.lld
OBJCOPY := llvm-objcopy
OBJDUMP := llvm-objdump

ARCH    := --target=riscv32-unknown-elf -march=rv32i -mabi=ilp32
CFLAGS  := $(ARCH) -O1 -ffreestanding -nostdlib -mno-relax -fno-addrsig
ASFLAGS := $(ARCH) -mno-relax
LDFLAGS := -m elf32lriscv -T link.ld -e 0

OBJS    := $(addprefix $(BUILD)/,$(addsuffix .o,$(basename $(SRCS))))
ELF     := $(BUILD)/$(PROG).elf
BIN     := $(BUILD)/$(PROG).bin
ASM     := $(BUILD)/$(PROG).s

.PHONY: all bin asm clean

all: $(ELF)

bin: $(BIN)

asm: $(ASM)

$(BUILD):
	mkdir -p $@

$(BUILD)/%.o: %.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/%.o: %.s | $(BUILD)
	$(CC) $(ASFLAGS) -c $< -o $@

$(ELF): $(OBJS) link.ld
	$(LD) $(LDFLAGS) $(OBJS) -o $@

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

# Disassemble the linked program: final addresses, real instructions (no pseudo-instructions).
$(ASM): $(ELF)
	$(OBJDUMP) -d -M no-aliases --no-show-raw-insn $< \
	| sed -e '/file format/d' -e '/^Disassembly of section/d' -e '/^[[:space:]]*$$/d' \
	      -e 's/^[0-9a-f]* <\(.*\)>:$$/\1:/' \
	      -e 's/[[:space:]]*<[^>]*>$$//' \
	      -e 's/^[[:space:]][[:space:]]*[0-9a-f][0-9a-f]*:[[:space:]]*//' \
	      -e 's/\t/ /g' \
	> $@

clean:
	rm -rf $(BUILD)
