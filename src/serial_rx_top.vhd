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
    valid : out std_logic;
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

  -- Signal declarations
  signal rx_data       : std_logic_vector(7 downto 0);
  signal rx_data_valid : std_logic;
  signal rx_data_out_0, rx_data_out_1, rx_data_out_2, rx_data_out_3 : std_logic_vector(23 downto 0);
  signal busy : std_logic := '1';
  signal data_send : std_logic := '1'; 
  signal tx_data    : std_logic_vector(7 downto 0);
  signal buf_full   : std_logic := '0';
  signal sent       : std_logic;
  
begin
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
    data_out_0 => rx_data_out_0,
    data_out_1 => rx_data_out_1,
    data_out_2 => rx_data_out_2,
    data_out_3 => rx_data_out_3
  );
  
  serial_buf_tx_inst : serial_buf_tx
  port map(
    clk => clk,
    rst => rst,
    busy => busy,
    data_in_0 => rx_data_out_0,
    data_in_1 => rx_data_out_1,
    data_in_2 => rx_data_out_2,
    data_in_3 => rx_data_out_3,
    data_valid => buf_full,
    data_send => data_send,
    data_out => tx_data
  );
  
  -- LED output logic
  led <= tx_data; -- Output received data to LEDs
  valid <= sent;

end Behavioral;