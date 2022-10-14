module digilent_pmod_mic3_spi_receiver
(
    input             clk,
    input             reset,
    output            cs,
    output            sck,
    input             sdo,
    output logic [15:0] value
);

    logic [ 6:0] cnt;
    logic [15:0] shift;

    always_ff @ (posedge clk or posedge reset)
    begin
        if (reset)
            cnt <= 7'b100;
        else
            cnt <= cnt + 7'b1;
    end

    assign sck = ~ cnt [1];
    assign cs  =   cnt [6];

    wire sample_bit = ( cs == 1'b0 && cnt [1:0] == 2'b11 );
    wire value_done = ( cnt [6:0] == 7'b0 );

    always_ff @ (posedge clk or posedge reset)
    begin
        if (reset)
        begin
            shift <= 16'h0000;
            value <= 16'h0000;
        end
        else if (sample_bit)
        begin
            shift <= (shift << 1) | sdo;
        end
        else if (value_done)
        begin
            value <= shift;
        end
    end

endmodule
