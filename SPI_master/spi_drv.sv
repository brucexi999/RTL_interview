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

    // Internal wires
    wire sclk_en;
    wire data_counter_up_flag;
    wire sclk_counter_up_flag;

    // Internal regsiters
    reg [$clog2(SPI_MAXLEN):0] data_counter_reg;
    reg [SPI_MAXLEN-1:0] shift_reg;
    reg sclk_reg;
    reg [7:0] sclk_counter_reg;
    
    //----------------------FSM-------------------------
    typedef enum {
        reset_state,
        idle_state,
        transaction_state
    } state_type;

    state_type current_state, next_state;

    always_ff@(posedge clk) begin
        if (!sresetn)
            current_state <= reset_state;
            //next_state <= reset_state;
        else 
            current_state <= next_state;
    end

    always_comb begin
        SS_N = 1;
        spi_drv_rdy = 0;
        sclk_en = 0;
        case(current_state)
        reset_state: begin
            if (!sresetn)
                next_state = reset_state;
            else
                next_state = idle_state;
        end

        idle_state: begin
            spi_drv_rdy = 1;
            if (start_cmd)
                next_state = transaction_state;
            else
                next_state = idle_state;
        end
        
        transaction_state: begin
            SS_N = 0;
            sclk_en = 1;
            if (counter_up_flag) // We have completed all the transactions
                next_state = idle_state;
            else
                next_state = transaction_state;
        end

        default: next_state = reset_state;
        endcase
    end

    //-------------------SCLK generator----------------------
    // Whenever the counter reaches CLK_DIVIDE/2 -1, sclk_reg will flip
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

    assign SCLK = sclk_reg;
    assign sclk_counter_up_flag = (sclk_counter_reg == (CLK_DIVIDE > 1) - 1);

    //-------------------Shift registers---------------------

endmodule
