`timescale 1ns / 1ps

module mini_sha256_controller (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire        data_vld,
    output reg         data_rdy,
    
    // External block input
    input  wire        first_block,
    output reg         done,

    // Datapath controls
    output reg [3:0]  sel_A,
    output reg [3:0]  sel_B,
    output reg [3:0]  sel_C,
    output reg [3:0]  sel_D,
    output reg [1:0]  aluop,
    output reg [1:0]  au_sel,
    output reg        out_sel,
    output reg [3:0]  wr_dst,
    output reg        reg_we,
    
    output reg        w_wr_en,
    output reg [3:0]  w_wr_addr,
    output reg [3:0]  w_rd_addr_A,
    output reg [3:0]  w_rd_addr_B,
    output reg [3:0]  w_rd_addr_C,
    output reg [3:0]  w_rd_addr_D,
    
    output reg        h_wr_en,
    output reg [2:0]  h_wr_addr,
    output reg [2:0]  h_rd_addr,
    
    output reg        round_en,
    output reg [4:0]  k_addr, // 32 rounds max
    
    output reg        msg_wr_en,
    output reg        h_load_en,
    output reg [15:0] ext_data
);

    // States
    localparam S_IDLE        = 4'd0;
    localparam S_LOAD_IV     = 4'd1;
    localparam S_LOAD_MSG    = 4'd2;
    localparam S_INIT_VARS   = 4'd3;
    localparam S_COMPRESS_WT = 4'd4;
    localparam S_COMPRESS_TX = 4'd5;
    localparam S_COMPRESS_TY = 4'd6;
    localparam S_COMPRESS_TZ = 4'd7;
    localparam S_UPDATE_H    = 4'd8;
    localparam S_DONE        = 4'd9;

    reg [3:0] state, next_state;
    reg [5:0] round_ctr, next_round_ctr;
    reg [3:0] sub_ctr, next_sub_ctr;
    
    // Rotating pointers for working variables a..h
    reg [2:0] p_start;
    wire [2:0] p_a = p_start;
    wire [2:0] p_b = p_start + 1;
    wire [2:0] p_c = p_start + 2;
    wire [2:0] p_d = p_start + 3;
    wire [2:0] p_e = p_start + 4;
    wire [2:0] p_f = p_start + 5;
    wire [2:0] p_g = p_start + 6;
    wire [2:0] p_h = p_start + 7;

    // IV ROM
    wire [15:0] IV [0:7];
    assign IV[0] = 16'h6a09;
    assign IV[1] = 16'hbb67;
    assign IV[2] = 16'h3c6e;
    assign IV[3] = 16'ha54f;
    assign IV[4] = 16'h510e;
    assign IV[5] = 16'h9b05;
    assign IV[6] = 16'h1f83;
    assign IV[7] = 16'h5be0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            round_ctr <= 0;
            sub_ctr <= 0;
            p_start <= 0;
        end else begin
            state <= next_state;
            round_ctr <= next_round_ctr;
            sub_ctr <= next_sub_ctr;
            if (state == S_COMPRESS_TZ) p_start <= p_start - 1;
            else if (state == S_IDLE)   p_start <= 0;
        end
    end

    always @(*) begin
        // Default values
        next_state = state;
        next_round_ctr = round_ctr;
        next_sub_ctr = sub_ctr;
        
        sel_A = 4'd11; sel_B = 4'd11; sel_C = 4'd11; sel_D = 4'd11;
        aluop = 2'b00; au_sel = 2'b11; out_sel = 0; wr_dst = 4'd8; reg_we = 0;
        w_wr_en = 0; w_wr_addr = 0;
        w_rd_addr_A = 0; w_rd_addr_B = 0; w_rd_addr_C = 0; w_rd_addr_D = 0;
        h_wr_en = 0; h_wr_addr = 0; h_rd_addr = 0;
        round_en = 0; k_addr = round_ctr[4:0]; // Default to current round
        msg_wr_en = 0; h_load_en = 0; ext_data = 0;
        done = 0;
        data_rdy = (state == S_IDLE) || (state == S_LOAD_MSG);

        case (state)
            S_IDLE: begin
                if (start) begin
                    if (first_block) next_state = S_LOAD_IV;
                    else next_state = S_LOAD_MSG;
                    next_sub_ctr = 0;
                end
            end
            
            S_LOAD_IV: begin
                h_load_en = 1;
                h_wr_addr = sub_ctr[2:0];
                ext_data = IV[sub_ctr[2:0]];
                if (sub_ctr == 7) begin
                    next_state = S_LOAD_MSG;
                    next_sub_ctr = 0;
                end else begin
                    next_sub_ctr = sub_ctr + 1;
                end
            end
            
            S_LOAD_MSG: begin
                if (data_vld) begin
                    msg_wr_en = 1;
                    w_wr_addr = sub_ctr[3:0]; // Datapath handles the actual ext_data routing in the top module wrapper!
                    // Wait! The datapath ext_data is connected to data_in in the top module wrapper.
                    // Actually, let's just assert msg_wr_en.
                    if (sub_ctr == 7) begin // 8 words for Mini SHA!
                        next_state = S_INIT_VARS;
                        next_sub_ctr = 0;
                    end else begin
                        next_sub_ctr = sub_ctr + 1;
                    end
                end
            end

            S_INIT_VARS: begin
                // a=H0, b=H1... Load via AU unit (H + 0)
                sel_A = 4'd9; // H_prev
                sel_B = 4'd11; // 0
                h_rd_addr = sub_ctr[2:0];
                au_sel = 2'b00; // A + B
                out_sel = 1; // AU result
                wr_dst = sub_ctr[3:0]; // 0 to 7
                reg_we = 1;
                
                if (sub_ctr == 7) begin
                    next_state = S_COMPRESS_WT;
                    next_round_ctr = 0;
                end else begin
                    next_sub_ctr = sub_ctr + 1;
                end
            end

            S_COMPRESS_WT: begin
                round_en = 1;
                if (round_ctr < 8) begin
                    // W_t already loaded, skip to Tx
                    next_state = S_COMPRESS_TX;
                end else begin
                    // W[t] = sig1(W[t-2]) + W[t-4] + sig0(W[t-7]) + W[t-8]
                    sel_A = 4'd8; w_rd_addr_A = (round_ctr - 2) & 15;
                    sel_B = 4'd8; w_rd_addr_B = (round_ctr - 4) & 15;
                    sel_C = 4'd8; w_rd_addr_C = (round_ctr - 7) & 15; // sigma0
                    sel_D = 4'd8; w_rd_addr_D = (round_ctr - 8) & 15;  // plain addition
                    aluop = 2'b11; // Wt_expand
                    w_wr_en = 1;
                    w_wr_addr = round_ctr[3:0]; // Modulo 16
                    next_state = S_COMPRESS_TX;
                end
            end

            S_COMPRESS_TX: begin
                round_en = 1;
                sel_A = {1'b0, p_e};
                sel_B = {1'b0, p_f};
                sel_C = {1'b0, p_g};
                sel_D = 4'd8; w_rd_addr_D = round_ctr[3:0]; // Wt
                aluop = 2'b00; // Tx
                // Result automatically latched into R1 by round_en
                next_state = S_COMPRESS_TY;
            end

            S_COMPRESS_TY: begin
                round_en = 1;
                sel_A = {1'b0, p_h};
                sel_B = 4'd10; // Kt
                sel_C = {1'b0, p_d};
                sel_D = 4'd11; // D comes from R1 (Tx)
                aluop = 2'b01; // Ty
                wr_dst = {1'b0, p_d}; // e = Ty (written to old d)
                reg_we = 1;
                out_sel = 0; // HASH_ALU
                next_state = S_COMPRESS_TZ;
            end

            S_COMPRESS_TZ: begin
                round_en = 1;
                sel_A = {1'b0, p_a};
                sel_B = {1'b0, p_b};
                sel_C = {1'b0, p_c};
                sel_D = 4'd11; // D comes from R1 - Reg2 (Ty - d)
                aluop = 2'b10; // Tz
                wr_dst = {1'b0, p_h}; // a = Tz (written to old h)
                reg_we = 1;
                out_sel = 0; // HASH_ALU
                
                if (round_ctr == 31) begin
                    next_state = S_UPDATE_H;
                    next_sub_ctr = 0;
                end else begin
                    next_state = S_COMPRESS_WT;
                    next_round_ctr = round_ctr + 1;
                end
            end

            S_UPDATE_H: begin
                // H_prev[j] = H_prev[j] + wrk[j]
                sel_A = 4'd9; h_rd_addr = sub_ctr[2:0]; // H_prev
                sel_B = {1'b0, sub_ctr[2:0]}; // wrk[j] -- Wait, we need to read wrk without rotating!
                // Actually sel_B = sub_ctr maps to wrk[0..7] linearly because sel_B handles 0..7 as direct addressing!
                au_sel = 2'b00; // A + B
                h_wr_en = 1;
                h_wr_addr = sub_ctr[2:0];
                out_sel = 1; // AU
                
                if (sub_ctr == 7) begin
                    next_state = S_DONE;
                end else begin
                    next_sub_ctr = sub_ctr + 1;
                end
            end

            S_DONE: begin
                done = 1;
                next_state = S_IDLE;
            end
        endcase
    end
endmodule
