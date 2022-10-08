module top
# (
    parameter debounce_depth             = 8,
              num_strobe_width           = 23,
              seven_segment_strobe_width = 10
)
(
    input        clk,
    input        reset_n,
    
    input  [3:0] key_sw,
    output [3:0] led,

    output [7:0] abcdefgh,
    output [3:0] digit,

    output       buzzer,

    output       hsync,
    output       vsync,
    output [2:0] rgb
);

    assign buzzer = 1'b0;
    assign hsync  = 1'b1;
    assign vsync  = 1'b1;
    assign rgb    = 3'b0;
    assign led    = 4'b0;
    
    //------------------------------------------------------------------------

    wire reset = ~ reset_n;

    //------------------------------------------------------------------------

    wire [3:0] key_db;

    sync_and_debounce # (.w (4), .depth (debounce_depth))
        i_sync_and_debounce_key
            (clk, reset, ~ key_sw, key_db);

    wire [3:0] sw_db = key_db;

    //------------------------------------------------------------------------

    wire num_strobe;

    wire num_strobe0;
    wire num_strobe1;
    wire num_strobe2;
    wire num_strobe3;

    strobe_gen # (.w (num_strobe_width)) i_num_strobe
        (clk, reset, num_strobe);

    assign num_strobe0 = num_strobe & key_sw[0];
    assign num_strobe1 = num_strobe & key_sw[1];
    assign num_strobe2 = num_strobe & key_sw[2];
    assign num_strobe3 = num_strobe & key_sw[3];

    //------------------------------------------------------------------------

    wire [3:0] num_count0;
    wire [3:0] num_count1;
    wire [3:0] num_count2;
    wire [3:0] num_count3;

    counter # (4) i_num_counter0
    (
        .clk   ( clk                ),
        .reset ( reset              ),
        .en    ( num_strobe0        ),
        .cnt   ( num_count0         )
    );

    counter # (4) i_num_counter1
    (
        .clk   ( clk                ),
        .reset ( reset              ),
        .en    ( num_strobe1        ),
        .cnt   ( num_count1         )
    );

    counter # (4) i_num_counter2
    (
        .clk   ( clk                ),
        .reset ( reset              ),
        .en    ( num_strobe2        ),
        .cnt   ( num_count2         )
    );

    counter # (4) i_num_counter3
    (
        .clk   ( clk                ),
        .reset ( reset              ),
        .en    ( num_strobe3        ),
        .cnt   ( num_count3         )
    );

    //------------------------------------------------------------------------

    wire [15:0] number_to_display =
    {
        num_count3,
        num_count2,
        num_count1,
        num_count0
    };

    //------------------------------------------------------------------------

    wire seven_segment_strobe;

    strobe_gen # (.w (seven_segment_strobe_width))
        i_seven_segment_strobe
            (clk, reset, seven_segment_strobe);

    seven_segment #(.w (16)) i_seven_segment
    (
        .clk     ( clk                  ),
        .reset   ( reset                ),
        .en      ( seven_segment_strobe ),
        .num     ( number_to_display    ),
        .dots    ( sw_db                ),
        .abcdefg ( abcdefgh [7:1]       ),
        .dot     ( abcdefgh [0]         ),
        .anodes  ( digit                )
    );

endmodule
