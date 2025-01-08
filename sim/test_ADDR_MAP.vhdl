library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test_ADDR_MAP is
end entity test_ADDR_MAP;

architecture Behavioral of test_ADDR_MAP is
    constant NUM_BANKS : integer := 4;

    -- DUT ports
    signal clk         : std_logic := '0';
    signal addr_0      : std_logic_vector(6 downto 0) := (others => '0');
    signal addr_1      : std_logic_vector(6 downto 0) := (others => '0');
    signal addr_2      : std_logic_vector(6 downto 0) := (others => '0');
    signal addr_3      : std_logic_vector(6 downto 0) := (others => '0');
    signal bank_addr_0 : std_logic_vector(4 downto 0);
    signal bank_addr_1 : std_logic_vector(4 downto 0);
    signal bank_addr_2 : std_logic_vector(4 downto 0);
    signal bank_addr_3 : std_logic_vector(4 downto 0);

    -- Clock period
    constant clk_period : time := 10 ns;

begin
    -- Instantiate the DUT
    DUT: entity work.ADDR_MAP
        port map (
            clk => clk,
            addr_0 => addr_0,
            addr_1 => addr_1,
            addr_2 => addr_2,
            addr_3 => addr_3,
            bank_addr_0 => bank_addr_0,
            bank_addr_1 => bank_addr_1,
            bank_addr_2 => bank_addr_2,
            bank_addr_3 => bank_addr_3
        );

    -- Clock generation process
    clk_process : process
    begin
        clk <= not clk;
        wait for clk_period / 2;
    end process;

    -- Test process
    test_process : process
    begin
        -- Iterate through all test cases for raw addresses 0 to 16
        for addr in 0 to 3 loop
            -- Apply test values to all input addresses
            addr_0 <= std_logic_vector(to_unsigned(4*addr, 7));
            addr_1 <= std_logic_vector(to_unsigned(4*addr + 1, 7));
            addr_2 <= std_logic_vector(to_unsigned(4*addr + 2, 7));
            addr_3 <= std_logic_vector(to_unsigned(4*addr + 3, 7));

            -- Wait for one clock cycle
            wait for clk_period;

            -- Log results
            report "Test case: addr_0 = " & integer'image(addr) &
                   ", addr_1 = " & integer'image(addr + 1) &
                   ", addr_2 = " & integer'image(addr + 2) &
                   ", addr_3 = " & integer'image(addr + 3);
            report "Bank Addresses: bank_addr_0 = " & integer'image(to_integer(unsigned(bank_addr_0))) &
                   ", bank_addr_1 = " & integer'image(to_integer(unsigned(bank_addr_1))) &
                   ", bank_addr_2 = " & integer'image(to_integer(unsigned(bank_addr_2))) &
                   ", bank_addr_3 = " & integer'image(to_integer(unsigned(bank_addr_3)));
        end loop;

        -- End simulation
        wait;
    end process;

end architecture Behavioral;
