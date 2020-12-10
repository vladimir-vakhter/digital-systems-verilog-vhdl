`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: WPI, ECE
// Engineer: Vladimir Vakhter
// Create Date: 11/26/2019 12:27:02 PM
// Module Name: top
// Description: Pong game.
// * Two-player mode. The y-position of two paddles is controlled from a keyboard via Microblaze MCS.
// * The button 'w' moves the left paddle 16 pixels up, the button 's' moves the left platform 16 pixel down.
// * The button 'i' moves the right paddle 16 pixels up, the button 'k' moves the right platform 16 pixel down.
// * A simple state machine is implemented to control the game logic.
// * The game is shown on a VGA display 640*480 pixels. The score is shown on four 7-segment indicators.
//////////////////////////////////////////////////////////////////////////////////

module top(
        input  clk_fpga,                 //FPGA system clk 100MHz
        input  reset,                    //reset
        input  rx,                       //USB-RS232 Interface: Rx 
        output tx,                       //USB-RS232 Interface: Tx
        output HS,                       //horizontal synch pulse
        output VS,                       //vertical synch pulse
        output [3:0] VGA_R,              //4-bits red-color component of VGA
        output [3:0] VGA_G,              //4-bits green-color component of VGA
        output [3:0] VGA_B,              //4-bits blue-color component of VGA 
        output [6:0] cathode,            //cathodes of the seven segment indicators
        output [7:0] anode               //anodes of the seven segment indicators
    );

    wire clk_25M;                        //clk 25MHz (for the VGA controller and other logic)
    wire clk_100M;                       //clk 100MHz (for MicroBlaze and the game logics)
    wire [10:0] hcount;                  //count columns for the current pixel (even if not in visible area)
    wire [10:0] vcount;                  //count raws for the current pixel (even if not in visible area)
    wire blank;                          //active when pixel is not in visible area 
    wire [31:0] GPIO1_tri_o;             //output port of MicroBlaze, channel = 1
    wire [31:0] GPIO2_tri_o;             //output port of MicroBlaze, channel = 2
    wire [31:0] GPIO3_tri_o;             //output port of MicroBlaze, channel = 3 
    wire [15:0] score;                   //the current score of the game 

    //clock manager
    clk_wiz_0 mmcm_ip
    (
        //in ports
        .clk_in1(clk_fpga),              //system clock 100MHz
        .reset(reset),                   //reset
        //out ports
        .clk_100M(clk_100M),             //output 100MHz
        .clk_25M(clk_25M)                //output 25MHz
    );
    
    //game logic
    game_logic game(
        .clk(clk_100M),                  //clock                                                            
        .reset(reset),                   //reset                                                             
        .hcount(hcount),                 //count columns for the current pixel (even if not in visible area)
        .vcount(vcount),                 //count raws for the current pixel (even if not in visible area)   
        .blank(blank),                   //active when pixel is not in visible area                         
        .y_pos_1(GPIO1_tri_o),           //the current y position of the paddle_1  
        .y_pos_2(GPIO2_tri_o),           //the current y position of the paddle_2 
        .ctrl(GPIO3_tri_o),              //run/stop/restart the game
        .VGA_R(VGA_R),                   //a VGA component - Red                                      
        .VGA_G(VGA_G),                   //a VGA component - Green
        .VGA_B(VGA_B),                   //a VGA component - Blue
        .score(score)                    //the current score of the game         
    );
    
    //VGA controller 640*480@60Hz
    vga_controller_640_60 vga_ctrl_ip
    (
        // in ports
        .rst(reset),                     // reset         
        .pixel_clk(clk_25M),             // 25MHz pixel clock                         
        // out ports                     
        .HS(HS),                         // output pin, to monitor horizontal synch pulse                    
        .VS(VS),                         // output pin, to monitor vertical synch pulse                  
        .hcount(hcount),                 // count columns for the current pixel (even if not in visible area)           
        .vcount(vcount),                 // count raws for the current pixel (even if not in visible area)           
        .blank(blank)                    // active when pixel is not in visible area 
    );      
    
    //seven segment display
    seven_seg_4 sev_seg (
        .clk_fpga(clk_100M),             //clock
        .in_number(score),               //input number to be displayed
        .cathode(cathode),               //cathodes
        .anode(anode)                    //anodes
    );                        
           
    //Microblaze MCS  
    microblaze_mcs_0 ublaze_mcs_ip (
        .Clk(clk_100M),                 //input wire Clk                 
        .Reset(reset),                  //input wire Reset               
        .UART_rxd(rx),                  //input wire UART_rxd            
        .UART_txd(tx),                  //output wire UART_txd           
        .GPIO1_tri_o(GPIO1_tri_o),      //output wire [31 : 0] GPIO1_tri_o 
        .GPIO2_tri_o(GPIO2_tri_o),      //output wire [31 : 0] GPIO2_tri_o 
        .GPIO3_tri_o(GPIO3_tri_o)       //output wire [31 : 0] GPIO3_tri_o 
    );
endmodule
