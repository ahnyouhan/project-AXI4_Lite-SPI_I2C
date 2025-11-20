`timescale 1ns / 1ps

module tb_spi_master ();
    logic       clk;
    logic       reset;
    logic       start;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic       tx_ready;
    logic       done;
    logic       sclk;
    logic       mosi;
    logic       miso;
    logic       loop_wire;

    spi_master dut (.*,
        .mosi(loop_wire),
        .miso(loop_wire)
    );

    always #5 clk = ~clk;
    initial begin
        clk   = 0;
        reset = 1;
        #10;
        reset = 0;
    end

    task automatic spi_write(byte data);
        repeat (5) @(posedge clk);

        @(posedge clk);
        wait(tx_ready);
        start  = 1'b1;
        tx_data = data;
        @(posedge clk);
        start = 0;
        wait(done);
        @(posedge clk);
    endtask

    initial begin
        repeat (5) @(posedge clk);
        spi_write(8'hf0);
        spi_write(8'h0f);
        spi_write(8'haa);
        spi_write(8'h55);
        #20; $finish;
    end

endmodule
