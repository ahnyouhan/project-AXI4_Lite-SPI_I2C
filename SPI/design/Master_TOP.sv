`timescale 1ns / 1ps

module Master_TOP (
    input logic clk,
    input logic reset,

    input logic btn_L,  // clear
    input logic btn_R,  // run/stop

    // External SPI ports
    output logic sclk,
    output logic mosi,
    input  logic miso,
    output logic ss_n
);

    logic       start;
    logic [7:0] tx_data, rx_data;
    logic       ready;
    logic       done;
    logic       w_btn_L, w_btn_R;

    button_debounce U_BTN_L(
        .clk(clk),
        .rst(reset),
        .i_btn(btn_L),
        .o_btn(w_btn_L)
    );
    button_debounce U_BTN_R(
        .clk(clk),
        .rst(reset),
        .i_btn(btn_R),
        .o_btn(w_btn_R)
    );

    up_counter U_UP_COUNTER (
        .clk     (clk),
        .reset   (reset),
        .btn_L   (w_btn_L),
        .btn_R   (w_btn_R),
        .tx_ready(ready),
        .done    (done),
        .tx_data (tx_data),
        .start   (start),
        .ss_n    (ss_n)
    );

    spi_master U_SPI_MASTER (
        .clk     (clk),
        .reset   (reset),
        .start   (start),
        .tx_data (tx_data),
        .rx_data (rx_data),
        .tx_ready(ready),
        .done    (done),
        .sclk    (sclk),
        .mosi    (mosi),
        .miso    (miso)
    );



endmodule
