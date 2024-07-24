module slow_to_fast_pulse (
    input fast_clk,
    input slow_pulse,
    input rst_n,
    output logic fast_pulse
);  
    logic sync_0, sync_1, delay;

    // 2-stage synchornizer
    always@(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_0 <= 0;
            sync_1 <= 0;
        end
        else begin
            sync_0 <= slow_pulse;
            sync_1 <= sync_0;
        end
    end

    always@(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            delay <= 0;
        end
        else
            delay <= sync_1;
    end

    assign fast_pulse = sync_1 && !fast_pulse_delayed;
endmodule