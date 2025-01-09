library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FSM_NTT_INTT_PWM is
    port (
        clk       : in  std_logic;  -- Clock signal
        reset     : in  std_logic;  -- Reset signal
        start     : in  std_logic;  -- Start signal
        input_sel : in  std_logic_vector(1 downto 0); -- Input selection (00: NTT, 01: INTT, 10: PWM)
        done      : out std_logic;  -- Done signal
        state_out : out std_logic_vector(1 downto 0)  -- Current state for debugging
    );
end FSM_NTT_INTT_PWM;

architecture Behavioral of FSM_NTT_INTT_PWM is
    -- Define states
    type state_type is (IDLE, NTT, INTT, PWM);
    signal current_state, next_state : state_type;

begin
    -- Sequential process for state transitions
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= IDLE; -- Default state after reset
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- Combinational process for next state logic
    process(current_state, start, input_sel)
    begin
        -- Default outputs
        next_state <= current_state;
        done <= '0';

        case current_state is
            when IDLE =>
                if start = '1' then
                    case input_sel is
                        when "00" => next_state <= NTT;
                        when "01" => next_state <= INTT;
                        when "10" => next_state <= PWM;
                        when others => next_state <= IDLE; -- Invalid input, stay in IDLE
                    end case;
                end if;

            when NTT =>
                done <= '1'; -- Indicate completion
                next_state <= IDLE; -- Return to IDLE

            when INTT =>
                done <= '1'; -- Indicate completion
                next_state <= IDLE; -- Return to IDLE

            when PWM =>
                done <= '1'; -- Indicate completion
                next_state <= IDLE; -- Return to IDLE

            when others =>
                next_state <= IDLE; -- Default state

        end case;
    end process;

    -- Output the current state for debugging
    state_out <= std_logic_vector(to_unsigned(state_type'pos(current_state), 2));

end Behavioral;
