`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: WPI, ECE
// Engineer: Vladimir Vakhter
// Create Date: 11/08/2019 09:20:51 AM
// Module Name: div64
// Description: a 64-bit unsigned divider
// input: a 64-bit dividend, a 64-bit divider,
// output: a 64-bit quotient, a 64-bit reminder
//////////////////////////////////////////////////////////////////////////////////

module udiv64(
        input  clk,                     //clock                                                            
        input  reset,                   //reset  
        
        input [31:0] in_loc,            //a location for a 32-bit chunk of the 128-bit input value 
        input [31:0] in_val,            //the 32-bit chunk input value                                     
        input [31:0] ctrl_reg,          //control register: start/stop/restart multiplication
        
        output reg [31:0] out_loc,      //a location for a 32-bit chunk of the 64-bit output values 
        output reg [31:0] out_val,      //the 32-bit chunk output value 
        output reg [31:0] state_reg     //the index location for a 32-bit chunk of the 256-bit output value 
    );
    
    //a bit depth of the input
    parameter BIT_DEPTH = 7'd64;
    
    //states
    parameter IDLE = 2'd0, DIV1 = 2'd1, DIV2 = 2'd2, FINAL = 2'd3;
    reg [1:0] next_state, current_state;
    
    //input locations
    parameter LOC_1 = 3'd1, LOC_2 = 3'd2, LOC_3 = 3'd3, LOC_4 = 3'd4,
              LOC_5 = 3'd5, LOC_6 = 3'd6, LOC_7 = 3'd7;
    
    reg [63:0] dividend, divider, quotient, reminder;

    //loop counter for the division operation
    reg [5:0] counter;  
        
    //Seq
    always@(posedge clk) begin
        if(reset == 1'b1) begin
            dividend <= 64'd0;
            divider  <= 64'd0;
            quotient <= 64'd0;
            reminder <= 64'd0;
        end 
        else begin
            if(current_state == IDLE) begin
                //load dividend and divider
                case (in_loc)
                   LOC_1: begin
                        dividend[31:0] <= in_val;
                   end
                   LOC_2: begin
                        dividend[63:32] <= in_val;
                   end
                   LOC_3: begin
                        divider[31:0] <= in_val;
                   end
                   LOC_4: begin
                        divider[63:32] <= in_val;
                        //initialize 
                        quotient <= 64'd0;
                        reminder <= 64'd0;
                        counter <= (BIT_DEPTH - 1);
                   end
                endcase
            end
            else if (current_state == DIV1) begin
                reminder <= {reminder[62:0], dividend[counter]};
            end
            else if (current_state == DIV2) begin
                if (reminder >= divider) begin
                    reminder <= reminder - divider;
                    quotient[counter] <= 1'd1;
                end
                if (counter != 6'd0) begin
                    counter <= counter - 6'd1;
                end
            end
        end
    end

    // Next-State Comb. 
    always@(*) begin
        if(ctrl_reg == 32'd1) begin
            case(current_state)
            IDLE: begin 
                next_state = DIV1;
            end
            DIV1: begin
                next_state = DIV2;
            end
            DIV2: begin
                if (counter == 6'd0) begin
                    next_state = FINAL;
                end
                else begin
                    next_state = DIV1;
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
    
    // Current-State Seq.
    always@(posedge clk) begin
        if(reset == 1'b1)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end    
    
    //update result (output logic)
    always@(posedge clk)begin
        if(reset == 1'b1) begin
            out_val <= 32'd0;
        end
        else if(current_state == FINAL) begin
            if (in_loc == LOC_4) begin
                out_loc <= LOC_1;
                out_val <= quotient[31:0];
            end
            if (in_loc == LOC_5) begin
                out_loc <= LOC_2;
                out_val <= quotient[63:32];
            end
            if (in_loc == LOC_6) begin
                out_loc <= LOC_3;
                out_val <= reminder[31:0];
            end                        
            if (in_loc == LOC_7) begin
                out_loc <= LOC_4;
                out_val <= reminder[63:32];
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
    
endmodule
