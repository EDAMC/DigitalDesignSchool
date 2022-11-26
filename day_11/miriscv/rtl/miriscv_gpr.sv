/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of miriscv core.
 *
 *
 *******************************************************/


 module miriscv_gpr
  import miriscv_pkg::XLEN;
  import miriscv_gpr_pkg::*;
  (

  // Clocking
  input                               clk_i,
  input                               arstn_i,

  // Write port
  input                               wr_en_i,
  input         [GPR_ADDR_WIDTH-1:0]  wr_addr_i,
  input         [XLEN-1:0]            wr_data_i,

  // Read port 1
  input         [GPR_ADDR_WIDTH-1:0]  r1_addr_i,
  output logic  [XLEN-1:0]            r1_data_o,

  // Read port 2
  input         [GPR_ADDR_WIDTH-1:0]  r2_addr_i,
  output logic  [XLEN-1:0]            r2_data_o
  );

  localparam    NUM_WORDS  = 2**GPR_ADDR_WIDTH;

  logic [NUM_WORDS-1:0][XLEN-1:0] rf_reg;
  logic [NUM_WORDS-1:0][XLEN-1:0] rf_reg_tmp;
  logic [NUM_WORDS-1:0]           wr_en_dec;

  always_comb
  begin : wr_en_decoder
    for (int i = 0; i < NUM_WORDS; i++) begin
      if (wr_addr_i == i)
        wr_en_dec[i] = wr_en_i;
      else
        wr_en_dec[i] = 1'b0;
    end
  end


  genvar i;
  generate
    for (i = 1; i < NUM_WORDS; i++)
    begin : rf_gen

      always_ff @(posedge clk_i, negedge arstn_i)
      begin : register_write_behavioral
        if (arstn_i==1'b0) begin
          rf_reg_tmp[i] <= 'b0;
        end else begin
          if (wr_en_dec[i])
            rf_reg_tmp[i] <= wr_data_i;
        end
      end

    end

    // R0 is nil
    assign rf_reg[0] = '0;
    assign rf_reg[NUM_WORDS-1:1] = rf_reg_tmp[NUM_WORDS-1:1];

  endgenerate

  assign r1_data_o = rf_reg[r1_addr_i];
  assign r2_data_o = rf_reg[r2_addr_i];



endmodule: miriscv_gpr