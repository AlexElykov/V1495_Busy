-- ****************************************************************************
-- Author:			Lukas Buetikofer
-- Date:				21.4.2015
-- Module:			EncodingComponent
-- Description:	Creates returns a logic signal as long as one of the
--						ADC boards is busy i.e. a channel from A(0-31) is active.
-- ----------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_misc.all;  -- Use OR_REDUCE function

USE work.v1495pkg.all;

ENTITY TestComponent IS
   PORT( 
		LCLK:		IN		std_logic;	-- ADC clock
		TestIN : IN		std_logic; -- not used
		TestOUT : OUT	std_logic	
	);
	
END TestComponent ;


ARCHITECTURE rtl OF TestComponent IS

--***********************************************************************************
-- set minimum busy length here (after ":="), 1 = 25ns 									--**
signal BusyMin : integer range 0 to 2000000 := 20;	 -- 1ms							--**
--***********************************************************************************

	-- local signals 
signal busyinput : std_logic := '0';
signal counter : integer range 0 to 1000000 := 0;
signal green_led : std_logic := '0';


	-- Component Declarations



BEGIN
	
   --*************************************************
   -- BUSY LOGIC
   --*************************************************	
	process (LCLK) begin
		if LCLK'event and LCLK = '1' then



			if TestIN = '0' then -- LVDS Busy is active low signal
				busyinput <= '0';
			else -- busy turns on 
				busyinput <= '1';
				if counter = 0 then
					counter <= 1;
				end if;
			end if;
	
			
			if busyinput = '1' OR (counter > 0 AND counter < BusyMin) then -- keep busy on at least for minimum busy time
				TestOut <= '1';
				counter <= counter + 1;
			else
				TestOut <= '0';
				counter <= 0;
			end if;

			

		end if;
	end process;
	
	

   
END rtl;

