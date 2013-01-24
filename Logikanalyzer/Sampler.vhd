library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.GlobalTypes.all;

-- Zust�ndig f�r das Aufnehmen von Messwerten in den RAM.
-- Unterst�tzt Start/Stopp, Einstellen der Abtastrate,
-- Stopp bei Speicher voll, loop, etc.

entity Sampler is
	port (
		running			: in boolean;
		samplingMode 	: in SamplingMode;
		samplingRate 	: in SamplingRate;
		clock				: in std_logic;
		probe				: in std_logic_vector(7 downto 0);
		
		ramAddress		: out std_logic_vector(14 downto 0);
		ramData			: out std_logic_vector(7 downto 0);
		ramWriteEnable : out std_logic_vector(0 downto 0)
	);
end Sampler;

architecture SamplerImplementation of Sampler is
	-- N�chste zu schreibende Adresse
	signal currentRamAddress : std_logic_vector(14 downto 0);
	
	-- Z�hler f�r den Taktteiler
	signal samplingCounter : integer;

begin
	process (clock)
	begin
		if rising_edge(clock) then
			if running then
				-- TODO: SamplingMode implementieren
				if (samplingCounter = samplingRateToCounter(samplingRate)) then
					samplingCounter <= 0;
					
					-- RAM-Adresse hochz�hlen / umbrechen.
					if (unsigned(currentRamAddress) >= ramSize) then
						currentRamAddress <= (others => '0');
					else
						currentRamAddress <= std_logic_vector(unsigned(currentRamAddress) + 1);
					end if;

					-- Einen Messwert aufnehmen					
					ramAddress <= currentRamAddress;
					ramData <= probe;
					ramWriteEnable <= "1";
				else
					samplingCounter <= samplingCounter + 1;
					ramWriteEnable <= "0";
				end if;
			else -- not running
				samplingCounter <= 0;
				ramWriteEnable <= "0";			
			end if;
		end if;
	end process;
end SamplerImplementation;
