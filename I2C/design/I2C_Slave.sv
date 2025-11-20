`timescale 1ns / 1ps

module I2C_Slave #(
    parameter SLV_ADDR = 7'h24
) (
    input logic clk,
    input logic reset,
    input logic SCL,
    inout logic SDA,
    output logic [7:0] LED
);

    // SDA open-drain
    logic SDA_en, SDA_out;
    assign SDA = SDA_en ? 1'bz : SDA_out;


    typedef enum logic [2:0] {
        IDLE,
        START,
        DATA_CL0,
        DATA_CL1,
        ACK_CL0,
        ACK_CL1
    } state_t;

    state_t state, next_state;


    logic [7:0] shift, shift_next;
    logic [2:0] bit_counter, bit_counter_next;

    logic first_byte, first_byte_next;
    logic addr_ok, addr_ok_next;
    logic rw_bit, rw_bit_next;


    logic scl_d0, scl_d1;
    logic sda_d0, sda_d1;

    always_ff @(posedge clk) begin
        scl_d0 <= SCL;
        scl_d1 <= scl_d0;

        sda_d0 <= SDA;
        sda_d1 <= sda_d0;
    end

    wire scl_rise = (scl_d0 & ~scl_d1);
    wire scl_fall = (~scl_d0 & scl_d1);
    wire sda_rise = (sda_d0 & ~sda_d1);
    wire sda_fall = (~sda_d0 & sda_d1);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state       <= IDLE;
            shift       <= 0;
            bit_counter <= 0;
            first_byte  <= 1;
            addr_ok     <= 0;
            rw_bit      <= 0;
            LED         <= 8'h00;
        end else begin
            state       <= next_state;
            shift       <= shift_next;
            bit_counter <= bit_counter_next;
            first_byte  <= first_byte_next;
            addr_ok     <= addr_ok_next;
            rw_bit      <= rw_bit_next;


            if (state == DATA_CL1 &&
                bit_counter == 3'd7 &&
                first_byte == 1'b0 &&      // 두 번째 바이트
                addr_ok == 1'b1 &&  // 주소 OK
                rw_bit == 1'b0)            // write 동작일 때만
            begin
                LED <= shift;
            end
        end
    end



    always_comb begin
        next_state       = state;
        shift_next       = shift;
        bit_counter_next = bit_counter;
        first_byte_next  = first_byte;
        addr_ok_next     = addr_ok;
        rw_bit_next      = rw_bit;

        SDA_en           = 1;
        SDA_out          = 1;

        case (state)

            IDLE: begin
                bit_counter_next = 0;
                first_byte_next  = 1;
                addr_ok_next     = 0;

                if (sda_fall && SCL) next_state = START;
            end
            START: begin
                if (scl_fall) next_state = DATA_CL0;
            end

            DATA_CL0: begin
                if (scl_rise) begin
                    shift_next = {shift[6:0], SDA};
                    next_state = DATA_CL1;
                end
            end

            DATA_CL1: begin
                if (sda_rise && SCL) next_state = IDLE;

                if (scl_fall) begin
                    if (bit_counter == 3'd7) begin
                        next_state       = ACK_CL0;
                        bit_counter_next = 0;

                        if (first_byte) begin
                            first_byte_next = 0;

                            if (shift[7:1] == SLV_ADDR) begin
                                addr_ok_next = 1;
                                rw_bit_next  = shift[0];
                            end else begin
                                addr_ok_next = 0;
                            end
                        end
                    end else begin
                        bit_counter_next = bit_counter + 1;
                        next_state = DATA_CL0;
                    end
                end
            end

            ACK_CL0: begin
                if (scl_rise) begin
                    SDA_en = 0;
                    SDA_out = addr_ok ? 1'b0 : 1'b1;
                    next_state = ACK_CL1;
                end
            end


            ACK_CL1: begin
                SDA_en  = 0;
                SDA_out = 0;

                if (sda_rise && SCL) next_state = IDLE;

                else if (scl_fall) begin
                    SDA_en = 1;
                    next_state = DATA_CL0;
                end
            end

        endcase
    end

endmodule
