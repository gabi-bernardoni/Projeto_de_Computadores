//
// Single-Port BRAM with Byte-wide Write Enable
//   4x9-bit write
//   Read-First mode
//   Single-process description
//   Compact description of the write with a generate-for statement
//   Column width and number of columns easily configurable 
//
// Download: ftp://ftp.xilinx.com/pub/documentation/misc/xstug_examples.zip
// File: HDL_Coding_Techniques/rams/bytewrite_ram_1b.v
//

module Memory #(
    parameter int unsigned SIZE = 1024,
    parameter int unsigned ADDR_WIDTH  = 10,
    parameter int unsigned COL_WIDTH  = 8,
    parameter int unsigned NB_COL = 4,
    parameter string image_file_name,
    parameter logic [ADDR_WIDTH - 1:0] OFFSET    
)(
    input logic clk, 
    input logic [NB_COL - 1:0] wbe,
    input logic ce, 
    input logic [ADDR_WIDTH - 1:0] address, 
    input logic [NB_COL * COL_WIDTH - 1:0] data_in, 
    output logic [NB_COL * COL_WIDTH - 1:0] data_out
);  
    logic [NB_COL * COL_WIDTH - 1:0] memory_array [0:SIZE - 1];
    logic [ADDR_WIDTH - 1:0] array_address;
    
    initial begin
        $display("*** Loading Memory image: %s ***", image_file_name);
        $readmemh(image_file_name, memory_array);
    end
    
    // address refers to words
    // OFFSET refers to bytes
    assign array_address = address - OFFSET/4; // Convert OFFSET to word address 
    
    // Read
    always_ff @(posedge clk) begin 
        if (ce) begin
            data_out <= memory_array[array_address];
        end;
    end

    // Write
    generate
        genvar i;
        
        for (i = 0; i < NB_COL; i = i + 1) begin
            always_ff @(posedge clk) begin  
                if (ce && wbe[i]) begin 
                    memory_array[array_address][(i + 1) * COL_WIDTH - 1:i * COL_WIDTH] <= data_in[(i + 1) * COL_WIDTH - 1:i * COL_WIDTH];
                end 
            end
        end
  endgenerate
    
endmodule