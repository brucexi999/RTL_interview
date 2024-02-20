module axi_stream_master # (
    parameter DATA_WIDTH = 32,
    parameter DATA_BYTE_WIDTH = DATA_WIDTH/8,
    parameter PAUSE_DURATION = 10,
    parameter PAUSE_CYCLE = 66,
    parameter DATA_MAX = 99
)
(   input clk,
    input rst_n,

    output logic valid,
    output logic [DATA_WIDTH-1:0] data,
    output logic [DATA_BYTE_WIDTH-1:0] keep,
    output logic last,
    input ready
);
    logic rst;
    logic [DATA_WIDTH-1:0] counter;
    logic pause;

    always@(posedge clk) begin
        if (rst || last || pause)
            valid <= 0;
        else if (!pause)
            valid <= 1;
        else
            valid <= valid;
    end

    always@(posedge clk) begin
        if (rst || last)
            data <= 0;
        else if (valid && ready && !last)
            data <= data + 1;
        else
            data <= data;
    end

    always@(posedge clk) begin
        if (rst || last)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    always@(posedge clk) begin
        if (rst)
            pause <= 0;
        else if ((counter >= PAUSE_CYCLE) && (counter < (PAUSE_CYCLE + PAUSE_DURATION)))
            pause <= 1;
        else
            pause <= 0;
    end
    
    assign rst = !rst_n;
    assign last = (data == DATA_MAX);
    assign keep = {DATA_BYTE_WIDTH{1'b1}};
endmodule