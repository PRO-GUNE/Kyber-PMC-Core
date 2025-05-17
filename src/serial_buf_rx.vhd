----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/14/2025 04:39:14 PM
-- Design Name: 
-- Module Name: serial_buf - Behavioral
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

entity serial_buf_rx is
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
end serial_buf_rx;

architecture Behavioral of serial_buf_rx is
    type buffer_type is array (0 to 11) of std_logic_vector(7 downto 0);
    signal buff         : buffer_type           := (others => (others => '0'));
    signal count        : integer range 0 to 12 := 0;
    signal full         : std_logic;
begin
    process (clk)
    begin
      if rst = '1' then
            buff <= (others => (others => '0'));
            count <= 0;
            full <= '0';
            data_out_0 <= (others => '0');
            data_out_1 <= (others => '0');
            data_out_2 <= (others => '0');
            data_out_3 <= (others => '0');
      elsif rising_edge(clk) then
        if rst = '1' then
            buff <= (others => (others => '0'));
            count <= 0;
            full <= '0';
        elsif data_valid = '1' and count < 12 then
            buff(count) <= data_in;
            count       <= count + 1;
            full <= '0';
        elsif count >= 12 then
          full <= '1';
          count <= 0;
          data_out_0 <= buff(0) & buff(1) & buff(2);
          data_out_1 <= buff(3) & buff(4) & buff(5);
          data_out_2 <= buff(6) & buff(7) & buff(8);
          data_out_3 <= buff(9) & buff(10) & buff(11);
        end if;
     end if;
     end process;
     
     buf_full <= full;
    
end Behavioral;
