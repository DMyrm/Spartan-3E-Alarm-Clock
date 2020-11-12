----------------------------------------------------------------------------------
-- Company:        UTCN
-- Engineer: 
-- 
-- Create Date:    10:48:13 02/09/2011 
-- Design Name:    clock
-- Module Name:    clock - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions:  12.4, 13.4
-- Description:    Real Time Clock for the Spartan-3E Board
--                 Displays the hours, minutes, and seconds
-- Dependencies: 
--
-- Revision:       0.01 - File Created
--    02/09/2011   1.0  - Allows to set the hour and minute
--    02/10/2011   1.1  - Allows to set the hour, minute, and second
--    02/11/2011   1.2  - Blinks the hour, minute, or second when the clock is set
-- Comments: 
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity clock is
    Port ( clk    : in   STD_LOGIC;
           rst    : in   STD_LOGIC;
			  ROT_A    : in   STD_LOGIC;
           ROT_B    : in   STD_LOGIC;
			  ROT_CENTER    : in   STD_LOGIC;
			  LED : out STD_LOGIC_VECTOR(7 downto 0);
           SF_D   : out  STD_LOGIC_VECTOR (3 downto 0);
           SF_CE0 : out  STD_LOGIC;
           LCD_E  : out  STD_LOGIC;
           LCD_RS : out  STD_LOGIC;
           LCD_RW : out  STD_LOGIC);
end clock;

architecture Behavioral of clock is

component control is
    Port ( clk      : in   STD_LOGIC;
           rst      : in   STD_LOGIC;
           mode_in  : in   STD_LOGIC;
           up_in    : in   STD_LOGIC;
           down_in  : in   STD_LOGIC;
           inc_time : out  STD_LOGIC;
           inc_h    : out  STD_LOGIC;
           dec_h    : out  STD_LOGIC;
           bl_h     : out  STD_LOGIC;
           inc_min  : out  STD_LOGIC;
           dec_min  : out  STD_LOGIC;
           bl_min   : out  STD_LOGIC;
           inc_sec  : out  STD_LOGIC;
           dec_sec  : out  STD_LOGIC;
           bl_sec   : out  STD_LOGIC);
end component control;

component time_cnt is
    Port ( clk      : in   STD_LOGIC;
           rst      : in   STD_LOGIC;
           inc_time : in   STD_LOGIC;
           inc_h    : in   STD_LOGIC;
           dec_h    : in   STD_LOGIC;
           inc_min  : in   STD_LOGIC;
           dec_min  : in   STD_LOGIC;
           inc_sec  : in   STD_LOGIC;
           dec_sec  : in   STD_LOGIC;
           h_hi     : out  STD_LOGIC_VECTOR (3 downto 0);
           h_lo     : out  STD_LOGIC_VECTOR (3 downto 0);
           min_hi   : out  STD_LOGIC_VECTOR (3 downto 0);
           min_lo   : out  STD_LOGIC_VECTOR (3 downto 0);
           sec_hi   : out  STD_LOGIC_VECTOR (3 downto 0);
           sec_lo   : out  STD_LOGIC_VECTOR (3 downto 0));
end component time_cnt;

component lcd_ctrl is
    Port ( clk    : in   STD_LOGIC;
           rst    : in   STD_LOGIC;
           lcd    : in   STD_LOGIC_VECTOR (63 downto 0);
           SF_D   : out  STD_LOGIC_VECTOR (3 downto 0);
			  SF_CE0 : out  STD_LOGIC;
           LCD_E  : out  STD_LOGIC;
           LCD_RS : out  STD_LOGIC;
           LCD_RW : out  STD_LOGIC);
end component lcd_ctrl;

component debounce is
    Port ( clk : in  STD_LOGIC;
           d_in : in  STD_LOGIC;
           q_out : out  STD_LOGIC);
end component debounce;

component comutator_filter is 
    Port ( clk : in  STD_LOGIC;
           rotary_a_in : in  STD_LOGIC;
			  rotary_b_in : in  STD_LOGIC;
           rotary_right_out : out  STD_LOGIC;
			  rotary_left_out : out  STD_LOGIC;
			  led :  out std_logic_vector(7 downto 0));
end component comutator_filter;

component Clock_Divider is
	port ( clk,reset: in std_logic;
			 clock_out: out std_logic);
end component Clock_Divider;

-- Function to convert a hexa digit to its ASCII code

function hex2ascii (hex : std_logic_vector) return std_logic_vector is
	variable ascii : std_logic_vector (7 downto 0);
begin
	if (hex > x"9") then
		ascii := x"0" & hex + x"37";
	else
		ascii := x"0" & hex + x"30";
	end if;
	return ascii;
end function hex2ascii;

signal lcd   : std_logic_vector (63 downto 0);
signal ch1   : std_logic_vector (7 downto 0);
signal ch2   : std_logic_vector (7 downto 0);
signal ch3   : std_logic_vector (7 downto 0);
signal ch4   : std_logic_vector (7 downto 0);
signal ch5   : std_logic_vector (7 downto 0);
signal ch6   : std_logic_vector (7 downto 0);
signal ch7   : std_logic_vector (7 downto 0);
signal ch8   : std_logic_vector (7 downto 0);

signal inc_time : std_logic;
signal inc_h    : std_logic;
signal dec_h    : std_logic;
signal bl_h     : std_logic;
signal inc_min  : std_logic;
signal dec_min  : std_logic;
signal bl_min   : std_logic;
signal inc_sec  : std_logic;
signal dec_sec  : std_logic;
signal bl_sec   : std_logic;
signal h_hi     : std_logic_vector (3 downto 0);
signal h_lo     : std_logic_vector (3 downto 0);
signal min_hi   : std_logic_vector (3 downto 0);
signal min_lo   : std_logic_vector (3 downto 0);
signal sec_hi   : std_logic_vector (3 downto 0);
signal sec_lo   : std_logic_vector (3 downto 0);

signal mode_d : std_logic;
signal up_d : std_logic;
signal down_d : std_logic;

signal divided_clk : std_logic;

begin

	mode_i: debounce port map (clk => clk, d_in => ROT_CENTER, q_out => mode_d);
	clk_div : Clock_Divider port map (clk => clk, reset => rst, clock_out => divided_clk);
	
	filter_i: comutator_filter port map (clk => clk, 
			  rotary_a_in  => ROT_A,
			  rotary_b_in  => ROT_B,
           rotary_right_out  => up_d,
			  rotary_left_out  => down_d,
			  led => LED);
		
	control_i:  control  port map (clk =>clk, 
											 rst => rst, 
											 mode_in => mode_d, 
											 up_in => up_d, 
											 down_in => down_d, 
											 inc_time => inc_time, 
											 inc_h => inc_h, 
											 dec_h => dec_h,
											 bl_h  => bl_h,
											 inc_min => inc_min, 
											 dec_min => dec_min,
											 bl_min  => bl_min,
											 inc_sec => inc_sec, 
											 dec_sec => dec_sec,
											 bl_sec  => bl_sec);

	time_cnt_i: time_cnt port map (clk => clk,
											 rst => rst, 
											 inc_time => inc_time, 
											 inc_h => inc_h, 
											 dec_h => dec_h, 
											 inc_min => inc_min, 
											 dec_min => dec_min, 
											 inc_sec => inc_sec, 
											 dec_sec => dec_sec, 
											 h_hi => h_hi, 
											 h_lo => h_lo, 
											 min_hi => min_hi,
											 min_lo => min_lo,
											 sec_hi => sec_hi,
											 sec_lo => sec_lo);

	lcd_ctrl_i: lcd_ctrl port map (clk => clk,
											 rst => rst,
											 lcd => lcd,
											 SF_D => SF_D,
											 SF_CE0 => SF_CE0,
											 LCD_E => LCD_E,
											 LCD_RS => LCD_RS,
											 LCD_RW => LCD_RW);

	ch1 <= hex2ascii (h_hi) or (bl_h & "0000000");
	ch2 <= hex2ascii (h_lo) or (bl_h & "0000000");
	ch3 <= x"3A" when (bl_h = '1') or (bl_min = '1') or (bl_sec = '1') else
			 x"3A" or x"80";												-- ':' -> non-blinking for clock set, blinking for run
	ch4 <= hex2ascii (min_hi) or (bl_min & "0000000");
	ch5 <= hex2ascii (min_lo) or (bl_min & "0000000");
	ch6 <= x"3A" when (bl_h = '1') or (bl_min = '1') or (bl_sec = '1') else
			 x"3A" or x"80";												-- ':' -> non-blinking for clock set, blinking for run
	ch7 <= hex2ascii (sec_hi) or (bl_sec & "0000000");
	ch8 <= hex2ascii (sec_lo) or (bl_sec & "0000000");
	lcd <= ch1 & ch2 & ch3 & ch4 & ch5 & ch6 & ch7 & ch8;

end Behavioral;

