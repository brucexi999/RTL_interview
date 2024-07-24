module half_adder (
    input a,
    input b,
    output wire c,
    output wire s
);
    assign c = a & b;
    assign s = a ^ b;

endmodule

module full_adder1 (
    input a,
    input b,
    input cin,
    output wire cout,
    output wire s
);
    wire g, p, cp;

    half_adder ha1 (a, b, g, p);
    half_adder ha2(cin, p, cp, s);

    assign cout = g | cp;

endmodule

module full_adderN # (
    parameter N = 3
) (
    input [N-1:0] a,
    input [N-1:0] b,
    output wire [N-1:0] s
);
    wire [N:0] c;
    assign c[0] = 1'b0;
    assign c[N] = 1'b0; 

    genvar i;
    generate 
        for (i = 0; i < N; i = i+1) begin: faN
            full_adder1 fa1 (
                .a(a[i]),
                .b(b[i]),
                .cin(c[i]),
                .cout(c[i+1]),
                .s(s[i])
            );
        end
    endgenerate
endmodule