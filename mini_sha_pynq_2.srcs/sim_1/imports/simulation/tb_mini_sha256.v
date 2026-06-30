`timescale 1ns / 1ps

module tb_mini_sha256();

    reg clk;
    reg rst_n;
    
    reg start;
    reg first_block;
    reg [15:0] data_in;
    reg data_vld;
    wire data_rdy;
    
    wire done;
    wire [127:0] digest;
    
    reg [2:0] digest_addr;
    wire [15:0] digest_out;

    // DUT instantiation
    mini_sha256_core u_core (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .first_block(first_block),
        .data_in(data_in),
        .data_vld(data_vld),
        .digest_addr(digest_addr),
        .data_rdy(data_rdy),
        .digest_out(digest_out),
        .done(done)
    );

    assign digest = u_core.full_digest;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Timeout
    initial begin
        #50000;
        $display("TIMEOUT! state=%0d round_ctr=%0d sub_ctr=%0d", u_core.u_ctrl.state, u_core.u_ctrl.round_ctr, u_core.u_ctrl.sub_ctr);
        $finish;
    end
    
    // Task to send a 128-bit block (8 x 16-bit words)
    task send_block;
        input [127:0] block;
        input is_first;
        integer i;
        begin
            @(negedge clk);
            // Ensure core is idle before starting
            while (data_rdy == 0) @(negedge clk);
            
            first_block = is_first;
            start = 1;
            @(negedge clk);
            start = 0; // Clear start after one clock cycle
            
            i = 0;
            while (i < 8) begin
                data_in = block[127 - i*16 -: 16];
                data_vld = 1;
                
                // Wait until core is ready to accept a message word (S_LOAD_MSG state)
                while (data_rdy == 0) @(negedge clk);
                
                // Core will sample data on the next posedge. 
                // We wait for the next negedge to safely advance to the next word.
                @(negedge clk);
                i = i + 1;
            end
            
            // Clear data_vld immediately after the last word is accepted
            data_vld = 0;
            data_in = 16'hx;
            first_block = 0;
        end
    endtask

    reg [127:0] expected_digest;
    integer errors = 0;

    initial begin
        rst_n = 0;
        start = 0;
        first_block = 0;
        data_in = 0;
        data_vld = 0;
        digest_addr = 0;
        
        #20;
        rst_n = 1;
        #10;
        
        // ================================================================
        // TEST 1: Empty string (padded)
        // ================================================================
        $display("\n================================================");
        $display("TEST 1: Input = (empty string)");
        send_block(128'h8000_0000_0000_0000_0000_0000_0000_0000, 1);
        
        wait(done);
        #10;
        
        expected_digest = 128'ha4028eeec943ca5abb539eb92d387689;
        $display("Expected : %x", expected_digest);
        $display("Got      : %x", digest);
        if (digest === expected_digest) begin
            $display("PASS");
        end else begin
            $display("FAIL");
            errors = errors + 1;
        end
        #50;

        // ================================================================
        // TEST 2: "abc" (padded)
        // ================================================================
        rst_n = 0;
        #10;
        rst_n = 1;
        #10;
        
        $display("\n================================================");
        $display("TEST 2: Input = abc");
        send_block(128'h6162_6380_0000_0000_0000_0000_0000_0018, 1);
        
        wait(done);
        #10;
        
        expected_digest = 128'hf8eb4970168ae597e4e3b18f23479f92;
        $display("Expected : %x", expected_digest);
        $display("Got      : %x", digest);
        if (digest === expected_digest) begin
            $display("PASS");
        end else begin
            $display("FAIL");
            errors = errors + 1;
        end
        #50;

        // ================================================================
        // TEST 3: 17 "A"s (2 blocks)
        // ================================================================
        rst_n = 0;
        #10;
        rst_n = 1;
        #10;
        
        $display("\n================================================");
        $display("TEST 3: Input = 17 'A's (2 blocks)");
        // Send Block 1 (first=1)
        send_block(128'h41414141414141414141414141414141, 1);
        wait(done);
        #10;
        // Send Block 2 (first=0)
        send_block(128'h41800000000000000000000000000088, 0);
        wait(done);
        #10;
        
        expected_digest = 128'hf9f0a2d56041641c324e546074df41d7;
        $display("Expected : %x", expected_digest);
        $display("Got      : %x", digest);
        if (digest === expected_digest) begin
            $display("PASS");
        end else begin
            $display("FAIL");
            errors = errors + 1;
        end
        #50;

        // ================================================================
        // TEST 4: 33 "A"s (3 blocks)
        // ================================================================
        rst_n = 0;
        #10;
        rst_n = 1;
        #10;
        
        $display("\n================================================");
        $display("TEST 4: Input = 33 'A's (3 blocks)");
        // Send Block 1 (first=1)
        send_block(128'h41414141414141414141414141414141, 1);
        wait(done);
        #10;
        // Send Block 2 (first=0)
        send_block(128'h41414141414141414141414141414141, 0);
        wait(done);
        #10;
        // Send Block 3 (first=0)
        send_block(128'h41800000000000000000000000000108, 0);
        wait(done);
        #10;
        
        expected_digest = 128'hb95445f44568ff900f7c21c3486bb7f5;
        $display("Expected : %x", expected_digest);
        $display("Got      : %x", digest);
        if (digest === expected_digest) begin
            $display("PASS");
        end else begin
            $display("FAIL");
            errors = errors + 1;
        end
        #50;

        // End of tests
        $display("\n================================================");
        if (errors == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("%0d TESTS FAILED", errors);
        end
        $display("================================================\n");
        $finish;
    end

endmodule
