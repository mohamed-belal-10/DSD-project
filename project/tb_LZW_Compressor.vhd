library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_LZW_Compressor is
end tb_LZW_Compressor;

architecture Behavioral of tb_LZW_Compressor is
    -- Testbench signals
    signal clk          : std_logic := '0';
    signal rst          : std_logic := '1';
    signal pixel_in     : std_logic_vector(7 downto 0) := (others => '0');
    signal pixel_valid  : std_logic := '0';
    signal start        : std_logic := '0';
    signal code_out     : std_logic_vector(11 downto 0);
    signal code_valid   : std_logic;
    signal done         : std_logic;

    -- Example 8-pixel grayscale image data (can expand as needed)
    type img_array_type is array (0 to 7) of std_logic_vector(7 downto 0);
    constant test_img : img_array_type := (
        x"12", x"12", x"23", x"23", x"34", x"12", x"23", x"34"
    );

    signal img_idx      : integer range 0 to 8 := 0;
    signal send_done    : std_logic := '0';

begin
    -- Instantiate the LZW compressor
    uut: entity work.LZW_Compressor
        port map (
            clk         => clk,
            rst         => rst,
            pixel_in    => pixel_in,
            pixel_valid => pixel_valid,
            start       => start,
            code_out    => code_out,
            code_valid  => code_valid,
            done        => done
        );

    -- Clock generation
    clk_process: process
    begin
        while now < 5000 ns loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
        wait;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Reset
        rst   <= '1';
        start <= '0';
        wait for 20 ns;
        rst   <= '0';
        wait for 20 ns;

        -- Start compression
        start <= '1';
        wait for 10 ns;
        start <= '0';

        -- Feed image pixels
        for i in 0 to 7 loop
            pixel_in    <= test_img(i);
            pixel_valid <= '1';
            wait for 10 ns;
            pixel_valid <= '0';
            wait for 10 ns;
        end loop;

        -- End pixel input
        wait for 100 ns;
        wait;
    end process;

    -- Catch output codes as they appear
    monitor: process(clk)
    begin
        if rising_edge(clk) then
            if code_valid = '1' then
                report "Code emitted: " & integer'image(to_integer(unsigned(code_out)));
            end if;
        end if;
    end process;

end Behavioral;

