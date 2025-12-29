`timescale 1ns / 1ps

module cam_lightning_filter (
    input  logic       clk,
    input  logic       reset,
    input  logic       v_sync,
    input  logic [9:0] x,
    input  logic [9:0] y,
    input  logic       trigger,
    input  logic [3:0] cam_r,
    input  logic [3:0] cam_g,
    input  logic [3:0] cam_b,
    output logic [3:0] out_r,
    output logic [3:0] out_g,
    output logic [3:0] out_b
);
    logic v_sync_d;
    logic [9:0] frame_cnt;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            v_sync_d  <= 0;
            frame_cnt <= 0;
        end else begin
            v_sync_d <= v_sync;
            if (v_sync && !v_sync_d) begin

                frame_cnt <= frame_cnt + 1;
            end
        end
    end
    logic [5:0] lightning_phase;
    logic       is_flash;
    assign lightning_phase = frame_cnt[5:0];
    always_comb begin
        is_flash = 0;
        case (lightning_phase)
            6'd0, 6'd1:   is_flash = 1;
            6'd4, 6'd5:   is_flash = 1;
            6'd30, 6'd31: is_flash = 1;
            6'd33:        is_flash = 1;
            default:      is_flash = 0;
        endcase
    end
    logic [9:0] bolt_x;
    logic [3:0] bolt_width;
    logic       in_bolt;
    always_comb begin
        case (frame_cnt[6:5])
            2'd0: bolt_x = 160;
            2'd1: bolt_x = 320;
            2'd2: bolt_x = 480;
            2'd3: bolt_x = 240;
        endcase
    end
    logic signed [10:0] zigzag_offset;
    logic [9:0] bolt_center;
    always_comb begin
        case (y[5:3])
            3'd0: zigzag_offset = 0;
            3'd1: zigzag_offset = 8;
            3'd2: zigzag_offset = -5;
            3'd3: zigzag_offset = 12;
            3'd4: zigzag_offset = -3;
            3'd5: zigzag_offset = 15;
            3'd6: zigzag_offset = -8;
            3'd7: zigzag_offset = 5;
        endcase
        bolt_center = bolt_x + zigzag_offset;
        if (y < 50) bolt_width = 4;
        else if (y < 100) bolt_width = 3;
        else if (y < 180) bolt_width = 2;
        else bolt_width = 1;
        in_bolt = (y < 220) && (x >= bolt_center - bolt_width) && (x <= bolt_center + bolt_width) && (is_flash);
    end
    logic in_branch1, in_branch2;
    logic [9:0] branch1_x, branch2_x;
    logic        [ 9:0] bolt2_x;
    logic signed [10:0] zigzag2_offset;
    logic        [ 9:0] bolt2_center;
    logic               in_bolt2;
    always_comb begin
        branch1_x = bolt_center + ((y - 80) >> 1);
        in_branch1 = (y >= 80) && (y < 160) && (x >= branch1_x - 1) && (x <= branch1_x) && (is_flash);
        branch2_x = bolt_center - ((y - 120) >> 1);
        in_branch2 = (y >= 120) && (y < 200) && (x >= branch2_x) && (x <= branch2_x + 1) && (is_flash);
        bolt2_x = bolt_x + 200;
        if (bolt2_x > 600) bolt2_x = bolt2_x - 400;
        case (y[5:3])
            3'd0: zigzag2_offset = 4;
            3'd1: zigzag2_offset = -6;
            3'd2: zigzag2_offset = 10;
            3'd3: zigzag2_offset = -4;
            3'd4: zigzag2_offset = 12;
            3'd5: zigzag2_offset = -10;
            3'd6: zigzag2_offset = 6;
            3'd7: zigzag2_offset = -2;
        endcase
        bolt2_center = bolt2_x + zigzag2_offset;
        in_bolt2 = (y < 180) && (x >= bolt2_center - 1) && (x <= bolt2_center + 1) && (lightning_phase < 6);
    end
    bit [11:0] C_BLK = 12'h000;
    bit [11:0] C_YEL = 12'hFE0;
    bit [11:0] C_RED = 12'hF00;
    bit [11:0] C_BRN = 12'hA50;
    bit [11:0] C_WHT = 12'hFFF;
    function automatic bit [11:0] draw_pikachu(input int dx, input int dy);
        bit [11:0] p = 12'h000;
        if (dx < 0 || dx >= 32 || dy < 0 || dy >= 32) return 12'h000;
        if (dx >= 2 && dx <= 6 && dy >= 3 && dy <= 8) p = C_YEL;
        if (dx >= 19 && dx <= 24 && dy >= 5 && dy <= 10) p = C_YEL;
        if (dx >= 5 && dx <= 20 && dy >= 7 && dy <= 18) p = C_YEL;
        if (dx >= 6 && dx <= 22 && dy >= 18 && dy <= 28) p = C_YEL;
        if (dx >= 6 && dx <= 9 && dy >= 28 && dy <= 30) p = C_YEL;
        if (dx >= 18 && dx <= 21 && dy >= 28 && dy <= 30) p = C_YEL;
        if (dx >= 23 && dx <= 26 && dy >= 18 && dy <= 22) p = C_YEL;
        if (dx >= 25 && dx <= 29 && dy >= 14 && dy <= 18) p = C_YEL;
        if (dx >= 27 && dx <= 31 && dy >= 7 && dy <= 14) p = C_YEL;
        if (dx >= 1 && dx <= 4 && dy >= 0 && dy <= 3) p = C_BLK;
        if (dx >= 22 && dx <= 25 && dy >= 2 && dy <= 5) p = C_BLK;
        if (dy >= 11 && dy <= 13 && ((dx >= 6 && dx <= 8) || (dx >= 16 && dx <= 18))) p = C_BLK;
        if (dy == 11 && (dx == 7 || dx == 17)) p = C_WHT;
        if (dx >= 11 && dx <= 13 && dy == 14) p = C_BLK;
        if ((dx == 11 || dx == 14) && dy == 16) p = C_BLK;
        if (dx >= 12 && dx <= 13 && dy == 17) p = C_BLK;
        if (dy >= 14 && dy <= 17 && ((dx >= 4 && dx <= 6) || (dx >= 18 && dx <= 20))) p = C_RED;
        if (dx >= 20 && dx <= 24 && dy >= 22 && dy <= 24) p = C_BRN;
        if (dx >= 10 && dx <= 18 && dy == 20) p = C_BRN;
        if (dx >= 11 && dx <= 19 && dy == 24) p = C_BRN;

        return p;
    endfunction

    localparam PIKA_X = 260;
    localparam PIKA_Y = 175;
    localparam SCALE = 4;

    int pika_dx, pika_dy;
    bit [11:0] pika_px;

    always_comb begin
        pika_dx = 0;
        pika_dy = 0;
        pika_px = 12'h000;
        if (x >= PIKA_X && x < PIKA_X + (32 * SCALE) && y >= PIKA_Y && y < PIKA_Y + (32 * SCALE)) begin
            pika_dx = (x - PIKA_X) / SCALE;
            pika_dy = (y - PIKA_Y) / SCALE;
            pika_px = draw_pikachu(pika_dx, pika_dy);
        end
    end

    logic [3:0] dark_r, dark_g, dark_b;
    logic [4:0] sum_r, sum_g, sum_b;

    always_comb begin
        dark_r = cam_r >> 1;
        dark_g = cam_g >> 1;
        dark_b = (cam_b >> 1) + (cam_b >> 2);
        if (in_bolt || in_branch1 || in_branch2 || in_bolt2) begin
            out_r = 4'hF;
            out_g = 4'hF;
            out_b = 4'hC;
        end else if (pika_px != 12'h000) begin
            out_r = pika_px[11:8];
            out_g = pika_px[7:4];
            out_b = pika_px[3:0];
        end else if (is_flash) begin
            sum_r = cam_r + 3;
            sum_g = cam_g + 3;
            sum_b = cam_b + 3;
            out_r = (sum_r > 15) ? 4'd15 : sum_r[3:0];
            out_g = (sum_g > 15) ? 4'd15 : sum_g[3:0];
            out_b = (sum_b > 15) ? 4'd15 : sum_b[3:0];
        end else begin
            out_r = dark_r;
            out_g = dark_g;
            out_b = dark_b;
        end
    end
endmodule
