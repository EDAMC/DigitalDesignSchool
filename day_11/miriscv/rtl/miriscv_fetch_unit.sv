/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of miriscv core.
 *
 *
 *******************************************************/

module miriscv_fetch_unit
  import miriscv_pkg::XLEN;
(
  // clock, reset
  input                     clk_i,
  input                     arstn_i,

  input   logic [XLEN-1:0]  boot_addr_i,

  // instruction memory interface
  input                     instr_rvalid_i,
  input         [XLEN-1:0]  instr_rdata_i,
  output  logic             instr_req_o,
  output  logic [XLEN-1:0]  instr_addr_o,

  // core pipeline signals
  input         [XLEN-1:0]  cu_pc_bra_i,
  input                     cu_stall_f_i,
  input                     cu_kill_f_i,
  input                     cu_boot_addr_load_en_i,

  output  logic [XLEN-1:0]  fetched_pc_addr_o,
  output  logic [XLEN-1:0]  fetched_pc_next_addr_o,
  output  logic [31:0]      instr_o,
  output  logic             fetch_rvalid_o
);

  localparam BYTE_ADDR_W = $clog2(XLEN/8);
  
    
  logic [15:0]     instr_rdata_s;
  logic            misaligned_access;

  logic [XLEN-1:0] pc_reg;
  logic [XLEN-1:0] pc_next;
  logic [XLEN-1:0] pc_plus_inc;
  logic            fetch_en;
  logic            compr_instr;
  
  assign fetch_en = fetch_rvalid_o | cu_kill_f_i;

  always_ff @(posedge clk_i or negedge arstn_i) begin
    if ( ~arstn_i ) begin
      pc_reg <= {XLEN{1'b0}}; // Reset value here
    end
    else if ( cu_boot_addr_load_en_i ) begin
      pc_reg <= boot_addr_i;
    end
    else if ( fetch_en ) begin
      pc_reg <= pc_next;
    end
  end

  assign pc_plus_inc  = pc_reg + 'd4;
  assign pc_next      = ( cu_kill_f_i ) ? cu_pc_bra_i : pc_plus_inc;

  


  assign instr_req_o  = ~cu_boot_addr_load_en_i & ~cu_stall_f_i & ~instr_rvalid_i & ~cu_kill_f_i;
  assign instr_addr_o = pc_reg;


  assign fetched_pc_addr_o       = pc_reg;
  assign fetched_pc_next_addr_o  = pc_plus_inc; 
  assign instr_o                 = instr_rdata_i;
  assign fetch_rvalid_o          = instr_rvalid_i & ~cu_kill_f_i & ~cu_stall_f_i;


  

endmodule
