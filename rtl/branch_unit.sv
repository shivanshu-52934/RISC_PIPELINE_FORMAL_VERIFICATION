module branch_unit (
    input  logic        branch_i,
    input  logic [31:0] pc_i,
    input  logic [31:0] imm_i,
    input  logic [31:0] rs1_i,
    input  logic [31:0] rs2_i,
    output logic        taken_o,
    output logic [31:0] target_o
);
    assign taken_o = branch_i && (rs1_i == rs2_i);
    assign target_o = pc_i + imm_i;
endmodule
