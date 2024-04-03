module Intel_LVDS_init (
    input clk, 
    input srstn,
    input interface_rst,
    input rx_locked,
    input rx_dpa_locked,

    output logic pll_areset,
    output logic rx_reset,
    output logic rx_fifo_reset,
    output logic rx_cda_reset
    );

    logic need_init_flag;

    typedef enum {
        user_mode_state,
        pll_rx_rst_state,
        monitor_rx_lock_state,
        monitor_rx_dpa_lock_state,
        rx_fifo_rst_state,
        rx_cda_rst_state,
        init_done_state
    } state_type;

    state_type current_state, next_state;

    always_ff@(posedge clk) begin
        if (!srstn)
            current_state <= user_mode_state;
        else
            current_state <= next_state;
    end

    always_comb begin
        pll_areset = 0;
        rx_reset = 0;
        rx_fifo_reset = 0;
        rx_cda_reset = 0;

        case (current_state)

        user_mode_state: begin
            if (need_init_flag || interface_rst)
                next_state = pll_rx_rst_state;
            else
                next_state = user_mode_state;
        end

        pll_rx_rst_state: begin
            pll_areset = 1;
            rx_reset = 1;
            next_state = monitor_rx_lock_state;
        end

        monitor_rx_lock_state: begin
            rx_reset = 1;
            if (rx_locked)
                next_state = monitor_rx_dpa_lock_state;
            else
                next_state = monitor_rx_lock_state;
        end

        monitor_rx_dpa_lock_state: begin
            if (rx_dpa_locked)
                next_state = rx_fifo_rst_state;
            else
                next_state = monitor_rx_dpa_lock_state;
        end

        rx_fifo_rst_state: begin
            rx_fifo_reset = 1;
            next_state = rx_cda_rst_state;
        end

        rx_cda_rst_state: begin
            rx_cda_reset = 1;
            next_state = init_done_state;
        end

        init_done_state: begin
            next_state = user_mode_state;
        end

        endcase
    end

    always@(posedge clk) begin
        if (!srstn)
            need_init_flag <= 1;
        else if (current_state == init_done_state)
            need_init_flag <= 0;
    end

endmodule