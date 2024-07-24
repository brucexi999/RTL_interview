module sequence_detector_tb;
    parameter k = 3;
    
    logic clk;
    logic rstn;
    logic [k-1:0] pattern_in;
    logic pattern_valid;
    logic in;
    logic out;
    logic pattern_ready;

    sequence_detector #(k) DUT (.*);

    initial begin
        rstn <= 0;
        clk <= 0;
        #20;
        rstn <= 1;
    end

    always #5 clk <= ~clk;

    always@(posedge clk) begin
        if (!rstn) begin 
            pattern_valid <= 0;
        end
        else if (!pattern_valid) begin
            pattern_valid <= $urandom() ;
        end

        else if (pattern_valid && pattern_ready) begin
            pattern_valid <= $urandom();
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin 
            pattern_in <= {k{1'b1}};
        end
        else if (pattern_valid && pattern_ready) begin
            pattern_in <= $urandom();
        end
    end

    always @(posedge clk) begin
        in <= $urandom();
    end

    initial begin
        #3000;
        $stop();
    end

    //initial begin
     //   $dumpfile("dump.vcd"); $dumpvars;
    //end
endmodule