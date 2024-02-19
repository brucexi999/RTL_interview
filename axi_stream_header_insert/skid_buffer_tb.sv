// Reference: https://github.com/thomasrussellmurphy/stx_cookbook/blob/master/storage/ready_skid_tb.sv
module skid_buffer_tb ();
    parameter DATA_WIDTH = 32;
    parameter DATA_BYTE_WIDTH = DATA_WIDTH/8;

    logic clk;
    logic rst;
    logic valid_in, valid_out;
    logic [DATA_WIDTH-1:0] data_in, data_out, data_previous, data_next;
    logic [DATA_BYTE_WIDTH-1:0] keep_in, keep_out;
    logic ready_in, ready_out;
    logic last_in, last_out;

    logic fail = 0;
    
    skid_buffer dut (.*);

    initial begin
        clk = 0;
        data_in = 0;
        keep_in = {DATA_BYTE_WIDTH{1'b1}};
        last_in = 0;
        valid_in = 0;
        ready_in = 0;
        data_previous = 0;
        rst = 0;
        #1 rst = 1'b1;
	    @(posedge clk) 
            rst = 1'b0;
    end

    always begin 
	#5 clk = ~clk;
    end

    always @(posedge clk) begin
	valid_in <= $random | $random;
	ready_in <= $random | $random;
    if (valid_in && ready_out)  // If a handshake is observed at the input side, increment the data
        data_in <= data_in + 1'b1;
    end

    always @(posedge clk) begin
        if (valid_out && ready_in) begin
            data_previous <= data_out;  // If a handshake is observed at the output side, increment the data
            data_next <= data_out + 1;
        end
        if (data_previous != data_out && data_next != data_out) begin
            $display("Mismatch at time %d, data_previous: %d, data_next: %d, data_out: %d",$time, data_previous, data_next, data_out);
            fail = 1;
        end
        //else
            //$display("Data match at time %d, data_previous: %d, data_next: %d, data_out: %d",$time, data_previous, data_next, data_out);
    end

    initial begin
        #10000 if (!fail) $display ("PASS");
        $stop();
    end

endmodule