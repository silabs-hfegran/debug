CV_SW_TOOLCHAIN  ?= /opt/riscv
RISCV            ?= $(CV_SW_TOOLCHAIN)
RISCV_EXE_PREFIX ?= $(RISCV)/bin/riscv32-corev-elf-
RISCV_CC         ?= gcc
RISCV_GCC = $(RISCV_EXE_PREFIX)$(RISCV_CC)
RISCV_AR = $(RISCV_EXE_PREFIX)ar
RISCV_MARCH ?= rv32im_zba1p00_zbb1p00_zbc1p00_zbs1p00_zca_zcb_zcmp_zcmt_zicsr_zifencei
BSP = ./bsp

CFLAGS ?= -Os -g -static -mabi=ilp32 -march=$(RISCV_MARCH) -Wall -pedantic $(ZCMT_FLAGS) $(RISCV_CFLAGS)

ZCMT_FLAGS = -nostartfiles -fno-pie

TEST_FILES = $(filter %.c %.S,$(wildcard  *.c))

LD_FILE = -T link.ld

LD_LIBRARY 	= -L ./bsp
LD_LIBRARY  += -L ./

all: bsp hello-world.hex hello-world.elf
#test.elf test.hex

.PHONY: bsp %.hex

bsp:
	make all -C $(BSP)
		VPATH=$(BSP) \
		RISCV=$(RISCV) \
		RISCV_PREFIX=$(RISCV_PREFIX) \
		RISCV_EXE_PREFIX=$(RISCV_EXE_PREFIX) \
		RISCV_MARCH=$(RISCV_MARCH) \
		RISCV_CC=$(RISCV_CC) \
		RISCV_CFLAGS="$(CFLAGS)" \

%.elf:
	make bsp
	$(RISCV_EXE_PREFIX)$(RISCV_CC) \
		$(CFLAGS) \
		-I $(BSP) \
		-o $@ \
		-nostartfiles \
		$(TEST_FILES) \
		$(LD_FILE) \
		$(LD_LIBRARY) \
		-lcv-verif

%.hex: %.elf
	$(RISCV_EXE_PREFIX)objcopy -O verilog \
		$< \
		$@
	$(RISCV_EXE_PREFIX)readelf -a $< > $*.readelf
	$(RISCV_EXE_PREFIX)objdump \
		-d \
		-M no-aliases \
		-M numeric \
		-S \
		$*.elf > $*.objdump

clean:
	make clean -C ./bsp
	rm -f *.elf *.hex *.objdump *.readelf
