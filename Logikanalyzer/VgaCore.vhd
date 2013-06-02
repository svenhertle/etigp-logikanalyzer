library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VgaText;
use work.GlobalTypes.all;

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
		ramData : in std_logic_vector(7 downto 0);
		
		-- Steuerung der Anzeige
		startAddress : in integer;
		zoomFactor : in integer;
		
		-- Status
		smState : in State;
		menuState : in Menu;
		samplingMode : in SamplingMode;
		samplingRate : in SamplingRate
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
	
	-- Die zuletzt gezeichneten Samples; benoetigt fr die steigenden
	-- und fallenden Flanken (= Unterschiedserkennung)
	signal oldData : std_logic_vector(7 downto 0);
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
					-- weglassen spart 50 % Platz; wenn benoetigt,
					-- mit if /= Black wieder einbauen.
					--else
					--	setPixel((p.x + j, p.y + i), backgroundColor);
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
				
				-- Naechste Speicheradresse berechnen
				ramAddress <= std_logic_vector(to_unsigned(startAddress + (currentPos.x - 80) * zoomFactor, 15));
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
						-- Begrenzung der einzelnen Kanaele
						drawRectangle((4, 4), (635, 420));
						
						-- Senkrechte Striche fuer Zeit
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
							
						-- Acht Striche fuer die Kanaele
						drawLine((20, 50), (620, 50));
						drawLine((20, 100), (620, 100));
						drawLine((20, 150), (620, 150));
						drawLine((20, 200), (620, 200));
						drawLine((20, 250), (620, 250));
						drawLine((20, 300), (620, 300));
						drawLine((20, 350), (620, 350));
						drawLine((20, 400), (620, 400));
						
						-- Infobox unten
						--drawRectangle((4, 430), (635, 475));
						
						-- Status
						drawRectangle((4,430),(103,475));
						case smState is
							when Start =>
								drawString((15, 450), "W"); -- WAIT
							when StartRunning | Running =>
									drawString((15, 450), "R"); -- RECORD
							when View =>
								drawString((15, 450), "V"); -- VIEW
							when Stopped =>
								drawString((15, 450), "S"); -- STOP
							when others =>
						end case;
						
						-- Sampling Mode
						if menuState = MSamplingMode then
							drawRectangle((104,430),(203,475), ColorRed);
						else
							drawRectangle((104,430),(203,475));
						end if;
						
						drawString((108, 436), "M"); -- MODE
						case samplingMode is
							when OneShot =>
								drawString((115, 450), "O"); -- ONESHOT
							when Continuous =>
									drawString((115, 450), "C"); -- CONT
							when others =>
						end case;
						
						-- Sampling Rate
						if menuState = MSamplingRate then
							drawRectangle((204,430),(303,475), ColorRed);
						else
							drawRectangle((204,430),(303,475));
						end if;
						
						drawString((208, 436), "S"); -- SAMP.RATE
						case samplingRate is
							when s1 =>
								drawString((215, 450), "1S");
							when ms100 =>
								drawString((215, 450), "100MS");
							when ms10 =>
								drawString((215, 450), "10MS");
							when ms1 =>
								drawString((215, 450), "1MS");
							when Max =>
								drawString((215, 450), "MAX");
							when others =>
						end case;
						
						-- Kanalbeschriftungen
						drawString((20, 55), "1");
						drawString((20, 105), "2");
						drawString((20, 155), "3");
						drawString((20, 205), "4");
						drawString((20, 255), "5");
						drawString((20, 305), "6");
						drawString((20, 355), "7");
						drawString((20, 405), "8");
						

						-- Werte anzeigen
						if currentPos.x > 80 + HOffset and currentPos.x < 620 + HOffset then
							-- Einzelne Kanaele malen.
							for i in 0 to 7 loop
								-- High
								if (currentPos.y = 25 + i * 50 + VOffset) then
									if (ramData(i) = '1') then
										setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorYellow);
									end if;
								end if;
								
								-- Low
								if (currentPos.y = 40 + i * 50 + VOffset) then
									if (ramData(i) = '0') then
										setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorYellow);
									end if;
								end if;
								
								-- Flanken
								-- ggf. auskommentieren fuer schnellere Synthese.
								for j in 25 to 40 loop
									if (currentPos.y = j + i * 50 + VOffset) then
										if (oldData(i) /= ramData(i)) then
											setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorYellow);
										end if;
									end if;
								end loop;
							end loop;
						end if;
						
						oldData <= ramData;
				end if;
				--
				-- HIER WIRD GEZEICHNET
				--
			end if;
		end if;			
	end process;
end VgaImplementation;
