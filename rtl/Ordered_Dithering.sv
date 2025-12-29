`timescale 1ns / 1ps
module Ordered_Dithering_4bit_InOut (
    input  logic         clk,
    input  logic         reset,
    input  logic [9:0]   x_pixel,
    input  logic [9:0]   y_pixel,
    
    input  logic [3:0]   i_r, 
    input  logic [3:0]   i_g,
    input  logic [3:0]   i_b,
    
    output logic [3:0]   o_r, 
    output logic [3:0]   o_g,
    output logic [3:0]   o_b
);
    
    logic [3:0] G_current;
    assign G_current = i_g; 
    
    logic [3:0] dither_matrix [0:3][0:3];
    
    initial begin
        dither_matrix[0][0] = 4'h0; dither_matrix[0][1] = 4'h8;
        dither_matrix[0][2] = 4'h2; dither_matrix[0][3] = 4'hA;
        
        dither_matrix[1][0] = 4'hC; dither_matrix[1][1] = 4'h4;
        dither_matrix[1][2] = 4'hE; dither_matrix[1][3] = 4'h6;
        
        dither_matrix[2][0] = 4'h3; dither_matrix[2][1] = 4'hB;
        dither_matrix[2][2] = 4'h1; dither_matrix[2][3] = 4'h9;
        
        dither_matrix[3][0] = 4'hF; dither_matrix[3][1] = 4'h7;
        dither_matrix[3][2] = 4'hD; dither_matrix[3][3] = 4'h5;
    end
    
    logic [3:0] dither_threshold;
    logic [1:0] x_mod, y_mod;
    assign x_mod = x_pixel[1:0]; 
    assign y_mod = y_pixel[1:0]; 
    assign dither_threshold = dither_matrix[y_mod][x_mod];
    
    logic [3:0] Dither_Result;
    
    always_comb begin
        if (G_current > dither_threshold) begin
            Dither_Result = 4'hF;
        end else begin
            Dither_Result = 4'h0;
        end
    end
    
    assign o_r = Dither_Result;
    assign o_g = Dither_Result;
    assign o_b = Dither_Result;
endmodule