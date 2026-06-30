`timescale 1ns / 1ps
module mini_sha256_core (
    input  wire        clk,
    input  wire        rst_n,

    // Control Interface
    input  wire        start,
    input  wire        first_block, // 1 to initialize with IVs, 0 to chain
    output wire        done,
    output wire        data_rdy,

    // Data Interface
    input  wire        data_vld,
    input  wire [15:0] data_in,     // Incoming message words
    input  wire [2:0]  digest_addr, // Address to read specific 16-bit chunk of the digest
    output reg  [15:0] digest_out   // 16-bit output bus
);

    wire [3:0]  sel_A, sel_B, sel_C, sel_D, wr_dst;
    wire [1:0]  aluop, au_sel;
    wire        out_sel, reg_we, round_en;
    wire        w_wr_en, msg_wr_en, h_wr_en, h_load_en;
    wire [3:0]  w_wr_addr, w_rd_addr_A, w_rd_addr_B, w_rd_addr_C, w_rd_addr_D;
    wire [2:0]  h_wr_addr, h_rd_addr;
    wire [4:0]  k_addr;
    wire [15:0] ext_data;
    wire [15:0] k_val;

    // Connect ext_data routing
    // When msg_wr_en is high, the controller is loading data_in into W
    // When h_load_en is high, the controller is loading IVs into H
    wire [15:0] datapath_ext_data = msg_wr_en ? data_in : ext_data;

    mini_sha256_controller u_ctrl (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .data_vld   (data_vld),
        .data_rdy   (data_rdy),
        .first_block(first_block),
        .done       (done),

        .sel_A      (sel_A),
        .sel_B      (sel_B),
        .sel_C      (sel_C),
        .sel_D      (sel_D),
        .aluop      (aluop),
        .au_sel     (au_sel),
        .out_sel    (out_sel),
        .wr_dst     (wr_dst),
        .reg_we     (reg_we),

        .w_wr_en    (w_wr_en),
        .w_wr_addr  (w_wr_addr),
        .w_rd_addr_A(w_rd_addr_A),
        .w_rd_addr_B(w_rd_addr_B),
        .w_rd_addr_C(w_rd_addr_C),
        .w_rd_addr_D(w_rd_addr_D),

        .h_wr_en    (h_wr_en),
        .h_wr_addr  (h_wr_addr),
        .h_rd_addr  (h_rd_addr),

        .round_en   (round_en),
        .k_addr     (k_addr),

        .msg_wr_en  (msg_wr_en),
        .h_load_en  (h_load_en),
        .ext_data   (ext_data) // IVs driven by controller
    );

    wire [127:0] full_digest;

    mini_sha256_datapath u_datapath (
        .clk        (clk),
        .rst_n      (rst_n),
        .ext_data   (datapath_ext_data),
        .w_wr_addr  (w_wr_addr),
        .w_rd_addr_A(w_rd_addr_A),
        .w_rd_addr_B(w_rd_addr_B),
        .w_rd_addr_C(w_rd_addr_C),
        .w_rd_addr_D(w_rd_addr_D),
        .w_wr_en    (w_wr_en),
        .msg_wr_en  (msg_wr_en),

        .h_wr_addr  (h_wr_addr),
        .h_rd_addr  (h_rd_addr),
        .h_wr_en    (h_wr_en),
        
        .aluop      (aluop),
        .k_in       (k_val),
        .sel_A      (sel_A),
        .sel_B      (sel_B),
        .sel_C      (sel_C),
        .sel_D      (sel_D),
        .au_sel     (au_sel),
        .out_sel    (out_sel),
        .wr_dst     (wr_dst),
        .reg_we     (reg_we),
        .round_en   (round_en),
        .h_load_en  (h_load_en),

        .data_out   (),
        .digest     (full_digest)
    );

    mini_k_rom u_k_rom (
        .addr       (k_addr),
        .k_out      (k_val)
    );

    always @(*) begin
        case (digest_addr)
            3'd0: digest_out = full_digest[127:112];
            3'd1: digest_out = full_digest[111:96];
            3'd2: digest_out = full_digest[95:80];
            3'd3: digest_out = full_digest[79:64];
            3'd4: digest_out = full_digest[63:48];
            3'd5: digest_out = full_digest[47:32];
            3'd6: digest_out = full_digest[31:16];
            3'd7: digest_out = full_digest[15:0];
        endcase
    end

endmodule
