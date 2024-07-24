module shifter (
  input [31:0] a,
  input [1:0] shift,
  
  output [31:0] b
);

  assign b = a << (shift*8);

endmodule
