library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VgaText;

-- Der VGA-Signal-Generator
entity VgaCore is
	port (
		clock : in   std_logic;

		hsync : out  std_logic;
		vsync : out  std_logic;

		red   : out  std_logic_vector(1 downto 0);
		green : out  std_logic_vector(1 downto 0);
		blue  : out  std_logic_vector(1 downto 0);
		
		-- Lesezugriff auf RAM
		ramAddress : out std_logic_vector(14 downto 0);
		ramData : in std_logic_vector(7 downto 0)
	);
end VgaCore;

architecture VgaImplementation of VgaCore is
	-- Spezifikation von VGA
	constant HFrontPorch : integer := 16;
	constant HSyncPulse 	: integer := 96;
	constant HBackPorch 	: integer := 48;
	constant HDisplay 	: integer := 640;
	constant HSize 		: integer := HFrontPorch + HSyncPulse + HBackPorch + HDisplay;
	constant HOffset 		: integer := HFrontPorch + HSyncPulse + HBackPorch;
	
	constant VFrontPorch : integer := 11;
	constant VSyncPulse 	: integer := 2;
	constant VBackPorch 	: integer := 31;
	constant VDisplay 	: integer := 480;
	constant VSize 		: integer := VFrontPorch + VSyncPulse + VBackPorch + VDisplay;
	constant VOffset 		: integer := VFrontPorch + VSyncPulse + VBackPorch;
	
	-- Zum Takt halbieren
	signal state : std_logic := '0';
	
	-- Position und Zoom
	signal startAddress : unsigned(14 downto 0) := to_unsigned(0, 15);
	signal skipPixel : integer range 1 to 100 := 1;
	
	-- Pixelkoordinaten
	type Point is
		record
			x : integer range 0 to HSize - 1;
			y : integer range 0 to VSize - 1;
		end record;
	
	-- Farbe eines Pixels
	type Color is
		record
			r : std_logic_vector(1 downto 0);
			g : std_logic_vector(1 downto 0);
			b : std_logic_vector(1 downto 0);
		end record;
	
	-- Farbkonstanten
	constant ColorBlack 			: Color := ("00", "00", "00");
	constant ColorBlue 			: Color := ("00", "00", "10");
	constant ColorGreen 			: Color := ("00", "10", "00");
	constant ColorCyan 			: Color := ("00", "10", "10");
	constant ColorRed 			: Color := ("10", "00", "00");
	constant ColorMagenta 		: Color := ("10", "00", "10");
	constant ColorBrown 			: Color := ("01", "01", "00");
	constant ColorLightGray 	: Color := ("10", "10", "10");
	constant ColorDarkGray 		: Color := ("01", "01", "01");
	constant ColorLightBlue 	: Color := ("00", "00", "11");
	constant ColorLightGreen 	: Color := ("00", "11", "00");
	constant ColorLightCyan 	: Color := ("00", "11", "11");
	constant ColorLightRed 		: Color := ("11", "00", "00");
	constant ColorLightMagenta	: Color := ("11", "00", "11");
	constant ColorYellow 		: Color := ("11", "11", "00");
	constant ColorWhite 			: Color := ("11", "11", "11");
	
	-- Aktuelle Position
	signal currentPos : Point := (0, 0);
begin
	-- Erzeugung des VGA-Signals.
	process(clock)
		-- Setzt ein Pixel.
		-- setPixel((x, y), [color]);
		procedure setPixel(
			constant p : Point;
			constant c : Color := ColorLightGray
		) is
		begin
			if (p.x + HOffset = currentPos.x and p.y + VOffset = currentPos.y) then
				red <= c.r;
				green <= c.g;
				blue <= c.b;
			end if;
		end setPixel;
	
		-- Zeichnet ein Zeichen.
		--	drawChar((x, y), 'A', [fc], [bc]);
		procedure drawChar(
			constant p : Point;
			constant char : character;
			constant foregroundColor : Color := ColorLightGray;
			constant backgroundColor : Color := ColorBlack
		) is
			variable pixels : VgaText.Letter := VgaText.getCharPixels(char);
		begin
			for i in 0 to 7 loop
				for j in 0 to 7 loop
					if (pixels(i)(j) = '1') then
						setPixel((p.x + j, p.y + i), foregroundColor);
					else
						setPixel((p.x + j, p.y + i), backgroundColor);
					end if;
				end loop;
			end loop;
		end drawChar;
		
		-- Zeichnet einen String.
		-- drawString((x, y), "String", [fc], [bc]);
		procedure drawString(
			constant p : Point;
			constant str : string;
			constant foregroundColor : Color := ColorLightGray;
			constant backgroundColor : Color := ColorBlack
		) is
		begin
			for i in 0 to str'length - 1 loop
				drawChar((p.x + 8 * i, p.y), str(i + 1), foregroundColor, backgroundColor);
			end loop;
		end drawString;
	
		-- Zeichnet eine Linie mit Start- und Endpunkt
		-- drawLine((startX, startY), (endeX, endeY), [color]);
		procedure drawLine(
			constant fromP : Point;
			constant toP : Point;
			constant c : Color := ColorLightGray
		) is
		begin
			assert (fromP.y = toP.y or fromP.x = toP.x)
				report "Die Funktion kann momentan nur waagrechte oder senkrechte Linien zeichnen!";
			
			if (fromP.y = toP.y) then
				if (fromP.y + VOffset = currentPos.y and fromP.x + HOffset <= currentPos.x and toP.x + HOffset >= currentPos.x) then
					red <= c.r;
					green <= c.g;
					blue <= c.b;
				end if;
				-- Synthese zu langsam
--				for i in fromP.x to toP.x loop
--					setPixel((i, fromP.y), c);
--				end loop;
			elsif (fromP.x = toP.x) then
				if (fromP.x + HOffset = currentPos.x and fromP.y + VOffset <= currentPos.y and toP.y + VOffset >= currentPos.y) then
					red <= c.r;
					green <= c.g;
					blue <= c.b;
				end if;
--				for i in fromP.y to toP.y loop
--					setPixel((fromP.x, i), c);
--				end loop;
			end if;
		end drawLine;
		
		-- Zeichnet ein Rechteck.
		-- drawRectangle((linksObenX, linksObenY), (rechtsUntenX, rechtsUntenY), [color]);
		procedure drawRectangle(
			constant upperLeft : Point;
			constant lowerRight : Point;
			constant c : Color := ColorLightGray
		) is
		begin
			drawLine(upperLeft, (lowerRight.x, upperLeft.y), c);
			drawLine(upperLeft, (upperLeft.x, lowerRight.y), c);
			drawLine((upperLeft.x, lowerRight.y), lowerRight, c);
			drawLine((lowerRight.x, upperLeft.y), lowerRight, c);
		end drawRectangle;
	begin
		if rising_edge(clock) then
			if state = '1' then
				state <= '0';
			else
				state <= '1';
				
				currentPos.x <= currentPos.x + 1;
				
				if (currentPos.x = HSize - 1) then 
					currentPos.x <= 0;
					currentPos.y <= currentPos.y + 1;
					
					if (currentPos.y = VSize - 1) then
						currentPos.y <= 0;
					end if;
				end if;
				
				red <= "00";
				green <= "00";
				blue <= "00";
				
				-- Vertikal
				if (currentPos.y < VFrontPorch - 1) then -- Front Porch
					vsync <= '1';
				elsif (currentPos.y < VFrontPorch + VSyncPulse - 1) then -- Sync
					vsync <= '0';
				elsif (currentPos.y < VOffset - 1) then -- Back Porch
					vsync <= '1';
				else -- Display
					vsync <= '1';
				end if;
				
				-- Horizontal
				if (currentPos.x < HFrontPorch - 1) then -- Front Porch
					hsync <= '1';
				elsif (currentPos.x < HFrontPorch + HSyncPulse - 1) then -- Sync
					hsync <= '0';
				elsif (currentPos.x < HOffset - 1) then -- Back Porch
					hsync <= '1';
				else -- Display
					hsync <= '1';
				end if;
					
				--
				-- HIER WIRD GEZEICHNET
				--
				if(currentPos.y >= VOffset - 1 and currentPos.x >= HOffset - 1) then
						-- Hier habe ich jetzt mal einen Vorschlag fr einen Bildschirm programmiert, ich denke,
						-- wir knnen das erst mal so lassen, evtl. noch wo anders hin auslagern.
						
						-- Begrenzung der einzelnen Kanle
						drawRectangle((4, 4), (635, 420));
						
						-- Senkrechte Striche fr Zeit
						drawLine((80, 20), (80, 400));						
						drawLine((130, 20), (130, 400), ColorDarkGray);
						drawLine((180, 20), (180, 400), ColorDarkGray);
						drawLine((230, 20), (230, 400), ColorDarkGray);
						drawLine((280, 20), (280, 400), ColorDarkGray);
						drawLine((330, 20), (330, 400), ColorDarkGray);
						drawLine((380, 20), (380, 400), ColorDarkGray);
						drawLine((430, 20), (430, 400), ColorDarkGray);
						drawLine((480, 20), (480, 400), ColorDarkGray);
						drawLine((530, 20), (530, 400), ColorDarkGray);
						drawLine((580, 20), (580, 400), ColorDarkGray);
							
						-- Acht Striche fr die Kanle
						drawLine((20, 50), (620, 50));
						drawLine((20, 100), (620, 100));
						drawLine((20, 150), (620, 150));
						drawLine((20, 200), (620, 200));
						drawLine((20, 250), (620, 250));
						drawLine((20, 300), (620, 300));
						drawLine((20, 350), (620, 350));
						drawLine((20, 400), (620, 400));
						
						-- Infobox unten
						drawRectangle((4, 430), (635, 475));
						
						-- Test
						--setPixel((10, 60));
						--drawChar((20, 80), 'A');
						--drawString((120, 20), "0123456789ABCDEFGHIJKLMN");
						
						-- Kanalbeschriftungen
--						drawString((20, 55), "KANAL 1", ColorLightGray);
--						drawString((20, 105), "KANAL 2", ColorDarkGray);
--						drawString((20, 155), "KANAL 3", ColorLightBlue);
--						drawString((20, 205), "KANAL 4", ColorLightGreen);
--						drawString((20, 255), "KANAL 5", ColorLightCyan);
--						drawString((20, 305), "KANAL 6", ColorLightRed);
--						drawString((20, 355), "KANAL 7", ColorLightMagenta);
--						drawString((20, 405), "KANAL 8", ColorYellow);
--						
						-- Werte anzeigen
						if currentPos.x > 80 + HOffset and currentPos.x < 620 + HOffset then
							-- Nur zum Testen, damit man auch was sieht.
							ramAddress <= std_logic_vector(startAddress + skipPixel * (currentPos.x - 80));
							-- ist das wirklich das, was wir wollen?
							-- momentan erzeugt das merkwrdige Ausgaben, vor allem sind die Abstnde
							-- berhaupt nicht mehr gleichmig.
							
							--ramAddress <= std_logic_vector(to_unsigned(currentPos.x - 80, 15));

							-- Einzelne Kanle malen.
							if (currentPos.y = 25 + VOffset) then
								if (ramData(0) = '1') then
									setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorRed);
								end if;
							end if;
							
							if (currentPos.y = 40 + VOffset) then
								if (ramData(0) = '0') then
									setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorGreen);
								end if;
							end if;
							
							
							if (currentPos.y = 25 + 50 + VOffset) then
								if (ramData(1) = '1') then
									setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorRed);
								end if;
							end if;
							
							if (currentPos.y = 40 + 50 + VOffset) then
								if (ramData(1) = '0') then
									setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorGreen);
								end if;
							end if;
							
							
							if (currentPos.y = 25 + 100 + VOffset) then
								if (ramData(2) = '1') then
									setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorRed);
								end if;
							end if;
							
							if (currentPos.y = 40 + 100 + VOffset) then
								if (ramData(2) = '0') then
									setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorGreen);
								end if;
							end if;
							
							
							if (currentPos.y = 25 + 150 + VOffset) then
								if (ramData(3) = '1') then
									setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorRed);
								end if;
							end if;
							
							if (currentPos.y = 40 + 150 + VOffset) then
								if (ramData(3) = '0') then
									setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorGreen);
								end if;
							end if;
							
							
							if (currentPos.y = 25 + 200 + VOffset) then
								if (ramData(4) = '1') then
									setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorRed);
								end if;
							end if;
							
							if (currentPos.y = 40 + 200 + VOffset) then
								if (ramData(4) = '0') then
									setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorGreen);
								end if;
							end if;
							
							
							if (currentPos.y = 25 + 250 + VOffset) then
								if (ramData(5) = '1') then
									setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorRed);
								end if;
							end if;
							
							if (currentPos.y = 40 + 250 + VOffset) then
								if (ramData(5) = '0') then
									setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorGreen);
								end if;
							end if;
							
							if (currentPos.y = 25 + 300 + VOffset) then
								if (ramData(6) = '1') then
									setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorRed);
								end if;
							end if;
							
							if (currentPos.y = 40 + 300 + VOffset) then
								if (ramData(6) = '0') then
									setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorGreen);
								end if;
							end if;
							
							
							if (currentPos.y = 25 + 350 + VOffset) then
								if (ramData(7) = '1') then
									setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorRed);
								end if;
							end if;
							
							if (currentPos.y = 40 + 350 + VOffset) then
								if (ramData(7) = '0') then
									setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorGreen);
								end if;
							end if;
						end if;
				end if;
				--
				-- HIER WIRD GEZEICHNET
				--
			end if;
		end if;			
	end process;
end VgaImplementation;
