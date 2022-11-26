/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of miriscv core.
 *
 *
 *******************************************************/

module miriscv_lsu
  import miriscv_pkg::XLEN;
  import miriscv_lsu_pkg::*;
(
  // clock, reset
  input                             clk_i,
  input                             arstn_i,

  // data memory interface
  input                             data_rvalid_i,
  input         [XLEN-1:0]          data_rdata_i,
  output  logic                     data_req_o,
  output  logic                     data_we_o,
  output  logic [XLEN/8-1:0]        data_be_o,
  output  logic [XLEN-1:0]          data_addr_o,
  output  logic [XLEN-1:0]          data_wdata_o,

  // core pipeline signals
  input                             lsu_req_i,
  input                             lsu_kill_i,
  input                             lsu_keep_i,
  input                             lsu_we_i,
  input         [MEM_ACCESS_W-1:0]  lsu_size_i,
  input         [XLEN-1:0]          lsu_addr_i,
  input         [XLEN-1:0]          lsu_data_i,
  output  logic [XLEN-1:0]          lsu_data_o,

  // control and status signals
  output  logic                     lsu_stall_o
);

  localparam BYTE_ADDR_W = $clog2(XLEN/8);
  
  logic [XLEN/4-1:0] data_be;

  assign data_req_o  = lsu_req_i & ~lsu_kill_i & ~data_rvalid_i;
  assign data_addr_o = (lsu_req_i) ? lsu_addr_i : 'b0;
  assign data_we_o   = lsu_we_i;
  assign data_be_o   = data_be;
  
  assign lsu_stall_o = data_req_o;
  


  
  ///////////
  // Store //
  ///////////

  
  always_comb begin
    case ( lsu_size_i )

      MEM_ACCESS_WORD: begin
        data_be = 'b1111;
      end

      MEM_ACCESS_UHALF,
      MEM_ACCESS_HALF: begin
        data_be = ( 'b0011 << lsu_addr_i[1:0] );
      end

      MEM_ACCESS_UBYTE,
      MEM_ACCESS_BYTE: begin
        data_be = ( 'b0001 << lsu_addr_i[1:0] );
      end

      default: begin
        data_be = {(XLEN/4){1'b0}};
      end

    endcase


    case ( lsu_addr_i[1:0] )
      2'b00:   data_wdata_o = { lsu_data_i[31:0] };
      2'b01:   data_wdata_o = { lsu_data_i[23:0], lsu_data_i[31:24] };
      2'b10:   data_wdata_o = { lsu_data_i[15:0], lsu_data_i[31:16] };
      2'b11:   data_wdata_o = { lsu_data_i[ 7:0], lsu_data_i[31: 8] };
      default: data_wdata_o = {XLEN{1'b0}};
    endcase
  end
   

  //////////
  // Load //
  //////////

  logic [XLEN-1:0] lsu_data;

  always_comb begin
    case ( lsu_size_i )

      MEM_ACCESS_WORD: begin
        case ( lsu_addr_i[1:0] )
          2'b00:   lsu_data_o = data_rdata_i[31:0];
          default: lsu_data_o = {XLEN{1'b0}};
        endcase
      end

      MEM_ACCESS_HALF: begin
        case ( lsu_addr_i[1:0] )
          2'b00:   lsu_data_o = { {(XLEN-16){data_rdata_i[15]}}, data_rdata_i[15: 0] };
          2'b01:   lsu_data_o = { {(XLEN-16){data_rdata_i[23]}}, data_rdata_i[23: 8] };
          2'b10:   lsu_data_o = { {(XLEN-16){data_rdata_i[31]}}, data_rdata_i[31:16] };
          default: lsu_data_o = {XLEN{1'b0}};
        endcase
      end

      MEM_ACCESS_BYTE: begin
        case ( lsu_addr_i[1:0] )
          2'b00:   lsu_data_o = { {(XLEN-8){data_rdata_i[ 7]}}, data_rdata_i[ 7: 0] };
          2'b01:   lsu_data_o = { {(XLEN-8){data_rdata_i[15]}}, data_rdata_i[15: 8] };
          2'b10:   lsu_data_o = { {(XLEN-8){data_rdata_i[23]}}, data_rdata_i[23:16] };
          2'b11:   lsu_data_o = { {(XLEN-8){data_rdata_i[31]}}, data_rdata_i[31:24] };
          default: lsu_data_o = {XLEN{1'b0}};
        endcase
      end

      MEM_ACCESS_UHALF: begin
        case ( lsu_addr_i[1:0] )
          2'b00:   lsu_data_o = { {(XLEN-16){1'b0}}, data_rdata_i[15: 0] };
          2'b01:   lsu_data_o = { {(XLEN-16){1'b0}}, data_rdata_i[23: 8] };
          2'b10:   lsu_data_o = { {(XLEN-16){1'b0}}, data_rdata_i[31:16] };
          default: lsu_data_o = {XLEN{1'b0}};
        endcase
      end

      MEM_ACCESS_UBYTE: begin
        case ( lsu_addr_i[1:0] )
          2'b00:   lsu_data_o = { {(XLEN-8){1'b0}}, data_rdata_i[ 7: 0] };
          2'b01:   lsu_data_o = { {(XLEN-8){1'b0}}, data_rdata_i[15: 8] };
          2'b10:   lsu_data_o = { {(XLEN-8){1'b0}}, data_rdata_i[23:16] };
          2'b11:   lsu_data_o = { {(XLEN-8){1'b0}}, data_rdata_i[31:24] };
          default: lsu_data_o = {XLEN{1'b0}};
        endcase
      end

      default: begin
        lsu_data_o = {XLEN{1'b0}};
      end

    endcase
  end
 

endmodule
