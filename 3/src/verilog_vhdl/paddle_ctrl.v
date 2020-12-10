`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: WPI, ECE
// Engineer: Vladimir Vakhter
// Create Date: 11/26/2019 01:08:58 PM
// Module Name: ball_ctrl
// Description: describes the movement of a paddle on the game field.
//////////////////////////////////////////////////////////////////////////////////

module paddle_ctrl
    #(//the upper left corner of the paddle in pixels
      parameter PADDLE_X = 10'd616,
      //paddle's width and height in pixels
      parameter PADDLE_WIDTH  = 10'd5,
      parameter PADDLE_HEIGHT = 10'd48)
    (
        input clk,                  //clock
        input reset,                //reset
        input[10:0] hcount,         //count columns for the current pixel (even if not in visible area)
        input[10:0] vcount,         //count raws for the current pixel (even if not in visible area)
        input blank,                //active when pixel is not in visible area 
        input[31:0] y_pos,          //the current y position of the platform
        output reg draw_paddle      //draw paddle enable
    );
    
    //draw the paddle
    always@(posedge clk) begin
        //reset
        if(reset == 1'b1) begin
            draw_paddle <= 1'b0;
        end
        else begin
            //draw paddle
            if((hcount >= PADDLE_X) && (hcount <= PADDLE_X + PADDLE_WIDTH - 1) &&
               (vcount >= y_pos) && (vcount <= y_pos + PADDLE_HEIGHT - 1) && blank == 1'b0) begin
                draw_paddle <= 1'b1;
            end
            else begin
               draw_paddle <= 1'b0;
            end
        end
    end
endmodule
