`timescale 1ns/1ps
// Simple AXI4-Lite register bank: 1024 x 32-bit words = 4 KB.
// AW and W are accepted independently and may arrive in either order.
// BRESP/RRESP are OKAY for this register bank.
module axi4_lite_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ADDR_LSB   = 2,
    parameter MEM_DEPTH  = 1024
)(
    input  wire                      aclk,
    input  wire                      aresetn,

    input  wire [ADDR_WIDTH-1:0]     s_awaddr,
    input  wire                      s_awvalid,
    output wire                      s_awready,

    input  wire [DATA_WIDTH-1:0]     s_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_wstrb,
    input  wire                      s_wvalid,
    output wire                      s_wready,

    output reg  [1:0]                s_bresp,
    output reg                       s_bvalid,
    input  wire                      s_bready,

    input  wire [ADDR_WIDTH-1:0]     s_araddr,
    input  wire                      s_arvalid,
    output wire                      s_arready,

    output reg  [DATA_WIDTH-1:0]     s_rdata,
    output reg  [1:0]                s_rresp,
    output reg                       s_rvalid,
    input  wire                      s_rready
);
    localparam OKAY = 2'b00;

    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [(DATA_WIDTH/8)-1:0] wstrb_reg;
    reg aw_pending, w_pending;
    reg [DATA_WIDTH-1:0] regs [0:MEM_DEPTH-1];

    wire aw_fire = s_awvalid && s_awready;
    wire w_fire  = s_wvalid  && s_wready;
    wire have_aw = aw_pending || aw_fire;
    wire have_w  = w_pending  || w_fire;
    wire [ADDR_WIDTH-1:0] write_addr = aw_pending ? awaddr_reg : s_awaddr;
    wire [DATA_WIDTH-1:0] write_data = w_pending ? wdata_reg : s_wdata;
    wire [(DATA_WIDTH/8)-1:0] write_strb = w_pending ? wstrb_reg : s_wstrb;
    wire write_fire = have_aw && have_w && !s_bvalid;

    integer i;
    assign s_awready = aresetn && !aw_pending && !s_bvalid;
    assign s_wready  = aresetn && !w_pending  && !s_bvalid;
    assign s_arready = aresetn && !s_rvalid;

    always @(posedge aclk) begin
        if (!aresetn) begin
            awaddr_reg <= {ADDR_WIDTH{1'b0}};
            wdata_reg  <= {DATA_WIDTH{1'b0}};
            wstrb_reg  <= {(DATA_WIDTH/8){1'b0}};
            aw_pending <= 1'b0;
            w_pending  <= 1'b0;
            s_bresp    <= OKAY;
            s_bvalid   <= 1'b0;
            s_rdata    <= {DATA_WIDTH{1'b0}};
            s_rresp    <= OKAY;
            s_rvalid   <= 1'b0;
            for (i = 0; i < MEM_DEPTH; i = i + 1)
                regs[i] <= {DATA_WIDTH{1'b0}};
        end else begin
            if (aw_fire) begin
                awaddr_reg <= s_awaddr;
                aw_pending <= 1'b1;
            end
            if (w_fire) begin
                wdata_reg <= s_wdata;
                wstrb_reg <= s_wstrb;
                w_pending <= 1'b1;
            end

            if (write_fire) begin
                if (write_strb[0]) regs[write_addr[ADDR_LSB +: 10]][7:0]   <= write_data[7:0];
                if (write_strb[1]) regs[write_addr[ADDR_LSB +: 10]][15:8]  <= write_data[15:8];
                if (write_strb[2]) regs[write_addr[ADDR_LSB +: 10]][23:16] <= write_data[23:16];
                if (write_strb[3]) regs[write_addr[ADDR_LSB +: 10]][31:24] <= write_data[31:24];
                aw_pending <= 1'b0;
                w_pending  <= 1'b0;
                s_bresp    <= OKAY;
                s_bvalid   <= 1'b1;
            end else if (s_bvalid && s_bready) begin
                s_bvalid <= 1'b0;
            end

            if (s_arvalid && s_arready) begin
                s_rdata  <= regs[s_araddr[ADDR_LSB +: 10]];
                s_rresp  <= OKAY;
                s_rvalid <= 1'b1;
            end else if (s_rvalid && s_rready) begin
                s_rvalid <= 1'b0;
            end
        end
    end
endmodule
