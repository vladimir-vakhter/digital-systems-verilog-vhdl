`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: WPI, ECE
// Engineer: Vladimir Vakhter
// Create Date: 11/26/2019 01:08:58 PM
// Module Name: game_logic
// Description: describes the game logic.
// Two players play against each other. If one of them misses a ball, the his opponent
// earns a point. The maximum score is limited by 9. When one of the players achieves
// the maximum score, the game is over and the score is reset to start another game.
//////////////////////////////////////////////////////////////////////////////////

module game_logic(
    input clk,               //clock
    input reset,             //reset
    input[10:0] hcount,      //count columns for the current pixel (even if not in visible area)
    input[10:0] vcount,      //count raws for the current pixel (even if not in visible area)
    input blank,             //active when pixel is not in visible area 
    input[31:0] y_pos_1,     //the current y position of the paddle_1
    input[31:0] y_pos_2,     //the current y position of the paddle_2
    input[31:0] ctrl,        //control
    output [3:0] VGA_R,      //4-bits red-color component of VGA
    output [3:0] VGA_G,      //4-bits green-color component of VGA
    output [3:0] VGA_B,      //4-bits blue-color component of VGA
    output wire [15:0] score  //score
    );
    
    //draw the elements of the game
    wire draw_paddle_1;
    wire draw_paddle_2;
    wire draw_borders;
    wire draw_ball;
    wire draw;
    
    //the game is running
    wire game_en;
 
    //colors
    parameter BLACK = 4'h0; 
    parameter WHITE = 4'hf;
    
    //max score
    parameter MAX_SCORE = 8'd9; 
    
    //score of the 1st and the 2nd players
    reg [7:0] score_1 = 8'b0;
    reg [7:0] score_2 = 8'b0;
    
    //current coordinates of the ball
    wire[9:0] ball_x;
    wire[8:0] ball_y;
    
    //states of the game's state machine(SM)
    parameter   IDLE        = 3'd0,
                GAME        = 3'd1,
                WINS_1      = 3'd2,
                WINS_2      = 3'd3, 
                CLEAR_SCR   = 3'd4;
                
    //current state, next state of SM
    reg [2:0] current_state, next_state;    
    
    //screen resolution in pixels
    parameter SCREEN_WIDTH   = 10'd640;
    parameter SCREEN_HEIGHT  = 9'd480; 
    
    //dimensions of the game field
    parameter BORDER_WIDTH   = 4'd10;
    parameter X_LEFT_BORDER  = 10'd19;
    parameter X_RIGHT_BORDER = 10'd620;    
    parameter Y_UP_BORDER    = 10'd19;
    parameter Y_DOWN_BORDER  = 10'd460;  
    
    //paddle's width and height in pixels
    parameter PADDLE_WIDTH  = 10'd5;
    parameter PADDLE_HEIGHT = 10'd48;
    
    //the positions of the paddle_1 and paddle_2
    parameter PADDLE_X_1 = X_LEFT_BORDER;
    parameter PADDLE_X_2 = X_RIGHT_BORDER - PADDLE_WIDTH + 1;
    
    //ball's speed
    parameter BALL_SPEED = 20'd1_000_000;
    //ball's width and height in pixels
    parameter BALL_SIZE  = 4'd10;

    //paddle of the first player
    paddle_ctrl #(.PADDLE_X(PADDLE_X_1), .PADDLE_WIDTH(PADDLE_WIDTH),
                  .PADDLE_HEIGHT(PADDLE_HEIGHT)) paddle_1
    (.clk(clk),
     .reset(reset),
     .hcount(hcount),
     .vcount(vcount),
     .blank(blank),
     .y_pos(y_pos_1),
     .draw_paddle(draw_paddle_1)
    );
    
    //paddle of the second player
    paddle_ctrl #(.PADDLE_X(PADDLE_X_2), .PADDLE_WIDTH(PADDLE_WIDTH),
                  .PADDLE_HEIGHT(PADDLE_HEIGHT)) paddle_2
    (.clk(clk),
     .reset(reset),
     .hcount(hcount),
     .vcount(vcount),
     .blank(blank),
     .y_pos(y_pos_2),
     .draw_paddle(draw_paddle_2)
    );

    //upper and bottom borders
    borders_ctrl #(.BORDER_WIDTH(BORDER_WIDTH),.X_LEFT_BORDER(X_LEFT_BORDER),
                   .X_RIGHT_BORDER(X_RIGHT_BORDER), .Y_UP_BORDER(Y_UP_BORDER),
                   .Y_DOWN_BORDER(Y_DOWN_BORDER)) borders
   (.clk(clk),
    .reset(reset),
    .hcount(hcount),
    .vcount(vcount),
    .blank(blank),
    .draw_borders(draw_borders)
    );
    
    //ball
    ball_ctrl #(.SCREEN_WIDTH(SCREEN_WIDTH), .SCREEN_HEIGHT(SCREEN_HEIGHT),
                .BALL_SPEED(BALL_SPEED), .BALL_SIZE(BALL_SIZE), .BORDER_WIDTH(BORDER_WIDTH),
                .Y_UP_BORDER(Y_UP_BORDER), .Y_DOWN_BORDER(Y_DOWN_BORDER), .PADDLE_X_1(PADDLE_X_1),
                .PADDLE_X_2(PADDLE_X_2), .PADDLE_WIDTH(PADDLE_WIDTH)) ball
    (.clk(clk),
     .reset(reset),
     .hcount(hcount),
     .vcount(vcount),
     .blank(blank),
     .ctrl(game_en),
     .draw_ball(draw_ball),
     .ball_x(ball_x),
     .ball_y(ball_y)
    );
    
    //next state logic combined with output logic (combinational)
    always @(*) begin
        if (ctrl == 32'd1) begin
            case(current_state)
                IDLE: begin
                    next_state = GAME;
                end
                GAME: begin
                    //paddle_1 missed a ball
                    if ((ball_x == PADDLE_X_1 + PADDLE_WIDTH - 1) &&
                        ((ball_y < y_pos_1) || (ball_y > y_pos_1 + PADDLE_HEIGHT - 1))) begin
                        next_state = WINS_2;
                    end
                    //paddle_2 missed a ball
                    else if ((ball_x == PADDLE_X_2 - BALL_SIZE) &&
                             ((ball_y < y_pos_2) || (ball_y > y_pos_2 + PADDLE_HEIGHT - 1))) begin
                        next_state = WINS_1;
                    end
                    else begin
                        next_state = GAME;
                    end
                end
                WINS_1: begin
                    next_state = CLEAR_SCR;
                end
                WINS_2: begin
                    next_state = CLEAR_SCR;
                end
                CLEAR_SCR: begin
                    next_state = CLEAR_SCR;
                end
                default: begin
                    next_state = IDLE;
                end           
            endcase
        end
        else begin
            next_state = IDLE;
        end
    end
    
    //update score
    always@(posedge clk) begin
        if(reset == 1'b1) begin
            //reset
            score_1 <= 8'd0;
            score_2 <= 8'd0;
        end
        else begin
            case (current_state)
            WINS_1: begin
                //the end of a game
                if (score_1 == MAX_SCORE - 1) begin  
                    score_1 <= 8'd0;
                    score_2 <= 8'd0;
                end
                else begin
                    score_1 <= score_1 + 8'b1;
                end
            end
            WINS_2: begin
                //the end of a game
                if (score_2 == MAX_SCORE - 1) begin  
                    score_1 <= 8'd0;
                    score_2 <= 8'd0;
                end 
                else begin
                    score_2 <= score_2 + 8'b1;
                end
            end               
            endcase
        end
    end 
    
    //state memory (sequential)
    always @(posedge clk, posedge reset) begin
        if (reset == 1'b1)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
    
    //current score
    assign score = {score_1, score_2};
    
    //the game status
    assign game_en = (current_state == GAME) ? 1'b1 : 1'b0;

    //update RGB components on the screen
    assign draw = draw_borders || draw_paddle_1 || draw_paddle_2 || draw_ball;
    assign VGA_R = draw ? WHITE : BLACK;
    assign VGA_G = draw ? WHITE : BLACK;
    assign VGA_B = draw ? WHITE : BLACK;    

endmodule
