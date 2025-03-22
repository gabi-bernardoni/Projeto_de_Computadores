//-----------------------------------------------------------------------
// Design unit: MIPS_monocycle test bench
// Description: Tests MIPS_monocycle 
//-----------------------------------------------------------------------

module MIPS_monocycle_tb;

    localparam logic [31:0] MARS_INSTRUCTION_OFFSET = 32'h00400000;
    localparam logic [31:0] MARS_DATA_OFFSET = 32'h10010000;
    
    logic rst, clk = 0;
    
    logic ce, clk_n;
    logic [3:0] wbe;
    logic [31:0] instruction_address, data_address, instruction, data_in, data_out;
    
    always #20 clk = ~clk; // 25MHz
    
    assign clk_n = ~clk;
    
    initial begin
        rst <= 0;
        #10 rst <= 1;
        #5 rst <= 0;
    end 
    
    MIPS_monocycle_beh #(
        .PC_START_ADDRESS(MARS_INSTRUCTION_OFFSET)
    ) PROCESSOR (
        .clk(clk),
        .rst(rst),       
        
        // Instruction memory interface
        .instruction(instruction),
        .instruction_address(instruction_address),
        
        // Data memory interface
        .data_address(data_address),
        .data_in(data_in),
        .data_out(data_out),
        .ce(ce),
        .wbe(wbe)
    );
    
    // Instruction memory
    Memory #(
        .SIZE(64),  // Memory depth in words
        .ADDR_WIDTH(30),
        .COL_WIDTH(8),
        .NB_COL(4),
        .OFFSET(MARS_INSTRUCTION_OFFSET),
        .image_file_name("/home/gmicro/Reading/systemVerilog/MIPS_Monocycle/sim/BubbleSort_code.txt" )        
    ) INSTRUCTION_MEMORY (
        .clk(clk),        
        .ce(1'b1),
        .wbe(4'b0000),
        .data_in(),
        .data_out(instruction),
        .address(instruction_address[31:2]) // Converts byte address to word address
    );
    
    // Data memory operates in clk falling edges
    // in order to support monocycle execution by MIPS
    Memory #(
        .SIZE(64),  // Memory depth in words
        .ADDR_WIDTH(30),
        .COL_WIDTH(8),
        .NB_COL(4),
        .OFFSET(MARS_DATA_OFFSET),
        .image_file_name("/home/gmicro/Reading/systemVerilog/MIPS_Monocycle/sim/BubbleSort_data.txt" )        
    ) DATA_MEMORY (
        .clk(clk_n),        
        .ce(ce),
        .wbe(wbe),
        .data_in(data_out),
        .data_out(data_in),
        .address(data_address[31:2]) // Converts byte address to word address
    );
    
endmodule
