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
		WaitRunning,	-- Aufzeichnung starten, wenn Trigger auslÃ¶st oder sofort bei deaktiviertem Trigger
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
	
	-- für jede Samplingrate, für jede Zoomstufe
	subtype TbString is string (1 to 8);
	type tbh is array(1 to 5) of TbString;
	type Timebase is array(1 to 5) of tbh;
		
	-- abstand zwischen zwei strichen: 91 px
	
	constant tb : Timebase := (
		--s1
		-- zoomstufen 0.25, 0.5, 1, 2, 4
		(
			"364 s   ",
			"182 s   ",
			"91 s    ",
			"45,5 s  ",
			"22,75 s "
		),
		
		--ms100
		(
			"36,4 s  ",
			"18,2 s  ",
			"9,1 s   ",
			"4,55 s  ",
			"2,275 s "
		),
		
		--ms10
		(
			"3,64 s  ",
			"1,82 s  ",
			"910 ms  ",
			"455 ms  ",
			"227,5 ms"
		),
		
		--ms1
		(		
			"364 ms  ",
			"182 ms  ",
			"91 ms   ",
			"45,5 ms ",
			"22,75 ms"
		),
		
		--max
		(		
			"7,4  mis",
			"3,7 mis ",
			"1,85 mis",
			"925 ns  ",
			"462,5 ns"
		)
	);
	
	
	-- moegliche Betriebsarten
	type SamplingMode is (
		OneShot, -- eine Aufnahme bis Speicher voll
		Continuous -- durchgehend aufnehmen, Speicher ueberschreiben
	);

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
end GlobalTypes;
