library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAM is
    port (
        clk         : in std_logic;
        rst         : in std_logic;
        
        -- Write ports - independent for each bank
        wr_en       : in std_logic_vector(3 downto 0);                    -- Write enable for each bank
        wr_addr_0   : in std_logic_vector(6 downto 0);                   -- Write address for bank 0
        wr_addr_1   : in std_logic_vector(6 downto 0);                   -- Write address for bank 1
        wr_addr_2   : in std_logic_vector(6 downto 0);                   -- Write address for bank 2
        wr_addr_3   : in std_logic_vector(6 downto 0);                   -- Write address for bank 3
        wr_data_0   : in std_logic_vector(23 downto 0);                  -- Write data for bank 0
        wr_data_1   : in std_logic_vector(23 downto 0);                  -- Write data for bank 1
        wr_data_2   : in std_logic_vector(23 downto 0);                  -- Write data for bank 2
        wr_data_3   : in std_logic_vector(23 downto 0);                  -- Write data for bank 3
        
        -- Read ports - independent for each bank
        rd_en       : in std_logic_vector(3 downto 0);                    -- Read enable for each bank
        rd_addr_0   : in std_logic_vector(6 downto 0);                   -- Read address for bank 0
        rd_addr_1   : in std_logic_vector(6 downto 0);                   -- Read address for bank 1
        rd_addr_2   : in std_logic_vector(6 downto 0);                   -- Read address for bank 2
        rd_addr_3   : in std_logic_vector(6 downto 0);                   -- Read address for bank 3
        rd_data_0   : out std_logic_vector(23 downto 0);                 -- Read data from bank 0
        rd_data_1   : out std_logic_vector(23 downto 0);                 -- Read data from bank 1
        rd_data_2   : out std_logic_vector(23 downto 0);                 -- Read data from bank 2
        rd_data_3   : out std_logic_vector(23 downto 0)                  -- Read data from bank 3
    );
end RAM;

architecture rtl of RAM is
    -- Constants
    constant ADDR_WIDTH : integer := 7;   -- 128 addresses need 7 bits
    constant DATA_WIDTH : integer := 24;  -- 24-bit data width
    constant NUM_BANKS : integer := 4;    -- Number of banks
    
    -- Memory type definitions
    type ram_type is array (0 to 127) of std_logic_vector(DATA_WIDTH-1 downto 0);
    type bank_array is array (0 to NUM_BANKS-1) of ram_type;
    
    -- Memory signals
    signal ram_banks : bank_array;
    
    -- Arrays to handle multiple addresses and data
    type addr_array is array (0 to NUM_BANKS-1) of std_logic_vector(ADDR_WIDTH-1 downto 0);
    type data_array is array (0 to NUM_BANKS-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    
    signal wr_addr_array : addr_array;
    signal rd_addr_array : addr_array;
    signal wr_data_array : data_array;
    signal rd_data_array : data_array;

begin
    -- Map individual signals to arrays for easier processing
    wr_addr_array <= (wr_addr_0, wr_addr_1, wr_addr_2, wr_addr_3);
    rd_addr_array <= (rd_addr_0, rd_addr_1, rd_addr_2, rd_addr_3);
    wr_data_array <= (wr_data_0, wr_data_1, wr_data_2, wr_data_3);
    
    -- Map output data
    rd_data_0 <= rd_data_array(0);
    rd_data_1 <= rd_data_array(1);
    rd_data_2 <= rd_data_array(2);
    rd_data_3 <= rd_data_array(3);

    -- Generate separate processes for each bank
    gen_banks: for i in 0 to NUM_BANKS-1 generate
        -- Memory process for bank i
        process(clk)
        begin
            if rising_edge(clk) then
                if rst = '1' then
                    -- Reset this bank
                    for addr in 0 to 127 loop
                        ram_banks(i)(addr) <= (others => '0');
                    end loop;
                    rd_data_array(i) <= (others => '0');
                    
                else
                    -- Write operation (Port A)
                    if wr_en(i) = '1' then
                        ram_banks(i)(to_integer(unsigned(wr_addr_array(i)))) <= wr_data_array(i);
                    end if;
                    
                    -- Read operation (Port B)
                    if rd_en(i) = '1' then
                        rd_data_array(i) <= ram_banks(i)(to_integer(unsigned(rd_addr_array(i))));
                    end if;
                end if;
            end if;
        end process;
    end generate;

end rtl;