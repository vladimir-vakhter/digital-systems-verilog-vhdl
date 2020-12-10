`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: WPI, ECE
// Engineer: Vladimir Vakhter
// Create Date: 11/26/2019 01:08:58 PM
// Module Name: ball_ctrl
// Description: describes the movement of the ball on the game field.
//////////////////////////////////////////////////////////////////////////////////

module ball_ctrl
    #(//screen resolution in pixels
      parameter SCREEN_WIDTH   = 10'd640,
      parameter SCREEN_HEIGHT  = 9'd480,
      //dimensions of the game field in pixels
      parameter BORDER_WIDTH   = 4'd10,
      parameter Y_UP_BORDER    = 10'd19,
      parameter Y_DOWN_BORDER  = 10'd460,
      //the positions of the paddle_1 and paddle_2
      parameter PADDLE_X_1 = 5'd19,
      parameter PADDLE_X_2 = 10'd616,
      //paddle's width in pixels
      parameter PADDLE_WIDTH  = 10'd5,
      //ball's speed
      parameter BALL_SPEED = 20'd1_000_000,
      //ball's width and height in pixels
      parameter BALL_SIZE  = 4'd10)
    (
        input clk,                      //clock
        input reset,                    //reset
        input[10:0] hcount,             //count columns for the current pixel (even if not in visible area)
        input[10:0] vcount,             //count raws for the current pixel (even if not in visible area)
        input blank,                    //active when pixel is not in visible area
        input[31:0] ctrl,               //control
        output reg draw_ball,           //draw ball enable
        output reg[9:0] ball_x,         //current x-position of the ball
        output reg[8:0] ball_y          //current y-position of the ball
    );
    
    //the previous coordinates of the ball (to keep track of the ball position)
    reg[9:0]  ball_x_prev;
    reg[8:0]  ball_y_prev;
    //ball speed
    reg[19:0] ball_speed;
    
    //update registers (sequential)
    always@(posedge clk)
    begin
        if(reset == 1'b1) begin
            ball_x      <= SCREEN_WIDTH/2 - 1;
            ball_y      <= SCREEN_HEIGHT/2 - 1;
            ball_x_prev <= SCREEN_WIDTH;
            ball_y_prev <= SCREEN_HEIGHT - 2;
            ball_speed  <= 32'd0;
        end
        else begin
            //if the game is inactive, the ball stays in the middle of the screen
            if (ctrl == 32'd0)begin
                ball_x      <= SCREEN_WIDTH/2 - 1;  //initially - move left
                ball_x_prev <= SCREEN_WIDTH/2;
                ball_y      <= SCREEN_HEIGHT/2 - 1; //initially - move up
                ball_y_prev <= SCREEN_HEIGHT/2 - 2;
                ball_speed  <= 32'd0;
            end
            else begin
                if (ball_speed < BALL_SPEED) begin
                    ball_speed <= ball_speed + 1;
                end
                else begin
                    //reset the ball speed
                    ball_speed <= 0;
                    //store the previous coordiates
                    ball_x_prev <= ball_x;
                    ball_y_prev <= ball_y;
                    //X-movement: when the previous X-value is less than the current one,
                    //the ball is moving right.
                    //Keep it moving to the right unless it hits the right paddle or leaves the field.
                    //When the previous X-value is greater than the current one, the ball is moving left.
                    //Keep it moving to the left unless it hits the left paddle or leaves the field.                    
                    if (((ball_x > ball_x_prev) && (ball_x == PADDLE_X_2 - BALL_SIZE + 1)) ||
                        ((ball_x < ball_x_prev) && (ball_x != PADDLE_X_1 + PADDLE_WIDTH - 1))) begin
                        ball_x <= ball_x - 1;
                    end
                    else begin
                        ball_x <= ball_x + 1;
                    end
                    //Y-movement: when the previous Y-value is less than the current one, the ball is moving up.
                    //Keep it moving up unless it hits the the upper border.
                    //When the previous Y-value is greater than the current one, the ball is moving down.
                    //Keep it moving down unless it hits the bottom border.    
                    if ((ball_y > ball_y_prev) && (ball_y == (Y_DOWN_BORDER - BORDER_WIDTH - BALL_SIZE + 2)) ||
                        ((ball_y < ball_y_prev) && (ball_y != (Y_UP_BORDER + BORDER_WIDTH - 1)))) begin
                        ball_y <= ball_y - 1;
                        end
                    else begin
                        ball_y <= ball_y + 1;
                    end
                end
            end        
        end
    end
    
    //draw the ball
    always@(posedge clk) begin
        if((hcount >= ball_x) && (hcount < ball_x + BALL_SIZE) &&
           (vcount >= ball_y) && (vcount < ball_y + BALL_SIZE) && blank == 1'b0) begin
            draw_ball <= 1'b1;
        end
        else begin
           draw_ball <= 1'b0;
        end
    end
    
endmodule
