module axi_stream_insert_header #(
    parameter DATA_WD = 32,
    parameter DATA_BYTE_WD = DATA_WD / 8,
    parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD)
    ) (
    input clk,
    input rst_n,
    // AXI Stream input original data
    input valid_in,
    input [DATA_WD-1 : 0] data_in,
    input [DATA_BYTE_WD-1 : 0] keep_in,
    input last_in,
    output ready_in,
    // AXI Stream output with header inserted
    output valid_out,
    output [DATA_WD-1 : 0] data_out,
    output [DATA_BYTE_WD-1 : 0] keep_out,
    output last_out,
    input ready_out,
    // The header to be inserted to AXI Stream input
    input valid_insert,
    input [DATA_WD-1 : 0] data_insert,
    input [DATA_BYTE_WD-1 : 0] keep_insert,
    input [BYTE_CNT_WD-1 : 0] byte_insert_cnt,
    output ready_insert
    );
    
    // -----------------Wires----------------------
    wire rst;
    //wire [BYTE_CNT_WD-1:0] data_byte_width = DATA_BYTE_WD;
    wire [BYTE_CNT_WD-1:0] shift_control;

    // Stream
    wire valid_from_stream;
    wire [DATA_WD-1:0] data_from_stream;
    wire [DATA_BYTE_WD-1:0] keep_from_stream;
    wire last_from_stream;
    wire ready_to_stream;

    wire [DATA_WD-1:0] data_from_stream_rshift;
    wire [DATA_BYTE_WD-1:0] keep_from_stream_rshift;
    wire [DATA_WD-1:0] data_from_stream_lshift;
    wire [DATA_BYTE_WD-1:0] keep_from_stream_lshift;
    
    //wire [DATA_WD-1:0] data_stream;
    //wire [DATA_BYTE_WD-1:0] keep_stream;
    //wire valid_stream;

    //wire [DATA_WD-1:0] data_to_shift;
    //wire [DATA_BYTE_WD-1:0] keep_to_shift;
    //wire last_signal;

    // Header
    wire valid_from_header;
    wire [DATA_WD-1:0] data_from_header;
    wire [DATA_BYTE_WD-1:0] keep_from_header;
    wire [BYTE_CNT_WD-1:0] byte_cnt_from_header;
    wire ready_to_header;

    wire [DATA_WD-1:0] data_from_header_lshift;
    wire [DATA_BYTE_WD-1:0] keep_from_header_lshift;

    // Downstream
    wire valid_to_downstream;
    wire [DATA_WD-1:0] data_to_downstream;
    wire [DATA_BYTE_WD-1:0] keep_to_downstream;
    wire last_to_downstream;
    wire ready_from_downstream;
    
    //wire tail_flag;
    /*wire ready_stream;
    wire valid_slave_stream;
    wire [DATA_WD-1:0] data_slave_stream;
    wire [DATA_BYTE_WD-1:0] keep_slave_stream;
    wire last_slave_stream;
    wire ready_slave_stream;

    wire ready_header;
    wire valid_slave_header;
    wire [DATA_WD-1:0] data_slave_header;
    wire [DATA_WD-1:0] null_removed_header;
    wire [DATA_BYTE_WD-1:0] keep_slave_header;
    wire last_slave_header;
    wire ready_slave_header;*/

    //------------------Registers-------------------
    reg header_inserted_flag;
    reg tail_buffer_valid;

    reg [DATA_WD-1:0] data_from_stream_lshift_reg;
    reg [DATA_BYTE_WD-1:0] keep_from_stream_lshift_reg;
    reg [BYTE_CNT_WD-1:0] byte_insert_cnt_reg;
    reg last_from_stream_reg;

    reg [DATA_WD-1:0] data_tail_buffer;
    reg [DATA_BYTE_WD-1:0] keep_tail_buffer;
    reg last_tail_buffer;
    
    //------------------Instantiations-------------
    skid_buffer stream_skid (
        .clk(clk), 
        .rst(rst), 
        .valid_in(valid_in), 
        .data_in(data_in), 
        .keep_in(keep_in), 
        .byte_insert_cnt_in(),
        .last_in(last_in), 
        .ready_in(ready_to_stream),
        .valid_out(valid_from_stream),
        .data_out(data_from_stream),
        .keep_out(keep_from_stream),
        .byte_insert_cnt_out(),
        .last_out(last_from_stream),
        .ready_out(ready_in)
        );

    skid_buffer header_skid (
        .clk(clk), 
        .rst(rst), 
        .valid_in(valid_insert), 
        .data_in(data_insert), 
        .keep_in(keep_insert),
        .byte_insert_cnt_in(byte_insert_cnt),
        .last_in(),  // Last signal from the header is always 1
        .ready_in(ready_to_header),
        .valid_out(valid_from_header),
        .data_out(data_from_header),
        .keep_out(keep_from_header),
        .byte_insert_cnt_out(byte_cnt_from_header),
        .last_out(),
        .ready_out(ready_insert)
    );

    skid_buffer output_skid (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_to_downstream),
        .data_in(data_to_downstream),
        .keep_in(keep_to_downstream),
        .byte_insert_cnt_in(),
        .last_in(last_to_downstream),
        .ready_in(ready_out),
        .valid_out(valid_out),
        .data_out(data_out),
        .keep_out(keep_out),
        .byte_insert_cnt_out(),
        .last_out(last_out),
        .ready_out(ready_from_downstream)
    );

    // Only updated when inserting new header
    always@(posedge clk) begin
        if (rst)
            byte_insert_cnt_reg <= 0;
        else if (valid_from_header && ready_to_header)
            byte_insert_cnt_reg <= byte_cnt_from_header;
        else
            byte_insert_cnt_reg <= byte_insert_cnt_reg;
    end 
    
    always@(posedge clk) begin
        if (rst | last_to_downstream)  // It will only be high for 1 cycle
            last_from_stream_reg <= 0;
        else if (valid_from_stream && ready_to_stream)
            //last_from_stream_reg <= last_signal;
            last_from_stream_reg <= last_from_stream;
        else
            last_from_stream_reg <= last_from_stream_reg;
    end
    
    always@(posedge clk) begin
        if (rst)
            header_inserted_flag <= 0;
        else if (!header_inserted_flag && valid_from_header && ready_to_header) // We have observed a handshake with the header skid buffer, we have completed a header insertion
            header_inserted_flag <= 1;
        else if (header_inserted_flag && last_to_downstream)  // After sending out the last frame of the stream, go back to header insertion mdoe
            header_inserted_flag <= 0;
        else
            header_inserted_flag <= header_inserted_flag;
    end

    // Only when there's handshake from the stream skid buffer this register can be updated, otherwise there will be data lost
    // Data from this register will always be valid
    always@(posedge clk) begin
        if (rst) begin
            data_from_stream_lshift_reg <= 0;
            keep_from_stream_lshift_reg <= 0;
        end
        else if (valid_from_stream && ready_to_stream) begin
            data_from_stream_lshift_reg <= data_from_stream_lshift;
            keep_from_stream_lshift_reg <= keep_from_stream_lshift;
        end
        else begin
            data_from_stream_lshift_reg <= data_from_stream_lshift_reg;
            keep_from_stream_lshift_reg <= keep_from_stream_lshift_reg;
        end
    end

    /*always@(posedge clk) begin
        if (rst || (!header_inserted_flag && valid_from_header && ready_to_header)) begin // When we have completed a header insertion, the data in the tail buffer will be taken
            tail_buffer_valid <= 0;
            data_tail_buffer <= 0;
            keep_tail_buffer <= 0;
            last_tail_buffer <= 0;
        end
        else if (tail_flag && valid_from_stream && ready_to_stream) begin
            tail_buffer_valid <= 1;
            data_tail_buffer <= data_from_stream;
            keep_tail_buffer <= keep_from_stream;
            last_tail_buffer <= last_from_stream;
        end
        else begin
            tail_buffer_valid <= tail_buffer_valid;
            data_tail_buffer <= data_tail_buffer;
            keep_tail_buffer <= keep_tail_buffer;
            last_tail_buffer <= last_tail_buffer;
        end
    end*/
    
    
    assign rst = !rst_n;

    /*
    Initially, when header is not inserted, we need to wait for both the header and the first frame of the stream to be valid,
    if at cycle = t1 both are valid, then within the same cycle, ready for both should be asserted to take one frame of data from both.
    At cycle = t1+1, these two taken frames can be packed and merged and picked up by the skid buffer at the output side.
    Ready must be asserted within the same cycle when valids are asserted to avoid a bubble of one cycle, that is, we can't do
    always@(posedge clk)
        if (valid)
            ready <= 1;
    this will cost us 1 extra cycle to take the data.

    After the header is being inserted, we should switch mode. ready_to_header should be kept 0 until we have sent out the last stream frame.
    ready_to_stream in this mode is a bit complicated, it is not simply ready_from_downstream. We also need to make sure there's no data
    in the tail buffer
    */
   
    assign ready_to_header = !header_inserted_flag && valid_from_header && valid_from_stream && ready_from_downstream;
    //assign ready_to_stream = header_inserted_flag? (ready_from_downstream && !  ) : ready_to_header; 
    assign ready_to_stream = header_inserted_flag? ready_from_downstream : ready_to_header;

    /*
    For the header frame, both the header and the stream need to be valid such that they can be merged
    For streaming frame, the shift register is valid all the time, so we simply pass the valid from the stream skid buffer if no tail.
    If there's tail, we pass insteal the valid from the shift register, which is 1
    */
    //assign valid_stream = last_from_stream_reg ? (valid_from_stream || tail_buffer_valid): 1'b1;
    //assign valid_to_downstream = header_inserted_flag? valid_stream : (valid_from_stream && valid_from_header);

    assign valid_to_downstream = header_inserted_flag? valid_from_stream : (valid_from_stream && valid_from_header);
    /*
    When there's data in the tail buffer, we need to send it out first
    */
    //assign data_to_shift = tail_buffer_valid? data_tail_buffer : data_from_stream;
    //assign keep_to_shift = tail_buffer_valid? keep_tail_buffer : keep_from_stream;
    //assign last_signal = tail_buffer_valid? last_tail_buffer : last_from_stream;
     
    /* 
    Use shift operation to pack frames (remove null bytes).
    After taking the byte_insert_cnt from the header skid buffer in the cycle that the header is inserted,
    we need to register it. When switching to the stream mode, we will take the value from the regsiter
    */
    assign shift_control = header_inserted_flag? byte_insert_cnt_reg : byte_cnt_from_header;
    assign data_from_header_lshift = data_from_header << ((DATA_BYTE_WD-(shift_control+1))*8);
    assign keep_from_header_lshift = keep_from_header << (DATA_BYTE_WD-(shift_control+1));

    assign data_from_stream_rshift = data_from_stream >> ((shift_control+1)*8);
    assign keep_from_stream_rshift = keep_from_stream >> (shift_control+1);

    assign data_from_stream_lshift = data_from_stream << ((DATA_BYTE_WD-(shift_control+1))*8);
    assign keep_from_stream_lshift = keep_from_stream << (DATA_BYTE_WD-(shift_control+1));
    
    // Use bitwise OR operation to merge frames
    // If header_inserted_flag == 0 that means we need to insert header, otherwise, we are streaming

    //assign data_to_downstream = header_inserted_flag ? data_stream : (data_from_header_lshift | data_from_stream_rshift);
    //assign keep_to_downstream = header_inserted_flag ? keep_stream : (keep_from_header_lshift | keep_from_stream_rshift);

    // In the cycle of sending the tail, flaged by the last_from_stream_reg, we direcly pass the tails without bitwise OR
    //assign data_stream = last_from_stream_reg ? data_from_stream_lshift_reg : (data_from_stream_lshift_reg | data_from_stream_rshift);
    //assign keep_stream = last_from_stream_reg ? keep_from_stream_lshift_reg : (keep_from_stream_lshift_reg | keep_from_stream_rshift);
    
    assign data_to_downstream = header_inserted_flag ? (data_from_stream_lshift_reg | data_from_stream_rshift) : (data_from_header_lshift | data_from_stream_rshift);
    assign keep_to_downstream = header_inserted_flag ? (keep_from_stream_lshift_reg | keep_from_stream_rshift) : (keep_from_header_lshift | keep_from_stream_rshift);
    /*
    Once we have detected a last signal from the stream and a handshake,
    if after left-shifting its associated keep we found it is all 0, then the last will propagate directly to the output skid,
    and will be picked up by it in the next cycle.
    If after shifting keep is not all zero, it means we have a tail and we need an extra cycle. The last signal will be put 
    in a register, and will be picked up by the output skid after two cycles. 
    We also need to deassert ready to stream skid in this extra cycle of sending the tail, otherwise it will get overwritten by
    the next frame
    */
    //assign last_to_downstream = (keep_from_stream_lshift == {DATA_BYTE_WD{1'b0}})? (last_signal && valid_from_stream && ready_to_stream) : last_from_stream_reg;
    assign last_to_downstream = (keep_from_stream_lshift == {DATA_BYTE_WD{1'b0}})? (last_from_stream && valid_from_stream && ready_to_stream) : last_from_stream_reg;
    //assign tail_flag = last_signal && valid_from_stream && ready_to_stream && keep_from_stream_lshift != {DATA_BYTE_WD{1'b0}};

endmodule