library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BUTTERFLY_CORE is
    port (
        clk      : in std_logic;
        mode     : in std_logic;
        reset    : in std_logic;
        enable   : in std_logic;
        u_in     : in std_logic_vector(47 downto 0); -- 4x 12-bit inputs
        v_in     : in std_logic_vector(47 downto 0); -- 4x 12-bit inputs
        tw_addr_0 : in std_logic_vector(6 downto 0); -- twiddle addr_0
        tw_addr_1 : in std_logic_vector(6 downto 0); -- twiddle addr_1
        u_out    : out std_logic_vector(47 downto 0); -- 4x 12-bit outputs
        v_out    : out std_logic_vector(47 downto 0); -- 4x 12-bit outputs

        -- debug outputs
        debug_out : out std_logic_vector(47 downto 0); -- Debug outputs for each butterfly
        u0        : out std_logic_vector(11 downto 0);
        u1        : out std_logic_vector(11 downto 0);
        u2        : out std_logic_vector(11 downto 0);
        u3        : out std_logic_vector(11 downto 0);
        v0        : out std_logic_vector(11 downto 0);
        v1        : out std_logic_vector(11 downto 0);
        v2        : out std_logic_vector(11 downto 0);
        v3        : out std_logic_vector(11 downto 0)
    );
end entity BUTTERFLY_CORE;

architecture Behavioral of BUTTERFLY_CORE is
    -- Signals for individual BUTTERFLY_UNIT components
    signal u_out_internal : std_logic_vector(47 downto 0);
    signal v_out_internal : std_logic_vector(47 downto 0);
    signal twiddle_internal : std_logic_vector(47 downto 0);
    signal debug_internal : std_logic_vector(47 downto 0);

    signal tw_0, tw_1 : std_logic_vector(11 downto 0);

    -- Component declaration
    component BUTTERFLY_UNIT is
        port (
            clk      : in std_logic;
            mode     : in std_logic;
            reset    : in std_logic;
            enable   : in std_logic;
            u_in     : in std_logic_vector(11 downto 0);
            v_in     : in std_logic_vector(11 downto 0);
            twiddle  : in std_logic_vector(11 downto 0);
            u_out    : out std_logic_vector(11 downto 0);
            v_out    : out std_logic_vector(11 downto 0);
            u_v_debug: out std_logic_vector(11 downto 0)
        );
    end component;

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

    -- Instantiate 4 BUTTERFLY_UNITs
    GEN_BUTTERFLY: for i in 0 to 3 generate
        BUTTERFLY_INST : BUTTERFLY_UNIT
            port map (
                clk      => clk,
                mode     => mode,
                reset    => reset,
                enable   => enable,
                u_in     => u_in((i+1)*12-1 downto i*12), -- Select 12-bit slice for u_in
                v_in     => v_in((i+1)*12-1 downto i*12), -- Select 12-bit slice for v_in
                twiddle  => twiddle_internal((i+1)*12-1 downto i*12), -- Select 12-bit slice for twiddle
                u_out    => u_out_internal((i+1)*12-1 downto i*12), -- Collect 12-bit output for u_out
                v_out    => v_out_internal((i+1)*12-1 downto i*12), -- Collect 12-bit output for v_out
                u_v_debug => debug_internal((i+1)*12-1 downto i*12) -- Collect debug outputs
            );
    end generate;

    -- Assign outputs
    u_out <= u_out_internal;
    v_out <= v_out_internal;
    debug_out <= debug_internal;
    twiddle_internal <= tw_1 & tw_1 & tw_0 & tw_0;

    -- -- debug outputs
    u0 <= u_out_internal(11 downto 0);
    u1 <= u_out_internal(23 downto 12);
    u2 <= u_out_internal(35 downto 24);
    u3 <= u_out_internal(47 downto 36);
    v0 <= v_out_internal(11 downto 0);
    v1 <= v_out_internal(23 downto 12);
    v2 <= v_out_internal(35 downto 24);
    v3 <= v_out_internal(47 downto 36);

end Behavioral;
