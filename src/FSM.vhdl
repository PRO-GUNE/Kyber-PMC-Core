library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FSM is
    generic (
        n : integer := 256;    -- Vector size
        q : integer := 3329 -- Prime modulus
    );
    port (
        clk       : in  std_logic;  -- Clock signal
        reset     : in  std_logic;  -- Reset signal
        mode      : in  std_logic_vector(3 downto 0); -- Input selection (000: IDLE, 001: NTT0, 010: INTT0, 011: NTT1, 100: INTT1, 101: PWM, 110: RD0, 111: WR0, 1000: RD0, 1001: WR0)
        done      : out std_logic;  -- Done signal
        data_transmit  : out std_logic_vector(23 downto 0);

        -- debug outputs
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
end FSM;

architecture Behavioral of FSM is
    -- Define states
    type state_type is (IDLE, NTT0, INTT0, NTT1, INTT1, PWM, RD0, WR0, RD1, WR1);
    signal current_state, next_state : state_type;

    signal enable_RAM, enable_BUT : std_logic := '0';

    -- Sending data_out
    signal data_out : std_logic_vector(23 downto 0) := (others => '0');

    -- Twiddle factor address signals 
    signal tw_addr_0, tw_addr_1 : std_logic_vector(6 downto 0);

    -- Address map addresses
    signal addr_rd_0, addr_rd_1, addr_rd_2, addr_rd_3 : std_logic_vector(6 downto 0);
    signal addr_wr_0, addr_wr_1, addr_wr_2, addr_wr_3 : std_logic_vector(6 downto 0);
    signal rd_en :  std_logic_vector(3 downto 0);
    signal wr_en :  std_logic_vector(3 downto 0);

    -- NTT specific signals
    signal k, l, s, j, stage : integer;
    
    -- Polynomial Multiplication Core
    component PMC_CORE is
        port (
          clk : in std_logic;
          reset : in std_logic;
          mode  : in  std_logic_vector(1 downto 0); -- Input selection (00: NTT, 01: INTT, 10: PWM)
          rd_en : in std_logic_vector(3 downto 0);
          wr_en : in std_logic_vector(3 downto 0);
          enable_BUT : in std_logic;
          enable_RAM : in std_logic;
          addr_rd_0 : in std_logic_vector(6 downto 0);
          addr_rd_1 : in std_logic_vector(6 downto 0);
          addr_rd_2 : in std_logic_vector(6 downto 0);
          addr_rd_3 : in std_logic_vector(6 downto 0);
          addr_wr_0 : in std_logic_vector(6 downto 0);
          addr_wr_1 : in std_logic_vector(6 downto 0);
          addr_wr_2 : in std_logic_vector(6 downto 0);
          addr_wr_3 : in std_logic_vector(6 downto 0);
          tw_addr_0 : in std_logic_vector(6 downto 0);
          tw_addr_1 : in std_logic_vector(6 downto 0);
          data_out : out std_logic_vector(23 downto 0)
        ) ;
    end component;
    

begin
    -- Polynomial multiplication core
    POLY_CORE : PMC_CORE
    port map(
        clk => clk,
        reset => reset,
        mode => mode(1 downto 0),
        rd_en => rd_en,
        wr_en => wr_en,
        enable_BUT => enable_BUT,
        enable_RAM => enable_RAM,
        sel_RAM => sel_RAM,
        addr_rd_0 => addr_rd_0,
        addr_rd_1 => addr_rd_1,
        addr_rd_2 => addr_rd_2,
        addr_rd_3 => addr_rd_3,
        addr_wr_0 => addr_wr_0,
        addr_wr_1 => addr_wr_1,
        addr_wr_2 => addr_wr_2,
        addr_wr_3 => addr_wr_3,
        tw_addr_0 => tw_addr_0,
        tw_addr_1 => tw_addr_1,
        data_out => data_out
    );
    
    -- Clock process
    clk_process : process(clk, reset)
    begin
        if reset = '1' then
            current_state <= IDLE; -- Default state after reset
            -- Default outputs
            next_state <= current_state;

        elsif rising_edge(clk) then
            case mode is
                when "0000" => next_state <= IDLE;
                when "0001" => next_state <= NTT0;
                when "0010" => next_state <= INTT0;
                when "0011" => next_state <= NTT1;
                when "0100" => next_state <= INTT1;
                when "0101" => next_state <= PWM;
                when "0110" => next_state <= RD0;
                when "1000" => next_state <= RD1;
                when "1001" => next_state <= WR1;
                when others => next_state <= IDLE; -- Invalid input, stay in IDLE
            end case;
                
            current_state <= next_state;
        
        end if;

    end process;


    -- Combinational process for next state logic
    process(current_state, clk)
    begin
        if rising_edge(clk) then
            case current_state is
                when IDLE =>
                    k <= 1;
                    l <= n/2;
                    s <= 0;
                    j <= 0;
                    sel_RAM <= '0';

                    -- reset signals to multiplication core
                    rd_en <= (others => '0');
                    wr_en <= (others => '0');
                    addr_rd_0 <= (others => '0');
                    addr_rd_1 <= (others => '0');
                    addr_rd_2 <= (others => '0');
                    addr_rd_3 <= (others => '0');
                    addr_wr_0 <= (others => '0');
                    addr_wr_1 <= (others => '0');
                    addr_wr_2 <= (others => '0');
                    addr_wr_3 <= (others => '0');
                    tw_addr_0 <= (others => '0');
                    tw_addr_1 <= (others => '0');
                    done <= '0'; -- Indicate completion

                when NTT0 =>
                    enable_BUT <= '1';
                    enable_RAM <= '1';
                    if l > 1 then
                        if s < n then
                            if l >= 4 then
                                if j < s + l then
                                    -- Update butterfly computation indices
                                    rd_en <= "1111";
                                    wr_en <= "1111";
                                    addr_rd_0 <= std_logic_vector(to_unsigned(j, 7));
                                    addr_rd_1 <= std_logic_vector(to_unsigned(j+2, 7));
                                    addr_rd_2 <= std_logic_vector(to_unsigned(j+l, 7));
                                    addr_rd_3 <= std_logic_vector(to_unsigned(j+l+2, 7));
                                    addr_wr_0 <= std_logic_vector(to_unsigned(j, 7));
                                    addr_wr_1 <= std_logic_vector(to_unsigned(j+2, 7));
                                    addr_wr_2 <= std_logic_vector(to_unsigned(j+l, 7));
                                    addr_wr_3 <= std_logic_vector(to_unsigned(j+l+2, 7));
                                    tw_addr_0 <= std_logic_vector(to_unsigned(k, 7));
                                    tw_addr_1 <= std_logic_vector(to_unsigned(k, 7));
                                    j <= j + 4;
                                else
                                    k <= k + 1;
                                    s <= s + 2*l;
                                    j <= s + 2*l;
                                end if;
                            elsif l = 2 then
                                addr_rd_0 <= std_logic_vector(to_unsigned(s, 7));
                                addr_rd_1 <= std_logic_vector(to_unsigned(s+4, 7));
                                addr_rd_2 <= std_logic_vector(to_unsigned(s+2, 7));
                                addr_rd_3 <= std_logic_vector(to_unsigned(s+6, 7));
                                addr_wr_0 <= std_logic_vector(to_unsigned(j, 7));
                                addr_wr_1 <= std_logic_vector(to_unsigned(j+2, 7));
                                addr_wr_2 <= std_logic_vector(to_unsigned(j+l, 7));
                                addr_wr_3 <= std_logic_vector(to_unsigned(j+l+2, 7));
                                tw_addr_0 <= std_logic_vector(to_unsigned(k, 7));
                                tw_addr_1 <= std_logic_vector(to_unsigned(k+1, 7));
                                s <= s + 4;
                                k <= k + 2;
                            end if;
                        else
                            s <= 0;
                            j <= 0;
                            l <= l/2;
                        end if;
                    else
                        done <= '1'; -- Indicate completion
                    end if;

                when RD0 =>
                    enable_BUT <= '0';
                    enable_RAM <= '1';
                    rd_en <= "1111";
                    if j < l then
                        addr_rd_0 <= std_logic_vector(to_unsigned(j, 7));
                    end if;
                    j <= j+1;
                    
                when others =>
                    

            end case;
        end if;
    end process;

    deb_addr_rd_0 <= addr_rd_0;  
    deb_addr_rd_1 <= addr_rd_1; 
    deb_addr_rd_2 <= addr_rd_2; 
    deb_addr_rd_3 <= addr_rd_3; 
    deb_addr_wr_0 <= addr_wr_0; 
    deb_addr_wr_1 <= addr_wr_1; 
    deb_addr_wr_2 <= addr_wr_2; 
    deb_addr_wr_3 <= addr_wr_3; 
    deb_tw_addr_0 <= tw_addr_0; 
    deb_tw_addr_1 <= tw_addr_1; 

    deb_k <= k;
    deb_l <= l;
    deb_s <= s;
    deb_j <= j;

    data_transmit <= data_out;
end Behavioral;
