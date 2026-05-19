    logic f_past_valid;
    logic f_past_two_valid;

    initial begin
        f_past_valid = 1'b0;
        f_past_two_valid = 1'b0;
    end

    always_ff @(posedge clk_i) begin
        f_past_two_valid <= f_past_valid;
        f_past_valid <= 1'b1;

        if (f_past_valid && $past(!rst_ni)) begin
            assert (pc_q == 32'd0);
            assert (!if_id_valid_q);
            assert (!id_ex_valid_q);
            assert (!ex_mem_valid_q);
            assert (!mem_wb_valid_q);
        end

        if (rst_ni) begin
            assert (x0_value == 32'd0);
            assert (pc_q[1:0] == 2'b00);
            assert (!(dmem_read_o && dmem_write_o));

            if (wb_valid_o) begin
                assert (wb_rd_o != 5'd0);
            end

            if (id_ex_valid_q && id_ex_uses_rs1_q &&
                ex_mem_valid_q && ex_mem_reg_write_q && !ex_mem_mem_read_q &&
                (ex_mem_rd_q != 5'd0) && (ex_mem_rd_q == id_ex_rs1_q)) begin
                assert (forward_a == 2'd1);
                assert (ex_operand_a == ex_mem_alu_result_q);
            end

            if (id_ex_valid_q && id_ex_uses_rs2_q &&
                ex_mem_valid_q && ex_mem_reg_write_q && !ex_mem_mem_read_q &&
                (ex_mem_rd_q != 5'd0) && (ex_mem_rd_q == id_ex_rs2_q)) begin
                assert (forward_b == 2'd1);
                assert (ex_operand_b_reg == ex_mem_alu_result_q);
            end

            if (id_ex_valid_q && id_ex_uses_rs1_q &&
                !(ex_mem_valid_q && ex_mem_reg_write_q && !ex_mem_mem_read_q &&
                  (ex_mem_rd_q != 5'd0) && (ex_mem_rd_q == id_ex_rs1_q)) &&
                mem_wb_valid_q && mem_wb_reg_write_q &&
                (mem_wb_rd_q != 5'd0) && (mem_wb_rd_q == id_ex_rs1_q)) begin
                assert (forward_a == 2'd2);
                assert (ex_operand_a == mem_wb_data_q);
            end

            if (id_ex_valid_q && id_ex_uses_rs2_q &&
                !(ex_mem_valid_q && ex_mem_reg_write_q && !ex_mem_mem_read_q &&
                  (ex_mem_rd_q != 5'd0) && (ex_mem_rd_q == id_ex_rs2_q)) &&
                mem_wb_valid_q && mem_wb_reg_write_q &&
                (mem_wb_rd_q != 5'd0) && (mem_wb_rd_q == id_ex_rs2_q)) begin
                assert (forward_b == 2'd2);
                assert (ex_operand_b_reg == mem_wb_data_q);
            end

            if (id_ex_valid_q && id_ex_mem_read_q && (id_ex_rd_q != 5'd0) &&
                if_id_valid_q &&
                ((id_uses_rs1 && (id_ex_rd_q == id_rs1)) ||
                 (id_uses_rs2 && (id_ex_rd_q == id_rs2)))) begin
                assert (load_use_stall);
            end

            if (id_ex_valid_q && id_ex_branch_q) begin
                assert (ex_branch_target == id_ex_pc_q + id_ex_imm_q);
                assert (ex_branch_taken == (ex_operand_a == ex_operand_b_reg));
            end
        end

        if (f_past_valid && $past(rst_ni) && rst_ni) begin
            if ($past(ex_branch_taken)) begin
                assert (pc_q == $past(ex_branch_target));
                assert (!if_id_valid_q);
                assert (!id_ex_valid_q);
            end else if ($past(load_use_stall)) begin
                assert (pc_q == $past(pc_q));
                assert (if_id_valid_q == $past(if_id_valid_q));
                assert (if_id_instr_q == $past(if_id_instr_q));
            end else begin
                assert (pc_q == $past(pc_q) + 32'd4);
            end
        end

        if (f_past_two_valid && $past(rst_ni, 2) && $past(rst_ni) && rst_ni) begin
            if ($past(id_ex_valid_q && id_ex_reg_write_q && (id_ex_rd_q != 5'd0), 2)) begin
                assert (wb_valid_o);
                assert (wb_rd_o == $past(id_ex_rd_q, 2));
            end
        end

        cover (rst_ni && wb_valid_o);
        cover (rst_ni && load_use_stall);
        cover (rst_ni && ex_branch_taken);
    end
