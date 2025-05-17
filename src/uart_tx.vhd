----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.04.2025 18:29:02
-- Design Name: 
-- Module Name: uart_tx - Behavioral
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

entity uart_tx is
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
end uart_tx;

architecture Behavioral of uart_tx is
  -- Calculate clock cycles per bit
  constant BIT_PERIOD : integer := CLK_FREQ / BAUD_RATE;

  -- State machine states
  type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
  signal state : state_type := IDLE;

  -- Internal signals
  signal bit_counter   : integer range 0 to 7              := 0; -- Bit counter
  signal cycle_counter : integer range 0 to BIT_PERIOD - 1 := 0; -- Clock cycle counter
  signal shift_reg     : std_logic_vector(7 downto 0)      := (others => '0'); -- Shift register
  signal tx_data       : std_logic                         := '1'; -- Output bit

begin
  -- Output assignment
  tx <= tx_data;

  -- Transmitter state machine
  process (clk, rst)
  begin
    if rst = '1' then
      state         <= IDLE;
      bit_counter   <= 0;
      cycle_counter <= 0;
      shift_reg     <= (others => '0');
      tx_data       <= '1'; -- Idle is high
      busy          <= '0';
    elsif rising_edge(clk) then

      case state is
        when IDLE =>
          tx_data       <= '1'; -- Idle is high
          busy          <= '0';
          cycle_counter <= 0;

          if data_send = '1' then
            -- Start transmission
            shift_reg <= data_in;
            state     <= START_BIT;
            busy      <= '1';
          end if;

        when START_BIT =>
          tx_data <= '0'; -- Start bit is low
          busy    <= '1';

          if cycle_counter = BIT_PERIOD - 1 then
            cycle_counter <= 0;
            state         <= DATA_BITS;
            bit_counter   <= 0;
          else
            cycle_counter <= cycle_counter + 1;
          end if;

        when DATA_BITS =>
          tx_data <= shift_reg(0); -- LSB first
          busy    <= '1';

          if cycle_counter = BIT_PERIOD - 1 then
            cycle_counter <= 0;
            -- Shift right
            shift_reg <= '0' & shift_reg(7 downto 1);

            if bit_counter = 7 then
              -- All bits sent
              state <= STOP_BIT;
            else
              bit_counter <= bit_counter + 1;
            end if;
          else
            cycle_counter <= cycle_counter + 1;
          end if;

        when STOP_BIT =>
          tx_data <= '1'; -- Stop bit is high
          busy    <= '1';

          if cycle_counter = BIT_PERIOD - 1 then
            state <= IDLE;
            busy  <= '0';
          else
            cycle_counter <= cycle_counter + 1;
          end if;
      end case;
    end if;
  end process;

end Behavioral;
