# =========================================================
# Toolchain Setting
# =========================================================

TOOL_DIR = C:/arm-gnu-toolchain-15.2.rel1-mingw-w64-i686-arm-none-eabi
TARGET   = arm-none-eabi

CC      = "$(TOOL_DIR)/bin/$(TARGET)-gcc"
OBJCOPY = "$(TOOL_DIR)/bin/$(TARGET)-objcopy"
OBJDUMP = "$(TOOL_DIR)/bin/$(TARGET)-objdump"

# =========================================================
# Project Setting
# =========================================================

OUT_FILE_NAME = rom_0x08000000
BUILD_DIR     = build

LDS_FILE_NAME = linker/rom_0x08000000.lds

OUT_ELF_FILE  = $(BUILD_DIR)/$(OUT_FILE_NAME).elf
OUT_BIN_FILE  = $(BUILD_DIR)/$(OUT_FILE_NAME).bin
OUT_MAP_FILE  = $(BUILD_DIR)/$(OUT_FILE_NAME).map
OUT_DUMP_FILE = $(BUILD_DIR)/$(OUT_FILE_NAME).dmp

# =========================================================
# Source Files
# =========================================================

CSRC = \
	src/app/main.c \
	src/app/alarm.c \
	src/app/lcd_status.c \
	drivers/buzzer.c \
	drivers/key.c \
	drivers/lcd.c \
	drivers/led.c \
	drivers/motor.c \
	drivers/status_led.c \
	drivers/timer.c \
	drivers/uart.c \
	drivers/ultrasonic.c \
	system/clock.c \
	system/exception.c \
	system/runtime.c \
	system/systick.c \
	system/system_stm32f4xx.c

ASRC = \
	startup/crt0.s

OBJS = $(addprefix $(BUILD_DIR)/, $(CSRC:.c=.o)) \
       $(addprefix $(BUILD_DIR)/, $(ASRC:.s=.o))

# =========================================================
# Include Paths
# =========================================================

C_DIR   = $(TOOL_DIR)/$(TARGET)
GCC_DIR = $(TOOL_DIR)/lib/gcc/$(TARGET)/15.2.1

INCLUDE = \
	-nostdinc \
	-Iinclude \
	-Icmsis \
	-Isystem \
	-I"$(C_DIR)/include" \
	-I"$(GCC_DIR)/include"

# =========================================================
# Compiler / Linker Options
# =========================================================

COMMON_FLAGS = \
	-mcpu=cortex-m4 \
	-mthumb \
	-mfpu=fpv4-sp-d16 \
	-mfloat-abi=hard

CFLAGS = \
	$(COMMON_FLAGS) \
	-DSTM32F411xE \
	-std=gnu99 \
	-O3 \
	-Wall \
	-g \
	-ffreestanding \
	-fno-builtin \
	-funsigned-char \
	-fno-strict-aliasing \
	-fno-common

ASFLAGS = \
	$(COMMON_FLAGS) \
	-g

LDFLAGS = \
	$(COMMON_FLAGS) \
	--specs=nano.specs \
	--specs=nosys.specs \
	-u _printf_float \
	-nostartfiles \
	-ffreestanding \
	-Wl,-Map=$(OUT_MAP_FILE) \
	-Wl,--cref \
	-Wl,-EL \
	-T $(LDS_FILE_NAME)

# =========================================================
# Build Rules
# =========================================================

all: $(OUT_BIN_FILE)

$(OUT_BIN_FILE): $(OUT_ELF_FILE)
	$(OBJCOPY) $< $@ -O binary
	$(OBJDUMP) -x -D $< > $(BUILD_DIR)/__dump.txt
	$(OBJDUMP) -x -D -S $< > $(BUILD_DIR)/__dump_all.txt

$(OUT_ELF_FILE): $(OBJS)
	$(CC) $(OBJS) $(LDFLAGS) -o $@

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(INCLUDE) -c $< -o $@

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $(@D)
	$(CC) $(ASFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILD_DIR)

flash:
	STM32_Programmer_CLI.exe -c port=SWD -w $(OUT_ELF_FILE) -v -rst -q
