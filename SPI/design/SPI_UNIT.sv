`timescale 1ns / 1ps


module SPI_UNIT(
    input  logic clk,
    input  logic reset,
    
    input logic btn_L,  // clear
    input logic btn_R,  // run/stop

    input  logic [7:0] tx_data,

    // -------------------------
    // External SPI ports
    //master
    output logic sclk_m,
    output logic mosi_m,
    output logic ss_n_m,
    
    //slave
    input logic sclk_s,
    input logic mosi_s,
    input logic ss_n_s,
    // -------------------------

    //fnd
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data

);

    
Master_TOP U_Master_TOP(
    .clk(clk),
    .reset(reset),
    .btn_L(btn_L),
    .btn_R(btn_R),
    .sclk(sclk_m),
    .mosi(mosi_m),
    .miso(),
    .ss_n(ss_n_m)
);

Slave_TOP U_Slave_TOP(
    .clk(clk),
    .reset(reset),
    .sclk(sclk_s),
    .ss_n(ss_n_s),
    .mosi(mosi_s),
    .miso(),
    .tx_data(tx_data),
    .fnd_com(fnd_com),
    .fnd_data(fnd_data)
);

endmodule
