`timescale 1ns / 1ps

module Threshold_Filter_4bit_InOut (
    input  logic [3:0]   i_r, 
    input  logic [3:0]   i_g, 
    input  logic [3:0]   i_b, 
    output logic [3:0]   o_r, 
    output logic [3:0]   o_g, 
    output logic [3:0]   o_b  
);

    localparam THRESHOLD = 4'd8; 
    
    logic [5:0] sum_rgb; 
    logic [3:0] avg_luminance;

    assign sum_rgb = i_r + i_g + i_b;
    assign avg_luminance = sum_rgb / 3; 

    logic [3:0] binary_val; 
    assign binary_val = (avg_luminance > THRESHOLD) ? 4'hF : 4'h0;
    
    assign o_r = binary_val;
    assign o_g = binary_val;
    assign o_b = binary_val;

endmodule
