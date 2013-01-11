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
	
	-- Für die Zeichenmethoden
	type Point is
		record
			x : integer range 0 to HSize - 1;
			y : integer range 0 to VSize - 1;
		end record;
	
	type Color is
		record
			r : std_logic_vector(1 downto 0);
			g : std_logic_vector(1 downto 0);
			b : std_logic_vector(1 downto 0);
		end record;
	
	constant ColorBlack : Color := ("00", "00", "00");
	constant ColorBlue : Color := ("00", "00", "10");
	constant ColorGreen : Color := ("00", "10", "00");
	constant ColorCyan : Color := ("00", "10", "10");
	constant ColorRed : Color := ("10", "00", "00");
	constant ColorMagenta : Color := ("10", "00", "10");
	constant ColorBrown : Color := ("01", "01", "00");
	constant ColorLightGray : Color := ("10", "10", "10");
	constant ColorDarkGray : Color := ("01", "01", "01");
	constant ColorLightBlue : Color := ("00", "00", "11");
	constant ColorLightGreen : Color := ("00", "11", "00");
	constant ColorLightCyan : Color := ("00", "11", "11");
	constant ColorLightRed : Color := ("11", "00", "00");
	constant ColorLightMagenta : Color := ("11", "00", "11");
	constant ColorYellow : Color := ("11", "11", "00");
	constant ColorWhite : Color := ("11", "11", "11");
	
	-- Aktuelle Position
	signal currentPos : Point := (0, 0);
	
	type Letter is array (0 to 7) of bit_vector(0 to 7);
	type Font is array (0 to 24) of Letter;

	constant fnt : Font := (
		(	-- ' '
			"00000000",
			"00000000",
			"00000000",
			"00000000",
			"00000000",
			"00000000",
			"00000000",
			"00000000"
		),
		(	-- 0
			"00111000",
			"01101100",
			"11000110",
			"11010110",
			"11000110",
			"01101100",
			"00111000",
			"00000000"
		),
		(	-- 1
			"00011000",
			"00111000",
			"00011000",
			"00011000",
			"00011000",
			"00011000",
			"01111110",
			"00000000"
		),
		(	-- 2
			"01111100",
			"11000110",
			"00000110",
			"00011100",
			"00110000",
			"01100110",
			"11111110",
			"00000000"
		),
		(	-- 3
			"01111100",
			"11000110",
			"00000110",
			"00111100",
			"00000110",
			"11000110",
			"01111100",
			"00000000"
		),
		(	-- 4
			"00011100",
			"00111100",
			"01101100",
			"11001100",
			"11111110",
			"00001100",
			"00011110",
			"00000000"
		),
		(	-- 5
			"11111110",
			"11000000",
			"11000000",
			"11111100",
			"00000110",
			"11000110",
			"01111100",
			"00000000"
		),
		(	-- 6
			"00111000",
			"01100000",
			"11000000",
			"11111100",
			"11000110",
			"11000110",
			"01111100",
			"00000000"
		),
		(	-- 7
			"11111110",
			"11000110",
			"00001100",
			"00011000",
			"00110000",
			"00110000",
			"00110000",
			"00000000"
		),
		(	-- 8
			"01111100",
			"11000110",
			"11000110",
			"01111100",
			"11000110",
			"11000110",
			"01111100",
			"00000000"
		),
		(	-- 9
			"01111100",
			"11000110",
			"11000110",
			"01111110",
			"00000110",
			"00001100",
			"01111000",
			"00000000"
		),
		(	-- A
			"00111000",
			"01101100",
			"11000110",
			"11111110",
			"11000110",
			"11000110",
			"11000110",
			"00000000"
		),
		(	-- B
			"11111100",
			"01100110",
			"01100110",
			"01111100",
			"01100110",
			"01100110",
			"11111100",
			"00000000"
		),
		(	-- C
			"00111100",
			"01100110",
			"11000000",
			"11000000",
			"11000000",
			"01100110",
			"00111100",
			"00000000"
		),
		(
			"11111000",
			"01101100",
			"01100110",
			"01100110",
			"01100110",
			"01101100",
			"11111000",
			"00000000"
		),
		(
			"11111110",
			"01100010",
			"01101000",
			"01111000",
			"01101000",
			"01100010",
			"11111110",
			"00000000"
		),
		(
			"11111110",
			"01100010",
			"01101000",
			"01111000",
			"01101000",
			"01100000",
			"11110000",
			"00000000"
		),
		(
			"00111100",
			"01100110",
			"11000000",
			"11000000",
			"11001110",
			"01100110",
			"00111010",
			"00000000"
		),
		(
			"11000110",
			"11000110",
			"11000110",
			"11111110",
			"11000110",
			"11000110",
			"11000110",
			"00000000"
		),
		(
			"00111100",
			"00011000",
			"00011000",
			"00011000",
			"00011000",
			"00011000",
			"00111100",
			"00000000"
		),
		(
			"00011110",
			"00001100",
			"00001100",
			"00001100",
			"11001100",
			"11001100",
			"01111000",
			"00000000"
		),
		(
			"11100110",
			"01100110",
			"01101100",
			"01111000",
			"01101100",
			"01100110",
			"11100110",
			"00000000"
		),
		(
			"11110000",
			"01100000",
			"01100000",
			"01100000",
			"01100010",
			"01100110",
			"11111110",
			"00000000"
		),
		(
			"11000110",
			"11101110",
			"11111110",
			"11111110",
			"11010110",
			"11000110",
			"11000110",
			"00000000"
		),
		(	-- N
			"11000110",
			"11100110",
			"11110110",
			"11011110",
			"11001110",
			"11000110",
			"11000110",
			"00000000"
		)
	);
	
begin
	-- Erzeugung des VGA-Signals.
	process(clock)
		function getCharPixels(
			constant char : character
		) return Letter is
		begin
			--assert (char >= 'A' and char <= 'C')
			--	report "Character not implemented.";
		
			if (char >= '0' and char <= '9') then
				return fnt(character'pos(char) - 48 + 1);
			end if;
		
			if (char >= 'A' and char <= 'N') then
				return fnt(character'pos(char) - 65 + 10 + 1);
			elsif (char = ' ') then
				return fnt(0);
			else
				return fnt(0); -- leerzeichen
			end if;
		end getCharPixels;
	
		-- Funktion zum Setzen eines Pixels.
		-- Aufruf:
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
	
		procedure drawChar(
			constant p : Point;
			constant char : character;
			constant c : Color := ColorLightGray
		) is
			variable pixels : Letter := getCharPixels(char);
		begin
			for i in 0 to 7 loop
				for j in 0 to 7 loop
					if (pixels(i)(j) = '1') then
						setPixel((p.x + j, p.y + i), c);
					end if;
				end loop;
			end loop;
		end drawChar;
		
		procedure drawString(
			constant p : Point;
			constant str : string;
			constant c : Color := ColorLightGray
		) is
		begin
			for i in 0 to str'length - 1 loop
				drawChar((p.x + 8 * i, p.y), str(i + 1), c);
			end loop;
		end drawString;
	
		-- Funktion zum Zeichnen einer Linie mit Start- und Endpunkt
		-- Aufruf:
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
			elsif (fromP.x = toP.x) then
				if (fromP.x + HOffset = currentPos.x and fromP.y + VOffset <= currentPos.y and toP.y + VOffset >= currentPos.y) then
					red <= c.r;
					green <= c.g;
					blue <= c.b;
				end if;
			end if;
		end drawLine;
		
		-- Funktion zum Zeichnen eines Rechtecks.
		-- Aufruf:
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
				elsif (currentPos.y < VFrontPorch + VSyncPulse + VBackPorch - 1) then -- Back Porch
					vsync <= '1';
				else -- Display
					vsync <= '1';
				end if;
				
				-- Horizontal
				if (currentPos.x < HFrontPorch - 1) then -- Front Porch
					hsync <= '1';
				elsif (currentPos.x < HFrontPorch + HSyncPulse - 1) then -- Sync
					hsync <= '0';
				elsif (currentPos.x < HFrontPorch + HSyncPulse + HBackPorch - 1) then -- Back Porch
					hsync <= '1';
				else -- Display
					hsync <= '1';
				end if;
					
				--
				-- HIER WIRD GEZEICHNET
				--
				if(currentPos.y >= VFrontPorch + VSyncPulse + VBackPorch - 1 and currentPos.x >= HFrontPorch + HSyncPulse + HBackPorch - 1) then
						-- Hier habe ich jetzt mal einen Vorschlag für einen Bildschirm programmiert, ich denke,
						-- wir können das erst mal so lassen, evtl. noch wo anders hin auslagern.
						
						-- Begrenzung der einzelnen Kanäle
						drawRectangle((4, 4), (635, 420));
						
						-- Acht Striche für die Kanäle
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
						drawString((20, 55), "KANAL 1", ColorLightGray);
						drawString((20, 105), "KANAL 2", ColorDarkGray);
						drawString((20, 155), "KANAL 3", ColorLightBlue);
						drawString((20, 205), "KANAL 4", ColorLightGreen);
						drawString((20, 255), "KANAL 5", ColorLightCyan);
						drawString((20, 305), "KANAL 6", ColorLightRed);
						drawString((20, 355), "KANAL 7", ColorLightMagenta);
						drawString((20, 405), "KANAL 8", ColorYellow);
				end if;
				--
				-- HIER WIRD GEZEICHNET
				--
			end if;
		end if;			
	end process;
end VgaImplementation;
