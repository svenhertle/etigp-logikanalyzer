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
		probe : in std_logic_vector(7 downto 0);
		
		-- LEDs
		led : out std_logic_vector(7 downto 0)
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
	signal vga_zoom_factor : integer := 1;
	signal vga_zoom_out : boolean := False;
	signal vga_start_tmp_counter : integer := 0;
	signal vga_scroll_factor : integer := 1;
	
	signal button_counter : integer := 0;
	signal button_counter2 : integer := 0;
	
	-- Signale fuer den Sampler.
	signal sampler_start : boolean := false;
	signal sampler_stop : boolean := false;
	signal sampler_finished : boolean;
	signal sampler_mode : SamplingMode := OneShot;
	signal sampler_rate : SamplingRate := Max;
	signal sampler_current_data : std_logic_vector(7 downto 0);
	
	-- Signale fuer den Trigger
	signal trigger_on : boolean := False;
	signal trigger_state : AllTriggers := (Off, Off, Off, Off, Off, Off, Off, Off);
	signal trigger_start : std_logic;
	signal trigger_reset : std_logic := '0';
	
	signal trigger_current_data : std_logic_vector(7 downto 0);
	signal trigger_last_data : std_logic_vector(7 downto 0);
	
	signal trigger_sel : integer range 0 to 8;
	
	-- einzelne Buttonbelegungen
	alias resetButton : std_logic is switch(1);
	alias recordStartButton : std_logic is switch(2);
	alias recordStopButton : std_logic is switch(3);
	
	alias left : std_logic is switch(4);
	alias right : std_logic is switch(5);
	alias up : std_logic is switch(6);
	alias down: std_logic is switch(7);
	
	-- hier muessen noch jede Menge weiterer Zustaende rein,
	-- vllt sollten wir wirklich ein Diagramm malen, was wir
	-- uns da so vorstellen.
	
	
	-- der aktuelle Zustand des LAs
	signal currentState : State := Start;
	
	-- der selektierte Menueintrag
	signal menuState : Menu := MSamplingMode;
	
	signal charAddress : character;
	signal charData : Letter;
	
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
		
		charAddress => charAddress,
		charData => charData,
		
		startAddress => vga_start_address,
		zoomFactor => vga_zoom_factor,
		zoomOut => vga_zoom_out,
		
		smState => currentState,
		menuState => menuState,
		samplingMode => sampler_mode,
		samplingRate => sampler_rate,
		triggerState => trigger_state,
		triggerOn => trigger_on,
		triggerSel => trigger_sel
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
	
	-- Character ROM
	charRom : entity work.TextRom port map (
		address => charAddress,
		char => charData
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
		samplingRate => sampler_rate,
		currentData => sampler_current_data
	);
	
	trigger : entity work.Trigger port map (
		clock => clock,
		start => trigger_start,
		state => trigger_state,
		current_data => trigger_current_data,
		last_data => trigger_last_data,
		reset => trigger_reset
	);
	
	led <= (others => '0');
	
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
						currentState <= WaitRunning;
					end if;
					
					-- Buttons: links, rechts, oben, unten
					button_counter <= button_counter + 1;
					
					if button_counter = 0 then
						if right = '1' then
							case menuState is
							when MSamplingMode =>
								menuState <= MSamplingRate;
							when MSamplingRate =>
								menuState <= MTriggerOn;
							when MTriggerOn =>
								if trigger_on then
									menuState <= MTriggerSettings;
									trigger_sel <= 8;
								else
									menuState <= MView;
								end if;
							when MTriggerSettings =>
								-- Im Menu -> andere Menueintraege
								if trigger_sel = 8 then
									menuState <= MView;
								-- Bei Kanaleinstellungen
								else
									case trigger_state(trigger_sel) is
										when Off =>
											trigger_state(trigger_sel) <= High;
										when High =>
											trigger_state(trigger_sel) <= Low;
										when Low =>
											trigger_state(trigger_sel) <= Rising;
										when Rising =>
											trigger_state(trigger_sel) <= Falling;
										when Falling =>
											trigger_state(trigger_sel) <= Off;
									end case;
								end if;
							when MView =>
								menuState <= MSamplingMode;
							end case;
						elsif left = '1' then
							case menuState is
							when MSamplingMode =>
								menuState <= MView;
							when MSamplingRate =>
								menuState <= MSamplingMode;
							when MTriggerOn =>
								menuState <= MSamplingRate;
							when MTriggerSettings =>
								-- Im Menu -> andere Menueintraege
								if trigger_sel = 8 then
									menuState <= MTriggerOn;
								-- Bei Kanaleinstellungen
								else
									case trigger_state(trigger_sel) is
										when Off =>
											trigger_state(trigger_sel) <= Falling;
										when High =>
											trigger_state(trigger_sel) <= Off;
										when Low =>
											trigger_state(trigger_sel) <= High;
										when Rising =>
											trigger_state(trigger_sel) <= Low;
										when Falling =>
											trigger_state(trigger_sel) <= Rising;
									end case;
								end if;
							when MView =>
								if trigger_on then
									menuState <= MTriggerSettings;
									trigger_sel <= 8;
								else
									menuState <= MTriggerOn;
								end if;
							end case;
						elsif up = '1' then
							case menuState is
							when MSamplingMode =>
								if sampler_mode = OneShot then
									sampler_mode <= Continuous;
								else
									sampler_mode <= OneShot;
								end if;
							when MSamplingRate =>
								case sampler_rate is
								when s1 =>
									sampler_rate <= ms100;
								when ms100 =>
									sampler_rate <= ms10;
								when ms10 =>
									sampler_rate <= ms1;
								when ms1 =>
									sampler_rate <= Max;
								when Max =>
									sampler_rate <= s1;
								end case;
							when MTriggerOn =>
								trigger_on <= not trigger_on;
							when MTriggerSettings =>
								if trigger_sel = 0 then
									trigger_sel <= 8;
								else
									trigger_sel <= trigger_sel - 1;
								end if;
							when others =>
								null;
							end case;
						elsif down = '1' then
							case menuState is
							when MSamplingMode =>
								if sampler_mode = OneShot then
									sampler_mode <= Continuous;
								else
									sampler_mode <= OneShot;
								end if;
							when MSamplingRate =>
								case sampler_rate is
								when s1 =>
									sampler_rate <= Max;
								when ms100 =>
									sampler_rate <= s1;
								when ms10 =>
									sampler_rate <= ms100;
								when ms1 =>
									sampler_rate <= ms10;
								when Max =>
									sampler_rate <= ms1;
								end case;
							when MTriggerOn =>
								trigger_on <= not trigger_on;
							when MTriggerSettings =>
								if trigger_sel >= 8 then
									trigger_sel <= 0;
								else
									trigger_sel <= trigger_sel + 1;
								end if;
							when others =>
								null;
							end case;
						elsif recordStopButton = '1' and menuState = MView then
							currentState <= View;
						end if;
					end if;
					
					if button_counter > 20000000 then
						button_counter <= 0;
					end if;
					
					-- Zuruecksetzen, damit es keine Verzoegerung gibt
					-- TODO: Ursache fuer Spruenge?
					if right = '0' and left = '0' and up = '0' and down = '0' then
						button_counter <= 0;
					end if;
				when WaitRunning =>
					if trigger_on then
						if trigger_start = '1' then
							currentState <= StartRunning; -- 1 Takt warten und weiter
						elsif recordStopButton = '1' then
							currentState <= Start;
						end if;
					else
						currentState <= StartRunning;
					end if;
				when StartRunning =>
					currentState <= Running;
				when Running =>
					if recordStopButton = '1' or sampler_finished then
						currentState <= View;
					end if;
				when View =>
					-- Links und rechts
					button_counter <= button_counter + 1;
					button_counter2 <= button_counter2 + 1;
					
					if recordStopButton = '1' then
						vga_scroll_factor <= 10;
					else
						vga_scroll_factor <= 1;
					end if;

					if button_counter = 0 then
						if right = '1' then
							if vga_zoom_out then
								vga_start_address <= vga_start_address + vga_scroll_factor;
							else
								vga_start_tmp_counter <= vga_start_tmp_counter + 1;
								
								if vga_start_tmp_counter >= vga_zoom_factor then
									vga_start_tmp_counter <= 0;
									vga_start_address <= vga_start_address + vga_scroll_factor;
								end if;
							end if;
							
							if vga_start_address >= ramSize-1 then -- TODO: Anzahl Messwerte
								vga_start_address <= ramSize-1;
							end if;
						elsif left = '1' then
							if vga_zoom_out then
								vga_start_address <= vga_start_address - vga_scroll_factor;
							else
								vga_start_tmp_counter <= vga_start_tmp_counter + 1;
								
								if vga_start_tmp_counter >= vga_zoom_factor then
									vga_start_tmp_counter <= 0;
									vga_start_address <= vga_start_address - vga_scroll_factor;
								end if;
							end if;							
							if vga_start_address <= 0 then
								vga_start_address <= 0;
							end if;
						end if;
					elsif button_counter > 500000 then
						button_counter <= 0;
					end if;
					
					if button_counter2 = 0 then
						if up = '1' then
							case vga_zoom_factor is
								when 1 =>
									vga_zoom_out <= False;
									vga_zoom_factor <= 2;
								when 2 =>
									if vga_zoom_out then
										vga_zoom_factor <= 1;
									else
										vga_zoom_factor <= 4;
									end if;
								when 4 =>
									if vga_zoom_out then
										vga_zoom_factor <= 2;
									end if;
								when others =>
									null;
							end case;
						elsif down = '1' then
							case vga_zoom_factor is
								when 1 =>
									vga_zoom_out <= True;
									vga_zoom_factor <= 2;
								when 2 =>
									if vga_zoom_out then
										vga_zoom_factor <= 4;
									else
										vga_zoom_factor <= 1;
									end if;
								when 4 =>
									if not vga_zoom_out then
										vga_zoom_factor <= 2;
									end if;
								when others =>
									null;
							end case;
						end if;
					elsif button_counter2 > 20000000 then
						button_counter2 <= 0;
					end if;
					
					if up = '0' and down = '0' then
						button_counter2 <= 0;
					end if;
					
					-- Zuruecksetzen, damit es keine Verzoegerung gibt
					if right = '0' and left = '0' then
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
				trigger_reset <= '1';
			when WaitRunning =>
				sampler_start <= false;
				sampler_stop <= true;
				trigger_reset <= '0';
			when StartRunning =>
				sampler_start <= true;
				sampler_stop <= false;
				trigger_reset <= '1';
			when View =>
				sampler_start <= false;
				sampler_stop <= true;
				trigger_reset <= '1';
			when Running =>
				sampler_start <= false;
				sampler_stop <= false;
				trigger_reset <= '1';
			when Stopped =>
				sampler_start <= false;
				sampler_stop <= true;
				trigger_reset <= '1';
		end case;
	end process;
	
	-- Aktuelle und letzte aufgenommene Daten fuer Sampler speichern
	process(sampler_current_data)
	begin
		trigger_current_data <= sampler_current_data;
		trigger_last_data <= trigger_current_data;
	end process;
end LAImplementation;
