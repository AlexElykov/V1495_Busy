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

ENTITY BusyLogicComponent IS
   PORT( 
		LCLK:		IN		std_logic;	-- ADC clock
		BusyIN1 : IN		std_logic_vector(31 downto 0);
		BusyIN2 : IN		std_logic_vector(31 downto 0); -- not used
		BusyOUT : OUT	std_logic	
	);
	
END BusyLogicComponent ;


ARCHITECTURE rtl OF BusyLogicComponent IS

--***********************************************************************************
-- set minimum busy length here (after ":="), 1 = 25ns 									--**
signal BusyMin : integer range 0 to 2000000 := 40000;	 -- 10ms						--**
--***********************************************************************************

	-- local signals 
signal busyinput : std_logic := '0';
signal counter : integer range 0 to 120000000 := 0;
signal green_led : std_logic := '0';
constant ones : std_logic_vector(31 downto 0) := (others => '1');

	-- Component Declarations



BEGIN
	
   --*************************************************
   -- BUSY LOGIC
   --*************************************************	
	process (LCLK) begin
		if LCLK'event and LCLK = '1' then


			if BusyIN1 = ones then -- LVDS Busy is active low signal
				busyinput <= '0';
			else -- busy turns on 
				busyinput <= '1';
				if counter = 0 then
					counter <= 1;
				end if;
			end if;
	
			
			if busyinput = '1' OR (counter > 0 AND counter < BusyMin) then -- keep busy on at least for minimum busy time
				BusyOut <= '1';
				if counter > 0 then
					counter <= counter + 1;
				end if;
			else
				BusyOut <= '0';
				if counter > 0 then
					counter <= 0;
				end if;
			end if;
			
		end if;
	end process;
	
	

   
END rtl;

