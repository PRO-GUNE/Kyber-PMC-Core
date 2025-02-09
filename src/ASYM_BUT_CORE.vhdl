library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

entity ASYM_BUT_CORE is
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
        v_out    : out std_logic_vector(47 downto 0); -- 4x 12-bit outputs

        u0        : out std_logic_vector(11 downto 0);
        u1        : out std_logic_vector(11 downto 0);
        u2        : out std_logic_vector(11 downto 0);
        u3        : out std_logic_vector(11 downto 0);
        v0        : out std_logic_vector(11 downto 0);
        v1        : out std_logic_vector(11 downto 0);
        v2        : out std_logic_vector(11 downto 0);
        v3        : out std_logic_vector(11 downto 0);
        tw_0_out  : out std_logic_vector(11 downto 0);
        tw_1_out  : out std_logic_vector(11 downto 0);
        u_v_debug  : out std_logic_vector(11 downto 0)
  ) ;
end ASYM_BUT_CORE ;

architecture Behavioral of ASYM_BUT_CORE is
    component TWIDDLE_ROM is
        port(
            clk : in std_logic;
            en : in std_logic;
            addr_0 : in std_logic_vector(6 downto 0);
            addr_1 : in std_logic_vector(6 downto 0);
            data_0 : out std_logic_vector(11 downto 0);
            data_1 : out std_logic_vector(11 downto 0)
        );
    end component;

    -- Component declaration
    component BUTTERFLY_UNIT is
        port (
            clk      : in std_logic;
            mode     : in std_logic_vector(1 downto 0);
            reset    : in std_logic;
            enable   : in std_logic;
            u_in     : in std_logic_vector(11 downto 0);
            v_in     : in std_logic_vector(11 downto 0);
            twiddle  : in std_logic_vector(11 downto 0);
            u_out    : out std_logic_vector(11 downto 0);
            v_out    : out std_logic_vector(11 downto 0)

        );
    end component;

    component BUTTERFLY_UNIT_1 is
        port (
            clk : in std_logic;
            mode : in std_logic_vector(1 downto 0);
            reset : in std_logic;
            enable : in std_logic;
            u_in : in std_logic_vector(11 downto 0);
            v_in : in std_logic_vector(11 downto 0);
            twiddle : in std_logic_vector(11 downto 0);
            u_out : out std_logic_vector(11 downto 0);
            v_out : out std_logic_vector(11 downto 0);
            u_v_debug : out std_logic_vector(11 downto 0)
        );
    end component;

    component BUTTERFLY_UNIT_2 is
        port (
            clk : in std_logic;
            mode : in std_logic_vector(1 downto 0);
            reset : in std_logic;
            enable : in std_logic;
            u_in : in std_logic_vector(11 downto 0);
            v_in : in std_logic_vector(11 downto 0);
            twiddle : in std_logic_vector(11 downto 0);
            u_out : out std_logic_vector(11 downto 0);
            v_out : out std_logic_vector(11 downto 0)
        );
    end component;

    signal but_00_u_in, but_01_u_in, but_00_u_out, but_01_u_out : std_logic_vector(11 downto 0); 
    signal but_00_v_in, but_01_v_in, but_00_v_out, but_01_v_out : std_logic_vector(11 downto 0); 
    signal but_1_u_in, but_1_v_in, but_2_u_in, but_2_v_in : std_logic_vector(11 downto 0); 
    signal but_00_tw_in, but_01_tw_in, but_1_tw_in, but_2_tw_in : std_logic_vector(11 downto 0); 
    signal but_1_u_out, but_1_v_out, but_2_u_out, but_2_v_out : std_logic_vector(11 downto 0); 

    signal tw_0, tw_1 : std_logic_vector(11 downto 0);

begin
    -- Instantiate Twiddle ROM
    TW_ROM : TWIDDLE_ROM
        port map(
            clk => clk,
            en => enable,
            addr_0 => tw_addr_0,
            addr_1 => tw_addr_1,
            data_0 => tw_0,
            data_1 => tw_1
        );

    BUT_0_0 : BUTTERFLY_UNIT
        port map(
            clk => clk,
            mode => mode,
            reset => reset,
            enable => enable,
            u_in => but_00_u_in,
            v_in => but_00_v_in,
            twiddle => but_00_tw_in,
            u_out => but_00_u_out,
            v_out => but_00_v_out
        );

    BUT_0_1 : BUTTERFLY_UNIT
        port map(
            clk => clk,
            mode => mode,
            reset => reset,
            enable => enable,
            u_in => but_01_u_in,
            v_in => but_01_v_in,
            twiddle => but_01_tw_in,
            u_out => but_01_u_out,
            v_out => but_01_v_out
        );

    BUT_1 : BUTTERFLY_UNIT_1
        port map(
            clk => clk,
            mode => mode,
            reset => reset,
            enable => enable,
            u_in => but_1_u_in,
            v_in => but_1_v_in,
            twiddle => but_1_tw_in,
            u_out => but_1_u_out,
            v_out => but_1_v_out,
            u_v_debug => u_v_debug
        ); 

    BUT_2 : BUTTERFLY_UNIT_2
        port map(
            clk => clk,
            mode => mode,
            reset => reset,
            enable => enable,
            u_in => but_2_u_in,
            v_in => but_2_v_in,
            twiddle => but_2_tw_in,
            u_out => but_2_u_out,
            v_out => but_2_v_out
        ); 

    -- u_in <= 0 | 0 | a(2i+1) | a(2i)
    -- v_in <= 0 | 0 | b(2i+1) | b(2i)
    -- tw <= tw1 | tw1 | tw0 | tw0


    -- BUT_0_0
    but_00_u_in <= u_in(11 downto 0) when mode(1)='0' else but_1_v_out; -- u(0) or w*a(2i+1)*b(2i+1)
    but_00_v_in <= v_in(11 downto 0);                                    -- v(0) or b(2i)
    but_00_tw_in <= tw_0 when mode(1)='0' else u_in(11 downto 0);       -- tw(0) or a(2i)
    u_out(11 downto 0) <= but_00_u_out;
    v_out(11 downto 0) <= but_00_v_out;

    -- BUT_0_1
    but_01_u_in <= u_in(23 downto 12) when mode(1)='0' else but_2_v_out; -- u(1) or a(2i+1)*b(2i)
    but_01_v_in <= v_in(23 downto 12);                                    -- v(1) or b(2i+1)
    but_01_tw_in <= tw_0 when mode(1)='0' else u_in(11 downto 0);        -- tw(0) or a(2i)
    u_out(23 downto 12) <= but_01_u_out;
    v_out(23 downto 12) <= but_01_v_out;

    -- BUT_1
    but_1_u_in <= u_in(35 downto 24) when mode(1)='0' else u_in(23 downto 12); -- u(2) or a(2i+1)
    but_1_v_in <= v_in(35 downto 24) when mode(1)='0' else v_in(23 downto 12); -- v(2) or b(2i+1)
    but_1_tw_in <= tw_1;                                                      -- tw(1) or tw(1)
    u_out(35 downto 24) <= but_1_u_out;
    v_out(35 downto 24) <= but_1_v_out;

    -- BUT_2
    but_2_u_in <= u_in(47 downto 36) when mode(1)='0' else (others => '0');   -- u(3) or 0
    but_2_v_in <= v_in(47 downto 36) when mode(1)='0' else v_in(11 downto 0); -- v(3) or b(2i)
    but_2_tw_in <= tw_1 when mode(1)='0' else u_in(23 downto 12);             -- tw(1) or a(2i+1)
    u_out(47 downto 36) <= but_2_u_out;
    v_out(47 downto 36) <= but_2_v_out;


    -- -- debug outputs
    u0 <= but_00_u_out;
    u1 <= but_01_u_out;
    u2 <= but_1_u_out;
    u3 <= but_2_u_out;
    v0 <= but_00_v_out;
    v1 <= but_01_v_out;
    v2 <= but_1_v_out;
    v3 <= but_2_v_out;
    tw_0_out <= tw_0;
    tw_1_out <= tw_1;

end architecture ;