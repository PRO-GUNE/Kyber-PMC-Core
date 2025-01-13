library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PMC_CORE is
  port (
    clk : in std_logic;
    reset : in std_logic;
    mode  : in  std_logic_vector(1 downto 0); -- Input selection (00: NTT, 01: INTT, 10: PWM)
    enable_BUT : in std_logic;
    enable_RAM : in std_logic;
    rd_en : in std_logic_vector(3 downto 0);
    wr_en : in std_logic_vector(3 downto 0);
    addr_rd_0 : in std_logic_vector(6 downto 0);
    addr_rd_1 : in std_logic_vector(6 downto 0);
    addr_rd_2 : in std_logic_vector(6 downto 0);
    addr_rd_3 : in std_logic_vector(6 downto 0);
    addr_wr_0 : in std_logic_vector(6 downto 0);
    addr_wr_1 : in std_logic_vector(6 downto 0);
    addr_wr_2 : in std_logic_vector(6 downto 0);
    addr_wr_3 : in std_logic_vector(6 downto 0);
    tw_addr_0 : in std_logic_vector(6 downto 0);
    tw_addr_1 : in std_logic_vector(6 downto 0);
    data_out : out std_logic_vector(23 downto 0)
  ) ;
end PMC_CORE ;

architecture Behavioral of PMC_CORE is

    -- RAM read addresses
    signal rd_addr_0, rd_addr_1, rd_addr_2, rd_addr_3 : std_logic_vector(4 downto 0);
    signal rd_data_0, rd_data_1, rd_data_2, rd_data_3 : std_logic_vector(23 downto 0);
    
    -- RAM write addresses
    signal wr_addr_0, wr_addr_1, wr_addr_2, wr_addr_3 : std_logic_vector(4 downto 0);
    signal wr_data_0, wr_data_1, wr_data_2, wr_data_3 : std_logic_vector(23 downto 0);

    -- Internal signals
    signal u_in_internal, v_in_internal : std_logic_vector(47 downto 0) := (others => '0');
    signal u_out_internal, v_out_internal : std_logic_vector(47 downto 0) := (others => '0');

    -- Write addresses buffered
    signal wr_addr_buf_in, wr_addr_buf_out : std_logic_vector(27 downto 0) := (others => '0');

    -- 4x1 Butterfly Core
    component BUTTERFLY_CORE is
        port (
            clk      : in std_logic;
            mode     : in std_logic;
            reset    : in std_logic;
            enable   : in std_logic;
            u_in     : in std_logic_vector(47 downto 0); -- 4x 12-bit inputs
            v_in     : in std_logic_vector(47 downto 0); -- 4x 12-bit inputs
            tw_addr_0 : in std_logic_vector(6 downto 0); -- twiddle addr_0
            tw_addr_1 : in std_logic_vector(6 downto 0); -- twiddle addr_1
            u_out    : out std_logic_vector(47 downto 0); -- 4x 12-bit outputs
            v_out    : out std_logic_vector(47 downto 0) -- 4x 12-bit outputs
        );
    end component;

    -- Address mapping
    component ADDR_MAP is
        port (
            clk : in std_logic;
            reset : in std_logic;
            addr_0 : in std_logic_vector(6 downto 0) ;
            addr_1 : in std_logic_vector(6 downto 0) ;
            addr_2 : in std_logic_vector(6 downto 0) ;
            addr_3 : in std_logic_vector(6 downto 0) ;
            bank_addr_0 : out std_logic_vector(4 downto 0) ;
            bank_addr_1 : out std_logic_vector(4 downto 0) ;
            bank_addr_2 : out std_logic_vector(4 downto 0) ;
            bank_addr_3 : out std_logic_vector(4 downto 0) 
        ) ;
    end component; 

    -- RAM
    component RAM
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
    end component;

    -- FIFO buffer for controlling write address signals
    component FIFO_BUFFER is
        generic (
            n : positive := 8;           -- Number of stages
            data_width : positive := 28   -- Width of data bus (4*wr_addr width)
        );
        port (
            clk     : in  std_logic;
            reset     : in  std_logic;
            enable  : in  std_logic;
            mode : in std_logic;
            data_in : in  std_logic_vector(data_width-1 downto 0);
            data_out   : out std_logic_vector(data_width-1 downto 0)
        );
    end component;
begin

    -- FIFO Buffer
    FIFO_0 : FIFO_BUFFER
    generic map(
        n => 8,
        data_width => 28
    )
    port map(
        clk => clk,
        reset => reset,
        enable => '1',
        mode => mode(0),
        data_in => wr_addr_buf_in,
        data_out => wr_addr_buf_out
    );

    -- 4x1 butterfly unit
    BUT_CORE : BUTTERFLY_CORE
    port map(
        clk => clk,
        mode => mode(0),
        reset => reset,
        enable => enable_BUT,
        u_in => u_in_internal,
        v_in => v_in_internal,
        tw_addr_0 => tw_addr_0, 
        tw_addr_1 => tw_addr_1,
        u_out => u_out_internal,
        v_out => v_out_internal
    );

    -- Address mapping for read signals
    ADDR_MAP_RD : ADDR_MAP
    port map(
        clk => clk,
        reset => reset,
        addr_0 => addr_rd_0,
        addr_1 => addr_rd_1,
        addr_2 => addr_rd_2,
        addr_3 => addr_rd_3,
        bank_addr_0 => rd_addr_0,
        bank_addr_1 => rd_addr_1,
        bank_addr_2 => rd_addr_2,
        bank_addr_3 => rd_addr_3
    );

    -- address mapping for write signals
    ADDR_MAP_WR : ADDR_MAP
    port map(
        clk => clk,
        reset => reset,
        addr_0 => wr_addr_buf_out(6 downto 0),
        addr_1 => wr_addr_buf_out(13 downto 7),
        addr_2 => wr_addr_buf_out(20 downto 14),
        addr_3 => wr_addr_buf_out(27 downto 21),
        bank_addr_0 => wr_addr_0,
        bank_addr_1 => wr_addr_1,
        bank_addr_2 => wr_addr_2,
        bank_addr_3 => wr_addr_3
    );

    -- RAM
    RAM_0 : RAM
    port map(
        clk => clk,
        rst => reset, 
        enable => enable_RAM,
        wr_en => wr_en,
        wr_addr_0 => wr_addr_0,
        wr_addr_1 => wr_addr_1,
        wr_addr_2 => wr_addr_2,
        wr_addr_3 => wr_addr_3,
        wr_data_0 => wr_data_0,
        wr_data_1 => wr_data_1,
        wr_data_2 => wr_data_2,
        wr_data_3 => wr_data_3,
        rd_en => rd_en,
        rd_addr_0 => rd_addr_0,
        rd_addr_1 => rd_addr_1,
        rd_addr_2 => rd_addr_2,
        rd_addr_3 => rd_addr_3,
        rd_data_0 => rd_data_0,
        rd_data_1 => rd_data_1,
        rd_data_2 => rd_data_2,
        rd_data_3 => rd_data_3
    );

    u_in_internal <= rd_data_1 & rd_data_0;
    v_in_internal <= rd_data_3 & rd_data_2;

    wr_addr_buf_in <= addr_wr_3 & addr_wr_2 & addr_wr_1 & addr_wr_0;

    wr_data_0 <= u_out_internal(23 downto 0);
    wr_data_1 <= u_out_internal(47 downto 24);
    wr_data_2 <= v_out_internal(23 downto 0);
    wr_data_3 <= v_out_internal(47 downto 24);

    data_out <= rd_data_0;

end architecture ; -- Behavioral