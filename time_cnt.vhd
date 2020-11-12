----------------------------------------------------------------------------------
-- Company:        UTCN
-- Engineer: 
-- 
-- Create Date:    11:23:23 02/09/2011 
-- Design Name:    clock
-- Module Name:    time_cnt - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions:  12.4, 13.4
-- Description:    Timer counter module for the real-time clock
--
-- Dependencies: 
--
-- Revision:       0.01 - File Created
--    02/09/2011   1.0  - Basic version allows to set the hour and minute
--    02/10/2011   1.1  - Process sec_cnt changed to allow setting the second
-- Comments: 
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity time_cnt is
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
end time_cnt;

architecture Behavioral of time_cnt is

signal cnt_sec_hi, cnt_sec_lo : std_logic_vector (3 downto 0);
signal cnt_min_hi, cnt_min_lo : std_logic_vector (3 downto 0);
signal cnt_h_hi, cnt_h_lo     : std_logic_vector (3 downto 0);
signal tc_sec, tc_min         : std_logic;

begin

sec_cnt: process (clk, rst)	-- Seconds count
begin
	if (rst = '1') then
		cnt_sec_lo <= x"0";
		cnt_sec_hi <= x"0";
	elsif rising_edge (clk) then
		tc_sec <= '0';
		if ((inc_time = '1') or (inc_sec = '1')) then
			if (cnt_sec_lo = x"9") then
				cnt_sec_lo <= x"0";
				if (cnt_sec_hi = x"5") then
					cnt_sec_hi <= x"0";
					if (inc_time = '1') then
						tc_sec <= '1';
					end if;
				else
					cnt_sec_hi <= cnt_sec_hi + 1;
				end if;
			else
				cnt_sec_lo <= cnt_sec_lo + 1;
			end if;
		end if;
		if (dec_sec = '1') then
			if (cnt_sec_lo = x"0") then
				cnt_sec_lo <= x"9";
				if (cnt_sec_hi = x"0") then
					cnt_sec_hi <= x"5";
				else
					cnt_sec_hi <= cnt_sec_hi - 1;
				end if;
			else
				cnt_sec_lo <= cnt_sec_lo - 1;
			end if;
		end if;
	end if;
end process sec_cnt;

min_cnt: process (clk, rst)	-- Minutes count
begin
	if (rst = '1') then
		cnt_min_lo <= x"0";
		cnt_min_hi <= x"0";
	elsif rising_edge (clk) then
		tc_min <= '0';
		if ((tc_sec = '1') or (inc_min = '1')) then
			if (cnt_min_lo = x"9") then
				cnt_min_lo <= x"0";
				if (cnt_min_hi = x"5") then
					cnt_min_hi <= x"0";
					if (tc_sec = '1') then
						tc_min <= '1';
					end if;
				else
					cnt_min_hi <= cnt_min_hi + 1;
				end if;
			else
				cnt_min_lo <= cnt_min_lo + 1;
			end if;
		end if;
		if (dec_min = '1') then
			if (cnt_min_lo = x"0") then
				cnt_min_lo <= x"9";
				if (cnt_min_hi = x"0") then
					cnt_min_hi <= x"5";
				else
					cnt_min_hi <= cnt_min_hi - 1;
				end if;
			else
				cnt_min_lo <= cnt_min_lo - 1;
			end if;
		end if;
	end if;
end process min_cnt;

h_cnt: process (clk, rst)		-- Hours count
begin
	if (rst = '1') then
		cnt_h_lo <= x"2";
		cnt_h_hi <= x"1";
	elsif rising_edge (clk) then
		if ((tc_min = '1') or (inc_h = '1')) then
			if ((cnt_h_hi = x"2") and (cnt_h_lo = x"3")) then
				cnt_h_hi <= x"0";
				cnt_h_lo <= x"0";
			elsif (cnt_h_lo = x"9") then
				cnt_h_lo <= x"0";
				cnt_h_hi <= cnt_h_hi + 1;
			else
				cnt_h_lo <= cnt_h_lo + 1;
			end if;
		end if;
		if (dec_h = '1') then
			if ((cnt_h_hi = x"0") and (cnt_h_lo = x"0")) then
				cnt_h_hi <= x"2";
				cnt_h_lo <= x"3";
			elsif (cnt_h_lo = x"0") then
				cnt_h_lo <= x"9";
				cnt_h_hi <= cnt_h_hi - 1;
			else
				cnt_h_lo <= cnt_h_lo - 1;
			end if;
		end if;
	end if;
end process h_cnt;

	h_hi   <= cnt_h_hi;
	h_lo   <= cnt_h_lo;
	min_hi <= cnt_min_hi;
	min_lo <= cnt_min_lo;
	sec_hi <= cnt_sec_hi;
	sec_lo <= cnt_sec_lo;
	
end Behavioral;

