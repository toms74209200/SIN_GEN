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

-- ROM table --
type    RomTableType    is array(0 to TABLE_SIZE-1) of std_logic_vector(DW-1 downto 0);
constant SIN_ROM_TABLE  : RomTableType := (
    X"0000",
    X"00c9",
    X"0192",
    X"025b",
    X"0324",
    X"03ed",
    X"04b6",
    X"057e",
    X"0647",
    X"0710",
    X"07d9",
    X"08a1",
    X"096a",
    X"0a32",
    X"0afb",
    X"0bc3",
    X"0c8b",
    X"0d53",
    X"0e1b",
    X"0ee3",
    X"0fab",
    X"1072",
    X"1139",
    X"1200",
    X"12c7",
    X"138e",
    X"1455",
    X"151b",
    X"15e1",
    X"16a7",
    X"176d",
    X"1833",
    X"18f8",
    X"19bd",
    X"1a82",
    X"1b46",
    X"1c0b",
    X"1ccf",
    X"1d93",
    X"1e56",
    X"1f19",
    X"1fdc",
    X"209f",
    X"2161",
    X"2223",
    X"22e4",
    X"23a6",
    X"2467",
    X"2527",
    X"25e7",
    X"26a7",
    X"2767",
    X"2826",
    X"28e5",
    X"29a3",
    X"2a61",
    X"2b1e",
    X"2bdb",
    X"2c98",
    X"2d54",
    X"2e10",
    X"2ecc",
    X"2f86",
    X"3041",
    X"30fb",
    X"31b4",
    X"326d",
    X"3326",
    X"33de",
    X"3496",
    X"354d",
    X"3603",
    X"36b9",
    X"376f",
    X"3824",
    X"38d8",
    X"398c",
    X"3a3f",
    X"3af2",
    X"3ba4",
    X"3c56",
    X"3d07",
    X"3db7",
    X"3e67",
    X"3f16",
    X"3fc5",
    X"4073",
    X"4120",
    X"41cd",
    X"4279",
    X"4325",
    X"43d0",
    X"447a",
    X"4523",
    X"45cc",
    X"4674",
    X"471c",
    X"47c3",
    X"4869",
    X"490e",
    X"49b3",
    X"4a57",
    X"4afa",
    X"4b9d",
    X"4c3f",
    X"4ce0",
    X"4d80",
    X"4e20",
    X"4ebf",
    X"4f5d",
    X"4ffa",
    X"5097",
    X"5133",
    X"51ce",
    X"5268",
    X"5301",
    X"539a",
    X"5432",
    X"54c9",
    X"555f",
    X"55f4",
    X"5689",
    X"571d",
    X"57b0",
    X"5842",
    X"58d3",
    X"5963",
    X"59f3",
    X"5a81",
    X"5b0f",
    X"5b9c",
    X"5c28",
    X"5cb3",
    X"5d3d",
    X"5dc6",
    X"5e4f",
    X"5ed6",
    X"5f5d",
    X"5fe2",
    X"6067",
    X"60eb",
    X"616e",
    X"61f0",
    X"6271",
    X"62f1",
    X"6370",
    X"63ee",
    X"646b",
    X"64e7",
    X"6562",
    X"65dd",
    X"6656",
    X"66ce",
    X"6745",
    X"67bc",
    X"6831",
    X"68a5",
    X"6919",
    X"698b",
    X"69fc",
    X"6a6c",
    X"6adb",
    X"6b4a",
    X"6bb7",
    X"6c23",
    X"6c8e",
    X"6cf8",
    X"6d61",
    X"6dc9",
    X"6e30",
    X"6e95",
    X"6efa",
    X"6f5e",
    X"6fc0",
    X"7022",
    X"7082",
    X"70e1",
    X"7140",
    X"719d",
    X"71f9",
    X"7254",
    X"72ae",
    X"7306",
    X"735e",
    X"73b5",
    X"740a",
    X"745e",
    X"74b1",
    X"7503",
    X"7554",
    X"75a4",
    X"75f3",
    X"7640",
    X"768d",
    X"76d8",
    X"7722",
    X"776b",
    X"77b3",
    X"77f9",
    X"783f",
    X"7883",
    X"78c6",
    X"7908",
    X"7949",
    X"7989",
    X"79c7",
    X"7a04",
    X"7a41",
    X"7a7c",
    X"7ab5",
    X"7aee",
    X"7b25",
    X"7b5c",
    X"7b91",
    X"7bc4",
    X"7bf7",
    X"7c29",
    X"7c59",
    X"7c88",
    X"7cb6",
    X"7ce2",
    X"7d0e",
    X"7d38",
    X"7d61",
    X"7d89",
    X"7db0",
    X"7dd5",
    X"7df9",
    X"7e1c",
    X"7e3e",
    X"7e5e",
    X"7e7e",
    X"7e9c",
    X"7eb9",
    X"7ed4",
    X"7eef",
    X"7f08",
    X"7f20",
    X"7f37",
    X"7f4c",
    X"7f61",
    X"7f74",
    X"7f86",
    X"7f96",
    X"7fa6",
    X"7fb4",
    X"7fc1",
    X"7fcd",
    X"7fd7",
    X"7fe0",
    X"7fe8",
    X"7fef",
    X"7ff5",
    X"7ff9",
    X"7ffc",
    X"7ffe"
);

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
