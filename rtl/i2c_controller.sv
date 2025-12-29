`timescale 1ns / 1ps

module i2c_controller (
    input  logic        clk,
    input  logic        reset,
    // rom port
    input  logic [15:0] data,
    output logic [ 6:0] addr,
    // i2c port
    input  logic        i2c_done,
    output logic [ 7:0] i2c_data,
    output logic        i2c_start,
    output logic        init_done
);

    typedef enum {
        IDLE,
        WAIT,
        LOAD,
        START,
        REG_BYTE,
        DATA_BYTE,
        DELAY,
        DONE
    } state_e;

    state_e state, state_next;
    logic [$clog2(20_000_000)-1:0] counter_reg, counter_next;
    logic [6:0] addr_reg, addr_next;
    logic [7:0] i2c_data_reg, i2c_data_next;


    assign addr     = addr_reg;
    assign i2c_data = i2c_data_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            counter_reg  <= 0;
            addr_reg     <= 0;
            i2c_data_reg <= 0;
        end else begin
            state        <= state_next;
            counter_reg  <= counter_next;
            addr_reg     <= addr_next;
            i2c_data_reg <= i2c_data_next;
        end
    end

    always_comb begin
        state_next    = state;
        counter_next  = counter_reg;
        addr_next     = addr_reg;
        i2c_data_next = i2c_data_reg;
        init_done     = 0;
        i2c_start     = 0;
        case (state)
            IDLE: begin
                counter_next = 0;
                addr_next    = 0;
                state_next   = WAIT;
            end
            WAIT: begin
                if (counter_reg == 20_000_000 - 1) begin  // 200ms wait
                    state_next   = START;
                    counter_next = 0;
                end else begin
                    counter_next = counter_reg + 1;
                end
            end
            START: begin
                i2c_start     = 1'b1;
                i2c_data_next = data[15:8];
                if (i2c_done) begin
                    i2c_data_next = data[7:0];
                    state_next    = REG_BYTE;
                end
            end
            REG_BYTE: begin
                i2c_start = 1'b0;
                if (i2c_done) begin
                    state_next = DATA_BYTE;
                end
            end
            DATA_BYTE: begin
                if (i2c_done) begin
                    addr_next  = addr_reg + 1;
                    state_next = DELAY;
                end
            end
            DELAY: begin
                if (counter_reg == 100_000 - 1) begin  // 10ms wait
                    counter_next = 0;
                    if (addr_reg < 75) begin
                        state_next = START;
                    end else begin
                        state_next = DONE;
                    end
                end else begin
                    counter_next = counter_reg + 1;
                end
            end
            DONE: begin
                init_done = 1;
            end
        endcase
    end
endmodule
