----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:23:25 11/08/2020 
-- Design Name: 
-- Module Name:    comutator_filter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all; 


entity comutator_filter is
    Port ( clk : in  STD_LOGIC;
           rotary_a_in : in  STD_LOGIC;
			  rotary_b_in : in  STD_LOGIC;
           rotary_right_out : out  STD_LOGIC;
			  rotary_left_out : out  STD_LOGIC;
			  led :  out std_logic_vector(7 downto 0));
end comutator_filter;

architecture Behavioral of comutator_filter is

signal rotary_in: STD_LOGIC_VECTOR(1 downto 0);
signal rotary_q1 : STD_LOGIC;
signal rotary_q2 : STD_LOGIC;
signal delay_rotary_q1 : STD_LOGIC;

signal rotary_left : STD_LOGIC;
signal rotary_event : STD_LOGIC;

signal led_pattern : std_logic_vector(7 downto 0):= "00000000"; --initial value puts one LED on near the middle.
signal led_drive : std_logic_vector(15 downto 0);


begin

rotary_filter: process(clk)
begin
	if clk'event and clk='1' then
		rotary_in <= rotary_b_in & rotary_a_in;
		case rotary_in is
			when "00" => 
				rotary_q1 <= '0';
				rotary_q2 <= rotary_q2;
			when "01" => 
				rotary_q1 <= rotary_q1;
				rotary_q2 <= '0';
			when "10" => 
				rotary_q1 <= rotary_q1;
				rotary_q2 <= '1';
			when "11" => 
				rotary_q1 <= '1';
				rotary_q2 <= rotary_q2;
			when others => rotary_q1 <= rotary_q1;
				rotary_q2 <= rotary_q2;
		end case;
	end if;
end process rotary_filter;

direction: process(clk)
begin
	if clk'event and clk='1' then
		delay_rotary_q1 <= rotary_q1;
		if rotary_q1='1' and delay_rotary_q1='0' then
			rotary_event <= '1';
			rotary_left <= rotary_q2;
		else
			rotary_event <= '0';
			rotary_left <= rotary_left;
		end if;
	end if;
end process direction;

filter_process: process(clk)
begin
	if clk'event and clk='1' then
		if rotary_event='1' then
			if rotary_left='0' then 
				rotary_right_out <= '1';
				rotary_left_out <= '0';
			else
				rotary_left_out <= '1';
				rotary_right_out <= '0';
			end if;
		else 
			rotary_right_out <= '0';
			rotary_left_out <= '0';
		end if;
	end if;
end process filter_process;

  led_display: process(clk)
  begin
    if clk'event and clk='1' then
		
      if rotary_event='1' then
			if rotary_left='1' then 
				case led_pattern is
					when "00000000" =>
						led_pattern <= "00000000";
					when "10000000" =>
						led_pattern <= "00000000";
					when "11000000" =>
						led_pattern <= "10000000";
					when "11100000" =>
						led_pattern <= "11000000";
					when "11110000" =>
						led_pattern <= "11100000";
					when "11111000" =>
						led_pattern <= "11110000";
					when "11111100" =>
						led_pattern <= "11111000";
					when "11111110" =>
						led_pattern <= "11111100";
					when "11111111" =>
						led_pattern <= "11111110";
					when others =>
						led_pattern <= "00000000";
				end case;	
         else
				case led_pattern is
					when "00000000" =>
						led_pattern <= "10000000";
					when "10000000" =>
						led_pattern <= "11000000";
					when "11000000" =>
						led_pattern <= "11100000";
					when "11100000" =>
						led_pattern <= "11110000";
					when "11110000" =>
						led_pattern <= "11111000";
					when "11111000" =>
						led_pattern <= "11111100";
					when "11111100" =>
						led_pattern <= "11111110";
					when "11111110" =>
						led_pattern <= "11111111";
					when "11111111" =>
						led_pattern <= "11111111";
					when others =>
						led_pattern <= "00000000";
					end case;	
			end if;
			led <= led_pattern; 
		end if;
    end if;
  end process led_display;
		
end Behavioral;

