library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity UART_RAM is
  generic (
    CLK_FREQ  : integer := 100_000_000; -- 100 MHz clock
    BAUD_RATE : integer := 5000000 -- UART baud rate
  );
  port (
    clk         : in std_logic;
    rst         : in std_logic;
    rx          : in std_logic; -- UART RX line
    tx          : out std_logic; -- UART TX line
    deb_wr_out  : out std_logic_vector(23 downto 0);
    deb_rd_out  : out std_logic_vector(23 downto 0);
    deb_wr_done : out std_logic
  );
end UART_RAM;

architecture Behavioral of UART_RAM is
  -- Signals for UART RX
  signal rx_data       : std_logic_vector(7 downto 0);
  signal rx_data_valid : std_logic;

  -- Signals for RX_MAP
  signal rx_map_data_out0 : std_logic_vector(23 downto 0);
  signal rx_map_data_out1 : std_logic_vector(23 downto 0);
  signal rx_map_data_out2 : std_logic_vector(23 downto 0);
  signal rx_map_data_out3 : std_logic_vector(23 downto 0);
  signal rx_map_ready     : std_logic;

  -- Signals for RAM
  signal ram_wr_en    : std_logic_vector(3 downto 0);
  signal ram_wr_addr  : std_logic_vector(4 downto 0);
  signal ram_rd_en    : std_logic_vector(3 downto 0);
  signal ram_rd_addr  : std_logic_vector(4 downto 0);
  signal ram_rd_data0 : std_logic_vector(23 downto 0);
  signal ram_rd_data1 : std_logic_vector(23 downto 0);
  signal ram_rd_data2 : std_logic_vector(23 downto 0);
  signal ram_rd_data3 : std_logic_vector(23 downto 0);

  -- Signals for TX_MAP
  signal tx_map_data_in0 : std_logic_vector(23 downto 0);
  signal tx_map_data_in1 : std_logic_vector(23 downto 0);
  signal tx_map_data_in2 : std_logic_vector(23 downto 0);
  signal tx_map_data_in3 : std_logic_vector(23 downto 0);
  signal tx_map_data_out : std_logic_vector(7 downto 0);
  signal tx_map_ready    : std_logic;

  -- Signals for UART TX
  signal tx_busy    : std_logic;
  signal tx_data_in : std_logic_vector(7 downto 0);
  signal tx_send    : std_logic;

  -- Control signals
  signal write_done : std_logic := '0';
  signal read_done  : std_logic := '0';

begin
  -- UART RX Instance
  uart_rx_inst : entity work.uart_rx
    generic map(
      CLK_FREQ  => CLK_FREQ,
      BAUD_RATE => BAUD_RATE
    )
    port map
    (
      clk        => clk,
      rst        => rst,
      rx         => rx,
      data_out   => rx_data,
      data_valid => rx_data_valid
    );

  -- RX_MAP Instance
  rx_map_inst : entity work.RX_MAP
    port map
    (
      clk        => clk,
      reset      => rst,
      data_in    => rx_data,
      data_valid => rx_data_valid,
      data_out0  => rx_map_data_out0,
      data_out1  => rx_map_data_out1,
      data_out2  => rx_map_data_out2,
      data_out3  => rx_map_data_out3,
      ready      => rx_map_ready
    );

  -- RAM Instance
  ram_inst : entity work.RAM
    port map
    (
      clk       => clk,
      rst       => rst,
      enable    => '1',
      wr_en     => ram_wr_en,
      wr_addr_0 => ram_wr_addr,
      wr_addr_1 => ram_wr_addr,
      wr_addr_2 => ram_wr_addr,
      wr_addr_3 => ram_wr_addr,
      wr_data_0 => rx_map_data_out0,
      wr_data_1 => rx_map_data_out1,
      wr_data_2 => rx_map_data_out2,
      wr_data_3 => rx_map_data_out3,
      rd_en     => ram_rd_en,
      rd_addr_0 => ram_rd_addr,
      rd_addr_1 => ram_rd_addr,
      rd_addr_2 => ram_rd_addr,
      rd_addr_3 => ram_rd_addr,
      rd_data_0 => ram_rd_data0,
      rd_data_1 => ram_rd_data1,
      rd_data_2 => ram_rd_data2,
      rd_data_3 => ram_rd_data3
    );

  -- TX_MAP Instance
  tx_map_inst : entity work.TX_MAP
    port map
    (
      clk        => clk,
      reset      => rst,
      data_in0   => ram_rd_data0,
      data_in1   => ram_rd_data1,
      data_in2   => ram_rd_data2,
      data_in3   => ram_rd_data3,
      data_valid => read_done,
      data_out   => tx_map_data_out,
      ready      => tx_map_ready
    );

  -- UART TX Instance
  uart_tx_inst : entity work.uart_tx
    generic map(
      CLK_FREQ  => CLK_FREQ,
      BAUD_RATE => BAUD_RATE
    )
    port map
    (
      clk       => clk,
      rst       => rst,
      data_in   => tx_map_data_out,
      data_send => tx_send,
      tx        => tx,
      busy      => tx_busy
    );

  -- Control Logic
  process (clk, rst)
  begin
    if rst = '1' then
      write_done <= '0';
      ram_wr_en  <= (others => '0');
      ram_rd_en  <= (others => '0');
      tx_send    <= '0';
    elsif rising_edge(clk) then
      ram_rd_en   <= "1111";
      ram_rd_addr <= "00000";

      if rx_map_ready = '1' and write_done = '0' then
        -- Write data to RAM
        ram_wr_en   <= "1111";
        ram_wr_addr <= "00000";
        write_done  <= '1';
      else
        ram_wr_en <= (others => '0');
      end if;

      if tx_map_ready = '1' and tx_busy = '0' then
        -- Send data via UART
        tx_send <= '1';
      else
        tx_send <= '0';
      end if;
    end if;
  end process;

  -- Output assignments
  deb_wr_out  <= rx_map_data_out0;
  deb_rd_out  <= ram_rd_data0;
  deb_wr_done <= write_done;

end Behavioral;