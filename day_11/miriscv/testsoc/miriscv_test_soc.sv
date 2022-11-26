`timescale 1ns / 1ps

module miriscv_test_soc
import miriscv_pkg::XLEN;
import miriscv_pkg::ILEN;
(
  input   logic               clk_i,
  input   logic               arstn_i,
  
  input   logic [XLEN-1:0]    boot_addr_i,

  input   logic               uart_rx_i,
  output  logic               uart_tx_o
    );

  // instruction memory interface
  logic               instr_rvalid;
  logic [XLEN-1:0]    instr_rdata;
  logic               instr_req;
  logic [XLEN-1:0]    instr_addr;

  // data memory interface
  logic               core_data_rvalid;
  logic [XLEN-1:0]    core_data_rdata;
  logic               core_data_req;
  logic               core_data_we;
  logic [XLEN/8-1:0]  core_data_be;
  logic [XLEN-1:0]    core_data_addr;
  logic [XLEN-1:0]    core_data_wdata;

  logic               dmem_data_rvalid;
  logic [XLEN-1:0]    dmem_data_rdata;
  logic               dmem_data_req;
  logic               dmem_data_we;
  logic [XLEN/8-1:0]  dmem_data_be;
  logic [XLEN-1:0]    dmem_data_addr;
  logic [XLEN-1:0]    dmem_data_wdata;

  logic               uart_psel;
  logic               uart_penable;
  logic               uart_pwrite;
  logic [XLEN-1:0]    uart_paddr;
  logic [XLEN-1:0]    uart_pwdata;
  logic [XLEN-1:0]    uart_prdata;
  logic               uart_pready;

  logic               timer_psel;
  logic               timer_penable;
  logic               timer_pwrite;
  logic [XLEN-1:0]    timer_paddr;
  logic [XLEN-1:0]    timer_pwdata;
  logic [XLEN-1:0]    timer_prdata;
  logic               timer_pready;

  assign dmem_data_req   = (core_data_addr[31] != 'b1) ? core_data_req : 'b0;
  assign dmem_data_we    = core_data_we;
  assign dmem_data_be    = core_data_be;
  assign dmem_data_addr  = core_data_addr;
  assign dmem_data_wdata = core_data_wdata;

  assign uart_psel       = ((core_data_addr[31] == 'b1) && (core_data_addr[12] != 'b1)) ? 1'b1 : 'b0;
  assign uart_penable    = uart_psel;
  assign uart_pwrite     = core_data_we;
  assign uart_paddr      = core_data_addr;
  assign uart_pwdata     = core_data_wdata;

  assign timer_psel       = ((core_data_addr[31] == 'b1) && (core_data_addr[12] == 'b1)) ? 1'b1 : 'b0;
  assign timer_penable    = timer_psel;
  assign timer_pwrite     = core_data_we;
  assign timer_paddr      = core_data_addr;
  assign timer_pwdata     = core_data_wdata;

  assign core_data_rdata = (core_data_addr[31] == 'b1) ? (core_data_addr[12] == 'b1) ? timer_prdata : uart_prdata : dmem_data_rdata;
  

always@(posedge clk_i) begin
  if(!arstn_i) begin
    core_data_rvalid <= 'b0;
  end else begin
    core_data_rvalid <= core_data_req;
  end
end  

miriscv_core 
#(
  .RVFI               (1'b0)
)
core
(
  .clk_i          ( clk_i        ),
  .arstn_i        ( arstn_i      ),
  
  // instruction memory interface
  .instr_rvalid_i ( instr_rvalid ),
  .instr_rdata_i  ( instr_rdata  ),
  .instr_req_o    ( instr_req    ),
  .instr_addr_o   ( instr_addr   ),

  // data memory interface
  .data_rvalid_i  ( core_data_rvalid  ),
  .data_rdata_i   ( core_data_rdata   ),
  .data_req_o     ( core_data_req     ),
  .data_we_o      ( core_data_we      ),
  .data_be_o      ( core_data_be      ),
  .data_addr_o    ( core_data_addr    ),
  .data_wdata_o   ( core_data_wdata   ),

  
  .boot_addr_i    ( boot_addr_i  )
);

miriscv_ram 
#(
  .RAM_SIZE      (65536),
  .IRAM_INIT_FILE ("testsoc_text.dat"),
  .DRAM_INIT_FILE ("testsoc_data.dat")
)
ram
(
  .clk_i          ( clk_i        ),
  .arstn_i        ( arstn_i      ),
  
  // instruction memory interface
  .instr_rvalid_o ( instr_rvalid ),
  .instr_rdata_o  ( instr_rdata  ),
  .instr_req_i    ( instr_req    ),
  .instr_addr_i   ( instr_addr   ),

  // data memory interface
  .data_rvalid_o  ( dmem_data_rvalid  ),
  .data_rdata_o   ( dmem_data_rdata   ),
  .data_req_i     ( dmem_data_req     ),
  .data_we_i      ( dmem_data_we      ),
  .data_be_i      ( dmem_data_be      ),
  .data_addr_i    ( dmem_data_addr    ),
  .data_wdata_i   ( dmem_data_wdata   )
);

apb_uart apb_uart_i (
  .CLK      ( clk_i           ),
  .RSTN     ( arstn_i         ),

  .PSEL     ( uart_psel       ),
  .PENABLE  ( uart_penable    ),
  .PWRITE   ( uart_pwrite     ),
  .PADDR    ( uart_paddr[4:2] ),
  .PWDATA   ( uart_pwdata     ),
  .PRDATA   ( uart_prdata     ),
  .PREADY   ( uart_pready     ),

  .DCDN     ( 1'b1        ),       //DCD input
  .RIN      ( 1'b1        ),       //RI input
  .SIN      ( uart_rx_i   ),
  .SOUT     ( uart_tx_o   )
  );

apb_timer apb_timer_i
  (
    .HCLK       ( clk_i           ),
    .HRESETn    ( arstn_i         ),

    .PADDR      ( timer_paddr[11:0]),
    .PWDATA     ( timer_pwdata     ),
    .PWRITE     ( timer_pwrite     ),
    .PSEL       ( timer_psel       ),
    .PENABLE    ( timer_penable    ),
    .PRDATA     ( timer_prdata     ),
    .PREADY     ( timer_pready     )
  );

endmodule



