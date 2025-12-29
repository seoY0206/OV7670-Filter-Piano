`timescale 1ns / 1ps

module red_finger_tracker (
    input  wire       clk,
    input  wire       reset,
    input  wire       vsync,
    input  wire       href,
    input  wire [9:0] pixel_x,
    input  wire [9:0] pixel_y,
    input  wire [3:0] r_in,
    input  wire [3:0] g_in,
    input  wire [3:0] b_in,
    output reg  [9:0] center_x,
    output reg  [9:0] center_y
);
    localparam [4:0] MIN_BRIGHTNESS = 5'd7;
    localparam [4:0] COLOR_MARGIN = 5'd6;
    localparam [4:0] MAX_OTHER_COLOR = 5'd6;
    wire [4:0] r_val = {1'b0, r_in};
    wire [4:0] g_val = {1'b0, g_in};
    wire [4:0] b_val = {1'b0, b_in};
    wire [4:0] g_limit = g_val + COLOR_MARGIN;
    wire [4:0] b_limit = b_val + COLOR_MARGIN;
    wire       raw_is_red;
    reg  [7:0] shift_reg;
    wire       clean_red;
    reg [9:0] x_min, x_max;
    reg [9:0] y_min, y_max;
    reg  vsync_d;
    wire frame_done;

    assign raw_is_red = href && (r_val > MIN_BRIGHTNESS) && (r_val > g_limit) && (r_val > b_limit) && (g_val < MAX_OTHER_COLOR) && (b_val < MAX_OTHER_COLOR);
    always @(posedge clk) begin
        if (reset) shift_reg <= 0;
        else begin
            if (href) shift_reg <= {shift_reg[6:0], raw_is_red};
            else shift_reg <= 0;
        end
    end

    assign clean_red = (shift_reg == 8'b1111_1111);
    always @(posedge clk) vsync_d <= vsync;
    assign frame_done = (vsync_d && !vsync);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            center_x <= 0;
            center_y <= 0;
            x_min <= 639;
            x_max <= 0;
            y_min <= 479;
            y_max <= 0;
        end else begin
            if (frame_done) begin
                if ((x_max > x_min + 10) && (y_max > y_min + 10)) begin
                    center_x <= ({1'b0, x_min} + {1'b0, x_max}) >> 1;
                    center_y <= ({1'b0, y_min} + {1'b0, y_max}) >> 1;
                end
                x_min <= 639;
                x_max <= 0;
                y_min <= 479;
                y_max <= 0;
            end else if (clean_red) begin
                if (pixel_x < x_min) x_min <= pixel_x;
                if (pixel_x > x_max) x_max <= pixel_x;
                if (pixel_y < y_min) y_min <= pixel_y;
                if (pixel_y > y_max) y_max <= pixel_y;
            end
        end
    end

endmodule
