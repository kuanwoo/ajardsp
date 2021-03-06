DESIGN		= AjarDSP-SoC-TOP
PINS		= soc-top.ucf
DEVICE		= xc3s1600e-fg320-4
BGFLAGS		= -g TdoPin:PULLNONE -g DonePin:PULLUP \
		  -g CRC:enable -g StartUpClk:CCLK

# standard opts
MAPFLAGS	= -ol std
# with optimizations
#MAPFLAGS	= -bp -k 8 -ol high -timing -xe n -logic_opt on

# standard opts
PARFLAGS	= -ol std
# with optimizations
#PARFLAGS	= -ol high


# Top

SRC =	../../rtl/verilog/ajardsp_top.v \
	../../rtl/verilog/imem.v \
	../../rtl/verilog/dmem.v \
	../../rtl/verilog/cu.v \
	../../rtl/verilog/bmu.v \
	../../rtl/verilog/vliwfetch.v \
	../../rtl/verilog/int_mul.v \
	../../rtl/verilog/accrf.v \
	../../rtl/verilog/int_addsub.v \
	../../rtl/verilog/pred.v \
	../../rtl/verilog/ptrrf.v \
	../../rtl/verilog/sp.v \
	../../rtl/verilog/lsu.v \
	../../rtl/verilog/curegs.v \
	../../rtl/verilog/pcu.v \
	../../rtl/verilog/vliwdec.v \
	../../rtl/verilog/soc/soc_top.v \
	../../rtl/verilog/soc/wb_sdram_ctrl.v \
	../../rtl/verilog/soc/sdram_ctrl.v \
	../../rtl/verilog/soc/wb_ajardsp.v \
	../../rtl/verilog/soc/wb_vga_ctrl.v \
	../../rtl/verilog/soc/vga_font.v \
	../../rtl/verilog/soc/wb_eth_ctrl.v \
	../../rtl/verilog/soc/async_fifo.v \
	../../rtl/verilog/soc/wb_adc_ctrl.v \
        ../../rtl/verilog/soc/wb_ram.v \
        ../../rtl/verilog/soc/wb_misc_io.v \
        ../../rtl/verilog/soc/wb_debug.v \
        ../../rtl/verilog/soc/uart.v


all:		bits

remake:		clean-build all

clean:
		rm -f *~ */*~ a.out *.log *.key *.edf *.ps trace.dat

clean-build:
		rm -rf build

cleanall:	clean
		rm -rf build $(DESIGN).bit

bits:		$(DESIGN).bit

download: bits
		impact -batch ./impact.run


#
# Synthesis
#
build/project.src:
		@[ -d build ] || mkdir build
		@rm -f $@
		for i in $(SRC); do echo verilog work ../$$i >> $@; done

build/project.xst: build/project.src
		echo "run" > $@
		echo "-top soc_top" >> $@
		echo "-p $(DEVICE)" >> $@
		echo "-opt_mode Speed" >> $@
		echo "-opt_level 1" >> $@
		echo "-ifn project.src" >> $@
		echo "-ifmt mixed" >> $@
		echo "-ofn project.ngc" >> $@
		echo "-ofmt NGC" >> $@

build/project.ngc: build/project.xst $(SRC)
		cd build && xst -ifn project.xst -ofn project.log

build/project.ngd: build/project.ngc $(PINS)
		cd build && ngdbuild -p $(DEVICE) project.ngc -uc ../$(PINS)

build/project.ncd: build/project.ngd
		cd build && map -pr b -p $(DEVICE) project $(MAPFLAGS)

build/project_r.ncd: build/project.ncd
		cd build && par -w project project_r.ncd $(PARFLAGS)

build/project_r.twr: build/project_r.ncd
		cd build && trce -v 25 project_r.ncd project.pcf

$(DESIGN).bit:	build/project_r.ncd build/project_r.twr
		cd build && bitgen project_r.ncd -l -w $(BGFLAGS)
		@cp -f build/project_r.bit $@
