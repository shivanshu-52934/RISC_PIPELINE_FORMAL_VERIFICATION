module forwarding_unit (
    input  logic [4:0] id_ex_rs1_i,
    input  logic [4:0] id_ex_rs2_i,
    input  logic [4:0] ex_mem_rd_i,
    input  logic       ex_mem_reg_write_i,
    input  logic       ex_mem_mem_read_i,
    input  logic [4:0] mem_wb_rd_i,
    input  logic       mem_wb_reg_write_i,
    output logic [1:0] forward_a_o,
    output logic [1:0] forward_b_o
);
    localparam logic [1:0] FWD_REG = 2'd0;
    localparam logic [1:0] FWD_MEM = 2'd1;
    localparam logic [1:0] FWD_WB  = 2'd2;

    always_comb begin
        forward_a_o = FWD_REG;
        forward_b_o = FWD_REG;

        if (ex_mem_reg_write_i && !ex_mem_mem_read_i &&
            (ex_mem_rd_i != 5'd0) && (ex_mem_rd_i == id_ex_rs1_i)) begin
            forward_a_o = FWD_MEM;
        end else if (mem_wb_reg_write_i &&
            (mem_wb_rd_i != 5'd0) && (mem_wb_rd_i == id_ex_rs1_i)) begin
            forward_a_o = FWD_WB;
        end

        if (ex_mem_reg_write_i && !ex_mem_mem_read_i &&
            (ex_mem_rd_i != 5'd0) && (ex_mem_rd_i == id_ex_rs2_i)) begin
            forward_b_o = FWD_MEM;
        end else if (mem_wb_reg_write_i &&
            (mem_wb_rd_i != 5'd0) && (mem_wb_rd_i == id_ex_rs2_i)) begin
            forward_b_o = FWD_WB;
        end
    end
endmodule
