# SPDX-License-Identifier: GPL-2.0-only
# (c) William Fonkou Tambe

ifeq ($(VIVADO_BIN),)
VIVADO_BIN := "/cygdrive/c/Xilinx/Vivado/2020.2/bin/vivado"
endif

all:
	${VIVADO_BIN} -mode batch -nojournal -nolog -notrace -source nexys4ddr.tcl
