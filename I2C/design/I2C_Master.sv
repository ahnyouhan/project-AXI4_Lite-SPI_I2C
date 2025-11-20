`timescale 1ns / 1ps

module I2C_Master (
    input  logic       clk,
    input  logic       reset,

    input  logic       I2C_En,
    input  logic       I2C_Start,   // HOLD에서 다음 전송 시작 지시
    input  logic       I2C_Stop,    // HOLD에서 STOP 지시

    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       ready,
    output logic       tx_done,
    output logic       rx_done,
 
    inout  logic       SDA,
    output logic       SCL
);

    typedef enum {
        IDLE,
        START1, START2,
        DATA1, DATA2, DATA3, DATA4,
        READ1, READ2, READ3, READ4,
        W_ACK1, W_ACK2, W_ACK3, W_ACK4,
        R_ACK1, R_ACK2, R_ACK3, R_ACK4,
        HOLD,
        STOP1, STOP2
    } state_t;

    state_t state, next_state;

    logic [8:0] clk_counter_reg, clk_counter_next;   // 0~249
    logic [2:0] bit_counter_reg, bit_counter_next;   // 0~7
    logic [7:0] tx_data_reg,  tx_data_next;
    logic [7:0] rx_data_reg,  rx_data_next;


    logic SDA_en, SDA_out;

    assign SDA = (SDA_en) ? SDA_out : 1'bz;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state           <= IDLE;
            clk_counter_reg <= 0;
            tx_data_reg     <= 0;
            bit_counter_reg <= 0;
        end else begin
            state           <= next_state;
            clk_counter_reg <= clk_counter_next;
            tx_data_reg     <= tx_data_next;
            bit_counter_reg <= bit_counter_next;
        end
    end

    
    always_comb begin
        next_state        = state;
        clk_counter_next  = clk_counter_reg;
        bit_counter_next  = bit_counter_reg;
        tx_data_next      = tx_data_reg;

        tx_done           = 0;
        SDA_out           = 1'b1;
        //rx_done           = 0;
        ready             = 0;
        SCL               = 1'b0;
        SDA_en            = 1'b1;

        case (state)
            IDLE: begin
                SDA_en  = 1;
                SCL     = 1;
                SDA_out = 1;
                ready   = 1;
                
                if (I2C_Start && I2C_En) begin
                    next_state        = START1;
                    clk_counter_next  = 0;
                    tx_data_next      = tx_data;
                    bit_counter_next  = 0;
                end
            end

            START1: begin
                SDA_en  = 1;
                SDA_out = 0;
                SCL     = 1;

                if (clk_counter_reg == 499) begin
                    clk_counter_next = 0;
                    next_state       = START2;
                end else clk_counter_next = clk_counter_reg + 1;
            end

            START2: begin
                SDA_en  = 1;
                SDA_out = 0;
                SCL     = 0;

                if (clk_counter_reg == 499) begin
                    ready            = 1;
                    clk_counter_next = 0;
                    next_state       = HOLD;
                end else clk_counter_next = clk_counter_reg + 1;
            end

            HOLD: begin
                SDA_en  = 1;
                SDA_out = 0;
                SCL     = 0;  
                ready   = 1;
                tx_done = 0;

                if (I2C_En) begin
                    case ({
                        I2C_Start, I2C_Stop
                    })
                        2'b00: begin 
                            next_state = DATA1;
                            tx_data_next = tx_data;
                        end
                        2'b10: next_state = START1;
                        2'b01: next_state = STOP1;
                    endcase
                end
            end
            DATA1: begin
                SDA_en  = 1;
                SDA_out = tx_data_reg[7];
                SCL     = 0;

                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    next_state       = DATA2;
                end else clk_counter_next = clk_counter_reg + 1;
            end

            DATA2: begin
                SDA_en  = 1;
                SDA_out = tx_data_reg[7];
                SCL     = 1;

                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    next_state       = DATA3;
                end else clk_counter_next = clk_counter_reg + 1;
            end

            DATA3: begin
                SDA_en  = 1;
                SDA_out = tx_data_reg[7];
                SCL     = 1;

                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    next_state       = DATA4;
                end else clk_counter_next = clk_counter_reg + 1;
            end

            DATA4: begin
                SDA_en  = 1;
                SDA_out = tx_data_reg[7];
                SCL     = 0;

                if (clk_counter_reg == 249) begin
                    if (bit_counter_reg == 7) begin
                        next_state       = W_ACK1;
                        tx_done          = 1;
                        SDA_en           = 1'b0;
                        bit_counter_next = 0;
                        clk_counter_next = 0;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                        clk_counter_next = 0;
                        next_state       = DATA1;
                        tx_data_next     = {tx_data_reg[6:0], 1'b0};
                    end
                end else clk_counter_next = clk_counter_reg + 1;
            end

            W_ACK1: begin
                SDA_en = 0;
                SCL    = 0;

                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    next_state       = W_ACK2;
                end else clk_counter_next = clk_counter_reg + 1;
            end

            W_ACK2: begin
                SDA_en = 0;
                SCL    = 1;

                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    next_state       = W_ACK3;
                end else clk_counter_next = clk_counter_reg + 1;
            end

            W_ACK3: begin
                SDA_en = 0;
                SCL    = 1;

                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    next_state       = W_ACK4;
                end else clk_counter_next = clk_counter_reg + 1;
            end

            W_ACK4: begin
                SDA_en = 0;
                SCL    = 0;

                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    next_state       = HOLD;
                end else clk_counter_next = clk_counter_reg + 1;
            end

            READ1: begin
                SDA_en = 0;
                SCL    = 0;

                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    next_state       = READ2;
                end else clk_counter_next = clk_counter_reg + 1;
            end

            READ2: begin
                SDA_en = 0;
                SCL    = 1;

                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    rx_data_next     = {rx_data_reg[6:0], SDA};
                    next_state       = READ3;
                end else clk_counter_next = clk_counter_reg + 1;
            end

            READ3: begin
                SDA_en = 0;
                SCL    = 1;

                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    next_state       = READ4;
                end else clk_counter_next = clk_counter_reg + 1;
            end

            READ4: begin
                SDA_en = 0;
                SCL    = 0;

                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;

                    if (bit_counter_reg == 7) begin
                        bit_counter_next = 0;
                        next_state       = R_ACK1;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                        next_state       = READ1;
                    end
                end else clk_counter_next = clk_counter_reg + 1;
            end

            R_ACK1: begin
                SDA_en  = 1;
                SDA_out = 1;
                SCL     = 0;

                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    next_state       = R_ACK2;
                end else clk_counter_next = clk_counter_reg + 1;
            end

            R_ACK2: begin
                SDA_en  = 1;
                SDA_out = 1;
                SCL     = 1;

                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    next_state       = R_ACK3;
                end else clk_counter_next = clk_counter_reg + 1;
            end

            R_ACK3: begin
                SDA_en  = 1;
                SDA_out = 1;
                SCL     = 1;

                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    next_state       = R_ACK4;
                end else clk_counter_next = clk_counter_reg + 1;
            end

            R_ACK4: begin
                SDA_en  = 1;
                SDA_out = 1;
                SCL     = 0;

                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    rx_done          = 1;
                    next_state       = HOLD;
                end else clk_counter_next = clk_counter_reg + 1;
            end

            STOP1: begin
                SDA_en  = 1;
                SDA_out = 0;
                SCL     = 1;
                ready   = 0;
                tx_done = 0;

                if (clk_counter_reg == 499) begin
                    clk_counter_next = 0;
                    next_state       = STOP2;
                end else clk_counter_next = clk_counter_reg + 1;
            end

            STOP2: begin
                SDA_en  = 0;
                SDA_out = 1;
                SCL     = 1;
                ready   = 0;
                tx_done = 0;

                if (clk_counter_reg == 499) begin
                    clk_counter_next = 0;
                    next_state       = IDLE;
                end else clk_counter_next = clk_counter_reg + 1;
            end

        endcase
    end

endmodule
