module mini_k_rom (
    input  wire [4:0]  addr,
    output reg  [15:0] k_out
);

    always @(*) begin
        case (addr)
            5'd00: k_out = 16'h428a;
            5'd01: k_out = 16'h7137;
            5'd02: k_out = 16'hb5c0;
            5'd03: k_out = 16'he9b5;
            5'd04: k_out = 16'h3956;
            5'd05: k_out = 16'h59f1;
            5'd06: k_out = 16'h923f;
            5'd07: k_out = 16'hab1c;
            5'd08: k_out = 16'hd807;
            5'd09: k_out = 16'h1283;
            5'd10: k_out = 16'h2431;
            5'd11: k_out = 16'h550c;
            5'd12: k_out = 16'h72be;
            5'd13: k_out = 16'h80de;
            5'd14: k_out = 16'h9bdc;
            5'd15: k_out = 16'hc19b;
            5'd16: k_out = 16'he49b;
            5'd17: k_out = 16'hefbe;
            5'd18: k_out = 16'h0fc1;
            5'd19: k_out = 16'h240c;
            5'd20: k_out = 16'h2de9;
            5'd21: k_out = 16'h4a74;
            5'd22: k_out = 16'h5cb0;
            5'd23: k_out = 16'h76f9;
            5'd24: k_out = 16'h983e;
            5'd25: k_out = 16'ha831;
            5'd26: k_out = 16'hb003;
            5'd27: k_out = 16'hbf59;
            5'd28: k_out = 16'hc6e0;
            5'd29: k_out = 16'hd5a7;
            5'd30: k_out = 16'h06ca;
            5'd31: k_out = 16'h1429;
            default: k_out = 16'h0000;
        endcase
    end

endmodule
