
module top
# (
    parameter clk_mhz = 50
)
(
    input               clk,
    input               reset_n,

    input        [ 3:0] key_sw,
    output       [ 3:0] led,

    output logic [ 7:0] abcdefgh,
    output       [ 3:0] digit,

    output              buzzer,

    output              hsync,
    output              vsync,
    output       [ 2:0] rgb,

    inout        [13:0] gpio
);

    wire   reset  = ~ reset_n;
    assign led    = 4'b0;
    assign buzzer = ~ reset;
    assign hsync  = 1'b0;
    assign vsync  = 1'b0;
    assign rgb    = '0;

    //------------------------------------------------------------------------
    //
    //  The microphone receiver
    //
    //------------------------------------------------------------------------

    wire [15:0] value;

    digilent_pmod_mic3_spi_receiver i_microphone
    (
        .clk   ( clk       ),
        .reset ( reset     ),
        .cs    ( gpio  [0] ), 
        .sck   ( gpio  [6] ),
        .sdo   ( gpio  [4] ),
        .value ( value     )
    );

    assign gpio [ 8] = 1'b0;  // GND
    assign gpio [10] = 1'b1;  // VCC


    logic [15:0] prev_value;
    logic [19:0] counter;
    logic [19:0] distance;

    localparam [15:0] threshold = 16'h1100; // threshold for note. higher than zero for noise filtration

    always_ff @ (posedge clk or posedge reset)
        if (reset)
        begin
            prev_value <= 16'h0;
            counter    <= 20'h0;
            distance   <= 20'h0;
        end
        else
        begin
            prev_value <= value;

            if (  value      >= threshold
                & prev_value < threshold)
            begin
               distance <= counter;
               counter  <= 20'h0;
            end
            else if (counter != ~ 20'h0)  // To prevent overflow
            begin
               counter <= counter + 20'h1;
            end
        end

    
// Задание 1. Заполнить таблицу параметров в соответствии с частотами нот четвертой октавы в Гц.
// Сейчас здесь правильная нота только C(До)=261.63 Гц и A(Ля)=440.00 Гц

    localparam freq_100_C  = 26163,
               freq_100_Cs = 99999,
               freq_100_D  = 99999,
               freq_100_Ds = 99999,
               freq_100_E  = 99999,
               freq_100_F  = 99999,
               freq_100_Fs = 99999,
               freq_100_G  = 99999,
               freq_100_Gs = 99999,
               freq_100_A  = 44000,
               freq_100_As = 99999,
               freq_100_B  = 99999;

    //------------------------------------------------------------------------

    function [19:0] high_distance (input [18:0] freq_100);            // Пересчёт частоты ноты в число тактов 
                                                                      // основной частоты CLK 50MHZ +4% (50MHz/f)*(104/100)
       high_distance = clk_mhz * 1000 * 1000 / freq_100 * 104;
    endfunction

    //------------------------------------------------------------------------

    function [19:0] low_distance (input [18:0] freq_100);             // Пересчёт частоты ноты в число тактов 
                                                                      // основной частоты CLK 50MHZ -4% (50MHz/f)*(96/100)
       low_distance = clk_mhz * 1000 * 1000 / freq_100 * 96;
    endfunction

    //------------------------------------------------------------------------

    function [19:0] check_freq_single_range (input [18:0] freq_100);  // Проверяем входит ли число посчитанных тактов distance 
                                                                      // в диапазон тактов, который вычисляли выше

       check_freq_single_range =    distance > low_distance  (freq_100)
                                  & distance < high_distance (freq_100);
    endfunction

    //------------------------------------------------------------------------

    function [19:0] check_freq (input [18:0] freq_100);               // Проверяем ноту на следующие две верхних октавы, 
                                                                      // так как частота каждой октавы отличается ровно в 2 раза
       check_freq =   check_freq_single_range (freq_100 * 4)
                    | check_freq_single_range (freq_100 * 2)
                    | check_freq_single_range (freq_100);

    endfunction

    //------------------------------------------------------------------------

    wire check_C  = check_freq (freq_100_C );
    wire check_Cs = check_freq (freq_100_Cs);
    wire check_D  = check_freq (freq_100_D );
    wire check_Ds = check_freq (freq_100_Ds);
    wire check_E  = check_freq (freq_100_E );
    wire check_F  = check_freq (freq_100_F );
    wire check_Fs = check_freq (freq_100_Fs);
    wire check_G  = check_freq (freq_100_G );
    wire check_Gs = check_freq (freq_100_Gs);
    wire check_A  = check_freq (freq_100_A );
    wire check_As = check_freq (freq_100_As);
    wire check_B  = check_freq (freq_100_B );

    //------------------------------------------------------------------------

    localparam w_note = 12;

    wire [w_note - 1:0] note = { check_C  , check_Cs , check_D  , check_Ds ,
                                 check_E  , check_F  , check_Fs , check_G  ,
                                 check_Gs , check_A  , check_As , check_B  };

    localparam [w_note - 1:0] no_note = 12'b0,

                              C  = 12'b1000_0000_0000,
                              Cs = 12'b0100_0000_0000,
                              D  = 12'b0010_0000_0000,
                              Ds = 12'b0001_0000_0000,
                              E  = 12'b0000_1000_0000,
                              F  = 12'b0000_0100_0000,
                              Fs = 12'b0000_0010_0000,
                              G  = 12'b0000_0001_0000,
                              Gs = 12'b0000_0000_1000,
                              A  = 12'b0000_0000_0100,
                              As = 12'b0000_0000_0010,
                              B  = 12'b0000_0000_0001;

    localparam [w_note - 1:0] Df = Cs, Ef = Ds, Gf = Fs, Af = Gs, Bf = As;

    //------------------------------------------------------------------------
    //
    //  Note filtering
    //
    //------------------------------------------------------------------------

    logic  [w_note - 1:0] d_note;  // Delayed note

    always_ff @ (posedge clk or posedge reset)
        if (reset)
            d_note <= no_note;
        else
            d_note <= note;

    logic  [17:0] t_cnt;           // Threshold counter
    logic  [w_note - 1:0] t_note;  // Thresholded note

    always_ff @ (posedge clk or posedge reset)
        if (reset)
            t_cnt <= 0;
        else
            if (note == d_note)
                t_cnt <= t_cnt + 1;
            else
                t_cnt <= 0;

    always_ff @ (posedge clk or posedge reset)
        if (reset)
            t_note <= no_note;
        else
            if (& t_cnt)
                t_note <= d_note;

    //------------------------------------------------------------------------
    //
    //  The output to seven segment display
    //
    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge reset)
        if (reset)
            abcdefgh <= 8'b11111111;
        else
            case (t_note)
            C  : abcdefgh <= 8'b01100011;  // C   // abcdefgh
            Cs : abcdefgh <= 8'b01100010;  // C#
            D  : abcdefgh <= 8'b10000101;  // D   //   --a-- 
            Ds : abcdefgh <= 8'b10000100;  // D#  //  |     |
            E  : abcdefgh <= 8'b01100001;  // E   //  f     b
            F  : abcdefgh <= 8'b01110001;  // F   //  |     |
            Fs : abcdefgh <= 8'b01110000;  // F#  //   --g-- 
            G  : abcdefgh <= 8'b01000011;  // G   //  |     |
            Gs : abcdefgh <= 8'b01000010;  // G#  //  e     c
            A  : abcdefgh <= 8'b00010001;  // A   //  |     |
            As : abcdefgh <= 8'b00010000;  // A#  //   --d--  h
            B  : abcdefgh <= 8'b11000001;  // B
            default : abcdefgh <= 8'b11111111;
            endcase

    assign digit = 4'b1110;
    
//------------------------------------------------------------------------
//   // Задание 2. Вывести на семисегментные индикаторы буквы С О Л Ь, когда микрофон распознает ноту G
//   // Сейчас здесь выводится "0" на все разряды

//    logic [31:0] cnt;
//    
//    always_ff @ (posedge clk or posedge reset)
//      if (reset)
//        cnt <= 32'b0;
//      else
//        cnt <= cnt + 32'b1;
//
//    wire enable = (cnt [17:0] == 18'b0);
//    logic [3:0] shift_reg;
//    
//    always_ff @ (posedge clk or posedge reset)
//      if (reset)
//        shift_reg <= 4'b0001;
//      else if (enable)
//        shift_reg <= { shift_reg [0], shift_reg [3:1] };
//
//    
//    enum bit [7:0] 
//    {
//        o = 8'b00010001,
//        n = 8'b00010001,
//        c = 8'b00010001,
//        b = 8'b00010001,
//        x = 8'b11111111
//    }
//    letter;
//    
//    always_comb
//    begin
//      case (shift_reg)
//      4'b1000: letter = c;
//      4'b0100: letter = o;
//      4'b0010: letter = n;
//      4'b0001: letter = b;
//      default: letter = c;
//      endcase
//    end
//
//    assign abcdefgh = (t_note == C) ? letter: x ;
//    assign digit    = ~ shift_reg;

endmodule
