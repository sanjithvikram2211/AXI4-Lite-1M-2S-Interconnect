transcript on
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

vlog ../rtl/axi4_lite_address_decoder.v
vlog ../rtl/axi4_lite_slave.v
vlog ../rtl/axi4_lite_interconnect.v
vlog ../tb/axi4_lite_interconnect_tb.v

vsim -voptargs=+acc work.axi4_lite_interconnect_tb

add wave -divider "CLOCK AND RESET"
add wave -radix binary sim:/axi4_lite_interconnect_tb/aclk
add wave -radix binary sim:/axi4_lite_interconnect_tb/aresetn

add wave -divider "MASTER WRITE ADDRESS AND DATA"
add wave -radix hexadecimal sim:/axi4_lite_interconnect_tb/m_awaddr
add wave -radix binary sim:/axi4_lite_interconnect_tb/m_awvalid
add wave -radix binary sim:/axi4_lite_interconnect_tb/m_awready
add wave -radix hexadecimal sim:/axi4_lite_interconnect_tb/m_wdata
add wave -radix hexadecimal sim:/axi4_lite_interconnect_tb/m_wstrb
add wave -radix binary sim:/axi4_lite_interconnect_tb/m_wvalid
add wave -radix binary sim:/axi4_lite_interconnect_tb/m_wready

add wave -divider "MASTER WRITE RESPONSE"
add wave -radix binary sim:/axi4_lite_interconnect_tb/m_bvalid
add wave -radix binary sim:/axi4_lite_interconnect_tb/m_bready
add wave -radix binary sim:/axi4_lite_interconnect_tb/m_bresp

add wave -divider "MASTER READ CHANNEL"
add wave -radix hexadecimal sim:/axi4_lite_interconnect_tb/m_araddr
add wave -radix binary sim:/axi4_lite_interconnect_tb/m_arvalid
add wave -radix binary sim:/axi4_lite_interconnect_tb/m_arready
add wave -radix hexadecimal sim:/axi4_lite_interconnect_tb/m_rdata
add wave -radix binary sim:/axi4_lite_interconnect_tb/m_rvalid
add wave -radix binary sim:/axi4_lite_interconnect_tb/m_rready
add wave -radix binary sim:/axi4_lite_interconnect_tb/m_rresp

add wave -divider "INTERCONNECT CONTROL"
add wave -radix binary sim:/axi4_lite_interconnect_tb/dut/wr_active
add wave -radix binary sim:/axi4_lite_interconnect_tb/dut/wr_sel
add wave -radix binary sim:/axi4_lite_interconnect_tb/dut/wr_invalid
add wave -radix binary sim:/axi4_lite_interconnect_tb/dut/rd_active
add wave -radix binary sim:/axi4_lite_interconnect_tb/dut/rd_sel
add wave -radix binary sim:/axi4_lite_interconnect_tb/dut/rd_invalid

add wave -divider "SLAVE 0"
add wave -radix binary sim:/axi4_lite_interconnect_tb/dut/s0_awvalid
add wave -radix binary sim:/axi4_lite_interconnect_tb/dut/s0_wvalid
add wave -radix binary sim:/axi4_lite_interconnect_tb/dut/s0_bvalid
add wave -radix binary sim:/axi4_lite_interconnect_tb/dut/s0_arvalid
add wave -radix binary sim:/axi4_lite_interconnect_tb/dut/s0_rvalid

add wave -divider "SLAVE 1"
add wave -radix binary sim:/axi4_lite_interconnect_tb/dut/s1_awvalid
add wave -radix binary sim:/axi4_lite_interconnect_tb/dut/s1_wvalid
add wave -radix binary sim:/axi4_lite_interconnect_tb/dut/s1_bvalid
add wave -radix binary sim:/axi4_lite_interconnect_tb/dut/s1_arvalid
add wave -radix binary sim:/axi4_lite_interconnect_tb/dut/s1_rvalid

run -all
