/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of  miriscv core.
 *
 *
 *******************************************************/

package  miriscv_intsr_decomp_pkg;
  // Quadrant 00
  parameter CADDI4SPN = 3'b000;
  parameter CLW       = 3'b010;
  parameter CSW       = 3'b110;

  // Quadrant 01
  parameter CNOP_ADDI     = 3'b000;
  parameter CJAL          = 3'b001;
  parameter CLI           = 3'b010;
  parameter CADDI16SP_LUI = 3'b011;
  parameter CALOPS       = 3'b100;
  // Subgroup of ops with common func3 in compressed instraction
    parameter CSRLI       = 2'b00;
    parameter CSRAI       = 2'b01;
    parameter CANDI       = 2'b10;
    parameter CSUB        = 5'b01100;
    parameter CXOR        = 5'b01101;
    parameter COR         = 5'b01110;
    parameter CAND        = 5'b01111;
  parameter CJ            = 3'b101;
  parameter CBEQZ         = 3'b110;
  parameter CBNEZ         = 3'b111;

  // Quadrant 02
  parameter CSLLI = 3'b000;
  parameter CLWSP = 3'b010;
  parameter CETC  = 3'b100;
  parameter CSWSP = 3'b110;
endpackage:  miriscv_intsr_decomp_pkg
