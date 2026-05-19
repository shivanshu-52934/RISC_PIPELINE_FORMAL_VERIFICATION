module core (
    input  logic        clk_i,
    input  logic        rst_ni,
    output logic [31:0] imem_addr_o,
    input  logic [31:0] imem_rdata_i,
    output logic        dmem_read_o,
    output logic        dmem_write_o,
    output logic [31:0] dmem_addr_o,
    output logic [31:0] dmem_wdata_o,
    input  logic [31:0] dmem_rdata_i,
    output logic [31:0] pc_o,
    output logic        wb_valid_o,
    output logic [4:0]  wb_rd_o,
    output logic [31:0] wb_data_o
);
    localparam logic [6:0] OPCODE_OP     = 7'b0110011;
    localparam logic [6:0] OPCODE_OP_IMM = 7'b0010011;
    localparam logic [6:0] OPCODE_LOAD   = 7'b0000011;
    localparam logic [6:0] OPCODE_STORE  = 7'b0100011;
    localparam logic [6:0] OPCODE_BRANCH = 7'b1100011;

    localparam logic [3:0] ALU_ADD = 4'd0;
    localparam logic [3:0] ALU_SUB = 4'd1;
    localparam logic [3:0] ALU_AND = 4'd2;
    localparam logic [3:0] ALU_OR  = 4'd3;
    localparam logic [3:0] ALU_XOR = 4'd4;
    localparam logic [3:0] ALU_SLT = 4'd5;

    logic [31:0] pc_q;
    logic [31:0] if_id_pc_q, if_id_instr_q;
    logic        if_id_valid_q;

    logic [31:0] id_ex_pc_q, id_ex_rs1_data_q, id_ex_rs2_data_q, id_ex_imm_q;
    logic [4:0]  id_ex_rs1_q, id_ex_rs2_q, id_ex_rd_q;
    logic [3:0]  id_ex_alu_op_q;
    logic        id_ex_valid_q, id_ex_reg_write_q, id_ex_mem_read_q;
    logic        id_ex_mem_write_q, id_ex_branch_q, id_ex_alu_src_imm_q;
    logic        id_ex_uses_rs1_q, id_ex_uses_rs2_q;

    logic [31:0] ex_mem_alu_result_q, ex_mem_rs2_data_q, ex_mem_branch_target_q;
    logic [4:0]  ex_mem_rd_q;
    logic        ex_mem_valid_q, ex_mem_reg_write_q, ex_mem_mem_read_q;
    logic        ex_mem_mem_write_q, ex_mem_branch_taken_q;

    logic [31:0] mem_wb_data_q;
    logic [4:0]  mem_wb_rd_q;
    logic        mem_wb_valid_q, mem_wb_reg_write_q;

    logic [4:0]  id_rs1, id_rs2, id_rd;
    logic [6:0]  id_opcode;
    logic [2:0]  id_funct3;
    logic [6:0]  id_funct7;
    logic [31:0] id_imm;
    logic [3:0]  id_alu_op;
    logic        id_reg_write, id_mem_read, id_mem_write, id_branch;
    logic        id_alu_src_imm, id_uses_rs1, id_uses_rs2;
    logic [31:0] id_rs1_data, id_rs2_data, x0_value;

    logic [1:0]  forward_a, forward_b;
    logic [31:0] ex_operand_a, ex_operand_b_reg, ex_operand_b;
    logic [31:0] ex_alu_result;
    logic        ex_branch_taken;
    logic [31:0] ex_branch_target;
    logic        load_use_stall;

    assign pc_o = pc_q;
    assign imem_addr_o = pc_q;

    assign id_opcode = if_id_instr_q[6:0];
    assign id_rd     = if_id_instr_q[11:7];
    assign id_funct3 = if_id_instr_q[14:12];
    assign id_rs1    = if_id_instr_q[19:15];
    assign id_rs2    = if_id_instr_q[24:20];
    assign id_funct7 = if_id_instr_q[31:25];

    always_comb begin
        id_imm = 32'd0;
        unique case (id_opcode)
            OPCODE_OP_IMM,
            OPCODE_LOAD: begin
                id_imm = {{20{if_id_instr_q[31]}}, if_id_instr_q[31:20]};
            end
            OPCODE_STORE: begin
                id_imm = {{20{if_id_instr_q[31]}}, if_id_instr_q[31:25], if_id_instr_q[11:7]};
            end
            OPCODE_BRANCH: begin
                id_imm = {{19{if_id_instr_q[31]}}, if_id_instr_q[31], if_id_instr_q[7],
                          if_id_instr_q[30:25], if_id_instr_q[11:8], 1'b0};
            end
            default: id_imm = 32'd0;
        endcase
    end

    always_comb begin
        id_reg_write  = 1'b0;
        id_mem_read   = 1'b0;
        id_mem_write  = 1'b0;
        id_branch     = 1'b0;
        id_alu_src_imm = 1'b0;
        id_uses_rs1   = 1'b0;
        id_uses_rs2   = 1'b0;
        id_alu_op     = ALU_ADD;

        unique case (id_opcode)
            OPCODE_OP: begin
                id_reg_write = 1'b1;
                id_uses_rs1 = 1'b1;
                id_uses_rs2 = 1'b1;
                unique case ({id_funct7, id_funct3})
                    {7'b0000000, 3'b000}: id_alu_op = ALU_ADD;
                    {7'b0100000, 3'b000}: id_alu_op = ALU_SUB;
                    {7'b0000000, 3'b111}: id_alu_op = ALU_AND;
                    {7'b0000000, 3'b110}: id_alu_op = ALU_OR;
                    {7'b0000000, 3'b100}: id_alu_op = ALU_XOR;
                    {7'b0000000, 3'b010}: id_alu_op = ALU_SLT;
                    default: begin
                        id_reg_write = 1'b0;
                        id_uses_rs1 = 1'b0;
                        id_uses_rs2 = 1'b0;
                    end
                endcase
            end
            OPCODE_OP_IMM: begin
                id_reg_write = 1'b1;
                id_alu_src_imm = 1'b1;
                id_uses_rs1 = 1'b1;
                unique case (id_funct3)
                    3'b000: id_alu_op = ALU_ADD;
                    3'b111: id_alu_op = ALU_AND;
                    3'b110: id_alu_op = ALU_OR;
                    3'b100: id_alu_op = ALU_XOR;
                    3'b010: id_alu_op = ALU_SLT;
                    default: begin
                        id_reg_write = 1'b0;
                        id_uses_rs1 = 1'b0;
                    end
                endcase
            end
            OPCODE_LOAD: begin
                id_reg_write = 1'b1;
                id_mem_read = 1'b1;
                id_alu_src_imm = 1'b1;
                id_uses_rs1 = 1'b1;
            end
            OPCODE_STORE: begin
                id_mem_write = 1'b1;
                id_alu_src_imm = 1'b1;
                id_uses_rs1 = 1'b1;
                id_uses_rs2 = 1'b1;
            end
            OPCODE_BRANCH: begin
                id_branch = (id_funct3 == 3'b000);
                id_uses_rs1 = (id_funct3 == 3'b000);
                id_uses_rs2 = (id_funct3 == 3'b000);
                id_alu_op = ALU_SUB;
            end
            default: begin
            end
        endcase
    end

    regfile u_regfile (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .rs1_i(id_rs1),
        .rs2_i(id_rs2),
        .rs1_data_o(id_rs1_data),
        .rs2_data_o(id_rs2_data),
        .we_i(mem_wb_valid_q && mem_wb_reg_write_q),
        .rd_i(mem_wb_rd_q),
        .rd_data_i(mem_wb_data_q),
        .x0_value_o(x0_value)
    );

    hazard_unit u_hazard_unit (
        .id_ex_mem_read_i(id_ex_mem_read_q && id_ex_valid_q),
        .id_ex_rd_i(id_ex_rd_q),
        .if_id_rs1_i(id_rs1),
        .if_id_rs2_i(id_rs2),
        .if_id_uses_rs1_i(id_uses_rs1 && if_id_valid_q),
        .if_id_uses_rs2_i(id_uses_rs2 && if_id_valid_q),
        .stall_o(load_use_stall)
    );

    forwarding_unit u_forwarding_unit (
        .id_ex_rs1_i(id_ex_rs1_q),
        .id_ex_rs2_i(id_ex_rs2_q),
        .ex_mem_rd_i(ex_mem_rd_q),
        .ex_mem_reg_write_i(ex_mem_valid_q && ex_mem_reg_write_q),
        .ex_mem_mem_read_i(ex_mem_mem_read_q),
        .mem_wb_rd_i(mem_wb_rd_q),
        .mem_wb_reg_write_i(mem_wb_valid_q && mem_wb_reg_write_q),
        .forward_a_o(forward_a),
        .forward_b_o(forward_b)
    );

    always_comb begin
        unique case (forward_a)
            2'd1: ex_operand_a = ex_mem_alu_result_q;
            2'd2: ex_operand_a = mem_wb_data_q;
            default: ex_operand_a = id_ex_rs1_data_q;
        endcase

        unique case (forward_b)
            2'd1: ex_operand_b_reg = ex_mem_alu_result_q;
            2'd2: ex_operand_b_reg = mem_wb_data_q;
            default: ex_operand_b_reg = id_ex_rs2_data_q;
        endcase
    end

    assign ex_operand_b = id_ex_alu_src_imm_q ? id_ex_imm_q : ex_operand_b_reg;

    alu u_alu (
        .a_i(ex_operand_a),
        .b_i(ex_operand_b),
        .op_i(id_ex_alu_op_q),
        .y_o(ex_alu_result),
        .zero_o()
    );

    branch_unit u_branch_unit (
        .branch_i(id_ex_valid_q && id_ex_branch_q),
        .pc_i(id_ex_pc_q),
        .imm_i(id_ex_imm_q),
        .rs1_i(ex_operand_a),
        .rs2_i(ex_operand_b_reg),
        .taken_o(ex_branch_taken),
        .target_o(ex_branch_target)
    );

    assign dmem_read_o  = ex_mem_valid_q && ex_mem_mem_read_q;
    assign dmem_write_o = ex_mem_valid_q && ex_mem_mem_write_q;
    assign dmem_addr_o  = ex_mem_alu_result_q;
    assign dmem_wdata_o = ex_mem_rs2_data_q;

    assign wb_valid_o = mem_wb_valid_q && mem_wb_reg_write_q && (mem_wb_rd_q != 5'd0);
    assign wb_rd_o = mem_wb_rd_q;
    assign wb_data_o = mem_wb_data_q;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            pc_q <= 32'd0;
            if_id_pc_q <= 32'd0;
            if_id_instr_q <= 32'd0;
            if_id_valid_q <= 1'b0;
            id_ex_pc_q <= 32'd0;
            id_ex_rs1_data_q <= 32'd0;
            id_ex_rs2_data_q <= 32'd0;
            id_ex_imm_q <= 32'd0;
            id_ex_rs1_q <= 5'd0;
            id_ex_rs2_q <= 5'd0;
            id_ex_rd_q <= 5'd0;
            id_ex_alu_op_q <= ALU_ADD;
            id_ex_valid_q <= 1'b0;
            id_ex_reg_write_q <= 1'b0;
            id_ex_mem_read_q <= 1'b0;
            id_ex_mem_write_q <= 1'b0;
            id_ex_branch_q <= 1'b0;
            id_ex_alu_src_imm_q <= 1'b0;
            id_ex_uses_rs1_q <= 1'b0;
            id_ex_uses_rs2_q <= 1'b0;
            ex_mem_alu_result_q <= 32'd0;
            ex_mem_rs2_data_q <= 32'd0;
            ex_mem_branch_target_q <= 32'd0;
            ex_mem_rd_q <= 5'd0;
            ex_mem_valid_q <= 1'b0;
            ex_mem_reg_write_q <= 1'b0;
            ex_mem_mem_read_q <= 1'b0;
            ex_mem_mem_write_q <= 1'b0;
            ex_mem_branch_taken_q <= 1'b0;
            mem_wb_data_q <= 32'd0;
            mem_wb_rd_q <= 5'd0;
            mem_wb_valid_q <= 1'b0;
            mem_wb_reg_write_q <= 1'b0;
        end else begin
            mem_wb_valid_q <= ex_mem_valid_q;
            mem_wb_reg_write_q <= ex_mem_reg_write_q;
            mem_wb_rd_q <= ex_mem_rd_q;
            mem_wb_data_q <= ex_mem_mem_read_q ? dmem_rdata_i : ex_mem_alu_result_q;

            ex_mem_valid_q <= id_ex_valid_q;
            ex_mem_reg_write_q <= id_ex_reg_write_q;
            ex_mem_mem_read_q <= id_ex_mem_read_q;
            ex_mem_mem_write_q <= id_ex_mem_write_q;
            ex_mem_rd_q <= id_ex_rd_q;
            ex_mem_alu_result_q <= ex_alu_result;
            ex_mem_rs2_data_q <= ex_operand_b_reg;
            ex_mem_branch_taken_q <= ex_branch_taken;
            ex_mem_branch_target_q <= ex_branch_target;

            if (ex_branch_taken) begin
                pc_q <= ex_branch_target;
                if_id_valid_q <= 1'b0;
                if_id_pc_q <= 32'd0;
                if_id_instr_q <= 32'd0;
                id_ex_valid_q <= 1'b0;
                id_ex_reg_write_q <= 1'b0;
                id_ex_mem_read_q <= 1'b0;
                id_ex_mem_write_q <= 1'b0;
                id_ex_branch_q <= 1'b0;
                id_ex_uses_rs1_q <= 1'b0;
                id_ex_uses_rs2_q <= 1'b0;
            end else if (load_use_stall) begin
                pc_q <= pc_q;
                if_id_valid_q <= if_id_valid_q;
                if_id_pc_q <= if_id_pc_q;
                if_id_instr_q <= if_id_instr_q;
                id_ex_valid_q <= 1'b0;
                id_ex_reg_write_q <= 1'b0;
                id_ex_mem_read_q <= 1'b0;
                id_ex_mem_write_q <= 1'b0;
                id_ex_branch_q <= 1'b0;
                id_ex_uses_rs1_q <= 1'b0;
                id_ex_uses_rs2_q <= 1'b0;
            end else begin
                pc_q <= pc_q + 32'd4;
                if_id_pc_q <= pc_q;
                if_id_instr_q <= imem_rdata_i;
                if_id_valid_q <= 1'b1;

                id_ex_pc_q <= if_id_pc_q;
                id_ex_rs1_data_q <= id_rs1_data;
                id_ex_rs2_data_q <= id_rs2_data;
                id_ex_imm_q <= id_imm;
                id_ex_rs1_q <= id_rs1;
                id_ex_rs2_q <= id_rs2;
                id_ex_rd_q <= id_rd;
                id_ex_alu_op_q <= id_alu_op;
                id_ex_valid_q <= if_id_valid_q;
                id_ex_reg_write_q <= id_reg_write;
                id_ex_mem_read_q <= id_mem_read;
                id_ex_mem_write_q <= id_mem_write;
                id_ex_branch_q <= id_branch;
                id_ex_alu_src_imm_q <= id_alu_src_imm;
                id_ex_uses_rs1_q <= id_uses_rs1;
                id_ex_uses_rs2_q <= id_uses_rs2;
            end
        end
    end

`ifdef FORMAL
`include "properties.sv"
`endif
endmodule
