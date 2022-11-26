/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of miriscv core.
 *
 *
 *******************************************************/

module miriscv_fetch_stage
  import miriscv_pkg::XLEN;
  import miriscv_pkg::ILEN;
#(
  parameter bit RVFI = 1'b0
) (
  input  logic             clk_i,
  input  logic             arstn_i,

  input  logic [XLEN-1:0]  boot_addr_i,

  // Instruction memory interface
  input  logic             instr_rvalid_i,
  input  logic [XLEN-1:0]  instr_rdata_i,
  output logic             instr_req_o,
  output logic [XLEN-1:0]  instr_addr_o,

  // Control Unit
  input  logic [XLEN-1:0]  cu_pc_bra_i,
  input  logic             cu_kill_f_i,
  input  logic             cu_boot_addr_load_en_i,
  input  logic             cu_stall_f_i,


  // To Decode
  output logic [ILEN-1:0]  f_instr_o,
  output logic [XLEN-1:0]  f_current_pc_o,
  output logic [XLEN-1:0]  f_next_pc_o,
  output logic             f_valid_o
);


  logic [ILEN-1:0] fetch_instr;
  logic [XLEN-1:0] f_current_pc;
  logic [XLEN-1:0] f_next_pc;
  logic            fetch_instr_valid;

  miriscv_fetch_unit fetch_unit (
   .clk_i                   (clk_i          ),
   .arstn_i                 (arstn_i        ),

   .boot_addr_i             (boot_addr_i    ),

   // instruction memory interface
   .instr_rvalid_i          (instr_rvalid_i ),
   .instr_rdata_i           (instr_rdata_i  ),
   .instr_req_o             (instr_req_o    ),
   .instr_addr_o            (instr_addr_o   ),

    // core pipeline signals
    .cu_pc_bra_i            (cu_pc_bra_i            ),
    .cu_stall_f_i           (cu_stall_f_i           ),
    .cu_kill_f_i            (cu_kill_f_i        ),
    .cu_boot_addr_load_en_i (cu_boot_addr_load_en_i ),

    .fetched_pc_addr_o      (f_current_pc      ),
    .fetched_pc_next_addr_o (f_next_pc         ),
    .instr_o                (fetch_instr       ),
    .fetch_rvalid_o         (fetch_instr_valid )
  );

  
  // Pipeline register
  always_ff @(posedge clk_i or negedge arstn_i) begin
    if(~arstn_i) begin
      f_instr_o                 <= { {(ILEN-8){1'b0}}, 8'h13 }; // ADDI x0, x0, 0 - NOP
      f_current_pc_o            <= {XLEN{1'b0}};
      f_next_pc_o               <= {XLEN{1'b0}};
      f_valid_o                 <= 1'b0;
    end

    else if (cu_kill_f_i) begin
      f_instr_o                 <= { {(ILEN-8){1'b0}}, 8'h13 };
      f_current_pc_o            <= {XLEN{1'b0}};
      f_next_pc_o               <= {XLEN{1'b0}};
      f_valid_o                 <= 1'b0;
    end

    else if (~cu_stall_f_i) begin
      f_instr_o                 <= fetch_instr_valid ? fetch_instr : { {(ILEN-8){1'b0}}, 8'h13 }; // put NOP if not valid
      f_current_pc_o            <= f_current_pc;
      f_next_pc_o               <= f_next_pc;
      f_valid_o                 <= fetch_instr_valid;
    end

  end

endmodule