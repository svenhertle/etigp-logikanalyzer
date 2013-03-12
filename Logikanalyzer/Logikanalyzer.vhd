library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.GlobalTypes.all;

entity Logikanalyzer is
	port (
		-- Takt
		clock    : in std_logic;

		-- VGA-Signale
		vgaHsync : out  std_logic;
		vgaVsync : out  std_logic;
		vgaRed   : out  std_logic_vector(1 downto 0);
		vgaGreen : out  std_logic_vector(1 downto 0);
		vgaBlue  : out  std_logic_vector(1 downto 0);
		
		-- Taster
		switch : in std_logic_vector(1 to 7);
		
		-- Fuehler
		probe : in std_logic_vector(7 downto 0)
	);
end Logikanalyzer;

architecture LAImplementation of Logikanalyzer is
	-- Ram Port A, nur zum Schreiben.
	signal ram_wenableA : std_logic_vector(0 downto 0);
	signal ram_addrA : std_logic_vector(14 downto 0);
	signal ram_datainA : std_logic_vector(7 downto 0);
		
	-- Ram Port B, nur zum Lesen.
	signal ram_addrB : std_logic_vector(14 downto 0);
	signal ram_dataoutB : std_logic_vector(7 downto 0);
	
	-- Steuerung der Anzeige
	signal vga_start_address : integer := 0;
	signal vga_zoom_factor : integer := 3;
	
	signal button_counter : integer := 0;
	
	-- Signale fuer den Sampler.
	signal sampler_start : boolean := false;
	signal sampler_stop : boolean := false;
	signal sampler_finished : boolean;
	signal sampler_mode : SamplingMode := OneShot;
	signal sampler_rate : SamplingRate := Max;
	
	-- einzelne Buttonbelegungen
	alias resetButton : std_logic is switch(1);
	alias recordStartButton : std_logic is switch(2);
	alias recordStopButton : std_logic is switch(3);
	
	alias moveRight : std_logic is switch(4);
	alias moveLeft : std_logic is switch(5);
	
	type State is (
		Start,			-- der Reset-Zustand nach dem Einschalten
		StartRunning,	-- Aufzeichnung starten
		Running,			-- Aufzeichnung laeuft
		View,				-- Daten anschauen
		Stopped			-- Aufzeichnung angehalten
	);
	
	-- hier muessen noch jede Menge weiterer Zustaende rein,
	-- vllt sollten wir wirklich ein Diagramm malen, was wir
	-- uns da so vorstellen.
	
	
	-- der aktuelle Zustand des LAs
	signal currentState : State := Start;
	
begin
	-- Instanzierung der verschiedenen Module
	-- VGA-Signal-Generator
	vga : entity work.VgaCore port map (
		clock => clock,
		hsync => vgaHsync,
		vsync => vgaVsync,
		red => vgaRed,
		green => vgaGreen,
		blue => vgaBlue,
		
		ramAddress => ram_addrB,
		ramData => ram_dataoutB,
		
		startAddress => vga_start_address,
		zoomFactor => vga_zoom_factor
	);
	
	-- Block RAM
	-- hat 24576 Bytes Platz.
	ram : entity work.BlockRam port map (
		 clka => clock,
		 wea => ram_wenableA,
		 addra => ram_addrA,
		 dina => ram_datainA,

		 clkb => clock,
		 web => "0",
		 addrb => ram_addrB,
		 dinb => "00000000",
		 doutb => ram_dataoutB
	);
	
	-- Sampler
	-- nimmt die Messwerte mit den gegebenen Einstellungen in den RAM auf.
	sampler : entity work.Sampler port map (
		probe => probe,
		ramAddress => ram_addrA,
		ramData => ram_datainA,
		ramWriteEnable => ram_wenableA,
		clock => clock,
		
		start => sampler_start,
		stop => sampler_stop,
		finished => sampler_finished,
		samplingMode => sampler_mode,
		samplingRate => sampler_rate
	);
	
	-- schaltet den aktuellen Zustand bei bestimmten Aktionen weiter.
	process(clock)
	begin
		if rising_edge(clock) then
			-- Mit dem Reset-Knopf gehts in den Startzustand.
			-- Kann / soll der RAM zurueckgesetzt werden?
			--   -> Adresse wird im Sampler beim naechsten Start zurueckgesetzt
			if resetButton = '1' then
				currentState <= Start;
			end if;

			-- Je nach aktuellem Zustand weiterschalten.
			case currentState is
				when Start =>
					if recordStartButton = '1' then
						currentState <= StartRunning;
					end if;
				when StartRunning =>
					currentState <= Running; -- 1 Takt warten und weiter
				when Running =>
					if recordStopButton = '1' or sampler_finished then
						currentState <= View;
					end if;
				when View =>
						-- Links und rechts
						button_counter <= button_counter + 1;

						if button_counter = 0 then
							if moveRight = '1' then
								vga_start_address <= vga_start_address + 1;
								
								if vga_start_address >= ramSize-1 then
									vga_start_address <= ramSize-1;
								end if;
							elsif moveLeft = '1' then
								vga_start_address <= vga_start_address - 1;
								
								if vga_start_address <= 0 then
									vga_start_address <= 0;
								end if;
							end if;
						elsif button_counter > 500000 then
							button_counter <= 0;
						end if;
						
						-- Zuruecksetzen, damit es keine Verzoegerung gibt
						if moveRight = '0' and moveLeft = '0' then
							button_counter <= 0;
						end if;
				when Stopped =>
					null; -- hier kommt man momentan nur mit einem Druck auf Reset raus.
			end case;
		end if;
	end process;
	
	-- Stellt die Signale an die anderen Module entsprechend des aktuellen Zustandes ein.
	process(currentState)
	begin
		case currentState is
			when Start =>
				sampler_start <= false;
				sampler_stop <= true;
			when StartRunning =>
				sampler_start <= true;
				sampler_stop <= false;
			when View =>
				sampler_start <= false;
				sampler_stop <= true;
			when Running =>
				sampler_start <= false;
				sampler_stop <= false;
			when Stopped =>
				sampler_start <= false;
				sampler_stop <= true;
		end case;
	end process;

end LAImplementation;
