library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FIFO_BUFFER is
    generic (
        n : positive := 8;           -- Number of stages
        data_width : positive := 28   -- Width of data bus (4*wr_addr width)
    );
    port (
        clk     : in  std_logic;
        reset     : in  std_logic;
        enable  : in  std_logic;
        mode : in std_logic;
        data_in : in  std_logic_vector(data_width-1 downto 0);
        data_out   : out std_logic_vector(data_width-1 downto 0)
    );
end FIFO_BUFFER;

architecture rtl of FIFO_BUFFER is
    -- Type definition for the FIFO stages
    type fifo_array is array (0 to n-1) of std_logic_vector(data_width-1 downto 0);
    signal fifo_stages : fifo_array;

    signal out_n_1, out_n : std_logic_vector(data_width-1 downto 0);
    
begin
    -- FIFO shifting process
    shift_process: process(clk, reset)
    begin
        if reset = '1' then
            -- Reset all stages to zero
            for i in 0 to n-1 loop
                fifo_stages(i) <= (others => '0');
            end loop;
            
        elsif rising_edge(clk) then
            if enable = '1' then
                -- Shift data through the FIFO stages
                for i in n-1 downto 1 loop
                    fifo_stages(i) <= fifo_stages(i-1);
                end loop;
                
                -- Input new data
                fifo_stages(0) <= data_in;
            end if;
        end if;
    end process;
    
    -- Output assignments
    out_n   <= fifo_stages(n-1);     -- nth stage output
    out_n_1 <= fifo_stages(n-2);     -- (n-1)th stage output

    data_out <= out_n_1 when mode='0' else out_n;
    
    -- Assert to ensure n is at least 2 (needed for n-1 output)
    assert n >= 2 
        report "FIFO depth must be at least 2 stages for n and n-1 outputs"
        severity error;
        
end rtl;