library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_buffer is
    generic (
        BUFFER_SIZE : integer := 12;
        MEM_SIZE    : integer := 3;
        BAUD_DELAY : integer := 13020
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        -- UART interface
        rx_data     : in  std_logic_vector(7 downto 0);
        rx_valid    : in  std_logic;
        tx_data     : out std_logic_vector(7 downto 0);
        tx_start    : out std_logic;
        -- Processing module interface
        data_out_0    : out std_logic_vector(8*MEM_SIZE-1 downto 0);  -- Data to processing module
        data_out_1    : out std_logic_vector(8*MEM_SIZE-1 downto 0);  -- Data to processing module
        data_out_2    : out std_logic_vector(8*MEM_SIZE-1 downto 0);  -- Data to processing module
        data_out_3    : out std_logic_vector(8*MEM_SIZE-1 downto 0);  -- Data to processing module
        data_in_0     : in  std_logic_vector(8*MEM_SIZE-1 downto 0);  -- Processed data from processing module
        data_in_1     : in  std_logic_vector(8*MEM_SIZE-1 downto 0);  -- Processed data from processing module
        data_in_2     : in  std_logic_vector(8*MEM_SIZE-1 downto 0);  -- Processed data from processing module
        data_in_3     : in  std_logic_vector(8*MEM_SIZE-1 downto 0);  -- Processed data from processing module
        proc_start  : out std_logic;                                    -- Signal to start processing
        proc_done   : in  std_logic                                    -- Signal from processing module when done
    );
end UART_buffer;

architecture Behavioral of UART_buffer is
    -- Internal signals using std_logic_vector
    signal data_buffer : std_logic_vector(8*BUFFER_SIZE-1 downto 0) := (others => '0');
    signal result_buffer : std_logic_vector(8*BUFFER_SIZE-1 downto 0) := (others => '0');
    
    signal rx_count : integer range 0 to BUFFER_SIZE := 0;
    signal tx_count : integer range 0 to BUFFER_SIZE := 0;
    
    type state_type is (RECEIVING, WAITING, TRANSMITTING);
    signal current_state : state_type := RECEIVING;
    
    signal delay_counter : integer range 0 to BAUD_DELAY := 0;
    signal transmit_active : boolean := false;
    signal proc_done_ack : std_logic := '0';

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                rx_count <= 0;
                tx_count <= 0;
                delay_counter <= 0;
                tx_start <= '0';
                proc_start <= '0';
                proc_done_ack <= '0';
                current_state <= RECEIVING;
                transmit_active <= false;
                data_buffer <= (others => '0');
                result_buffer <= (others => '0');
                
            else
                case current_state is
                    when RECEIVING =>
                        tx_start <= '0';
                        proc_start <= '0';
                        proc_done_ack <= '0';
                        
                        if rx_valid = '1' then
                            -- Store received byte in appropriate position within data_buffer
                            data_buffer(8*(rx_count+1)-1 downto 8*rx_count) <= rx_data;
                            
                            if rx_count = BUFFER_SIZE-1 then
                                rx_count <= 0;
                                data_out_0 <= data_buffer(8*MEM_SIZE-1 downto 0);
                                data_out_1 <= data_buffer(2*8*MEM_SIZE-1 downto 8*MEM_SIZE);
                                data_out_2 <= data_buffer(3*8*MEM_SIZE-1 downto 2*8*MEM_SIZE);
                                data_out_3 <= data_buffer(4*8*MEM_SIZE-1 downto 3*8*MEM_SIZE);
                                proc_start <= '1';
                                current_state <= WAITING;
                            else
                                rx_count <= rx_count + 1;
                            end if;
                        end if;
                        
                    when WAITING =>
                        proc_start <= '0';
                        
                        if proc_done = '1' and proc_done_ack = '0' then
                            result_buffer(8*MEM_SIZE-1 downto 0) <= data_in_0;
                            result_buffer(2*8*MEM_SIZE-1 downto 8*MEM_SIZE) <= data_in_1;
                            result_buffer(3*8*MEM_SIZE-1 downto 2*8*MEM_SIZE) <= data_in_2;
                            result_buffer(4*8*MEM_SIZE-1 downto 3*8*MEM_SIZE) <= data_in_3;
                            tx_count <= 0;
                            proc_done_ack <= '1';
                            current_state <= TRANSMITTING;
                            delay_counter <= 0;
                            transmit_active <= false;
                        end if;
                        
                    when TRANSMITTING =>
                        if not transmit_active then
                            -- Extract appropriate byte from result_buffer
                            tx_data <= result_buffer(8*(tx_count+1)-1 downto 8*tx_count);
                            tx_start <= '1';
                            transmit_active <= true;
                            delay_counter <= 0;
                        else
                            tx_start <= '0';
                            if delay_counter = BAUD_DELAY then
                                if tx_count = BUFFER_SIZE-1 then
                                    current_state <= RECEIVING;
                                    tx_count <= 0;
                                else
                                    tx_count <= tx_count + 1;
                                end if;
                                transmit_active <= false;
                            else
                                delay_counter <= delay_counter + 1;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;
end Behavioral;