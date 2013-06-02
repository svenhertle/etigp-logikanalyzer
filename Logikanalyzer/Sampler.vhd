library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.GlobalTypes.all;

-- Zustaendig fuer das Aufnehmen von Messwerten in den RAM.
-- Unterstuetzt Start/Stopp, Einstellen der Abtastrate,
-- Stopp bei Speicher voll, loop, etc.

entity Sampler is
	port (
		start				: in boolean;
		stop				: in boolean;
		
		finished			: out boolean;
		
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
	-- Laeuft gerade?
	signal running : boolean := false;
	
	-- Naechste zu schreibende Adresse
	signal currentRamAddress : std_logic_vector(14 downto 0);
	
	-- Zaehler fr den Taktteiler
	signal samplingCounter : integer;

begin
	finished <= not running;
	
	process (clock)
	begin
		if rising_edge(clock) then
			if start then
				running <= true;
				currentRamAddress <= (others => '0');
			elsif stop then
				running <= false;
			end if;
			
			if running then
				if samplingCounter = samplingRateToCounter(samplingRate) then
					samplingCounter <= 0;
					
					-- RAM-Adresse hochzaehlen / umbrechen.
					if (unsigned(currentRamAddress) >= ramSize) then
						if samplingMode = OneShot then
							running <= false;
						else
							currentRamAddress <= (others => '0');
						end if;
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
