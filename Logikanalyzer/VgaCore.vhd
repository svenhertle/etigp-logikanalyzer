library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

-- Der VGA-Signal-Generator
entity VgaCore is
	port(
		clock : in   std_logic;

		hsync : out  std_logic;
		vsync : out  std_logic;

		red   : out  std_logic_vector(1 downto 0);
		green : out  std_logic_vector(1 downto 0);
		blue  : out  std_logic_vector(1 downto 0)
	);
end VgaCore;

architecture VgaImplementation of VgaCore is
	-- Spezifikation von VGA
	constant HFrontPorch : integer := 16;
	constant HSyncPulse : integer := 96;
	constant HBackPorch : integer := 48;
	constant HDisplay : integer := 640;
	constant HSize : integer := HFrontPorch + HSyncPulse + HBackPorch + HDisplay;
	constant HOffset : integer := HFrontPorch + HSyncPulse + HBackPorch;
	
	constant VFrontPorch : integer := 11;
	constant VSyncPulse : integer := 2;
	constant VBackPorch : integer := 31;
	constant VDisplay : integer := 480;
	constant VSize : integer := VFrontPorch + VSyncPulse + VBackPorch + VDisplay;
	constant VOffset : integer := VFrontPorch + VSyncPulse + VBackPorch;
	
	-- Aktuelle Position
	signal x : integer range 0 to HSize-1 := 0;
	signal y : integer range 0 to VSize-1 := 0;
	
	-- Zum Takt halbieren
	signal state : std_logic := '0';
begin
	-- Erzeugung des VGA-Signals.
	process(clock)
	begin
		if rising_edge(clock) then
			if state = '1' then
				state <= '0';
			else
				state<= '1';
				
				x <= x + 1;
				
				if (x = HSize-1) then 
					x <= 0;
					y <= y+1;
					
					if (y = VSize-1) then
						y <= 0;
					end if;
				end if;
				
				-- Vertikal
				if (y < VFrontPorch-1) then -- FrontPorch
					vsync <= '1';
					red <= "00";
					green <= "00";
					blue <= "00";
				elsif (y < VFrontPorch+VSyncPulse-1) then -- Sync
					vsync <= '0';
					red <= "00";
					green <= "00";
					blue <= "00";
				elsif (y < VFrontPorch+VSyncPulse+VBackPorch-1) then -- BackPorch
					vsync <= '1';
					red <= "00";
					green <= "00";
					blue <= "00";
				else -- Display
					vsync <= '1';
				end if;
				
				-- Horizontal
				if (x < HFrontPorch-1) then -- Front Porch
					hsync <= '1';
					red <= "00";
					green <= "00";
					blue <= "00";
				elsif (x < HFrontPorch+HSyncPulse-1) then -- Sync
					hsync <= '0';
					red <= "00";
					green <= "00";
					blue <= "00";
				elsif (x < HFrontPorch+HSyncPulse+HBackPorch-1) then -- BackPorch
					hsync <='1';
					red <= "00";
					green <= "00";
					blue <= "00";
				else -- Display
					hsync <='1';
				end if;
					
				--
				-- HIER WIRD GEZEICHNET
				--
				if(y >= VFrontPorch+VSyncPulse+VBackPorch-1 and x >= HFrontPorch+HSyncPulse+HBackPorch-1) then
						red <= "00";
						green <= "00";
						blue <= "00";
						
						if (x = HOffset + 50) then
							red <= "11";
							green <= "11";
							blue <= "11";
						end if;
				end if;
				
				--
				-- HIER WIRD GEZEICHNET
				--
			end if;
		end if;			
	end process;
end VgaImplementation;
