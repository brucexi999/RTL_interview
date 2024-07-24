// Odd integer clock divider with 50% duty cycle
// N is odd
module odd_clk_divider #(
    parameter N = 5
)(
    input clk_in,
    input rst_n,
    output logic clk_out
);

    logic [$clog2(N):0] counter;
    logic tff_1; // T-Flip flop, T stands for toggle
    logic tff_2;

    always_ff@(posedge clk_in) begin
        if (!rst_n || counter == N-1)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    always_ff@(posedge clk_in) begin
        if (!rst_n)
            tff_1 <= 0;
        else if (counter == 0)
            tff_1 <= ~tff_1;
    end

    always_ff@(negedge clk_in) begin
        if (!rst_n)
            tff_2 <= 0;
        else if (counter == (N>>1) + 1)
            tff_2 <= ~tff_2;
    end

    assign clk_out = tff_2 ^ tff_1;
endmodule