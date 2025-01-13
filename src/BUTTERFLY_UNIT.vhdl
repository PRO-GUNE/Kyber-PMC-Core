library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BUTTERFLY_UNIT is
    port (
        clk : in std_logic;
        mode : in std_logic;
        reset : in std_logic;
        enable : in std_logic;
        u_in : in std_logic_vector(11 downto 0);
        v_in : in std_logic_vector(11 downto 0);
        twiddle : in std_logic_vector(11 downto 0);
        u_out : out std_logic_vector(11 downto 0);
        v_out : out std_logic_vector(11 downto 0);

        -- debug outs
        u_v_debug : out std_logic_vector(11 downto 0)
    );
end entity BUTTERFLY_UNIT;

architecture Behavioral of BUTTERFLY_UNIT is

    component MOD_MUL
        port (
            clk    : in  std_logic;
            reset  : in  std_logic;
            enable : in  std_logic;
            a      : in  std_logic_vector(11 downto 0);
            b      : in  std_logic_vector(11 downto 0);
            mult   : out std_logic_vector(11 downto 0)
        );
    end component;

    component MOD_ADD
        port (
            clk    : in  std_logic;
            reset  : in  std_logic;
            enable : in  std_logic;
            a      : in  std_logic_vector(11 downto 0);
            b      : in  std_logic_vector(11 downto 0);
            sum    : out std_logic_vector(11 downto 0)
        );  
    end component;

    component MOD_SUB
        port (
            clk    : in  std_logic;
            reset  : in  std_logic;
            enable : in  std_logic;
            a      : in  std_logic_vector(11 downto 0);
            b      : in  std_logic_vector(11 downto 0);
            diff   : out std_logic_vector(11 downto 0)
        );
    end component;

    -- post scaling constant
    constant half : std_logic_vector(11 downto 0) := "101011110111"; -- 2^(-1)*k^(-2) mod 3329 = 1665*2285 = 2807 

    -- Pipeline registers
    signal reg_u1, reg_u2, reg_u3, reg_u4, reg_u5 : std_logic_vector(11 downto 0);
    signal reg_add, reg_sub         : std_logic_vector(11 downto 0);

    -- internal signals
    signal mod_u_in, mod_v_in, add_out, sub_out : std_logic_vector(11 downto 0);
    signal mul_u_in, mul_v_in, mul_out, scalar_out_0, scalar_out_1  : std_logic_vector(11 downto 0);   

begin

    add_unit : MOD_ADD
        port map(
            clk => clk,
            reset => reset,
            enable => enable,
            a => mod_u_in,
            b => mod_v_in,
            sum => add_out
        );

    sub_unit : MOD_SUB
        port map(
            clk => clk,
            reset => reset,
            enable => enable,
            a => mod_u_in,
            b => mod_v_in,
            diff => sub_out
        );

    mul_unit : MOD_MUL
        port map(
            clk => clk,
            reset => reset,
            enable => enable,
            a => mul_u_in,
            b => mul_v_in,
            mult => mul_out
        );

    scalar_unit_0 : MOD_MUL
        port map(
            clk => clk,
            reset => reset,
            enable => enable,
            a => twiddle,
            b => half,
            mult => scalar_out_0
        );

    scalar_unit_1 : MOD_MUL
        port map(
            clk => clk,
            reset => reset,
            enable => enable,
            a => reg_add,
            b => half,
            mult => scalar_out_1 
        );
    
    edge_triggered : process(clk, reset)
    begin
        if reset = '1' then
            -- reset registers
            reg_u1 <= (others => '0');
            reg_u2 <= (others => '0');
            reg_u3 <= (others => '0');
            reg_u4 <= (others => '0');
            reg_u5 <= (others => '0');
            reg_add <= (others => '0');
            reg_sub <= (others => '0');

        elsif enable = '1' then
            if rising_edge(clk) then
                reg_u1 <= u_in;
                reg_u2 <= reg_u1;
                reg_u3 <= reg_u2;
                reg_u4 <= reg_u3;
                reg_u5 <= reg_u4;
                reg_add <= add_out;
                reg_sub <= sub_out;
            end if;
        end if;
    end process ; -- edge_triggered
    
    -- asynchronous signals
    mod_u_in <= reg_u5 when mode='0' else u_in;
    mod_v_in <= mul_out when mode='0' else v_in;
    
    u_out <= add_out when mode='0' else scalar_out_1;
    v_out <= sub_out when mode='0' else mul_out;
    
    mul_u_in <= twiddle when mode='0' else scalar_out_0;
    mul_v_in <= v_in when mode='0' else reg_sub;

    -- debug outputs
    u_v_debug <= mul_out;

end Behavioral ; -- Behavioral