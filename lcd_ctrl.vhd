----------------------------------------------------------------------------------
-- Company:        UTCN
-- Engineer: 
-- 
-- Create Date:    17:40:49 02/07/2011 
-- Design Name:    lcd_demo
-- Module Name:    lcd_ctrl - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions:  12.4, 13.4
-- Description:    LCD Controller for the Spartan-3E Board
--
-- Dependencies: 
--
-- Revision:       0.01 - File Created
--    02/07/2011   1.0  - Basic version
--    02/11/2011   1.1  - Blinking feature added
-- Comments:       For blinking a character, bit 7 of the character should be set to 1
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lcd_ctrl is
    Port ( clk    : in   STD_LOGIC;
           rst    : in   STD_LOGIC;
           lcd    : in   STD_LOGIC_VECTOR (63 downto 0);
           SF_D   : out  STD_LOGIC_VECTOR (3 downto 0);
			  SF_CE0 : out  STD_LOGIC;
           LCD_E  : out  STD_LOGIC;
           LCD_RS : out  STD_LOGIC;
           LCD_RW : out  STD_LOGIC);
end lcd_ctrl;

architecture Behavioral of lcd_ctrl is

type displ_type is (displ_init, function_set, entry_mode_set, displ_on_off, displ_clear, pause, set_address, displ_done,
						  displ_ch1, displ_ch2, displ_ch3, displ_ch4, displ_ch5, displ_ch6, displ_ch7, displ_ch8);
signal displ_state : displ_type;

type wr_type is (wr_idle, high_setup, high_hold, delay_1us, low_setup, low_hold, delay_40us, wr_done);
signal wr_state : wr_type;

type init_type is (init_idle, st_init1, st_init2, st_init3, st_init4, st_init5, st_init6, st_init7, st_init8, st_init9, init_done);
signal init_state : init_type;

constant CNT_40NS   : integer := 2;				-- 40 ns
constant CNT_240NS  : integer := 12;			-- 240 ns
constant CNT_1US    : integer := 50;			-- 1 us
constant CNT_40US   : integer := 2000;			-- 40 us
constant CNT_100US  : integer := 5000;			-- 100 us
constant CNT_1640US : integer := 82000;		-- 1.64 ms
constant CNT_4100US : integer := 205000;		-- 4.1 ms
constant CNT_15MS   : integer := 750000;		-- 15 ms
constant CNT_500MS  : integer := 25000000;	-- 500 ms

signal wr_byte      : std_logic_vector (7 downto 0);
signal wr_init      : std_logic;
signal wr_end       : std_logic;
signal init_init    : std_logic;
signal init_end     : std_logic;
signal SF_D0        : std_logic_vector (3 downto 0);
signal SF_D1        : std_logic_vector (3 downto 0);
signal LCD_E0       : std_logic;
signal LCD_E1       : std_logic;
signal blink_on     : std_logic;
signal blink_cnt    : integer range 0 to CNT_500MS;
signal displ_cnt    : integer range 0 to CNT_1640US;
signal wr_cnt       : integer range 0 to CNT_40US;
signal init_cnt     : integer range 0 to CNT_15MS;

signal ch1          : std_logic_vector (7 downto 0);
signal ch2          : std_logic_vector (7 downto 0);
signal ch3          : std_logic_vector (7 downto 0);
signal ch4          : std_logic_vector (7 downto 0);
signal ch5          : std_logic_vector (7 downto 0);
signal ch6          : std_logic_vector (7 downto 0);
signal ch7          : std_logic_vector (7 downto 0);
signal ch8          : std_logic_vector (7 downto 0);

begin

-- Main state machine

displ: process (clk, rst)
begin
	if (rst = '1') then
		displ_state <= displ_init;
	elsif rising_edge (clk) then
		case displ_state is
			when displ_init =>
				if (init_end = '1') then
					displ_state <= function_set;
				else
					displ_state <= displ_init;
				end if;

			when function_set =>
				if (wr_end = '1') then
					displ_state <= entry_mode_set;
				else
					displ_state <= function_set;
				end if;

			when entry_mode_set =>
				if (wr_end = '1') then
					displ_state <= displ_on_off;
				else
					displ_state <= entry_mode_set;
				end if;

			when displ_on_off =>
				if (wr_end = '1') then
					displ_state <= displ_clear;
				else
					displ_state <= displ_on_off;
				end if;

			when displ_clear =>
				displ_cnt <= 0;
				if (wr_end = '1') then
					displ_state <= pause;
				else
					displ_state <= displ_clear;
				end if;

			when pause =>
				if (displ_cnt = CNT_1640US) then
					displ_state <= set_address;
					displ_cnt <= 0;
				else
					displ_state <= pause;
					displ_cnt <= displ_cnt + 1;
				end if;

			when set_address =>
				if (wr_end = '1') then
					displ_state <= displ_ch1;
				else
					displ_state <= set_address;
				end if;

			when displ_ch1 =>
				if (wr_end = '1') then
					displ_state <= displ_ch2;
				else
					displ_state <= displ_ch1;
				end if;

			when displ_ch2 =>
				if (wr_end = '1') then
					displ_state <= displ_ch3;
				else
					displ_state <= displ_ch2;
				end if;

			when displ_ch3 =>
				if (wr_end = '1') then
					displ_state <= displ_ch4;
				else
					displ_state <= displ_ch3;
				end if;

			when displ_ch4 =>
				if (wr_end = '1') then
					displ_state <= displ_ch5;
				else
					displ_state <= displ_ch4;
				end if;

			when displ_ch5 =>
				if (wr_end = '1') then
					displ_state <= displ_ch6;
				else
					displ_state <= displ_ch5;
				end if;

			when displ_ch6 =>
				if (wr_end = '1') then
					displ_state <= displ_ch7;
				else
					displ_state <= displ_ch6;
				end if;

			when displ_ch7 =>
				if (wr_end = '1') then
					displ_state <= displ_ch8;
				else
					displ_state <= displ_ch7;
				end if;

			when displ_ch8 =>
				if (wr_end = '1') then
					displ_state <= displ_done;
				else
					displ_state <= displ_ch8;
				end if;

			when displ_done =>
					displ_state <= set_address;

		end case;
	end if;
end process displ;

-- Controlling the write of a command/data

	with displ_state select
		wr_init <= '0' when displ_init | pause | displ_done,
					  '1' when others;

-- Controlling the initialization sequence

	with displ_state select
		init_init <= '1' when displ_init,
						 '0' when others;

-- Select value to display for blinking

	ch1 <= x"20" when (blink_on = '1') and (lcd(63) = '1') else
			 '0' & lcd (62 downto 56);
	ch2 <= x"20" when (blink_on = '1') and (lcd(55) = '1') else
			 '0' & lcd (54 downto 48);
	ch3 <= x"20" when (blink_on = '1') and (lcd(47) = '1') else
			 '0' & lcd (46 downto 40);
	ch4 <= x"20" when (blink_on = '1') and (lcd(39) = '1') else
			 '0' & lcd (38 downto 32);
	ch5 <= x"20" when (blink_on = '1') and (lcd(31) = '1') else
			 '0' & lcd (30 downto 24);
	ch6 <= x"20" when (blink_on = '1') and (lcd(23) = '1') else
			 '0' & lcd (22 downto 16);
	ch7 <= x"20" when (blink_on = '1') and (lcd(15) = '1') else
			 '0' & lcd (14 downto 8);
	ch8 <= x"20" when (blink_on = '1') and (lcd(7)  = '1') else
			 '0' & lcd (6 downto 0);
	
-- The byte to write to LCD

	with displ_state select
		wr_byte <= x"28" when function_set,			-- 4-bit interface, 2 lines, 5x8 font
					  x"06" when entry_mode_set,		-- auto-increment address, shifting disabled
					  x"0C" when displ_on_off,			-- display on, no cursor, no cursor blinking
					  x"01" when displ_clear,			-- clear display
					  x"80" when set_address,			-- set DD RAM address to 0
					  ch1   when displ_ch1,				-- char 1
					  ch2   when displ_ch2,				-- char 2
					  ch3   when displ_ch3,				-- char 3
					  ch4   when displ_ch4,				-- char 4
					  ch5   when displ_ch5,				-- char 5
					  ch6   when displ_ch6,				-- char 6
					  ch7   when displ_ch7,				-- char 7
					  ch8   when displ_ch8,				-- char 8
					  x"00" when others;

-- Data and control outputs

	with displ_state select
		SF_D <= SF_D1 when displ_init,
				  SF_D0 when others;

	with displ_state select
		LCD_E <= LCD_E1 when displ_init,
				   LCD_E0 when others;

	with displ_state select
		LCD_RS <= '0' when function_set | entry_mode_set | displ_on_off | displ_clear | set_address,
				    '1' when others;

	LCD_RW <= '0';			-- only write operations to the LCD
	SF_CE0 <= '1';			-- disable the Intel StrataFlash memory

-- Process for blinking

blink: process (clk, rst)
begin
	if (rst = '1') then
		blink_cnt <= 0;
		blink_on <= '0';
	elsif rising_edge (clk) then
		if (blink_cnt = CNT_500MS) then
			blink_cnt <= 0;
			blink_on <= not blink_on;
		else
			blink_cnt <= blink_cnt + 1;
		end if;
	end if;
end process blink;

-- Write data state machine

wr: process (clk, rst)
begin
	if (rst = '1') then
		wr_state <= wr_idle;
	elsif rising_edge (clk) then
		case wr_state is
			when wr_idle =>
				wr_cnt <= 0;
				if (wr_init = '1') then
					wr_state <= high_setup;
				else
					wr_state <= wr_idle;
				end if;

			when high_setup =>
				if (wr_cnt = CNT_40NS) then
					wr_cnt <= 0;
					wr_state <= high_hold;
				else
					wr_cnt <= wr_cnt + 1;
					wr_state <= high_setup;
				end if;

			when high_hold =>
				if (wr_cnt = CNT_240NS) then
					wr_cnt <= 0;
					wr_state <= delay_1us;
				else
					wr_cnt <= wr_cnt + 1;
					wr_state <= high_hold;
				end if;

			when delay_1us =>
				if (wr_cnt = CNT_1US) then
					wr_cnt <= 0;
					wr_state <= low_setup;
				else
					wr_cnt <= wr_cnt + 1;
					wr_state <= delay_1us;
				end if;

			when low_setup =>
				if (wr_cnt = CNT_40NS) then
					wr_cnt <= 0;
					wr_state <= low_hold;
				else
					wr_cnt <= wr_cnt + 1;
					wr_state <= low_setup;
				end if;

			when low_hold =>
				if (wr_cnt = CNT_240NS) then
					wr_cnt <= 0;
					wr_state <= delay_40us;
				else
					wr_cnt <= wr_cnt + 1;
					wr_state <= low_hold;
				end if;

			when delay_40us =>
				if (wr_cnt = CNT_40US) then
					wr_cnt <= 0;
					wr_state <= wr_done;
				else
					wr_cnt <= wr_cnt + 1;
					wr_state <= delay_40us;
				end if;

			when wr_done =>
					wr_state <= wr_idle;

		end case;
	end if;
end process wr;

	with wr_state select
		wr_end <= '1' when wr_done,
				    '0' when others;

	with wr_state select
		SF_D0 <= wr_byte (7 downto 4) when high_setup | high_hold | delay_1us,
				   wr_byte (3 downto 0) when others;

	with wr_state select
		LCD_E0 <= '1' when high_hold | low_hold,
				    '0' when others;

-- Initialization state machine

init: process (clk, rst)
begin
	if (rst = '1') then
		init_state <= init_idle;
	elsif rising_edge (clk) then
		case init_state is
			when init_idle =>
				init_cnt <= 0;
				if (init_init = '1') then
					init_state <= st_init1;
				else
					init_state <= init_idle;
				end if;

			when st_init1 =>
				if (init_cnt = CNT_15MS) then
					init_cnt <= 0;
					init_state <= st_init2;
				else
					init_cnt <= init_cnt + 1;
					init_state <= st_init1;
				end if;

			when st_init2 =>
				if (init_cnt = CNT_240NS) then
					init_cnt <= 0;
					init_state <= st_init3;
				else
					init_cnt <= init_cnt + 1;
					init_state <= st_init2;
				end if;

			when st_init3 =>
				if (init_cnt = CNT_4100US) then
					init_cnt <= 0;
					init_state <= st_init4;
				else
					init_cnt <= init_cnt + 1;
					init_state <= st_init3;
				end if;

			when st_init4 =>
				if (init_cnt = CNT_240NS) then
					init_cnt <= 0;
					init_state <= st_init5;
				else
					init_cnt <= init_cnt + 1;
					init_state <= st_init4;
				end if;

			when st_init5 =>
				if (init_cnt = CNT_100US) then
					init_cnt <= 0;
					init_state <= st_init6;
				else
					init_cnt <= init_cnt + 1;
					init_state <= st_init5;
				end if;

			when st_init6 =>
				if (init_cnt = CNT_240NS) then
					init_cnt <= 0;
					init_state <= st_init7;
				else
					init_cnt <= init_cnt + 1;
					init_state <= st_init6;
				end if;

			when st_init7 =>
				if (init_cnt = CNT_40US) then
					init_cnt <= 0;
					init_state <= st_init8;
				else
					init_cnt <= init_cnt + 1;
					init_state <= st_init7;
				end if;

			when st_init8 =>
				if (init_cnt = CNT_240NS) then
					init_cnt <= 0;
					init_state <= st_init9;
				else
					init_cnt <= init_cnt + 1;
					init_state <= st_init8;
				end if;

			when st_init9 =>
				if (init_cnt = CNT_40US) then
					init_cnt <= 0;
					init_state <= init_done;
				else
					init_cnt <= init_cnt + 1;
					init_state <= st_init9;
				end if;

			when init_done =>
				init_state <= init_done;

		end case;
	end if;
end process init;

	with init_state select
		init_end <= '1' when init_done,
				      '0' when others;

	with init_state select
		SF_D1 <= x"3" when st_init2 | st_init3 | st_init4 | st_init5 | st_init6 | st_init7,
					x"2" when st_init8 | st_init9,
				   x"0" when others;

	with init_state select
		LCD_E1 <= '1' when st_init2 | st_init4 | st_init6 | st_init8,
				    '0' when others;


end Behavioral;
