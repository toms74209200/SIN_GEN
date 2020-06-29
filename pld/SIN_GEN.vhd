-- ============================================================================
--  Title       : SIN wave generator
--
--  File Name   : SIN_GEN.vhd
--  Project     : Sample
--  Designer    : toms74209200 <https://github.com/toms74209200>
--  Created     : 2020/06/24
--  Copyright   : 2020 toms74209200
--  License     : MIT License.
--                http://opensource.org/licenses/mit-license.php
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;

entity SIN_GEN is
    generic(
        DW              : integer := 16                                 -- Data width
    );
    port(
    -- System --
        RESET_n         : in    std_logic;                              --(n) Reset
        CLK             : in    std_logic;                              --(p) Clock

    -- Control --
        ASI_READY       : out   std_logic;                              --(p) Avalon-ST sink data ready
        ASI_VALID       : in    std_logic;                              --(p) Avalon-ST sink data valid
        ASI_DATA        : in    std_logic_vector(DW-1 downto 0);        --(p) Avalon-ST sink data: Frequency ratio
        ASO_VALID       : out   std_logic;                              --(p) Avalon-ST source data valid
        ASO_DATA        : out   std_logic_vector(DW-1 downto 0);        --(p) Avalon-ST source data: SIN wave
        ASO_ERROR       : out   std_logic                               --(p) Avalon-ST source error
    );
end SIN_GEN;

architecture RTL of SIN_GEN is

-- Parameters --
constant TABLE_SIZE     : integer := 256;                               -- ROM table size
constant DC_OFFSET      : std_logic_vector(ASI_DATA'range) := X"7fff";  -- DC offset

-- Internal signals --
signal  dec_cnt         : std_logic_vector(ASI_DATA'range);             -- Decimation counter
signal  dec_pls_i       : std_logic;                                    -- Decimation point pulse
signal  dat_cnt         : integer range 0 to TABLE_SIZE-1;              -- Data counter
signal  phs_pls_i       : std_logic;                                    -- Wave phase pulse
signal  phs_cnt         : std_logic_vector(1 downto 0);                 -- Wave phase counter
signal  dat_i           : std_logic_vector(ASI_DATA'range);             -- Data

-- ROM data type --
type    RomTableType    is array(0 to TABLE_SIZE-1) of std_logic_vector(DW-1 downto 0);

-- Function --
function readFile(read_file_name : in string)                           -- Read data table file
return RomTableType is
    FILE read_file              : text is in read_file_name;
    variable read_file_line     : line;
    variable file_data_array    : RomTableType;
begin
    for i in RomTableType'range loop
        readline(read_file, read_file_line);
        hread(read_file_line, file_data_array(i));
    end loop;
    return file_data_array;
end function;

-- ROM table --
constant SIN_ROM_TABLE  : RomTableType := readFile("pld/sin_rom_table.txt");

begin

-- ============================================================================
--  Decimation counter
-- ============================================================================
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        dec_cnt <= (others => '0');
    elsif (CLK'event and CLK = '1') then
        if (ASI_VALID = '1') then
            if (dec_pls_i = '1') then
                dec_cnt <= (others => '0');
            else
                dec_cnt <= dec_cnt + 1;
            end if;
        else
            dec_cnt <= (others => '0');
        end if;
    end if;
end process;

dec_pls_i <= '1' when (dec_cnt = ASI_DATA) else '0';


-- ============================================================================
--  Data counter
-- ============================================================================
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        dat_cnt <= 0;
    elsif (CLK'event and CLK = '1') then
        if (ASI_VALID = '1') then
            if (ASI_DATA = 0) then
                if (phs_pls_i = '1') then
                    dat_cnt <= 0;
                else
                    dat_cnt <= dat_cnt + 1;
                end if;
            else
                if (dec_pls_i = '1') then
                    if (phs_pls_i = '1') then
                        dat_cnt <= 0;
                    else
                        dat_cnt <= dat_cnt + 1;
                    end if;
                end if;
            end if;
        else
            dat_cnt <= 0;
        end if;
    end if;
end process;

phs_pls_i <= '1' when (dat_cnt = TABLE_SIZE - 1) else '0';


-- ============================================================================
--  Data counter
-- ============================================================================
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        phs_cnt <= (others => '0');
    elsif (CLK'event and CLK = '1') then
        if (ASI_VALID = '1') then
            if (phs_pls_i = '1') then
                if (ASI_DATA = 0) then
                    if (phs_cnt = 3) then
                        phs_cnt <= (others => '0');
                    else
                        phs_cnt <= phs_cnt + 1;
                    end if;
                else
                    if (dec_pls_i = '1') then
                        if (phs_cnt = 3) then
                            phs_cnt <= (others => '0');
                        else
                            phs_cnt <= phs_cnt + 1;
                        end if;
                    end if;
                end if;
            end if;
        else
            phs_cnt <= (others => '0');
        end if;
    end if;
end process;


-- ============================================================================
--  Data
-- ============================================================================
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        dat_i <= (others => '0');
    elsif (CLK'event and CLK = '1') then
        if (ASI_VALID = '1') then
            case phs_cnt is
                when "00" => dat_i <= SIN_ROM_TABLE(dat_cnt) + DC_OFFSET;
                when "01" => dat_i <= SIN_ROM_TABLE(TABLE_SIZE - dat_cnt - 1) + DC_OFFSET;
                when "10" => dat_i <= not SIN_ROM_TABLE(dat_cnt) + DC_OFFSET;
                when "11" => dat_i <= not SIN_ROM_TABLE(TABLE_SIZE - dat_cnt - 1) + DC_OFFSET;
                when others => dat_i <= (others => '0');
            end case;
        else
            dat_i <= (others => '0');
        end if;
    end if;
end process;

ASO_DATA <= dat_i;

-- Output SIN signal frequency --
-- = fclk /(4 * signal table length(RAM word num) * (ratio + 1))

end RTL; --SIN_GEN
