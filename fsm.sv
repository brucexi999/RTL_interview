module fsm (
    input i1, i2, i3, i4, clk, n_rst,
    output reg err, n_o1, o2, o3, o4
);
    typedef enum {
        STATE_IDLE,
        STATE_1,
        STATE_2,
        STATE_3,
        STATE_ERROR
    } state_type;

    state_type current_state, next_state;

    always@(posedge clk or negedge n_rst) begin
        if (~n_rst) begin
            current_state <= STATE_IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end

    always@(*) begin
        n_o1 = 1;
        o2 = 0;
        o3 = 0;
        o4 = 0;
        err = 0;
        case (current_state)
        STATE_IDLE: begin
            if (i1 & i2) 
                next_state = STATE_1;
            else if (i1 & ~i2 & i3)
                next_state = STATE_2;
            else if (~i1)
                next_state = STATE_IDLE; 
            else
                next_state = STATE_ERROR;
        end

        STATE_1: begin
            n_o1 = 0;
            o2 = 1;

            if (~i2)
                next_state = STATE_1;
            else if (i2 & i3) 
                next_state = STATE_2;
            else if (i2 & ~i3 & i4)
                next_state = STATE_3;
            else 
                next_state = STATE_ERROR;
        end

        STATE_2: begin
            o2 = 1;
            o3 = 1;

            if (i3)
                next_state = STATE_2;
            else if (~i3 & i4) 
                next_state = STATE_3;
            else 
                next_state = STATE_ERROR;
        end

        STATE_3: begin
            o4 = 1;

            if (~i1)
                next_state = STATE_IDLE;
            else if (i1 & ~i2) 
                next_state = STATE_3;
            else 
                next_state = STATE_ERROR;
        end

        STATE_ERROR: begin
            err = 1;

            if (~i1) 
                next_state = STATE_IDLE;
            else 
                next_state = STATE_ERROR;
        end

        default: next_state = STATE_IDLE;
        endcase
    end
endmodule