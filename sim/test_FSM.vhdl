library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity test_FSM is
end test_FSM;

architecture behavior of test_FSM is
    -- Constants
    constant CLK_PERIOD : time := 10 ns;  -- 100MHz clock
    constant N : integer := 256;
    constant Q : integer := 3329;
    
    -- Component Declaration
    component FSM
        generic (
            n : integer := 256;
            q : integer := 3329
        );
        port (
            clk           : in  std_logic;
            reset        : in  std_logic;
            mode         : in  std_logic_vector(2 downto 0);
            done         : out std_logic;
            data_transmit : out std_logic_vector(23 downto 0);

            deb_addr_rd_0 : out std_logic_vector(6 downto 0);
            deb_addr_rd_1 : out std_logic_vector(6 downto 0);
            deb_addr_rd_2 : out std_logic_vector(6 downto 0);
            deb_addr_rd_3 : out std_logic_vector(6 downto 0);
            deb_addr_wr_0 : out std_logic_vector(6 downto 0);
            deb_addr_wr_1 : out std_logic_vector(6 downto 0);
            deb_addr_wr_2 : out std_logic_vector(6 downto 0);
            deb_addr_wr_3 : out std_logic_vector(6 downto 0);
            deb_tw_addr_0 : out std_logic_vector(6 downto 0);
            deb_tw_addr_1 : out std_logic_vector(6 downto 0);

            deb_k : out integer;
            deb_l : out integer;
            deb_s : out integer;
            deb_j : out integer
        );
    end component;
    
    -- Signal Declarations
    signal clk_tb          : std_logic := '0';
    signal reset_tb       : std_logic := '0';
    signal mode_tb        : std_logic_vector(2 downto 0) := "000";
    signal done_tb        : std_logic;
    signal data_transmit_tb : std_logic_vector(23 downto 0);

    signal deb_addr_rd_0 : std_logic_vector(6 downto 0);
    signal deb_addr_rd_1 : std_logic_vector(6 downto 0);
    signal deb_addr_rd_2 : std_logic_vector(6 downto 0);
    signal deb_addr_rd_3 : std_logic_vector(6 downto 0);
    signal deb_addr_wr_0 : std_logic_vector(6 downto 0);
    signal deb_addr_wr_1 : std_logic_vector(6 downto 0);
    signal deb_addr_wr_2 : std_logic_vector(6 downto 0);
    signal deb_addr_wr_3 : std_logic_vector(6 downto 0);
    signal deb_tw_addr_0 : std_logic_vector(6 downto 0);
    signal deb_tw_addr_1 : std_logic_vector(6 downto 0);
    signal deb_k, deb_l, deb_s, deb_j : integer;
    
    -- Test control signals
    signal sim_done : boolean := false;
    signal clock_count : integer := 0;
    
begin
    -- Device Under Test (DUT) instantiation
    DUT: FSM
        generic map (
            n => N,
            q => Q
        )
        port map (
            clk           => clk_tb,
            reset        => reset_tb,
            mode         => mode_tb,
            done         => done_tb,
            data_transmit => data_transmit_tb,
            deb_addr_rd_0 => deb_addr_rd_0,
            deb_addr_rd_1 => deb_addr_rd_1,
            deb_addr_rd_2 => deb_addr_rd_2,
            deb_addr_rd_3 => deb_addr_rd_3,
            deb_addr_wr_0 => deb_addr_wr_0,
            deb_addr_wr_1 => deb_addr_wr_1,
            deb_addr_wr_2 => deb_addr_wr_2,
            deb_addr_wr_3 => deb_addr_wr_3,
            deb_tw_addr_0 => deb_tw_addr_0,
            deb_tw_addr_1 => deb_tw_addr_1,
            deb_k => deb_k,
            deb_l => deb_l,
            deb_s => deb_s,
            deb_j => deb_j
        );
    
    -- Clock generation process
    clk_process: process
    begin
        while not sim_done loop
            clk_tb <= '0';
            wait for CLK_PERIOD/2;
            clk_tb <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;
    
    -- Clock counter process
    clock_counter: process(clk_tb)
    begin
        if rising_edge(clk_tb) then
            clock_count <= clock_count + 1;
        end if;
    end process;
    
    -- Stimulus process
    stim_proc: process
    begin
        -- Initialize signals
        reset_tb <= '1';
        mode_tb <= "000";  -- IDLE mode
        wait for CLK_PERIOD * 2;
        
        -- Release reset
        reset_tb <= '0';
        mode_tb <= "000";  -- IDLE mode
        wait for CLK_PERIOD * 2;
        
        mode_tb <= "001";  -- NTT mode
        -- Wait for NTT operation (240 clock cycles)
        wait for CLK_PERIOD * 500;
        
        -- Verify if done signal is asserted
        assert done_tb = '1'
            report "ERROR: NTT operation not completed after 240 clock cycles!"
            severity ERROR;
        
        mode_tb <= "000";  -- IDLE mode
        wait for CLK_PERIOD * 2;    

        -- Additional test: Try Read mode
        mode_tb <= "100";  -- Read mode
        wait for CLK_PERIOD * 240;
        
        -- End simulation
        sim_done <= true;
        wait;
    end process;
    
    -- Monitor process
    monitor_proc: process(clk_tb)
        variable cycle_count : integer := 0;
    begin
        if rising_edge(clk_tb) then
            -- Print relevant signals for debugging
            report "Cycle: " & integer'image(cycle_count) &
                  " Mode: " & integer'image(to_integer(unsigned(mode_tb))) &
                  " Done: " & std_logic'image(done_tb) &
                  " Data: " & integer'image(to_integer(unsigned(data_transmit_tb)));
            
            -- Verify timing requirements
            if cycle_count = 240 then
                assert done_tb = '1'
                    report "ERROR: NTT operation did not complete in expected time!"
                    severity ERROR;
            end if;
            
            cycle_count := cycle_count + 1;
        end if;
    end process;
    
    -- Verification process
    verify_proc: process
        -- Add any verification variables here
    begin
        wait until rising_edge(clk_tb);
        
        -- Wait for reset to complete
        wait until reset_tb = '0';
        
        -- Monitor NTT operation
        while done_tb = '0' loop
            -- Verify that k, l, s, j values are within expected ranges
            -- (These would need to be made visible from the FSM for complete verification)
            wait until rising_edge(clk_tb);
        end loop;
        
        -- Verify final state
        assert mode_tb = "000" and done_tb = '1'
            report "ERROR: Unexpected final state!"
            severity ERROR;
            
        wait;
    end process;
    
end behavior;