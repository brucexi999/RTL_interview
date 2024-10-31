module SYNC_FIFO_TB;

    parameter DEPTH = 8;
    parameter WIDTH = 8; 

    logic clk;
    logic rstn;

    logic [WIDTH-1:0] wdata;
    logic wen;
    logic full;
    
    logic [WIDTH-1:0] rdata;
    logic ren;
    logic empty;

    SYNC_FIFO #(DEPTH, WIDTH) DUT (
        .*
    );

    initial begin
        clk <= 0;
        rstn <= 0;
        #35;
        rstn <= 1;
        #1000;
        $stop;
    end

    always #5 clk <= ~clk;

    initial begin
        // Write until full
        wen <= 0;
        wdata <= 0;

        #35;
        for (int i=0; i<DEPTH; i++) begin
            @(posedge clk);
            wen <= 1;
            wdata <= i;
        end
        @(posedge clk);
        wen <= 0;
        repeat(DEPTH-1) @(posedge clk);

        // Random write
        for (int i=0; i<50; i++) begin
            @(posedge clk);
            wen <= $urandom;
            wdata <= i;
        end
    end

    initial begin
        // read until empty
        ren <= 0;

        #35;
        repeat(DEPTH) @(posedge clk);
        for (int i=0; i<DEPTH; i++) begin
            @(posedge clk);
            ren <= 1;
        end

        // Random read
        for (int i=0; i<50; i++) begin
            @(posedge clk);
            ren <= $urandom;
        end
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end

endmodule

module AXIS_SYNC_FIFO_TB;
    parameter DEPTH = 8;
    parameter WIDTH = 8;

    logic clk;
    logic rstn;

    logic [WIDTH-1:0] s_axis_tdata;
    logic s_axis_tvalid;
    logic s_axis_tready;

    logic [WIDTH-1:0] m_axis_tdata;
    logic m_axis_tvalid;
    logic m_axis_tready;

    AXIS_SYNC_FIFO #(DEPTH, WIDTH) DUT (
        .*
    );

    initial begin
        clk <= 0;
        rstn <= 0;
        #35;
        rstn <= 1;
        #1000;
        $stop;
    end

    always #5 clk <= ~clk;

    initial begin
        // Write until full
        s_axis_tvalid <= 0;
        s_axis_tdata <= 0;

        #35;
        for (int i=0; i<DEPTH; i++) begin
            @(posedge clk);
            s_axis_tvalid <= 1;
            s_axis_tdata <= i;
        end
        @(posedge clk);
        s_axis_tvalid <= 0;
        repeat(DEPTH-1) @(posedge clk);

        // Random write
        for (int i=0; i<50; i++) begin
            @(posedge clk);
            s_axis_tvalid <= $urandom;
            s_axis_tdata <= i;
        end
    end

    initial begin
        // read until empty
        m_axis_tready <= 0;

        #35;
        repeat(DEPTH) @(posedge clk);
        for (int i=0; i<DEPTH; i++) begin
            @(posedge clk);
            m_axis_tready <= 1;
        end

        // Random read
        for (int i=0; i<50; i++) begin
            @(posedge clk);
            m_axis_tready <= $urandom;
        end
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end

endmodule