module skid_buffer # (
    parameter DATA_WIDTH = 32,
    parameter DATA_BYTE_WIDTH = DATA_WIDTH/8
)
(
    input clk,
    input rst,

    input valid_in,
    input [DATA_WIDTH-1:0] data_in,
    input [DATA_BYTE_WIDTH-1:0] keep_in,
    input last_in,
    input ready_in,

    output reg valid_out,
    output reg [DATA_WIDTH-1:0] data_out,
    output wire [DATA_BYTE_WIDTH-1:0] keep_out,
    output wire last_out,
    output reg ready_out
);

    reg [DATA_WIDTH-1:0] data_skid_buffer;
    reg skid_buffer_valid;

    always@(posedge clk) begin
        if (rst) begin
            ready_out <= 0;
            valid_out <= 0;
            data_out <= 0;
            data_skid_buffer <= 0;
            skid_buffer_valid <= 0;
        end

        else begin
            ready_out <= ready_in;

            if (valid_out & ready_in) begin
                if (skid_buffer_valid) begin  // We have data in the skid buffer, send it out first to the pipeline register
                    data_out <= data_skid_buffer;
                    skid_buffer_valid <= 0;
                    valid_out <= 1;
                end
                else begin
                    valid_out <= 0;
                end
            end

            // The pipeline register captures the input data

            if (ready_out & valid_in) begin
                if (ready_in || ~valid_out) begin
                    data_out <= data_in;
                    valid_out <= 1;
                end
                else begin
                    skid_buffer_valid <= 1;
                    data_skid_buffer <= data_in;
                    ready_out <= 0;
                end
            end
        end
    end

    assign last_out = last_in;
    assign keep_out = keep_in;
endmodule