library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity Logikanalyzer is
	port(
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
		
		-- Fhler
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
	
	-- Zhler fr aktuelle Ram-Schreib-Adresse.
	signal ctr : integer := 0;
			
	-- Counter fuer Abtastrate
	signal abtast_counter : integer := 0;
	signal abtastrate : integer := 0;
begin
	-- Instanzierung der verschiedenen Module
	-- VGA-Signal-Generator
	vga : entity work.VgaCore port map(
		clock => clock,
		hsync => vgaHsync,
		vsync => vgaVsync,
		red => vgaRed,
		green => vgaGreen,
		blue => vgaBlue,
		
		switch => switch,
		probe => probe,
		
		ramAddress => ram_addrB,
		ramData => ram_dataoutB
	);
	
	-- hat 24576 Bytes Platz.
	ram : entity work.BlockRam PORT MAP (
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
	
	
	-- Aufzeichnung der Eingnge mit maximaler Geschwindigkeit.
	process (clock)
	begin
		if rising_edge(clock) then
			-- Einlesen mit Taster 1 unterbrechen
			if switch(1) = '0' then
				-- Abtastrate
				if abtast_counter >= abtastrate then -- TODO 1 -> var
					abtast_counter <= 0;
					
					ctr <= ctr + 1;
					ram_addrA <= std_logic_vector(to_unsigned(ctr, 15));
					ram_wenableA <= "1";
					ram_datainA <= probe;
				else
					abtast_counter <= abtast_counter + 1;
				end if;
			-- Zurueksetzen, koennte sich sonst aufhaengen
			else
				abtast_counter <= 0;
			end if;
		end if;
	end process;
end LAImplementation;
