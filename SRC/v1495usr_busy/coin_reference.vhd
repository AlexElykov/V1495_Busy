-- ****************************************************************************
-- Company:         CAEN SpA - Viareggio - Italy
-- Model:           V1495 -  Multipurpose Programmable Trigger Unit
-- FPGA Proj. Name: V1495USR_DEMO
-- Device:          ALTERA EP1C4F400C6
-- Author:          Luca Colombini (l.colombini@caen.it)
-- Date:            02-03-2006
-- ----------------------------------------------------------------------------
-- Module:          BUSY_LOGIC
-- Description:     Reference design to use the V1495 board 
--                  as a Coincidence Unit & I/O Register. 
--                  A gate pulse is generated on G port when a data 
--                  patterns on input ports A and B satisfy a trigger condition.
--                  The trigger condition implemented in this reference design
--                  is true when a bit-per-bit logic operation on port A and B 
--                  is true. The logic operator applied to Port A and B is
--                  selectable by means of a register bit (MODE Register Bit 4).
--                  If MODE bit 4 is set to '0', an AND logic operation is applied
--                  to corresponding bits in Port A and B.
--                  (i.e. A(0) AND B(0), A(1) AND B(1) etc.). 
--                  In this case, a trigger is generated if corresponding A and B
--                  port bits are '1' at the same time.
--                  If MODE bit 4 is set to '1', an OR logic operation is applied
--                  to corresponding bits in Port A and B.
--                  (i.e. A(0) OR B(0), A(1) OR B(1) etc.)
--                  In this case, a trigger is generated if there is a '1' on one
--                  bit of either port A or B.
--                  Port A and B bits can be singularly masked through a register,
--                  so that a '1' on that bit doesn't generate any trigger.
--                  Expansion mezzanine cards can be directly controlled through
--                  registers already implemented in this design.
--                  The expansion mezzanine is identified by a unique 
--                  identification code that can be read through a register.
-- ****************************************************************************

-- ############################################################################
-- Revision History:
--   Date         Author          Revision             Comments
--   02 Mar 06    LC              1.0                  Creation
-- ############################################################################

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_misc.all;  -- Use OR_REDUCE function

USE work.v1495pkg.all;

ENTITY busy_logic IS
   PORT( 
      nLBRES      : IN     std_logic;                       -- Async Reset (active low)
      LCLK        : IN     std_logic;                       -- Local Bus Clock
      --*************************************************
      -- REGISTER INTERFACE
      --*************************************************
      REG_WREN    : IN     std_logic;                       -- Write pulse (active high)
      REG_RDEN    : IN     std_logic;                       -- Read  pulse (active high)
      REG_ADDR    : IN     std_logic_vector (15 DOWNTO 0);  -- Register address
      REG_DIN     : IN     std_logic_vector (15 DOWNTO 0);  -- Data from CAEN Local Bus
      REG_DOUT    : OUT    std_logic_vector (15 DOWNTO 0);  -- Data to   CAEN Local Bus
      USR_ACCESS  : IN     std_logic;                       -- Current register access is 
                                                            -- at user address space(Active high)
      --*************************************************
      -- V1495 Front Panel Ports (PORT A,B,C,G)
      --*************************************************
      A_DIN       : IN     std_logic_vector (31 DOWNTO 0);  -- In A (32 x LVDS/ECL)
      B_DIN       : IN     std_logic_vector (31 DOWNTO 0);  -- In B (32 x LVDS/ECL) 
      C_DOUT      : OUT    std_logic_vector (31 DOWNTO 0);  -- Out C (32 x LVDS)
      G_LEV       : OUT    std_logic;                       -- Output Level Select (NIM/TTL)
      G_DIR       : OUT    std_logic;                       -- Output Enable
      G_DOUT      : OUT    std_logic_vector (1 DOWNTO 0);   -- Out G - LEMO (2 x NIM/TTL)
      G_DIN       : IN     std_logic_vector (1 DOWNTO 0);   -- In G - LEMO (2 x NIM/TTL)
      --*************************************************
      -- A395x MEZZANINES INTERFACES (PORT D,E,F)
      --*************************************************
      -- Expansion Mezzanine Identifier:
      -- x_IDCODE :
      -- 000 : A395A (32 x IN LVDS/ECL)
      -- 001 : A395B (32 x OUT LVDS)
      -- 010 : A395C (32 x OUT ECL)
      -- 011 : A395D (8  x IN/OUT NIM/TTL)
      
      -- Expansion Mezzanine Port Signal Standard Select
      -- x_LEV : 
      --    0=>TTL,1=>NIM

      -- Expansion Mezzanine Port Direction
      -- x_DIR : 
      --    0=>OUT,1=>IN

      -- In/Out D (I/O Expansion)
      D_IDCODE    : IN     std_logic_vector ( 2 DOWNTO 0);  -- D slot mezzanine Identifier
      D_LEV       : OUT    std_logic;                       -- D slot Port Signal Level Select 
      D_DIR       : OUT    std_logic;                       -- D slot Port Direction
      D_DIN       : IN     std_logic_vector (31 DOWNTO 0);  -- D slot Data In  Bus
      D_DOUT      : OUT    std_logic_vector (31 DOWNTO 0);  -- D slot Data Out Bus
      -- In/Out E (I/O Expansion)
      E_IDCODE    : IN     std_logic_vector ( 2 DOWNTO 0);  -- E slot mezzanine Identifier
      E_LEV       : OUT    std_logic;                       -- E slot Port Signal Level Select
      E_DIR       : OUT    std_logic;                       -- E slot Port Direction
      E_DIN       : IN     std_logic_vector (31 DOWNTO 0);  -- E slot Data In  Bus
      E_DOUT      : OUT    std_logic_vector (31 DOWNTO 0);  -- E slot Data Out Bus
      -- In/Out F (I/O Expansion)
      F_IDCODE    : IN     std_logic_vector ( 2 DOWNTO 0);  -- F slot mezzanine Identifier
      F_LEV       : OUT    std_logic;                       -- F slot Port Signal Level Select
      F_DIR       : OUT    std_logic;                       -- F slot Port Direction
      F_DIN       : IN     std_logic_vector (31 DOWNTO 0);  -- F slot Data In  Bus
      F_DOUT      : OUT    std_logic_vector (31 DOWNTO 0);  -- F slot Data Out Bus
      --*************************************************
      -- DELAY LINES
      --*************************************************
      -- PDL = Programmable Delay Lines  (Step = 0.25ns / FSR = 64ns)
      -- DLO = Delay Line Oscillator     (Half Period ~ 10 ns)
      -- 3D3428 PDL (PROGRAMMABLE DELAY LINE) CONFIGURATION
      PDL_WR      : OUT    std_logic;                       -- Write Enable
      PDL_SEL     : OUT    std_logic;                       -- PDL Selection (0=>PDL0, 1=>PDL1)
      PDL_READ    : IN     std_logic_vector ( 7 DOWNTO 0);  -- Read Data
      PDL_WRITE   : OUT    std_logic_vector ( 7 DOWNTO 0);  -- Write Data
      PDL_DIR     : OUT    std_logic;                       -- Direction (0=>Write, 1=>Read)
      -- DELAY I/O
      PDL0_OUT    : IN     std_logic;                       -- Signal from PDL0 Output
      PDL1_OUT    : IN     std_logic;                       -- Signal from PDL1 Output
      DLO0_OUT    : IN     std_logic;                       -- Signal from DLO0 Output
      DLO1_OUT    : IN     std_logic;                       -- Signal from DLO1 Output
      PDL0_IN     : OUT    std_logic;                       -- Signal to   PDL0 Input
      PDL1_IN     : OUT    std_logic;                       -- Signal to   PDL1 Input
      DLO0_GATE   : OUT    std_logic;                       -- DLO0 Gate (active high)
      DLO1_GATE   : OUT    std_logic;                       -- DLO1 Gate (active high)
      --*************************************************
      -- SPARE PORTS
      --*************************************************
      SPARE_OUT    : OUT   std_logic_vector(11 downto 0);   -- SPARE Data Out 
      SPARE_IN     : IN    std_logic_vector(11 downto 0);   -- SPARE Data In
      SPARE_DIR    : OUT   std_logic_vector(11 downto 0);   -- SPARE Direction (0 => OUT, 1 => IN)   
      --*************************************************
      -- LED
      --*************************************************
      RED_PULSE       : OUT    std_logic;                   -- RED   Led Pulse (active high)
      GREEN_PULSE     : OUT    std_logic                    -- GREEN Led Pulse (active high)
   );

-- Declarations

END busy_logic ;

ARCHITECTURE rtl OF busy_logic IS

-- Local Signals
signal A     : std_logic_vector(31 downto 0);
signal B     : std_logic_vector(31 downto 0);
signal C   	 : std_logic_vector(31 downto 0);

signal counter : std_logic_vector(31 downto 0) := (others => '0');
signal green_led : std_logic := '0';

-- Busy Logic
signal BUSY_OUT	 : std_logic;

BEGIN

   
   --*************************************************
   -- SPARE PORT
   --*************************************************
   -- ALL Outputs driving 0
   SPARE_OUT <= (others => '0');
   SPARE_DIR <= (others => '1'); 

   --*************************************************
   -- LED PULSES
   --*************************************************
   RED_PULSE   <= green_led;
   GREEN_PULSE <= BUSY_OUT; -- BUSY_OUT is active high
	
   --*************************************************
   -- BUSY OUT
   --*************************************************
	C_DOUT <= (others => BUSY_OUT); -- output on all channels at LVDS out 
	--G_DOUT <= (others => BUSY_OUT); -- 2x NIM output
	G_DOUT(0) <= BUSY_OUT;
	G_DOUT(1) <= green_led; 
	
	
   --*************************************************
   -- BUSY LOGIC
   --*************************************************	
	process (LCLK) begin
		if LCLK'event and LCLK = '1' then

			-- blinking LED
			if counter < 100000000 then
				counter <= counter + 1;
			else
				counter <= (others => '0');
				green_led <= not green_led;
			end if;
			
			--if A_DIN = X"FFFFFFFF" AND B_DIN = X"FFFFFFFF" then
			if A_DIN = X"00000000" AND B_DIN = X"00000000" then
				BUSY_OUT <= '0';
				else
					BUSY_OUT <= '1';
				end if;

		end if;
	end process;
	
	

   
END rtl;

