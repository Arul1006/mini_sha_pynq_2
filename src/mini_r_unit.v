`timescale 1ns / 1ps
module mini_r_unit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        round_en,     // HIGH only during compression rounds
    input  wire [1:0]  aluop,
    input  wire [15:0] hash_alu_out,
    input  wire [15:0] C,
    input  wire [15:0] D,
    output reg  [15:0] D_prime,
    output wire [15:0] OutputR1
);

    reg [15:0] Reg1, Reg2;
    assign OutputR1 = Reg1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Reg1 <= 16'h0;
            Reg2 <= 16'h0;
        end else if (round_en) begin
            Reg1 <= hash_alu_out;
            if (aluop == 2'b01)
                Reg2 <= C;
        end
    end

    always @(*) begin
        case (aluop)
            2'b01:   D_prime = Reg1;
            2'b10:   D_prime = Reg1 - Reg2;
            default: D_prime = D;
        endcase
    end

endmodule
