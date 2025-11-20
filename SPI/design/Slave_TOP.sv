`timescale 1ns / 1ps

module Slave_TOP(
    // Global signals
    input  logic        clk,      
    input  logic        reset,     
    input  logic        sclk,      
    input  logic        ss_n,      // Slave select (Active Low)

    // SPI data lines
    input  logic        mosi,      // Master Out Slave In
    output logic        miso,      // Master In Slave Out

    // Internal signals
    input  logic [7:0]  tx_data,

    // fnd signals 
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data
);

    logic [7:0]  rx_data;
    logic        done;
    
    logic [13:0] counter;

    spi_slave U_SPI_SLAVE(.*);
    data_decoder U_DATA_DECODER(.*);
    fnd_controller U_FND_CTRL(.*);

endmodule

module data_decoder (
    input logic clk,
    input logic reset,
    input logic [7:0] rx_data,
    input logic done,
    input logic ss_n,
    output logic [13:0] counter
);

    typedef enum logic[1:0]{
        HIGH, LOW
    } state_t;
    state_t state, next_state;
    logic [7:0] temp;

    always_ff @ (posedge clk, posedge reset) begin
        if(reset) begin
            state <= HIGH;
            temp <=8'd0;
            counter <= 14'd0;
        end else begin
            state <= next_state;
            if(done) begin
                if (state == HIGH) begin
                    temp <= rx_data;
                end else  if(state == LOW) begin
                    counter <= {temp[5:0], rx_data}; // 16 비트중 상위 14비트만
                end
                
            end
        end
    end
    
    always_comb begin
        next_state = state;
        case (state)
            HIGH:  if(done) next_state = LOW;
            LOW:   if(done) next_state = HIGH;
        endcase
    end
    
endmodule