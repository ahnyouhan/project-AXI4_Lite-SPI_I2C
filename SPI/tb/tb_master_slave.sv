`timescale 1ns / 1ps

module tb_master_slave ();

    // --- 신호 선언 ---
    logic clk, reset;
    logic m_start, m_tx_ready, m_done;
    logic [7:0] m_tx_data, m_rx_data;
    logic spi_sclk, spi_mosi, spi_ss_n;
    logic [7:0] s_rx_data;
    logic s_done;

    // --- 모니터링 변수 ---
    logic [7:0] tb_captured_data;
    logic       tb_data_valid;

    // --- 클럭 생성 ---
    always #5 clk = ~clk;

    // --- 모듈 인스턴스 ---
    // Master (ss_n 포트가 없는 버전 가정, 없다면 추가 필요)
    spi_master u_master (
        .clk(clk), .reset(reset),
        .start(m_start), .tx_data(m_tx_data),
        .rx_data(m_rx_data), .tx_ready(m_tx_ready), .done(m_done),
        .sclk(spi_sclk), .mosi(spi_mosi), .miso(1'b0)
        // .ss_n(spi_ss_n) // Master에 ss_n이 있다면 주석 해제하고 아래 수동 제어 삭제
    );

    spi_slave u_slave (
        .clk(clk), .reset(reset),
        .sclk(spi_sclk), .ss_n(spi_ss_n), .mosi(spi_mosi),
        .rx_data(s_rx_data), .done(s_done)
    );

    // --- Slave 데이터 감시 프로세스 ---
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            tb_captured_data <= 8'h00;
            tb_data_valid    <= 1'b0;
        end else begin
            if (s_done) begin
                tb_captured_data <= s_rx_data;
                tb_data_valid    <= 1'b1;
            end else if (m_start) begin
                tb_data_valid <= 1'b0;
            end
        end
    end

    // --- 테스트 절차 ---
    initial begin
        clk = 0; reset = 1; m_start = 0; spi_ss_n = 1;
        #100 reset = 0;
        #20;

        $display("=== SPI Test Start ===");

        send_data(8'h55); check_result(8'h55);
        #50;
        send_data(8'hAA); check_result(8'hAA);
        #50;
        send_data(8'h12); check_result(8'h12);
        #20;
        send_data(8'h34); check_result(8'h34);

        $display("=== All Tests Passed! ===");
        $finish;
    end

    // --- 태스크 ---
    task send_data(input [7:0] data);
        begin
            wait(m_tx_ready); @(posedge clk);
            spi_ss_n = 0; // SS_N Active
            #20; // 안정화 대기
            m_tx_data = data; m_start = 1; @(posedge clk); m_start = 0;
            wait(m_done); @(posedge clk);
            #100; // 충분한 여유 시간
            spi_ss_n = 1; // SS_N Inactive
        end
    endtask

    task check_result(input [7:0] expected);
        begin
            fork : wait_capture
                wait(tb_data_valid);
                begin #20000; $display("[Error] Timeout!"); $stop; end
            join_any
            disable wait_capture;

            if (tb_captured_data === expected)
                $display("[Check] SUCCESS: Expected 0x%h, Received 0x%h", expected, tb_captured_data);
            else begin
                $display("[Check] FAILED: Expected 0x%h, Received 0x%h", expected, tb_captured_data);
                $stop;
            end
            @(posedge clk);
        end
    endtask

endmodule