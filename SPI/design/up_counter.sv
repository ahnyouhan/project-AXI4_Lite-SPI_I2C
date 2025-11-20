`timescale 1ns / 1ps


module up_counter (
    input logic clk,
    input logic reset,
    input logic btn_L,  // clear
    input logic btn_R,  // run/stop

    input  logic       tx_ready,
    input  logic       done,
    output logic [7:0] tx_data,
    output logic       start,
    output logic       ss_n
);

    logic        w_tick_10hz;
    logic [13:0] counter;
    logic w_enable, w_clear;

    //button debounce

    tick_gen_10hz U_TICK_GEN_10HZ (
        .clk(clk),
        .reset(reset),
        .o_clk_10hz(w_tick_10hz)
    );

    control_unit U_CTRL_UNIT(
        .clk(clk),
        .reset(reset),
        .btn_L(btn_L),   // db시 w_btn_
        .btn_R(btn_R),
        .o_enable(w_enable),
        .o_clear(w_clear)
    );

    counter_10000 U_COUNTER_10000(
        .i_tick(w_tick_10hz),
        .clk(clk),
        .reset(reset),
        .clear(w_clear),
        .enable(w_enable),
        .counter(counter)
    );

    typedef enum logic [2:0] {
        IDLE,
        LATCH,
        SEND_HIGH,
        DONE_1,
        READY,
        SEND_LOW,
        DONE_2
    } state_t;
    state_t state, next_state;

    logic [13:0] temp_counter;
    logic start_reg, start_next;
    assign start = start_reg;

    logic [7:0] tx_data_reg, tx_data_next;
    assign tx_data = tx_data_reg;

    logic ss_n_reg, ss_n_next;
    assign ss_n = ss_n_reg;

    // tick edge detection
    logic tick_d;
    logic tick_posedge;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) tick_d <= 1'b0;
        else       tick_d <= w_tick_10hz;
    end
    assign tick_posedge = w_tick_10hz & ~tick_d;

    // 1. Sequential Logic
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            start_reg    <= 1'b0;
            temp_counter <= 14'd0;
            tx_data_reg  <= 8'd0;
            ss_n_reg     <= 1'b1;
        end else begin
            state        <= next_state;
            start_reg    <= start_next;
            tx_data_reg  <= tx_data_next;
            ss_n_reg     <= ss_n_next;
            
            if (state == LATCH) begin
                temp_counter <= counter;
            end
        end
    end

    // 2. Combinational Logic
    always_comb begin
        next_state   = state;
        start_next   = 1'b0;
        tx_data_next = tx_data_reg;
        ss_n_next    = 1'b1; // High (비활성)

        case (state)
            IDLE: begin
                if (tick_posedge && tx_ready) begin
                    next_state = LATCH;
                end
            end

            LATCH: begin
                next_state = SEND_HIGH;
            end

            SEND_HIGH: begin
                ss_n_next    = 1'b0; // 통신 시작
                tx_data_next = {2'b00, temp_counter[13:8]};
                start_next   = 1'b1;
                next_state   = DONE_1;
            end

            DONE_1: begin
                ss_n_next = 1'b0;
                if (done) next_state = READY;
            end

            READY: begin
                ss_n_next = 1'b0;
                if (tx_ready) next_state = SEND_LOW;
            end

            SEND_LOW: begin
                ss_n_next    = 1'b0;
                tx_data_next = temp_counter[7:0];
                start_next   = 1'b1;
                next_state   = DONE_2;
            end

            DONE_2: begin
                ss_n_next = 1'b0;
                if (done) next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end

endmodule

module control_unit (
    input  logic clk,
    input  logic reset,
    input  logic btn_L,
    input  logic btn_R,
    output logic o_enable,
    output logic o_clear
);

    logic state, next_state;
    logic enable_reg, enable_next, clear_reg, clear_next;

    assign o_enable = enable_reg;
    assign o_clear  = clear_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state      <= 1'b0;
            enable_reg <= 0;
            clear_reg  <= 0;
        end else begin
            state      <= next_state;
            enable_reg <= enable_next;
            clear_reg  <= clear_next;
        end
    end

    always_comb begin
        next_state  = state;
        enable_next = enable_reg;
        clear_next  = 1'b0;

        case (state)
            0: begin
                if (btn_L) clear_next = 1'b1;
                else if (btn_R) enable_next = ~enable_reg;
                next_state = 0;
            end
        endcase
    end
endmodule

module counter_10000 (
    input  logic        clk,
    input  logic        reset,
    input  logic        i_tick,
    input  logic        clear,
    input  logic        enable,  // 0:run  1:stop
    output logic [13:0] counter
);

    logic [13:0] r_counter;
    assign counter = r_counter;

    always_ff @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            r_counter <= 0;
        end else begin
            if (i_tick) begin
                if (enable) begin  // run
                    if (r_counter == 10_000 - 1) begin
                        r_counter <= 0;
                    end else begin
                        r_counter <= r_counter + 1;
                    end
                end else begin  // stop
                    r_counter <= r_counter;
                end
            end
        end
    end

endmodule

module tick_gen_10hz (
    input logic clk,
    input logic reset,
    output o_clk_10hz
);
    parameter TIME_COUNT = 10;//10_000_000;  // 10Mhz -> 10hz (100M/10M) = 10hz
    logic [$clog2(TIME_COUNT)-1:0] r_counter;
    logic r_tick;
    assign o_clk_10hz = r_tick;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            r_tick    <= 1'b0;
        end else begin
            if (r_counter == TIME_COUNT - 1) begin
                r_counter <= 0;
                r_tick <= 1'b1;
            end else begin
                r_counter <= r_counter + 1;
                r_tick    <= 1'b0;
            end


        end
    end
endmodule
