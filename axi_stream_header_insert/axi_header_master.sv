module axi_header_master # (
    parameter DATA_WIDTH = 32,
    parameter DATA_BYTE_WIDTH = DATA_WIDTH/8,
    parameter BYTE_CNT_WIDTH = $clog2(DATA_BYTE_WIDTH)
    ) (
    input clk,
    input rst_n,

    output logic valid,
    output logic [DATA_WIDTH-1:0] data,
    output logic [DATA_BYTE_WIDTH-1:0] keep,
    output logic [BYTE_CNT_WIDTH-1:0] byte_insert_cnt,
    input ready 
    );
    
    logic rst;
    logic [DATA_BYTE_WIDTH-1:0] new_keep;
    logic [BYTE_CNT_WIDTH-1:0] new_byte_insert_cnt;

    always@(posedge clk) begin
        if (rst)
            valid <= 0;
        else
            valid <= 1;
    end

    always@(posedge clk) begin
        if (rst)
            data <= 'hDEADBEEF;
        else if (valid && ready)
            data <= data + 1;
        else
            data <= data;
    end

    always@(posedge clk) begin
        if (rst)
            keep <= {DATA_BYTE_WIDTH{1'b1}};
        else if (valid && ready) 
            keep <= new_keep;
        else
            keep <= keep;
    end

    always@(posedge clk) begin
        if (rst)
            byte_insert_cnt = {BYTE_CNT_WIDTH{1'b1}};
        else if (valid && ready)
            byte_insert_cnt <= new_byte_insert_cnt;
        else
            byte_insert_cnt <= byte_insert_cnt;
    end
    
    always@(*) begin
        new_keep = keep >> 1;
        new_byte_insert_cnt = byte_insert_cnt - 1;
        if (new_keep == 0) begin
            new_keep = {DATA_BYTE_WIDTH{1'b1}};
            new_byte_insert_cnt = {BYTE_CNT_WIDTH{1'b1}};
        end
    end

    assign rst = !rst_n;
    
endmodule