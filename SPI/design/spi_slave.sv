`timescale 1ns / 1ps

module spi_slave (
    // Global signals
    input  logic       clk,
    input  logic       reset,
    input  logic       sclk,
    input  logic       ss_n,   // Slave select (Active Low)

    // SPI data lines
    input  logic       mosi,   // Master Out Slave In (데이터 수신용)
     output logic    miso,

    // Internal signals
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       done
);


    logic sclk_s0, sclk_s1;
    logic ss_s0,   ss_s1;
    logic mosi_s0, mosi_s1;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            sclk_s0 <= 0; sclk_s1 <= 0;
            ss_s0   <= 1; ss_s1   <= 1;
            mosi_s0 <= 0; mosi_s1 <= 0;
        end else begin
            sclk_s0 <= sclk;
            sclk_s1 <= sclk_s0;

            ss_s0   <= ss_n;
            ss_s1   <= ss_s0;

            mosi_s0 <= mosi;
            mosi_s1 <= mosi_s0;
        end
    end

    wire sclk_clean = sclk_s1;
    wire ss_clean   = ss_s1;
    wire mosi_clean = mosi_s1;



    typedef enum logic { IDLE, CP0 } state_t;
    state_t state, next_state;

    logic [7:0] rx_shift_reg, rx_shift_next;
    logic [2:0] bit_counter_reg, bit_counter_next; // 0~7 카운트 (3비트)

    logic [1:0] sclk_prev;
    logic       sclk_rise, sclk_fall;
    logic       done_next;
    logic [7:0] rx_data_next;

    // Edge Detection
    assign sclk_rise = (sclk_prev == 2'b01);
    assign sclk_fall = (sclk_prev == 2'b10);

    always_ff @(posedge clk, posedge reset) begin
        if (reset) sclk_prev <= 2'b00;
        else       sclk_prev <= {sclk_prev[0], sclk};
    end

    // Sequential Logic
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state           <= IDLE;
            rx_shift_reg    <= 8'd0;
            bit_counter_reg <= 3'd0;
            done            <= 1'b0;
            rx_data         <= 8'd0;
        end else begin
            state           <= next_state;
            rx_shift_reg    <= rx_shift_next;
            bit_counter_reg <= bit_counter_next;
            done            <= done_next;
            rx_data         <= rx_data_next;
        end
    end

    // Combinational Logic
    always_comb begin
        next_state       = state;
        rx_shift_next    = rx_shift_reg;
        bit_counter_next = bit_counter_reg;
        done_next        = 1'b0;
        rx_data_next     = rx_data;

        case (state)
            IDLE: begin
                if (!ss_clean) begin
                    next_state       = CP0;
                    bit_counter_next = 3'd0;
                    rx_shift_next    = 8'd0;
                end
            end

            CP0: begin
                if (ss_clean) begin
                    next_state = IDLE;
                end else begin  
                    // Rising Edge에서 MOSI 샘플링
                    if (sclk_rise) begin
                        rx_shift_next = {rx_shift_reg[6:0], mosi_clean};
                    end

                    // Falling Edge에서 비트 카운트
                    if (sclk_fall) begin
                        if (bit_counter_reg == 3'd7) begin
                            rx_data_next = {rx_shift_reg[6:0], mosi_clean}; // 마지막 비트 포함
                            //rx_data_next = rx_shift_reg;
                            done_next    = 1'b1;                      // 정확히 1클럭 High
                            next_state   = IDLE;
                        end else begin
                            bit_counter_next = bit_counter_reg + 3'd1;
                        end
                    end
                end
            end
        endcase
    end

endmodule