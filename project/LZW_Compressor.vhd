library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LZW_Compressor is
    generic (
        PIXEL_WIDTH : integer := 8; -- 8 bits for greyscale pixels
        CODE_WIDTH  : integer := 12; -- Typical LZW output code width
        DICT_SIZE   : integer := 4096  -- Dictionary size (2^12)
    );
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        pixel_in    : in  std_logic_vector(PIXEL_WIDTH-1 downto 0);
        pixel_valid : in  std_logic;
        start       : in  std_logic;  -- Start compression flag
        code_out    : out std_logic_vector(CODE_WIDTH-1 downto 0);
        code_valid  : out std_logic;
        done        : out std_logic
    );
end entity;

architecture Behavioral of LZW_Compressor is

    type string_array is array (0 to DICT_SIZE-1) of std_logic_vector(PIXEL_WIDTH*2-1 downto 0);
    type dict_entry_array is array (0 to DICT_SIZE-1) of std_logic_vector(PIXEL_WIDTH*2-1 downto 0);

    signal dictionary : dict_entry_array;
    signal dict_index : integer range 0 to DICT_SIZE-1 := 0;
    signal curr_str   : std_logic_vector(PIXEL_WIDTH*2-1 downto 0);
    signal match_idx  : integer range 0 to DICT_SIZE-1;
    signal match      : std_logic := '0';
    signal compressing: std_logic := '0';
    signal output_buf : std_logic_vector(CODE_WIDTH-1 downto 0);
    signal output_vld : std_logic := '0';

begin

    process(clk, rst)
    begin
        if rst = '1' then
            curr_str    <= (others => '0');
            dict_index  <= 0;
            match_idx   <= 0;
            compressing <= '0';
            output_buf  <= (others => '0');
            output_vld  <= '0';
            done        <= '0';
            for i in 0 to DICT_SIZE-1 loop
                dictionary(i) <= (others => '0');
            end loop;

        elsif rising_edge(clk) then
            if start = '1' then
                compressing <= '1';
                done <= '0';
                dict_index <= 0;
                -- Initialize dictionary to single pixel values
                for i in 0 to 255 loop
                    dictionary(i)(PIXEL_WIDTH-1 downto 0) <= std_logic_vector(to_unsigned(i, PIXEL_WIDTH));
                    dictionary(i)(PIXEL_WIDTH*2-1 downto PIXEL_WIDTH) <= (others => '0');
                end loop;
                for i in 256 to DICT_SIZE-1 loop
                    dictionary(i) <= (others => '0');
                end loop;
            end if;

            if compressing = '1' then
                if pixel_valid = '1' then
                    -- Compose new string by appending symbol
                    curr_str(PIXEL_WIDTH*2-1 downto PIXEL_WIDTH) <= curr_str(PIXEL_WIDTH-1 downto 0);
                    curr_str(PIXEL_WIDTH-1 downto 0) <= pixel_in;
                    
                    -- Search dictionary for curr_str
                    match   <= '0';
                    match_idx <= 0; 
                    for i in 0 to dict_index-1 loop
                        if dictionary(i) = curr_str then
                            match <= '1';
                            match_idx <= i;
                        end if;
                    end loop;
                    
                    if match = '1' then
                        -- String found, wait for next pixel
                    else
                        -- Output code for curr_str prefix
                        output_buf <= std_logic_vector(to_unsigned(match_idx, CODE_WIDTH));
                        output_vld <= '1';
                        -- Add new string to dictionary
                        if dict_index < DICT_SIZE-1 then
                            dictionary(dict_index) <= curr_str;
                            dict_index <= dict_index + 1;
                        end if;
                        -- Reset curr_str to last symbol
                        curr_str(PIXEL_WIDTH*2-1 downto PIXEL_WIDTH) <= (others => '0');
                        curr_str(PIXEL_WIDTH-1 downto 0) <= pixel_in;
                    end if;
                else
                    output_vld <= '0';
                end if;
                -- Termination logic (example)
                if false then
                    compressing <= '0';
                    done <= '1';
                end if;
            end if;
        end if;
    end process;

    code_out   <= output_buf;
    code_valid <= output_vld;

end architecture;

