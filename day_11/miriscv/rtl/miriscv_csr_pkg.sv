/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of  miriscv core.
 *
 *
 *******************************************************/

package  miriscv_csr_pkg;

  parameter MXLEN                = 32;

  parameter CSRRW_OP             = 2'd0;
  parameter CSRRS_OP             = 2'd1;
  parameter CSRRC_OP             = 2'd2;

  parameter CSR_MVENDORID_BANK          = 25'd0;
  parameter CSR_MVENDORID_OFFSET        = 7'd0;
  parameter CSR_MARCHID                 = '0;
  parameter CSR_MIMPID                  = '0;
  parameter CSR_MSTATUS_RESET_VAL       = 'h1880;
  parameter CSR_MTVEC_BASE_RESET_VAL    = '0;
  parameter CSR_MSTATUS_MPP_DEFAULT_VAL = 2'b11;
  parameter CSR_MTVEC_MODE_DEFAULT_VAL  = 2'b01;
  parameter CSR_MISA_MXL_DEFAULT_VAL    = 2'b01;

  // interrupt codes
  parameter INTERRUPT_MACHINE_SW    = 'd3;
  parameter INTERRUPT_MACHINE_TIMER = 'd7;
  parameter INTERRUPT_MACHINE_EXT   = 'd11;

  // exception codes
  parameter EXCEPTION_INSTR_ADDR_MISALIGNED = 'd0;
  parameter EXCEPTION_INSTR_ACCESS_FAULT    = 'd1;
  parameter EXCEPTION_ILLEGAL_INSTR         = 'd2;
  parameter EXCEPTION_BREAKPOINT            = 'd3;
  parameter EXCEPTION_LOAD_ADDR_MISALIGNED  = 'd4;
  parameter EXCEPTION_LOAD_ACCESS_FAULT     = 'd5;
  parameter EXCEPTION_STORE_ADDR_MISALIGNED = 'd6;
  parameter EXCEPTION_STORE_ACCESS_FAULT    = 'd7;
  parameter EXCEPTION_ECALL_M_MODE          = 'd11;
  parameter EXCEPTION_INSTR_PAGE_FAULT      = 'd12;
  parameter EXCEPTION_LOAD_PAGE_FAULT       = 'd13;
  parameter EXCEPTION_STORE_PAGE_FAULT      = 'd15;

endpackage :  miriscv_csr_pkg