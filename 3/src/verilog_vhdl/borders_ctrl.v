`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: WPI, ECE
// Engineer: Vladimir Vakhter
// Create Date: 11/26/2019 01:08:58 PM
// Module Name: ball_ctrl
// Description: describes the position and the dimensions of the borders of the game field.
//////////////////////////////////////////////////////////////////////////////////

module borders_ctrl
    #(//dimensions of the game field
        parameter BORDER_WIDTH   = 4'd10,
        parameter X_LEFT_BORDER  = 10'd19,
        parameter X_RIGHT_BORDER = 10'd620,    
        parameter Y_UP_BORDER    = 10'd19,
        parameter Y_DOWN_BORDER  = 10'd460)
    (
        input clk,                  //clock
        input reset,                //reset
        input[10:0] hcount,         //count columns for the current pixel (even if not in visible area)
        input[10:0] vcount,         //count raws for the current pixel (even if not in visible area)
        input blank,                //active when pixel is not in visible area 
        output reg draw_borders     //draw borders enable
    );
    
    //draw the borders
    always@(posedge clk) begin
        //reset
        if(reset == 1'b1) begin
            draw_borders <= 1'b0;
        end
        else begin
            if(           
                //upper horizontal border
                (((hcount >= X_LEFT_BORDER) && (hcount <= X_RIGHT_BORDER)) &&
                ((vcount >= Y_UP_BORDER) && (vcount < Y_UP_BORDER + BORDER_WIDTH)) && blank == 1'b0) ||
                //bottom horizontal border
                (((hcount >= X_LEFT_BORDER) && (hcount <= X_RIGHT_BORDER)) &&
                ((vcount > Y_DOWN_BORDER - BORDER_WIDTH) && (vcount <= Y_DOWN_BORDER)) && blank == 1'b0)
               ) begin
                draw_borders <= 1'b1;
            end
            else begin
               draw_borders <= 1'b0;
            end
        end
    end
endmodule
