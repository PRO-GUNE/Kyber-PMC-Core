-- filepath: d:/University/Semester_07/FYP/Kyber-PMC-Core/src/BUFFERED_UART.vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BUFFERED_UART is
    generic (
        CLK_FREQ  : integer := 100_000_000; -- System clock frequency (e.g., 100 MHz)
        BAUD_RATE : integer := 5000000 -- UART baud rate
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        rx         : in  std_logic; -- UART receive line
        tx         : out std_logic; -- UART transmit line
        ram_data0  : in  std_logic_vector(23 downto 0); -- Data from RAM (word 0)
        ram_data1  : in  std_logic_vector(23 downto 0); -- Data from RAM (word 1)
        ram_data2  : in  std_logic_vector(23 downto 0); -- Data from RAM (word 2)
        ram_data3  : in  std_logic_vector(23 downto 0); -- Data from RAM (word 3)
        ram_valid  : in  std_logic; -- Valid signal for RAM data
        ram_ready  : out std_logic; -- Ready signal for RAM
        uart_data0 : out std_logic_vector(23 downto 0); -- Data to RAM (word 0)
        uart_data1 : out std_logic_vector(23 downto 0); -- Data to RAM (word 1)
        uart_data2 : out std_logic_vector(23 downto 0); -- Data to RAM (word 2)
        uart_data3 : out std_logic_vector(23 downto 0); -- Data to RAM (word 3)
        uart_valid : out std_logic -- Valid signal for UART data
    );
end BUFFERED_UART;

architecture Behavioral of BUFFERED_UART is
    -- Signals for RX_MAP
    signal rx_data_out0  : std_logic_vector(23 downto 0);
    signal rx_data_out1  : std_logic_vector(23 downto 0);
    signal rx_data_out2  : std_logic_vector(23 downto 0);
    signal rx_data_out3  : std_logic_vector(23 downto 0);
    signal rx_ready      : std_logic;
    signal rx_data_valid : std_logic;

    -- Signals for TX_MAP
    signal tx_data_out   : std_logic_vector(7 downto 0);
    signal tx_ready      : std_logic;

    -- Signals for UART RX and TX
    signal uart_rx_data  : std_logic_vector(7 downto 0);
    signal uart_rx_valid : std_logic;
    signal uart_tx_busy  : std_logic;
    signal uart_tx_send  : std_logic;

    -- Internal control signals
    signal tx_map_ready  : std_logic;
    signal tx_map_valid  : std_logic;
begin
    -- UART Receiver
    uart_rx_inst : entity work.uart_rx
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk        => clk,
            rst        => rst,
            rx         => rx,
            data_out   => uart_rx_data,
            data_valid => uart_rx_valid
        );

    -- RX_MAP to convert UART data to 24-bit words
    rx_map_inst : entity work.RX_MAP
        port map (
            clk        => clk,
            reset      => rst,
            data_in    => uart_rx_data,
            data_valid => uart_rx_valid,
            data_out0  => rx_data_out0,
            data_out1  => rx_data_out1,
            data_out2  => rx_data_out2,
            data_out3  => rx_data_out3,
            ready      => rx_ready
        );

    -- Assign outputs for data received from UART
    uart_data0 <= rx_data_out0;
    uart_data1 <= rx_data_out1;
    uart_data2 <= rx_data_out2;
    uart_data3 <= rx_data_out3;
    uart_valid <= rx_ready;

    -- TX_MAP to convert 24-bit words to UART data
    tx_map_inst : entity work.TX_MAP
        port map (
            clk        => clk,
            reset      => rst,
            data_in0   => ram_data0,
            data_in1   => ram_data1,
            data_in2   => ram_data2,
            data_in3   => ram_data3,
            data_valid => ram_valid,
            data_out   => tx_data_out,
            ready      => tx_map_ready
        );

    -- UART Transmitter
    uart_tx_inst : entity work.uart_tx
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk       => clk,
            rst       => rst,
            data_in   => tx_data_out,
            data_send => tx_map_valid,
            tx        => tx,
            busy      => uart_tx_busy
        );

    -- Control logic for TX_MAP and UART TX
    tx_map_valid <= tx_map_ready and not uart_tx_busy;
    ram_ready    <= tx_map_ready;

end Behavioral;