`timescale 1ns / 1ps

module cam_snow_filter (
    input logic       clk,
    input logic       reset,
    input logic       v_sync,
    input logic       DE,
    input logic [9:0] x,
    input logic [9:0] y,

    input logic [3:0] cam_r,
    input logic [3:0] cam_g,
    input logic [3:0] cam_b,

    output logic [3:0] out_r,
    output logic [3:0] out_g,
    output logic [3:0] out_b
);
    logic [ 9:0] snow_timer;
    logic        v_sync_d;
    logic [ 9:0] pile_base;
    logic [ 9:0] stack_counter;
    logic        falling_snow;
    logic        small_snow;
    logic        piled_snow;
    logic [15:0] rand_big;
    logic [15:0] rand_small;
    logic [ 4:0] wave_height;
    logic [9:0] peng_x;
    logic       peng_dir;

    assign rand_big = ((x >> 2) * 73) + (((y - snow_timer) >> 2) * 97);
    assign falling_snow = (rand_big[10:0] == 0);  // 속도
    assign rand_small = (x * 123) ^ (y * 91) ^ (snow_timer * 57);
    assign small_snow = (rand_small[9:0] == 10'h001);  //속도
    always_comb wave_height = (x[7] ? ~x[6:2] : x[6:2]) >> 1;
    assign piled_snow = (y < 250) && (y >= (250 - pile_base - wave_height));

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            snow_timer    <= 0;
            v_sync_d      <= 0;
            pile_base     <= 0;
            stack_counter <= 0;
        end else begin
            v_sync_d <= v_sync;
            if (v_sync && !v_sync_d) begin
                snow_timer <= snow_timer + 1;
                if (pile_base < 180) begin
                    if (stack_counter == 40) begin
                        pile_base     <= pile_base + 1;
                        stack_counter <= 0;
                    end else begin
                        stack_counter <= stack_counter + 1;
                    end
                end
            end
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            peng_x   <= 200;
            peng_dir <= 1;
        end else if (v_sync && !v_sync_d) begin
            if (peng_dir) peng_x <= peng_x + 1;
            else peng_x <= peng_x - 1;

            if (peng_x >= 560) peng_dir <= 0;
            else if (peng_x <= 40) peng_dir <= 1;
        end
    end

    function automatic bit [11:0] penguin40(input int dx, input int dy);
        bit [11:0] p;
        if (dx < 0 || dx >= 40 || dy < 0 || dy >= 40) return 12'h000;
        p = 12'h000;
        if ((dy == 4 && dx >= 14 && dx <= 25) || (dy == 5 && dx >= 12 && dx <= 27) || (dy == 6 && dx >= 11 && dx <= 28)) p = 12'hF00;
        if (dy == 7 && dx >= 11 && dx <= 28) p = 12'hFFF;
        if (dy >= 8 && dy <= 18 && dx >= 12 && dx <= 27) p = 12'hFFF;
        if ((dy >= 11 && dy <= 13) && (dx == 16 || dx == 23)) p = 12'hFFF;
        if ((dy == 12) && (dx == 17 || dx == 22)) p = 12'h001;
        if (dy >= 14 && dy <= 16 && dx >= 17 && dx <= 22) p = 12'hFA0;
        if ((dy >= 19 && dy <= 21 && dx >= 12 && dx <= 27) || (dy >= 22 && dy <= 25 && dx >= 26 && dx <= 28)) p = 12'hF00;
        if (dy >= 22 && dy <= 32 && dx >= 12 && dx <= 27) p = 12'hFFF;
        if ((dy >= 19 && dy <= 32) && (dx >= 8 && dx <= 11)) p = 12'h001;
        if ((dy >= 19 && dy <= 32) && (dx >= 28 && dx <= 31)) p = 12'h001;
        if (dy >= 33 && dy <= 35 && dx >= 14 && dx <= 25) p = 12'hFA0;
        if (dy == 4 && dx >= 14 && dx <= 33) p = 12'h001;
        if ((dx == 12 || dx == 35) && dy >= 8 && dy <= 12) p = 12'h001;
        if (dx == 12 && dy >= 12 && dy <= 22) p = 12'h001;
        if (dx == 35 && dy >= 12 && dy <= 22) p = 12'h001;
        if ((dx == 17 || dx == 31) && dy >= 30 && dy <= 45) p = 12'h001;
        return p;
    endfunction
    int dx = x - peng_x;
    int dy = y - 155;
    bit [11:0] peng_px;
    always_comb peng_px = penguin40(dx, dy);
    always_comb begin
        if (!DE) begin
            out_r = 0;
            out_g = 0;
            out_b = 0;
        end else if (peng_px != 12'h000) begin
            out_r = peng_px[11:8];
            out_g = peng_px[7:4];
            out_b = peng_px[3:0];
        end else if (piled_snow) begin
            out_r = 4'hF;
            out_g = 4'hF;
            out_b = 4'hF;
        end else if (falling_snow) begin
            if ((x % 3 == 0) || (y % 3 == 0)) begin
                out_r = 4'hF;
                out_g = 4'hF;
                out_b = 4'hF;
            end else begin
                out_r = cam_r;
                out_g = cam_g;
                out_b = cam_b;
            end
        end else if (small_snow) begin
            case (rand_small[1:0])
                2'b00: begin
                    out_r = 4'hF;
                    out_g = 4'h2;
                    out_b = 4'h0;
                end
                2'b01: begin
                    out_r = 4'h2;
                    out_g = 4'hF;
                    out_b = 4'h0;
                end
                2'b10: begin
                    out_r = 4'hF;
                    out_g = 4'h6;
                    out_b = 4'h0;
                end
                default: begin
                    out_r = 4'h0;
                    out_g = 4'hF;
                    out_b = 4'h5;
                end
            endcase
        end else begin
            out_r = cam_r;
            out_g = cam_g;
            out_b = cam_b;
        end
    end

endmodule

