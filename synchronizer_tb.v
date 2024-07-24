module synchronizer_tb ();
    reg in, clk, rst;
    wire out;

    synchronizer # (3) dut (in, clk, rst, out);

    initial begin
        clk = 0; #5;
        forever begin
        clk = 1; #5;
        clk = 0; #5;
        end
    end

    initial begin
        rst = 1; #15;

        rst = 0; 
        in = 1;
        #30;
        in = 0;
        #11;
        in = 1;
        #30;

        $stop;
    end
endmodule