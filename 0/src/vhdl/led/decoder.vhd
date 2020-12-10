----------------------------------------------------------------------------------
-- Company: WPI, ECE
-- Engineer: Vladimir Vakhter (id = 323834968)
-- 
-- Create Date: 09/04/2019 12:36:22 AM
-- Design Name: 
-- Module Name: decoder - Behavioral
-- Project Name: Decoder 4 to 16
-- Target Devices: 
-- Tool Versions: 
-- Description: decoder 4 to 16 (using four slider switches and 16 LEDs)
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

-- use the package std_logic_1164 (describing digital logic values) from the library IEEE
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- external view of the decoder 4-to-16
entity decoder is
    Port ( SW : in STD_LOGIC_VECTOR (3 downto 0);      -- slider switches' ports
           LED : out STD_LOGIC_VECTOR (15 downto 0));  -- LEDs' ports
end decoder;

-- behavior of the decoder 4-to-16
architecture Behavioral of decoder is
begin
    LED <=  "0000000000000001" when SW = "0000" else    -- 0
            "0000000000000010" when SW = "0001" else    -- 1
            "0000000000000100" when SW = "0010" else    -- 2
            "0000000000001000" when SW = "0011" else    -- 3
            "0000000000010000" when SW = "0100" else    -- 4
            "0000000000100000" when SW = "0101" else    -- 5
            "0000000001000000" when SW = "0110" else    -- 6
            "0000000010000000" when SW = "0111" else    -- 7
            "0000000100000000" when SW = "1000" else    -- 8
            "0000001000000000" when SW = "1001" else    -- 9
            "0000010000000000" when SW = "1010" else    -- 10
            "0000100000000000" when SW = "1011" else    -- 11
            "0001000000000000" when SW = "1100" else    -- 12
            "0010000000000000" when SW = "1101" else    -- 13
            "0100000000000000" when SW = "1110" else    -- 14
            "1000000000000000";                         -- 15
end Behavioral;
