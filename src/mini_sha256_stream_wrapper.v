`timescale 1ns / 1ps

module mini_sha256_stream_wrapper (
    input  wire        aclk,
    input  wire        aresetn,
    
    // AXI-Stream Input
    input  wire [7:0]  s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tlast,
    
    // AXI-Lite Interface (Target)
    input  wire [4:0]  s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    
    output wire [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    
    input  wire [4:0]  s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    output reg  [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);

    // ==========================================
    // AXI-Lite Write Channel
    // ==========================================
    assign s_axi_bresp = 2'b00;
    
    always @(posedge aclk) begin
        if (!aresetn) begin
            s_axi_awready <= 0;
            s_axi_wready <= 0;
            s_axi_bvalid <= 0;
        end else begin
            if (s_axi_awvalid && ~s_axi_awready)
                s_axi_awready <= 1;
            else
                s_axi_awready <= 0;
                
            if (s_axi_wvalid && ~s_axi_wready)
                s_axi_wready <= 1;
            else
                s_axi_wready <= 0;
                
            if (s_axi_awvalid && s_axi_wvalid && ~s_axi_bvalid)
                s_axi_bvalid <= 1;
            else if (s_axi_bready && s_axi_bvalid)
                s_axi_bvalid <= 0;
        end
    end

    // ==========================================
    // AXI-Lite Read Channel
    // ==========================================
    assign s_axi_rresp = 2'b00;
    
    reg padder_done;
    reg [127:0] final_digest;
    
    always @(posedge aclk) begin
        if (!aresetn) begin
            s_axi_arready <= 0;
            s_axi_rvalid <= 0;
            s_axi_rdata <= 0;
        end else begin
            if (s_axi_arvalid && ~s_axi_arready) begin
                s_axi_arready <= 1;
            end else begin
                s_axi_arready <= 0;
            end
            
            if (s_axi_arvalid && s_axi_arready && ~s_axi_rvalid) begin
                s_axi_rvalid <= 1;
                case (s_axi_araddr[4:2])
                    3'b000: s_axi_rdata <= {31'd0, padder_done};
                    3'b001: s_axi_rdata <= final_digest[127:96];
                    3'b010: s_axi_rdata <= final_digest[95:64];
                    3'b011: s_axi_rdata <= final_digest[63:32];
                    3'b100: s_axi_rdata <= final_digest[31:0];
                    default: s_axi_rdata <= 32'd0;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 0;
            end
        end
    end

    wire soft_reset = (s_axi_awvalid && s_axi_wvalid && s_axi_awready && s_axi_wready && s_axi_awaddr[4:2] == 0 && s_axi_wdata[0]);

    assign s_axis_tready = (p_state == ST_RECEIVE) && (!core_data_vld);

    // =========================================================
    // Core Handshake & State Machine
    // =========================================================
    reg core_start;
    reg core_first_block;
    wire core_done;
    wire core_data_rdy;
    reg core_data_vld;
    reg [15:0] core_data_in;
    reg [3:0] core_digest_addr;
    wire [15:0] core_digest_out;

    wire word_accepted = core_data_rdy && core_data_vld;

    // ==========================================
    // Wrapper FSM
    // ==========================================
    localparam ST_IDLE       = 4'd0;
    localparam ST_START_BLK  = 4'd1;
    localparam ST_RECEIVE    = 4'd2;
    localparam ST_PAD_80     = 4'd3;
    localparam ST_PAD_00     = 4'd4;
    localparam ST_PAD_LEN_1  = 4'd5;
    localparam ST_PAD_LEN_2  = 4'd6;
    localparam ST_WAIT_DONE  = 4'd7;
    localparam ST_CAPTURE    = 4'd8;
    localparam ST_DONE       = 4'd9;
    localparam ST_WAIT_RDY   = 4'd10;

    reg [3:0] p_state;
    reg [31:0] bit_count;   // BUG #3 FIX: 32-bit counter
    reg [3:0] byte_in_block; // 0 to 15
    reg [7:0] byte_latch;
    reg [3:0] next_state_after_done;
    reg is_pad_len_blk;

    always @(posedge aclk) begin
        if (!aresetn || soft_reset) begin
            p_state <= ST_IDLE;
            bit_count <= 0;
            byte_in_block <= 0;
            byte_latch <= 0;
            
            core_data_in <= 0;
            core_data_vld <= 0;
            core_first_block <= 1;
            core_start <= 0;
            
            is_pad_len_blk <= 0;
            padder_done <= 0;
            core_digest_addr <= 0;
            next_state_after_done <= ST_IDLE;
        end else begin
            core_start <= 0;
            
            if (word_accepted) begin
                core_data_vld <= 0;
            end
            
            case (p_state)
                ST_IDLE: begin
                    if (s_axis_tvalid) begin
                        padder_done <= 0;
                        bit_count <= 0;
                        byte_in_block <= 0;
                        core_first_block <= 1;
                        is_pad_len_blk <= 0;
                        p_state <= ST_START_BLK;
                        next_state_after_done <= ST_RECEIVE;
                    end
                end
                
                ST_START_BLK: begin
                    core_start <= 1;
                    p_state <= ST_WAIT_RDY;
                end
                
                ST_WAIT_RDY: begin
                    if (core_data_rdy) begin
                        p_state <= next_state_after_done;
                    end
                end
                
                ST_WAIT_DONE: begin
                    if (core_done) begin
                        p_state <= next_state_after_done;
                    end
                end
                
                ST_RECEIVE: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        bit_count <= bit_count + 8;
                        
                        if (byte_in_block[0] == 0) begin
                            byte_latch <= s_axis_tdata;
                            if (s_axis_tlast) begin
                                p_state <= ST_PAD_80;
                            end
                        end else begin
                            core_data_in <= {byte_latch, s_axis_tdata};
                            core_data_vld <= 1;
                            
                            if (byte_in_block == 15) begin
                                core_first_block <= 0;
                                // Core will start hashing automatically when byte 15 is accepted
                                next_state_after_done <= (s_axis_tlast) ? ST_PAD_80 : ST_RECEIVE;
                                // Need to manually start core for NEXT block after it finishes this one
                                p_state <= ST_WAIT_DONE; 
                            end else begin
                                if (s_axis_tlast) p_state <= ST_PAD_80;
                            end
                        end
                        byte_in_block <= byte_in_block + 1;
                    end
                end
                
                ST_PAD_80: begin
                    if (!core_data_vld) begin
                        if (byte_in_block[0] == 0) begin
                            byte_latch <= 8'h80;
                            p_state <= ST_PAD_00;
                        end else begin
                            core_data_in <= {byte_latch, 8'h80};
                            core_data_vld <= 1;
                            p_state <= ST_PAD_00;
                            
                            if (byte_in_block == 15) begin
                                core_first_block <= 0;
                                next_state_after_done <= ST_PAD_00;
                                p_state <= ST_WAIT_DONE;
                            end
                        end
                        byte_in_block <= byte_in_block + 1;
                    end
                end
                
                ST_PAD_00: begin
                    if (!core_data_vld) begin
                        if (byte_in_block == 14) begin
                            p_state <= ST_PAD_LEN_1;
                        end else begin
                            if (byte_in_block[0] == 0) begin
                                byte_latch <= 8'h00;
                            end else begin
                                core_data_in <= {byte_latch, 8'h00};
                                core_data_vld <= 1;
                                
                                // BUG #2 FIX: Exact padding overflow
                                if (byte_in_block == 15) begin
                                    core_first_block <= 0;
                                    next_state_after_done <= ST_PAD_00; // Come back to pad 00 for the length block
                                    p_state <= ST_WAIT_DONE;
                                end
                            end
                            byte_in_block <= byte_in_block + 1;
                        end
                    end
                end
                
                ST_PAD_LEN_1: begin
                    if (!core_data_vld) begin
                        // Original requested 16-bit length (mini version)
                        byte_latch <= bit_count[15:8];
                        byte_in_block <= byte_in_block + 1;
                        p_state <= ST_PAD_LEN_2;
                    end
                end
                
                ST_PAD_LEN_2: begin
                    if (!core_data_vld) begin
                        core_data_in <= {byte_latch, bit_count[7:0]};
                        core_data_vld <= 1;
                        byte_in_block <= byte_in_block + 1;
                        is_pad_len_blk <= 1;
                        // Core will process the final block. Go to WAIT_DONE, then CAPTURE
                        next_state_after_done <= ST_CAPTURE;
                        p_state <= ST_WAIT_DONE;
                    end
                end
                
                ST_CAPTURE: begin
                    if (core_digest_addr < 8) begin
                        final_digest[127 - core_digest_addr*16 -: 16] <= core_digest_out;
                        core_digest_addr <= core_digest_addr + 1;
                    end else begin
                        core_digest_addr <= 0;
                        padder_done <= 1;
                        p_state <= ST_DONE;
                    end
                end
                
                ST_DONE: begin
                    // Wait for next transaction
                end
            endcase
            
            // Auto-restart core if it finished a block and we need to send more
            // core_done stays high while in S_DONE. So pulse start once, then core leaves S_DONE.
            if (core_done && p_state == ST_WAIT_DONE && next_state_after_done != ST_CAPTURE) begin
                core_start <= 1;
            end
        end
    end

    mini_sha256_core u_core (
        .clk(aclk),
        .rst_n(aresetn),
        .start(core_start),
        .first_block(core_first_block),
        .done(core_done),
        .data_rdy(core_data_rdy),
        .data_vld(core_data_vld),
        .data_in(core_data_in),
        .digest_addr(core_digest_addr),
        .digest_out(core_digest_out)
    );

endmodule
