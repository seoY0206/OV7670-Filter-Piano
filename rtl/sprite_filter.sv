`timescale 1ns / 1ps

module sprite_filter #(
    parameter SPRITE_X = 100,
    parameter SPRITE_Y = 200
) (
    input  logic        de,
    input  logic [ 9:0] x,
    input  logic [ 9:0] y,
    input  logic [11:0] sprite_rom[0:4095],  // 64x64 이미지
    output logic [ 3:0] r,
    output logic [ 3:0] g,
    output logic [ 3:0] b
);
    logic [11:0] pixel;
    int sx = x - SPRITE_X;
    int sy = y - SPRITE_Y;
    int idx = sy * 64 + sx;

    always_comb begin
        r = 0;
        g = 0;
        b = 0;

        if (de &&
            x >= SPRITE_X && x < SPRITE_X + 64 &&
            y >= SPRITE_Y && y < SPRITE_Y + 64
        ) begin

            pixel = sprite_rom[idx];
            r = pixel[11:8];
            g = pixel[7:4];
            b = pixel[3:0];
        end
    end
endmodule
