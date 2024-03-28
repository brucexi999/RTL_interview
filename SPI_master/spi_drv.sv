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

endmodule
