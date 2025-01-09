library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

entity ADDR_MAP is
  port (
    clk : in std_logic;
    reset : in std_logic;
    addr_0 : in std_logic_vector(6 downto 0) ;
    addr_1 : in std_logic_vector(6 downto 0) ;
    addr_2 : in std_logic_vector(6 downto 0) ;
    addr_3 : in std_logic_vector(6 downto 0) ;
    bank_addr_0 : out std_logic_vector(4 downto 0) ;
    bank_addr_1 : out std_logic_vector(4 downto 0) ;
    bank_addr_2 : out std_logic_vector(4 downto 0) ;
    bank_addr_3 : out std_logic_vector(4 downto 0) 
  ) ;
end ADDR_MAP ; 

architecture Behavioral of ADDR_MAP is
    constant NUM_BANKS : integer := 4;

    type bank_array is array (0 to NUM_BANKS-1) of std_logic_vector(4 downto 0);
    type addr_array is array (0 to NUM_BANKS-1) of std_logic_vector(6 downto 0);

    signal bank_addr_array : bank_array;
    signal raw_addr_array : addr_array;

    
begin
    map_process : process(clk)
        variable slide_dist : std_logic_vector(1 downto 0);
        variable slide_val : unsigned(1 downto 0);
        variable BI :integer := 0; 
        variable BA : std_logic_vector(4 downto 0) := (others => '0');
    begin
        if reset = '1' then
            bank_addr_array <= (others => (others => '0'));
        elsif rising_edge(clk) then
            raw_addr_array <= (addr_0, addr_1, addr_2, addr_3);
            for bank in 0 to NUM_BANKS-1 loop
                slide_dist := (raw_addr_array(bank)(6) xor raw_addr_array(bank)(5) xor raw_addr_array(bank)(4) 
                            xor raw_addr_array(bank)(3) xor raw_addr_array(bank)(2)) & '0';
                slide_val := unsigned(slide_dist) + unsigned(raw_addr_array(bank)(1 downto 0));
                BI := to_integer(slide_val);
                BA := raw_addr_array(bank)(6 downto 2);

                bank_addr_array(BI) <= BA;
            end loop;
        end if;
    end process;

    bank_addr_0 <= bank_addr_array(0);
    bank_addr_1 <= bank_addr_array(1);
    bank_addr_2 <= bank_addr_array(2);
    bank_addr_3 <= bank_addr_array(3);

end architecture Behavioral;