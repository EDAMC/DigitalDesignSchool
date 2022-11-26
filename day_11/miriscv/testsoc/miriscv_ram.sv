`timescale 1ns / 1ps

module miriscv_ram
  #(
    parameter RAM_SIZE = 65536,
    parameter IRAM_INIT_FILE = "testsoc_text.dat",
    parameter DRAM_INIT_FILE = "testsoc_data.dat"
  ) 
  (
    input   logic 	             clk_i,
    input   logic                arstn_i,
  
    // instruction memory interface
    output   logic               instr_rvalid_o,
    output   logic [31:0]        instr_rdata_o,
    input    logic               instr_req_i,
    input    logic [31:0]        instr_addr_i,

    // data memory interface
    output   logic               data_rvalid_o,
    output   logic [31:0]        data_rdata_o,
    input    logic               data_req_i,
    input    logic               data_we_i,
    input    logic [3:0]         data_be_i,
    input    logic [31:0]        data_addr_i,
    input    logic [31:0]        data_wdata_i
    );

   genvar 	     i;

   reg [31:0]         imem [0:RAM_SIZE/4-1];
   reg [31:0]         dmem [0:RAM_SIZE/4-1];
    

   integer         f, addr;
   reg[31:0]           data;
   reg [8*20-1:0]      cmd;
   
  integer iram_index;
  integer dram_index; 
   
  initial begin
    //for (iram_index = 0; iram_index < RAM_SIZE/4-1; iram_index = iram_index + 1)
    //  imem[iram_index] = {32{1'b0}};
    //if(IRAM_INIT_FILE != "")    
      $readmemh(IRAM_INIT_FILE, imem);
  end

  initial begin
    //for (dram_index = 0; dram_index < RAM_SIZE/4-1; dram_index = dram_index + 1)
    //  dmem[dram_index] = {32{1'b0}};
    //if(DRAM_INIT_FILE != "")    
      $readmemh(DRAM_INIT_FILE, dmem);
  end


  always@(posedge clk_i) begin
    instr_rdata_o  <= imem[(instr_addr_i / 4) % RAM_SIZE];
    instr_rvalid_o <= instr_req_i;
  end


  
  
  always@(posedge clk_i) begin
      data_rdata_o  <= dmem[data_addr_i[15:2]];
      data_rvalid_o <= data_req_i;

      if(data_req_i && data_we_i && data_be_i[0])
        dmem [data_addr_i[15:2]] [7:0]   <= data_wdata_i[7:0];
      if(data_req_i && data_we_i && data_be_i[1])
        dmem [data_addr_i[15:2]] [15:8]  <= data_wdata_i[15:8];
      if(data_req_i && data_we_i && data_be_i[2])
        dmem [data_addr_i[15:2]] [23:16] <= data_wdata_i[23:16];
      if(data_req_i && data_we_i && data_be_i[3])
        dmem [data_addr_i[15:2]] [31:24] <= data_wdata_i[31:24];       
  end // always@ (posedge clk_i)
   

endmodule