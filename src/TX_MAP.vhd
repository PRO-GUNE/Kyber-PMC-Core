library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TX_MAP is
    Port (
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        data_in0   : in  STD_LOGIC_VECTOR(23 downto 0); -- First 24-bit value
        data_in1   : in  STD_LOGIC_VECTOR(23 downto 0); -- Second 24-bit value
        data_in2   : in  STD_LOGIC_VECTOR(23 downto 0); -- Third 24-bit value
        data_in3   : in  STD_LOGIC_VECTOR(23 downto 0); -- Fourth 24-bit value
        data_valid : in  STD_LOGIC;
        data_out   : out STD_LOGIC_VECTOR(7 downto 0);
        ready      : out STD_LOGIC
    );
end TX_MAP;

architecture Behavioral of TX_MAP is
    type buffer_type is array (0 to 11) of STD_LOGIC_VECTOR(7 downto 0);
    signal buff : buffer_type := (others => (others => '0'));
    signal count : integer range 0 to 12 := 0;
    signal output_ready : STD_LOGIC := '0';
begin

    process(clk, reset)
    begin
        if reset = '1' then
            buff <= (others => (others => '0'));
            count <= 0;
            output_ready <= '0';
        elsif rising_edge(clk) then
            if data_valid = '1' and count = 0 then
                -- Split 24-bit inputs into 8-bit chunks and store in buffer
                buff(0) <= data_in0(23 downto 16);
                buff(1) <= data_in0(15 downto 8);
                buff(2) <= data_in0(7 downto 0);
                buff(3) <= data_in1(23 downto 16);
                buff(4) <= data_in1(15 downto 8);
                buff(5) <= data_in1(7 downto 0);
                buff(6) <= data_in2(23 downto 16);
                buff(7) <= data_in2(15 downto 8);
                buff(8) <= data_in2(7 downto 0);
                buff(9) <= data_in3(23 downto 16);
                buff(10) <= data_in3(15 downto 8);
                buff(11) <= data_in3(7 downto 0);
                output_ready <= '1';
            elsif output_ready = '1' then
                -- Transmit data sequentially
                data_out <= buff(count);
                count <= count + 1;
                if count = 11 then
                    output_ready <= '0';
                    count <= 0;
                end if;
            end if;
        end if;
    end process;

    ready <= not output_ready;

end Behavioral;