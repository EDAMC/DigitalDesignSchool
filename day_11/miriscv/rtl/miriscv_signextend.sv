/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of miriscv core.
 *
 *
 *******************************************************/

module miriscv_signextend
 #(parameter IN_WIDTH  = 12,
   parameter OUT_WIDTH = 32)
  (
  input  [IN_WIDTH-1:0]  data_i,
  output [OUT_WIDTH-1:0] data_o
  );

  assign data_o = {{(OUT_WIDTH - IN_WIDTH){data_i[IN_WIDTH-1]}}, data_i};

endmodule