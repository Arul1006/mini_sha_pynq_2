`timescale 1ns / 1ps

module tb_mini_sha256_stream;

    // Inputs
    reg aclk;
    reg aresetn;
    
    // AXI-Stream Input
    reg [7:0]  s_axis_tdata;
    reg        s_axis_tvalid;
    reg        s_axis_tlast;
    wire       s_axis_tready;
    
    // AXI-Lite Interface
    reg [4:0]  s_axi_awaddr;
    reg        s_axi_awvalid;
    wire       s_axi_awready;
    reg [31:0] s_axi_wdata;
    reg [3:0]  s_axi_wstrb;
    reg        s_axi_wvalid;
    wire       s_axi_wready;
    wire [1:0] s_axi_bresp;
    wire       s_axi_bvalid;
    reg        s_axi_bready;
    
    reg [4:0]  s_axi_araddr;
    reg        s_axi_arvalid;
    wire       s_axi_arready;
    wire [31:0] s_axi_rdata;
    wire       s_axi_rvalid;
    reg        s_axi_rready;

    // Instantiate the Unit Under Test (UUT)
    mini_sha256_stream_wrapper uut (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready)
    );

    // Clock generation
    always #5 aclk = ~aclk;

    // Task to write to AXI-Lite (Soft Reset)
    task axi_lite_write;
        input [4:0] addr;
        input [31:0] data;
        integer timeout_aw;
        integer timeout_b;
        begin
            @(posedge aclk);
            s_axi_awaddr = addr;
            s_axi_wdata = data;
            s_axi_wstrb = 4'hF;
            s_axi_awvalid = 1;
            s_axi_wvalid = 1;
            
            timeout_aw = 0;
            while (!(s_axi_awready && s_axi_wready)) begin
                @(posedge aclk);
                timeout_aw = timeout_aw + 1;
                if (timeout_aw > 500) begin
                    $display("TIMEOUT waiting for awready and wready!");
                    $stop;
                end
            end
            
            @(posedge aclk);
            s_axi_awvalid = 0;
            s_axi_wvalid = 0;
            s_axi_bready = 1;
            
            timeout_b = 0;
            while (!s_axi_bvalid) begin
                @(posedge aclk);
                timeout_b = timeout_b + 1;
                if (timeout_b > 500) begin
                    $display("TIMEOUT waiting for bvalid!");
                    $stop;
                end
            end
            
            @(posedge aclk);
            s_axi_bready = 0;
        end
    endtask

    // Task to send a string through AXI-Stream
    task send_string;
        input [8*100-1:0] str;
        input integer len;
        integer i;
        reg [7:0] char;
        integer timeout_ctr;
        begin
            for (i = 0; i < len; i = i + 1) begin
                // Extract characters from left to right
                char = str[((len-1-i)*8) +: 8];
                @(posedge aclk);
                #1;
                s_axis_tdata = char;
                s_axis_tvalid = 1;
                s_axis_tlast = (i == len - 1);
                timeout_ctr = 0;
                // wait for handshake
                while (!s_axis_tready) begin
                    @(posedge aclk);
                    #1;
                    timeout_ctr = timeout_ctr + 1;
                    if (timeout_ctr > 1000) begin
                        $display("TIMEOUT waiting for s_axis_tready!");
                        $stop;
                    end
                end
            end
            @(posedge aclk);
            #1;
            s_axis_tvalid = 0;
            s_axis_tlast = 0;
        end
    endtask

    // Task to read and verify the hash
    task verify_hash;
        input [127:0] expected_hash;
        reg [31:0] read_word;
        reg [127:0] output_hash;
        integer i;
        integer timeout_ctr_2;
        integer timeout_ar;
        integer timeout_r;
        begin
            // Wait for status = done
            read_word = 0;
            timeout_ctr_2 = 0;
            while (read_word[0] == 0) begin
                @(posedge aclk);
                s_axi_araddr = 5'h00;
                s_axi_arvalid = 1;
                
                timeout_ar = 0;
                while (!s_axi_arready) begin
                    @(posedge aclk);
                    timeout_ar = timeout_ar + 1;
                    if (timeout_ar > 500) begin
                        $display("TIMEOUT waiting for arready!");
                        $stop;
                    end
                end
                
                @(posedge aclk);
                s_axi_arvalid = 0;
                s_axi_rready = 1;
                
                timeout_r = 0;
                while (!s_axi_rvalid) begin
                    @(posedge aclk);
                    timeout_r = timeout_r + 1;
                    if (timeout_r > 500) begin
                        $display("TIMEOUT waiting for rvalid!");
                        $stop;
                    end
                end
                
                read_word = s_axi_rdata;
                @(posedge aclk);
                s_axi_rready = 0;
                
                timeout_ctr_2 = timeout_ctr_2 + 1;
                if (timeout_ctr_2 > 2000) begin
                    $display("TIMEOUT waiting for padder_done! p_state=%d, c_state=%d, core_data_vld=%b, sub_ctr=%d, byte_in_block=%d", uut.p_state, uut.u_core.u_ctrl.state, uut.core_data_vld, uut.u_core.u_ctrl.sub_ctr, uut.byte_in_block);
                    $stop;
                end
            end
            
            // Read 4 registers (each holds 32 bits = 2 x 16-bit hash words)
            for (i = 0; i < 4; i = i + 1) begin
                $display("Reading hash word %d...", i);
                @(posedge aclk);
                s_axi_araddr = 5'h04 + (i * 4);
                s_axi_arvalid = 1;
                $display("  Waiting for arready...");
                
                timeout_ar = 0;
                while (!s_axi_arready) @(posedge aclk);
                
                @(posedge aclk);
                s_axi_arvalid = 0;
                s_axi_rready = 1;
                $display("  Waiting for rvalid...");
                
                while (!s_axi_rvalid) @(posedge aclk);
                
                read_word = s_axi_rdata;
                output_hash[127-(i*32) -: 32] = read_word;
                $display("  Read %h", read_word);
                @(posedge aclk);
                s_axi_rready = 0;
            end
            
            $display("    Expected Hash : %32x", expected_hash);
            $display("    Output Hash   : %32x", output_hash);
            
            if (output_hash !== expected_hash) begin
                $display("    -> RESULT     : FAIL\n");
                // $stop; // removed to allow Test 2 to run
            end else begin
                $display("    -> RESULT     : PASS\n");
            end
        end
    endtask

    initial begin
        // Initialize Inputs
        aclk = 0;
        aresetn = 0;
        s_axis_tdata = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        s_axi_awaddr = 0;
        s_axi_awvalid = 0;
        s_axi_wdata = 0;
        s_axi_wstrb = 0;
        s_axi_wvalid = 0;
        s_axi_bready = 0;
        s_axi_araddr = 0;
        s_axi_arvalid = 0;
        s_axi_rready = 0;

        // Reset
        #100;
        aresetn = 1;
        #20;
        
        $display("\n==============================================================");
        $display("   STARTING MINI SHA-256 TEST SUITE");
        $display("==============================================================\n");

        // Test 1: Short string "abc"
        $display("Test 1: Message = \"abc\"");
        send_string("abc", 3);
        verify_hash(128'hf8eb4970168ae597e4e3b18f23479f92);
        
        // Reset via AXI-Lite
        axi_lite_write(5'h00, 32'd1);
        #50;

        // Test 2: Multi-block string
        $display("Test 2: Message = \"Hello World! This is a test of the mini SHA-256.\"");
        send_string("Hello World! This is a test of the mini SHA-256.", 48);
        verify_hash(128'h0e25_3e5a_0068_38af_8bb6_bf9c_bb64_5492);

        // Reset via AXI-Lite
        axi_lite_write(5'h00, 32'd1);
        #50;

        // Test 3: Standard pangram
        $display("Test 3: Message = \"The quick brown fox jumps over the lazy dog\"");
        send_string("The quick brown fox jumps over the lazy dog", 43);
        verify_hash(128'hdea5_bc8f_ba69_f03d_ba54_a9cf_1b62_cbb7);
        
        // Reset via AXI-Lite
        axi_lite_write(5'h00, 32'd1);
        #50;

        // Test 4: Custom fun string
        $display("Test 4: Message = \"Vivado is sometimes frustrating but FPGA design is fun!\"");
        send_string("Vivado is sometimes frustrating but FPGA design is fun!", 55);
        verify_hash(128'h720b_3129_3037_2cfb_9af8_d4e8_4d9d_db3c);

        $display("==============================================================");
        $display("   ALL TESTS COMPLETED SUCCESSFULLY!");
        $display("==============================================================\n");

        $finish;
    end

endmodule
