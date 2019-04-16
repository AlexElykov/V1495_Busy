-- ****************************************************************************
-- Author:			Lukas Buetikofer
-- Date:				21.4.2015
-- Module:			EncodingComponent
-- Description:	This module checks if there are any pulses arriving at input G_1 (DAQ is running in LED mode)
--						and puts a logic signal to '1' if YES and to '0' if NO. 
-- ----------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_misc.all;  -- Use OR_REDUCE function

USE work.v1495pkg.all;

ENTITY LEDstatus IS
   PORT( 
		LCLK:			IN		std_logic;	-- ADC clock
		PulserIN:	IN		std_logic;
		LEDmode:	OUT	std_logic
	);
	
END LEDstatus ;


ARCHITECTURE rtl OF LEDstatus IS

-- local signals 
signal counter : std_logic_vector(31 downto 0) := (others => '0');


BEGIN
	
   --*************************************************
   -- CHECK IF RUNNING IN LED MODE
   --*************************************************	
	process (LCLK) begin
		if LCLK'event and LCLK = '1' then

			if PulserIN = '1' then
				counter <= (others => '0');
			elsif counter < 200000000 then
				counter <= counter + 1;
			end if;
			
			-- if there was no LED pulse during the last five seconds
			-- LED mode goes to '0'
			-- if there was a LED pulse during the last two seconds
			-- it is assumed the DAQ is running in LED mode => LEDmode='1'
			if counter = 200000000 then
				LEDmode <= '0';
			else 
				LEDmode <= '1';
			end if;
				
		end if;
	end process;
	
	

   
END rtl;

