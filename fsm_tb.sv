module fsm_tb();
    reg err, n_o1, o2, o3, o4, i1, i2, i3, i4, clk, n_rst;

    fsm dut (i1, i2, i3, i4, clk, n_rst, err, n_o1, o2, o3, o4);

    initial begin
        clk = 0; #5;
        forever begin
            clk = 1; #5;
            clk = 0; #5;
        end
    end

    initial begin
        i1 = 0;
        i2 = 0;
        i3 = 0;
        i4 = 0;
        n_rst = 0; #15;

        n_rst = 1;
        i1 = 1;
        i2 = 1;
        i3 = 0;
        i4 = 0; #10;

        i1 = 1;
        i2 = 0;
        i3 = 0;
        i4 = 0; #10;

        i1 = 0;
        i2 = 1;
        i3 = 1;
        i4 = 0; #10;

        i1 = 1;
        i2 = 0;
        i3 = 1;
        i4 = 0; #10;

        i1 = 1;
        i2 = 0;
        i3 = 0;
        i4 = 1; #10;

        i1 = 1;
        i2 = 0;
        i3 = 0;
        i4 = 0; #10;

        i1 = 0;
        i2 = 0;
        i3 = 0;
        i4 = 0; #10;

        i1 = 1;
        i2 = 0;
        i3 = 1;
        i4 = 0; #10;

        i1 = 1;
        i2 = 0;
        i3 = 0;
        i4 = 0; #10;

        i1 = 0;
        i2 = 0;
        i3 = 0;
        i4 = 0; #10;

        i1 = 1;
        i2 = 1;
        i3 = 0;
        i4 = 0; #10;

        i1 = 0;
        i2 = 1;
        i3 = 0;
        i4 = 1; #10;

        i1 = 1;
        i2 = 1;
        i3 = 0;
        i4 = 0; #10;
        $stop;
    end
endmodule