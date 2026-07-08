module mini_au_unit (
    input  wire [1:0]  au_sel,
    input  wire [15:0] A,
    input  wire [15:0] B,
    output reg  [15:0] au_out
);

    always @(*) begin
        case (au_sel)
            2'b00: au_out = A + B;       // e.g. h + Kt
            2'b01: au_out = A + B;       // e.g. H0 + a
            default: au_out = A + B;
        endcase
    end

endmodule
