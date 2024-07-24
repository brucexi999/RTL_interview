module counter_up #(
    parameter N = 4
) (
    input clk,
    input rst,
    output reg [N-1:0] out
);
    reg [N-1:0] count;
    reg [N-1:0] new_count;

    always@(posedge clk or posedge rst) begin
        if (rst) begin
            count <= {N{1'b0}};
        end
        else begin
            count <= new_count;
        end
    end

    always@(*) begin
        if (count < {N{1'b1}}) begin
            new_count = count + 1;
        end
        else begin
            new_count = count;
        end
    end

    always@(*) begin
        out = count;
    end

endmodule

module counter_down #(
    parameter N = 8
) (
    input clk,
    input rst,
    output [N-1:0] out
);
    reg [N-1:0] count;

    always@(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
        end
        else begin
            count <= count - 1;
        end
    end

    assign out = count;

endmodule