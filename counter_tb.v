module counter_tb;
    parameter N = 2;
    reg clk;
    reg rst;
    wire [N-1:0] out_up;
    wire [N-1:0] out_down;

    /*counter_up #(N) dut (
        clk,
        rst,
        out_up
    );*/

    counter_down #(N) dut1 (
        clk,
        rst,
        out_down
    );

    initial begin
        clk = 0;
        #5;
        forever begin
            clk = 1;
            #5;
            clk = 0;
            #5;
        end
    end
    initial begin
        rst = 1;
        #25;
        rst = 0;
        #2680;
        //rst = 1;
        //#20;
        //rst = 0;
        //#200;
        $stop;
    end
/*
    initial begin
        $monitor("Time: %t, reset: %b, output: %d", $time, rst, out_up);
        $monitor("Time: %t, reset: %b, output: %d", $time, rst, out_down);
    end
*/

endmodule