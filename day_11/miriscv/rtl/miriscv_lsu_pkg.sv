/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of  miriscv core.
 *
 *
 *******************************************************/

package  miriscv_lsu_pkg;

  parameter MEM_ACCESS_W     = 3;

  parameter MEM_ACCESS_WORD  = 'd0; // sign-extension is needed
  parameter MEM_ACCESS_HALF  = 'd1; // sign-extension is needed
  parameter MEM_ACCESS_BYTE  = 'd2; // sign-extension is needed
  parameter MEM_ACCESS_UHALF = 'd3; // allowed for read only
  parameter MEM_ACCESS_UBYTE = 'd4; // allowed for read only

  parameter MEM_ACCESS_DWORD = 'd5;
  parameter MEM_ACCESS_UWORD = 'd6;

endpackage :  miriscv_lsu_pkg