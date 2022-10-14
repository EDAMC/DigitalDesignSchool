module digilent_pmod_mic3_spi_receiver
(
    input             clk,
    input             reset,
    output            cs,
    output            sck,
    input             sdo,
    output logic [15:0] value
);

    logic [ 6:0] cnt; // counter for sck and sc clocks
    logic [15:0] shift; // shift register for spi master

    always_ff @ (posedge clk or posedge reset) // simple counter for main clk 50 MHz
    begin
        if (reset)
            cnt <= 7'b100;
        else
            cnt <= cnt + 7'b1;
    end

    assign sck = ~ cnt [1]; // sck clock for spi 12.5 MHz    which directly controls the conversion and readout processes
    assign cs  =   cnt [6]; // cs  clock for spi 390.625 kHz which initiates a conversion process and data transfer

    wire sample_bit = ( cs == 1'b0 && cnt [1:0] == 2'b11 ); // sample_bit for capture data when cs low
    wire value_done = ( cnt [6:0] == 7'b0 );                // get value from spi, when cs is high

    always_ff @ (posedge clk or posedge reset)
    begin
        if (reset)
        begin
            shift <= 16'h0000;
            value <= 16'h0000;
        end
        else if (sample_bit)
        begin
            shift <= (shift << 1) | sdo; // shift data for one bit left in shift_reg and mask serial data, when sample_bit is high
        end
        else if (value_done)
        begin
            value <= shift;             // get value from shift reg before new transaction starts ( before cs low again)
        end
    end

endmodule
