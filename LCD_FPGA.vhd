library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lcd_fpga is
    generic (
        FCLK : natural := 50_000_000 
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        hits        : in  std_logic_vector(4 downto 0); 
        error_count : in  std_logic_vector(2 downto 0); 
        RS          : out std_logic;
        RW          : out std_logic;
        E           : out std_logic;
        DB          : out std_logic_vector(7 downto 0)
    );
end entity lcd_fpga;

architecture rtl of lcd_fpga is

    
    constant TICK_MAX : natural := (FCLK / 1000) - 1;
    signal tick_cnt   : natural range 0 to TICK_MAX := 0;
    signal tick_1ms   : std_logic := '0';
    signal e_reg      : std_logic := '0';

    
    type lcd_state_type is (ST_INIT, ST_LINE1, ST_SET_ADDR, ST_LINE2, ST_HOME);
    signal state    : lcd_state_type := ST_INIT;
    signal step_idx : natural range 0 to 12 := 0;

    
    type rom5_t is array (0 to 4) of std_logic_vector(7 downto 0);
    type rom6_t is array (0 to 5) of std_logic_vector(7 downto 0);
    type rom7_t is array (0 to 6) of std_logic_vector(7 downto 0);

    
    constant INIT_ROM  : rom5_t := (x"38", x"38", x"01", x"0C", x"06");
    constant WORD_ROM  : rom5_t := (x"46", x"4F", x"52", x"43", x"41"); 
    constant VIDAS_ROM : rom6_t := (x"56", x"69", x"64", x"61", x"73", x"3A"); 
    constant WIN_ROM   : rom7_t := (x"47", x"41", x"4E", x"48", x"4F", x"55", x"21"); 
    constant LOSE_ROM  : rom7_t := (x"50", x"45", x"52", x"44", x"45", x"55", x"21"); 

    
    signal won        : std_logic;
    signal lost       : std_logic;
    signal line1_char : std_logic_vector(7 downto 0);
    signal line2_char : std_logic_vector(7 downto 0);

begin

    won  <= '1' when hits = "11111" else '0';
    lost <= '1' when error_count = "101" else '0';

  
    process(step_idx, hits, won, lost)
    begin
        if step_idx <= 4 then
            if hits(4 - step_idx) = '1' then
                line1_char <= WORD_ROM(step_idx);
            else
                line1_char <= x"5F"; -- '_'
            end if;
        elsif step_idx = 5 then
            line1_char <= x"20"; 
        else
            if won = '1' then
                line1_char <= WIN_ROM(step_idx - 6);
            elsif lost = '1' then
                line1_char <= LOSE_ROM(step_idx - 6);
            else
                line1_char <= x"20"; 
            end if;
        end if;
    end process;

 
    process(step_idx, error_count)
    begin
        if step_idx <= 5 then
            line2_char <= VIDAS_ROM(step_idx);
        elsif step_idx <= 10 then
            if unsigned(error_count) < (11 - step_idx) then
                line2_char <= x"2A"; -- '*'
            else
                line2_char <= x"20"; -- ' '
            end if;
        else
            line2_char <= x"20";
        end if;
    end process;

 
    process(clk, reset)
    begin
        if reset = '1' then
            tick_cnt <= 0;
            tick_1ms <= '0';
        elsif rising_edge(clk) then
            if tick_cnt = TICK_MAX then
                tick_cnt <= 0;
                tick_1ms <= '1';
            else
                tick_cnt <= tick_cnt + 1;
                tick_1ms <= '0';
            end if;
        end if;
    end process;

 
    process(clk, reset)
    begin
        if reset = '1' then
            e_reg    <= '0';
            state    <= ST_INIT;
            step_idx <= 0;
            RS       <= '0';
            RW       <= '0';
            DB       <= x"38";
        elsif rising_edge(clk) then
            if tick_1ms = '1' then
                if e_reg = '0' then
                   
                    e_reg <= '1';
                    case state is
                        when ST_INIT =>
                            RS <= '0';
                            RW <= '0';
                            DB <= INIT_ROM(step_idx);
                            if step_idx = 4 then
                                step_idx <= 0;
                                state    <= ST_LINE1;
                            else
                                step_idx <= step_idx + 1;
                            end if;

                        when ST_LINE1 =>
                            RS <= '1';
                            RW <= '0';
                            DB <= line1_char;
                            if step_idx = 12 then
                                step_idx <= 0;
                                state    <= ST_SET_ADDR;
                            else
                                step_idx <= step_idx + 1;
                            end if;

                        when ST_SET_ADDR =>
                            RS       <= '0';
                            RW       <= '0';
                            DB       <= x"C5"; 
                            step_idx <= 0;
                            state    <= ST_LINE2;

                        when ST_LINE2 =>
                            RS <= '1';
                            RW <= '0';
                            DB <= line2_char;
                            if step_idx = 10 then
                                step_idx <= 0;
                                state    <= ST_HOME;
                            else
                                step_idx <= step_idx + 1;
                            end if;

                        when ST_HOME =>
                            RS       <= '0';
                            RW       <= '0';
                            DB       <= x"80"; 
                            step_idx <= 0;
                            state    <= ST_LINE1;
                    end case;
                else
                    
                    e_reg <= '0';
                end if;
            end if;
        end if;
    end process;

    E <= e_reg;

end architecture rtl;