// Assumptions keep the formal environment focused on legal RV32I subset
// instructions. The DUT still treats unsupported encodings as bubbles.

function automatic logic is_supported_instr(input logic [31:0] instr);
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    opcode = instr[6:0];
    funct3 = instr[14:12];
    funct7 = instr[31:25];

    unique case (opcode)
        7'b0110011: begin
            is_supported_instr =
                ((funct7 == 7'b0000000) &&
                    ((funct3 == 3'b000) || (funct3 == 3'b111) ||
                     (funct3 == 3'b110) || (funct3 == 3'b100) ||
                     (funct3 == 3'b010))) ||
                ((funct7 == 7'b0100000) && (funct3 == 3'b000));
        end
        7'b0010011: begin
            is_supported_instr =
                (funct3 == 3'b000) || (funct3 == 3'b111) ||
                (funct3 == 3'b110) || (funct3 == 3'b100) ||
                (funct3 == 3'b010);
        end
        7'b0000011: is_supported_instr = (funct3 == 3'b010);
        7'b0100011: is_supported_instr = (funct3 == 3'b010);
        7'b1100011: is_supported_instr = (funct3 == 3'b000);
        default:    is_supported_instr = (instr == 32'h0000_0013);
    endcase
endfunction

always_ff @(posedge clk) begin
    if (rst_n) begin
        assume (is_supported_instr(imem_rdata));
        if (imem_rdata[6:0] == 7'b1100011) begin
            assume (imem_rdata[8] == 1'b0);
        end
    end
end
