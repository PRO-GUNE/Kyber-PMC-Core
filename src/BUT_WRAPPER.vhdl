library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

entity BUT_WRAPPER is
  port (
    clk : in std_logic;
    reset : in std_logic;
    mode : in std_logic_vector(1 downto 0);
    u_in_1 : in std_logic_vector(47 downto 0);
    u_in_2 : in std_logic_vector(47 downto 0);
    info: out std_logic
  ) ;
end BUT_WRAPPER ; 

architecture arch of BUT_WRAPPER is
  component ASYM_BUT_CORE is
    port (
          clk      : in std_logic;
          mode     : in std_logic_vector(1 downto 0);
          reset    : in std_logic;
          enable   : in std_logic;
          u_in     : in std_logic_vector(47 downto 0); -- 4x 12-bit inputs
          v_in     : in std_logic_vector(47 downto 0); -- 4x 12-bit inputs
          tw_addr_0 : in std_logic_vector(6 downto 0); -- twiddle addr_0
          tw_addr_1 : in std_logic_vector(6 downto 0); -- twiddle addr_1
          u_out    : out std_logic_vector(47 downto 0); -- 4x 12-bit outputs
          v_out    : out std_logic_vector(47 downto 0) -- 4x 12-bit outputs
    );
  end component;

  signal u_in_internal, v_in_internal : std_logic_vector(47 downto 0) := (others => '0');
  signal u_out_internal, v_out_internal : std_logic_vector(47 downto 0) := (others => '0');
  signal tw_addr_0, tw_addr_1 : std_logic_vector(6 downto 0) := (others => '0');

begin
    -- 4x1 butterfly unit
    BUT_CORE : ASYM_BUT_CORE
    port map(
        clk => clk,
        mode => mode,
        reset => reset,
        enable => '1',
        u_in => u_in_internal,
        v_in => v_in_internal,
        tw_addr_0 => tw_addr_0, 
        tw_addr_1 => tw_addr_1,
        u_out => u_out_internal,
        v_out => v_out_internal
    );
    
info <= u_out_internal(0) and v_out_internal(0);

end architecture ;