/*
    http://atlas.physics.arizona.edu/~kjohns/downloads/panos/a7_mmfe_mb_udp.xpr/a7_mmfe_mb_udp/a7_mmfe_mb_udp.srcs/sources_1/ipshared/xilinx.com/axi_register_slice_v2_1/353278bf/hdl/verilog/axi_register_slice_v2_1_axic_register_slice.v
    This design doesn't work
*/


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

    reg [DATA_WIDTH-1:0] data_out_i;
    reg [DATA_WIDTH-1:0] data_skid_buffer;
    reg ready_out_i;
    reg valid_out_i;
    reg [1:0] rstn_d = 2'b00;  // Delayed negative reset

    always@(posedge clk) begin
        if (rst)
            rstn_d <= 2'b00;
        else
            rstn_d <= {rstn_d[0], ~rst};
    end

    always@(posedge clk) begin
        if (rstn_d[0])
            ready_out_i <= 0;
        else
            ready_out_i <= ready_in | ~valid_out | (ready_out_i & ~valid_in);
        
        if (rstn_d[1])
            valid_out_i <= 0;
        else
            valid_out_i <= valid_in | ~ready_out_i | (valid_out_i & ~ready_in);
        
        if (ready_in | ~valid_out_i)
            data_out_i <= ready_out_i ? data_in : data_skid_buffer;
        
        if (ready_out_i)
            data_skid_buffer <= data_in;
    end
    
    assign ready_out = ready_out_i;
    assign valid_out = valid_out_i;
    assign data_out = data_out_i;

    assign keep_out = keep_in;
    assign last_out = last_in;

endmodule