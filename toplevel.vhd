library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity termo_top is
    Port (
        clk      : in  STD_LOGIC;
        rst      : in  STD_LOGIC;
        ps2_clk  : in  STD_LOGIC;
        ps2_data : in  STD_LOGIC;
        lcd_e    : out STD_LOGIC;
        lcd_rs   : out STD_LOGIC;
        lcd_rw   : out STD_LOGIC;
        lcd_db   : out STD_LOGIC_VECTOR(7 downto 0)
    );
end termo_top;

architecture Structural of termo_top is

    -- Components declaration
    component ps2_keyboard
        Port (
            clk        : in  STD_LOGIC;
            rst        : in  STD_LOGIC;
            ps2_clk    : in  STD_LOGIC;
            ps2_data   : in  STD_LOGIC;
            ascii_code : out STD_LOGIC_VECTOR(7 downto 0);
            key_pulse  : out STD_LOGIC;
            is_letter  : out STD_LOGIC;
            is_enter   : out STD_LOGIC;
            is_bksp    : out STD_LOGIC
        );
    end component;
    component termo_core
        Port (
            clk        : in  STD_LOGIC;
            rst        : in  STD_LOGIC;
            ascii_in   : in  STD_LOGIC_VECTOR(7 downto 0);
            key_pulse  : in  STD_LOGIC;
            is_letter  : in  STD_LOGIC;
            is_enter   : in  STD_LOGIC;
            is_bksp    : in  STD_LOGIC;
            lcd_line1  : out STD_LOGIC_VECTOR(127 downto 0);
            lcd_line2  : out STD_LOGIC_VECTOR(127 downto 0)
        );
    end component;
    component lcd_controller
        Port (
            clk       : in  STD_LOGIC;
            rst       : in  STD_LOGIC;
            line1_in  : in  STD_LOGIC_VECTOR(127 downto 0);
            line2_in  : in  STD_LOGIC_VECTOR(127 downto 0);
            lcd_e     : out STD_LOGIC;
            lcd_rs    : out STD_LOGIC;
            lcd_rw    : out STD_LOGIC;
            lcd_db    : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    -- Internal signals
    signal w_ascii     : STD_LOGIC_VECTOR(7 downto 0);
    signal w_key_pulse : STD_LOGIC;
    signal w_is_letter : STD_LOGIC;
    signal w_is_enter  : STD_LOGIC;
    signal w_is_bksp   : STD_LOGIC;
    signal w_line1     : STD_LOGIC_VECTOR(127 downto 0);
    signal w_line2     : STD_LOGIC_VECTOR(127 downto 0);

begin

    -- Components instantiation
    U_PS2: ps2_keyboard
        port map (
            clk        => clk,
            rst        => rst,
            ps2_clk    => ps2_clk,
            ps2_data   => ps2_data,
            ascii_code => w_ascii,
            key_pulse  => w_key_pulse,
            is_letter  => w_is_letter,
            is_enter   => w_is_enter,
            is_bksp    => w_is_bksp
        );
    U_CORE: termo_core
        port map (
            clk       => clk,
            rst       => rst,
            ascii_in  => w_ascii,
            key_pulse => w_key_pulse,
            is_letter => w_is_letter,
            is_enter  => w_is_enter,
            is_bksp   => w_is_bksp,
            lcd_line1 => w_line1,
            lcd_line2 => w_line2
        );
    U_LCD: lcd_controller
        port map (
            clk      => clk,
            rst      => rst,
            line1_in => w_line1,
            line2_in => w_line2,
            lcd_e    => lcd_e,
            lcd_rs   => lcd_rs,
            lcd_rw   => lcd_rw,
            lcd_db   => lcd_db
        );
end Structural;