/*
Pipeline register with skid buffer, outputs are registered
Reference: 
https://github.com/thomasrussellmurphy/stx_cookbook/blob/master/storage/ready_skid_tb.sv
https://docs.xilinx.com/r/en-US/pg373-axi-register-slice/Fully-Registered
https://www.twblogs.net/a/5bfae448bd9eee7aed32c7d0
*/
module skid_buffer # (
    parameter DATA_WIDTH = 32,
    parameter DATA_BYTE_WIDTH = DATA_WIDTH/8,
    parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WIDTH)
)
(
    input clk,
    input rst,

    input valid_in,
    input [DATA_WIDTH-1:0] data_in,
    input [DATA_BYTE_WIDTH-1:0] keep_in,
    input [BYTE_CNT_WD-1:0] byte_insert_cnt_in,
    input last_in,
    input ready_in,

    output reg valid_out,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg [DATA_BYTE_WIDTH-1:0] keep_out,
    output reg [BYTE_CNT_WD-1:0] byte_insert_cnt_out,
    output reg last_out,
    output reg ready_out
);

    reg [DATA_WIDTH-1:0] data_skid;
    reg [DATA_BYTE_WIDTH-1:0] keep_skid;
    reg [BYTE_CNT_WD-1:0] byte_insert_cnt_skid;
    reg last_skid;

    reg valid_skid;

    always@(posedge clk) begin
        if (rst)
            valid_out <= 0;
        // If we have received data from the upstream, or we have data in the skid buffer
        else if ((valid_in && ready_out) || valid_skid)
            valid_out <= 1;
        // No valid data from the upstream, and no valid data in the skid, and the current data is taken by the downstream, the data at the next cycle will be invalid
        else if ((ready_in && valid_out) && ~valid_skid && (!valid_in || !ready_out))
            valid_out <= 0;
    end

    // Essentially ready_out = ~valid_skid
    always@(posedge clk) begin
        if (rst) begin
            valid_skid <= 0;
            ready_out <= 0;
        end
        // We have received data from the upstream, and the data in the pipeline register has not been taken, buffer the upstream data
        else if ((valid_in && ready_out) && (valid_out && !ready_in)) begin
            valid_skid <= 1;
            ready_out <= 0;
        end
        // If there's data in the skid buffer, and the downstream asserted ready, we know the data in the skid buffer will be sent out
        else if (ready_in && valid_skid) begin
            valid_skid <= 0;
            ready_out <= 1;
        end
        else begin
            ready_out <= !valid_skid;
        end
    end

    always@(posedge clk) begin
        if (rst) begin
            data_out <= 0;
            keep_out <= 0;
            byte_insert_cnt_out <= 0;
            last_out <= 0;
        end
        // When the current data in the pipeline register has been taken by downstream, and we found there's data in the skid buffer
        else if (valid_out && ready_in && valid_skid) begin
            data_out <= data_skid;
            keep_out <= keep_skid;
            byte_insert_cnt_out <= byte_insert_cnt_skid;
            last_out <= last_skid;
        end
        // We have taken in new data from the upstream, now if we don't have valid pipeline register, or the downstream has taken the current data, we put the incoming data into the pipeline register
        else if (valid_in && ready_out && (!valid_out || (ready_in && valid_out))) begin
            data_out <= data_in;
            keep_out <= keep_in;
            byte_insert_cnt_out <= byte_insert_cnt_in;
            last_out <= last_in;
        end
    end

    always@(posedge clk) begin
        if (rst) begin
            data_skid <= 0;
            keep_skid <= 0;
            byte_insert_cnt_skid <= 0;
            last_skid <= 0;
        end
        // We have taken in new data from the upstream, but the current data in the pipeline register has not been taken, store the incoming data into skid buffer
        else if ((valid_in && ready_out) && (valid_out && !ready_in)) begin
            data_skid <= data_in;
            keep_skid <= keep_in;
            byte_insert_cnt_skid <= byte_insert_cnt_in;
            last_skid <= last_in;
        end
    end

endmodule