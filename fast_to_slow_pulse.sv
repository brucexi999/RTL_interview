module fast_to_slow_pulse (
    input fast_pulse,
    input rst_n,
    input fast_clk,
    input slow_clk,
    output logic slow_pulse
); 
    logic tff, sync_0, sync_1, delay;

    always@(posedge fast_clk or negedge rst_n) begin
        if (!rst_n)
            tff <= 0;
        else
            tff <= ~tff;
    end

    always@(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_0 <= 0;
            sync_1 <= 0;
            delay <= 0;
        end
        else begin
            sync_0 <= tff;
            sync_1 <= sync_0;
            delay <= sync_1;
        end
    end

    assign slow_pulse = delay ^ sync_1;

endmodule