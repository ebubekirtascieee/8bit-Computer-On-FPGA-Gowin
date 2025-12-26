//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.11.01 Education (64-bit)
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18
//Device Version: C
//Created Time: Fri Dec 26 23:18:39 2025

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_pROM_Control_Logic your_instance_name(
        .dout(dout), //output [15:0] dout
        .clk(clk), //input clk
        .oce(oce), //input oce
        .ce(ce), //input ce
        .reset(reset), //input reset
        .ad(ad) //input [6:0] ad
    );

//--------Copy end-------------------
