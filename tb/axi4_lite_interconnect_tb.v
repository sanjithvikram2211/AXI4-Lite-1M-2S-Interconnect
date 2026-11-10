`timescale 1ns/1ps
module axi4_lite_interconnect_tb;
    reg aclk, aresetn;
    reg [31:0] m_awaddr, m_wdata, m_araddr;
    reg [3:0] m_wstrb;
    reg m_awvalid, m_wvalid, m_bready, m_arvalid, m_rready;
    wire m_awready, m_wready, m_bvalid, m_arready, m_rvalid;
    wire [1:0] m_bresp, m_rresp;
    wire [31:0] m_rdata;
    integer errors;

    axi4_lite_interconnect dut (
        .aclk(aclk), .aresetn(aresetn),
        .m_awaddr(m_awaddr), .m_awvalid(m_awvalid), .m_awready(m_awready),
        .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wvalid(m_wvalid), .m_wready(m_wready),
        .m_bresp(m_bresp), .m_bvalid(m_bvalid), .m_bready(m_bready),
        .m_araddr(m_araddr), .m_arvalid(m_arvalid), .m_arready(m_arready),
        .m_rdata(m_rdata), .m_rresp(m_rresp), .m_rvalid(m_rvalid), .m_rready(m_rready)
    );

    always #5 aclk = ~aclk;

    task send_aw;
        input [31:0] addr;
        begin
            @(negedge aclk); m_awaddr = addr; m_awvalid = 1;
            while (m_awready !== 1'b1) @(negedge aclk);
            @(posedge aclk); @(negedge aclk); m_awvalid = 0;
        end
    endtask

    task send_w;
        input [31:0] data;
        input [3:0] strb;
        begin
            @(negedge aclk); m_wdata = data; m_wstrb = strb; m_wvalid = 1;
            while (m_wready !== 1'b1) @(negedge aclk);
            @(posedge aclk); @(negedge aclk); m_wvalid = 0;
        end
    endtask

    task get_b;
        input [1:0] expected_resp;
        begin
            m_bready = 0;
            while (m_bvalid !== 1'b1) @(negedge aclk);
            repeat (2) @(negedge aclk); // exercise B-channel backpressure
            if (m_bresp !== expected_resp) begin
                $display("ERROR: BRESP expected=%b got=%b", expected_resp, m_bresp);
                errors = errors + 1;
            end
            m_bready = 1;
            @(posedge aclk); @(negedge aclk); m_bready = 0;
        end
    endtask

    task axi_write;
        input [31:0] addr, data;
        input [3:0] strb;
        input aw_first;
        input [1:0] expected_resp;
        begin
            if (aw_first) begin
                send_aw(addr); send_w(data, strb);
            end else begin
                // Present WVALID before AWVALID. WREADY is allowed to stay low
                // until the interconnect has captured the write address.
                @(negedge aclk);
                m_wdata = data; m_wstrb = strb; m_wvalid = 1'b1;
                repeat (2) @(negedge aclk);
                m_awaddr = addr; m_awvalid = 1'b1;
                while (m_awready !== 1'b1) @(negedge aclk);
                @(posedge aclk);
                @(negedge aclk);
                m_awvalid = 1'b0;
                while (m_wready !== 1'b1) @(negedge aclk);
                @(posedge aclk);
                @(negedge aclk);
                m_wvalid = 1'b0;
            end
            get_b(expected_resp);
            $display("[%0t] WRITE addr=%h data=%h strb=%b BRESP=%b",
                     $time, addr, data, strb, expected_resp);
        end
    endtask

    task axi_read;
        input [31:0] addr, expected_data;
        input [1:0] expected_resp;
        reg [31:0] got;
        begin
            @(negedge aclk); m_araddr = addr; m_arvalid = 1;
            while (m_arready !== 1'b1) @(negedge aclk);
            @(posedge aclk); @(negedge aclk); m_arvalid = 0;
            m_rready = 0;
            while (m_rvalid !== 1'b1) @(negedge aclk);
            got = m_rdata;
            repeat (2) @(negedge aclk); // exercise R-channel backpressure
            if (m_rresp !== expected_resp) begin
                $display("ERROR: RRESP expected=%b got=%b", expected_resp, m_rresp);
                errors = errors + 1;
            end
            if (expected_resp == 2'b00 && got !== expected_data) begin
                $display("ERROR: READ addr=%h expected=%h got=%h", addr, expected_data, got);
                errors = errors + 1;
            end else if (expected_resp == 2'b00) begin
                $display("[%0t] READ  addr=%h data=%h PASS", $time, addr, got);
            end else begin
                $display("[%0t] INVALID READ addr=%h RRESP=%b", $time, addr, m_rresp);
            end
            m_rready = 1;
            @(posedge aclk); @(negedge aclk); m_rready = 0;
        end
    endtask

    initial begin
        aclk=0; aresetn=0; errors=0;
        m_awaddr=0; m_awvalid=0; m_wdata=0; m_wstrb=4'hF; m_wvalid=0; m_bready=0;
        m_araddr=0; m_arvalid=0; m_rready=0;
        repeat (4) @(negedge aclk); aresetn=1;
        repeat (2) @(negedge aclk);

        $display("===== AXI4-Lite 1-Master / 2-Slave TEST =====");
        // Slave 0: AW first, then readback.
        axi_write(32'h0000_0000, 32'h1234_ABCD, 4'hF, 1'b1, 2'b00);
        axi_read (32'h0000_0000, 32'h1234_ABCD, 2'b00);
        // Slave 0: W first, then AW; byte lane 0 update.
        axi_write(32'h0000_0000, 32'h0000_00AA, 4'b0001, 1'b0, 2'b00);
        axi_read (32'h0000_0000, 32'h1234_ABAA, 2'b00);
        // More words in Slave 0.
        axi_write(32'h0000_0004, 32'hDEAD_BEEF, 4'hF, 1'b1, 2'b00);
        axi_read (32'h0000_0004, 32'hDEAD_BEEF, 2'b00);

        // Slave 1.
        axi_write(32'h0000_1000, 32'hCAFE_1234, 4'hF, 1'b0, 2'b00);
        axi_read (32'h0000_1000, 32'hCAFE_1234, 2'b00);
        axi_write(32'h0000_1008, 32'h8765_4321, 4'hF, 1'b1, 2'b00);
        axi_read (32'h0000_1008, 32'h8765_4321, 2'b00);

        // Out-of-range and unaligned accesses must return DECERR.
        axi_write(32'h0000_2000, 32'h1111_2222, 4'hF, 1'b1, 2'b11);
        axi_read (32'h0000_2000, 32'h0000_0000, 2'b11);
        axi_read (32'h0000_0002, 32'h0000_0000, 2'b11);

        repeat (4) @(negedge aclk);
        if (errors == 0) $display("===== ALL TESTS PASSED =====");
        else $display("===== TEST FAILED: %0d ERRORS =====", errors);
        $finish;
    end
endmodule
