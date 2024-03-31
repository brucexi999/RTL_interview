module spi_drv_tb;
    parameter integer CLK_DIVIDE = 4;
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

    logic random_bit;
    logic [SPI_MAXLEN-1:0]         mosi_holder;
    logic [SPI_MAXLEN-1:0]         miso_holder;
    logic [$clog2(SPI_MAXLEN):0]   n_clks_holder;
    logic [SPI_MAXLEN-1:0]         tx_data_holder;
    logic random_check_enabled;
    logic [$clog2(SPI_MAXLEN):0] counter;

    spi_drv #(CLK_DIVIDE, SPI_MAXLEN) dut  (.*);
    
    initial begin
        sresetn = 0; #45;
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
        // Start with fixed mode, then random mode
        random_check_enabled = 0; #45;
        start_cmd = 1; #20;
        start_cmd = 0; #500;

        random_check_enabled = 1;
        #20000;
        $stop;
    end

    //----------------Host side-------------------
    always@(posedge clk) begin
        if (!sresetn)
            start_cmd <= 0;
        else if (!start_cmd && random_check_enabled)
            start_cmd <= $random & 1; // If start_cmd is low, assert it at random time
        else if (start_cmd && spi_drv_rdy && random_check_enabled)
            start_cmd <= $random & 1; // If start_cmd and ready are both high, a handshake is observed, either keep or deassert start_cmd
    end

    task generate_tx_data(
        output logic [$clog2(SPI_MAXLEN):0] n_clks,
        output logic [SPI_MAXLEN-1:0] tx_data
    );
        automatic int i = $urandom_range(1, SPI_MAXLEN);
        begin
            n_clks = i;
            tx_data = 0; // Initialize tx_data to 0
            
            // Set bits up to 'i' as random, ensuring that bits beyond 'i' are 0
            for (int j = 0; j < i; j++) begin
                tx_data[j] = $random & 1; // Randomly assign 0 or 1 to each bit up to 'i'
            end
        end
    endtask

    // Whenever a handshake is observed, it means tx_data and n_clks are taken,
    // Gnerate a new random pair, and store to the holders for comparision
    always@(posedge clk) begin
        if (!sresetn) begin
            n_clks <= 8;
            tx_data <= 'hab;
            n_clks_holder <= 8;
            tx_data_holder <= 'hab;
        end
        else if (start_cmd && spi_drv_rdy && random_check_enabled) begin
            generate_tx_data(n_clks, tx_data);
            n_clks_holder <= n_clks;
            tx_data_holder <= tx_data;
        end
    end

    //------------------Slave side---------------------
    // mosi_holder will be compared with tx_data_holder with reference to n_clks_holder
    initial mosi_holder = 0;
    always@(posedge SCLK) begin
        if (random_check_enabled)
            mosi_holder <= {mosi_holder[SPI_MAXLEN-2:0], MOSI};
    end
    
    // miso_holder will be compared with rx_miso
    initial MISO = 0;
    initial miso_holder = 0;
    always@(negedge SCLK or negedge SS_N) begin // negedge SS_N makes sure the first bit is stored in the holder
        if (counter != n_clks_holder && random_check_enabled) begin
            random_bit = $random & 1;
            MISO <= random_bit;
            miso_holder <= {miso_holder[SPI_MAXLEN-2:0], random_bit};
        end
    end
    
    // In fixed mode, MISO simply flips at each negedge SCLK
    always@(negedge SCLK) begin
        if (!random_check_enabled)
            MISO <= ~MISO;
    end

    initial counter = 0;
    always@(posedge SCLK or posedge SS_N) begin
        if (SS_N)
            counter = 0;
        else if (random_check_enabled)
            counter = counter + 1;
    end

    always @(posedge SS_N) begin
        #1;
        if (random_check_enabled) begin
            // Mask relevant bits based on n_clks_holder
            logic [SPI_MAXLEN-1:0] miso_masked;
            logic [SPI_MAXLEN-1:0] rx_miso_masked;
            logic [SPI_MAXLEN-1:0] mosi_masked;
            logic [SPI_MAXLEN-1:0] tx_data_masked;

            miso_masked = miso_holder & ((1'b1 << n_clks_holder) - 1);
            rx_miso_masked = rx_miso & ((1'b1 << n_clks_holder) - 1);

            mosi_masked = mosi_holder & ((1'b1 << n_clks_holder) - 1);
            tx_data_masked = tx_data_holder & ((1'b1 << n_clks_holder) - 1);

            // Perform the comparison using masked values
            assert (mosi_masked == tx_data_masked) else
                $error("MOSI: (%0b) does not match with tx_data: (%0b)", mosi_holder, tx_data_holder);

            assert (miso_masked == rx_miso_masked) else
                $error("MISO: (%0b) does not match with rx_miso: (%0b)", miso_holder, rx_miso);

        end
    end

endmodule