library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ps2_keyboard is
    Port (
        clk        : in  STD_LOGIC; -- 50 MHz system clock
        rst        : in  STD_LOGIC;
        ps2_clk    : in  STD_LOGIC;
        ps2_data   : in  STD_LOGIC;
        ascii_code : out STD_LOGIC_VECTOR(7 downto 0);
        key_pulse  : out STD_LOGIC; -- 1-cycle pulse on valid key press
        is_letter  : out STD_LOGIC;
        is_enter   : out STD_LOGIC;
        is_bksp    : out STD_LOGIC
    );
end ps2_keyboard;

architecture Behavioral of ps2_keyboard is
    signal ps2c_sync : STD_LOGIC_VECTOR(7 downto 0) := (others => '1');
    signal ps2d_sync : STD_LOGIC := '1';
    signal ps2c_filt : STD_LOGIC := '1';
    signal ps2c_prev : STD_LOGIC := '1';
    signal fall_edge : STD_LOGIC := '0';

    signal bit_cnt : integer range 0 to 10 := 0;
    signal shift_reg : STD_LOGIC_VECTOR(10 downto 0) := (others => '0');
    signal scan_done : STD_LOGIC := '0';
    signal scan_code : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal break_flg : STD_LOGIC := '0';
begin

    -- Filter PS/2 clock and detect falling edge
    process(clk, rst)
    begin
        if rst = '1' then
            ps2c_sync <= (others => '1');
            ps2c_filt <= '1';
            ps2c_prev <= '1';
            ps2d_sync <= '1';
        elsif rising_edge(clk) then
            ps2c_sync <= ps2c_sync(6 downto 0) & ps2_clk;
            ps2d_sync <= ps2_data;
            if ps2c_sync = x"FF" then
                ps2c_filt <= '1';
            elsif ps2c_sync = x"00" then
                ps2c_filt <= '0';
            end if;
            ps2c_prev <= ps2c_filt;
        end if;
    end process;

    fall_edge <= '1' when (ps2c_prev = '1' and ps2c_filt = '0') else '0';

    -- Shift in 11-bit Data Bus
    process(clk, rst)
    begin
        if rst = '1' then
            bit_cnt <= 0;
            shift_reg <= (others => '0');
            scan_done <= '0';
        elsif rising_edge(clk) then
            scan_done <= '0';
            if fall_edge = '1' then
                shift_reg <= ps2d_sync & shift_reg(10 downto 1);
                if bit_cnt = 10 then
                    bit_cnt <= 0;
                    scan_done <= '1';
                else
                    bit_cnt <= bit_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    scan_code <= shift_reg(8 downto 1);

    -- Handle break code (0xF0) and decode Scan Code Set 2 to ASCII
    process(clk, rst)
    begin
        if rst = '1' then
            break_flg <= '0';
            key_pulse <= '0';
            is_letter <= '0';
            is_enter <= '0';
            is_bksp <= '0';
            ascii_code <= x"20";
        elsif rising_edge(clk) then
            key_pulse <= '0';
            if scan_done = '1' then
                if scan_code = x"F0" then
                    break_flg <= '1'; -- Next byte is key release
                elsif break_flg = '1' then
                    break_flg <= '0'; -- Ignore released key
                else
                    -- Key press detected
                    key_pulse <= '1';
                    is_letter <= '1';
                    is_enter <= '0';
                    is_bksp <= '0';

                    case scan_code is
                        when x"1C" => ascii_code <= x"41"; -- A
                        when x"32" => ascii_code <= x"42"; -- B
                        when x"21" => ascii_code <= x"43"; -- C
                        when x"23" => ascii_code <= x"44"; -- D
                        when x"24" => ascii_code <= x"45"; -- E
                        when x"2B" => ascii_code <= x"46"; -- F
                        when x"34" => ascii_code <= x"47"; -- G
                        when x"33" => ascii_code <= x"48"; -- H
                        when x"43" => ascii_code <= x"49"; -- I
                        when x"3B" => ascii_code <= x"4A"; -- J
                        when x"42" => ascii_code <= x"4B"; -- K
                        when x"4B" => ascii_code <= x"4C"; -- L
                        when x"3A" => ascii_code <= x"4D"; -- M
                        when x"31" => ascii_code <= x"4E"; -- N
                        when x"44" => ascii_code <= x"4F"; -- O
                        when x"4D" => ascii_code <= x"50"; -- P
                        when x"15" => ascii_code <= x"51"; -- Q
                        when x"2D" => ascii_code <= x"52"; -- R
                        when x"1B" => ascii_code <= x"53"; -- S
                        when x"2C" => ascii_code <= x"54"; -- T
                        when x"3C" => ascii_code <= x"55"; -- U
                        when x"2A" => ascii_code <= x"56"; -- V
                        when x"1D" => ascii_code <= x"57"; -- W
                        when x"22" => ascii_code <= x"58"; -- X
                        when x"35" => ascii_code <= x"59"; -- Y
                        when x"1A" => ascii_code <= x"5A"; -- Z
                        when x"5A" => -- ENTER
                            ascii_code <= x"0D";
                            is_letter <= '0';
                            is_enter <= '1';
                        when x"66" => -- BACKSPACE
                            ascii_code <= x"08";
                            is_letter <= '0';
                            is_bksp <= '1';
                        when others =>
                            ascii_code <= x"20";
                            is_letter <= '0';
                            key_pulse <= '0';
                    end case;
                end if;
            end if;
        end if;
    end process;
end Behavioral;