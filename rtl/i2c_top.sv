`timescale 1ns / 1ps

module i2c_top (
    input  logic clk,
    input  logic reset,
    // External port
    output logic SCL,
    inout  wire  SDA
);

    logic [15:0] rom_data;
    logic [ 7:0] i2c_tx_data;
    logic [ 6:0] rom_addr;
    logic i2c_tx_done, i2c_start, init_start;

    I2C_MASTER U_I2C_Master (
        // global ports
        .clk      (clk),
        .reset    (reset),
        // internal ports
        .I2C_En   (i2c_start),
        .addr     (7'b0100001),
        .CR_RW    (1'b0),
        .tx_data  (i2c_tx_data),
        .tx_done  (i2c_tx_done),
        .tx_ready (),
        .rx_data  (),
        .rx_done  (),
        .I2C_start(1'b0),
        .I2C_stop (1'b1),
        .length   (2'b10),
        // external ports
        .SCL      (SCL),
        .SDA      (SDA)
    );

    i2c_controller U_I2C_Controller (
        .clk      (clk),
        .reset    (reset),
        // rom port
        .addr     (rom_addr),
        .data     (rom_data),
        // i2c port
        .i2c_done (i2c_tx_done),
        .i2c_data (i2c_tx_data),
        .i2c_start(i2c_start),
        .init_done()
    );


    OV7670_ROM U_V7670_ROM (
        .addr(rom_addr),
        .data(rom_data)
    );

endmodule
