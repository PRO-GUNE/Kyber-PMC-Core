library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity RX_MAP is
  port (
    clk        : in std_logic;
    reset      : in std_logic;
    data_in    : in std_logic_vector(7 downto 0);
    data_valid : in std_logic;
    data_out0  : out std_logic_vector(23 downto 0); -- First 24-bit value
    data_out1  : out std_logic_vector(23 downto 0); -- Second 24-bit value
    data_out2  : out std_logic_vector(23 downto 0); -- Third 24-bit value
    data_out3  : out std_logic_vector(23 downto 0); -- Fourth 24-bit value
    ready      : out std_logic
  );
end RX_MAP;

architecture Behavioral of RX_MAP is
  type buffer_type is array (0 to 11) of std_logic_vector(7 downto 0);
  signal buff         : buffer_type           := (others => (others => '0'));
  signal count        : integer range 0 to 12 := 0;
  signal output_ready : std_logic             := '0';
begin

  process (clk, reset)
  begin
    if reset = '1' then
      buff         <= (others => (others => '0'));
      count        <= 0;
      output_ready <= '0';
    elsif rising_edge(clk) then
      if data_valid = '1' then
        buff(count) <= data_in;
        count       <= count + 1;
        if count = 11 then
          output_ready <= '1';
          count        <= 0;
        else
          output_ready <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Assign 4 separate 24-bit outputs
  data_out0 <= buff(2) & buff(1) & buff(0) when output_ready = '1' else
    (others => '0');
  data_out1 <= buff(5) & buff(4) & buff(3) when output_ready = '1' else
    (others => '0');
  data_out2 <= buff(8) & buff(7) & buff(6) when output_ready = '1' else
    (others => '0');
  data_out3 <= buff(11) & buff(10) & buff(9) when output_ready = '1' else
    (others => '0');

  ready <= output_ready;

end Behavioral;