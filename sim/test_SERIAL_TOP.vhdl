-- Testbench for serial_rx_top
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test_SERIAL_TOP is
end test_SERIAL_TOP;

architecture tb of test_SERIAL_TOP is

    -- Constants for UART
    constant CLK_FREQ  : integer := 100_000_000;
    constant BAUD_RATE : integer := 5_000_000;
    constant CLK_PERIOD : time := 10 ns; -- 100 MHz

    -- DUT signals
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';
    signal rx    : std_logic := '1';
    signal tx    : std_logic;
    signal led   : std_logic_vector(7 downto 0);

    -- Helper signals
    signal rx_data_byte : std_logic_vector(7 downto 0);

    -- UART timing
    constant BIT_PERIOD : time := 1 sec / BAUD_RATE;

    -- DUT component declaration
    component serial_rx_top
        generic (
            CLK_FREQ  : integer := 100_000_000;
            BAUD_RATE : integer := 5_000_000
        );
        port (
            clk : in std_logic;
            rst : in std_logic;
            rx  : in std_logic;
            tx  : out std_logic;
            led : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Procedure to send a byte over UART RX
    procedure uart_send_byte(signal rx : out std_logic; data : std_logic_vector(7 downto 0)) is
    begin
        -- Start bit
        rx <= '0';
        wait for BIT_PERIOD;
        -- Data bits (LSB first)
        for i in 0 to 7 loop
            rx <= data(i);
            wait for BIT_PERIOD;
        end loop;
        -- Stop bit
        rx <= '1';
        wait for BIT_PERIOD;
    end procedure;

begin

    -- Clock generation
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- DUT instantiation
    dut: serial_rx_top
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk => clk,
            rst => rst,
            rx  => rx,
            tx  => tx,
            led => led
        );

    -- Stimulus process
    stim_proc: process
    begin
        -- Reset
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 100 ns;

        -- Send three bytes (0xA5, 0x5A, 0xFF) over RX
        uart_send_byte(rx, x"A5");
        uart_send_byte(rx, x"5A");
        uart_send_byte(rx, x"FF");

        -- Wait for processing
        wait for 1 us;

        -- Optionally, observe LED output
        assert false report "Testbench finished" severity note;
        wait;
    end process;

end tb;