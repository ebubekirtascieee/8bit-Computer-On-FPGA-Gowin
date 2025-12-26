//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.11.01 Education (64-bit)
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18
//Device Version: C
//Created Time: Fri Dec 26 23:18:39 2025

module Gowin_pROM_Control_Logic (dout, clk, oce, ce, reset, ad);

output [15:0] dout;
input clk;
input oce;
input ce;
input reset;
input [6:0] ad;

wire [15:0] prom_inst_0_dout_w;
wire gw_gnd;

assign gw_gnd = 1'b0;

pROM prom_inst_0 (
    .DO({prom_inst_0_dout_w[15:0],dout[15:0]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .AD({gw_gnd,gw_gnd,gw_gnd,ad[6:0],gw_gnd,gw_gnd,gw_gnd,gw_gnd})
);

defparam prom_inst_0.READ_MODE = 1'b0;
defparam prom_inst_0.BIT_WIDTH = 16;
defparam prom_inst_0.RESET_MODE = "SYNC";
defparam prom_inst_0.INIT_RAM_00 = 256'h0000000000000000120048000000000000000000000000000000000014044002;
defparam prom_inst_0.INIT_RAM_01 = 256'h0000000000000240101048000000000000000000000002401010480000000000;
defparam prom_inst_0.INIT_RAM_02 = 256'h000000000000000000000A000000000000000000000000002100480000000000;
defparam prom_inst_0.INIT_RAM_03 = 256'h0000000000000000000008000000000000000000000000000000080100000000;
defparam prom_inst_0.INIT_RAM_04 = 256'h0000000000000000000008000000000000000000000000000000080000000000;
defparam prom_inst_0.INIT_RAM_05 = 256'h0000000000000240101048000000000000000000000002401010480000000000;
defparam prom_inst_0.INIT_RAM_06 = 256'h0000000000000000024001100000000000000000000002401010480000000000;
defparam prom_inst_0.INIT_RAM_07 = 256'h0000000000000000000080000000000000000000000000000000010800000000;

endmodule //Gowin_pROM_Control_Logic
