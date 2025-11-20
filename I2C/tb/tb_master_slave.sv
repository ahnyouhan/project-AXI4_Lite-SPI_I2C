// `timescale 1ns / 1ps

// module tb_i2c_master_slave ();

//     logic       clk;
//     logic       reset;
//     logic       I2C_En;
//     logic       I2C_Start;
//     logic       I2C_Stop;
//     logic [7:0] tx_data;
//     logic [7:0] rx_data;
//     logic       ready;
//     logic       tx_done;
//     logic       rx_done;
//     tri1        SDA;  // 풀업 포함
//     logic       SCL;

//     logic [7:0] LED;

//     // MASTER
//     I2C_Master dut1 (
//         .clk(clk),
//         .reset(reset),
//         .I2C_En(I2C_En),
//         .I2C_Start(I2C_Start),
//         .I2C_Stop(I2C_Stop),
//         .tx_data(tx_data),
//         .rx_data(rx_data),
//         .ready(ready),
//         .tx_done(tx_done),
//         .rx_done(rx_done),
//         .SDA(SDA),
//         .SCL(SCL)
//     );

//     // SLAVE
//     I2C_Slave dut2 (
//         .clk(clk),
//         .reset(reset),
//         .SCL(SCL),
//         .SDA(SDA),
//         .LED(LED)     // ★ LED 연결
//     );
//     // initial begin
//     //     clk = 0;
//     //     reset = 1;
//     //     I2C_En = 0;
//     //     I2C_Start = 0;
//     //     I2C_Stop = 0;

//     //     repeat (10) @(posedge clk);
//     //     reset = 0;

//     //     // ------ 하나의 I2C 트랜잭션 ------
//     //     I2C_En = 1;

//     //     // START
//     //     I2C_Start = 1;
//     //     @(posedge clk);
//     //     I2C_Start = 0;

//     //     // 1) 주소 바이트
//     //     tx_data   = 8'h48;  // addr + W
//     //     wait (tx_done);
//     //     wait (ready);

//     //     // 2) LED 데이터 바이트
//     //     tx_data = 8'h01;
//     //     wait (tx_done);
//     //     wait (ready);

//     //     // STOP
//     //     I2C_Stop = 1;
//     //     @(posedge clk);
//     //     I2C_Stop = 0;
//     //     // -----------------------------

//     //     repeat (2000) @(posedge clk);
//     // end


//     //     // 100MHz
//     //     always #5 clk = ~clk;

//     //     initial begin
//     //         clk       = 0;
//     //         reset     = 1;
//     //         I2C_En    = 0;
//     //         I2C_Start = 0;
//     //         I2C_Stop  = 0;
//     //         tx_data   = 0;

//     //         repeat (5) @(posedge clk);
//     //         reset = 0;
//     //         repeat (5) @(posedge clk);

//     //         I2C_Write(8'h48);
//     //         I2C_Write(8'h01);

//     //         repeat (2000) @(posedge clk);
//     //         $finish;
//     //     end

//     //     task automatic I2C_Write(input byte data);
//     //         begin
//     //             I2C_En = 1;
//     //             tx_data = data;

//     //             I2C_Start = 0;
//     //             I2C_Stop = 0;

//     //             // 1) 데이터 8bit 전송 완료 기다림
//     //             wait (tx_done == 1);
//     //             @(posedge clk);

//     //             // 2) ACK 4단계 끝나고 HOLD 진입할 때까지 기다림
//     //             wait (ready == 1);  // HOLD에서 ready=1

//     //             // 3) 이제 STOP을 준다 (ACK 끝난 확실한 시점)
//     //             I2C_Stop = 1;

//     //             repeat (500) @(posedge clk);
//     //             I2C_Stop = 0;
//     //         end
//     //     endtask


// endmodule

`timescale 1ns / 1ps

module tb_i2c_master_slave ();

    //-----------------------------------------
    // TB Signals
    //-----------------------------------------
    logic       clk;
    logic       reset;

    logic       I2C_En;
    logic       I2C_Start;
    logic       I2C_Stop;

    logic [7:0] tx_data;
    logic [7:0] rx_data;

    logic       ready;
    logic       tx_done;
    logic       rx_done;

    tri1        SDA;    // 풀업 포함
    logic       SCL;

    logic [7:0] LED;


    //-----------------------------------------
    // DUT: MASTER
    //-----------------------------------------
    I2C_Master dut1 (
        .clk(clk),
        .reset(reset),
        .I2C_En(I2C_En),
        .I2C_Start(I2C_Start),
        .I2C_Stop(I2C_Stop),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .ready(ready),
        .tx_done(tx_done),
        .rx_done(rx_done),
        .SDA(SDA),
        .SCL(SCL)
    );

    //-----------------------------------------
    // DUT: SLAVE
    //-----------------------------------------
    I2C_Slave dut2 (
        .clk(clk),
        .reset(reset),
        .SCL(SCL),
        .SDA(SDA),
        .LED(LED)
    );


    //-----------------------------------------
    // Clock : 100 MHz
    //-----------------------------------------
    always #5 clk = ~clk;


    //-----------------------------------------
    // TEST SEQUENCE
    //-----------------------------------------
    initial begin
        clk       = 0;
        reset     = 1;

        I2C_En    = 0;
        I2C_Start = 0;
        I2C_Stop  = 0;

        tx_data   = 8'h00;

        repeat (5) @(posedge clk);
        reset = 0;
        repeat (5) @(posedge clk);

        //-----------------------------------------------------
        // Write 테스트: 슬레이브 주소 {0x24,0} = 0x48, LED 데이터 0x01
        //-----------------------------------------------------
        I2C_Write2(8'h48, 8'h01);

        repeat (4000) @(posedge clk);
        $finish;
    end


    //=========================================================
    //  2-바이트 연속 전송 (START → Addr → ACK → Data → ACK → STOP)
    //=========================================================
    task automatic I2C_Write2(input byte addr, input byte data);
    begin
        I2C_En = 1;

        //--------------------------------------------------
        // 1) START + 첫 번째 바이트(주소+RW)
        //--------------------------------------------------
        tx_data = addr;

        I2C_Start = 1;
        @(posedge clk);
        I2C_Start = 0;

        // 전송 완료 기다림
        wait(tx_done == 1);
        @(posedge clk);

        // ACK 4단계 끝나고 ready(HOLD) 들어올 때까지 기다림
        wait(ready == 1);

        //--------------------------------------------------
        // 2) 두 번째 바이트(LED 데이터)
        //--------------------------------------------------
        tx_data = data;

        @(posedge clk);

        wait(tx_done == 1);
        @(posedge clk);

        wait(ready == 1);

    
        //--------------------------------------------------
        // 3) STOP
        //--------------------------------------------------
        I2C_Stop = 1;
        @(posedge clk);
        I2C_Stop = 0;

        repeat(20) @(posedge clk);
    end
    endtask

endmodule
