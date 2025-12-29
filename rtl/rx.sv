// module RX (
//     input logic clk,
//     input logic rst,
//     input logic rx,
//     input logic b_tick,
//     output logic rx_done,
//     output logic [7:0] rx_data
// );

//     typedef enum logic [1:0] {
//         IDLE,
//         START,
//         DATA,
//         STOP
//     } state_rx;

//     state_rx s, ns;

//     logic [3:0] tick_cnt_reg, tick_cnt_next;  // 0~15
//     logic [2:0] bit_cnt_reg, bit_cnt_next;  // 0~7
//     logic rx_done_reg, rx_done_next;
//     logic [7:0] rx_buf_reg, rx_buf_next;

//     assign rx_done = rx_done_reg;
//     assign rx_data = rx_buf_reg;

//     always @(posedge clk or posedge rst) begin
//         if (rst) begin
//             s            <= IDLE;
//             tick_cnt_reg <= 0;
//             bit_cnt_reg  <= 0;
//             rx_done_reg  <= 0;
//             rx_buf_reg   <= 0;
//         end else begin
//             s            <= ns;
//             tick_cnt_reg <= tick_cnt_next;
//             bit_cnt_reg  <= bit_cnt_next;
//             rx_done_reg  <= rx_done_next;
//             rx_buf_reg   <= rx_buf_next;
//         end
//     end


//     always @(*) begin
//         ns            = s;
//         tick_cnt_next = tick_cnt_reg;
//         bit_cnt_next  = bit_cnt_reg;
//         rx_done_next  = 0;  // default : 1클럭 펄스
//         rx_buf_next   = rx_buf_reg;

//         case (s)

//             IDLE: begin
//                 tick_cnt_next = 0;
//                 bit_cnt_next  = 0;

//                 if (!rx) begin  // START bit 감지
//                     ns = START;
//                 end
//             end

//             START: begin
//                 if (b_tick) begin
//                     tick_cnt_next = tick_cnt_reg + 1;

//                     if (tick_cnt_reg == 7) begin
//                         if (!rx) begin  // START bit 유효 확인
//                             tick_cnt_next = 0;
//                             ns = DATA;
//                         end else begin  // 잡음 → 다시 IDLE
//                             ns = IDLE;
//                         end
//                     end
//                 end
//             end

//             DATA: begin
//                 if (b_tick) begin
//                     tick_cnt_next = tick_cnt_reg + 1;

//                     // 중앙 샘플링 (tick = 7)
//                     if (tick_cnt_reg == 7) begin
//                         rx_buf_next = {rx, rx_buf_reg[7:1]};  // ★ MSB-first 저장

//                     end

//                     // 한 비트 완료 (tick = 15)
//                     if (tick_cnt_reg == 15) begin
//                         tick_cnt_next = 0;

//                         if (bit_cnt_reg == 7) begin
//                             bit_cnt_next = 0;
//                             ns = STOP;
//                         end else begin
//                             bit_cnt_next = bit_cnt_reg + 1;
//                         end
//                     end
//                 end
//             end

//             STOP: begin
//                 if (b_tick) begin
//                     tick_cnt_next = tick_cnt_reg + 1;

//                     // 중앙 샘플링
//                     if (tick_cnt_reg == 7) begin
//                         if (rx) begin
//                             rx_done_next = 1;  // 1클럭 펄스
//                         end
//                     end

//                     if (tick_cnt_reg == 15) begin
//                         tick_cnt_next = 0;
//                         ns = IDLE;
//                     end
//                 end
//             end

//         endcase
//     end
// endmodule

module RX #(
    parameter OVERSAMPLE = 16
)(
    input  wire clk,        // system clock
    input  wire rst,
    input  wire rx,         // uart receive
    input  wire b_tick,     // oversampling tick (baud*16)
    output reg  rx_done,    // 1clk pulse
    output reg [7:0] rx_data
);

    // ----------------------------
    // 1) Synchronize RX
    // ----------------------------
    reg rx_ff1, rx_ff2;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_ff1 <= 1'b1;
            rx_ff2 <= 1'b1;
        end else begin
            rx_ff1 <= rx;
            rx_ff2 <= rx_ff1;
        end
    end

    wire rx_d = rx_ff2;

    // ----------------------------
    // 2) States
    // ----------------------------
    localparam [1:0]
        IDLE  = 2'd0,
        START = 2'd1,
        DATA  = 2'd2,
        STOP  = 2'd3;

    reg [1:0] state, next_state;

    // sample counter (0~15)
    reg [3:0] tick_reg, tick_next;

    // bit counter (0~7)
    reg [2:0] bit_reg, bit_next;

    reg [7:0] data_reg, data_next;
    reg done_next;

    // ----------------------------
    // Sequential
    // ----------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            tick_reg  <= 0;
            bit_reg   <= 0;
            data_reg  <= 0;
            rx_done   <= 0;
            rx_data   <= 0;
        end else begin
            state     <= next_state;
            tick_reg  <= tick_next;
            bit_reg   <= bit_next;
            data_reg  <= data_next;
            rx_done   <= done_next;
            rx_data   <= data_reg;
        end
    end

    // ----------------------------
    // Combinational
    // ----------------------------
    always @(*) begin
        next_state = state;
        tick_next  = tick_reg;
        bit_next   = bit_reg;
        data_next  = data_reg;
        done_next  = 1'b0;

        case (state)

        //----------------------------------------
        // IDLE - wait for start bit (rx=0)
        //----------------------------------------
        IDLE: begin
            tick_next = 0;
            bit_next  = 0;

            if (rx_d == 1'b0) begin   // no start_edge needed
                next_state = START;
            end
        end

        //----------------------------------------
        // START bit
        //----------------------------------------
        START: begin
            if (b_tick) begin
                tick_next = tick_reg + 1;

                // sample exactly at center of bit
                if (tick_reg == (OVERSAMPLE/2)) begin
                    if (rx_d == 1'b0) begin
                        tick_next  = 0;
                        next_state = DATA;
                    end else begin
                        next_state = IDLE;
                    end
                end
            end
        end

        //----------------------------------------
        // DATA bits
        //----------------------------------------
        DATA: begin
            if (b_tick) begin
                tick_next = tick_reg + 1;

                if (tick_reg == (OVERSAMPLE/2)) begin
                    data_next = {rx_d, data_reg[7:1]};
                end

                if (tick_reg == OVERSAMPLE-1) begin
                    tick_next = 0;
                    if (bit_reg == 3'd7) begin
                        next_state = STOP;
                    end else begin
                        bit_next = bit_reg + 1;
                    end
                end
            end
        end

        //----------------------------------------
        // STOP bit
        //----------------------------------------
        STOP: begin
            if (b_tick) begin
                tick_next = tick_reg + 1;

                if (tick_reg == (OVERSAMPLE/2)) begin
                    if (rx_d == 1'b1) begin
                        done_next = 1'b1;   // valid byte
                    end
                end

                if (tick_reg == OVERSAMPLE-1) begin
                    tick_next  = 0;
                    next_state = IDLE;
                end
            end
        end

        endcase
    end

endmodule
