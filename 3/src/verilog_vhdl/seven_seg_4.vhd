----------------------------------------------------------------------------------
-- Company: WPI, ECE
-- Engineer: Vladimir Vakhter (id = 323834968)
-- Create Date: 09/13/2019 03:17:51 PM
-- Module Name: seven_seg_4 - Behavioral
-- Description: this module represents the 4-digit seven-segment display.
--      Display update rate should be higher than the human eye's reaction (around 45Hz).
--      Input clock = FPGA clock = 100MHz.
--      Using divider 1/2^20, obtain the following update rate: 100MHz/2^20 = 95.4Hz (around 10ms).
--      Each digit will be illuminated for 1/4 of the refresh cycle, or 2.5ms.
--
--      Seven-segment indicator schematic:
--                      
--             0 (ca)          
--              ---            
--      5 (cf) |   |  1 (cb)   
--              ---   6 (cg)   
--      4 (ce) |   |  2 (cc)   
--              --- . 7 (dp)   
--             3 (cd)          
--                             
--      common anode(active-low)
--      where c - cathode, dp - digital point 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;	-- these two libraries are used for        
use ieee.std_logic_arith.all;	    -- arithmetic operations on std_logic_vectors

entity seven_seg_4 is
    Port(   
         in_number : in std_logic_vector(15 downto 0);  -- input 16-bit number
	     clk_fpga  : in std_logic;                      -- 100MHz system clock
		 cathode   : out std_logic_vector(6 downto 0);  -- cathodes
		 anode     : out std_logic_vector(7 downto 0)   -- anodes
		); 
end seven_seg_4;

architecture Behavioral of seven_seg_4 is

    -- decoder
    component decoder is
    port (  binary_number   : in std_logic_vector(3 downto 0);
            hex_symbol      : out std_logic_vector(6 downto 0));
    end component;

	-- signals
	signal display_pattern : std_logic_vector(27 downto 0);  -- 28 bit number to be displayed (4 symbols * 7 cathodes)
	signal digit           : std_logic_vector(6 downto 0);   -- digit to be displayed on a segment
	signal internal_anode  : std_logic_vector(7 downto 0);   -- internal signal corresponding to anodes' state
	signal counter_10ms    : std_logic_vector(19 downto 0);  -- divider counter for 95.4Hz update rate

    -- 7-bit symbols (cathodes)
    alias symbol0 : std_logic_vector(6 DOWNTO 0) is display_pattern(6 DOWNTO 0);
    alias symbol1 : std_logic_vector(6 DOWNTO 0) is display_pattern(13 DOWNTO 7);
    alias symbol2 : std_logic_vector(6 DOWNTO 0) is display_pattern(20 DOWNTO 14);
    alias symbol3 : std_logic_vector(6 DOWNTO 0) is display_pattern(27 DOWNTO 21);

    -- split input 16-bit number into 4 chunks of 4 bit each
    alias number0 : std_logic_vector(3 DOWNTO 0) IS in_number (3 DOWNTO 0);
    alias number1 : std_logic_vector(3 DOWNTO 0) IS in_number (7 DOWNTO 4);
    alias number2 : std_logic_vector(3 DOWNTO 0) IS in_number (11 DOWNTO 8);
    alias number3 : std_logic_vector(3 DOWNTO 0) IS in_number (15 DOWNTO 12);

begin

    -- decoder instances
    decoder0 : decoder port map (binary_number => number0, hex_symbol => symbol0);
    decoder1 : decoder port map (binary_number => number1, hex_symbol => symbol1);
    decoder2 : decoder port map (binary_number => number2, hex_symbol => symbol2);
    decoder3 : decoder port map (binary_number => number3, hex_symbol => symbol3); 
    
    -- assign outputs
    anode    <= internal_anode;
    cathode  <= digit; 
    
    -- generate a 10ms clock from the 100MHZ FPGA clock
    ten_ms_process : process(clk_fpga)
    begin
        if rising_edge(clk_fpga) then
            if counter_10ms = x"fffff" then
                counter_10ms <= x"00000";
            else
                counter_10ms <= counter_10ms + '1';
            end if;
        end if;
    end process ten_ms_process;
    
    -- update anodes each 2.5ms
    with counter_10ms(19 downto 18) select
        internal_anode <=        -- anodes 4...7 are always inactive (high level)
            x"fe" when "00",     -- 1111 1110    segment 0 is active 
            x"fd" when "01",     -- 1111 1101    segment 1 is active 
            x"fb" when "10",     -- 1111 1011    segment 2 is active 
            x"f7" when others;   -- 1111 0111    segment 3 is active 
    
    -- update cathodes each 2.5ms
    with counter_10ms(19 downto 18) select
    digit <=      
        display_pattern(6 downto 0)   when "00",
        display_pattern(13 downto 7)  when "01",
        display_pattern(20 downto 14) when "10",
        display_pattern(27 downto 21) when others;

end Behavioral;
