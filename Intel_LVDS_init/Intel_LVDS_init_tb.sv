module Intel_LVDS_init_tb;
    logic clk;
    logic srstn;
    logic interface_rst;
    logic rx_locked;
    logic rx_dpa_locked;
    logic pll_areset;
    logic rx_reset;
    logic rx_fifo_reset;
    logic rx_cda_reset;

    Intel_LVDS_init dut (.*);

    initial begin
        srstn = 0; #25;
        srstn = 1; #400;
        srstn = 0; #10;
        srstn = 1;
    end

    initial begin
        clk = 0; #5;
        forever begin
            clk = 1; #5;
            clk = 0; #5;
        end
    end

    initial begin
        interface_rst = 0;
        rx_locked = 0;
        rx_dpa_locked = 0;
        #55;
        rx_locked = 1;
        #50;
        rx_locked = 0;
        rx_dpa_locked = 1;
        #10;
        rx_dpa_locked = 0;
        #100;

        interface_rst = 1;
        #50;
        interface_rst = 0;
        rx_locked = 1;
        #50;
        rx_locked = 0;
        rx_dpa_locked = 1;
        #10;
        rx_dpa_locked = 0;
        #200;

        interface_rst = 0;
        rx_locked = 0;
        rx_dpa_locked = 0;
        #50;
        rx_locked = 1;
        #50;
        rx_locked = 0;
        rx_dpa_locked = 1;
        #10;
        rx_dpa_locked = 0;
        #100;
        $stop;
    end
endmodule