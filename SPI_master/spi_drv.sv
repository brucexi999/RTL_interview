// SPI Master Module
//
//  This module is used to implement a SPI master. The host will want to transmit a certain number
// of SCLK pulses. This number will be placed in the n_clks port. It will always be less than or
// equal to SPI_MAXLEN.
//
// SPI bus timing
// --------------
// This SPI clock frequency should be the host clock frequency divided by CLK_DIVIDE. This value is
// guaranteed to be even and >= 4. SCLK should have a 50% duty cycle. The slave will expect to clock
// in data on the rising edge of SCLK; therefore this module should output new MOSI values on SCLK
// falling edges. Similarly, you should latch MISO input bits on the rising edges of SCLK.
//
//  Example timing diagram for n_clks = 4:
//  SCLK        ________/-\_/-\_/-\_/-\______ 
//  MOSI        ======= 3 | 2 | 1 | 0 =======
//  MISO        ======= 3 | 2 | 1 | 0 =======
//  SS_N        ------\_______________/------
//
// Command Interface
// -----------------
// The data to be transmitted on MOSI will be placed on the tx_data port. The first bit of data to
// be transmitted will be bit tx_data[n_clks-1] and the last bit transmitted will be tx_data[0].
//  On completion of the SPI transaction, rx_miso should hold the data clocked in from MISO on each
// positive edge of SCLK. rx_miso[n_clks-1] should hold the first bit and rx_miso[0] will be the last.
//
//  When the host wants to issue a SPI transaction, the host will hold the start_cmd pin high. While
// start_cmd is asserted, the host guarantees that n_clks and tx_data are valid and stable. This
// module acknowledges receipt of the command by issuing a transition on spi_drv_rdy from 1 to 0.
// This module should then being performing the SPI transaction on the SPI lines. This module indicates
// completion of the command by transitioning spi_drv_rdy from 0 to 1. rx_miso must contain valid data
// when this transition happens, and the data must remain stable until the next command starts.
//
// CPOL = 0 (SCLK = 0 when it's idle), CPHA = 0 (data transition at negedge SCLK, data sampling at posedge SCLK) => Mode 0

module spi_drv #(
    parameter integer               CLK_DIVIDE  = 100, // Clock divider to indicate frequency of SCLK
    parameter integer               SPI_MAXLEN  = 32   // Maximum SPI transfer length
) (
    input                           clk,
    input                           sresetn,        // active low reset, synchronous to clk
    
    // Command interface 
    input                           start_cmd,     // Start SPI transfer
    output                          spi_drv_rdy,   // Ready to begin a transfer
    input  [$clog2(SPI_MAXLEN):0]   n_clks,        // Number of bits (SCLK pulses) for the SPI transaction
    input  [SPI_MAXLEN-1:0]         tx_data,       // Data to be transmitted out on MOSI
    output [SPI_MAXLEN-1:0]         rx_miso,       // Data read in from MISO
    
    // SPI pins
    output                          SCLK,          // SPI clock sent to the slave
    output                          MOSI,          // Master out slave in pin (data output to the slave)
    input                           MISO,          // Master in slave out pin (data input from the slave)
    output                          SS_N           // Slave select, will be 0 during a SPI transaction
);

    // Internal logics
    logic sclk_en;
    logic data_counter_up_flag;
    logic sclk_counter_up_flag;
    logic resetn_shift;
    logic load_tx;
    logic ss_n;
    logic ready;
    logic sclk_rising_edge;
    logic sclk_falling_edge;
    logic latch_rx;

    // Internal regsiters
    logic [$clog2(SPI_MAXLEN):0] data_counter_reg;
    logic [SPI_MAXLEN-1:0] write_shift_reg;
    logic [SPI_MAXLEN-1:0] read_shift_reg;
    logic sclk_reg;
    logic [7:0] sclk_counter_reg;
    logic [$clog2(SPI_MAXLEN):0] n_clks_reg;
    logic [SPI_MAXLEN-1:0]         rx_miso_reg;
    
    //----------------------FSM-------------------------
    typedef enum {
        reset_state,
        idle_state,
        load_state,
        transaction_state,
        latch_state
    } state_type;

    state_type current_state, next_state;

    always_ff@(posedge clk) begin
        if (!sresetn)
            current_state <= reset_state;
        else 
            current_state <= next_state;
    end

    always_comb begin
        resetn_shift = 1;
        ss_n = 1;
        ready = 0;
        sclk_en = 0;
        load_tx = 0;
        latch_rx = 0;

        case(current_state)
        reset_state: begin
            resetn_shift = 0;
            if (!sresetn)
                next_state = reset_state;
            else
                next_state = idle_state;
        end

        idle_state: begin
            ready = 1;
            if (start_cmd) begin
                next_state = load_state;
            end
            else
                next_state = idle_state;
        end

        load_state: begin // Load n_clks and tx_data into internal registers
            load_tx = 1;
            next_state = transaction_state;
        end
        
        transaction_state: begin
            ss_n = 0;
            sclk_en = 1;
            if (data_counter_up_flag && !sclk_reg) 
                // We have completed all the transactions as indicated by data_counter_up_flag,
                // wait until sclk_reg goes low then exit this state
                next_state = latch_state;
            else
                next_state = transaction_state;
        end

        latch_state: begin
            ss_n = 0;
            latch_rx = 1;
            resetn_shift = 0;
            next_state = idle_state;
        end

        default: next_state = reset_state;
        endcase
    end

    //-------------------SCLK generator----------------------
    /*
    Whenever sclk_counter_reg reaches (CLK_DIVIDE/2-1), sclk_reg will flip. 
    Hence there will be CLK_DIVIDE cycles of clk within one cycle of sclk_reg, 
    essentially dividing the clock frequency by CLK_DIVIDE.
    */
    always_ff@(posedge clk) begin
        if (!sresetn || !sclk_en)
            sclk_reg <= 0;
        else if (sclk_en && sclk_counter_up_flag)
            sclk_reg <= ~sclk_reg;
    end

    always_ff@(posedge clk) begin
        if (!sresetn || sclk_counter_up_flag)
            sclk_counter_reg <= 0;
        else if (sclk_en)
            sclk_counter_reg <= sclk_counter_reg + 1;
    end

    //Used to indicate the rising and falling edge of SCLK
    always_ff@(posedge clk) begin
        sclk_rising_edge <= 0;
        sclk_falling_edge <= 0;
        if (sclk_en && sclk_counter_up_flag) begin
            if (sclk_reg == 0)
                sclk_rising_edge <= 1;
            else
                sclk_falling_edge <= 1;
        end
    end

    assign sclk_counter_up_flag = (sclk_counter_reg == (CLK_DIVIDE>>1)-1);

    //-------------------Shift registers---------------------
    /*
    read_shift_reg is used to latch the incoming MISO data on every rising edge of SCLK while shifting previous bits to make room for the new one
    (actually delayed by 1 clk cycle, but functionally it's correct)
    write_shift_reg is used to latch tx_data at the start of each transaction, at every falling edge of SCLK, write_shift_reg
    will shift its MSB out as MOSI
    */
    always_ff@(posedge clk) begin
        if (!resetn_shift)
            read_shift_reg <= 0;
        else if (sclk_rising_edge && !data_counter_up_flag)
            read_shift_reg <= {read_shift_reg[SPI_MAXLEN-1:0], MISO};

    end

    always_ff@(posedge clk) begin
        if (!resetn_shift)
            write_shift_reg <= 0;
        else if (load_tx)
            write_shift_reg <= tx_data << (SPI_MAXLEN - n_clks);
        else if (sclk_falling_edge && !data_counter_up_flag)
            write_shift_reg <= {write_shift_reg[SPI_MAXLEN-1:0], 1'b0};
    end

    always_ff@(posedge clk) begin
        if (!sresetn)
            rx_miso_reg <= 0;
        else if (latch_rx)
            rx_miso_reg <= read_shift_reg;
    end

    //-------------------Data counter-----------------------
    // When number of SCLK == n_clks, set the flag to terminate the transaction
    always_ff@(posedge clk) begin
        if (!sresetn)
            n_clks_reg <= 0;
        else if (load_tx)
            n_clks_reg <= n_clks;
    end

    always_ff@(posedge clk) begin
        if (!resetn_shift)
            data_counter_reg <= 0;
        else if (sclk_rising_edge && !data_counter_up_flag)
            data_counter_reg <= data_counter_reg + 1;
    end

    assign data_counter_up_flag = data_counter_reg == n_clks_reg;

    //----------------------Output-----------------------
    assign rx_miso = rx_miso_reg;
    assign SS_N = ss_n;
    assign spi_drv_rdy = ready;
    assign MOSI = write_shift_reg[SPI_MAXLEN-1]; // At negedge SCLK, send out the MSB of write_shift_reg 
    assign SCLK = sclk_reg;

endmodule
