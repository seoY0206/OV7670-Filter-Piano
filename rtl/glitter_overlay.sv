
`timescale 1ns / 1ps

module glitter_overlay #(
    parameter PARTICLE_COUNT = 60,   // 파티클 개수
    parameter MAX_BRIGHTNESS = 4'd15 // 최대 밝기
)(
    input  wire        clk,
    input  wire        reset,
    input  wire        vsync,
    input  wire        href,
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,

    input  wire [3:0]  r_in,
    input  wire [3:0]  g_in,
    input  wire [3:0]  b_in,

    output reg  [3:0]  r_out,
    output reg  [3:0]  g_out,
    output reg  [3:0]  b_out
);

    // ============================================================
    // 1. LFSR 기반 랜덤 생성기 (Random Number Generator)
    // ============================================================
    reg [15:0] lfsr = 16'hACE1;
    wire feedback = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];

    always @(posedge clk) begin
        if (reset)
            lfsr <= 16'hACE1;
        else if (href) // 픽셀이 그려질 때마다 랜덤값 갱신
            lfsr <= {lfsr[14:0], feedback};
    end

    // 기본 랜덤 좌표 (이 값 하나만 쓰면 모든 점이 뭉침)
    wire [9:0] base_rand_x = lfsr[9:0] % 640;
    wire [9:0] base_rand_y = lfsr[9:0] % 480;

    // ============================================================
    // 2. 파티클 상태 저장소 (위치 + 수명/밝기)
    // ============================================================
    reg [9:0] px[0:PARTICLE_COUNT-1];
    reg [9:0] py[0:PARTICLE_COUNT-1];
    reg [3:0] pw[0:PARTICLE_COUNT-1];   // 밝기 겸 수명 (Weight)

    integer i;

    // ============================================================
    // 3. 프레임 종료 감지 (Vsync Falling Edge)
    // ============================================================
    reg vsync_d;
    wire frame_done;

    always @(posedge clk) vsync_d <= vsync;
    assign frame_done = (vsync_d == 1 && vsync == 0);

    // ============================================================
    // 4. 파티클 업데이트 로직 (핵심 수정 부분)
    // ============================================================
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < PARTICLE_COUNT; i = i + 1) begin
                // [수정] 초기화 시 i를 곱해 위치를 화면 전체에 흩뿌림
                px[i] <= (i * 53) % 640; 
                py[i] <= (i * 29) % 480;
                pw[i] <= 0; // 초기 상태는 꺼짐
            end
        end 
        else if (frame_done) begin
            for (i = 0; i < PARTICLE_COUNT; i = i + 1) begin
                if (pw[i] == 0) begin
                    // [수정] 수명이 다해 재성성할 때도 i를 섞음
                    // 이렇게 해야 같은 프레임에 태어나는 파티클들이 서로 다른 위치를 가짐
                    px[i] <= (base_rand_x + (i * 37)) % 640;
                    py[i] <= (base_rand_y + (i * 17)) % 480;
                    
                    // 랜덤한 밝기로 시작 (너무 동시에 반짝이지 않게)
                    pw[i] <= MAX_BRIGHTNESS - (i % 4); 
                end else begin
                    // 수명 감소 (점점 어두워짐)
                    pw[i] <= pw[i] - 1;
                end
            end
        end
    end

    // ============================================================
    // 5. 현재 픽셀 렌더링 (Is there a particle here?)
    // ============================================================
    reg [3:0] sparkle_intensity;

    always @(*) begin
        sparkle_intensity = 0;
        // 현재 x,y 좌표에 파티클이 있는지 확인
        for (i = 0; i < PARTICLE_COUNT; i = i + 1) begin
            if ((pixel_x == px[i]) && (pixel_y == py[i])) begin
                sparkle_intensity = pw[i]; // 해당 파티클의 밝기 가져옴
            end
        end
    end

    // ============================================================
    // 6. 최종 합성 (Additive Blending + Saturation)
    // ============================================================
    always @(*) begin
        if (sparkle_intensity > 0) begin
            // 기존 색상에 반짝임 밝기를 더함 (최대값 15 넘지 않게 처리)
            r_out = (r_in + sparkle_intensity > 15) ? 4'd15 : (r_in + sparkle_intensity);
            g_out = (g_in + sparkle_intensity > 15) ? 4'd15 : (g_in + sparkle_intensity);
            b_out = (b_in + sparkle_intensity > 15) ? 4'd15 : (b_in + sparkle_intensity);
        end else begin
            // 반짝임 없으면 원본 그대로 출력
            r_out = r_in;
            g_out = g_in;
            b_out = b_in;
        end
    end

endmodule