module hazard_unit (
    input  logic       id_ex_mem_read_i,
    input  logic [4:0] id_ex_rd_i,
    input  logic [4:0] if_id_rs1_i,
    input  logic [4:0] if_id_rs2_i,
    input  logic       if_id_uses_rs1_i,
    input  logic       if_id_uses_rs2_i,
    output logic       stall_o
);
    always_comb begin
        stall_o = 1'b0;
        if (id_ex_mem_read_i && (id_ex_rd_i != 5'd0)) begin
            stall_o = (if_id_uses_rs1_i && (id_ex_rd_i == if_id_rs1_i)) ||
                      (if_id_uses_rs2_i && (id_ex_rd_i == if_id_rs2_i));
        end
    end
endmodule
