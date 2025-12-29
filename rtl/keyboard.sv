module keyboard (
    input  logic       de,
    input  logic [9:0] x,
    input  logic [9:0] y,
    input  logic [3:0] cam_r,
    input  logic [3:0] cam_g,
    input  logic [3:0] cam_b,
    output logic [3:0] out_r,
    output logic [3:0] out_g,
    output logic [3:0] out_b
);

    localparam int WHITE_Y_TOP = 250;
    localparam int WHITE_Y_BOTTOM = 479;
    localparam int BLACK_Y_TOP = 250;
    localparam int BLACK_Y_BOTTOM = 370;
    logic white_key;

    always_comb begin
        white_key = 0;
        if (y >= WHITE_Y_TOP && y <= WHITE_Y_BOTTOM) begin
            if ((x >= 40  && x <= 109) ||  
                (x >= 110 && x <= 179) ||  
                (x >= 180 && x <= 249) ||  
                (x >= 250 && x <= 319) ||  
                (x >= 320 && x <= 389) ||  
                (x >= 390 && x <= 459) ||  
                (x >= 460 && x <= 529) ||  
                (x >= 530 && x <= 599))
                white_key = 1;
        end
    end

    logic black_key;
    always_comb begin
        black_key = 0;

        if (y >= BLACK_Y_TOP && y <= BLACK_Y_BOTTOM) begin
            if ((x >= 86  && x <= 109) ||  
                (x >= 110 && x <= 133) ||  
                (x >= 156 && x <= 179) ||  
                (x >= 180 && x <= 203) ||  
                (x >= 296 && x <= 319) ||  
                (x >= 320 && x <= 343) ||  
                (x >= 366 && x <= 389) ||  
                (x >= 390 && x <= 413) ||  
                (x >= 436 && x <= 459) ||  
                (x >= 460 && x <= 483))
                black_key = 1;
        end
    end

    logic white_key_outline;
    always_comb begin
        white_key_outline = 0;
        if (y >= WHITE_Y_TOP && y <= WHITE_Y_BOTTOM) begin
            if (x == 40 || x == 110 || x == 180 || x == 250 || x == 320 || x == 390 || x == 460 || x == 530 || x == 599) white_key_outline = 1;
        end
    end

    logic outside_key;
    always_comb begin
        outside_key = 0;
        if (y >= WHITE_Y_TOP && y <= WHITE_Y_BOTTOM) begin
            if ((x >= 0 && x <= 40) || (x >= 600 && x <= 640)) outside_key = 1;
        end
    end

    always_comb begin
        if (!de) begin
            out_r = 0;
            out_g = 0;
            out_b = 0;
        end else if (black_key) begin
            out_r = 0;
            out_g = 0;
            out_b = 0;
        end else if (white_key_outline) begin
            out_r = 0;
            out_g = 0;
            out_b = 0;
        end else if (white_key) begin
            out_r = 15;
            out_g = 15;
            out_b = 15;
        end else if (outside_key) begin
            out_r = 2;
            out_g = 2;
            out_b = 2;
        end else begin
            out_r = cam_r;
            out_g = cam_g;
            out_b = cam_b;
        end
    end

endmodule
