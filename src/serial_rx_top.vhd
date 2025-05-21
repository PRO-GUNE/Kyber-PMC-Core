----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.04.2025 22:35:46
-- Design Name: 
-- Module Name: snn_top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity serial_rx_top is
  generic (
    -- UART parameters
    CLK_FREQ  : integer := 100000000; -- 100 MHz FPGA clock
    BAUD_RATE : integer := 115200 -- Serial baud rate
  );
  port (
    clk : in std_logic;
    rst : in std_logic;
    rx  : in std_logic; -- Serial RX input
    tx  : out std_logic; -- Serial TX output
    led : out std_logic_vector(7 downto 0) -- LED output for debugging
  );
end serial_rx_top;

architecture Behavioral of serial_rx_top is
  -- Component declarations
  component uart_rx is
    generic (
      CLK_FREQ  : integer;
      BAUD_RATE : integer
    );
    port (
      clk        : in std_logic;
      rst        : in std_logic;
      rx         : in std_logic;
      data_out   : out std_logic_vector(7 downto 0);
      data_valid : out std_logic
    );
  end component;
  
  component serial_buf_rx is
  Port (
     clk        : in std_logic;
     rst      : in std_logic;
     data_in    : in std_logic_vector(7 downto 0);
     data_valid : in std_logic;
     buf_full  : out std_logic;
     data_out_0  : out std_logic_vector(23 downto 0);
     data_out_1  : out std_logic_vector(23 downto 0); 
     data_out_2  : out std_logic_vector(23 downto 0); 
     data_out_3  : out std_logic_vector(23 downto 0) 
   );
  end component;
  
  component uart_tx is
      generic (
        CLK_FREQ  : integer; -- 100 MHz
        BAUD_RATE : integer -- UART baud rate
      );
      port (
        clk       : in std_logic;
        rst       : in std_logic;
        data_in   : in std_logic_vector(7 downto 0); -- Data to transmit
        data_send : in std_logic; -- Signal to start transmission
        tx        : out std_logic; -- Serial output
        busy      : out std_logic -- '1' when transmitting
      );
  end component;
  
  component serial_buf_tx is
    Port (
     clk       : in std_logic;
     rst       : in std_logic;
     busy      : in std_logic;
     data_in_0 : in std_logic_vector(23 downto 0);
     data_in_1 : in std_logic_vector(23 downto 0);
     data_in_2 : in std_logic_vector(23 downto 0);
     data_in_3 : in std_logic_vector(23 downto 0);
     data_valid: in std_logic;
     data_send : out std_logic;
     data_out  : out std_logic_vector(7 downto 0) -- First 24-bit value
   );
  end component;
  
  component RAM
    port (
      clk    : in std_logic;
      rst    : in std_logic;
      enable : in std_logic;
      -- Write ports - independent for each bank
      wr_en     : in std_logic_vector(3 downto 0); -- Write enable for each bank
      wr_addr_0 : in std_logic_vector(4 downto 0); -- Write address for bank 0
      wr_addr_1 : in std_logic_vector(4 downto 0); -- Write address for bank 1
      wr_addr_2 : in std_logic_vector(4 downto 0); -- Write address for bank 2
      wr_addr_3 : in std_logic_vector(4 downto 0); -- Write address for bank 3
      wr_data_0 : in std_logic_vector(23 downto 0); -- Write data for bank 0
      wr_data_1 : in std_logic_vector(23 downto 0); -- Write data for bank 1
      wr_data_2 : in std_logic_vector(23 downto 0); -- Write data for bank 2
      wr_data_3 : in std_logic_vector(23 downto 0); -- Write data for bank 3

      -- Read ports - independent for each bank
      rd_en     : in std_logic_vector(3 downto 0); -- Read enable for each bank
      rd_addr_0 : in std_logic_vector(4 downto 0); -- Read address for bank 0
      rd_addr_1 : in std_logic_vector(4 downto 0); -- Read address for bank 1
      rd_addr_2 : in std_logic_vector(4 downto 0); -- Read address for bank 2
      rd_addr_3 : in std_logic_vector(4 downto 0); -- Read address for bank 3
      rd_data_0 : out std_logic_vector(23 downto 0); -- Read data from bank 0
      rd_data_1 : out std_logic_vector(23 downto 0); -- Read data from bank 1
      rd_data_2 : out std_logic_vector(23 downto 0); -- Read data from bank 2
      rd_data_3 : out std_logic_vector(23 downto 0) -- Read data from bank 3
    );
  end component;

  -- Signal declarations
  signal rx_data       : std_logic_vector(7 downto 0);
  signal rx_data_valid : std_logic;
  signal busy : std_logic := '1';
  signal data_send : std_logic := '1'; 
  signal tx_data    : std_logic_vector(7 downto 0);
  signal buf_full   : std_logic := '0';
  
  signal rd_addr_0, rd_addr_1, rd_addr_2, rd_addr_3 : std_logic_vector(4 downto 0) := (others => '0');
  signal rd_data_0, rd_data_1, rd_data_2, rd_data_3 : std_logic_vector(23 downto 0);
  signal wr_addr_0, wr_addr_1, wr_addr_2, wr_addr_3 : std_logic_vector(4 downto 0) := (others => '0');
  signal wr_data_0, wr_data_1, wr_data_2, wr_data_3 : std_logic_vector(23 downto 0);
  signal wr_en, rd_en                               : std_logic_vector(3 downto 0) := "1111";
  signal read_valid : std_logic := '1';
begin
  -- instantiate the RAM
  
  -- Instantiate the serial interface
  uart_rx_inst : uart_rx
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
  
  uart_tx_inst : uart_tx
  generic map(
    CLK_FREQ  => CLK_FREQ,
    BAUD_RATE => BAUD_RATE
  )
  port map
  (
    clk        => clk,
    rst        => rst,
    data_in    => tx_data,
    data_send  => data_send,
    tx         => tx,
    busy       => busy
  );
  
  serial_buf_rx_inst : serial_buf_rx
  port map
  (
    clk => clk,
    rst => rst,
    data_in => rx_data,
    data_valid => rx_data_valid,
    buf_full => buf_full,
    data_out_0 => wr_data_0,
    data_out_1 => wr_data_1,
    data_out_2 => wr_data_2,
    data_out_3 => wr_data_3
  );
  
  serial_buf_tx_inst : serial_buf_tx
  port map(
    clk => clk,
    rst => rst,
    busy => busy,
    data_in_0 => rd_data_0,
    data_in_1 => rd_data_1,
    data_in_2 => rd_data_2,
    data_in_3 => rd_data_3,
    data_valid => buf_full,
    data_send => data_send,
    data_out => tx_data
  );
  
  -- RAM
  RAM_0 : RAM
  port map
  (
    clk       => clk,
    rst       => rst,
    enable    => '1',
    wr_en     => wr_en,
    wr_addr_0 => wr_addr_0,
    wr_addr_1 => wr_addr_1,
    wr_addr_2 => wr_addr_2,
    wr_addr_3 => wr_addr_3,
    wr_data_0 => wr_data_0,
    wr_data_1 => wr_data_1,
    wr_data_2 => wr_data_2,
    wr_data_3 => wr_data_3,
    rd_en     => rd_en,
    rd_addr_0 => rd_addr_0,
    rd_addr_1 => rd_addr_1,
    rd_addr_2 => rd_addr_2,
    rd_addr_3 => rd_addr_3,
    rd_data_0 => rd_data_0,
    rd_data_1 => rd_data_1,
    rd_data_2 => rd_data_2,
    rd_data_3 => rd_data_3
  );
  
  -- LED output logic
  led <= tx_data; -- Output received data to LEDs
end Behavioral;