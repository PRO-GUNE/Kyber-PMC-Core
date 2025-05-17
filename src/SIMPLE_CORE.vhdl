library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SIMPLE_CORE is
  port (
    clk      : in std_logic;
    mode_in  : in std_logic_vector(3 downto 0);
    reset    : in std_logic;
    rx_in    : in std_logic;
    busy     : out std_logic;
    tx_out   : out std_logic;
    tx_busy  : out std_logic;
    deb_addr : out std_logic_vector(6 downto 0)
  );
end SIMPLE_CORE;

architecture Behavioral of SIMPLE_CORE is

  -- Write addresses buffered
  signal wr_addr_buf_in, wr_addr_buf_out : std_logic_vector(19 downto 0) := (others => '0');

  -- Internal signals
  signal u_in_internal, v_in_internal   : std_logic_vector(47 downto 0) := (others => '0');
  signal u_out_internal, v_out_internal : std_logic_vector(47 downto 0) := (others => '0');
  signal tw_addr_0, tw_addr_1           : std_logic_vector(6 downto 0); -- set by controller
  signal enable_RAM, enable_BUT         : std_logic                    := '1';
  signal rd_en, wr_en                   : std_logic_vector(3 downto 0) := (others => '0');
  signal rd_en_1, wr_en_1               : std_logic_vector(3 downto 0) := (others => '0');
  signal rd_en_2, wr_en_2               : std_logic_vector(3 downto 0) := (others => '0');

  -- ADDR MAP signals
  signal addr_0, addr_1, addr_2, addr_3 : std_logic_vector(6 downto 0); -- set by controller
  signal mode : std_logic_vector(1 downto 0);
  signal uart_valid : std_logic := '0';
  signal ram_ready: std_logic := '0';

  -- RAM 0 read/write addresses
  signal rd_addr_0, rd_addr_1, rd_addr_2, rd_addr_3 : std_logic_vector(4 downto 0);
  signal rd_data_0, rd_data_1, rd_data_2, rd_data_3 : std_logic_vector(23 downto 0);
  signal wr_addr_0, wr_addr_1, wr_addr_2, wr_addr_3 : std_logic_vector(4 downto 0);
  signal wr_data_0, wr_data_1, wr_data_2, wr_data_3 : std_logic_vector(23 downto 0);
  type state_type is (IDLE, NTT0, NTT1, INTT0, PWM, MACC, WRITE0, WRITE1, WRITE2, READ0, READ1, READ2);
  signal current_state, next_state : state_type := IDLE;

  constant UART_SYN_TIME : integer := 96; -- UART sync time in clock cycles

  component BUFFERED_UART is
    port (
      clk        : in  std_logic;
      rst        : in  std_logic;
      rx         : in  std_logic; -- UART receive line
      tx         : out std_logic; -- UART transmit line
      ram_data0  : in  std_logic_vector(23 downto 0); -- Data from RAM (word 0)
      ram_data1  : in  std_logic_vector(23 downto 0); -- Data from RAM (word 1)
      ram_data2  : in  std_logic_vector(23 downto 0); -- Data from RAM (word 2)
      ram_data3  : in  std_logic_vector(23 downto 0); -- Data from RAM (word 3)
      ram_valid  : in  std_logic; -- Valid signal for RAM data
      ram_ready  : out std_logic; -- Ready signal for RAM
      uart_data0 : out std_logic_vector(23 downto 0); -- Data to RAM (word 0)
      uart_data1 : out std_logic_vector(23 downto 0); -- Data to RAM (word 1)
      uart_data2 : out std_logic_vector(23 downto 0); -- Data to RAM (word 2)
      uart_data3 : out std_logic_vector(23 downto 0); -- Data to RAM (word 3)
      uart_valid : out std_logic -- Valid signal for UART data
    );
  end component;

  -- 4x1 Butterfly Core
  component ASYM_BUT_CORE is
    port (
      clk       : in std_logic;
      mode      : in std_logic_vector(1 downto 0);
      reset     : in std_logic;
      enable    : in std_logic;
      u_in      : in std_logic_vector(47 downto 0); -- 4x 12-bit inputs
      v_in      : in std_logic_vector(47 downto 0); -- 4x 12-bit inputs
      tw_addr_0 : in std_logic_vector(6 downto 0); -- twiddle addr_0
      tw_addr_1 : in std_logic_vector(6 downto 0); -- twiddle addr_1
      u_out     : out std_logic_vector(47 downto 0); -- 4x 12-bit outputs
      v_out     : out std_logic_vector(47 downto 0) -- 4x 12-bit outputs
    );
  end component;

  -- Address mapping
  component ADDR_MAP is
    port (
      clk         : in std_logic;
      reset       : in std_logic;
      addr_0      : in std_logic_vector(6 downto 0);
      addr_1      : in std_logic_vector(6 downto 0);
      addr_2      : in std_logic_vector(6 downto 0);
      addr_3      : in std_logic_vector(6 downto 0);
      bank_addr_0 : out std_logic_vector(4 downto 0);
      bank_addr_1 : out std_logic_vector(4 downto 0);
      bank_addr_2 : out std_logic_vector(4 downto 0);
      bank_addr_3 : out std_logic_vector(4 downto 0)
    );
  end component;

  -- RAM
  component RAM
    port (
      clk    : in std_logic;
      rst    : in std_logic;
      enable : in std_logic;
      -- Write ports - independent for each bank
      wr_en     : in std_logic_vector(3 downto 0); -- Write enable for each bank
      wr_addr_0 : in std_logic_vector(4 downto 0); -- Write address for bank 0
      wr_addr_1 : in std_logic_vector(4 downto 0); -- Write address for bank 1
      wr_addr_2 : in std_logic_vector(4 downto 0); -- Write address for bank 2
      wr_addr_3 : in std_logic_vector(4 downto 0); -- Write address for bank 3
      wr_data_0 : in std_logic_vector(23 downto 0); -- Write data for bank 0
      wr_data_1 : in std_logic_vector(23 downto 0); -- Write data for bank 1
      wr_data_2 : in std_logic_vector(23 downto 0); -- Write data for bank 2
      wr_data_3 : in std_logic_vector(23 downto 0); -- Write data for bank 3

      -- Read ports - independent for each bank
      rd_en     : in std_logic_vector(3 downto 0); -- Read enable for each bank
      rd_addr_0 : in std_logic_vector(4 downto 0); -- Read address for bank 0
      rd_addr_1 : in std_logic_vector(4 downto 0); -- Read address for bank 1
      rd_addr_2 : in std_logic_vector(4 downto 0); -- Read address for bank 2
      rd_addr_3 : in std_logic_vector(4 downto 0); -- Read address for bank 3
      rd_data_0 : out std_logic_vector(23 downto 0); -- Read data from bank 0
      rd_data_1 : out std_logic_vector(23 downto 0); -- Read data from bank 1
      rd_data_2 : out std_logic_vector(23 downto 0); -- Read data from bank 2
      rd_data_3 : out std_logic_vector(23 downto 0) -- Read data from bank 3
    );
  end component;

  -- FIFO buffer for controlling write address signals
  component FIFO_BUFFER is
    generic (
      n          : positive := 8; -- Number of stages
      data_width : positive := 20 -- Width of data bus (4*wr_addr width)
    );
    port (
      clk      : in std_logic;
      reset    : in std_logic;
      enable   : in std_logic;
      mode     : in std_logic_vector(1 downto 0);
      data_in  : in std_logic_vector(data_width - 1 downto 0);
      data_out : out std_logic_vector(data_width - 1 downto 0)
    );
  end component;
begin

  -- Instantiate the buffered UART
  UART_0 : BUFFERED_UART
  port map
  (
    clk        => clk,
    rst        => reset,
    rx         => rx_in,
    tx         => tx_out,
    ram_data0  => rd_data_0,
    ram_data1  => rd_data_1,
    ram_data2  => rd_data_2,
    ram_data3  => rd_data_3,
    ram_valid  => '1',
    ram_ready  => ram_ready,
    uart_data0 => wr_data_0,
    uart_data1 => wr_data_1,
    uart_data2 => wr_data_2,
    uart_data3 => wr_data_3,
    uart_valid  => uart_valid
  );

  -- FIFO Buffer
  FIFO_0 : FIFO_BUFFER
  generic map(
    n          => 8,
    data_width => 20
  )
  port map
  (
    clk      => clk,
    reset    => reset,
    enable   => '1',
    mode     => mode,
    data_in  => wr_addr_buf_in,
    data_out => wr_addr_buf_out
  );
  -- 4x1 butterfly unit
  BUT_CORE : ASYM_BUT_CORE
  port map
  (
    clk       => clk,
    mode      => mode,
    reset     => reset,
    enable    => enable_BUT,
    u_in      => u_in_internal,
    v_in      => v_in_internal,
    tw_addr_0 => tw_addr_0,
    tw_addr_1 => tw_addr_1,
    u_out     => u_out_internal,
    v_out     => v_out_internal
  );

  -- Address mapping for read signals
  ADDR_MAP_0 : ADDR_MAP
  port map
  (
    clk         => clk,
    reset       => reset,
    addr_0      => addr_0,
    addr_1      => addr_1,
    addr_2      => addr_2,
    addr_3      => addr_3,
    bank_addr_0 => rd_addr_0,
    bank_addr_1 => rd_addr_1,
    bank_addr_2 => rd_addr_2,
    bank_addr_3 => rd_addr_3
  );

  -- RAM
  RAM_0 : RAM
  port map
  (
    clk       => clk,
    rst       => reset,
    enable    => enable_RAM,
    wr_en     => wr_en,
    wr_addr_0 => wr_addr_0,
    wr_addr_1 => wr_addr_1,
    wr_addr_2 => wr_addr_2,
    wr_addr_3 => wr_addr_3,
    wr_data_0 => wr_data_0,
    wr_data_1 => wr_data_1,
    wr_data_2 => wr_data_2,
    wr_data_3 => wr_data_3,
    rd_en     => rd_en,
    rd_addr_0 => rd_addr_0,
    rd_addr_1 => rd_addr_1,
    rd_addr_2 => rd_addr_2,
    rd_addr_3 => rd_addr_3,
    rd_data_0 => rd_data_0,
    rd_data_1 => rd_data_1,
    rd_data_2 => rd_data_2,
    rd_data_3 => rd_data_3
  );

  RAM_1 : RAM
  port map
  (
    clk       => clk,
    rst       => reset,
    enable    => enable_RAM,
    wr_en     => wr_en_1,
    wr_addr_0 => wr_addr_0,
    wr_addr_1 => wr_addr_1,
    wr_addr_2 => wr_addr_2,
    wr_addr_3 => wr_addr_3,
    wr_data_0 => wr_data_0,
    wr_data_1 => wr_data_1,
    wr_data_2 => wr_data_2,
    wr_data_3 => wr_data_3,
    rd_en     => rd_en_1,
    rd_addr_0 => rd_addr_0,
    rd_addr_1 => rd_addr_1,
    rd_addr_2 => rd_addr_2,
    rd_addr_3 => rd_addr_3,
    rd_data_0 => rd_data_0,
    rd_data_1 => rd_data_1,
    rd_data_2 => rd_data_2,
    rd_data_3 => rd_data_3
  );

  RAM_2 : RAM
  port map
  (
    clk       => clk,
    rst       => reset,
    enable    => enable_RAM,
    wr_en     => wr_en_2,
    wr_addr_0 => wr_addr_0,
    wr_addr_1 => wr_addr_1,
    wr_addr_2 => wr_addr_2,
    wr_addr_3 => wr_addr_3,
    wr_data_0 => wr_data_0,
    wr_data_1 => wr_data_1,
    wr_data_2 => wr_data_2,
    wr_data_3 => wr_data_3,
    rd_en     => rd_en_2,
    rd_addr_0 => rd_addr_0,
    rd_addr_1 => rd_addr_1,
    rd_addr_2 => rd_addr_2,
    rd_addr_3 => rd_addr_3,
    rd_data_0 => rd_data_0,
    rd_data_1 => rd_data_1,
    rd_data_2 => rd_data_2,
    rd_data_3 => rd_data_3
  );

  process (clk)
    variable k : integer := 0;
    variable l : integer := 64; -- Assuming n = 128, so n/2 = 64
    variable s : integer := 0;
    variable j : integer := 0;
  begin
    if rising_edge(clk) then
      current_state <= next_state;

      if reset = '1' then
        -- Set current state of the core
        current_state <= IDLE;
      else
        case current_state is
          when IDLE =>
            case mode_in is
              when "0000" => next_state <= NTT0; -- NTT0
              when "0001" => next_state <= NTT1; -- NTT1
              when "0010" => next_state <= INTT0; -- WRITE
              when "0010" => next_state <= PWM; -- PWM
              when "0011" => next_state <= MACC; -- MACC
              when "0100" => next_state <= WRITE0; -- WRITE0
              when "0101" => next_state <= WRITE1; -- WRITE1
              when "0110" => next_state <= WRITE2; -- WRITE3
              when "0111" => next_state <= READ0; -- READ0
              when "1000" => next_state <= READ1; -- READ1
              when "1001" => next_state <= READ2; -- READ2
              when others => next_state <= IDLE;
            end case;

            -- -- Reset all signals
            k := 0;
            l := 64;
            s := 0;
            j := 0;
            -- Reset addresses to zero
            addr_0 <= (others => '0');
            addr_1 <= (others => '0');
            addr_2 <= (others => '0');
            addr_3 <= (others => '0');

            wr_en <= "0000"; -- Disable all write ports
            rd_en <= "0000"; -- Disable all read ports

            wr_en_1 <= "0000"; -- Disable all write ports
            rd_en_1 <= "0000"; -- Disable all read ports

            wr_en_2 <= "0000"; -- Disable all write ports
            rd_en_2 <= "0000"; -- Disable all read ports

            mode <= "00"; -- NTT mode
            ram_ready <= '0';
            uart_valid <= '0';

          when NTT0 =>
            wr_en <= "1111"; -- Enable all write ports
            rd_en <= "1111"; -- Disable all read ports
            mode <= "00"; -- NTT mode
            if l > 0 then
              if s < 128 then
                if l >= 4 then
                  k := k + 1;
                  tw_addr_0 <= std_logic_vector(to_unsigned(k, 7));
                  tw_addr_1 <= std_logic_vector(to_unsigned(k, 7));

                  if j < (s + l) then
                    addr_0 <= std_logic_vector(to_unsigned(j, 7));
                    addr_1 <= std_logic_vector(to_unsigned(j + 1, 7));
                    addr_2 <= std_logic_vector(to_unsigned(j + l, 7));
                    addr_3 <= std_logic_vector(to_unsigned(j + l + 1, 7));
                    j := j + 4;
                  else
                    j := s;
                    s := s + 2 * l;
                  end if;

                elsif l = 2 then
                  k := k + 1;
                  tw_addr_0 <= std_logic_vector(to_unsigned(k, 7));
                  k := k + 1;
                  tw_addr_1 <= std_logic_vector(to_unsigned(k, 7));

                  addr_0 <= std_logic_vector(to_unsigned(s, 7));
                  addr_1 <= std_logic_vector(to_unsigned(s + 2, 7));
                  addr_2 <= std_logic_vector(to_unsigned(s + 1, 7));
                  addr_3 <= std_logic_vector(to_unsigned(s + 3, 7));

                  s := s + 2 * l;
                end if;
              else
                -- Move to next stage
                s := 0;
                l := l / 2;
              end if;
            else
              next_state <= IDLE;
            end if;

          when NTT1 =>
            wr_en_1 <= "1111"; -- Enable all write ports
            rd_en_1 <= "1111"; -- Disable all read ports
            mode <= "00"; -- NTT mode
            if l > 0 then
              if s < 128 then
                if l >= 4 then
                  k := k + 1;
                  tw_addr_0 <= std_logic_vector(to_unsigned(k, 7));
                  tw_addr_1 <= std_logic_vector(to_unsigned(k, 7));

                  if j < (s + l) then
                    addr_0 <= std_logic_vector(to_unsigned(j, 7));
                    addr_1 <= std_logic_vector(to_unsigned(j + 1, 7));
                    addr_2 <= std_logic_vector(to_unsigned(j + l, 7));
                    addr_3 <= std_logic_vector(to_unsigned(j + l + 1, 7));
                    j := j + 4;
                  else
                    j := s;
                    s := s + 2 * l;
                  end if;

                elsif l = 2 then
                  k := k + 1;
                  tw_addr_0 <= std_logic_vector(to_unsigned(k, 7));
                  k := k + 1;
                  tw_addr_1 <= std_logic_vector(to_unsigned(k, 7));

                  addr_0 <= std_logic_vector(to_unsigned(s, 7));
                  addr_1 <= std_logic_vector(to_unsigned(s + 2, 7));
                  addr_2 <= std_logic_vector(to_unsigned(s + 1, 7));
                  addr_3 <= std_logic_vector(to_unsigned(s + 3, 7));

                  s := s + 2 * l;
                end if;
              else
                -- Move to next stage
                s := 0;
                l := l / 2;
              end if;
            else
              next_state <= IDLE;
            end if;

          when PWM =>
            
            if s < 128 then
              wr_en   <= "0011";
              rd_en   <= "0011";
              rd_en_1 <= "1100";
              mode <= "10"; -- PWM mode
              tw_addr_0 <= (others => '0');
              tw_addr_1 <= (others => '0');

              addr_0 <= std_logic_vector(to_unsigned(2 * s, 7));
              addr_1 <= std_logic_vector(to_unsigned(2 * s + 1, 7));
              addr_2 <= std_logic_vector(to_unsigned(2 * s, 7));
              addr_3 <= std_logic_vector(to_unsigned(2 * s + 1, 7));

              s := s + 1;
            else
              next_state <= IDLE;
            end if;
          
          when MACC =>
          if s < 128 then
            rd_en <= "0011"; -- Enable read ports from RAM0
            rd_en_2 <= "1100"; -- Enable read ports from RAM2
            wr_en_2 <= "1111"; -- Disable write ports
            mode <= "00";
            tw_addr_0 <= (others => '0');
            tw_addr_1 <= (others => '0');

            addr_0 <= std_logic_vector(to_unsigned(2 * s, 7));
            addr_1 <= std_logic_vector(to_unsigned(2 * s + 1, 7));
            addr_2 <= std_logic_vector(to_unsigned(2 * s, 7));
            addr_3 <= std_logic_vector(to_unsigned(2 * s + 1, 7));
          end if;


          when INTT0 =>
            wr_en <= "1111"; -- Enable all write ports
            rd_en <= "1111"; -- Disable all read ports
            mode <= "01"; -- INTT mode
            if l > 0 then
              if s < 128 then
                if l >= 4 then
                  k := k + 1;
                  tw_addr_0 <= std_logic_vector(to_unsigned(k, 7));
                  tw_addr_1 <= std_logic_vector(to_unsigned(k, 7));

                  if j < (s + l) then
                    addr_0 <= std_logic_vector(to_unsigned(j, 7));
                    addr_1 <= std_logic_vector(to_unsigned(j + 1, 7));
                    addr_2 <= std_logic_vector(to_unsigned(j + l, 7));
                    addr_3 <= std_logic_vector(to_unsigned(j + l + 1, 7));
                    j := j + 4;
                  else
                    j := s;
                    s := s + 2 * l;
                  end if;

                elsif l = 2 then
                  k := k + 1;
                  tw_addr_0 <= std_logic_vector(to_unsigned(k, 7));
                  k := k + 1;
                  tw_addr_1 <= std_logic_vector(to_unsigned(k, 7));

                  addr_0 <= std_logic_vector(to_unsigned(s, 7));
                  addr_1 <= std_logic_vector(to_unsigned(s + 2, 7));
                  addr_2 <= std_logic_vector(to_unsigned(s + 1, 7));
                  addr_3 <= std_logic_vector(to_unsigned(s + 3, 7));

                  s := s + 2 * l;
                end if;
              else
                -- Move to next stage
                s := 0;
                l := l / 2;
              end if;

            else
              next_state <= IDLE;
            end if;

          when WRITE0 =>
            if l >= 0 then
              if l >= UART_SYN_TIME and uart_valid='1' then
                wr_en  <= "1111"; -- Enable all write ports
                addr_0 <= std_logic_vector(to_unsigned(j, 7));
                addr_1 <= std_logic_vector(to_unsigned(j + 32, 7));
                addr_2 <= std_logic_vector(to_unsigned(j + 64, 7));
                addr_3 <= std_logic_vector(to_unsigned(j + 96, 7));
                j := j + 1;
                l := 0;
                if j >= 32 then
                  next_state <= IDLE;
                end if;
              end if;

              l := l + 1;
            end if;

          when READ0 =>
            if l >= 0 then
              if l <= UART_SYN_TIME then
                rd_en  <= "1111"; -- Enable all read ports
                addr_0 <= std_logic_vector(to_unsigned(j, 7));
                addr_1 <= std_logic_vector(to_unsigned(j + 32, 7));
                addr_2 <= std_logic_vector(to_unsigned(j + 64, 7));
                addr_3 <= std_logic_vector(to_unsigned(j + 96, 7));
                ram_ready <= '0';
              else
                j := j + 1;
                l := 0;
                ram_ready <= '1';
                if j >= 32 then
                  next_state <= IDLE;
                end if;
              end if;

              l := l + 1;
            end if;

          when WRITE1 =>
            if l >= 0 then
              if l >= UART_SYN_TIME and uart_valid='1' then
                wr_en_1 <= "1111"; -- Enable all write ports
                addr_0  <= std_logic_vector(to_unsigned(j, 7));
                addr_1  <= std_logic_vector(to_unsigned(j + 32, 7));
                addr_2  <= std_logic_vector(to_unsigned(j + 64, 7));
                addr_3  <= std_logic_vector(to_unsigned(j + 96, 7));
                j := j + 1;
                l := 0;
                if j >= 32 then
                  next_state <= IDLE;
                end if;
              end if;

              l := l + 1;
            end if;

          when READ1 =>
            if l >= 0 then
              if l <= UART_SYN_TIME then
                rd_en_1 <= "1111"; -- Enable all read ports
                addr_0  <= std_logic_vector(to_unsigned(j, 7));
                addr_1  <= std_logic_vector(to_unsigned(j + 32, 7));
                addr_2  <= std_logic_vector(to_unsigned(j + 64, 7));
                addr_3  <= std_logic_vector(to_unsigned(j + 96, 7));
                ram_ready <= '0';
              else
                j := j + 1;
                l := 0;
                ram_ready <= '1';
                if j >= 32 then
                  next_state <= IDLE;
                end if;
              end if;

              l := l + 1;
            end if;

          when WRITE2 =>
            if l >= 0 then
              if l >= UART_SYN_TIME and uart_valid='1' then
                wr_en_2 <= "1111"; -- Enable all write ports
                addr_0  <= std_logic_vector(to_unsigned(j, 7));
                addr_1  <= std_logic_vector(to_unsigned(j + 32, 7));
                addr_2  <= std_logic_vector(to_unsigned(j + 64, 7));
                addr_3  <= std_logic_vector(to_unsigned(j + 96, 7));
                j := j + 1;
                l := 0;
                if j >= 32 then
                  next_state <= IDLE;
                end if;
              end if;

              l := l + 1;
            end if;

          when READ2 =>
            if l >= 0 then
              if l <= UART_SYN_TIME then
                rd_en_2 <= "1111"; -- Enable all read ports
                addr_0  <= std_logic_vector(to_unsigned(j, 7));
                addr_1  <= std_logic_vector(to_unsigned(j + 32, 7));
                addr_2  <= std_logic_vector(to_unsigned(j + 64, 7));
                addr_3  <= std_logic_vector(to_unsigned(j + 96, 7));
                ram_ready <= '0';
              else
                j := j + 1;
                l := 0;
                ram_ready <= '1';
                if j >= 32 then
                  next_state <= IDLE;
                end if;
              end if;

              l := l + 1;
            end if;

          when others =>
            next_state <= IDLE;

        end case;
      end if;
    end if;
  end process;

  u_in_internal <= rd_data_1 & rd_data_0;
  v_in_internal <= rd_data_3 & rd_data_2;

  wr_addr_buf_in <= rd_addr_3 & rd_addr_2 & rd_addr_1 & rd_addr_0;

  wr_data_0 <= u_out_internal(23 downto 0);
  wr_data_1 <= u_out_internal(47 downto 24);
  wr_data_2 <= v_out_internal(23 downto 0);
  wr_data_3 <= v_out_internal(47 downto 24);

  wr_addr_0 <= wr_addr_buf_out(4 downto 0);
  wr_addr_1 <= wr_addr_buf_out(9 downto 5);
  wr_addr_2 <= wr_addr_buf_out(14 downto 10);
  wr_addr_3 <= wr_addr_buf_out(19 downto 15);

  deb_addr <= addr_2;

end architecture; -- Behavioral