module formal_harness;
`ifdef FORMAL
    (* gclk *) logic clk;
`else
    logic        clk;
`endif
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

`ifdef FORMAL
    (* anyseq *) logic [31:0] f_imem_rdata;
    (* anyseq *) logic [31:0] f_dmem_rdata;

    assign imem_rdata = f_imem_rdata;
    assign dmem_rdata = f_dmem_rdata;
`endif

`ifdef FORMAL
    initial rst_n = 1'b0;
    always_ff @(posedge clk) begin
        rst_n <= 1'b1;
    end
`else
    initial clk = 1'b0;
    always #5 clk = !clk;

    initial begin
        rst_n = 1'b0;
        #12 rst_n = 1'b1;
    end
`endif

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

`ifdef FORMAL
`include "assumptions.sv"
`endif
endmodule
