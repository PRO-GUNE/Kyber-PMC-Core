library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test_RAM is
end test_RAM;

architecture sim of test_RAM is
    -- Constants
    constant CLK_PERIOD : time := 10 ns;
    
    -- Test signals
    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal wr_en     : std_logic_vector(3 downto 0) := (others => '0');
    signal rd_en     : std_logic_vector(3 downto 0) := (others => '0');
    
    -- Write signals
    signal wr_addr_0, wr_addr_1, wr_addr_2, wr_addr_3 : std_logic_vector(6 downto 0) := (others => '0');
    signal wr_data_0, wr_data_1, wr_data_2, wr_data_3 : std_logic_vector(23 downto 0) := (others => '0');
    
    -- Read signals
    signal rd_addr_0, rd_addr_1, rd_addr_2, rd_addr_3 : std_logic_vector(6 downto 0) := (others => '0');
    signal rd_data_0, rd_data_1, rd_data_2, rd_data_3 : std_logic_vector(23 downto 0);

begin
    -- DUT instantiation
    DUT: entity work.RAM
    port map (
        clk => clk, rst => rst,
        wr_en => wr_en, rd_en => rd_en,
        wr_addr_0 => wr_addr_0, wr_addr_1 => wr_addr_1,
        wr_addr_2 => wr_addr_2, wr_addr_3 => wr_addr_3,
        wr_data_0 => wr_data_0, wr_data_1 => wr_data_1,
        wr_data_2 => wr_data_2, wr_data_3 => wr_data_3,
        rd_addr_0 => rd_addr_0, rd_addr_1 => rd_addr_1,
        rd_addr_2 => rd_addr_2, rd_addr_3 => rd_addr_3,
        rd_data_0 => rd_data_0, rd_data_1 => rd_data_1,
        rd_data_2 => rd_data_2, rd_data_3 => rd_data_3
    );

    -- Clock generation
    clk <= not clk after CLK_PERIOD/2;

    -- Stimulus process
    stimulus: process
    begin
        -- Reset
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD;

        -- Test 1: Independent write to all banks simultaneously
        wr_en <= "1111";
        wr_addr_0 <= "0000001";  -- Address 1
        wr_addr_1 <= "0000010";  -- Address 2
        wr_addr_2 <= "0000011";  -- Address 3
        wr_addr_3 <= "0000100";  -- Address 4
        
        wr_data_0 <= x"111111";
        wr_data_1 <= x"222222";
        wr_data_2 <= x"333333";
        wr_data_3 <= x"444444";
        
        wait for CLK_PERIOD;
        wr_en <= "0000";
        
        -- Test 2: Independent read from all banks simultaneously
        rd_en <= "1111";
        rd_addr_0 <= "0000001";  -- Address 1
        rd_addr_1 <= "0000010";  -- Address 2
        rd_addr_2 <= "0000011";  -- Address 3
        rd_addr_3 <= "0000100";  -- Address 4
        
        wait for CLK_PERIOD;
        rd_en <= "0000";
        wait for CLK_PERIOD;  -- Wait for read data
        
        -- Verify read data
        assert rd_data_0 = x"111111" report "Bank 0 read error" severity error;
        assert rd_data_1 = x"222222" report "Bank 1 read error" severity error;
        assert rd_data_2 = x"333333" report "Bank 2 read error" severity error;
        assert rd_data_3 = x"444444" report "Bank 3 read error" severity error;
        
        -- Test 3: Simultaneous read/write to different addresses in same bank
        -- Write new data
        wr_en <= "1111";
        wr_addr_0 <= "0010000";  -- Address 16
        wr_addr_1 <= "0010001";  -- Address 17
        wr_addr_2 <= "0010010";  -- Address 18
        wr_addr_3 <= "0010011";  -- Address 19
        
        wr_data_0 <= x"AAAA00";
        wr_data_1 <= x"AAAA11";
        wr_data_2 <= x"AAAA22";
        wr_data_3 <= x"AAAA33";
        
        -- Read previous data simultaneously
        rd_en <= "1111";
        rd_addr_0 <= "0000001";  -- Address 1
        rd_addr_1 <= "0000010";  -- Address 2
        rd_addr_2 <= "0000011";  -- Address 3
        rd_addr_3 <= "0000100";  -- Address 4
        
        wait for CLK_PERIOD;
        
        -- Read newly written data
        rd_addr_0 <= "0010000";  -- Address 16
        rd_addr_1 <= "0010001";  -- Address 17
        rd_addr_2 <= "0010010";  -- Address 18
        rd_addr_3 <= "0010011";  -- Address 19
        wait for CLK_PERIOD;

        wr_en <= "0000";
        rd_en <= "0000";
        
        -- End simulation
        wait for CLK_PERIOD * 2;
        report "Simulation completed successfully!";
        wait;
    end process;

end sim;