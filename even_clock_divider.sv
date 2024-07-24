module clk_divider # (
  parameter clk_ratio = 10
) (
  input clk_in,
  input rstn,
  output logic clk_out
);
  logic [3:0] counter;
  
  always_ff @(posedge clk_in or negedge rstn) begin
    if (!rstn || counter == (clk_ratio >> 1) -1)
      counter <= 0;
    else
      counter <= counter + 1;
  end
  
  always_ff @(posedge clk_in or negedge rstn) begin
    if (!rstn)
      clk_out <= 0;
    else if (counter == (clk_ratio >> 1) -1)
      clk_out <= ~clk_out;
  end
  
endmodule