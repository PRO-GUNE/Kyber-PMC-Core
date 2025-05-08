library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SIMPLE_CORE_TB is
end SIMPLE_CORE_TB;


architecture TB of SIMPLE_CORE_TB is

    -- Component declaration
    component SIMPLE_CORE
        port (
            clk   : in std_logic;
            reset : in std_logic;
            deb_addr: out std_logic_vector(6 downto 0)
        );
    end component;

    -- Signals for the testbench
    signal clk   : std_logic := '0';
    signal reset : std_logic := '0';
    signal addr_0 : std_logic_vector(6 downto 0);

begin

    -- Instantiate the DUT (Device Under Test)
    DUT : SIMPLE_CORE
        port map (
            clk   => clk,
            reset => reset,
            deb_addr => addr_0
        );

    -- Clock generation process
    clk_process : process
    begin
        clk <= not clk;
        wait for 5 ns;
    end process;

    -- Test process
    test_process : process
    begin
        reset <= '1';
        wait for 50 ns;
        reset <= '0';
        wait for 5 ns;
        wait;
    end process;


end TB;