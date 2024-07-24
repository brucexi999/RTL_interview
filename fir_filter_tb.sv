module fir_filter_tb;
    parameter NUM_TABS =3;
    parameter TAB_WIDTH = 3;
    parameter DATA_IN_WIDTH = 8;
    parameter DATA_OUT_WIDTH = TAB_WIDTH + DATA_IN_WIDTH + 8;

    logic clk;
    logic rst_n;
    logic clk_en;
    logic [DATA_IN_WIDTH-1:0] data_in;
    logic [DATA_OUT_WIDTH-1:0] data_out;

    fir_filter DUT (.*);

    initial begin
        rst_n = 0; #25;
        rst_n  = 1;
    end

    initial begin
        clk = 0; #5;
        forever begin
            clk = 1; #5;
            clk = 0; #5;
        end
    end

    initial begin
        clk_en = 1;
        #25;
        data_in = 'h01;
        #10;
        data_in = 'h01;
        #10;
        data_in = 0;
        #200;
        $stop;
    end
    
endmodule