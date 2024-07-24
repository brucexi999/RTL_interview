module shift_register #(
    parameter WIDTH = 8
) (
    input clk,
    input rst,
    input serial_in,
    output [WIDTH-1:0] parallel_out
);
    always@(posedge clk) begin
        if (rst)
            parallel_out <= 0;
        else
            parallel_out <= {parallel_out[WIDTH-2:0], serial_in};
    end
endmodule