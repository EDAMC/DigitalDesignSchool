/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of miriscv core.
 *
 *
 *******************************************************/

module miriscv_mdu
  import miriscv_pkg::XLEN;
  import miriscv_mdu_pkg::*;
(
  input                             clk_i,
  input                             arstn_i,
  input                             mdu_req_i,        // request for proceeding operation
  input         [XLEN-1:0]          mdu_port_a_i,     // operand A
  input         [XLEN-1:0]          mdu_port_b_i,     // operand B
  input         [MDU_OP_WIDTH-1:0]  mdu_op_i,         // opcode
  input                             mdu_kill_i,       // cancel a current multicycle operation
  input                             mdu_keep_i,       // save the result and prevent repetition of computation
  output  logic [XLEN-1:0]          mdu_result_o,     // computation result
  output  logic                     mdu_stall_req_o   // stall the pipeline during a multicycle operation
);


  ////////////////////////////////////
  // Sign extention for multipliers //
  ////////////////////////////////////

  logic  sign_a;
  logic  sign_b;
  assign sign_a = mdu_port_a_i[XLEN-1];
  assign sign_b = mdu_port_b_i[XLEN-1];

  // used for both MUL and DIV
  logic b_is_zero;
  assign b_is_zero = ~|mdu_port_b_i;

  logic mult_op;

  always_comb begin
    case ( mdu_op_i )
      MDU_MUL,
      MDU_MULH,
      MDU_MULHU,
      MDU_MULHSU:
        mult_op = 1'b1;
      MDU_DIV,
      MDU_REM,
      MDU_DIVU,
      MDU_REMU:
        mult_op = 1'b0;
      default:
        mult_op = 1'b0;
    endcase
  end

  logic signed [XLEN:0]     mul_operand_a;
  logic signed [XLEN:0]     mul_operand_b;
  logic signed [2*XLEN+1:0] mult_result_full;
  logic        [2*XLEN-1:0] mult_result;

  logic msb_a;
  logic msb_b;

  assign mul_operand_a = { msb_a, mdu_port_a_i };
  assign mul_operand_b = { msb_b, mdu_port_b_i };

  always_comb begin
    case ( mdu_op_i )
      MDU_MUL,
      MDU_MULH: begin
        msb_a = sign_a;
        msb_b = sign_b;
      end
      MDU_MULHU: begin
        msb_a = 1'b0;
        msb_b = 1'b0;
      end
      MDU_MULHSU: begin
        msb_a = sign_a;
        msb_b = 1'b0;
      end
      default: begin
        msb_a = 1'b0;
        msb_b = 1'b0;
      end
    endcase
  end

  logic mult_stall;


  ////////////////////
  // Multiplication //
  ////////////////////

  assign mult_stall = 1'b0;

  assign mult_result_full = mul_operand_a * mul_operand_b;
  assign mult_result = mult_result_full[2*XLEN-1:0];


  


  //////////////
  // Division //
  //////////////

  logic        [XLEN-1:0] div_result;
  logic signed [XLEN-1:0] rem_result;
  logic                   div_start;
  logic                   div_stall;

  assign div_start = !mult_op && mdu_req_i;

  logic b_zero_flag;
  always_ff @( posedge clk_i or negedge arstn_i ) begin
    if ( ~arstn_i ) begin
      b_zero_flag <= 1'b0;
    end
    else begin
      b_zero_flag <= b_is_zero;
    end
  end

  miriscv_div #(
    .DIV_IMPLEMENTATION( "GENERIC" )
  ) div_unit (
    .clk_i           ( clk_i        ),
    .arstn_i         ( arstn_i      ),
    .div_start_i     ( div_start    ),
    .port_a_i        ( mdu_port_a_i ),
    .port_b_i        ( mdu_port_b_i ),
    .mdu_op_i        ( mdu_op_i     ),
    .zero_i          ( b_zero_flag  ),
    .kill_i          ( mdu_kill_i   ),
    .keep_i          ( mdu_keep_i   ),
    .div_result_o    ( div_result   ),
    .rem_result_o    ( rem_result   ),
    .div_stall_req_o ( div_stall    )
  );


  assign mdu_stall_req_o = div_stall || mult_stall;

  always_comb begin
    case ( mdu_op_i )
      MDU_MUL:    mdu_result_o = mult_result[XLEN-1:0];
      MDU_MULH,
      MDU_MULHSU,
      MDU_MULHU:  mdu_result_o = mult_result[2*XLEN-1:XLEN];
      MDU_DIV,
      MDU_DIVU:   mdu_result_o = div_result;
      MDU_REM,
      MDU_REMU:   mdu_result_o = rem_result;
      default:    mdu_result_o = {XLEN{1'b0}};
    endcase

  end


  

endmodule
