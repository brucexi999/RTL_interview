module odd_clk_divider_tb;
    parameter N = 5;

    logic clk_in;
    logic rst_n;
    logic clk_out;

    odd_clk_divider #(N) dut (.*);

    initial begin
        rst_n = 0; # 25;
        rst_n = 1;
    end

    initial begin
        clk_in = 0; #5;
        forever begin
            clk_in = 1; #5;
            clk_in = 0; #5;
        end
    end
    initial begin
        #200;
        $stop;
    end
endmodule