library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lcd_controller is
    Port (
        clk       : in  STD_LOGIC; -- 50 MHz
        rst       : in  STD_LOGIC;
        line1_in  : in  STD_LOGIC_VECTOR(127 downto 0);
        line2_in  : in  STD_LOGIC_VECTOR(127 downto 0);
        lcd_e     : out STD_LOGIC; -- Enable
        lcd_rs    : out STD_LOGIC; -- Register select 
        lcd_rw    : out STD_LOGIC; -- Read/Write
        lcd_db    : out STD_LOGIC_VECTOR(7 downto 0) -- Data Bus
    );
end lcd_controller;

architecture Behavioral of lcd_controller is
    -- Steps 0-4: Init commands
    -- Step 5: Set Line 1 addr (0x80)
    -- Steps 6-21: Line 1 chars
    -- Step 22: Set Line 2 addr (0xC0)
    -- Steps 23-38: Line 2 chars
    signal step     : integer range 0 to 38 := 0;
    signal clk_cnt  : integer range 0 to 1000000 := 0;
    signal wait_lim : integer range 0 to 1000000 := 1000000;
begin
    
    lcd_rw <= '0'; -- Always write mode

    -- Select command or character byte for current step
    process(step, line1_in, line2_in)
        variable char_idx : integer range 0 to 15;
    begin
        lcd_rs   <= '0'; -- Commands / Instructions mode
        lcd_db   <= x"00";
        wait_lim <= 5000; -- Default 100 ms per cycle (5000 ticks @ 50 MHz)

        case step is
            when 0 =>
                lcd_db <= x"38"; -- 8-bit mode, 2 lines, 5x8 font
                wait_lim <= 1000000; -- 20 ms power-on wait
            when 1 =>
                lcd_db <= x"38";
                wait_lim <= 250000; -- 5 ms wait
            when 2 =>
                lcd_db <= x"0C"; -- Display ON, Cursor OFF
                wait_lim <= 10000; -- 0.2 ms wait
            when 3 =>
                lcd_db <= x"01"; -- Clear Display
                wait_lim <= 150000; -- 3 ms wait for clear
            when 4 =>
                lcd_db <= x"06"; -- Entry mode: increment cursor
                wait_lim <= 10000; -- 0.2 ms wait
            when 5 =>
                lcd_db <= x"80"; -- DDRAM address - Line 1
            when 6 to 21 =>
                lcd_rs <= '1'; -- Character write mode
                char_idx := 21 - step;
                lcd_db <= line1_in((char_idx*8 + 7) downto (char_idx*8));
            when 22 =>
                lcd_db   <= x"C0"; -- DDRAM address - Line 2
            when 23 to 38 =>
                lcd_rs <= '1'; -- Character write mode
                char_idx := 38 - step;
                lcd_db <= line2_in((char_idx*8 + 7) downto (char_idx*8));
        end case;
    end process;

    -- Generate LCD_E pulse and advance through sequence
    process(clk, rst)
    begin
        if rst = '1' then
            step    <= 0;
            clk_cnt <= 0;
            lcd_e   <= '0';
        elsif rising_edge(clk) then
            if clk_cnt < wait_lim then
                clk_cnt <= clk_cnt + 1;
                -- Assert Enable (LCD_E) between 50 and 100 clock cycles (0,001 ms pulse)
                if (clk_cnt >= 50) and (clk_cnt < 100) then
                    lcd_e <= '1';
                else
                    lcd_e <= '0';
                end if;
            else
                clk_cnt <= 0;
                lcd_e   <= '0';
                if step = 38 then
                    step <= 5; -- Loop continuously refreshing Line 1 and Line 2
                else
                    step <= step + 1;
                end if;
            end if;
        end if;
    end process;
end Behavioral;