library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity termo_core is
    Port (
        clk        : in  STD_LOGIC;
        rst        : in  STD_LOGIC;
        ascii_in   : in  STD_LOGIC_VECTOR(7 downto 0);
        key_pulse  : in  STD_LOGIC;
        is_letter  : in  STD_LOGIC;
        is_enter   : in  STD_LOGIC;
        is_bksp    : in  STD_LOGIC;
        lcd_line1  : out STD_LOGIC_VECTOR(127 downto 0); -- 16 chars
        lcd_line2  : out STD_LOGIC_VECTOR(127 downto 0)  -- 16 chars
    );
end termo_core;

architecture Behavioral of termo_core is
    type word5_t is array (0 to 4) of STD_LOGIC_VECTOR(7 downto 0);

    type state_t is (S_INIT, S_SET_WORD, S_PLAY, S_CHECK, S_WIN, S_LOSE);
    signal state       : state_t := S_INIT;

    signal secret_word : word5_t := (others => x"5F");
    signal guess_word  : word5_t := (others => x"5F"); 
    signal feedback    : word5_t := (others => x"20");
    signal eval_comb   : word5_t := (others => x"5F");

    signal cursor      : integer range 0 to 5 := 0;
    signal attempt     : integer range 1 to 6 := 1;
begin

    -- Two-pass combinational comparator
    -- '*' (0x2A) = exact match, '?' (0x3F) = misplaced, '_' (0x5F) = absent
    process(guess_word, secret_word)
        variable used : STD_LOGIC_VECTOR(4 downto 0);
        variable res : word5_t;
        variable matched : STD_LOGIC;
    begin
        used := "00000";
        res  := (others => x"5F"); -- Default '_'

        -- Check exact positions
        for i in 0 to 4 loop
            if guess_word(i) = secret_word(i) then
                res(i) := x"2A"; -- '*'
                used(i) := '1';
            end if;
        end loop;

        -- Check misplaced letters
        for i in 0 to 4 loop
            if res(i) /= x"2A" then
                matched := '0';
                for j in 0 to 4 loop
                    if (used(j) = '0') and (matched = '0') and (guess_word(i) = secret_word(j)) then
                        res(i) := x"3F"; -- '?'
                        used(j) := '1';
                        matched := '1';
                    end if;
                end loop;
            end if;
        end loop;

        eval_comb <= res;
    end process;

    -- Termo Finite State Machine (FSM)
    process(clk, rst)
    begin
        if rst = '1' then
            state <= S_INIT;
            cursor <= 0;
            attempt <= 1;
            secret_word <= (others => x"5F");
            guess_word <= (others => x"5F");
            feedback <= (others => x"20");
        elsif rising_edge(clk) then
            case state is
                when S_INIT =>
                    cursor <= 0;
                    attempt <= 1;
                    secret_word <= (others => x"5F");
                    guess_word <= (others => x"5F");
                    feedback <= (others => x"20");
                    if key_pulse = '1' and is_enter = '1' then
                        state <= S_SET_WORD;
                    end if;

                -- Defining the 5-letter secret word
                when S_SET_WORD =>
                    if key_pulse = '1' then
                        if is_letter = '1' and cursor < 5 then
                            secret_word(cursor) <= ascii_in;
                            cursor <= cursor + 1;
                        elsif is_bksp = '1' and cursor > 0 then
                            secret_word(cursor - 1) <= x"5F"; -- '_'
                            cursor <= cursor - 1;
                        elsif is_enter = '1' and cursor = 5 then
                            cursor <= 0;
                            attempt <= 1;
                            guess_word <= (others => x"5F");
                            feedback <= (others => x"20");
                            state <= S_PLAY;
                        end if;
                    end if;

                -- Guessing the secret word
                when S_PLAY =>
                    if key_pulse = '1' then
                        if is_letter = '1' and cursor < 5 then
                            guess_word(cursor) <= ascii_in;
                            cursor <= cursor + 1;
                        elsif is_bksp = '1' and cursor > 0 then
                            guess_word(cursor - 1) <= x"5F"; -- '_'
                            cursor <= cursor - 1;
                        elsif is_enter = '1' and cursor = 5 then
                            state <= S_CHECK;
                        end if;
                    end if;

                when S_CHECK =>
                    feedback <= eval_comb;
                    if eval_comb = (x"2A", x"2A", x"2A", x"2A", x"2A") then
                        state <= S_WIN;
                    elsif attempt = 6 then
                        state <= S_LOSE;
                    else
                        attempt <= attempt + 1;
                        cursor <= 0;
                        guess_word <= (others => x"5F");
                        state <= S_PLAY;
                    end if;

                when S_WIN | S_LOSE =>
                    if key_pulse = '1' and is_enter = '1' then
                        state <= S_INIT;
                    end if;
            end case;
        end if;
    end process;

    -- Format 16x2 LCD Strings
    process(state, attempt, secret_word, guess_word, feedback)
        variable att_ascii : STD_LOGIC_VECTOR(7 downto 0);
    begin
        att_ascii := std_logic_vector(to_unsigned(48 + attempt, 8));

        case state is
            when S_INIT =>
                -- "  JOGO TERMO    "
                lcd_line1 <= x"20204A4F474F205445524D4F20202020";
                -- " TECLE <ENTER>  "
                lcd_line2 <= x"205445434C45203C454E5445523E2020";

            when S_SET_WORD =>
                -- Line 1: "PALAVRA SECRETA:"
                lcd_line1 <= x"50414C4156524120534543524554413A";
                -- Line 2: "DIGITE: " & 5 secret chars & "   "
                lcd_line2 <= x"4449474954453A20" &
                             secret_word(0) & secret_word(1) & secret_word(2) & secret_word(3) & secret_word(4) &
                             x"202020";

            when S_PLAY | S_CHECK =>
                -- Line 1: "T" & att & "/6:   " & 5 guess chars & "   "
                lcd_line1 <= x"54" & att_ascii & x"2F363A202020" &
                             guess_word(0) & guess_word(1) & guess_word(2) & guess_word(3) & guess_word(4) &
                             x"202020";
                -- Line 2: "RESP:   " & 5 feedback chars & "   "
                lcd_line2 <= x"524553503A202020" &
                             feedback(0) & feedback(1) & feedback(2) & feedback(3) & feedback(4) &
                             x"202020";

            when S_WIN =>
                -- Line 1: "ACERTOU: " & secret_word & "  "
                lcd_line1 <= x"41434552544F553A20" &
                             secret_word(0) & secret_word(1) & secret_word(2) & secret_word(3) & secret_word(4) &
                             x"2020";
                -- Line 2: "VITORIA! (ENTER)"
                lcd_line2 <= x"5649544F524941212028454E54455229";

            when S_LOSE =>
                -- Line 1: "FIM! ERA: " & secret_word & " "
                lcd_line1 <= x"46494D21204552413A20" &
                             secret_word(0) & secret_word(1) & secret_word(2) & secret_word(3) & secret_word(4) &
                             x"20";
                -- Line 2: "TENTE NOVAMENTE!"
                lcd_line2 <= x"54454E5445204E4F56414D454E544521";
        end case;
    end process;
end Behavioral;