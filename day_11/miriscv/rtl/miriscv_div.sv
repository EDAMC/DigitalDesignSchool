/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of miriscv core.
 *
 *
 *******************************************************/

module miriscv_div
  import miriscv_pkg::XLEN;
  import miriscv_mdu_pkg::*;
#(
  parameter DIV_IMPLEMENTATION = "GENERIC" // GENERIC or XILINX_7_SERIES
) (
  input                             clk_i,
  input                             arstn_i,
  input                             div_start_i,
  input         [XLEN-1:0]          port_a_i,
  input         [XLEN-1:0]          port_b_i,
  input         [MDU_OP_WIDTH-1:0]  mdu_op_i,
  input                             zero_i,
  input                             kill_i,
  input                             keep_i,
  output  logic [XLEN-1:0]          div_result_o,
  output  logic [XLEN-1:0]          rem_result_o,
  output  logic                     div_stall_req_o
);

  enum logic [2:0] { DIV_IDLE, DIV_FIRST, DIV_COMP, DIV_LAST,
                     DIV_SIGN_CHANGE, DIV_FINISH } d_state, d_next_state;

  logic        [XLEN-1:0]         div_result;
  logic signed [2*XLEN:0]         rem_result;
  logic        [XLEN-1:0]         div_operand_a;
  logic        [XLEN-1:0]         div_operand_b;
  logic                           sign_inv;
  logic        [$clog2(XLEN)-1:0] iter;

  logic  sign_a;
  logic  sign_b;
  logic  div_done;

  assign sign_a = port_a_i[XLEN-1];
  assign sign_b = port_b_i[XLEN-1];

  assign div_done = ( d_state == DIV_FINISH );
  assign div_stall_req_o = ( div_start_i && !div_done );


  /////////////////////////
  // Next state decision //
  /////////////////////////

  always_ff @( posedge clk_i ) begin
    if( ~arstn_i ) begin
      d_state <= DIV_IDLE;
    end
    else begin
      if ( kill_i )
        d_state <= DIV_IDLE;
      else
        d_state <= d_next_state;
    end
  end

  always_comb begin
    case ( d_state )

      DIV_IDLE: begin
        if ( div_start_i )
          d_next_state = DIV_FIRST;
        else
          d_next_state = DIV_IDLE;
      end

      DIV_FIRST: begin
        if ( zero_i )
          d_next_state = DIV_FINISH;
        else
          d_next_state = DIV_COMP;
      end

      DIV_COMP: begin
        if ( iter == 'd1 )
          d_next_state = DIV_LAST;
        else
          d_next_state = DIV_COMP;
      end

      DIV_LAST: begin
        if ( sign_inv ) begin
          d_next_state = DIV_SIGN_CHANGE;
        end
        else begin
          d_next_state = DIV_FINISH;
        end
      end

      DIV_SIGN_CHANGE: begin
        d_next_state = DIV_FINISH;
      end

      DIV_FINISH: begin
        if ( ~keep_i )
          d_next_state = DIV_IDLE;
        else
          d_next_state = DIV_FINISH;
      end

      default: begin
        d_next_state = DIV_IDLE;
      end

    endcase
  end


  ////////////////////////////
  // Division state machine //
  ////////////////////////////

  generate
    if ( DIV_IMPLEMENTATION == "XILINX_7_SERIES" ) begin : dsp_div

      logic        [6:0]  dsp48_opmode;
      logic        [3:0]  dsp48_alumode;
      logic signed [29:0] dsp48_A;
      logic signed [17:0] dsp48_B;
      logic signed [47:0] dsp48_C;
      logic signed [47:0] dsp48_P;

      localparam [1:0] OPMODE_X_AB_CONCAT = 2'b11;
      localparam [1:0] OPMODE_Y_ZERO      = 2'b00;
      localparam [2:0] OPMODE_Z_C         = 3'b011;
      localparam [3:0] ALUMODE_SUM        = 4'b0000;
      localparam [3:0] ALUMODE_INV_Z      = 4'b0001;
      localparam [3:0] ALUMODE_SUB        = 4'b0011;

      mrv1f_dsp48_wrapper #(
        .A_INPUT_SOURCE ( "DIRECT" ),
        .B_INPUT_SOURCE ( "DIRECT" ),
        .USE_MULT       ( "NONE"   ),
        .A_REG          ( 2'b0     ),
        .B_REG          ( 2'b0     ),
        .P_REG          ( 1'b0     )
      ) dsp48 (
        .clk_i   ( clk_i         ),
        .srstn_i ( arstn_i       ),
        .enable  ( 1'b1          ),
        .OPMODE  ( dsp48_opmode  ),
        .ALUMODE ( dsp48_alumode ),
        .A       ( dsp48_A       ),
        .B       ( dsp48_B       ),
        .C       ( dsp48_C       ),
        .P       ( dsp48_P       )
      );

      assign dsp48_opmode[6:4] = OPMODE_Z_C;
      assign dsp48_opmode[3:2] = OPMODE_Y_ZERO;
      assign dsp48_opmode[1:0] = OPMODE_X_AB_CONCAT;

      always_comb begin
        case ( { rem_result[2*XLEN], d_state } ) inside
          { 1'b0, DIV_LAST },
          { 1'b?, DIV_SIGN_CHANGE }: dsp48_A = 'd0;
          default:                   dsp48_A = {'0, div_operand_b[XLEN-1:18]};
        endcase

        case ( { rem_result[2*XLEN], d_state } ) inside
          { 1'b0, DIV_LAST }:        dsp48_B = 'd0;
          { 1'b?, DIV_SIGN_CHANGE }: dsp48_B = 'd1;
          default:                   dsp48_B = div_operand_b[17:0];
        endcase

        case ( d_state )
          DIV_FIRST: dsp48_C = div_operand_a[XLEN-1];
          DIV_COMP:  dsp48_C = rem_result[2*XLEN-1:XLEN-1];
          default:   dsp48_C = rem_result[2*XLEN:XLEN];
        endcase

        case ( { rem_result[2*XLEN], d_state } ) inside
          { 1'b1, DIV_COMP },
          { 1'b1, DIV_LAST }:        dsp48_alumode = ALUMODE_SUM;
          { 1'b?, DIV_SIGN_CHANGE }: dsp48_alumode = ALUMODE_INV_Z;
          default:                   dsp48_alumode = ALUMODE_SUB;
        endcase
      end

      always_ff @( posedge clk_i ) begin
        if ( ~arstn_i ) begin
          div_result    <= {XLEN{1'b0}};
          rem_result    <= {(2*XLEN+1){1'b0}};
          div_operand_a <= {(XLEN){1'b0}};
          div_operand_b <= {(XLEN){1'b0}};
          sign_inv      <= 1'b0;
          iter          <= {($clog2(XLEN)){1'b0}};
        end
        else begin
          rem_result[2*XLEN:XLEN] <= dsp48_P[XLEN:0];

          case ( d_state )

            DIV_IDLE: begin
              case ( mdu_op_i )
                MDU_DIV,
                MDU_REM:  begin
                  div_operand_a <= ( sign_a ) ? ( ~port_a_i + 'd1 ) : ( port_a_i );
                  div_operand_b <= ( sign_b ) ? ( ~port_b_i + 'd1 ) : ( port_b_i );
                end
                MDU_DIVU,
                MDU_REMU: begin
                  div_operand_a <= port_a_i;
                  div_operand_b <= port_b_i;
                end
                default: ;
              endcase

              case ( mdu_op_i )
                MDU_DIV: sign_inv <= ( sign_a ^ sign_b );
                MDU_REM: sign_inv <= sign_a;
                default: sign_inv <= 1'b0;
              endcase
            end

            DIV_FIRST: begin
              iter <= XLEN - 1;
              if ( zero_i ) begin
                div_result <= '1;
                rem_result[2*XLEN-1:XLEN] <= port_a_i;
              end
              else begin
                div_result <= { {(XLEN-1){~sign_inv}}, 1'b1 };
                rem_result[XLEN-1:0] <= { div_operand_a[XLEN-2:0], 1'b0 };
              end
            end

            DIV_COMP,
            DIV_LAST: begin
              iter <= iter - 1;
              rem_result[XLEN-1:0] <= { rem_result[XLEN-2:0], 1'b0 };
              div_result[iter] <= !rem_result[2*XLEN];
            end

            DIV_SIGN_CHANGE: begin
              div_result <= ~div_result + 'd1;
            end

            default: ;
          endcase
        end
      end

    end
    else if ( DIV_IMPLEMENTATION == "GENERIC" ) begin

      always_ff @( posedge clk_i ) begin
        if ( ~arstn_i ) begin
          div_result    <= {XLEN{1'b0}};
          rem_result    <= {(2*XLEN+1){1'b0}};
          div_operand_a <= {(XLEN){1'b0}};
          div_operand_b <= {(XLEN){1'b0}};
          sign_inv      <= 1'b0;
          iter          <= {($clog2(XLEN)){1'b0}};
        end
        else begin
          case ( d_state )

            DIV_IDLE: begin
              case ( mdu_op_i )
                MDU_DIV,
                MDU_REM:  begin
                  div_operand_a <= ( sign_a ) ? ( ~port_a_i + 'd1 ) : ( port_a_i );
                  div_operand_b <= ( sign_b ) ? ( ~port_b_i + 'd1 ) : ( port_b_i );
                end
                MDU_DIVU,
                MDU_REMU: begin
                  div_operand_a <= port_a_i;
                  div_operand_b <= port_b_i;
                end
                default: ;
              endcase

              case ( mdu_op_i )
                MDU_DIV: sign_inv <= ( sign_a ^ sign_b );
                MDU_REM: sign_inv <= sign_a;
                default: sign_inv <= 1'b0;
              endcase
            end

            DIV_FIRST: begin
              iter <= XLEN - 'd1;
              if ( zero_i ) begin
                div_result <= '1;
                rem_result[2*XLEN-1:XLEN] <= port_a_i;
              end
              else begin
                div_result <= { {(XLEN-1){~sign_inv}}, 1'b1 };
                rem_result[2*XLEN:XLEN] <= div_operand_a[XLEN-1] - div_operand_b[XLEN-1:0];
                rem_result[XLEN-1:0] <= { div_operand_a[XLEN-2:0], 1'b0 };
              end
            end

            DIV_COMP: begin
              iter <= iter - 'd1;
              div_result[iter] <= !rem_result[2*XLEN];
              rem_result[XLEN-1:0] <= { rem_result[XLEN-2:0], 1'b0 };
              if ( rem_result[2*XLEN] ) begin
                rem_result[2*XLEN:XLEN] <= rem_result[2*XLEN-1:XLEN-1] + div_operand_b[XLEN-1:0];
              end
              else begin
                rem_result[2*XLEN:XLEN] <= rem_result[2*XLEN-1:XLEN-1] - div_operand_b[XLEN-1:0];
              end
            end

            DIV_LAST: begin
              div_result[0] <= !rem_result[2*XLEN];
              if ( rem_result[2*XLEN] ) begin
                rem_result[2*XLEN:XLEN] <= rem_result[2*XLEN:XLEN] + div_operand_b[XLEN-1:0];
              end
            end

            DIV_SIGN_CHANGE: begin
              rem_result[2*XLEN:XLEN] <= ~rem_result[2*XLEN:XLEN] + 'd1;
              div_result <= ~div_result + 'd1;
            end

            default: ;
          endcase
        end
      end

    end
  endgenerate

  assign div_result_o = div_result;
  assign rem_result_o = rem_result[2*XLEN-1:XLEN];

  initial begin
    if ( ( DIV_IMPLEMENTATION != "XILINX_7_SERIES" ) &&
         ( DIV_IMPLEMENTATION != "GENERIC" ) ) begin
      $error( "Illegal parameter 'DIV_IMPLEMENTATION' in module 'mrv1f_div': %s", DIV_IMPLEMENTATION );
    end
  end

endmodule
