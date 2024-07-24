module decoder # (
    parameter N = 2,
    parameter M = 4
) (
    input [N-1] in,
    output wire [M-1] out
);
    assign out = 1 << in;

endmodule