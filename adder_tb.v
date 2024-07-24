module half_adder_tb ();
    reg a, b; 
    wire c, s;

    half_adder dut (a, b, c, s);

    initial begin
        a=0;
        b=1;
        #5;
        a=1;
        b=0;
        #5;
        a=1;
        b=1;
        #5;
    end

endmodule

module full_adder1_tb();
    reg a, b, cin;
    wire cout, s;

    full_adder1 dut (a, b, cin, cout, s);

    initial begin
        a=0;
        b=0;
        cin = 0;
        #5;
        a=0;
        b=1;
        cin = 0;
        #5;
        a=1;
        b=0;
        cin = 0;
        #5;
        a=1;
        b=1;
        cin = 0;
        #5;
        a=0;
        b=0;
        cin = 1;
        #5;
        a=1;
        b=0;
        cin = 1;
        #5;
        a=1;
        b=1;
        cin = 1;
        #5;

    end

endmodule

module full_adderN_tb ();
    parameter N=3;
    reg [N-1:0] a;
    reg [N-1:0] b;
    wire [N-1:0] s;

    full_adderN dut (a, b, s);

    initial begin
        a=0;
        b=0;
        #5;
        a=1;
        b=1;
        #5;
        a=2;
        b=3;
        #5;
        a=1;
        b=6;
        #5;
    end
endmodule