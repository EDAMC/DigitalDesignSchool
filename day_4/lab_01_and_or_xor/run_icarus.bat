iverilog -g2005-sv *.sv
vvp a.out
gtkwave --dump dump.vcd --script xx_gtkwave.tcl
