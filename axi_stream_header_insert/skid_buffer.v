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

    output wire valid_out,
    output wire [DATA_WIDTH-1:0] data_out,
    output wire [DATA_BYTE_WIDTH-1:0] keep_out,
    output wire last_out,
    output wire ready_out
);

    reg valid_buffer;  // Indicate whether the internel buffer has valid data
    reg valid_pipe;  // Indicate whether the pipe register has valid data

    reg [DATA_WIDTH-1:0] data_buffer;
    reg [DATA_BYTE_WIDTH-1:0] keep_buffer;
    reg last_buffer;

    reg [DATA_WIDTH-1:0] data_pipe;
    reg [DATA_BYTE_WIDTH-1:0] keep_pipe;
    reg last_pipe;

    always@(posedge clk) begin
        if (rst)
            valid_pipe <= 0;
        else if (valid_in && ready_out)  // As long as we have handshake with the previous stage, the pipeline takes in new data
            valid_pipe <= 1;
        else if (ready_in && !valid_buffer && valid_pipe)  // This means the buffer is empty, and we have sent out the data in the pipeline register as well
            valid_pipe <= 0;
        else
            valid_pipe <= valid_pipe;
    end
    
    always@(posedge clk) begin
        if (rst) begin
            data_pipe <= 0;
            keep_pipe <= 0;
            last_pipe <= 0;
        end
        else if (valid_in && ready_out) begin  // As long as we have handshake with the previous stage, the pipeline takes in new data
            data_pipe <= data_in;
            keep_pipe <= keep_in;
            last_pipe <= last_in;
        end
        else begin
            data_pipe <= data_pipe;
            keep_pipe <= keep_pipe;
            last_pipe <= last_pipe;
        end
    end
    
    always@(posedge clk) begin
        if (rst)
            valid_buffer <= 0;
        else if ((valid_in && ready_out) && (valid_out && !ready_in))  // The next stage issues a stall, but the previous stage is still sending data, we need to buffer the pipe data, and indicate the buffer is full
            valid_buffer <= 1;
        else if (ready_in && valid_buffer)
            valid_buffer <= 0;
        else
            valid_buffer <= valid_buffer;
    end

    always@(posedge clk) begin
        if (rst) begin
            data_buffer <= 0;
            keep_buffer <= 0;
            last_buffer <= 0;
        end
        else if ((valid_in && ready_out) && (valid_out && !ready_in)) begin
            data_buffer <= data_pipe;
            keep_buffer <= keep_pipe;
            last_buffer <= last_pipe;
        end
        else begin
            data_buffer <= data_buffer;
            keep_buffer <= keep_buffer;
            last_buffer <= last_buffer;
        end
    end

    /*always@(posedge clk) begin
        if (rst)
            valid_out <= 0;
        else if (valid_pipe || valid_buffer)
            valid_out <= 1;
        else
            valid_out <= 0;
    end

    // Somehow Modelsim deasserts valid_buffer at the same cycle when ready_in goes high so I have to use these FFs to delay the data in one extra cycle. In real hardware, this should be unnecessary 
    always@(posedge clk) begin
        if (rst)
            data_out <= 0;
        else if (valid_buffer)
            data_out <= data_buffer[DATA_WIDTH-1:0];
        else if (valid_pipe)
            data_out <= data_pipe[DATA_WIDTH-1:0];
    end

    always@(posedge clk) begin
        if (rst)
            keep_out <= 0;
        else if (valid_buffer)
            keep_out <= data_buffer[DATA_WIDTH+DATA_BYTE_WIDTH-1:DATA_WIDTH];
        else if (valid_pipe)
            keep_out <= data_pipe[DATA_WIDTH+DATA_BYTE_WIDTH-1:DATA_WIDTH];
    end

    always@(posedge clk) begin
        if (rst)
            last_out <= 0;
        else if (valid_buffer)
            last_out <= data_buffer[DATA_WIDTH+DATA_BYTE_WIDTH];
        else if (valid_pipe)
            last_out <= data_pipe[DATA_WIDTH+DATA_BYTE_WIDTH];
    end*/
    
    /*always @(posedge clk) begin
        if (reset) begin
            valid_buffer <= 0;
            data_buffer <= 0;
        end
        // The next stage issues a stall, but the previous stage is still sending data, we need to buffer the incoming data, and indicate its validity
        else if ((valid_in && ready_out) && (valid_out && !ready_in)) begin
            valid_buffer <= 1;
            data_buffer <= {keep_in, data_in};
        end
        // If the next stage is ready for data, we send out the buffered data
        else if (ready_in) begin
            valid_buffer <= 0;
            data_buffer <= 0;
        end
    end*/

    assign ready_out = !valid_buffer;  // We are always ready for new data from the previous stage, as long as the buffer is empty
    assign valid_out = valid_pipe || valid_buffer;  // The output is valid whenever there's buffered data or data in the pipe register
    assign data_out = valid_buffer ? data_buffer : data_pipe;  // If we have data in the buffer, send it out first, else, send the data from the pipe
    assign keep_out = valid_buffer ? keep_buffer : keep_pipe;
    assign last_out = valid_buffer ? last_buffer : last_pipe;


endmodule