----------------------------------------------------------------------------------
-- Company: WPI, ECE
-- Engineer: Vladimir Vakhter
-- Create Date: 10/02/2019 09:18:29 AM
-- Module Name: pmodals - Behavioral
-- Project Name: Light Sensor Interface
-- Description: 
-- Display the ambient light level (light sensor value) in the hexadecimal
-- format on two of the 7-segment indicators (00 to approximately FF).
--
-- Pmod ALS - light-to-digital ambient sensor module based on TI ADC081S021
-- and Vishay Semi TEMT6000X01.Ambient light level resolution: 8 bits (ADC). 
--
-- Bus - SPI, JD pinout (1-2-3-4-5-6):
-- 1 - ~CS (active low), 2 - NC, 3 - MISO, 4 - SCLK, 5 - GND, 6 - VCC
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;	-- these two libraries are used for        
use ieee.std_logic_arith.all;	    -- arithmetic operations on std_logic_vectors

entity pmodals is
  Port ( -- input signals
         clk_fpga   : in std_logic;                         -- 100MHz system clock
         reset      : in std_logic;                         -- reset
         sdo        : in std_logic;                         -- SPI: SDO - digital data input from the sensor
         -- output signals
         sclk       : out std_logic;                        -- SPI: SCLK - digital clock output
         cs         : out std_logic;                        -- SPI: CS - chip selected (active low)
         lock_led   : out std_logic;                        -- LED is on when clock manager locked 
         cathode    : out std_logic_vector (6 downto 0);    -- cathodes 
         anode      : out std_logic_vector (7 downto 0)     -- anodes   
        );
end pmodals;

architecture Behavioral of pmodals is

    -- signals
    -- ===========================================================================================
    -- System clock (25MHz)
    signal clk_25MHz    : std_logic := '0';  
    
    -- SCLK (1MHz)
    signal sclk_counter  : std_logic_vector(4 downto 0) := "00000";
    signal sclk_internal : std_logic := '0'; 
    
    -- CS (10Hz)
    signal cs_counter  : std_logic_vector(19 downto 0) := X"00000";
    signal cs_internal : std_logic := '0';    
    
    -- the data to be displayed on the seven segment display
    signal data : std_logic_vector(15 downto 0) := X"0000";
    alias light_level : std_logic_vector(7 downto 0) is data(7 downto 0); 
    
    -- the light level received from the sensor via SPI
    signal light_level_upd : std_logic_vector(7 downto 0) := X"00"; 
    -- ===========================================================================================

    -- components
    -- ===========================================================================================
    -- clock manager (generates the clock signal of 25MHz using 100MHz system clock)
    component clk_manager
        port(   
                -- In ports
                clk_in1 : in std_logic;
                reset   : in std_logic;
                -- Out ports
                clk_25M : out std_logic;
                locked  : out std_logic
            );
    end component;
    
    -- tell the synthesis tool that an instantiated clock manager is a black box
    ATTRIBUTE SYN_BLACK_BOX : BOOLEAN;
    ATTRIBUTE SYN_BLACK_BOX OF clk_manager : COMPONENT IS TRUE;
    ATTRIBUTE BLACK_PAD_PIN : STRING;
    ATTRIBUTE BLACK_PAD_PIN OF clk_manager : COMPONENT IS "clk_in1, clk_25M, reset, locked";

    -- seven segment display
    component seven_seg_4
        port(   
                input_number : in std_logic_vector(15 downto 0);      -- input 16-bit number
                clk_fpga     : in std_logic;                          -- 100MHz system clock
                cathode      : out std_logic_vector (6 downto 0);     -- cathodes
                anode        : out std_logic_vector (7 downto 0)      -- anodes
            );
    end component;
    -- ===========================================================================================

begin

    -- clock manager instance
    clk_mngr : clk_manager
       port map ( 
       clk_in1  => clk_fpga,
       reset    => reset,
       clk_25M  => clk_25MHz,
       locked   => lock_led
       );

    -- seven segment diaplay instance
    sev_seg_display : seven_seg_4
        port map (
            input_number    => data,
            clk_fpga        => clk_fpga,
            anode           => anode, 
            cathode         => cathode
        );

    -- generate SCLK clock (1MHz, DC=40%) using 25MHz clock
    sclk_process : process(clk_25MHz, reset)
        begin
            -- if reset is active
            if reset = '1' then
                -- reset SCLK counter
                sclk_counter <= "00000"; 
                -- set low (passive state)                 
                sclk_internal <= '0';                     
            elsif rising_edge(clk_25MHz) then
                -- if counter = 25, reset it
                if sclk_counter = X"19" then
                    sclk_counter <= "00000";
                else
                    -- increment counter on the rising edge
                    sclk_counter <= sclk_counter + '1';
                    -- active 10 cycles of clk_25MHz
                    if sclk_counter <= X"0A" then        
                        sclk_internal <= '1';
                    -- passive 15 cycles of clk_25MHz
                    else
                        sclk_internal <= '0';            
                    end if;
                end if;
            end if;
    end process sclk_process;
    
    -- capture a new light level value every 100ms:
    --      - generate ~CS clock (10Hz, DC=0.017%) using SCLK clock
    capture_process : process(sclk_internal, reset)
        begin
            -- if reset is active
            if reset = '1' then
                -- reset CS counter
                cs_counter <= X"00000";
                -- set high (passive state)                
                cs_internal <= '1';                     
            elsif rising_edge(sclk_internal) then
                -- if CS counter = 100,000, reset it 
                if cs_counter = X"186A0" then
                    cs_counter <= X"00000";
                else
                    -- increment CS counter on the rising edge 
                    cs_counter <= cs_counter + '1';
                     -- low 16 cycles of SCLK
                    if cs_counter <= X"0000F" then     
                        cs_internal <= '0';
                        -- get the light level
                        -- ==============================================================
                        if ((cs_counter >= X"00005") and (cs_counter <= X"0000C")) then
                            -- shift left and concatenate with a new input bit 
                            light_level_upd <= (light_level_upd(6 downto 0) & sdo);
                            -- show the level on the seven segment display
                            if cs_counter = X"0000C" then
                                light_level <= light_level_upd;
                            end if;
                        end if;
                        -- ==============================================================
                    else
                        cs_internal <= '1';
                    end if;
                end if;
            end if;
    end process capture_process; 
       
    -- assign clock signals
    sclk <= sclk_internal;
    cs   <= cs_internal;

end Behavioral;
