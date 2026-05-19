module tb;
    logic        clk;
    logic        rst_n;
    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;
    logic        dmem_read;
    logic        dmem_write;
    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic [31:0] dmem_rdata;
    logic [31:0] pc;
    logic        wb_valid;
    logic [4:0]  wb_rd;
    logic [31:0] wb_data;

    logic [31:0] imem [0:31];
    logic [31:0] dmem [0:31];

    function automatic logic [31:0] r_type(
        input logic [6:0] funct7,
        input logic [4:0] rs2,
        input logic [4:0] rs1,
        input logic [2:0] funct3,
        input logic [4:0] rd
    );
        r_type = {funct7, rs2, rs1, funct3, rd, 7'b0110011};
    endfunction

    function automatic logic [31:0] i_type(
        input logic [11:0] imm,
        input logic [4:0] rs1,
        input logic [2:0] funct3,
        input logic [4:0] rd,
        input logic [6:0] opcode
    );
        i_type = {imm, rs1, funct3, rd, opcode};
    endfunction

    function automatic logic [31:0] s_type(
        input logic [11:0] imm,
        input logic [4:0] rs2,
        input logic [4:0] rs1,
        input logic [2:0] funct3
    );
        s_type = {imm[11:5], rs2, rs1, funct3, imm[4:0], 7'b0100011};
    endfunction

    function automatic logic [31:0] b_type(
        input logic [12:0] imm,
        input logic [4:0] rs2,
        input logic [4:0] rs1,
        input logic [2:0] funct3
    );
        b_type = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], 7'b1100011};
    endfunction

    core dut (
        .clk_i(clk),
        .rst_ni(rst_n),
        .imem_addr_o(imem_addr),
        .imem_rdata_i(imem_rdata),
        .dmem_read_o(dmem_read),
        .dmem_write_o(dmem_write),
        .dmem_addr_o(dmem_addr),
        .dmem_wdata_o(dmem_wdata),
        .dmem_rdata_i(dmem_rdata),
        .pc_o(pc),
        .wb_valid_o(wb_valid),
        .wb_rd_o(wb_rd),
        .wb_data_o(wb_data)
    );

    assign imem_rdata = imem[imem_addr[6:2]];
    assign dmem_rdata = dmem[dmem_addr[6:2]];

    always_ff @(posedge clk) begin
        if (dmem_write) begin
            dmem[dmem_addr[6:2]] <= dmem_wdata;
        end
    end

    initial begin
        clk = 1'b0;
        forever #5 clk = !clk;
    end

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            imem[i] = 32'h0000_0013;
            dmem[i] = 32'd0;
        end

        imem[0] = i_type(12'd5,  5'd0, 3'b000, 5'd1, 7'b0010011); // addi x1, x0, 5
        imem[1] = i_type(12'd7,  5'd0, 3'b000, 5'd2, 7'b0010011); // addi x2, x0, 7
        imem[2] = r_type(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3);   // add x3, x1, x2
        imem[3] = r_type(7'b0100000, 5'd1, 5'd3, 3'b000, 5'd4);   // sub x4, x3, x1
        imem[4] = s_type(12'd0, 5'd4, 5'd0, 3'b010);              // sw x4, 0(x0)
        imem[5] = i_type(12'd0, 5'd0, 3'b010, 5'd5, 7'b0000011);  // lw x5, 0(x0)
        imem[6] = r_type(7'b0000000, 5'd1, 5'd5, 3'b000, 5'd6);   // add x6, x5, x1
        imem[7] = b_type(13'd8, 5'd3, 5'd6, 3'b000);              // beq x6, x3, +8
        imem[8] = i_type(12'd1, 5'd0, 3'b000, 5'd7, 7'b0010011);  // flushed if branch works
        imem[9] = i_type(12'd9, 5'd0, 3'b000, 5'd8, 7'b0010011);

        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        repeat (40) @(posedge clk);
        $finish;
    end

    initial begin
        $dumpfile("waveforms/pipeline.vcd");
        $dumpvars(0, tb);
    end
endmodule
