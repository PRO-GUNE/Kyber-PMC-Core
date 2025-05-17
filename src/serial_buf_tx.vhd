----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/15/2025 11:24:40 AM
-- Design Name: 
-- Module Name: serial_buf_tx - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity serial_buf_tx is
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
end serial_buf_tx;

architecture Behavioral of serial_buf_tx is
    type buffer_type is array (0 to 11) of STD_LOGIC_VECTOR(7 downto 0);
    signal buff : buffer_type := (others => (others => '0'));
    signal count : integer range 0 to 12 := 0;
    signal ready : STD_LOGIC := '0';
begin

    process(clk)
    begin
        if rst = '1' then
            buff <= (others => (others => '0'));
            count <= 0;
            ready <= '0';
        elsif rising_edge(clk) then
            if data_valid = '1' and count = 0 and ready = '0' then
                -- Split 24-bit inputs into 8-bit chunks and store in buffer
                buff(0) <= data_in_0(23 downto 16);
                buff(1) <= data_in_0(15 downto 8);
                buff(2) <= data_in_0(7 downto 0);
                buff(3) <= data_in_1(23 downto 16);
                buff(4) <= data_in_1(15 downto 8);
                buff(5) <= data_in_1(7 downto 0);
                buff(6) <= data_in_2(23 downto 16);
                buff(7) <= data_in_2(15 downto 8);
                buff(8) <= data_in_2(7 downto 0);
                buff(9) <= data_in_3(23 downto 16);
                buff(10) <= data_in_3(15 downto 8);
                buff(11) <= data_in_3(7 downto 0);
                ready <= '1';
            elsif ready = '1' and busy = '0' and count < 12 then
                -- Transmit data sequentially
                data_out <= buff(count);
                count <= count + 1;
            elsif count = 12 then
                ready <= '0';
                count <= 0;
            end if;
        end if;
    end process;
    
    data_send <= ready;
end Behavioral;
