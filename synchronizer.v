module ff (
    input d,
    input clk,
    input rst,
    output reg q
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            q <= 0;
        else 
            q <= d;
    end

endmodule

module synchronizer # (
    parameter N = 2
) (
    input in,
    input clk,
    input rst,
    output wire out
);
    wire [N:0] interconnect;

    assign interconnect[0] = in;
    assign out = interconnect[N];

    genvar i;
    generate
        for (i=0; i<N; i = i+1) begin: syn
            ff flip_flop (interconnect[i], clk, rst, interconnect[i+1]);
        end
    endgenerate

endmodule