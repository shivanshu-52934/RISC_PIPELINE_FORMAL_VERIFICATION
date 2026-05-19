module alu (
    input  logic [31:0] a_i,
    input  logic [31:0] b_i,
    input  logic [3:0]  op_i,
    output logic [31:0] y_o,
    output logic        zero_o
);
    localparam logic [3:0] ALU_ADD = 4'd0;
    localparam logic [3:0] ALU_SUB = 4'd1;
    localparam logic [3:0] ALU_AND = 4'd2;
    localparam logic [3:0] ALU_OR  = 4'd3;
    localparam logic [3:0] ALU_XOR = 4'd4;
    localparam logic [3:0] ALU_SLT = 4'd5;

    always_comb begin
        unique case (op_i)
            ALU_ADD: y_o = a_i + b_i;
            ALU_SUB: y_o = a_i - b_i;
            ALU_AND: y_o = a_i & b_i;
            ALU_OR:  y_o = a_i | b_i;
            ALU_XOR: y_o = a_i ^ b_i;
            ALU_SLT: y_o = ($signed(a_i) < $signed(b_i)) ? 32'd1 : 32'd0;
            default: y_o = 32'd0;
        endcase
    end

    assign zero_o = (y_o == 32'd0);
endmodule
