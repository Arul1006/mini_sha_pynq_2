`timescale 1ns / 1ps
module mini_sha256_datapath (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        round_en,

    // --- Operand selects (FSM drives these) ---
    input  wire [3:0]  sel_A,
    input  wire [3:0]  sel_B,
    input  wire [3:0]  sel_C,
    input  wire [3:0]  sel_D,

    // --- ALU controls ---
    input  wire [1:0]  aluop,
    input  wire [1:0]  au_sel,
    input  wire        out_sel,    // 0=HASH_ALU result, 1=AU result

    // --- Write-back (working variables) ---
    input  wire [3:0]  wr_dst,
    input  wire        reg_we,

    // --- W_cache access ---
    input  wire        w_wr_en,
    input  wire [3:0]  w_wr_addr,
    input  wire [3:0]  w_rd_addr_A,
    input  wire [3:0]  w_rd_addr_B,
    input  wire [3:0]  w_rd_addr_C,
    input  wire [3:0]  w_rd_addr_D,

    // --- H_prev access ---
    input  wire        h_wr_en,
    input  wire [2:0]  h_wr_addr,
    input  wire [2:0]  h_rd_addr,

    // --- External inputs ---
    input  wire [15:0] k_in,       // current K[t] from ROM
    input  wire [15:0] ext_data,   // message word or H value being loaded
    input  wire        msg_wr_en,  // write ext_data into W_cache
    input  wire        h_load_en,  // write ext_data into H_prev

    // --- Output ---
    output wire [15:0] data_out,
    output wire [127:0] digest
);

    // =========================================================
    // Working variable registers (a through h)
    // =========================================================
    reg [15:0] wrk [0:7];

    // =========================================================
    // W_cache: 16×16 sliding window for Message Schedule
    // =========================================================
    reg [15:0] W_cache [0:15];

    // =========================================================
    // H_prev: 8×16 intermediate hash
    // =========================================================
    reg [15:0] H_prev [0:7];

    assign digest = {H_prev[0], H_prev[1], H_prev[2], H_prev[3], 
                     H_prev[4], H_prev[5], H_prev[6], H_prev[7]};

    // =========================================================
    // Operand read mux
    // =========================================================
    function [15:0] sel_operand;
        input [3:0]  sel;
        input [3:0]  w_addr;
        input [2:0]  h_addr;
        input [15:0] k;
        begin
            case (sel)
                4'd0:    sel_operand = wrk[0];          // a
                4'd1:    sel_operand = wrk[1];          // b
                4'd2:    sel_operand = wrk[2];          // c
                4'd3:    sel_operand = wrk[3];          // d
                4'd4:    sel_operand = wrk[4];          // e
                4'd5:    sel_operand = wrk[5];          // f
                4'd6:    sel_operand = wrk[6];          // g
                4'd7:    sel_operand = wrk[7];          // h
                4'd8:    sel_operand = W_cache[w_addr]; // W[t]
                4'd9:    sel_operand = H_prev[h_addr];  // H_prev[j]
                4'd10:   sel_operand = k;               // Kt
                default: sel_operand = 16'h0;
            endcase
        end
    endfunction

    wire [15:0] opA = sel_operand(sel_A, w_rd_addr_A, h_rd_addr, k_in);
    wire [15:0] opB = sel_operand(sel_B, w_rd_addr_B, h_rd_addr, k_in);
    wire [15:0] opC = sel_operand(sel_C, w_rd_addr_C, h_rd_addr, k_in);
    wire [15:0] opD = sel_operand(sel_D, w_rd_addr_D, h_rd_addr, k_in);

    // =========================================================
    // R unit
    // =========================================================
    wire [15:0] D_prime, OutputR1, alu_result;

    mini_r_unit u_r (
        .clk         (clk),
        .round_en    (round_en),
        .rst_n       (rst_n),
        .aluop       (aluop),
        .hash_alu_out(alu_result),
        .C           (opC),
        .D           (opD),
        .D_prime     (D_prime),
        .OutputR1    (OutputR1)
    );

    // =========================================================
    // HASH_ALU
    // =========================================================
    mini_hash_alu u_hash_alu (
        .aluop   (aluop),
        .A       (opA),
        .B       (opB),
        .C       (opC),
        .D_prime (D_prime),
        .result  (alu_result)
    );

    // =========================================================
    // AU unit
    // =========================================================
    wire [15:0] au_result;

    mini_au_unit u_au (
        .au_sel (au_sel),
        .A      (opA),
        .B      (opB),
        .au_out (au_result)
    );

    // =========================================================
    // Output MUX
    // =========================================================
    assign data_out = out_sel ? au_result : alu_result;

    // =========================================================
    // Write-back logic
    // =========================================================
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i+1)
                wrk[i] <= 16'h0;
        end else if (reg_we && wr_dst < 4'd8) begin
            wrk[wr_dst] <= data_out;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 16; i = i+1)
                W_cache[i] <= 16'h0;
        end else if (msg_wr_en) begin
            W_cache[w_wr_addr] <= ext_data;
        end else if (w_wr_en) begin
            W_cache[w_wr_addr] <= alu_result;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i+1)
                H_prev[i] <= 16'h0;
        end else if (h_load_en) begin
            H_prev[h_wr_addr] <= ext_data;
        end else if (h_wr_en) begin
            H_prev[h_wr_addr] <= au_result;
        end
    end

endmodule
