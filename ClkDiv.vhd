library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.Types.all;
use ieee.std_logic_unsigned.all;
 
entity ClkDiv is
	generic (
		SourceFreq : positive;
		SinkFreq : positive
	);
   port (
        clk    : in  STD_LOGIC;
        reset  : in  STD_LOGIC;
        clk_out: out STD_LOGIC
    );
end;
 
architecture Behavioral of ClkDiv is
    signal temporal: STD_LOGIC;
	 constant Period : positive := SourceFreq / SinkFreq;
	 constant HalfPeriod : positive := Period / 2;
    signal counter : word(bits(HalfPeriod)-1 downto 0);
begin
    freq_divider: process (reset, clk) begin
        if (reset = '0') then
            temporal <= '0';
            counter  <= (others => '0');
        elsif rising_edge(clk) then
            if (counter = HalfPeriod-1) then
                temporal <= not temporal;
                counter  <= (others => '0');
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    clk_out <= temporal;
end Behavioral;