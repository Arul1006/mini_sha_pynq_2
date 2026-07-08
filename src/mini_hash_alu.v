`timescale 1ns / 1ps
`include "mini_sha256_functions.vh"

module mini_hash_alu (
    input  wire [1:0]  aluop,
    input  wire [15:0] A,      // e / h / a / Wt-2
    input  wire [15:0] B,      // f / Kt/ b / Wt-4
    input  wire [15:0] C,      // g / d / c / Wt-7
    input  wire [15:0] D_prime,// Wt / T_x / (T_y-d) / Wt-8
    output reg  [15:0] result
);

    // Internal wires for each sub-function
    wire [15:0] sig_upper_0_A = `SIGMA_UPPER_0(A);
    wire [15:0] sig_upper_1_A = `SIGMA_UPPER_1(A);
    wire [15:0] sig_lower_0_C = `SIGMA_LOWER_0(C);
    wire [15:0] sig_lower_1_A = `SIGMA_LOWER_1(A);
    wire [15:0] ch_ABC        = `CH(A, B, C);
    wire [15:0] maj_ABC       = `MAJ(A, B, C);

    always @(*) begin
        case (aluop)
            2'b00: // T_x = Σ1(e) + Ch(e,f,g) + Wt + 0
                result = sig_upper_1_A + ch_ABC + D_prime;

            2'b01: // T_y = h + Kt + d + T_x
                result = A + B + C + D_prime;

            2'b10: // T_z = Σ0(a) + Maj(a,b,c) + (T_y - d) + 0
                result = sig_upper_0_A + maj_ABC + D_prime;

            2'b11: // Wt_expand = σ1(Wt-2) + Wt-4 + σ0(Wt-7) + Wt-8
                result = sig_lower_1_A + B + sig_lower_0_C + D_prime;

            default:
                result = 16'h0;
        endcase
    end

endmodule
