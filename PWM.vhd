library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity PWM is 
	generic (
		Displays : positive := 8
	);
	port (
	RstN : in bit1;
	Clk  : in bit1;
	--
	Button0 : in bit1;
	Button1 : in bit1;
	--
   Display : out word(Displays-1 downto 0);
   Segments : out word(8-1 downto 0);
	--
	ServoPitch : out bit1;
	ServoYaw   : out bit1
	);
end entity;

architecture rtl of PWM is
	signal Btn0Deb : bit1;
	signal Btn1Deb : bit1;
	constant Freq : positive := 50000000;
	
	constant PwmRes : positive   := 128;
	constant PwmResW : positive  := bits(PwmRes);
	constant MaxPitch : positive := 40;
	
	signal Pos_N, Pos_D : word(PwmResW-1 downto 0);
	signal Data : word(27-1 downto 0);
	
	signal Button0_N, Button0_D : bit1;
	signal Button1_N, Button1_D : bit1;
	signal Clk64kHz : bit1;
	
	signal Clk1Hz : bit1;
	signal OldClk1Hz_D, OldClk1Hz_N : bit1;
	signal Rising_N, Rising_D : bit1;
	
begin
	Btn0Debouncer : entity work.Debounce
	port map (
		Clk => Clk,
		x   => Button0,
		DBx => Btn0Deb
	);

	Btn1Debouncer : entity work.Debounce
	port map (
		Clk => Clk,
		x   => Button1,
		DBx => Btn1Deb
	);
	
	process (Clk, RstN)
	begin
		if RstN = '0' then
			Pos_D <= (others => '0');
			Button0_D <= '0';
			Button1_D <= '0';
			OldClk1Hz_D <= '0';
			Rising_D <= '1';
		elsif rising_edge(Clk) then
			Pos_D <= Pos_N;
			Button0_D <= Button0_N;
			Button1_D <= Button1_N;
			OldClk1Hz_D <= OldClk1Hz_N;
			Rising_D <= Rising_N;
		end if;
	end process;
	
	Button0_N <= Btn0Deb;
	Button1_N <= Btn1Deb;
	
	OldClk1Hz_N <= Clk1Hz;
	process (Clk1Hz, Pos_D, OldClk1Hz_D)
	begin
		Pos_N    <= Pos_D;
		Rising_N <= Rising_D;
		
		if Pos_D = MaxPitch then
			Rising_N <= '0';
			Pos_N <= Pos_D - 1;
		elsif Pos_D = 0 then
			Rising_N <= '1';
			Pos_N <= Pos_D + 1;
		elsif (Clk1Hz = '1' and OldClk1Hz_D = '0') then
			if Rising_D = '1' then
				Pos_N <= Pos_D + 1;
				--Pos_N <= conv_word(MaxPitch, Pos_N'length);
			else
				Pos_N <= Pos_D - 1;
				--Pos_N <= (others => '0');
			end if;
		end if;
	end process;
	
	Clk1HzGen : entity work.ClkDiv
	generic map (
		SourceFreq => Freq,
		SinkFreq => 1
	)
	port map (
		clk     => Clk,
		Reset   => RstN,
		Clk_out => Clk1Hz
	);
	
	Data <= xt0(Pos_D, Data'length);
	BcdDispay : entity work.BcdDisp
	generic map (
		Displays => 8,
		Freq     => Freq
	)
	port map (
		Clk => Clk,
		RstN => RstN,
		Data => Data,
		--
		Segments => Segments,
		Display => Display
	);

	Clk64kHzGen : entity work.ClkDiv
	generic map (
		SourceFreq => Freq,
		SinkFreq   => 32000
	)
	port map (
		clk     => Clk,
		Reset   => RstN,
		Clk_out => Clk64kHz
	);
	
	PitchServo : entity work.Servo_pwm
	port map (
		Clk   => Clk64kHz,
		Reset => RstN,
		Pos   => Pos_D,
		servo => ServoPitch
	);
	
	YawServo : entity work.Servo_pwm
	port map (
		Clk   => Clk64kHz,
		Reset => RstN,
		Pos   => Pos_D,
		servo => ServoYaw
	);
	
end architecture rtl;