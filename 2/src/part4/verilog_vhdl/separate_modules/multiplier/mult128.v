`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////////////////////
// Company: WPI, ECE
// Engineer: Vladimir Vakhter
// Create Date: 10/26/2019 10:16:36 PM
// Module Name: mult128
// Description: 128-bit multiplier. A state machine is used to calculate
// the multiplication in multiple clock cycles using a single 32x32-bit multiplier.
// The 128-bit input numbers are entered via terminal.
// The following notation is used in the design:
//      |hh_1|hl_1|lh_1|ll_1| = in1[127:0]
//      x                                 
//      |hh_2|hl_2|lh_2|ll_2| = in2[127:0],
// where hh - high_high[31:0], hl - high_low[63:32], lh - low_high[95:64], ll - low_low[127:96]    
////////////////////////////////////////////////////////////////////////////////////////////////////

module mult128(
        input  clk,                     //clock                                                            
        input  reset,                   //reset                                                            
        
        input [31:0] in_loc,            //the index location for a 32-bit chunk of the 128-bit input value 
        input [31:0] in_val,            //the 32-bit chunk input value                                     
        input [31:0] ctrl_reg,          //control register: start/stop/restart multiplication             
        
        output reg [31:0] out_loc,      //a location for a 32-bit chunk of the 64-bit output values
        output reg [31:0] out_val,      //the 32-bit chunk output value 
        output reg [31:0] state_reg     //the index location for a 32-bit chunk of the 256-bit output value                                   
   );
     
    //states of the multiplier
    parameter   
                //to receive 2 128-bit numbers through a 32-bit port
                IDLE    = 2'd0,
                MULT    = 2'd1, 
                FINAL   = 2'd2;
               
    reg [5:0] current_state, next_state;
    
    parameter MULT_STAGE0 = 5'd0, MULT_STAGE1 = 5'd1, MULT_STAGE2 = 5'd2, MULT_STAGE3 = 5'd3,
              MULT_STAGE4 = 5'd4, MULT_STAGE5 = 5'd5, MULT_STAGE6 = 5'd6, MULT_STAGE7 = 5'd7,
              MULT_STAGE8 = 5'd8, MULT_STAGE9 = 5'd9, MULT_STAGE10 = 5'd10, MULT_STAGE11 = 5'd11,
              MULT_STAGE12 = 5'd12, MULT_STAGE13 = 5'd13, MULT_STAGE14 = 5'd14, MULT_STAGE15 = 5'd15,
              MULT_STAGE16 = 5'd16, MULT_STAGE17 = 5'd17, MULT_STAGE18 = 5'd18, MULT_STAGE19 = 5'd19;
    
    //input locations
    parameter LOC_1 = 5'd1, LOC_2 = 5'd2, LOC_3 = 5'd3, LOC_4 = 5'd4,
              LOC_5 = 5'd5, LOC_6 = 5'd6, LOC_7 = 5'd7, LOC_8 = 5'd8,
              LOC_9 = 5'd9, LOC_10 = 5'd10, LOC_11 = 5'd11, LOC_12 = 5'd12,
              LOC_13 = 5'd13, LOC_14 = 5'd14, LOC_15 = 5'd15, LOC_16 = 5'd16;
    
    //input data registers
    reg [127:0] in1, in2;
                                                
    //intermediate results of multiplication
    reg [63:0] ll_1_ll_2; reg [63:0] ll_1_lh_2; reg [63:0] ll_1_hl_2; reg [63:0] ll_1_hh_2;                            
    reg [63:0] lh_1_ll_2; reg [63:0] lh_1_lh_2; reg [63:0] lh_1_hl_2; reg [63:0] lh_1_hh_2;                            
    reg [63:0] hl_1_ll_2; reg [63:0] hl_1_lh_2; reg [63:0] hl_1_hl_2; reg [63:0] hl_1_hh_2;                            
    reg [63:0] hh_1_ll_2; reg [63:0] hh_1_lh_2; reg [63:0] hh_1_hl_2; reg [63:0] hh_1_hh_2;   
    
    //the inputs of a 32-bit multiplier and a temporary output for each of 16 stages of multiplication
    reg [31:0] mult_in_1;
    reg [31:0] mult_in_2;
    reg [4:0] mult_stage;
    wire [63:0] tmp_mult_res;
    
    //the final 256-bit output out_val of multiplication
    reg [255:0] mult_res;
    
    //update registers (sequential)
    always@(posedge clk) begin
        if(reset == 1'b1) begin
            in1 <= 128'd0;
            in2 <= 128'd0;
            mult_stage <= 5'd0;
        end 
        else begin
            if (current_state == IDLE) begin
                case (in_loc) 
                LOC_1: begin
                    in1[31:0] <= in_val;
                end
                LOC_2: begin
                    in1[63:32] <= in_val;
                end
                LOC_3: begin
                    in1[95:64] <= in_val;
                end
                LOC_4: begin
                    in1[127:96] <= in_val;
                end
                LOC_5: begin
                    in2[31:0] <= in_val;
                end
                LOC_6: begin
                    in2[63:32] <= in_val;
                end                    
                LOC_7: begin
                    in2[95:64] <= in_val;
                end
                LOC_8: begin
                    in2[127:96] <= in_val;
                    mult_stage <= 5'd0;
                end                
                endcase
           end
           if (current_state == MULT) begin
                mult_stage <= mult_stage + 5'd1;
                case (mult_stage)
                MULT_STAGE2: begin
                    ll_1_ll_2 <= tmp_mult_res;                
                end
                MULT_STAGE3: begin
                    ll_1_lh_2   <= tmp_mult_res;                
                end
                MULT_STAGE4: begin
                    ll_1_hl_2   <= tmp_mult_res;                
                end
                MULT_STAGE5: begin
                    ll_1_hh_2 <= tmp_mult_res;                
                end
                MULT_STAGE6: begin
                    lh_1_ll_2   <= tmp_mult_res;                  
                end
                MULT_STAGE7: begin
                    lh_1_lh_2   <= tmp_mult_res;              
                end
                MULT_STAGE8: begin
                    lh_1_hl_2   <= tmp_mult_res;                
                end
                MULT_STAGE9: begin
                    lh_1_hh_2   <= tmp_mult_res;               
                end
                MULT_STAGE10: begin
                    hl_1_ll_2   <= tmp_mult_res;                
                end
                MULT_STAGE11: begin
                    hl_1_lh_2   <= tmp_mult_res;                
                end
                MULT_STAGE12: begin
                    hl_1_hl_2   <= tmp_mult_res;                
                end
                MULT_STAGE13: begin
                    hl_1_hh_2   <= tmp_mult_res;                
                end
                MULT_STAGE14: begin
                    hh_1_ll_2   <= tmp_mult_res;
                end
                MULT_STAGE15: begin
                    hh_1_lh_2   <= tmp_mult_res;                
                end
                MULT_STAGE16: begin
                    hh_1_hl_2   <= tmp_mult_res;                
                end
                MULT_STAGE17: begin
                    hh_1_hh_2  <= tmp_mult_res;
                end
                MULT_STAGE18: begin
                    mult_res <=  (ll_1_ll_2 << 0)  + (ll_1_lh_2 << 32)  + (ll_1_hl_2 << 64)  + (ll_1_hh_2 << 96)  + 
                                 (lh_1_ll_2 << 32) + (lh_1_lh_2 << 64)  + (lh_1_hl_2 << 96)  + (lh_1_hh_2 << 128) +
                                 (hl_1_ll_2 << 64) + (hl_1_lh_2 << 96)  + (hl_1_hl_2 << 128) + (hl_1_hh_2 << 160) +
                                 (hh_1_ll_2 << 96) + (hh_1_lh_2 << 128) + (hh_1_hl_2 << 160) + (hh_1_hh_2 << 192);
                end
                endcase
           end
        end
    end
    
    //next state logic (combinational - use blocking)
    always @(*) begin
        if (ctrl_reg == 32'd1) begin
            case(current_state)
                IDLE: begin
                    next_state = MULT;
                end
                MULT: begin
                    if (mult_stage == MULT_STAGE18) begin
                        next_state = FINAL;
                    end
                    else begin
                        next_state = MULT;
                    end
                end
                FINAL:
                    next_state = FINAL;
            endcase
        end
        else begin
            next_state = IDLE;
        end
    end
    
    //output logic
    always@(posedge clk)begin
        if(reset == 1'b1) begin
            out_val <= 32'd0;
        end
        else if(current_state == FINAL) begin
            if (in_loc == LOC_8) begin
                out_loc <= LOC_1;
                out_val <= mult_res[31:0];
            end
            if (in_loc == LOC_9) begin
                out_loc <= LOC_2;
                out_val <= mult_res[63:32];
            end
            if (in_loc == LOC_10) begin
                out_loc <= LOC_3;
                out_val <= mult_res[95:64];
            end                        
            if (in_loc == LOC_11) begin
                out_loc <= LOC_4;
                out_val <= mult_res[127:96];
            end 
            if (in_loc == LOC_12) begin
                out_loc <= LOC_5;
                out_val <= mult_res[159:128];
            end
            if (in_loc == LOC_13) begin
                out_loc <= LOC_6;
                out_val <= mult_res[191:160];
            end
            if (in_loc == LOC_14) begin
                out_loc <= LOC_7;
                out_val <= mult_res[223:192];
            end                        
            if (in_loc == LOC_15) begin
                out_loc <= LOC_8;
                out_val <= mult_res[255:224];
           end 
        end
        else begin
            out_val <= 32'd0;
        end
    end
    
    //update state register
    always@(posedge clk)begin
        if(reset == 1'b1)
            state_reg <= 32'd0;
        else begin
            state_reg <= {30'd0, current_state};
        end
    end
    
    //state-machine flip-flops, or state memory, or current state (sequential - use non-blocking)
    always @(posedge clk, posedge reset)
        if (reset == 1'b1)
            current_state <= IDLE;
        else
            current_state <= next_state;

    //multiplication 
    always@(*) begin
        case (current_state)
        MULT: begin
            case (mult_stage)
            MULT_STAGE0: begin
                mult_in_1 = in1[31:0];
                mult_in_2 = in2[31:0];
            end
            MULT_STAGE1: begin
                mult_in_1 = in1[31:0];
                mult_in_2 = in2[63:32];
            end
            MULT_STAGE2: begin
                mult_in_1 = in1[31:0];
                mult_in_2 = in2[95:64];
            end
            MULT_STAGE3: begin
                mult_in_1 = in1[31:0];
                mult_in_2 = in2[127:96];
            end
            MULT_STAGE4: begin
                mult_in_1 = in1[63:32];
                mult_in_2 = in2[31:0];
            end
            MULT_STAGE5: begin
                mult_in_1 = in1[63:32];
                mult_in_2 = in2[63:32];
            end
            MULT_STAGE6: begin
                mult_in_1 = in1[63:32];
                mult_in_2 = in2[95:64];
            end
            MULT_STAGE7: begin
                mult_in_1 = in1[63:32];
                mult_in_2 = in2[127:96];            
            end
            MULT_STAGE8: begin
                mult_in_1 = in1 [95:64];
                mult_in_2 = in2[31:0];
            end
            MULT_STAGE9: begin
                mult_in_1 = in1[95:64];
                mult_in_2 = in2[63:32];
            end
            MULT_STAGE10: begin
                mult_in_1 = in1[95:64];
                mult_in_2 = in2[95:64];            
            end
            MULT_STAGE11: begin
                mult_in_1 = in1[95:64];
                mult_in_2 = in2[127:96];
            end
            MULT_STAGE12: begin
                mult_in_1 = in1[127:96];
                mult_in_2 = in2[31:0];
            end
            MULT_STAGE13: begin
                mult_in_1 = in1[127:96];
                mult_in_2 = in2[63:32];
            end
            MULT_STAGE14: begin
                mult_in_1 = in1[127:96];
                mult_in_2 = in2[95:64];            
            end
            MULT_STAGE15: begin
                mult_in_1 = in1[127:96];
                mult_in_2 = in2[127:96];
            end
            endcase
        end
        default: begin
            mult_in_1 = 32'd0;
            mult_in_2 = 32'd0;
        end
        endcase 
    end

    mult32 mult32_1(.reset(reset), .clk(clk), .a(mult_in_1), .b(mult_in_2), .c(tmp_mult_res));       
      
endmodule
