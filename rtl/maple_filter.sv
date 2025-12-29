`timescale 1ns / 1ps

module cam_maple_filter (
    input  logic       clk,
    input  logic       reset,
    input  logic       v_sync,
    input  logic       DE,
    input  logic [9:0] x,
    input  logic [9:0] y,
    input  logic [3:0] cam_r,
    input  logic [3:0] cam_g,
    input  logic [3:0] cam_b,
    output logic [3:0] out_r,
    output logic [3:0] out_g,
    output logic [3:0] out_b
);
    logic [9:0] snow_timer;
    logic [9:0] slow_timer;
    logic v_sync_d;
    logic [15:0] rand_big_q;
    logic [6:0] x_scaled = x[9:3];
    logic [6:0] y_scaled = y[9:3];
    logic [9:0] y_scaled_full = {3'b0, y_scaled};
    logic [3:0] speed_offset = rand_big_q[3:0];
    logic [9:0] varied_timer = slow_timer + {6'b0, speed_offset};
    logic [15:0] rand_big_next;
    logic falling_petal = (rand_big_q[6:0] == 0);

    assign rand_big_next = (({3'b0, x_scaled} - varied_timer) * 73) + ((y_scaled_full - varied_timer) * 97);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            snow_timer <= 0;
            v_sync_d   <= 0;
            rand_big_q <= 0;
            slow_timer <= 0;
        end else begin
            v_sync_d <= v_sync;
            if (DE) begin
                rand_big_q <= rand_big_next;
            end
            if (v_sync && !v_sync_d) begin
                snow_timer <= snow_timer + 1;
                if (snow_timer[2:0] == 3'b000) begin
                    slow_timer <= slow_timer + 1;
                end
            end
        end
    end

    localparam TREE_X1 = 550;
    localparam TREE_X2 = 70;
    localparam TREE_Y = 190;
    localparam SCALE = 4;
    bit [11:0] C_TRUNK = 12'h421;
    bit [11:0] C_YEL = 12'hFE0;
    bit [11:0] C_ORG = 12'hFA0;
    bit [11:0] C_RED = 12'hD40;

    function automatic bit [11:0] draw_maple_pixel(input int dx, input int dy);
        bit [11:0] p = 12'h000;
        if (dx < 0 || dx >= 16 || dy < 0 || dy >= 16) return 12'h000;
        if (dx >= 7 && dx <= 8 && dy >= 10 && dy <= 14) p = C_TRUNK;
        if (dy == 15 && dx >= 6 && dx <= 9) p = C_TRUNK;
        if ((dx == 6 && dy == 10) || (dx == 5 && dy == 9)) p = C_TRUNK;
        if ((dx == 9 && dy == 10) || (dx == 10 && dy == 9)) p = C_TRUNK;
        if (dy >= 1 && dy <= 3 && dx >= 5 && dx <= 10) p = C_YEL;
        if (dy == 2 && (dx == 4 || dx == 11)) p = C_YEL;
        if (dy == 4 && dx >= 6 && dx <= 9) p = C_YEL;
        if (dy >= 4 && dy <= 8 && dx >= 3 && dx <= 12) begin
            if (p != C_YEL) p = C_ORG;
        end
        if (dy == 5 && (dx == 2 || dx == 13)) p = C_ORG;

        if (dy >= 9 && dy <= 11 && dx >= 4 && dx <= 11) begin
            if (p != C_TRUNK) p = C_RED;
        end
        if (dy == 8 && (dx == 3 || dx == 12)) p = C_RED;
        if ((dx == 5 && dy == 7) || (dx == 10 && dy == 7)) p = C_RED;

        if (dx == 13 && dy == 3) p = C_YEL;
        if (dx == 2 && dy == 4) p = C_ORG;
        if (dx == 1 && dy == 6) p = C_RED;
        if (dx == 14 && dy == 7) p = C_RED;
        return p;

    endfunction

    int dx, dy;
    bit [11:0] tree_color;
    logic is_tree_pixel;

    always_comb begin
        tree_color = 12'h000;
        is_tree_pixel = 0;
        dx = 0;
        dy = 0;
        if (y >= TREE_Y && y < TREE_Y + (16 * SCALE)) begin
            if (x >= TREE_X1 && x < TREE_X1 + (16 * SCALE)) begin
                dx = (x - TREE_X1) / SCALE;
                dy = (y - TREE_Y) / SCALE;
                tree_color = draw_maple_pixel(dx, dy);
            end else if (x >= TREE_X2 && x < TREE_X2 + (16 * SCALE)) begin
                dx = (x - TREE_X2) / SCALE;
                dy = (y - TREE_Y) / SCALE;
                tree_color = draw_maple_pixel(dx, dy);
            end
        end
        if (tree_color != 12'h000) is_tree_pixel = 1;
    end

    always_comb begin
        if (!DE) begin
            out_r = 0;
            out_g = 0;
            out_b = 0;
        end else if (is_tree_pixel) begin
            out_r = tree_color[11:8];
            out_g = tree_color[7:4];
            out_b = tree_color[3:0];
        end else if (falling_petal) begin
            if (rand_big_q[2]) begin
                out_r = 4'hF;
                out_g = 4'hA;
                out_b = 4'h0;
            end else begin
                out_r = 4'hD;
                out_g = 4'h4;
                out_b = 4'h0;
            end
        end else begin
            out_r = cam_r;
            out_g = (cam_g * 3) >>> 2;
            out_b = (cam_b * 3) >>> 2;
        end
    end
endmodule
