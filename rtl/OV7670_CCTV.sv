`timescale 1ns / 1ps

module OV7670_CCTV (
    input logic clk,
    input logic reset,


    output logic       xclk,
    input  logic       pclk,
    input  logic       href,
    input  logic       vsync,
    input  logic [7:0] data,
    input  logic       rx,

    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] r_port,
    output logic [3:0] g_port,
    output logic [3:0] b_port,


    output logic       SCL,
    inout  wire        SDA,
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data,


    output logic [15:0] led,
    input  logic        sw_mode,
    input  logic        sw_start,
    output logic        tx
);

    logic sys_clk;
    logic DE;
    logic [9:0] x_pixel, y_pixel;

    logic [16:0] rAddr, wAddr;
    logic [15:0] rData, wData;
    logic we;

    logic [3:0] w_r_cam, w_g_cam, w_b_cam;
    logic [3:0] w_r_out, w_g_out, w_b_out;

    logic [7:0] w_uart_data, w_tx_data;
    logic w_uart_start, w_sec_start;
    logic b_tick, tx_busy;
    logic fifo_push, fifo_pop, fifo_full, fifo_empty;
    logic [7:0] fifo_push_data, fifo_pop_data;

    logic [9:0] detected_x, detected_y;

    logic [3:0] kb_r, kb_g, kb_b;
    logic [3:0] cat1_r, cat1_g, cat1_b;
    logic [3:0] cat2_r, cat2_g, cat2_b;
    logic rx_done_tick, sound_enable;

    logic [11:0] cat_rom [0:4095];
    logic [11:0] cat2_rom[0:4095];
    logic [11:0] duck_rom[  0:11];


    initial $readmemh("cat_64x64.mem", cat_rom);
    initial $readmemh("cat2_64x64.mem", cat2_rom);
    initial $readmemh("duck_12x12.mem", duck_rom);


    assign xclk = sys_clk;

    fnd_controller U_FND (
        .clk     (clk),
        .reset   (reset),
        .dist1   (w_tx_data),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );

    i2c_top U_I2C_TOP (
        .clk  (clk),
        .reset(reset),
        .SCL  (SCL),
        .SDA  (SDA)
    );


    wire [7:0] rx_data;

    pixel_clk_gen U_PXL_CLK_GEN (
        .clk  (clk),
        .reset(reset),
        .pclk (sys_clk)
    );

    VGA_syncher U_VGA_Syncher (
        .clk    (sys_clk),
        .reset  (reset),
        .h_sync (h_sync),
        .v_sync (v_sync),
        .DE     (DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
    );

    wire [9:0] x_pixel_flipped = 639 - x_pixel;

    ImgMemReader_upscaler U_IMG_Reader (
        .DE     (DE),
        .x_pixel(x_pixel_flipped),
        .y_pixel(y_pixel),
        .addr   (rAddr),
        .imgData(rData),
        .r_port (w_r_cam),
        .g_port (w_g_cam),
        .b_port (w_b_cam)
    );

    frame_buffer U_Frame_Buffer (
        .wclk (pclk),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk (sys_clk),
        .oe   (1),
        .rAddr(rAddr),
        .rData(rData)
    );

    OV7670_Mem_Controller U_OV7670_Mem_Controller (
        .pclk (pclk),
        .reset(reset),
        .href (href),
        .vsync(vsync),
        .data (data),
        .we   (we),
        .wAddr(wAddr),
        .wdata(wData)
    );

    red_finger_tracker U_TRACKER (
        .clk     (sys_clk),
        .reset   (reset),
        .vsync   (v_sync),
        .href    (DE),
        .pixel_x (x_pixel),
        .pixel_y (y_pixel),
        .r_in    (w_r_cam),
        .g_in    (w_g_cam),
        .b_in    (w_b_cam),
        .center_x(detected_x),
        .center_y(detected_y)
    );

    piano_logic U_PIANO_LOGIC (
        .clk         (sys_clk),
        .reset       (reset),
        .vsync       (v_sync),
        .center_x    (detected_x),
        .center_y    (detected_y),
        .sound_enable(sound_enable),
        .tx_data     (w_tx_data),
        .tx_start    (w_sec_start)
    );

    keyboard U_KEYBOARD (
        .de   (DE),
        .x    (x_pixel),
        .y    (y_pixel),
        .cam_r(w_r_cam),
        .cam_g(w_g_cam),
        .cam_b(w_b_cam),
        .out_r(kb_r),
        .out_g(kb_g),
        .out_b(kb_b)
    );

    sprite_filter #(
        .SPRITE_X(150),
        .SPRITE_Y(240)
    ) CAT1 (
        .de        (DE),
        .x         (x_pixel),
        .y         (y_pixel),
        .sprite_rom(cat_rom),
        .r         (cat1_r),
        .g         (cat1_g),
        .b         (cat1_b)
    );

    sprite_filter #(
        .SPRITE_X(323),
        .SPRITE_Y(400)
    ) CAT2 (
        .de        (DE),
        .x         (x_pixel),
        .y         (y_pixel),
        .sprite_rom(cat2_rom),
        .r         (cat2_r),
        .g         (cat2_g),
        .b         (cat2_b)
    );

    DATA_SEC U_SEC (
        .clk      (clk),
        .rst      (reset),
        .in_data  (w_tx_data),
        .in_valid (w_sec_start),
        .out_data (w_uart_data),
        .out_valid(w_uart_start)
    );


    baud_tick U_tick (
        .clk   (clk),
        .rst   (reset),
        .b_tick(b_tick)
    );

    assign fifo_push      = w_uart_start & ~fifo_full;
    assign fifo_push_data = w_uart_data;
    assign fifo_pop       = ~tx_busy & ~fifo_empty;

    fifo U_FIFO_TX (
        .clk      (clk),
        .rst      (reset),
        .push     (fifo_push),
        .push_data(fifo_push_data),
        .pop      (fifo_pop),
        .pop_data (fifo_pop_data),
        .full     (fifo_full),
        .empty    (fifo_empty)
    );

    TX U_TX (
        .clk    (clk),
        .rst    (reset),
        .b_tick (b_tick),
        .start  (fifo_pop),
        .tx_data(fifo_pop_data),
        .tx     (tx),
        .tx_done(),
        .tx_busy(tx_busy)
    );

    logic fifo_empty_rx;
    logic fifo_full_rx;
    logic fifo_push_rx;
    logic [7:0] fifo_pop_rx_data;
    assign fifo_push_rx = rx_done_tick & ~fifo_full_rx;
    assign fifo_pop_rx  = ~fifo_empty_rx;

    fifo U_RX_FIFO (
        .clk      (clk),
        .rst      (reset),
        .push     (fifo_push_rx),
        .push_data(rx_data),
        .pop      (fifo_pop_rx),
        .pop_data (fifo_pop_rx_data),
        .full     (fifo_full_rx),
        .empty    (fifo_empty_rx)
    );

    RX U_RX (
        .clk    (clk),
        .rst    (reset),
        .rx     (rx),
        .b_tick (b_tick),
        .rx_done(rx_done_tick),
        .rx_data(rx_data)
    );

    logic [23:0] rx_done_cnt;
    logic rx_done_led;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_done_cnt <= 0;
            rx_done_led <= 0;
        end else begin
            if (rx_done_tick) begin
                rx_done_cnt <= 24'd10_000_000;
                rx_done_led <= 1;
            end else if (rx_done_cnt > 0) begin
                rx_done_cnt <= rx_done_cnt - 1;
            end else begin
                rx_done_led <= 0;
            end
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sound_enable <= 0;
        end else if (rx_done_tick) begin
            sound_enable <= (rx_data == 8'h01);
        end else begin
            sound_enable <= 0;
        end
    end

    logic [3:0] dither_r, dither_g, dither_b;
    logic [3:0] snow_r, snow_g, snow_b;
    logic [3:0] glitter_r, glitter_g, glitter_b;
    logic [3:0] thresh_r, thresh_b, thresh_g;
    logic [3:0] bubble_r, bubble_g, bubble_b;
    logic [3:0] lightning_r, lightning_g, lightning_b;
    logic [3:0] sakura_r, sakura_g, sakura_b;
    logic [3:0] maple_r, maple_g, maple_b;

    Ordered_Dithering_4bit_InOut U_DITHER (
        .clk    (sys_clk),
        .reset  (reset),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .i_r    (w_r_cam),
        .i_g    (w_g_cam),
        .i_b    (w_b_cam),
        .o_r    (dither_r),
        .o_g    (dither_g),
        .o_b    (dither_b)
    );

    cam_snow_filter U_SNOW (
        .clk   (sys_clk),
        .reset (reset),
        .v_sync(v_sync),
        .DE    (DE),
        .x     (x_pixel),
        .y     (y_pixel),
        .cam_r (w_r_cam),
        .cam_g (w_g_cam),
        .cam_b (w_b_cam),
        .out_r (snow_r),
        .out_g (snow_g),
        .out_b (snow_b)
    );

    cam_sakura_filter U_SAKURA (
        .clk   (sys_clk),
        .reset (reset),
        .v_sync(v_sync),
        .DE    (DE),
        .x     (x_pixel),
        .y     (y_pixel),
        .cam_r (w_r_cam),
        .cam_g (w_g_cam),
        .cam_b (w_b_cam),
        .out_r (sakura_r),
        .out_g (sakura_g),
        .out_b (sakura_b)
    );

    Threshold_Filter_4bit_InOut U_THRESHOLD (
        .i_r(w_r_cam),
        .i_g(w_g_cam),
        .i_b(w_b_cam),
        .o_r(thresh_r),
        .o_g(thresh_g),
        .o_b(thresh_b)
    );

    cam_rain_filter U_RAIN (
        .clk   (sys_clk),
        .reset (reset),
        .v_sync(v_sync),
        .DE    (DE),
        .x     (x_pixel),
        .y     (y_pixel),
        .cam_r (w_r_cam),
        .cam_g (w_g_cam),
        .cam_b (w_b_cam),
        .out_r (bubble_r),
        .out_g (bubble_g),
        .out_b (bubble_b)
    );
    cam_lightning_filter U_LIGHTNING (
        .clk   (sys_clk),
        .reset (reset),
        .v_sync(v_sync),
        .x     (x_pixel),
        .y     (y_pixel),
        .cam_r (w_r_cam),
        .cam_g (w_g_cam),
        .cam_b (w_b_cam),
        .out_r (lightning_r),
        .out_g (lightning_g),
        .out_b (lightning_b)
    );
    cam_maple_filter U_MAPLE (
        .clk   (sys_clk),
        .reset (reset),
        .v_sync(v_sync),
        .DE    (DE),
        .x     (x_pixel),
        .y     (y_pixel),
        .cam_r (w_r_cam),
        .cam_g (w_g_cam),
        .cam_b (w_b_cam),
        .out_r (maple_r),
        .out_g (maple_g),
        .out_b (maple_b)
    );

    logic [11:0] cursor_bmp[0:11];
    logic [11:0] heart_bmp [0:11];

    initial begin
        cursor_bmp[0]  = 12'b000000111110;
        cursor_bmp[1]  = 12'b000000111110;
        cursor_bmp[2]  = 12'b000000110000;
        cursor_bmp[3]  = 12'b000000110000;
        cursor_bmp[4]  = 12'b000000110000;
        cursor_bmp[5]  = 12'b000000110000;
        cursor_bmp[6]  = 12'b000000110000;
        cursor_bmp[7]  = 12'b000111110000;
        cursor_bmp[8]  = 12'b001111110000;
        cursor_bmp[9]  = 12'b001111110000;
        cursor_bmp[10] = 12'b000111100000;
        cursor_bmp[11] = 12'b000000000000;

        heart_bmp[0]   = 12'b000000000000;
        heart_bmp[1]   = 12'b001110011100;
        heart_bmp[2]   = 12'b011111111110;
        heart_bmp[3]   = 12'b111111111111;
        heart_bmp[4]   = 12'b111111111111;
        heart_bmp[5]   = 12'b111111111111;
        heart_bmp[6]   = 12'b011111111110;
        heart_bmp[7]   = 12'b001111111100;
        heart_bmp[8]   = 12'b000111111000;
        heart_bmp[9]   = 12'b000011110000;
        heart_bmp[10]  = 12'b000001100000;
        heart_bmp[11]  = 12'b000000000000;
    end

    logic [3:0] fil_r, fil_g, fil_b;
    logic [2:0] active_note;
    logic       is_pressed_visual;

    assign is_pressed_visual = (detected_y > 300);
    assign fire_trigger = sw_mode && is_pressed_visual && (active_note == 3'd2);
    assign active_note = detected_x / 80;
    assign led[15:8] = rx_data[7:0];
    assign led[1:0] = {sound_enable, rx_done_led};
    logic cursor_is_duck;
    logic prev_note0_pressed;
    logic note0_pressed;

    assign note0_pressed = sw_mode && is_pressed_visual && (active_note == 3'd0);

    always_ff @(posedge sys_clk or posedge reset) begin
        if (reset) begin
            cursor_is_duck     <= 0;
            prev_note0_pressed <= 0;
        end else begin
            prev_note0_pressed <= note0_pressed;
            if (note0_pressed && !prev_note0_pressed) begin
                cursor_is_duck <= ~cursor_is_duck;
            end
        end
    end

    wire [9:0] cur_start_x = (detected_x > 24) ? (detected_x - 24) : 0;
    wire [9:0] cur_start_y = (detected_y > 48) ? (detected_y - 48) : 0;

    wire in_cursor_box = (x_pixel >= cur_start_x) && (x_pixel < cur_start_x + 48) && (y_pixel >= cur_start_y) && (y_pixel < cur_start_y + 48);

    wire [3:0] cursor_row = (y_pixel - cur_start_y) >> 2;
    wire [3:0] cursor_col = (x_pixel - cur_start_x) >> 2;

    reg is_cursor_pixel;
    reg [11:0] cursor_color;

    always @(*) begin
        is_cursor_pixel = 0;
        cursor_color = 12'h000;

        if (in_cursor_box) begin
            if (cursor_is_duck) begin
                if (heart_bmp[cursor_row][11-cursor_col]) begin
                    is_cursor_pixel = 1;
                    cursor_color = 12'hF00;
                end
            end else begin
                if (cursor_bmp[cursor_row][11-cursor_col]) begin
                    is_cursor_pixel = 1;
                    cursor_color = 12'h000;
                end
            end
        end
    end

    reg [9:0] frame_cnt;
    always @(posedge vsync or posedge reset) begin
        if (reset) frame_cnt <= 0;
        else frame_cnt <= frame_cnt + 1;
    end

    always_comb begin
        fil_r = w_r_cam;
        fil_g = w_g_cam;
        fil_b = w_b_cam;

        if (sw_mode && is_pressed_visual) begin
            case (active_note)
                3'd0: begin
                end

                3'd1: begin
                    fil_r = thresh_r;
                    fil_g = thresh_g;
                    fil_b = thresh_b;
                end

                3'd2: begin
                    fil_r = dither_r;
                    fil_g = dither_g;
                    fil_b = dither_b;
                end

                3'd3: begin
                    fil_r = lightning_r;
                    fil_g = lightning_g;
                    fil_b = lightning_b;
                end

                3'd4: begin
                    fil_r = sakura_r;
                    fil_g = sakura_g;
                    fil_b = sakura_b;
                end

                3'd5: begin
                    fil_r = bubble_r;
                    fil_g = bubble_g;
                    fil_b = bubble_b;
                end

                3'd6: begin
                    fil_r = maple_r;
                    fil_g = maple_g;
                    fil_b = maple_b;
                end

                3'd7: begin
                    fil_r = snow_r;
                    fil_g = snow_g;
                    fil_b = snow_b;
                end
            endcase
        end
    end

    always_comb begin
        w_r_out = fil_r;
        w_g_out = fil_g;
        w_b_out = fil_b;

        if (sw_mode) begin
            if (y_pixel >= 250) begin
                w_r_out = kb_r;
                w_g_out = kb_g;
                w_b_out = kb_b;
            end

            if (cat1_r != 0 || cat1_g != 0 || cat1_b != 0) begin
                w_r_out = cat1_r;
                w_g_out = cat1_g;
                w_b_out = cat1_b;
            end

            if (cat2_r != 0 || cat2_g != 0 || cat2_b != 0) begin
                w_r_out = cat2_r;
                w_g_out = cat2_g;
                w_b_out = cat2_b;
            end

            if (is_cursor_pixel) begin
                w_r_out = cursor_color[11:8];
                w_g_out = cursor_color[7:4];
                w_b_out = cursor_color[3:0];
            end
        end
    end

    assign r_port = w_r_out;
    assign g_port = w_g_out;
    assign b_port = w_b_out;

endmodule

module baud_tick (
    input  logic clk,
    input  logic rst,
    output logic b_tick
);

    localparam integer F_CLK = 100_000_000;
    localparam integer BAUD = 115200;
    localparam integer BAUD_TICK = F_CLK / (BAUD * 16);

    logic [$clog2(BAUD_TICK)-1:0] tick_cnt_reg;
    logic b_tick_reg;

    assign b_tick = b_tick_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            tick_cnt_reg <= 0;
            b_tick_reg   <= 0;
        end else begin
            if (tick_cnt_reg == BAUD_TICK - 1) begin
                tick_cnt_reg <= 0;
                b_tick_reg   <= 1;
            end else begin
                tick_cnt_reg <= tick_cnt_reg + 1;
                b_tick_reg   <= 0;
            end
        end
    end

endmodule


module fifo (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] push_data,
    input  logic       push,
    input  logic       pop,
    output logic [7:0] pop_data,
    output logic       full,
    output logic       empty
);

    wire [3:0] w_wptr, w_rptr;

    register_file U_REG_FILE (
        .clk(clk),
        .wptr(w_wptr),
        .rptr(w_rptr),
        .push_data(push_data),
        .wr(~full & push),
        .pop_data(pop_data)
    );

    fifo_cu U_FIFO_CU (
        .clk  (clk),
        .rst  (rst),
        .push (push),
        .pop  (pop),
        .wptr (w_wptr),
        .rptr (w_rptr),
        .full (full),
        .empty(empty)
    );

endmodule

module register_file (
    input  logic       clk,
    input  logic [3:0] wptr,
    input  logic [3:0] rptr,
    input  logic [7:0] push_data,
    input  logic       wr,
    output logic [7:0] pop_data
);
    logic [7:0] ram[0:256];

    assign pop_data = ram[rptr];

    always @(posedge clk) begin
        if (wr) begin
            ram[wptr] <= push_data;
        end
    end
endmodule

module fifo_cu (
    input        clk,
    input        rst,
    input        push,
    input        pop,
    output [3:0] wptr,
    output [3:0] rptr,
    output       full,
    output       empty
);

    reg [3:0] wptr_reg, wptr_next;
    reg [3:0] rptr_reg, rptr_next;
    reg full_reg, full_next;
    reg empty_reg, empty_next;

    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            full_reg  <= 0;
            empty_reg <= 1'b1;
        end else begin
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    always @(*) begin
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        case ({
            push, pop
        })
            2'b01: begin
                full_next = 1'b0;
                if (!empty_reg) begin
                    rptr_next = rptr_reg + 1;
                    if (wptr_reg == rptr_next) begin
                        empty_next = 1'b1;
                    end
                end
            end
            2'b10: begin
                empty_next = 1'b0;
                if (!full_reg) begin
                    wptr_next = wptr_reg + 1;
                    if (wptr_next == rptr_reg) begin
                        full_next = 1'b1;
                    end
                end
            end
            2'b11: begin
                if (empty_reg == 1'b1) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                end else if (full_reg == 1'b1) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
        endcase
    end

endmodule
