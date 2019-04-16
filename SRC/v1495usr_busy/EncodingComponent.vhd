-- ****************************************************************************
-- Author:			Lukas Buetikofer
-- Date:				16.7.2016
-- Module:			EncodingComponent
-- Description:	Takes a logic input signal and returns 
--						one pulse (10ns) at falling edge and two pulses (10 ns each)
--						 at rising edge.
-- ----------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_misc.all;  -- Use OR_REDUCE function
USE work.v1495pkg.all;

ENTITY EncodingComponent IS
   PORT( 
		LCLK:			IN		std_logic;	-- ADC clock
		SignalIN:	IN		std_logic;
		SignalOUTstart:	OUT	std_logic;
		SignalOUTstop:	OUT	std_logic;
		SignalOUT:	OUT	std_logic
	);
END EncodingComponent ;


ARCHITECTURE rtl OF EncodingComponent IS

	-- local signals 
	signal counter : integer range 0 to 5 := 0;
	signal output : std_logic := '0';
	signal SignalON : std_logic := '0';
	signal SignalD1 : std_logic;
	signal SignalD2 : std_logic;
	
	
	BEGIN
	
   --************************************************* 
   -- ENCODING LOGIC
   --*************************************************	
	process (LCLK) begin
		if LCLK'event and LCLK = '1' then

			SignalD1 <= SignalIN;
			SignalD2 <= SignalD1;


-- this new logic seems to work. most of the time the output is 50 ns long (sometimes only 25 ns)
			SignalOUTstart<= (not SignalD2) and SignalIN; -- rising edge
			SignalOUTstop<= (not SignalIN) and SignalD2; -- falling edge
		
		end if;
	end process;
	
	SignalOUT <= output; -- dummy output (was uesd for encoding on one channel)

	END rtl;

