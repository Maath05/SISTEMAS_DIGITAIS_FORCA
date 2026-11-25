library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity projeto_forca is
    port (
        clk   : in  std_logic;
        reset : in  std_logic;

        
        RS    : out std_logic;
        RW    : out std_logic;
        E     : out std_logic;
        DB    : out std_logic_vector(7 downto 0);

        
        ps2d  : in  std_logic;
        ps2c  : in  std_logic
    );
end entity projeto_forca;

architecture behavioral of projeto_forca is

    type state_type is (
        aguarda_letra,
        compara_letra,
        verifica_vitoria,
        erro,
        fim_jogo
    );
    signal estado_atual : state_type := aguarda_letra;

    signal rd_key_code  : std_logic := '0';
    signal key_code     : std_logic_vector(7 downto 0);
    signal kb_buf_empty : std_logic;

    signal hits        : std_logic_vector(4 downto 0) := (others => '0');
    signal error_count : unsigned(2 downto 0) := (others => '0');

begin

    game_fsm : process(clk, reset)
    begin
        if reset = '1' then
            hits         <= (others => '0');
            error_count  <= (others => '0');
            rd_key_code  <= '0';
            estado_atual <= aguarda_letra;

        elsif rising_edge(clk) then
            case estado_atual is

                when aguarda_letra =>
                    rd_key_code <= '0';
                    if kb_buf_empty = '0' then
                        rd_key_code  <= '1';
                        estado_atual <= compara_letra;
                    end if;

                when compara_letra =>
                    rd_key_code <= '0';
                    case key_code is
                        when x"2B" => -- 'F'
                            hits(4)      <= '1';
                            estado_atual <= verifica_vitoria;
                        when x"44" => -- 'O'
                            hits(3)      <= '1';
                            estado_atual <= verifica_vitoria;
                        when x"2D" => -- 'R'
                            hits(2)      <= '1';
                            estado_atual <= verifica_vitoria;
                        when x"21" => -- 'C'
                            hits(1)      <= '1';
                            estado_atual <= verifica_vitoria;
                        when x"1C" => -- 'A'
                            hits(0)      <= '1';
                            estado_atual <= verifica_vitoria;
                        when others =>
                            estado_atual <= erro;
                    end case;

                when verifica_vitoria =>
                    if hits = "11111" then
                        estado_atual <= fim_jogo;
                    else
                        estado_atual <= aguarda_letra;
                    end if;

                when erro =>
                    if error_count = 4 then
                        error_count  <= to_unsigned(5, 3);
                        estado_atual <= fim_jogo;
                    else
                        error_count  <= error_count + 1;
                        estado_atual <= aguarda_letra;
                    end if;

                when fim_jogo =>
                    null;

            end case;
        end if;
    end process game_fsm;

    keyboard_unit : entity work.kb_code(arch)
        generic map (
            W_SIZE => 2
        )
        port map (
            clk          => clk,
            reset        => reset,
            ps2d         => ps2d,
            ps2c         => ps2c,
            rd_key_code  => rd_key_code,
            key_code     => key_code,
            kb_buf_empty => kb_buf_empty
        );

    display_unit : entity work.lcd_fpga(rtl)
        generic map (
            FCLK => 50_000_000
        )
        port map (
            clk         => clk,
            reset       => reset,
            hits        => hits,
            error_count => std_logic_vector(error_count),
            RS          => RS,
            RW          => RW,
            E           => E,
            DB          => DB
        );

end architecture behavioral;