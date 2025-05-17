----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.04.2025 22:34:45
-- Design Name: 
-- Module Name: uart_rx - Behavioral
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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
    generic (
        CLK_FREQ    : integer := 100000000;  -- 100 MHz clock
        BAUD_RATE   : integer := 115200      -- Baud rate
    );
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        rx          : in  std_logic;
        data_out    : out std_logic_vector(7 downto 0);
        data_valid  : out std_logic
    );
end uart_rx;

architecture Behavioral of uart_rx is
    -- Calculate the clock ticks per bit
    constant TICKS_PER_BIT : integer := CLK_FREQ / BAUD_RATE;
    
    -- UART receiver state machine
    type uart_state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state        : uart_state_type := IDLE;
    
    -- Registers to keep track of the receiver
    signal rx_clk_count : integer range 0 to TICKS_PER_BIT-1 := 0;
    signal rx_bit_index : integer range 0 to 7 := 0;
    signal rx_data      : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_data_valid: std_logic := '0';
    
begin
    -- UART receiver process
    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE;
            rx_clk_count <= 0;
            rx_bit_index <= 0;
            rx_data <= (others => '0');
            rx_data_valid <= '0';
        elsif rising_edge(clk) then
            -- Default state
            rx_data_valid <= '0';
            
            case state is
                when IDLE =>
                    rx_clk_count <= 0;
                    rx_bit_index <= 0;
                    
                    -- Wait for start bit (RX line going low)
                    if rx = '0' then
                        state <= START_BIT;
                    end if;
                    
                when START_BIT =>
                    -- Sample in the middle of the start bit
                    if rx_clk_count = TICKS_PER_BIT/2 then
                        if rx = '0' then  -- Confirm it's still a start bit
                            rx_clk_count <= 0;
                            state <= DATA_BITS;
                        else  -- False start, go back to idle
                            state <= IDLE;
                        end if;
                    else
                        rx_clk_count <= rx_clk_count + 1;
                    end if;
                    
                when DATA_BITS =>
                    -- Sample in the middle of each data bit
                    if rx_clk_count = TICKS_PER_BIT-1 then
                        rx_clk_count <= 0;
                        rx_data(rx_bit_index) <= rx;  -- LSB first
                        
                        if rx_bit_index = 7 then
                            rx_bit_index <= 0;
                            state <= STOP_BIT;
                        else
                            rx_bit_index <= rx_bit_index + 1;
                        end if;
                    else
                        rx_clk_count <= rx_clk_count + 1;
                    end if;
                    
                when STOP_BIT =>
                    -- Wait for the stop bit to finish
                    if rx_clk_count = TICKS_PER_BIT-1 then
                        rx_data_valid <= '1';
                        rx_clk_count <= 0;
                        state <= IDLE;
                    else
                        rx_clk_count <= rx_clk_count + 1;
                    end if;
            end case;
        end if;
    end process;
    
    -- Connect registers to outputs
    data_out <= rx_data;
    data_valid <= rx_data_valid;
    
end Behavioral;