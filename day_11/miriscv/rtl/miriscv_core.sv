/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of  miriscv core.
 *
 * Unauthorized copying of this file, via any medium is strictly prohibited.
 * Proprietary and confidential.
 *
 *******************************************************/

module  miriscv_core
  import  miriscv_pkg::XLEN;
  import  miriscv_pkg::ILEN;

  import  miriscv_gpr_pkg::GPR_ADDR_WIDTH;
#(
  parameter bit RVFI               = 1'b0
) (
  input   logic               clk_i,
  input   logic               arstn_i,
  
  input   logic [XLEN-1:0]    boot_addr_i,

  // instruction memory interface
  input   logic               instr_rvalid_i,
  input   logic [XLEN-1:0]    instr_rdata_i,
  output  logic               instr_req_o,
  output  logic [XLEN-1:0]    instr_addr_o,

  // data memory interface
  input   logic               data_rvalid_i,
  input   logic [XLEN-1:0]    data_rdata_i,
  output  logic               data_req_o,
  output  logic               data_we_o,
  output  logic [XLEN/8-1:0]  data_be_o,
  output  logic [XLEN-1:0]    data_addr_o,
  output  logic [XLEN-1:0]    data_wdata_o,

  output  logic               rvfi_valid_o,
  output  logic [63:0]        rvfi_order_o,
  output  logic [31:0]        rvfi_insn_o,
  output  logic               rvfi_trap_o,
  output  logic               rvfi_halt_o,
  output  logic               rvfi_intr_o,
  output  logic [ 1:0]        rvfi_mode_o,
  output  logic [ 1:0]        rvfi_ixl_o,
  output  logic [ 4:0]        rvfi_rs1_addr_o,
  output  logic [ 4:0]        rvfi_rs2_addr_o,
  output  logic [31:0]        rvfi_rs1_rdata_o,
  output  logic [31:0]        rvfi_rs2_rdata_o,
  output  logic [ 4:0]        rvfi_rd_addr_o,
  output  logic [31:0]        rvfi_rd_wdata_o,
  output  logic [31:0]        rvfi_pc_rdata_o,
  output  logic [31:0]        rvfi_pc_wdata_o,
  output  logic [31:0]        rvfi_mem_addr_o,
  output  logic [ 3:0]        rvfi_mem_rmask_o,
  output  logic [ 3:0]        rvfi_mem_wmask_o,
  output  logic [31:0]        rvfi_mem_rdata_o,
  output  logic [31:0]        rvfi_mem_wdata_o

);

  localparam f = 3'd0; // fetch
  localparam d = 3'd1; // decode
  localparam e = 3'd2; // execute
  localparam m = 3'd3; // memory
  localparam w = 3'd4; // writeback

  logic [XLEN-1:0]            current_pc [f:d];
  logic [XLEN-1:0]            next_pc    [f:f];

  logic [ILEN-1:0]            instr [f:d];
  logic                       valid [f:d];


  logic [GPR_ADDR_WIDTH-1:0]  rs1_addr   [d:d];
  logic [GPR_ADDR_WIDTH-1:0]  rs2_addr   [d:d];
  logic [GPR_ADDR_WIDTH-1:0]  wb_rd_addr [d:d];
  logic                       wb_we      [d:d];
  logic [1:0]                 wb_src_sel [d:d];

  logic                       mem_we    [d:d];
  logic [2:0]                 mem_size  [d:d];
  logic                       mem_req   [d:d];

  //logic [1:0]                 csr_op      [d:e];
  //logic [11:0]                csr_addr    [d:e];
  //logic [XLEN-1:0]            csr_imm     [d:d];
  //logic                       csr_src_sel [d:d];
  //logic [XLEN-1:0]            csr_data    [e:e];
  //logic                       csr_req     [d:e];
  //logic                       csr_rs1_null[d:e];

  logic                       cu_stall  [f:d];
  //logic                       cu_flush  [f:d];
  logic                       cu_kill   [f:d];
  logic                       cu_keep   [d:d];


  logic [XLEN-1:0]            rvfi_ex_result [d:w];
  logic [XLEN-1:0]            rvfi_lsu_data  [d:w];
  logic [XLEN-1:0]            rvfi_csr_data  [d:w];

  logic [1:0]                 rvfi_wb_src_sel [d:w];
  logic                       rvfi_wb_we      [d:w];
  logic [GPR_ADDR_WIDTH-1:0]  rvfi_wb_rd_addr [d:w];
  logic [XLEN-1:0]            rvfi_wb_data    [d:w];

  logic [ILEN-1:0]            rvfi_instr         [d:w];
  logic [GPR_ADDR_WIDTH-1:0]  rvfi_rs1_addr      [d:w];
  logic [GPR_ADDR_WIDTH-1:0]  rvfi_rs2_addr      [d:w];
  logic                       rvfi_op1_gpr       [d:w];
  logic                       rvfi_op2_gpr       [d:w];
  logic [XLEN-1:0]            rvfi_rs1_rdata     [d:w];
  logic [XLEN-1:0]            rvfi_rs2_rdata     [d:w];
  logic [XLEN-1:0]            rvfi_current_pc    [d:w];
  logic [XLEN-1:0]            rvfi_next_pc       [d:w];
  logic                       rvfi_valid         [d:w];
  logic                       rvfi_illegal_instr [d:w];
  logic                       rvfi_trap          [d:w];
  logic                       rvfi_intr          [f:w];

  logic                       rvfi_mem_req   [d:w];
  logic                       rvfi_mem_we    [d:w];
  logic [2:0]                 rvfi_mem_size  [d:w];
  logic [XLEN-1:0]            rvfi_mem_addr  [d:w];
  logic [XLEN-1:0]            rvfi_mem_data  [d:w];
  logic [XLEN-1:0]            rvfi_mem_wdata [d:w];
  logic [XLEN-1:0]            rvfi_mem_rdata [d:w];


  // Fetch stage

  logic [XLEN-1:0]  cu_pc_bra;
  logic             cu_boot_addr_load_en;

   miriscv_fetch_stage #(
    .RVFI (RVFI)
  ) fetch (
    .clk_i                        (clk_i                      ),
    .arstn_i                      (arstn_i                    ),
    
    .boot_addr_i                  (boot_addr_i                ),

    // Instruction memory interface
    .instr_rvalid_i               (instr_rvalid_i             ),
    .instr_rdata_i                (instr_rdata_i              ),
    .instr_req_o                  (instr_req_o                ),
    .instr_addr_o                 (instr_addr_o               ),

    // Control Unit
    .cu_pc_bra_i                  (cu_pc_bra                  ),
    .cu_kill_f_i                  (cu_kill[f]                 ),
    .cu_boot_addr_load_en_i       (cu_boot_addr_load_en       ),
    .cu_stall_f_i                 (cu_stall[f]                ),
  

    // To Decode
    .f_instr_o                    (instr[f]                   ),
    .f_current_pc_o               (current_pc[f]              ),
    .f_next_pc_o                  (next_pc[f]                 ),
    .f_valid_o                    (valid[f]                   )
    
  );


  // Decode stage

  logic [XLEN-1:0]            d_ex_op1;
  logic [XLEN-1:0]            d_ex_op2;
  logic [4:0]                 d_ex_alu_op;
  logic [2:0]                 d_ex_mdu_op;
  logic                       d_ex_mdu_req;
  logic                       d_ex_result_sel;

  logic [XLEN-1:0]            d_mem_addr_imm;

  logic [XLEN-1:0]            w_wb_data;

  logic                       d_ebreak;
  logic                       d_ecall;
  logic                       d_mret;
  logic                       d_fence;
  logic                       d_wfi;
  logic                       d_jal;
  logic                       d_jalr;
  logic                       d_load;

  logic [XLEN-1:0]            d_imm_b;
  logic [XLEN-1:0]            d_imm_j;
  logic [XLEN-1:0]            d_imm_i;

  logic                       op1_gpr [d:d];
  logic                       op2_gpr [d:d];

  logic [GPR_ADDR_WIDTH-1:0]  d_dec_rs1;
  logic [GPR_ADDR_WIDTH-1:0]  d_dec_rs2;

  logic                       d_dec_rs1_re;
  logic                       d_dec_rs2_re;

  logic                       dbg_gpr_sel;
  logic                       dbg_gpr_rd_we;
  logic [GPR_ADDR_WIDTH-1:0]  dbg_gpr_rd_addr;
  logic [XLEN-1:0]            dbg_gpr_rd_data;
  logic [GPR_ADDR_WIDTH-1:0]  dbg_gpr_rs1_addr;
  logic [XLEN-1:0]            dbg_gpr_rs1_data;


   miriscv_decode_stage #(
    .RVFI     (RVFI)
  ) decode (
    .clk_i                  (clk_i                  ),
    .arstn_i                (arstn_i                ),

    // From Fetch
    .f_instr_i              (instr[f]               ),
    .f_current_pc_i         (current_pc[f]          ),
    .f_next_pc_i            (next_pc[f]             ),
    .f_valid_i              (valid[f]               ),

    // data memory interface
    .data_rvalid_i          (data_rvalid_i          ),
    .data_rdata_i           (data_rdata_i           ),
    .data_req_o             (data_req_o             ),
    .data_we_o              (data_we_o              ),
    .data_be_o              (data_be_o              ),
    .data_addr_o            (data_addr_o            ),
    .data_wdata_o           (data_wdata_o           ),

    // Decode - RVFI
    .d_rvfi_wb_data_o       (rvfi_wb_data[d]        ),
    .d_rvfi_wb_we_o         (rvfi_wb_we[d]          ),
    .d_rvfi_wb_rd_addr_o    (rvfi_wb_rd_addr[d]     ),

    .d_rvfi_instr_o         (rvfi_instr[d]          ),
    .d_rvfi_rs1_addr_o      (rvfi_rs1_addr[d]       ),
    .d_rvfi_rs2_addr_o      (rvfi_rs2_addr[d]       ),
    .d_rvfi_op1_gpr_o       (rvfi_op1_gpr[d]        ),
    .d_rvfi_op2_gpr_o       (rvfi_op2_gpr[d]        ),
    .d_rvfi_rs1_rdata_o     (rvfi_rs1_rdata[d]      ),
    .d_rvfi_rs2_rdata_o     (rvfi_rs2_rdata[d]      ),
    .d_rvfi_current_pc_o    (rvfi_current_pc[d]     ),
    .d_rvfi_next_pc_o       (rvfi_next_pc[d]        ),
    .d_rvfi_valid_o         (rvfi_valid[d]          ),
    .d_rvfi_trap_o          (rvfi_trap[d]           ),
    .d_rvfi_intr_o          (rvfi_intr[d]           ),

    .d_rvfi_mem_req_o       (rvfi_mem_req[d]        ),
    .d_rvfi_mem_we_o        (rvfi_mem_we[d]         ),
    .d_rvfi_mem_size_o      (rvfi_mem_size[d]       ),
    .d_rvfi_mem_addr_o      (rvfi_mem_addr[d]       ),
    .d_rvfi_mem_wdata_o     (rvfi_mem_wdata[d]      ),
    .d_rvfi_mem_rdata_o     (rvfi_mem_rdata[d]      ),

    // Control Unit
    .cu_pc_bra_o            (cu_pc_bra              ),
    .cu_boot_addr_load_en_o (cu_boot_addr_load_en   ),
    .cu_stall_f_o           (cu_stall[f]            ),
    .cu_kill_f_o            (cu_kill[f]             ),
    .cu_stall_d_o           (cu_stall[d]            ),
    .cu_kill_d_o            (cu_kill[d]             )
  );


  // RVFI related signals
  
  assign rvfi_instr[w]      = rvfi_instr[d];
  assign rvfi_rs1_addr[w]   = rvfi_rs1_addr[d];
  assign rvfi_rs2_addr[w]   = rvfi_rs2_addr[d];
  assign rvfi_op1_gpr[w]    = rvfi_op1_gpr[d];
  assign rvfi_op2_gpr[w]    = rvfi_op2_gpr[d];
  assign rvfi_rs1_rdata[w]  = rvfi_rs1_rdata[d];
  assign rvfi_rs2_rdata[w]  = rvfi_rs2_rdata[d];
  assign rvfi_wb_rd_addr[w] = rvfi_wb_rd_addr[d];
  assign rvfi_wb_we[w]      = rvfi_wb_we[d];
  assign rvfi_wb_data[w]    = rvfi_wb_data[d];
  assign rvfi_mem_we[w]     = rvfi_mem_we[d];
  assign rvfi_mem_req[w]    = rvfi_mem_req[d];
  assign rvfi_mem_size[w]   = rvfi_mem_size[d];
  assign rvfi_mem_addr[w]   = rvfi_mem_addr[d];
  assign rvfi_mem_wdata[w]  = rvfi_mem_wdata[d];
  assign rvfi_mem_rdata[w]  = rvfi_mem_rdata[d];
  assign rvfi_current_pc[w] = rvfi_current_pc[d];
  assign rvfi_next_pc[w]    = rvfi_next_pc[d];
  assign rvfi_valid[w]      = rvfi_valid[d] && !( !cu_kill[d] && cu_stall[d] );
  assign rvfi_intr[w]       = rvfi_intr[d];
  assign rvfi_trap[w]       = rvfi_trap[d];


  if (RVFI) begin
     miriscv_rvfi_controller rvfi(
      .clk_i            (clk_i              ),
      .aresetn_i        (arstn_i            ),
      .w_instr_i        (rvfi_instr[w]      ),
      .w_rs1_addr_i     (rvfi_rs1_addr[w]   ),
      .w_rs2_addr_i     (rvfi_rs2_addr[w]   ),
      .w_op1_gpr_i      (rvfi_op1_gpr[w]    ),
      .w_op2_gpr_i      (rvfi_op2_gpr[w]    ),
      .w_rs1_rdata_i    (rvfi_rs1_rdata[w]  ),
      .w_rs2_rdata_i    (rvfi_rs2_rdata[w]  ),
      .w_wb_rd_addr_i   (rvfi_wb_rd_addr[w] ),
      .w_wb_we_i        (rvfi_wb_we[w]      ),
      .w_wb_data_i      (rvfi_wb_data[w]    ),
      .w_data_we_i      (rvfi_mem_we[w]     ),
      .w_data_req_i     (rvfi_mem_req[w]    ),
      .w_data_size_i    (rvfi_mem_size[w]   ),
      .w_data_addr_i    (rvfi_mem_addr[w]   ),
      .w_data_wdata_i   (rvfi_mem_wdata[w]  ),
      .w_data_rdata_i   (rvfi_mem_rdata[w]  ),
      .w_current_pc_i   (rvfi_current_pc[w] ),
      .w_next_pc_i      (rvfi_next_pc[w]    ),
      .w_valid_i        (rvfi_valid[w]      ),
      .w_intr_i         (rvfi_intr[w]       ),
      .w_trap_i         (rvfi_trap[w]       ),
      .rvfi_valid_o     (rvfi_valid_o       ),
      .rvfi_order_o     (rvfi_order_o       ),
      .rvfi_insn_o      (rvfi_insn_o        ),
      .rvfi_trap_o      (rvfi_trap_o        ),
      .rvfi_halt_o      (rvfi_halt_o        ),
      .rvfi_intr_o      (rvfi_intr_o        ),
      .rvfi_mode_o      (rvfi_mode_o        ),
      .rvfi_ixl_o       (rvfi_ixl_o         ),
      .rvfi_rs1_addr_o  (rvfi_rs1_addr_o    ),
      .rvfi_rs2_addr_o  (rvfi_rs2_addr_o    ),
      .rvfi_rs1_rdata_o (rvfi_rs1_rdata_o   ),
      .rvfi_rs2_rdata_o (rvfi_rs2_rdata_o   ),
      .rvfi_rd_addr_o   (rvfi_rd_addr_o     ),
      .rvfi_rd_wdata_o  (rvfi_rd_wdata_o    ),
      .rvfi_pc_rdata_o  (rvfi_pc_rdata_o    ),
      .rvfi_pc_wdata_o  (rvfi_pc_wdata_o    ),
      .rvfi_mem_addr_o  (rvfi_mem_addr_o    ),
      .rvfi_mem_rmask_o (rvfi_mem_rmask_o   ),
      .rvfi_mem_wmask_o (rvfi_mem_wmask_o   ),
      .rvfi_mem_rdata_o (rvfi_mem_rdata_o   ),
      .rvfi_mem_wdata_o (rvfi_mem_wdata_o   )
    );
  end
  else begin
    assign rvfi_valid_o     = 'd0;
    assign rvfi_order_o     = 'd0;
    assign rvfi_insn_o      = 'd0;
    assign rvfi_trap_o      = 'd0;
    assign rvfi_halt_o      = 'd0;
    assign rvfi_intr_o      = 'd0;
    assign rvfi_mode_o      = 'd0;
    assign rvfi_ixl_o       = 'd0;
    assign rvfi_rs1_addr_o  = 'd0;
    assign rvfi_rs2_addr_o  = 'd0;
    assign rvfi_rs1_rdata_o = 'd0;
    assign rvfi_rs2_rdata_o = 'd0;
    assign rvfi_rd_addr_o   = 'd0;
    assign rvfi_rd_wdata_o  = 'd0;
    assign rvfi_pc_rdata_o  = 'd0;
    assign rvfi_pc_wdata_o  = 'd0;
    assign rvfi_mem_addr_o  = 'd0;
    assign rvfi_mem_rmask_o = 'd0;
    assign rvfi_mem_wmask_o = 'd0;
    assign rvfi_mem_rdata_o = 'd0;
    assign rvfi_mem_wdata_o = 'd0;
  end

endmodule
