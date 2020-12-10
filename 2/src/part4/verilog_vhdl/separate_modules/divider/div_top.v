`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: WPI, ECE
// Engineer: Vladimir Vakhter
// Create Date: 11/08/2019 09:21:33 AM
// Module Name: top
// Description: 
// 64-bit divider
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
    wire [31:0] GPIO4_tri_i;   
    wire [31:0] GPIO1_tri_o;    
    wire [31:0] GPIO2_tri_o;    
    wire [31:0] GPIO3_tri_o;
    wire [31:0] GPIO4_tri_o;    
    
    //unsigned 64-bit divider
    udiv64 u_div_64(
        .clk(clk_fpga),             //clock
        .reset(reset),              //reset 
        
        .in_loc(GPIO1_tri_o),       //the index location for a 32-bit chunk of the input data
        .in_val(GPIO2_tri_o),       //a 32-bit chunk input value   
        .ctrl_reg(GPIO3_tri_o),     //control register: start/stop/restart computation
        
        .out_loc(GPIO1_tri_i),      //a location for a 32-bit chunk of the 64-bit output values 
        .out_val(GPIO2_tri_i),      //the 32-bit chunk output value
        .state_reg(GPIO3_tri_i)     //state
    );
    
    //Microblaze MCS
    microblaze_mcs_0 u_blaze (
        .Clk(clk_fpga),             //input wire Clk
        .Reset(reset),              //input wire Reset
        .UART_rxd(rx),              //input wire UART_rxd
        .UART_txd(tx),              //output wire UART_txd
        .GPIO1_tri_i(GPIO1_tri_i),  //input wire [31 : 0] GPIO1_tri_i
        .GPIO2_tri_i(GPIO2_tri_i),  //input wire [31 : 0] GPIO2_tri_i
        .GPIO3_tri_i(GPIO3_tri_i),  //input wire [31 : 0] GPIO3_tri_i
        .GPIO4_tri_i(GPIO4_tri_i),  //input wire [31 : 0] GPIO4_tri_i
        .GPIO1_tri_o(GPIO1_tri_o),  //output wire [31 : 0] GPIO1_tri_o
        .GPIO2_tri_o(GPIO2_tri_o),  //output wire [31 : 0] GPIO2_tri_o
        .GPIO3_tri_o(GPIO3_tri_o),  //output wire [31 : 0] GPIO3_tri_o
        .GPIO4_tri_o(GPIO4_tri_o)   //output wire [31 : 0] GPIO4_tri_o
    );
    
endmodule
