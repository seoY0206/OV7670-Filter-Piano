module piano_logic (
    input  logic       clk,
    input  logic       reset,
    input  logic       vsync,
    input  logic [9:0] center_x,
    input  logic [9:0] center_y,
    input  logic       sound_enable,
    output logic [7:0] tx_data,
    output logic       tx_start
);
    localparam int WHITE_Y_TOP = 320;
    localparam int WHITE_Y_BOTTOM = 479;
    logic [7:0] note_reg, note_next;
    logic [7:0] tx_data_reg, tx_data_next;
    logic tx_start_reg, tx_start_next;
    assign tx_data  = tx_data_reg;
    assign tx_start = tx_start_reg;
    always @(*) begin
        note_next     = note_reg;
        tx_data_next  = tx_data_reg;
        tx_start_next = 1'b0;
        if (center_y >= 320 && center_y <= 470) begin
            if (center_x >= 40 && center_x <= 109) note_next = 0;
            else if (center_x >= 110 && center_x <= 179) note_next = 1;
            else if (center_x >= 180 && center_x <= 249) note_next = 2;
            else if (center_x >= 250 && center_x <= 319) note_next = 3;
            else if (center_x >= 320 && center_x <= 389) note_next = 4;
            else if (center_x >= 390 && center_x <= 459) note_next = 5;
            else if (center_x >= 460 && center_x <= 529) note_next = 6;
            else if (center_x >= 530 && center_x <= 599) note_next = 7;
            else note_next = 8'hFF;
        end else note_next = 8'hFF;
        if (sound_enable) begin
            tx_data_next  = note_next;
            tx_start_next = 1'b1;
        end
    end
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            note_reg     <= 8'd1;
            tx_data_reg  <= 8'd0;
            tx_start_reg <= 1'b0;
        end else begin
            note_reg     <= note_next;
            tx_data_reg  <= tx_data_next;
            tx_start_reg <= tx_start_next;
        end
    end

endmodule

module DATA_SEC (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] in_data,
    input  wire       in_valid,
    output reg  [7:0] out_data,
    output reg        out_valid
);
    localparam ONE_SEC = 20_000_000 - 1;
    reg [31:0] cnt;
    reg [ 7:0] latched_data;
    reg        has_data;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt          <= 0;
            latched_data <= 0;
            has_data     <= 0;
            out_data     <= 0;
            out_valid    <= 0;
        end else begin
            out_valid <= 0;
            if (in_valid) begin
                latched_data <= in_data;
                has_data     <= 1;
            end
            if (cnt == ONE_SEC) begin
                cnt <= 0;
                if (has_data) begin
                    out_data  <= latched_data;
                    out_valid <= 1;
                    has_data  <= 0;
                end
            end else begin
                cnt <= cnt + 1;
            end

        end
    end

endmodule
