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
    wire ready_from_slave;
    wire rst;
    
    wire ready_stream;
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
    wire ready_slave_header;

    //------------------Registers-------------------
    reg r_insert_header_flag;
    
    //------------------Instantiations-------------
    skid_buffer stream_skd (
        .clk(clk), 
        .rst(rst), 
        .valid_in(valid_in), 
        .data_in(data_in), 
        .keep_in(keep_in), 
        .last_in(last_in), 
        .ready_in(ready_slave_stream),
        .valid_out(valid_slave_stream),
        .data_out(data_slave_stream),
        .keep_out(keep_slave_stream),
        .last_out(last_slave_stream),
        .ready_out(ready_stream)
        );

    skid_buffer header_skd (
        .clk(clk), 
        .rst(rst), 
        .valid_in(valid_insert), 
        .data_in(data_insert), 
        .keep_in(keep_insert), 
        .last_in(1'b1),  // Last signal from the header is always 1
        .ready_in(ready_slave_header),
        .valid_out(valid_slave_header),
        .data_out(data_slave_header),
        .keep_out(keep_slave_header),
        .last_out(last_slave_header),
        .ready_out(ready_header));
    
    //---------------Always blocks----------------
    always@(posedge clk) begin
        if (rst)  // Upon resetting, we first wait for the arrival of the first header
            r_insert_header_flag <= 1;
        else if (r_insert_header_flag && valid_slave_header && ready_slave_header)  // When we are in the header-inserting mode, and have observed a handshake with the slave, we know a data transfer has completed (a header has been sent out to the slave)
            r_insert_header_flag <= 0;
        else if (!r_insert_header_flag && last_slave_stream && valid_slave_stream && ready_slave_stream)  // When we have observed the last signal from the stream, we know that's the end of a packet, we need to wait for a new header to be inserted for the next packet
            r_insert_header_flag <= 1;
        else
            r_insert_header_flag <= r_insert_header_flag;
    end
    
    //---------------Combinational logics------------------

    // Remove the null bytes in inserted header by making them 0
    function [DATA_WD-1:0] remove_null;
        input [DATA_WD-1:0] original_data;
        input [DATA_BYTE_WD-1:0] keep;

        integer k;
        for (k=0; k<DATA_BYTE_WD; k=k+1) begin
            remove_null[k*8 +: 8] = keep[k] ? original_data[k*8 +: 8] : {8{1'b0}};
        end
    endfunction
    assign null_removed_header = remove_null(data_slave_header, keep_slave_header);

    assign ready_from_slave = ready_out;
    assign rst = !rst_n;
    
    assign ready_in = ready_stream;
    assign ready_slave_stream = (!r_insert_header_flag) && ready_from_slave;  // Pass the ready from the slave to the stream skid buffer if we are not inserting the header

    assign ready_insert = ready_header;
    assign ready_slave_header = r_insert_header_flag && ready_from_slave;  // Pass the ready from the slave to the header skid buffer if we are inserting the header

    assign valid_out = r_insert_header_flag? valid_slave_header: valid_slave_stream;
    assign data_out = r_insert_header_flag? null_removed_header: data_slave_stream;
    assign keep_out = r_insert_header_flag? keep_slave_header: keep_slave_stream;
    assign last_out = r_insert_header_flag? last_slave_header: last_slave_stream;

endmodule