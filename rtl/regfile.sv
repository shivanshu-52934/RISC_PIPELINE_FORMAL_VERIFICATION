module regfile (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic [4:0]  rs1_i,
    input  logic [4:0]  rs2_i,
    output logic [31:0] rs1_data_o,
    output logic [31:0] rs2_data_o,
    input  logic        we_i,
    input  logic [4:0]  rd_i,
    input  logic [31:0] rd_data_i,
    output logic [31:0] x0_value_o
);
    logic [31:0] regs_q [31:0];
    integer i;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs_q[i] <= 32'd0;
            end
        end else if (we_i && (rd_i != 5'd0)) begin
            regs_q[rd_i] <= rd_data_i;
        end
    end

    assign rs1_data_o = (rs1_i == 5'd0) ? 32'd0 : regs_q[rs1_i];
    assign rs2_data_o = (rs2_i == 5'd0) ? 32'd0 : regs_q[rs2_i];
    assign x0_value_o = regs_q[0];
endmodule
