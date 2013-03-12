library ieee;
use ieee.std_logic_1164.all;

package GlobalTypes is
	-- moegliche Abtastraten
	type SamplingRate is (
		s1, 		-- Aufzeichnung alle 1 s
		ms100,	-- 100 ms
		ms10,		-- 10 ms
		ms1,		-- 1 ms
		Max		-- Aufzeichnung mit 49,152 MHz
	);
	
	-- moegliche Betriebsarten
	type SamplingMode is (
		OneShot, -- eine Aufnahme bis Speicher voll
		Continuous -- durchgehend aufnehmen, Speicher ueberschreiben
	);
		
	-- moegliche Zoomfaktoren
	type ZoomFactor is (
		Min,	-- kompletter Speicher auf einer Bildschirmbreite
		Max	-- z. B. jeder Messwert 10 Pixel lang
		-- ersteres sinnvoll? Also immer nur jeden n-ten Wert malen?
		-- oder lieber Min = 1 Pixel pro Messwert?
	);

	-- Taktfrequenz des FPGA
	constant currentFrequency : integer := 49_152_000; -- Hz
	
	-- Anzahl der im RAM verfuegbaren Bytes
	constant ramSize : integer := 24576;

	
	function samplingRateToCounter (
		constant sr : SamplingRate
	) return integer;
	
	function samplingRateToString (
		constant sr : SamplingRate
	) return string;
end GlobalTypes;

package body GlobalTypes is
	-- Gibt den zur angegebenen Abtastrate gehoerenden Zaehlerstand zurueck.
	-- d. h. 49152000 Takte pro Sekunde
	-- d. h. 4915200 Takte pro 100 ms
	-- d. h. 491520 Takte pro 10 ms
	-- d. h. 49152 Takte pro ms
	function samplingRateToCounter (
		constant sr : SamplingRate
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
		constant sr : SamplingRate
	) return string is
	begin
		case sr is
			when s1 => "1 s";
			when ms100 => "100 ms";
			when ms10 => "10 ms";
			when ms1 => "1 ms";
			when Max => "Max";
			when others => "???";
		end case;
	end samplingRateToString;
end GlobalTypes;
