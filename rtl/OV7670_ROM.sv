`timescale 1ns / 1ps

module OV7670_ROM (
    input  logic [6:0] addr,
    output logic [15:0] data
);
    logic [15:0] mem[0:100];

    initial begin
        mem[0]   = 16'h12_80; //   0: 0x12 <- 0x80 (COM7_RESET)
        mem[1]   = 16'hFF_F0; //   1: 0x11 <- 0x01 (CLKRC)
        mem[2]   = 16'h12_14; //   2: 0x6B <- 0x4A (DBLV)
        mem[3]   = 16'h11_80; //   3: 0x12 <- 0x14 (COM7_QVGA_RGB)
        mem[4]   = 16'h0C_04; //   4: 0x17 <- 0x13 (HSTART)
        mem[5]   = 16'h3E_19; //   5: 0x18 <- 0x01 (HSTOP)
        mem[6]   = 16'h04_00; //   6: 0x32 <- 0xB6 (HREF)
        mem[7]   = 16'h40_d0; //   7: 0x19 <- 0x02 (VSTART)
        mem[8]   = 16'h3a_04; //   8: 0x1A <- 0x7A (VSTOP)
        mem[9]   = 16'h14_18; //   9: 0x03 <- 0x0A (VREF)
        mem[10]  = 16'h4F_B3; //  10: 0x0C <- 0x00 (COM3)
        mem[11]  = 16'h50_B3; //  11: 0x3E <- 0x00 (COM14)
        mem[12]  = 16'h51_00; //  12: 0x70 <- 0x3A (SCAL_XSC)
        mem[13]  = 16'h52_3d; //  13: 0x71 <- 0x35 (SCAL_YSC)
        mem[14]  = 16'h53_A7; //  14: 0x72 <- 0x11 (DCWCTR)
        mem[15]  = 16'h54_E4; //  15: 0x73 <- 0xF0 (PCLK_DIV)
        mem[16]  = 16'h58_9E; //  16: 0xA2 <- 0x02 (PCLK_DELAY)
        mem[17]  = 16'h3D_C0; //  17: 0x15 <- 0x00 (COM10)
        mem[18]  = 16'h17_15; //  18
        mem[19]  = 16'h18_03; //  19
        mem[20]  = 16'h32_00; //  20
        mem[21]  = 16'h19_03; //  21
        mem[22]  = 16'h1A_7B; //  22
        mem[23]  = 16'h03_00; //  23
        mem[24]  = 16'h0F_41; //  24
        mem[25]  = 16'h1E_00; //  25
        mem[26]  = 16'h33_0B; //  26
        mem[27]  = 16'h3C_78; //  27
        mem[28]  = 16'h69_00; //  28
        mem[29]  = 16'h74_00; //  29
        mem[30]  = 16'hB0_84; //  30
        mem[31]  = 16'hB1_0c; //  31
        mem[32]  = 16'hB2_0e; //  32
        mem[33]  = 16'hB3_80; //  33
        mem[34]  = 16'h70_3a; //  34: 0x13 <- 0xE0 (COM8 base)
        mem[35]  = 16'h71_35; //  35: 0x00 <- 0x00 (GAIN)
        mem[36]  = 16'h72_11; //  36: 0x10 <- 0x00 (AECH)
        mem[37]  = 16'h73_f1; //  37: 0x0D <- 0x40 (COM4)
        mem[38]  = 16'ha2_02; //  38: 0x14 <- 0x18 (COM9)
        mem[39]  = 16'h7a_20; //  39: 0xA5 <- 0x05 (BD50MAX)
        mem[40]  = 16'h7b_10; //  40: 0xAB <- 0x07 (BD60MAX)
        mem[41]  = 16'h7c_1e; //  41: 0x24 <- 0x95 (AEW)
        mem[42]  = 16'h7d_35; //  42: 0x25 <- 0x33 (AEB)
        mem[43]  = 16'h7e_5a; //  43: 0x26 <- 0xE3 (VPT)
        mem[44]  = 16'h7f_69; //  44: 0x9F <- 0x78 (HAECC1)
        mem[45]  = 16'h80_76; //  45: 0xA0 <- 0x68 (HAECC2)
        mem[46]  = 16'h81_80; //  46
        mem[47]  = 16'h82_88; //  47: HAECC3
        mem[48]  = 16'h83_8f; //  48: HAECC4
        mem[49]  = 16'h84_96; //  49: HAECC5
        mem[50]  = 16'h85_a3; //  50: HAECC6
        mem[51]  = 16'h86_af; //  51: HAECC7
        mem[52]  = 16'h87_c4; //  52: COM8 (E5 = FASTAEC|AECSTEP|BFILT|AGC|AEC)
        mem[53]  = 16'h88_d7; //  53: COM5
        mem[54]  = 16'h89_e8; //  54: COM6
        mem[55]  = 16'h13_e0; //  55
        mem[56]  = 16'h00_00; //  56: MVFP
        mem[57]  = 16'h10_00; //  57
        mem[58]  = 16'h0d_40; //  58
        mem[59]  = 16'h14_18; //  59
        mem[60]  = 16'ha5_05; //  60
        mem[61]  = 16'hab_07; //  61
        mem[62]  = 16'h24_95; //  62
        mem[63]  = 16'h25_33; //  63
        mem[64]  = 16'h26_e3; //  64
        mem[65]  = 16'h9f_78; //  65: COM12
        mem[66]  = 16'ha0_68; //  66
        mem[67]  = 16'ha1_03; //  67
        mem[68]  = 16'ha6_d8; //  68: GFIX
        mem[69]  = 16'ha7_d8; //  69: DBLV
        mem[70]  = 16'ha8_f0; //  70
        mem[71]  = 16'ha9_90; //  71
        mem[72]  = 16'haa_94; //  72
        mem[73]  = 16'h13_e7; //  73
        mem[74]  = 16'h69_07; //  74
    end


    assign data = mem[addr];

endmodule
