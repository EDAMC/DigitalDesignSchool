/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of  miriscv core.
 *
 *
 *******************************************************/

package  miriscv_mdu_pkg;

  parameter MDU_OP_WIDTH = 3;

  parameter MDU_MUL    = 'd0; // MUL
  parameter MDU_MULH   = 'd1; // MUL High
  parameter MDU_MULHSU = 'd2; // MUL High (S) (U)
  parameter MDU_MULHU  = 'd3; // MUL High (U)
  parameter MDU_DIV    = 'd4; // DIV
  parameter MDU_DIVU   = 'd5; // DIV (U)
  parameter MDU_REM    = 'd6; // Remainder
  parameter MDU_REMU   = 'd7; // Remainder (U)

endpackage :  miriscv_mdu_pkg