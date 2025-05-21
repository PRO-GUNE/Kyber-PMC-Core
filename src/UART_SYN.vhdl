library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_SYN is
    generic (
        BUFFER_SIZE : integer := 12;
        MEM_SIZE    : integer := 3;
        BAUD_DELAY  : integer := 13020
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        -- UART interface
        rx          : in  std_logic;
        tx          : out std_logic;
        -- Processing module interface
        data_out_0  : out std_logic_vector(8*MEM_SIZE-1 downto 0);
        data_out_1  : out std_logic_vector(8*MEM_SIZE-1 downto 0);
        data_out_2  : out std_logic_vector(8*MEM_SIZE-1 downto 0);
        data_out_3  : out std_logic_vector(8*MEM_SIZE-1 downto 0);
        data_in_0   : in  std_logic_vector(8*MEM_SIZE-1 downto 0);
        data_in_1   : in  std_logic_vector(8*MEM_SIZE-1 downto 0);
        data_in_2   : in  std_logic_vector(8*MEM_SIZE-1 downto 0);
        data_in_3   : in  std_logic_vector(8*MEM_SIZE-1 downto 0);
        proc_start  : out std_logic;
        proc_done   : in  std_logic
    );
end UART_SYN;

architecture Behavioral of UART_SYN is

    -- UART entity declaration
    component UART
        port(
            clk        : in  std_logic;
            reset      : in  std_logic;
            tx_start   : in  std_logic;
            data_in    : in  std_logic_vector (7 downto 0);
            data_out   : out std_logic_vector (7 downto 0);
            data_valid : out std_logic;
            rx         : in  std_logic;
            tx         : out std_logic
        );
    end component;

    -- UART_buffer entity declaration
    component UART_buffer
        generic (
            BUFFER_SIZE : integer := 12;
            MEM_SIZE    : integer := 3;
            BAUD_DELAY  : integer := 13020
        );
        port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            rx_data     : in  std_logic_vector(7 downto 0);
            rx_valid    : in  std_logic;
            tx_data     : out std_logic_vector(7 downto 0);
            tx_start    : out std_logic;
            data_out_0  : out std_logic_vector(8*MEM_SIZE-1 downto 0);
            data_out_1  : out std_logic_vector(8*MEM_SIZE-1 downto 0);
            data_out_2  : out std_logic_vector(8*MEM_SIZE-1 downto 0);
            data_out_3  : out std_logic_vector(8*MEM_SIZE-1 downto 0);
            data_in_0   : in  std_logic_vector(8*MEM_SIZE-1 downto 0);
            data_in_1   : in  std_logic_vector(8*MEM_SIZE-1 downto 0);
            data_in_2   : in  std_logic_vector(8*MEM_SIZE-1 downto 0);
            data_in_3   : in  std_logic_vector(8*MEM_SIZE-1 downto 0);
            proc_start  : out std_logic;
            proc_done   : in  std_logic
        );
    end component;

    -- Internal signals for UART <-> UART_buffer connection
    signal rx_data      : std_logic_vector(7 downto 0);
    signal rx_valid     : std_logic;
    signal tx_data      : std_logic_vector(7 downto 0);
    signal tx_start_sig : std_logic;

begin

    -- UART instance
    uart_inst : UART
        port map (
            clk        => clk,
            reset      => reset,
            tx_start   => tx_start_sig,
            data_in    => tx_data,
            data_out   => rx_data,
            data_valid => rx_valid,
            rx         => rx,
            tx         => tx
        );

    -- UART_buffer instance
    uart_buffer_inst : UART_buffer
        generic map (
            BUFFER_SIZE => BUFFER_SIZE,
            MEM_SIZE    => MEM_SIZE,
            BAUD_DELAY  => BAUD_DELAY
        )
        port map (
            clk         => clk,
            reset       => reset,
            rx_data     => rx_data,
            rx_valid    => rx_valid,
            tx_data     => tx_data,
            tx_start    => tx_start_sig,
            data_out_0  => data_out_0,
            data_out_1  => data_out_1,
            data_out_2  => data_out_2,
            data_out_3  => data_out_3,
            data_in_0   => data_in_0,
            data_in_1   => data_in_1,
            data_in_2   => data_in_2,
            data_in_3   => data_in_3,
            proc_start  => proc_start,
            proc_done   => proc_done
        );

end Behavioral;