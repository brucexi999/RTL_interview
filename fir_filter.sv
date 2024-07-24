// Reference: https://zipcpu.com/dsp/2017/09/15/fastfir.html

module fir_filter #(
    parameter NUM_TAPS = 2,  // Length of the finite impulse response of the filter
    parameter TAP_WIDTH = 3,  // Number of bits used to represent a tap
    parameter DATA_IN_WIDTH = 8,  // Number of bits used to represent numbers in the input signal
    parameter DATA_OUT_WIDTH = TAP_WIDTH + DATA_IN_WIDTH + 8  // Tap will be multiplied with the input, the results will be TAP_WIDTH + DATA_IN_WIDTH bit wide. +8 to make room for the accumulation, can be adjusted
) (
    input clk,
    input rst_n,
    input clk_en,
    input [DATA_IN_WIDTH-1:0] data_in,
    output logic [DATA_OUT_WIDTH-1:0] data_out
);

    logic [TAP_WIDTH-1:0] tap [NUM_TAPS-1:0];
    logic [DATA_IN_WIDTH-1:0] data_in_pipe [NUM_TAPS:0];
    logic [DATA_OUT_WIDTH-1:0] data_out_pipe [NUM_TAPS:0];

    assign data_in_pipe[0] = data_in;
    assign data_out_pipe[0] = 0;
    assign data_out = data_out_pipe[NUM_TAPS];
    
    // Hardcoded for now
    assign tap[0] = 3'b001;
    assign tap[1] = 3'b010;

    genvar i;

    generate
        for (i = 0; i < NUM_TAPS; i = i + 1) begin: FIRFilter
            fir_tap # (TAP_WIDTH, DATA_IN_WIDTH) FIRTap (
                .clk(clk),
                .clk_en(clk_en),
                .rst_n(rst_n),
                .data_in(data_in_pipe[i]),
                .tap(tap[i]),
                .partial_sum(data_out_pipe[i]),
                .data_out(data_out_pipe[i+1]),
                .data_in_delayed(data_in_pipe[i+1])
            );
        end
    endgenerate    
endmodule

module fir_tap #(
    parameter TAP_WIDTH = 2,
    parameter DATA_IN_WIDTH = 8,
    parameter DATA_OUT_WIDTH = TAP_WIDTH + DATA_IN_WIDTH + 8
) (
    input clk,
    input clk_en, // Used to halt the system pipeline if needed
    input rst_n,
    input signed [DATA_IN_WIDTH-1:0] data_in,
    input signed [TAP_WIDTH-1:0] tap,
    input signed [DATA_OUT_WIDTH-1:0] partial_sum,
    output signed [DATA_OUT_WIDTH-1:0] data_out, // +8 to account for the space needed for accumulation
    output signed [DATA_IN_WIDTH-1:0] data_in_delayed
);
    reg signed [TAP_WIDTH + DATA_IN_WIDTH-1:0] product_reg;
    reg signed [DATA_IN_WIDTH-1:0] data_reg, data_delayed_reg;
    reg signed [DATA_OUT_WIDTH-1:0] accumulator_reg;
    
    always@(posedge clk) begin
        if (!rst_n) begin
            data_reg <= 0;
            data_delayed_reg <= 0; // This reg ensures the correct delaying of signals to correctly compute the convolution
        end
        else if (clk_en) begin
            data_reg <= data_in;
            data_delayed_reg <= data_reg;
        end
    end
    
    // This reg cuts the combinational path between the multiplier and the accumulator 
    always@(posedge clk) begin
        if (!rst_n)
            product_reg <= 0;
        else if (clk_en)
            product_reg <= data_reg * tap;
    end

    // This reg cuts the long chain of accumulators
    always@(posedge clk) begin
        if (!rst_n)
            accumulator_reg <= 0;
        else if (clk_en)
            accumulator_reg <= partial_sum + { {(DATA_OUT_WIDTH-(TAP_WIDTH + DATA_IN_WIDTH)){product_reg[(TAP_WIDTH + DATA_IN_WIDTH-1)]}}, product_reg}; // Sign extension and addition
    end

    assign data_out = accumulator_reg;
    assign data_in_delayed = data_delayed_reg;
endmodule