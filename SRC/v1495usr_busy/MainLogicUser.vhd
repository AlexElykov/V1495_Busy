-- ****************************************************************************
-- Model:           V1495 -  Multipurpose Programmable Trigger Unit
-- Device:          ALTERA EP1C4F400C6
-- Author:          Lukas Buetikofer (lukas.buetikofer@lhep.unibe.ch)
-- Date:            16.7.2015
-- ----------------------------------------------------------------------------
-- Module:          MainLogicUser
-- Description:     Firmware for v1495 used in XENON1T DAQ.
--						  See also documentation here: http://www.lhep.unibe.ch/darkmatter/darkwiki/doku.php?id=xenon:daq:busy_veto
-- 
--						  This firmware takes the LVDS busy signals from the V1724 digitizers at the input A
--						  ,the signal from the DDC-10 HE-veto (used for XENON1T) at input G_0 and a pulser signal at input G_1.
--						  The busy and the HEV NIM signals are encoded according the following scheme:
--						  One short pulse at falling edge and two short pulses at rising edge.
--						  The encoded signals are sent to F_0 (HEV) and F_1 (Busy). 
--						  
--						  If there are no pulses comming at input G_1, A and G_0 are combined using a logic OR
--						  and the output is sent to F_2 and F_3.
--						  
--						  If there are pulses comming to input G_1, the pulses are sent to F_2, F_3 and F_4 
--						  unless there is a signal in any channel of (=> digitizer is busy). In that case there is no output at F_2, F_3 and F_4.
--						  
-- ****************************************************************************


LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_misc.all;  -- Use OR_REDUCE function

USE work.v1495pkg.all;

ENTITY MainLogicUser IS
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

END MainLogicUser ;

ARCHITECTURE rtl OF MainLogicUser IS

-- Local Signals
signal A     : std_logic_vector(31 downto 0);
signal B     : std_logic_vector(31 downto 0);
signal C   	 : std_logic_vector(31 downto 0);

--signal counter : std_logic_vector(31 downto 0) := (others => '0');
signal green_led : std_logic := '0';
signal red_led : std_logic := '0';

-- Busy 
signal BusyIN1 : std_logic_vector(31 downto 0); -- from digitizers
signal BusyIN2 : std_logic_vector(31 downto 0);
signal BusyOUT	 : std_logic;
signal BUSYencod : std_logic;
signal BUSYstart : std_logic;
signal BUSYstop : std_logic;

-- HEV
signal HEVin : std_logic; -- from HEV module
signal HEVout : std_logic;
signal HEVencod : std_logic;
signal HEVstart : std_logic;
signal HEVstop : std_logic;

-- LED
signal PulserIN : std_logic; -- comming from the crate controller
signal LEDmode : std_logic;

-- Final V1495 outputs
signal VetoOUT : std_logic; --Fignal HEV/Busy veto going to -> LogicFans -> ADCss
signal TrgOUT : std_logic; -- LED trigger after busy gate
signal Heartbeat : std_logic :='0';

-- Component Declarations
COMPONENT BusyLogicComponent
PORT (
	LCLK:		IN		std_logic;	-- ADC clock
	BusyIN1 : IN		std_logic_vector(31 downto 0);
	BusyIN2 : IN		std_logic_vector(31 downto 0);
	BusyOUT : OUT	std_logic
);
END COMPONENT;

-- testing component
COMPONENT TestComponent
PORT (
	LCLK:		IN		std_logic;	-- ADC clock
	TestIN : IN		std_logic;
	TestOUT : OUT	std_logic
);
END COMPONENT;

-- returns 
--	one pulses if 0=>1 transitions
--	two pulse for 1=>0 transitions
COMPONENT EncodingComponent
PORT( 
	LCLK:			IN		std_logic;	-- ADC clock
	SignalIN:	IN		std_logic;
	SignalOUTstart:	OUT	std_logic;
	SignalOUTstop:	OUT	std_logic;
	SignalOUT:	OUT	std_logic
);
END COMPONENT ;


-- this component checks if we are running in LED mode or not
-- LEDmode='1' if there are LEDpulses comming from the crate controller
-- LEDmode='0' if there are no LEDpulses comming from the crate controller
COMPONENT LEDstatus
PORT( 
	LCLK:			IN		std_logic;	-- ADC clock
	PulserIN:	IN		std_logic;
	LEDmode:	OUT	std_logic
);
END COMPONENT ;



BEGIN

   --******************** put levels to NIM *************
	F_LEV <= '1'; -- set to NIM 
	G_LEV <= '1'; -- set to NIM 
   
   --******************** SPARE PORT ********************
   -- ALL Outputs driving 0
   SPARE_OUT <= (others => '0');
   SPARE_DIR <= (others => '1'); 

	
   --******************** Inputs ************************
	BusyIN1 <= A_DIN;
	BusyIN2 <= B_DIN; -- not used
	HEVin <= not G_DIN(0); -- HEVin = '1' if NIM pulse is on
	PulserIN <= not G_DIN(1); -- PulserIN = '1' if NIM pulse from crate controller is on	
		
	-- check if any of the digitizers is busy
	-- If so, then BusyOUT is '1', else BusyOUT='0'
	busy_logic : BusyLogicComponent
	PORT MAP (
		LCLK => LCLK,
		BusyIN1  => BusyIN1,
		BusyIN2 => BusyIN2,
		BusyOUT => BusyOUT
	);
	
		-- check if any of the digitizers is busy
	-- If so, then BusyOUT is '1', else BusyOUT='0'
--	HEVtest_logic : TestComponent
--	PORT MAP (
--		LCLK => LCLK,
--		TestIN  => HEVin,
--		TestOUT => HEVout
--	);
	
	-- Encodeing the HEV signal as follows:
	-- => one pulse (10ns) at falling edge and
	-- 	two pulses (10 ns each) at rising edge.
	HEV_encoding : EncodingComponent
	PORT MAP (
		LCLK => LCLK,
		SignalIN => HEVin,
		SignalOUTstart => HEVstart,
		SignalOUTstop => HEVstop,
		SignalOUT => HEVencod
	);

	-- Encodeing the BusyOUT signal as follows:
	-- => one pulse (10ns) at falling edge and
	-- 	two pulses (10 ns each) at rising edge.
	BUSY_encoding : EncodingComponent
	PORT MAP (
		LCLK => LCLK,
		SignalIN => BusyOUT,
		SignalOUTstart => BUSYstart,
		SignalOUTstop => BUSYstop,
		SignalOUT => BUSYencod
	);
	
	check_LED_status : LEDstatus
	PORT MAP (
		LCLK => LCLK,
		PulserIN => PulserIN,
		LEDmode => LEDmode
	);
			
	-- combine Busy veto and HEV with OR logic to final Veto_Pulser_OUT
	process (LCLK) begin
		if LCLK'event and LCLK = '1' then
		
			Heartbeat <= not Heartbeat;
		
			-- Busy/HEV logic
			if (BusyOUT = '1' OR HEVin = '1') AND LEDmode = '0' then -- LVDS Busy is active low signal
				VetoOUT <= '1';
			else
				VetoOUT <= '0';
			end if;
	
			-- LED trigger logic
			if BusyOUT = '0' then
				TrgOUT <= PulserIN;
			else
				TrgOUT <= '0';
			end if;

			-- LEDs
			-- LED = orange if Busy is active (priority over HEV)
			if BusyOUT = '1' then
				green_led <= '1';
				red_led <= '1';
			-- if there is incoming pulse from crate controller, LED = red (top priority)
			elsif PulserIN = '1' then
				red_led <= '1';
				green_led <= '0';
			-- LED = green if HEV is active (and busy is not)
			elsif HEVin = '1' then
				green_led <= '1';
				red_led <= '0';
			else
				green_led <= '0';
				red_led <= '0';
			end if;	

		end if;
	end process;
	
   --******************** Outputs **************************
-- OLD OUTPUTS
--	F_DOUT(0) <=  HEVencod; -- to acquisition monitor
--	F_DOUT(1) <=  BUSYencod; -- to acquisition monitor
--	F_DOUT(2) <=  TrgOUT; -- to digitizer TRG
--	F_DOUT(3) <=  VetoOUT; -- to digitizer TRG
--	F_DOUT(4) <=  VetoOUT; -- to LED pulser

	F_DOUT(0) <=  BUSYstart; -- to acquisition monitor
	F_DOUT(1) <=  BUSYstop; -- to acquisition monitor
	F_DOUT(2) <=  HEVstart; -- to digitizer TRG
	F_DOUT(3) <=  HEVstop; -- to digitizer TRG
	F_DOUT(4) <=  TrgOUT; -- pulser for LED 
	F_DOUT(5) <=  VetoOUT; -- to Fan1 --> digitizer TRG
	F_DOUT(6) <=  VetoOUT; -- to Fan2 --> digitizer TRG
--	F_DOUT(7) <=  Heartbeat; -- test output
	

	-- LEDs
	GREEN_PULSE <= green_led; -- green LED turns on, at least one digitizer is busy
	RED_PULSE <= red_led; -- turns on if running in LED mode
	
   
END rtl;

