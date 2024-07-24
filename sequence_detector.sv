module sequence_detector #(
    parameter k = 4
) (
    input clk,
    input rstn,
    input [k-1:0] pattern_in,
    input pattern_valid,
    input in,
    output logic out,
    output logic pattern_ready
);
    logic [k-1:0] pattern, shift_reg;
    logic load_pattern, load_shift_reg, match, start_detect;
    typedef enum {
        reset_st,
        pattern_st,
        detect_st
    } state_type;

    state_type current_state, next_state;

    always_ff@(posedge clk) begin
        if (!rstn) begin
            current_state <= reset_st;
        end
        else begin
            current_state <= next_state;
        end
    end

    always_ff@(posedge clk) begin
        if (!rstn) begin
            pattern <= 0;
        end
        else if (load_pattern) begin
            pattern <= pattern_in;
        end
    end

    always_ff@(posedge clk) begin
        if (!rstn) begin
            shift_reg <= 0;
        end
        else if (load_pattern) begin
            shift_reg <= pattern_in;
        end
        else if (in == shift_reg[0] && start_detect) begin
            shift_reg <= {1'b0, shift_reg[k-1:1]};
        end
        else if (in != shift_reg[0] && start_detect) begin
            shift_reg <= pattern;
        end
        
    end

    always_ff@(posedge clk) begin
        match <= 0;
        if (shift_reg == 0 && start_detect) begin
            match <= 1;
        end
    end

    always_comb begin
        pattern_ready = 0;
        load_shift_reg = 0;
        start_detect = 0;
        case (current_state)
            reset_st: begin
                if (pattern_valid) begin
                    next_state = pattern_st;
                end
                else begin
                    next_state = reset_st;
                end
            end
            pattern_st: begin
                pattern_ready = 1;
                next_state = detect_st;
            end
            detect_st: begin
                start_detect = 1;
                if (match) begin
                    next_state = reset_st;
                end
                else begin
                    next_state = detect_st;
                end
            end
        endcase
    end

    assign out = match;
    assign load_pattern = (pattern_valid && pattern_ready);
endmodule