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
	
	-- Signale fr den Sampler.
	signal sampler_running : boolean := true;
	signal sampler_mode : SamplingMode := Continuous;
	signal sampler_rate : SamplingRate := Max;
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
		ramData => ram_dataoutB
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
		
		running => sampler_running,
		samplingMode => sampler_mode,
		samplingRate => sampler_rate
	);
	
	process(clock)
	begin
		if rising_edge(clock) then
			-- das Anhalten macht nachher die State Machine.
			if (switch(1) = '1') then
				sampler_running <= false;
			else
				sampler_running <= true;
			end if;
		end if;
	end process;
end LAImplementation;
