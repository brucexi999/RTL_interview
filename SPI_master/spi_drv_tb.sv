module spi_drv_tb;
    parameter integer SPI_MAXLEN = 8;
    logic clk;
    logic sresetn;
    logic start_cmd;
    logic spi_drv_rdy;
    logic [$clog2(SPI_MAXLEN):0]   n_clks;
    logic [SPI_MAXLEN-1:0]         tx_data;
    logic [SPI_MAXLEN-1:0]         rx_miso;
    logic SCLK;
    logic MOSI;
    logic MISO;
    logic SS_N;

    spi_drv #(4, 8) dut  (.*);
    
    initial begin
        sresetn = 0; # 50;
        sresetn = 1;
    end

    initial begin
        clk = 0; #5;
        forever begin
            clk = 1; #5;
            clk = 0; #5;
        end
    end
    
    initial begin
        #50;
        start_cmd = 1;
        tx_data = 'hab;
        n_clks = 8;
        #20;
        start_cmd = 0;
        #2000;
        $stop;
    end

    initial MISO = 0;
    always@(negedge SCLK) begin
        MISO <= $random & 1;
    end
endmodule