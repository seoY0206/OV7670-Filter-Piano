module TX (
    input  logic       clk,
    input  logic       rst,
    input  logic       b_tick,
    input  logic       start,
    input  logic [7:0] tx_data,
    output logic       tx,
    output logic       tx_busy,
    output logic       tx_done
);

    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,   
        STOP
    } state_TX;

    state_TX s, ns;
    logic [3:0] tick_cnt_reg, tick_cnt_next;
    logic [2:0] bit_cnt_reg, bit_cnt_next;
    logic tx_reg, tx_next;
    logic tx_busy_reg, tx_busy_next;
    logic [7:0] tx_buf_reg, tx_buf_next;
    assign tx_busy = tx_busy_reg;
    assign tx = tx_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            s            <= IDLE;
            tick_cnt_reg <= 0;
            bit_cnt_reg  <= 0;
            tx_reg       <= 1;
            tx_busy_reg  <= 0;
            tx_buf_reg   <= 0;
        end else begin
            s            <= ns;
            tick_cnt_reg <= tick_cnt_next;
            bit_cnt_reg  <= bit_cnt_next;
            tx_reg       <= tx_next;
            tx_busy_reg  <= tx_busy_next;
            tx_buf_reg   <= tx_buf_next;
        end
    end

    always_comb begin
        ns            = s;
        tick_cnt_next = tick_cnt_reg;
        bit_cnt_next  = bit_cnt_reg;
        tx_next       = tx_reg;
        tx_busy_next  = tx_busy_reg;
        tx_buf_next   = tx_buf_reg;
        tx_done       = 0;

        case (s)

            IDLE: begin
                tx_next      = 1;
                tx_busy_next = 0;
                tx_done      = 0;
                if (start) begin
                    tx_busy_next  = 1;
                    tx_buf_next   = tx_data;
                    tick_cnt_next = 0;
                    ns            = START;
                end
            end

            START: begin
                tx_next      = 0;
                tx_busy_next = 1;

                if (b_tick) begin
                    if (tick_cnt_reg == 15) begin
                        tick_cnt_next = 0;
                        bit_cnt_next  = 0;
                        ns            = DATA;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            DATA: begin
                tx_next      = tx_buf_reg[0];
                tx_busy_next = 1;

                if (b_tick) begin
                    if (tick_cnt_reg == 15) begin
                        tick_cnt_next = 0;
                        if (bit_cnt_reg == 7) begin
                            bit_cnt_next = 0;
                            ns           = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                            tx_buf_next  = tx_buf_reg >> 1;
                        end
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            STOP: begin
                tx_next      = 1;  
                tx_busy_next = 1;
                tx_done       = 1;
                if (b_tick) begin
                    if (tick_cnt_reg == 15) begin
                        tick_cnt_next = 0;
                        tx_busy_next  = 0;
                        ns            = IDLE;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

        endcase
    end

endmodule
