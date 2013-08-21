library ieee;
use ieee.std_logic_1164.all;

package GlobalTypes is
	-- Trigger
	type TriggerState is (
		Off,
		High,
		Low,
		Rising,
		Falling
	);
	
	type AllTriggers is array (0 to 7) of TriggerState;
	
	-- Status der State Machine
	type State is (
		Start,			-- der Reset-Zustand nach dem Einschalten -> Menues aendern
		WaitRunning,	-- Aufzeichnung starten, wenn Trigger auslöst oder sofort bei deaktiviertem Trigger
		StartRunning,	-- Aufzeichnung starten
		Running,			-- Aufzeichnung laeuft
		View,				-- Daten anschauen
		Stopped			-- Aufzeichnung angehalten
	);
	
	-- Selektierter Menueintrag
	type Menu is (
		MSamplingMode,
		MSamplingRate,
		MTriggerOn,
		MTriggerSettings,
		MView
	);
	
	-- moegliche Abtastraten
	type SamplingRate is (
		s1, 		-- Aufzeichnung alle 1 s
		ms100,	-- 100 ms
		ms10,		-- 10 ms
		ms1,		-- 1 ms
		Max		-- Aufzeichnung mit 49,152 MHz
	);
	
	-- fr jede Samplingrate, fr jede Zoomstufe
	subtype TbString is string (1 to 8);
	type tbh is array(1 to 5) of TbString;
	type Timebase is array(1 to 5) of tbh;
		
	-- abstand zwischen zwei strichen: 91 px
	
	constant tb : Timebase := (
		--s1
		-- zoomstufen 0.25, 0.5, 1, 2, 4
		(
			"364 S   ",
			"182 S   ",
			"91 S    ",
			"45,5 S  ",
			"22,75 S "
		),
		
		--ms100
		(
			"36,4 S  ",
			"18,2 S  ",
			"9,1 S   ",
			"4,55 S  ",
			"2,275 S "
		),
		
		--ms10
		(
			"3,64 S  ",
			"1,82 S  ",
			"910 MS  ",
			"455 MS  ",
			"227,5 MS"
		),
		
		--ms1
		(		
			"364 MS  ",
			"182 MS  ",
			"91 MS   ",
			"45,5 MS ",
			"22,75 MS"
		),
		
		--max
		(		
			"7,4  MIS",
			"3,7 MIS ",
			"1,85 MIS",
			"925 NS  ",
			"462,5 NS"
		)
	);
	
	
	-- moegliche Betriebsarten
	type SamplingMode is (
		OneShot, -- eine Aufnahme bis Speicher voll
		Continuous -- durchgehend aufnehmen, Speicher ueberschreiben
	);
	
	-- Fuer Texte
	type Letter is array (0 to 7) of bit_vector(0 to 7);
	type Font is array (32 to 90) of Letter;

	-- Taktfrequenz des FPGA
	constant currentFrequency : integer := 49_152_000; -- Hz
	
	-- Anzahl der im RAM verfuegbaren Bytes
	constant ramSize : integer := 24576;

	
	function samplingRateToCounter (
		signal sr : SamplingRate
	) return integer;
	
	function samplingRateToString (
		signal sr : SamplingRate
	) return string;
	
	function stateToString (
		signal st : State
	) return string;
	
	function samplingRateToTBIndex(
		signal sr: SamplingRate
	)
	return integer;
	
	function zoomToTBIndex(
		signal z: integer;
		signal zout : boolean
	)
	return integer;
end GlobalTypes;

package body GlobalTypes is
	-- Gibt den zur angegebenen Abtastrate gehoerenden Zaehlerstand zurueck.
	-- d. h. 49152000 Takte pro Sekunde
	-- d. h. 4915200 Takte pro 100 ms
	-- d. h. 491520 Takte pro 10 ms
	-- d. h. 49152 Takte pro ms
	function samplingRateToCounter (
		signal sr : SamplingRate
	) return integer is
	begin
		case sr is
			when s1 => return 49152000;
			when ms100 => return 4915200;
			when ms10 => return 491520;
			when ms1 => return 49152;
			when Max  => return 0;
		end case;
	end samplingRateToCounter;
	
	-- Gibt die uebergebene Abtastrate als String zurueck.
	function samplingRateToString (
		signal sr : SamplingRate
	) return string is
	begin
		case sr is
			when s1 => return "1 S";
			when ms100 => return "100 MS";
			when ms10 => return "10 MS";
			when ms1 => return "1 MS";
			when Max => return "MAX";
			--when others => return "???";
		end case;
	end samplingRateToString;
	
	-- Gibt den uebergebenen Status als String zurueck.
	-- TODO: use or remove
	function stateToString (
		signal st : in State
	) return string is
	begin
		case st is
			when Start => return "WAIT";
			when WaitRunning | StartRunning | Running => return "RECORD";
			when View => return "VIEW";
			when Stopped => return "STOP";
			--when others => return "???";
		end case;
	end stateToString;
	
	function samplingRateToTBIndex(
		signal sr: SamplingRate
	) return integer is
	begin
		case sr is
			when s1 => return 1;
			when ms100 => return 2;
			when ms10 => return 3;
			when ms1 => return 4;
			when Max => return 5;
		end case;
	end samplingRateToTBIndex;
	
	function zoomToTBIndex(
		signal z: integer;
		signal zout : boolean
	) return integer is
	begin
		if zout then
			case z is
				when 1 => return 3;
				when 2 => return 2;
				when 4 => return 1;
				when others => return 1;
			end case;
		else
			case z is
				when 1 => return 3;
				when 2 => return 4;
				when 4 => return 5;
				when others => return 1;
			end case;
		end if;
	end zoomToTBIndex;
end GlobalTypes;
