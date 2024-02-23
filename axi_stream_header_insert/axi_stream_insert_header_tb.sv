`timescale 1 ps / 1 ps
module axi_stream_insert_header_tb ();
    parameter DATA_WIDTH = 32;
    parameter DATA_BYTE_WIDTH = DATA_WIDTH/8;
    parameter BYTE_CNT_WIDTH = $clog2(DATA_BYTE_WIDTH);

    logic clk;
    logic rst_n;

    logic valid_insert, valid_in, valid_out;
    logic [DATA_WIDTH-1:0] data_insert, data_in, data_out, new_in, new_insert;
    logic [DATA_BYTE_WIDTH-1:0] keep_insert, keep_in, keep_out;
    logic last_in, last_out;
    logic [BYTE_CNT_WIDTH-1:0] byte_insert_cnt;
    logic ready_insert, ready_in, ready_out;

    axi_header_master header_master (clk, rst_n, valid_insert, data_insert, keep_insert, byte_insert_cnt, ready_insert);
    axi_stream_insert_header dut (
        clk, rst_n,
        valid_in, data_in, keep_in, last_in, ready_in,
        valid_out, data_out, keep_out, last_out, ready_out,
        valid_insert, data_insert, keep_insert, byte_insert_cnt, ready_insert
    );
/*
    initial begin
        clk = 0;

        // Stream data
        data_in = 0;
        keep_in = {DATA_BYTE_WIDTH{1'b1}};
        last_in = 0;
        valid_in = 0;

        // Header
        data_insert = 0;
        keep_insert = 0;
        byte_insert_cnt = 0;
        valid_insert = 0;

        // Slave
        ready_out = 0;

        rst_n = 1;
        #1 rst_n = 0;
	    @(posedge clk) 
            rst_n = 1;
    end
    
    always begin 
	#5 clk = ~clk;
    end

    always@(posedge clk) begin
        if (!rst_n)
            data_in <= 0;
        else
            data_in <= new_in;
    end
    
    always@(*) begin
        new_in = data_in + 1;
        if (new_in == 'd255)
            new_in = data_in;
    end

    

    initial begin
        #6000;
        $stop;
    end
*/

    initial begin
        clk = 0; #5;
        forever begin
            clk = 1; #5;
            clk = 0; #5;
        end
    end

    initial begin
        rst_n = 0; #15;
        rst_n = 1;
    end

    initial begin
        #6000;
        $stop;
    end

    //------------------An embedded slave module---------------
    /* 
    This slave module will first idel for some time (IDLE_DURATION), in which state ready_out = 0,
    then it will be active, i.e., ready_out = 1 for some time (READY_DURATION_1), 
    then deassert ready_out again (DEASSERTION_DURATION), after which, it is re-asserted (READY_DURATION_2)
    */

    int IDLE_DURATION = 10;
    int READY_DURATION_1 = 200;
    int DEASSERTION_DURATION = 5;
    int READY_DURATION_2 = 300;
    int UPPER_BOUND = 100;
    int SEED = 1984;
    int MASK = 32'h7FFFFFFF;
    /*
    // Generate the random durations
    initial begin
    IDLE_DURATION = ($random(SEED) & MASK % UPPER_BOUND) + 1; // Ensure non-zero
    READY_DURATION_1 = ($random(SEED) & MASK % UPPER_BOUND) + 1;
    DEASSERTION_DURATION = ($random(SEED) & MASK % UPPER_BOUND) + 1;
    READY_DURATION_2 = ($random(SEED) & MASK % UPPER_BOUND) + 1;

    $display("IDLE_DURATION: %d", IDLE_DURATION);
    $display("READY_DURATION_1: %d", READY_DURATION_1);
    $display("DEASSERTION_DURATION: %d", DEASSERTION_DURATION);
    $display("READY_DURATION_2: %d", READY_DURATION_2);
    end*/

    logic [DATA_WIDTH-1:0] counter_slave;

    always@(posedge clk) begin
        if (!rst_n)
            counter_slave <= 0;
        else
            counter_slave <= counter_slave + 1;
    end
    
    typedef enum {
        STATE_IDLE,
        STATE_READY_1,
        STATE_DEASSERTION,
        STATE_READY_2
    } state_type;
    
    state_type current_state, next_state;
    
    always@(posedge clk) begin
        if (!rst_n)
            current_state <= STATE_IDLE;
        else
            current_state <= next_state;
    end

    always@(*) begin
        case (current_state)
            STATE_IDLE: begin
                ready_out = 0;
                next_state = STATE_IDLE;
                if (counter_slave == IDLE_DURATION)
                    next_state = STATE_READY_1;
            end
            STATE_READY_1: begin
                ready_out = 1;
                next_state = STATE_READY_1;
                if (counter_slave == IDLE_DURATION + READY_DURATION_1)
                    next_state = STATE_DEASSERTION;
            end
            STATE_DEASSERTION: begin
                ready_out = 0;
                next_state = STATE_DEASSERTION;
                if (counter_slave == IDLE_DURATION + READY_DURATION_1 + DEASSERTION_DURATION)
                    next_state = STATE_READY_2;
            end
            STATE_READY_2: begin
                ready_out = 1;
                next_state = STATE_READY_2;
                if (counter_slave == IDLE_DURATION + READY_DURATION_1 + DEASSERTION_DURATION + READY_DURATION_2)
                    next_state = STATE_IDLE;
            end
            default: next_state = STATE_IDLE;
        endcase
    end

    //-----------------------An embedded master stream module-----------------

    /*
    This master module will first be valid until cycle == PAUSE_CYCLE, 
    pause for PAUSE_DURATION cycles, and remain valid afterwards,
    It generates incrementing data, with a ceiling of DATA_MAX.
    */

    int PAUSE_DURATION = 10;
    int PAUSE_CYCLE = 66;
    int DATA_MAX = 'h12345678 + 'd99;
/*
    initial begin
    PAUSE_DURATION = ($random(SEED) & MASK % UPPER_BOUND) + 1; // Ensure non-zero
    PAUSE_CYCLE = ($random(SEED) & MASK % UPPER_BOUND) + 1;
    DATA_MAX = ($random(SEED) & MASK % UPPER_BOUND) + 1;

    $display("PAUSE_DURATION: %d", PAUSE_DURATION);
    $display("PAUSE_CYCLE: %d", PAUSE_CYCLE);
    $display("DATA_MAX: %d", DATA_MAX);
    end
    */
    logic [DATA_WIDTH-1:0] counter_master;
    logic pause;

    always@(posedge clk) begin
        if (!rst_n || last_in || pause)
            valid_in <= 0;
        else if (!pause)
            valid_in <= 1;
        else
            valid_in <= valid_in;
    end

    always@(posedge clk) begin
        if (!rst_n || last_in)
            data_in <= 'h12345678;
        else if (valid_in && ready_in && !last_in)
            data_in <= data_in + 1;
        else
            data_in <= data_in;
    end

    always@(posedge clk) begin
        if (!rst_n || last_in)
            counter_master <= 0;
        else
            counter_master <= counter_master + 1;
    end

    always@(posedge clk) begin
        if (!rst_n)
            pause <= 0;
        else if ((counter_master >= PAUSE_CYCLE) && (counter_master < (PAUSE_CYCLE + PAUSE_DURATION)))
            pause <= 1;
        else
            pause <= 0;
    end
    
    logic [DATA_BYTE_WIDTH-1:0] keep_last = {DATA_BYTE_WIDTH{1'b1}};

    assign last_in = (data_in == DATA_MAX);
    always@(*) begin
        keep_in = {DATA_BYTE_WIDTH{1'b1}};
        if (last_in)
            keep_in = keep_last;
    end

    always@(posedge last_in) begin
        keep_last = keep_last << 1;
        if (keep_last == 0)
            keep_last = {DATA_BYTE_WIDTH{1'b1}};
    end

endmodule

