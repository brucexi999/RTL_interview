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
    wire [BYTE_CNT_WD-1:0] shift_control;

    // Stream
    wire valid_from_stream;
    wire [DATA_WD-1:0] data_from_stream;
    wire [DATA_BYTE_WD-1:0] keep_from_stream;
    wire last_from_stream;
    wire ready_to_stream;
    wire ready_to_stream_last;
    wire [DATA_WD-1:0] data_from_stream_rshift;
    wire [DATA_BYTE_WD-1:0] keep_from_stream_rshift;
    wire [DATA_WD-1:0] data_from_stream_lshift;
    wire [DATA_BYTE_WD-1:0] keep_from_stream_lshift;
    wire keep_lshift_all_0;

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

    //------------------Registers-------------------
    reg header_inserted_reg;
    reg [DATA_WD-1:0] data_from_stream_lshift_reg;
    reg [DATA_BYTE_WD-1:0] keep_from_stream_lshift_reg;
    reg [BYTE_CNT_WD-1:0] byte_insert_cnt_reg;
    reg last_from_stream_reg;
    
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
        .last_in(),
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

    //----------------Sequential logic---------------
    // Only updated when inserting new header
    always@(posedge clk) begin
        if (rst)
            byte_insert_cnt_reg <= 0;
        else if (valid_from_header && ready_to_header)
            byte_insert_cnt_reg <= byte_cnt_from_header;
    end 
    
    always@(posedge clk) begin
        if (rst | last_to_downstream)  // It will only be high for 1 cycle
            last_from_stream_reg <= 0;
        /*
        Here, we play a trick in the combinational logic. This reg is only 1 when there's a valid last signal from the stream skid,
        At that moment, the ready to the stream skid is deassertted for 1 cycle if keep_from_stream_lshift is not all zero, yet the ready from downstream is 1 (if the output skid didn't deasserted)
        So at the stream skid side, there's no data coming in. But at the output skid side, there's data going out, that is exactly our tail.
        */
        else if (valid_from_stream && last_from_stream && !keep_lshift_all_0 && ready_from_downstream) 
            last_from_stream_reg <= last_from_stream;
    end
    
    always@(posedge clk) begin
        if (rst)
            header_inserted_reg <= 0;  
        else if (!header_inserted_reg && valid_from_header && ready_to_header) // We have observed a handshake with the header skid buffer, we have completed a header insertion
            header_inserted_reg <= 1;
        else if (header_inserted_reg && last_to_downstream)  // After sending out the last frame of the stream, go back to header insertion mdoe
            header_inserted_reg <= 0;
    end

    // Only when there's handshake from the stream skid buffer this register can be updated, otherwise there will be data lost
    // Data from this register will always be valid
    always@(posedge clk) begin
        if (rst) begin
            data_from_stream_lshift_reg <= 0;
            keep_from_stream_lshift_reg <= 0;
        end
        /*
        ready_from_downstream is used instead of ready_to_stream is similar to the logic for last_from_stream_reg.
        In the case of a tail, we want to create an illusion to the stream skid that the last data is not taken because ready_to_stream is 0,
        However, it is still loaded into data_from_stream_lshift_reg, and after one cycle, when it has reached to the output skid, 
        we reassert ready_to_stream to make things transparent again.
        */
        else if (valid_from_stream && ready_from_downstream) begin
            data_from_stream_lshift_reg <= data_from_stream_lshift;
            keep_from_stream_lshift_reg <= keep_from_stream_lshift;
        end
    end
    
    //---------------Combinational logic----------------
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
    In the case where a tail is being sent, ready_to_stream will be 0. Otherwise we simply pass ready_from_downstream
    */
    assign ready_to_header = !header_inserted_reg && valid_from_header && valid_from_stream && ready_from_downstream;
    assign ready_to_stream_last = (!keep_lshift_all_0 && last_from_stream && valid_from_stream && !last_from_stream_reg) ? 1'b0 : ready_from_downstream;
    assign ready_to_stream = header_inserted_reg ? ready_to_stream_last: ready_to_header;
    /*
    For the header frame, both the header and the stream need to be valid such that they can be merged
    For streaming frame, the shift register is valid all the time, so we simply pass the valid from the stream skid buffer.
    */
    assign valid_to_downstream = header_inserted_reg? valid_from_stream : (valid_from_stream && valid_from_header);
    /* 
    Use shift operation to pack frames (remove null bytes).
    After taking the byte_insert_cnt from the header skid buffer in the cycle that the header is inserted,
    we need to register it. When switching to the stream mode, we will take the value from the regsiter
    */
    assign shift_control = header_inserted_reg? byte_insert_cnt_reg : byte_cnt_from_header;
    assign data_from_header_lshift = data_from_header << ((DATA_BYTE_WD-(shift_control+1))<<3);
    assign keep_from_header_lshift = keep_from_header << (DATA_BYTE_WD-(shift_control+1));

    assign data_from_stream_rshift = last_from_stream_reg ? {DATA_WD{1'b0}} : data_from_stream >> ((shift_control+1) << 3);
    assign keep_from_stream_rshift = last_from_stream_reg ? {DATA_BYTE_WD{1'b0}} : keep_from_stream >> (shift_control+1);

    assign data_from_stream_lshift = data_from_stream << ((DATA_BYTE_WD-(shift_control+1)) << 3);
    assign keep_from_stream_lshift = keep_from_stream << (DATA_BYTE_WD-(shift_control+1));
    
    // Use bitwise OR operation to merge frames
    // If header_inserted_reg == 0 that means we need to insert header, otherwise, we are streaming
    assign data_to_downstream = header_inserted_reg ? (data_from_stream_lshift_reg | data_from_stream_rshift) : (data_from_header_lshift | data_from_stream_rshift);
    assign keep_to_downstream = header_inserted_reg ? (keep_from_stream_lshift_reg | keep_from_stream_rshift) : (keep_from_header_lshift | keep_from_stream_rshift);
    /*
    Once we have detected a last signal from the stream and a handshake,
    if after left-shifting its associated keep we found it is all 0, then the last will propagate directly to the output skid,
    and will be picked up by it in the next cycle.
    If after shifting keep is not all zero, it means we have a tail and we need an extra cycle. The last signal will be put 
    in a register, and will be picked up by the output skid after two cycles. 
    We also need to deassert ready to stream skid in this extra cycle of sending the tail, otherwise it will get overwritten by
    the next frame
    */
    assign keep_lshift_all_0 = ~keep_from_stream_lshift[0] & ~keep_from_stream_lshift[DATA_BYTE_WD-1];
    assign last_to_downstream = keep_lshift_all_0 ? (last_from_stream && valid_from_stream && ready_to_stream) : last_from_stream_reg;

    
endmodule
