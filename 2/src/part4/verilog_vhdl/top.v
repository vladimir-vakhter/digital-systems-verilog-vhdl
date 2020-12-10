`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: WPI, ECE
// Engineer: Vladimir Vakhter
// Create Date: 11/01/2019 05:04:10 PM
// Module Name: top
// Description: 
// top level of the design of a 128-bit hardware multiplier and a 64-bit unsigned divider
//////////////////////////////////////////////////////////////////////////////////

module top(
        input  clk_fpga,        //FPGA system clk 100MHz
        input  reset,           //reset
        input  rx,              //USB-RS232 Interface: Rx 
        output tx               //USB-RS232 Interface: Tx
    );
    
    wire [31:0] GPIO1_tri_i;    
    wire [31:0] GPIO2_tri_i;
    wire [31:0] GPIO3_tri_i;
        
    wire [31:0] GPIO1_tri_o;    
    wire [31:0] GPIO2_tri_o;    
    wire [31:0] GPIO3_tri_o; 
    wire [31:0] GPIO4_tri_o;   

    //128-bit multiplier
    mult128 mult_128(
        .clk(clk_fpga),             //clock
        .reset(reset),              //reset
        
        .select(GPIO4_tri_o),       //select: 0 - multipliction, 1 - division 
        .in_loc(GPIO1_tri_o),       //the index location for a 32-bit chunk of the 128-bit input value
        .in_val(GPIO2_tri_o),       //the 32-bit chunk input value   
        .ctrl_reg(GPIO3_tri_o),     //control register: start/stop/restart multiplication
        
        .out_loc(GPIO1_tri_i),      //a location for a 32-bit chunk of the 64-bit output values
        .out_val(GPIO2_tri_i),      //the 32-bit chunk output value
        .state_reg(GPIO3_tri_i)     //state
    );
    
    //Microblaze MCS 
    microblaze_mcs_0 u_blaze (
        .Clk(clk_fpga),              //input wire Clk
        .Reset(reset),               //input wire Reset
        .UART_rxd(rx),               //input wire UART_rxd
        .UART_txd(tx),               //output wire UART_txd
        .GPIO1_tri_i(GPIO1_tri_i),   //input wire [31 : 0] GPIO1_tri_i
        .GPIO2_tri_i(GPIO2_tri_i),   //input wire [31 : 0] GPIO2_tri_i
        .GPIO3_tri_i(GPIO3_tri_i),   //input wire [31 : 0] GPIO3_tri_i
        .GPIO1_tri_o(GPIO1_tri_o),   //output wire [31 : 0] GPIO1_tri_o
        .GPIO2_tri_o(GPIO2_tri_o),   //output wire [31 : 0] GPIO2_tri_o
        .GPIO3_tri_o(GPIO3_tri_o),   //output wire [31 : 0] GPIO3_tri_o
        .GPIO4_tri_o(GPIO4_tri_o)    //output wire [31 : 0] GPIO4_tri_o
    );
    
endmodule
