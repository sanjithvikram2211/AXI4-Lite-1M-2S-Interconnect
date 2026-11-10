`timescale 1ns/1ps
// Slave 0: 0x0000_0000 - 0x0000_0FFF
// Slave 1: 0x0000_1000 - 0x0000_1FFF
module axi4_lite_address_decoder (
    input  wire [31:0] addr,
    output reg         valid_addr,
    output reg         slave_sel
);
    always @(*) begin
        valid_addr = 1'b1;
        slave_sel  = 1'b0;

        if ((addr[31:12] == 20'h00000) && (addr[1:0] == 2'b00)) begin
            valid_addr = 1'b1;
            slave_sel  = 1'b0;
        end
        else if ((addr[31:12] == 20'h00001) && (addr[1:0] == 2'b00)) begin
            valid_addr = 1'b1;
            slave_sel  = 1'b1;
        end
        else begin
            valid_addr = 1'b0;
            slave_sel  = 1'b0;
        end
    end
endmodule
