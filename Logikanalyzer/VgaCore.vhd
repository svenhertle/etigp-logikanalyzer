library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VgaText.all;
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
		
		-- Zugriff auf das Character ROM
		charAddress : out character;
		charData : in Letter;
		
		-- Status
		smState : in State;
		menuState : in Menu;
		samplingMode : in SamplingMode;
		samplingRate : in SamplingRate;
		triggerOn : in boolean;
		triggerState : in AllTriggers
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

	type CharRamT is array(integer range 0 to 79, integer range 0 to 59) of character;
	signal charRam : CharRamT;
	
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
			constant char : character
			--constant foregroundColor : Color := ColorLightGray;
			--constant backgroundColor : Color := ColorBlack
		) is
		begin
			charRam(p.x, p.y) <= char;
		end drawChar;
		
		-- Zeichnet einen String.
		-- drawString((x, y), "String", [fc], [bc]);
		procedure drawString(
			constant p : Point;
			constant str : string
			--constant foregroundColor : Color := ColorLightGray;
			--constant backgroundColor : Color := ColorBlack
		) is
		begin
			for i in 0 to str'length - 1 loop
				drawChar((p.x + i, p.y), str(i + 1));--, foregroundColor, backgroundColor);
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
						drawRectangle((7, 7), (631, 400));
						
						-- Senkrechte Striche fuer Zeit
						drawLine((80, 16), (80, 392));						
--						drawLine((130, 16), (130, 392), ColorDarkGray);
--						drawLine((180, 16), (180, 392), ColorDarkGray);
--						drawLine((230, 16), (230, 392), ColorDarkGray);
--						drawLine((280, 16), (280, 392), ColorDarkGray);
--						drawLine((330, 16), (330, 392), ColorDarkGray);
--						drawLine((380, 16), (380, 392), ColorDarkGray);
--						drawLine((430, 16), (430, 392), ColorDarkGray);
--						drawLine((480, 16), (480, 392), ColorDarkGray);
--						drawLine((530, 16), (530, 392), ColorDarkGray);
--						drawLine((580, 16), (580, 392), ColorDarkGray);
							
						for i in 1 to 5 loop
							drawLine((80 + i * 91, 16), (80 + i * 91, 392), ColorDarkGray);
						end loop;
							
						-- Acht Striche fuer die Kanaele
						for i in 1 to 8 loop
							drawLine((16, 48*i+8), (623, 48*i+8));
						end loop;
						
						-- Kanalbeschriftung
						drawString((2, 3), "1");
						drawString((2, 9), "2");
						drawString((2, 15), "3");
						drawString((2, 21), "4");
						drawString((2, 27), "5");
						drawString((2, 33), "6");
						drawString((2, 39), "7");
						drawString((2, 45), "8");
												
						-- Trigger
						for i  in 0 to 7 loop
							case triggerState(i) is
								when High =>
									drawString((2, 5+i*6), "HIGH   ");
								when Low =>
									drawString((2, 5+i*6), "LOW    ");
								when Rising =>
									drawString((2, 5+i*6), "RISING ");
								when Falling =>
									drawString((2, 5+i*6), "FALLING");
								when others =>
							end case;
						end loop;
											
						-- Status
						drawRectangle((7,416),(110,472));
						case smState is
							when Start =>
								drawString((3, 55), "WAIT  "); -- WAIT
							when StartRunning | Running =>
									drawString((3, 55), "RECORD"); -- RECORD
							when View =>
								drawString((3, 55), "VIEW  "); -- VIEW
							when Stopped =>
								drawString((3, 55), "STOP  "); -- STOP
							when others =>
						end case;
						
						-- Sampling Mode
						if menuState = MSamplingMode then
							drawRectangle((111,416),(203,472), ColorRed);
						else
							drawRectangle((111,416),(203,472));
						end if;
						
						drawString((13, 54), "MODE"); -- MODE
						case samplingMode is
							when OneShot =>
								drawString((14, 56), "ONESHOT"); -- ONESHOT
							when Continuous =>
									drawString((14, 56), "CONT   "); -- CONT
							when others =>
						end case;
						
						-- Sampling Rate
						if menuState = MSamplingRate then
							drawRectangle((204,430),(303,475), ColorRed);
						else
							drawRectangle((204,430),(303,475));
						end if;
						
						drawString((26, 54), "SAMP RATE"); -- SAMP.RATE
						case samplingRate is
							when s1 =>
								drawString((27, 56), "1S   ");
							when ms100 =>
								drawString((27, 56), "100MS");
							when ms10 =>
								drawString((27, 56), "10MS ");
							when ms1 =>
								drawString((27, 56), "1MS  ");
							when Max =>
								drawString((27, 56), "MAX  ");
							when others =>
						end case;
						
						-- Trigger
						if menuState = MTriggerOn then
							drawRectangle((304,430),(403,475), ColorRed);
						else
							drawRectangle((304,430),(403,475));
						end if;
						
						drawString((40, 54), "TRIGGER"); -- TRIGGER
						if triggerOn then
							drawString((41, 56), "ON "); -- ON
						else
							drawString((41, 56), "OFF"); -- OFF
						end if;					
						
						
						-- Adresse des nächsten Pixels an den charRam schicken.
						charAddress <= charRam((currentPos.x + 1 - HOffset) / 8,(currentPos.y - VOffset) / 8);
						
						-- Pixel setzen, wenn Schriftzeichen an der Stelle.
						if (charData((currentPos.y - VOffset) mod 8)((currentPos.x - HOffset) mod 8) = '1') then
							setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorWhite);
						end if;
												

						-- Werte anzeigen
						if currentPos.x > 80 + HOffset and currentPos.x < 623 + HOffset then
							-- Einzelne Kanaele malen.
							for i in 0 to 7 loop
								-- High
								if (currentPos.y = 24 + i * 48 + VOffset) then
									if (ramData(i) = '1') then
										setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorYellow);
									end if;
								end if;
								
								-- Low
								if (currentPos.y = 48 + i * 48 + VOffset) then
									if (ramData(i) = '0') then
										setPixel((currentPos.x - HOffset, currentPos.y - VOffset), ColorYellow);
									end if;
								end if;
								
								-- Flanken
								for j in 24 to 48 loop
									if (currentPos.y = j + i * 48 + VOffset) then
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
