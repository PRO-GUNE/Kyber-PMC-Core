library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MOD_MUL is
    port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        enable : in  std_logic;
        a      : in  std_logic_vector(11 downto 0);
        b      : in  std_logic_vector(11 downto 0);
        mult   : out std_logic_vector(11 downto 0)
    );
end entity MOD_MUL;

architecture Behavioral of MOD_MUL is
    component MUL
        port (
            clk     : in  std_logic;                      -- Added clock for M register
            enable  : in  std_logic;
            a       : in  std_logic_vector(11 downto 0);
            b       : in  std_logic_vector(11 downto 0);
            result  : out std_logic_vector(23 downto 0)
        );
    end component;

    component MOD_K2_RED
        port (
            clk     : in std_logic;  -- Added clock input
            reset     : in std_logic;  -- Added reset input
            c_in    : in std_logic_vector(23 downto 0);
            c_out   : out std_logic_vector(11 downto 0)
        );
    end component;

    signal mul_out : std_logic_vector(23 downto 0);

begin
    mul_unit : MUL
        port map(
            clk => clk,
            enable => enable,
            a => a,
            b => b,
            result => mul_out
        );

    mod_k2_red_unit : MOD_K2_RED
        port map(
            clk => clk,
            reset => reset,
            c_in => mul_out,
            c_out => mult
        );
end architecture Behavioral;