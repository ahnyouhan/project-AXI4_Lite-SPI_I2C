`timescale 1ns / 1ps
module tb_counter ();
     // ------------------------------------------------------
    // Clock / Reset
    // ------------------------------------------------------
    logic clk = 0;
    logic reset = 1;

    always #5 clk = ~clk;  // 100MHz

    // ------------------------------------------------------
    // Button Inputs
    // ------------------------------------------------------
    logic btn_L;
    logic btn_R;

    // ------------------------------------------------------
    // SPI wires (Master → Slave)
    // ------------------------------------------------------
    logic sclk_m, mosi_m, ss_n_m;
    logic sclk_s, mosi_s, ss_n_s;

    assign sclk_s = sclk_m;
    assign mosi_s = mosi_m;
    assign ss_n_s = ss_n_m;

    // ------------------------------------------------------
    // Slave outputs
    // ------------------------------------------------------
    logic [3:0] fnd_com;
    logic [7:0] fnd_data;

    // ------------------------------------------------------
    // DUT
    // ------------------------------------------------------
    SPI_UNIT DUT (
        .clk(clk),
        .reset(reset),

        .btn_L(btn_L),
        .btn_R(btn_R),

        .tx_data(8'h00),        // Slave_TOP tx_data 입력은 사용 안 함

        .sclk_m(sclk_m),
        .mosi_m(mosi_m),
        .ss_n_m(ss_n_m),

        .sclk_s(sclk_s),
        .mosi_s(mosi_s),
        .ss_n_s(ss_n_s),

        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

    // ------------------------------------------------------
    // OVERRIDE: up_counter tick speed for simulation
    // ------------------------------------------------------
    // 인스턴스 경로 = DUT.U_Master_TOP.U_UP_COUNTER.U_TICK_GEN_10HZ
    //defparam DUT.U_Master_TOP.U_UP_COUNTER.U_TICK_GEN_10HZ.TIME_COUNT = 100;

    // ------------------------------------------------------
    // TEST
    // ------------------------------------------------------
    initial begin
        $display("\n===== TB START : A → SPI → B 전달 검증 =====");

        btn_L = 0;
        btn_R = 0;

        repeat(5) @(posedge clk);
        reset = 0;

        // --------------------------------------------------
        // CLEAR
        // --------------------------------------------------
        $display("\n[TB] CLEAR 버튼");
        btn_L = 1; @(posedge clk);
        btn_L = 0;

        repeat(20) @(posedge clk);

        // --------------------------------------------------
        // RUN
        // --------------------------------------------------
        $display("\n[TB] RUN 시작 (up_counter 증가 + 전송 시작)");
        btn_R = 1;

        // 20회 cycle 관찰
        for (int i = 0; i < 20; i++) begin

            repeat(1000) @(posedge clk);  // counter가 10 tick마다 증가

            // Slave 내부 data_decoder counter 값 읽기
            $display("[%0t]  A:tx_data(H/L) = %02h , B:counter = %0d (FND=%h)",
                $time,
                DUT.U_Master_TOP.tx_data,
                DUT.U_Slave_TOP.counter,
                fnd_data
            );
        end

        $display("\n===== TB END =====\n");
        $stop;
    end
endmodule
