

APP_SRC ?= $(wildcard ./*.c) $(wildcard ./*.cpp) $(wildcard ./*.s) $(wildcard ./*.S)

# Compiler toolchain
RISCV_PREFIX ?= riscv32-unknown-elf-

# CPU architecture and ABI
MARCH ?= rv32i_zicsr
MABI  ?= ilp32

SARATOGA_HOME ?= ../../..


# --------------------------------------------------
# Saratoga software framework
# --------------------------------------------------
# Linker script and startup file
SARATOGA_COM_PATH = $(SARATOGA_HOME)/sw/common
# Main library include files
SARATOGA_INC_PATH = $(SARATOGA_HOME)/sw/lib/inc
# Main library source files
SARATOGA_SRC_PATH = $(SARATOGA_HOME)/sw/lib/src


# Core libraries
CORE_SRC  = $(wildcard $(SARATOGA_SRC_PATH)/*.c) $(wildcard $(SARATOGA_SRC_PATH)/*.cpp)
# Start-up code
CORE_SRC += $(SARATOGA_COM_PATH)/startup_saratoga.S

# Linker script
LD_SCRIPT ?= $(SARATOGA_COM_PATH)/saratoga.ld
# MakeHex script
MAKE_HEX ?= $(SARATOGA_HOME)/scripts/makehex.py

# Main output files
APP_ELF = main.elf
APP_BIN = rom.bin
APP_HEX = rom.hex
DUMP    = disassembly.dump

SRC  = $(APP_SRC)
SRC += $(CORE_SRC)
OBJ  = $(SRC:%=%.o)


# --------------------------------------------------
# Tools
# --------------------------------------------------
CC      = $(RISCV_PREFIX)gcc
LD		= $(RISCV_PREFIX)ld
OBJDUMP	= $(RISCV_PREFIX)objdump
OBJCOPY = $(RISCV_PREFIX)objcopy
SIZE    = $(RISCV_PREFIX)size
GDB     = $(RISCV_PREFIX)gdb


# --------------------------------------------------
# Flags
# --------------------------------------------------
# Main compiler opts
CC_OPTS  = -march=$(MARCH) -mabi=$(MABI) -ffunction-sections -fdata-sections -Wl,--gc-sections -nostartfiles -Os
# Compiler warning flags
CC_OPTS += -Wall -Wshadow -Wdouble-promotion -Wformat-overflow -Wformat-truncation -Wundef -fno-common -Wconversion
# Compiler debug flags
CC_OPTS += -g3
# Linker flags
LS_LIBS = -lm -lc -lgcc
# Disassemble opts
DUMP_OPTS ?= --visualize-jumps -Mnumeric,no-aliases


# Macros
ifdef SARATOGA_SIM
CC_OPTS += -DSARATOGA_SIM
endif


# Targets
build: $(APP_HEX)
dump:  $(DUMP)

clean:
	@rm -rf $(OBJ) $(APP_ELF) $(APP_BIN) $(APP_HEX) $(DUMP)



# Compile
%.s.o: %.s
	@echo "Compiling $<"
	@$(CC) -c $(CC_OPTS) -I $(SARATOGA_INC_PATH) $< -o $@
%.S.o: %.S
	@echo "Compiling $<"
	@$(CC) -c $(CC_OPTS) -I $(SARATOGA_INC_PATH) $< -o $@
%.c.o: %.c
	@echo "Compiling $<"
	@$(CC) -c $(CC_OPTS) -I $(SARATOGA_INC_PATH) $< -o $@
%.cpp.o: %.cpp
	@echo "Compiling $<"
	@$(CC) -c $(CC_OPTS) -I $(SARATOGA_INC_PATH) $< -o $@

# Link
$(APP_ELF): $(OBJ)
	@echo "Linking"
	@$(CC) $(CC_OPTS) $(LD_LIBS) -T $(LD_SCRIPT) $(OBJ) -o $@
	@echo "Memory utilization"
	@$(SIZE) $(APP_ELF)

$(APP_BIN): $(APP_ELF)
	@echo "Generating ROM binary"
	@$(OBJCOPY) -I elf32-little $< -j .text   -O binary text.bin
	@$(OBJCOPY) -I elf32-little $< -j .rodata -O binary rodata.bin
	@$(OBJCOPY) -I elf32-little $< -j .data   -O binary data.bin
	@cat text.bin rodata.bin data.bin > $@
	@rm -f text.bin rodata.bin data.bin


$(APP_HEX): $(APP_BIN)
	@echo "Generating ROM hex"
	@python3 $(MAKE_HEX) $< 1024 > $@


$(DUMP): build
	@echo "Disassembling"
	@$(OBJDUMP) -d $(DUMP_OPTS) $(APP_ELF) > $@
