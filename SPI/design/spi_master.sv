`timescale 1ns / 1ps

module spi_master (
    // Global signals
    input  logic        clk,
    input  logic        reset,

    // Internal signals
    input  logic        start,
    input  logic [7:0]  tx_data,
    output logic [7:0]  rx_data,
    output logic        tx_ready,
    output logic        done, // clock-synchronous 1-cycle pulse

    // External SPI ports
    output logic        sclk,
    output logic        mosi,
    input  logic        miso
);

    // FSM states
    typedef enum logic [1:0] {
        IDLE,
        CP0,
        CP1
    } state_t;

    state_t state, next_state;

    // Internal registers
    logic [7:0] tx_data_reg, tx_data_next;
    logic [7:0] rx_data_reg, rx_data_next;
    logic [5:0] sclk_counter_reg, sclk_counter_next;
    logic [3:0] bit_counter_reg, bit_counter_next;

    logic done_reg, done_next;

    // Output assignments
    assign mosi    = tx_data_reg[7];
    assign rx_data = rx_data_reg;
    assign done    = done_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state            <= IDLE;
            tx_data_reg      <= 8'd0;
            rx_data_reg      <= 8'd0;
            sclk_counter_reg <= 6'd0;
            bit_counter_reg  <= 4'd0;
            done_reg         <= 1'b0;
        end else begin
            state            <= next_state;
            tx_data_reg      <= tx_data_next;
            rx_data_reg      <= rx_data_next;
            sclk_counter_reg <= sclk_counter_next;
            bit_counter_reg  <= bit_counter_next;
            done_reg         <= done_next;
        end 
    end

    always_comb begin
        // 기본값 초기화
        next_state          = state;
        tx_data_next        = tx_data_reg;
        rx_data_next        = rx_data_reg;
        sclk_counter_next   = sclk_counter_reg;
        bit_counter_next    = bit_counter_reg;
        

        tx_ready  = 1'b0;
        done_next = 1'b0;
        sclk      = 1'b0;

        case (state)
            IDLE: begin
                done_next           = 1'b0;
                tx_ready            = 1'b1;
                sclk_counter_next   = 0;
                bit_counter_next    = 0;

                if (start) begin
                    next_state      = CP0;
                    tx_data_next    = tx_data;
                end
            end
            CP0: begin
                sclk = 1'b0;
                if (sclk_counter_reg == 49) begin
                    rx_data_next        = {rx_data_reg[6:0], miso};
                    sclk_counter_next   = 0;
                    next_state          = CP1;
                end else begin
                    sclk_counter_next   = sclk_counter_reg + 1;
                end
            end
            CP1: begin
                sclk = 1'b1;
                if (sclk_counter_reg == 49) begin
                    sclk_counter_next = 0;

                    if (bit_counter_reg == 7) begin
                        bit_counter_next = 0;
                        done_next        = 1'b1;
                        next_state       = IDLE;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                        tx_data_next     = {tx_data_reg[6:0], 1'b0};
                        next_state       = CP0;
                    end
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
        endcase
    end

endmodule
