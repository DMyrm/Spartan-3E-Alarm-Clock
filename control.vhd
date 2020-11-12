----------------------------------------------------------------------------------
-- Company:        UTCN
-- Engineer: 
-- 
-- Create Date:    11:15:34 02/09/2011 
-- Design Name:    clock
-- Module Name:    control - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions:  12.4, 13.4
-- Description:    Control module for the real-time clock
--
-- Dependencies: 
--
-- Revision:       0.01 - File Created
--    02/09/2011   1.0  - Basic version allows to set the hour and minute
--    02/10/2011   1.1  - State machine changed to allow setting the second
--    02/11/2011   1.2  - Signals added to allow blinking the hour, minute, or second 
--                        when the clock is set
-- Comments: 
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control is
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
end control;

architecture Behavioral of control is

type ctrl_type is (run, set_h, set_h_inc, set_h_dec, set_min, set_min_inc, set_min_dec,
						 set_sec, set_sec_inc, set_sec_dec);
signal ctrl_state : ctrl_type;

begin

ctrl: process (clk, rst)
variable div : integer range 0 to 50000000 := 0;
begin
	if (rst = '1') then
		ctrl_state <= run;
		div := 0;
	elsif rising_edge (clk) then
		case ctrl_state is
			when run =>
				if div = 50000000 then
					inc_time <= '1';
					div := 0;
				else
					inc_time <= '0';
					div := div + 1;
				end if;
				if (mode_in = '1') then
					ctrl_state <= set_h;
				else
					ctrl_state <= run;
				end if;

			when set_h =>
				inc_time <= '0';
				if (up_in = '1') then
					ctrl_state <= set_h_inc;
				elsif (down_in = '1') then
					ctrl_state <= set_h_dec;
				elsif (mode_in = '1') then
					ctrl_state <= set_min;
				else
					ctrl_state <= set_h;
				end if;

			when set_h_inc =>
				inc_time <= '0';
				ctrl_state <= set_h;

			when set_h_dec =>
				inc_time <= '0';
				ctrl_state <= set_h;

			when set_min =>
				inc_time <= '0';
				if (up_in = '1') then
					ctrl_state <= set_min_inc;
				elsif (down_in = '1') then
					ctrl_state <= set_min_dec;
				elsif (mode_in = '1') then
					ctrl_state <= set_sec;
				else
					ctrl_state <= set_min;
				end if;

			when set_min_inc =>
				inc_time <= '0';
				ctrl_state <= set_min;

			when set_min_dec =>
				inc_time <= '0';
				ctrl_state <= set_min;

			when set_sec =>
				inc_time <= '0';
				div := 0;
				if (up_in = '1') then
					ctrl_state <= set_sec_inc;
				elsif (down_in = '1') then
					ctrl_state <= set_sec_dec;
				elsif (mode_in = '1') then
					ctrl_state <= run;
				else
					ctrl_state <= set_sec;
				end if;

			when set_sec_inc =>
				inc_time <= '0';
				ctrl_state <= set_sec;

			when set_sec_dec =>
				inc_time <= '0';
				ctrl_state <= set_sec;

		end case;
	end if;
end process ctrl;

	with ctrl_state select
		inc_h <= '1' when set_h_inc, '0' when others;

	with ctrl_state select
		dec_h <= '1' when set_h_dec, '0' when others;

	with ctrl_state select
		bl_h  <= '1' when set_h, '0' when others;

	with ctrl_state select
		inc_min <= '1' when set_min_inc, '0' when others;

	with ctrl_state select
		dec_min <= '1' when set_min_dec, '0' when others;

	with ctrl_state select
		bl_min  <= '1' when set_min, '0' when others;

	with ctrl_state select
		inc_sec <= '1' when set_sec_inc, '0' when others;

	with ctrl_state select
		dec_sec <= '1' when set_sec_dec, '0' when others;

	with ctrl_state select
		bl_sec  <= '1' when set_sec, '0' when others;

end Behavioral;

