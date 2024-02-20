module axi_stream_slave # (
    parameter DATA_WIDTH = 32,
    parameter DATA_BYTE_WIDTH = DATA_WIDTH/8,
    parameter IDLE_DURATION = 10,
    parameter READY_DURATION_1 = 200,
    parameter READY_DURATION_2 = 300
) (
    input clk,
    input rst_n,
    input valid,
    input [DATA_WIDTH-1:0] data,
    input [DATA_BYTE_WIDTH-1:0] keep,
    input last,
    output logic ready
);
    logic rst;
    logic [DATA_WIDTH-1:0] counter;

    always@(posedge clk) begin
        if (rst)
            counter <= 0;
        else
            counter <= counter + 1;
    end
    
    typedef enum {
        STATE_IDLE,
        STATE_READY_1,
        STATE_DEASSERTION,
        STATE_READY_2
    } state_type;
    
    state_type current_state, next_state;
    
    always@(posedge clk) begin
        if (rst)
            current_state <= STATE_IDLE;
        else
            current_state <= next_state;
    end

    always@(*) begin
        case (current_state)
            STATE_IDLE: begin
                ready = 0;
                next_state = STATE_IDLE;
                if (counter == IDLE_DURATION)
                    next_state = STATE_READY_1;
            end
            STATE_READY_1: begin
                ready = 1;
                next_state = STATE_READY_1;
                if (counter == IDLE_DURATION + READY_DURATION_1)
                    next_state = STATE_DEASSERTION;
            end
            STATE_DEASSERTION: begin
                ready = 0;
                next_state = STATE_READY_2;
            end
            STATE_READY_2: begin
                ready = 1;
                next_state = STATE_READY_2;
                if (counter == IDLE_DURATION + READY_DURATION_1 + READY_DURATION_2 + 1)
                    next_state = STATE_IDLE;
            end
            default: next_state = STATE_IDLE;
        endcase
    end

    assign rst = !rst_n;
endmodule