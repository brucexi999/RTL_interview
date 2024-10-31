module SYNC_FIFO #(
    parameter integer DEPTH,
    parameter integer WIDTH
) (
    input clk,
    input rstn,

    input [WIDTH-1:0] wdata,
    input wen,
    output logic full,
    
    output logic [WIDTH-1:0] rdata,
    input ren,
    output logic empty
);

    localparam int PTR_WIDTH = $clog2(DEPTH) + 1; // +1 such that the write pointer can wrap around and produce the full condition
    logic [PTR_WIDTH-1:0] wptr, rptr;
    logic [WIDTH-1:0] mem [0:DEPTH-1];

    always@(posedge clk or negedge rstn) begin
        if (!rstn) begin
            int i;
            for (i=0; i<DEPTH; i++) begin
                mem[i] <= 0;
            end
        end
        else if (!full && wen) begin
            mem[wptr[PTR_WIDTH-2:0]] <= wdata;
        end
    end

    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            wptr <= 0;
        end
        else if (!full && wen) begin
            wptr <= wptr + 1;
        end
    end

    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            rptr <= 0;
        end
        else if (!empty && ren) begin
            rptr <= rptr + 1;
        end
    end

    assign full = {~wptr[PTR_WIDTH-1], wptr[PTR_WIDTH-2:0]} == rptr;
    assign empty = wptr == rptr;
    assign rdata = mem[rptr[PTR_WIDTH-2:0]];

endmodule 

module AXIS_SYNC_FIFO #(
    parameter DEPTH,
    parameter WIDTH
) (
    input clk,
    input rstn,

    input [WIDTH-1:0] s_axis_tdata,
    input s_axis_tvalid,
    output logic s_axis_tready,

    output logic [WIDTH-1:0] m_axis_tdata,
    output logic m_axis_tvalid,
    input m_axis_tready
);

    logic full, empty;

    SYNC_FIFO #(DEPTH, WIDTH) sync_fifo  (
        .clk(clk),
        .rstn(rstn),
        .wdata(s_axis_tdata),
        .wen(s_axis_tvalid),
        .full(full),
        .rdata(m_axis_tdata),
        .ren(m_axis_tready),
        .empty(empty)
    );
    
    assign s_axis_tready = !full;
    assign m_axis_tvalid = !empty;
    
endmodule