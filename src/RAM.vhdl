library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAM is
    port (
        clk         : in std_logic;
        rst         : in std_logic;
        enable      : in std_logic;
        -- Write ports - independent for each bank
        wr_en       : in std_logic_vector(3 downto 0);                   -- Write enable for each bank
        wr_addr_0   : in std_logic_vector(4 downto 0);                   -- Write address for bank 0
        wr_addr_1   : in std_logic_vector(4 downto 0);                   -- Write address for bank 1
        wr_addr_2   : in std_logic_vector(4 downto 0);                   -- Write address for bank 2
        wr_addr_3   : in std_logic_vector(4 downto 0);                   -- Write address for bank 3
        wr_data_0   : in std_logic_vector(23 downto 0);                  -- Write data for bank 0
        wr_data_1   : in std_logic_vector(23 downto 0);                  -- Write data for bank 1
        wr_data_2   : in std_logic_vector(23 downto 0);                  -- Write data for bank 2
        wr_data_3   : in std_logic_vector(23 downto 0);                  -- Write data for bank 3
        
        -- Read ports - independent for each bank
        rd_en       : in std_logic_vector(3 downto 0);                   -- Read enable for each bank
        rd_addr_0   : in std_logic_vector(4 downto 0);                   -- Read address for bank 0
        rd_addr_1   : in std_logic_vector(4 downto 0);                   -- Read address for bank 1
        rd_addr_2   : in std_logic_vector(4 downto 0);                   -- Read address for bank 2
        rd_addr_3   : in std_logic_vector(4 downto 0);                   -- Read address for bank 3
        rd_data_0   : out std_logic_vector(23 downto 0);                 -- Read data from bank 0
        rd_data_1   : out std_logic_vector(23 downto 0);                 -- Read data from bank 1
        rd_data_2   : out std_logic_vector(23 downto 0);                 -- Read data from bank 2
        rd_data_3   : out std_logic_vector(23 downto 0)                  -- Read data from bank 3
    );
end RAM;

architecture rtl of RAM is

    component bram0
        port (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(23 DOWNTO 0) 
        );
    end component;

    component bram1
        port (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(23 DOWNTO 0) 
        );
    end component;
    
    component bram2
    port (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
        clkb : IN STD_LOGIC;
        enb : IN STD_LOGIC;
        addrb : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(23 DOWNTO 0) 
        );
    end component;
    
    component bram3
    port (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
        clkb : IN STD_LOGIC;
        enb : IN STD_LOGIC;
        addrb : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(23 DOWNTO 0) 
        );
    end component;

begin
    mem_bank_0 : bram0
    port map(
        clka => clk,
        ena => enable,
        wea => wr_en(0 downto 0),
        addra => wr_addr_0,
        dina => wr_data_0,
        clkb => clk,
        enb => rd_en(0),
        addrb => rd_addr_0,
        doutb => rd_data_0
    );

    mem_bank_1 : bram1
    port map(
        clka => clk,
        ena => enable,
        wea => wr_en(1 downto 1),
        addra => wr_addr_1,
        dina => wr_data_1,
        clkb => clk,
        enb => rd_en(1),
        addrb => rd_addr_1,
        doutb => rd_data_1
    );

    mem_bank_2 : bram2
    port map(
        clka => clk,
        ena => enable,
        wea => wr_en(2 downto 2),
        addra => wr_addr_2,
        dina => wr_data_2,
        clkb => clk,
        enb => rd_en(2),
        addrb => rd_addr_2,
        doutb => rd_data_2
    );

    mem_bank_3 : bram3
    port map(
        clka => clk,
        ena => enable,
        wea => wr_en(3 downto 3),
        addra => wr_addr_3,
        dina => wr_data_3,
        clkb => clk,
        enb => rd_en(3),
        addrb => rd_addr_3,
        doutb => rd_data_3
    );


end rtl;