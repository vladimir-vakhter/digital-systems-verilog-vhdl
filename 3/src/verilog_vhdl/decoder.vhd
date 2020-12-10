----------------------------------------------------------------------------------
-- Company: WPI, ECE
-- Engineer: Vladimir Vakhter (id = 323834968)
-- Create Date: 09/15/2019 12:29:09 AM
-- Module Name: decoder - Behavioral
-- Description: convert binary numbers to hex symbols
--              to be displayed on a seven-segment idicator
--
--              Seven-segment indicator schematic:
--                              
--                     0 (ca)          
--                      ---            
--              5 (cf) |   |  1 (cb)   
--                      ---   6 (cg)   
--              4 (ce) |   |  2 (cc)   
--                      --- . 7 (dp)   
--                     3 (cd)          
--                                     
--              common anode(active-low)
--              where c - cathode, dp - digital point             
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity decoder is
    port (  
          binary_number : in std_logic_vector(3 downto 0);
          hex_symbol : out std_logic_vector(6 downto 0)
          );
end decoder;

architecture Behavioral of decoder is

    -- digits to be displayed (cathode patterns)                                           
    constant zero       : std_logic_vector(6 downto 0)  := "1000000";     
    constant one        : std_logic_vector(6 downto 0)  := "1111001";     
    constant two        : std_logic_vector(6 downto 0)  := "0100100";        
    constant three      : std_logic_vector(6 downto 0)  := "0110000";        
    constant four       : std_logic_vector(6 downto 0)  := "0011001";        
    constant five       : std_logic_vector(6 downto 0)  := "0010010";        
    constant six        : std_logic_vector(6 downto 0)  := "0000010";        
    constant seven      : std_logic_vector(6 downto 0)  := "1111000";        
    constant eight      : std_logic_vector(6 downto 0)  := "0000000";      
    constant nine       : std_logic_vector(6 downto 0)  := "0010000";      
    constant a_digit    : std_logic_vector(6 downto 0)  := "0001000";      
    constant b_digit    : std_logic_vector(6 downto 0)  := "0000000";     
    constant c_digit    : std_logic_vector(6 downto 0)  := "1000110";     
    constant d_digit    : std_logic_vector(6 downto 0)  := "1000000";     
    constant e_digit    : std_logic_vector(6 downto 0)  := "0000110";    
    constant f_digit    : std_logic_vector(6 downto 0)  := "0001110";    
    
begin

    -- display the value on the seven segment display
    seven_seg_decoder_process: process(binary_number)
    begin
        case binary_number is
            when "0000" => hex_symbol <= zero;
            when "0001" => hex_symbol <= one;
            when "0010" => hex_symbol <= two;
            when "0011" => hex_symbol <= three;
            when "0100" => hex_symbol <= four;
            when "0101" => hex_symbol <= five;
            when "0110" => hex_symbol <= six;
            when "0111" => hex_symbol <= seven;
            when "1000" => hex_symbol <= eight;
            when "1001" => hex_symbol <= nine;
            when "1010" => hex_symbol <= a_digit;
            when "1011" => hex_symbol <= b_digit;
            when "1100" => hex_symbol <= c_digit;
            when "1101" => hex_symbol <= d_digit;
            when "1110" => hex_symbol <= e_digit;
            when others => hex_symbol <= f_digit;
        end case;
    end process;

end Behavioral;
