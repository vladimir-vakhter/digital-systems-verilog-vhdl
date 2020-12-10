----------------------------------------------------------------------------------
-- Company: WPI, ECE
-- Engineer: Vladimir Vakhter (id = 323834968)
-- 
-- Create Date: 09/04/2019 02:13:53 PM
-- Design Name: 
-- Module Name: seven_seg - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: a seven-segment LED indicator
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- external view of the seven-segment display
entity seven_seg is
    Port ( SW : in STD_LOGIC_VECTOR (3 downto 0);   -- control signals (slide switches)
           AN : out STD_LOGIC_VECTOR (7 downto 0);  -- anodes (digit enable)
           CA : out STD_LOGIC;                      -- cathode A
           CB : out STD_LOGIC;                      -- cathode B
           CC : out STD_LOGIC;                      -- cathode C
           CD : out STD_LOGIC;                      -- cathode D
           CE : out STD_LOGIC;                      -- cathode E
           CF : out STD_LOGIC;                      -- cathode F
           CG : out STD_LOGIC);                     -- cathode G
end seven_seg;

architecture Behavioral of seven_seg is
begin
    -- disable all digits except digit #0
    AN <= "11111110";  
    -- drive the cathodes (CA...CG) low when active
    CA <=   '1' when    SW = "0001" or
                        SW = "0100" else           
            '0';                                               
    CB <=   '1' when    SW = "0101" or
                        SW = "0110" or
                        SW = "1100" or
                        SW = "1110" or
                        SW = "1111" else           
            '0';                                               
    CC <=   '1' when    SW = "0010" or
                        SW = "1100" or
                        SW = "1110" or
                        SW = "1111" else                           
            '0';                                               
    CD <=   '1' when    SW = "0001" or
                        SW = "0100" or
                        SW = "0111" or
                        SW = "1010" or
                        SW = "1111" else                           
            '0';                                               
    CE <=   '1' when    SW = "0001" or
                        SW = "0011" or
                        SW = "0100" or
                        SW = "0101" or
                        SW = "0111" or
                        SW = "1001" else                           
            '0';                                               
    CF <=   '1' when    SW = "0001" or
                        SW = "0010" or
                        SW = "0011" or
                        SW = "0111" else                           
            '0';                                               
    CG <=   '1' when    SW = "0000" or
                        SW = "0001" or
                        SW = "0111" or
                        SW = "1100" or
                        SW = "1101" else                           
            '0';                                                                                                       
end Behavioral;                                               
                                                             