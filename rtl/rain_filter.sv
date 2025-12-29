module cam_rain_filter (
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

    logic [ 9:0] rain_timer;
    logic        v_sync_d;
    logic [ 9:0] x_div2;
    logic [ 9:0] y_div2;
    logic [15:0] rand_rain;
    logic        is_raindrop;
    logic        is_rain_trail;
    logic [15:0] rand_trail, rand_trail2, rand_trail3, rand_trail4;
    logic trail_1, trail_2, trail_3, trail_4;
    logic [15:0] rand_splash;
    logic        is_splash;
    logic [ 1:0] speed_cnt;

    assign x_div2 = x >> 1;
    assign y_div2 = y >> 1;
    assign rand_rain = ((x_div2 * 73) + ((y_div2 + rain_timer * 4) * 97)) ^ (x_div2[3:0] << 8);
    assign is_raindrop = (rand_rain[10:0] == 0);
    assign rand_trail = ((x_div2 * 73) + ((y_div2 + rain_timer * 4 - 1) * 97)) ^ (x_div2[3:0] << 8);
    assign rand_trail2 = ((x_div2 * 73) + ((y_div2 + rain_timer * 4 - 2) * 97)) ^ (x_div2[3:0] << 8);
    assign rand_trail3 = ((x_div2 * 73) + ((y_div2 + rain_timer * 4 - 3) * 97)) ^ (x_div2[3:0] << 8);
    assign rand_trail4 = ((x_div2 * 73) + ((y_div2 + rain_timer * 4 - 4) * 97)) ^ (x_div2[3:0] << 8);
    assign trail_1 = (rand_trail[10:0] == 0);
    assign trail_2 = (rand_trail2[10:0] == 0);
    assign trail_3 = (rand_trail3[10:0] == 0);
    assign trail_4 = (rand_trail4[10:0] == 0);
    assign is_rain_trail = trail_1 | trail_2 | trail_3 | trail_4;
    assign rand_splash = (x * 127) ^ (rain_timer * 31);
    assign is_splash = (y >= 470) && (y <= 479) && (rand_splash[8:0] < 50);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            rain_timer <= 0;
            v_sync_d   <= 0;
        end else begin
            v_sync_d <= v_sync;
            if (v_sync && !v_sync_d) begin
                if (speed_cnt == 2) begin
                    rain_timer <= rain_timer + 1;
                    speed_cnt  <= 0;
                end else begin
                    speed_cnt <= speed_cnt + 1;
                end
            end
        end
    end

    function automatic bit [11:0] plankton_pixel(input int dx, input int dy);
        bit [11:0] p = 12'h000;
        if (dx < 0 || dx >= 24 || dy < 0 || dy >= 48) return 12'h000;
        if ((dx == 8 && dy >= 4 && dy <= 43) || (dx == 15 && dy >= 4 && dy <= 43) || (dy == 4 && dx >= 8 && dx <= 15) || (dy == 43 && dx >= 8 && dx <= 15))
            p = 12'h001;
        if ((dx == 9 || dx == 14) && dy >= 0 && dy <= 4) p = 12'h001;
        if ((dx >= 5 && dx <= 8) && (dy >= 18 && dy <= 28)) p = 12'h001;
        if ((dx >= 15 && dx <= 18) && (dy >= 18 && dy <= 28)) p = 12'h001;
        if (dx >= 9 && dx <= 14 && dy >= 6 && dy <= 41) p = 12'h0A3;
        if (dx >= 10 && dx <= 13 && dy >= 18 && dy <= 25) p = 12'hFF0;
        if (dx >= 11 && dx <= 12 && dy >= 20 && dy <= 23) p = 12'hF00;
        return p;
    endfunction

    function automatic bit [11:0] ps_pixel(input int dx, input int dy);
        bit [11:0] p = 12'h000;
        if (dx < 0 || dx >= 48 || dy < 0 || dy >= 48) return 12'h000;
        if (dx >= 4 && dx <= 20 && dy >= 6 && dy <= 22) p = 12'hF9A;
        if ((dx >= 9 && dx <= 11) && (dy >= 10 && dy <= 12)) p = 12'hFFF;
        if ((dx >= 13 && dx <= 15) && (dy >= 10 && dy <= 12)) p = 12'hFFF;
        if ((dx == 10) && (dy == 11)) p = 12'h001;
        if ((dx == 14) && (dy == 11)) p = 12'h001;
        if (dx >= 9 && dx <= 15 && dy == 15) p = 12'h001;
        if (dx >= 4 && dx <= 20 && dy >= 22 && dy <= 35) p = 12'hF9A;
        if (dx >= 4 && dx <= 20 && dy >= 32 && dy <= 38) p = 12'h2E4;
        if ((dx >= 10 && dx <= 12) && (dy >= 34 && dy <= 36)) p = 12'hA8F;
        if (dx >= 24 && dx <= 42 && dy >= 8 && dy <= 22) p = 12'hFF0;
        if ((dx >= 28 && dx <= 30) && (dy >= 12 && dy <= 14)) p = 12'hFFF;
        if ((dx >= 34 && dx <= 36) && (dy >= 12 && dy <= 14)) p = 12'hFFF;
        if ((dx == 29) && (dy == 13)) p = 12'h001;
        if ((dx == 35) && (dy == 13)) p = 12'h001;
        if (dx >= 30 && dx <= 36 && dy == 17) p = 12'h001;
        if (dx >= 24 && dx <= 42 && dy >= 22 && dy <= 27) p = 12'hFFF;
        if ((dx >= 32 && dx <= 34) && (dy >= 22 && dy <= 26)) p = 12'hF00;
        if (dx >= 24 && dx <= 42 && dy >= 27 && dy <= 36) p = 12'hB63;
        if ((dx >= 28 && dx <= 30) && (dy >= 36 && dy <= 38)) p = 12'h001;
        if ((dx >= 36 && dx <= 38) && (dy >= 36 && dy <= 38)) p = 12'h001;
        if ((dx >= 27 && dx <= 31) && (dy >= 38 && dy <= 40)) p = 12'h001;
        if ((dx >= 35 && dx <= 39) && (dy >= 38 && dy <= 40)) p = 12'h001;
        return p;
    endfunction

    logic signed [10:0] pdx, pdy;
    logic signed [10:0] sdx, sdy;
    logic [11:0] plank_px;
    logic [11:0] ps_px;

    always_comb begin
        pdx = x - 360;
        pdy = y - 200;
        plank_px = plankton_pixel(pdx, pdy);
        sdx = x - 200;
        sdy = y - 200;
        ps_px = ps_pixel(sdx, sdy);
    end
    always_comb begin
        if (!DE) begin
            out_r = 0;
            out_g = 0;
            out_b = 0;
        end else if (ps_px != 12'h000) begin
            out_r = ps_px[11:8];
            out_g = ps_px[7:4];
            out_b = ps_px[3:0];
        end else if (plank_px != 12'h000) begin
            out_r = plank_px[11:8];
            out_g = plank_px[7:4];
            out_b = plank_px[3:0];
        end else if (is_raindrop) begin
            out_r = 4'hC;
            out_g = 4'hD;
            out_b = 4'hF;
        end else if (is_rain_trail) begin
            out_r = (cam_r >> 1) + 4'h4;
            out_g = (cam_g >> 1) + 4'h5;
            out_b = (cam_b >> 1) + 4'h7;
        end else if (is_splash) begin
            out_r = 4'h8;
            out_g = 4'hA;
            out_b = 4'hE;
        end else begin
            out_r = (cam_r > 1) ? cam_r - 1 : 0;
            out_g = (cam_g > 1) ? cam_g - 1 : 0;
            out_b = cam_b;
        end
    end

endmodule
