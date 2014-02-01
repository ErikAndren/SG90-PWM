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
	PWM : out bit1
	);
end entity;

architecture rtl of PWM is
	signal Btn0Deb : bit1;
	signal Btn1Deb : bit1;
	
	constant PwmRes : positive := 128;
	constant PwmResW : positive := bits(PwmRes);
	
	signal Pos_N, Pos_D : word(PwmResW-1 downto 0);
	signal Data : word(27-1 downto 0);
	
	signal Button0_N, Button0_D : bit1;
	signal BUtton1_N, Button1_D : bit1;
	signal Clk64kHz : bit1;
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
		elsif rising_edge(Clk) then
			Pos_D <= Pos_N;
			Button0_D <= Button0_N;
			Button1_D <= Button1_N;
		end if;
	end process;
	
	Button0_N <= Btn0Deb;
	Button1_N <= Btn1Deb;

	Pos_N <= Pos_D + 1 when Btn0Deb = '0' and Pos_D <= 127 and Button0_D = '1' else
				Pos_D - 1 when Btn1Deb = '0' and Pos_D >= 0 and Button1_D = '1' else Pos_D;
	
	Data <= xt0(Pos_D, Data'length);
	BcdDispay : entity work.BcdDisp
	generic map (
		Displays => 8,
		Freq     => 50000000
	)
	port map (
		Clk => Clk,
		RstN => RstN,
		Data => Data,
		--
		Segments => Segments,
		Display => Display
	);

	Clk64kHzGen : entity work.Clk64kHz
	port map (
		clk     => Clk,
		Reset   => RstN,
		Clk_out => Clk64kHz
	);
	
	PwmServo : entity work.Servo_pwm
	port map (
		Clk   => Clk64kHz,
		Reset => RstN,
		Pos   => Pos_D,
		servo => PWM
	);
	
end architecture rtl;