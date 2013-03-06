package VgaText is
	type Letter is array (0 to 7) of bit_vector(0 to 7);
	type Font is array (32 to 90) of Letter;

	-- Source: https://github.com/torvalds/linux/blob/master/drivers/video/console/font_8x8.c
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
		(	-- '!'
			"00011000",
			"00111100",
			"00111100",
			"00011000",
			"00011000",
			"00000000",
			"00011000",
			"00000000"
		),
		(
			"01100110",
			"01100110",
			"00100100",
			"00000000",
			"00000000",
			"00000000",
			"00000000",
			"00000000"
		),
		(
			"01101100",
			"01101100",
			"11111110",
			"01101100",
			"11111110",
			"01101100",
			"01101100",
			"00000000"
		),
		(
			"00011000",
			"00111110",
			"01100000",
			"00111100",
			"00000110",
			"01111100",
			"00011000",
			"00000000"
		),
		(
			"00000000",
			"11000110",
			"11001100",
			"00011000",
			"00110000",
			"01100110",
			"11000110",
			"00000000"
		),
		(
			"00111000",
			"01101100",
			"00111000",
			"01110110",
			"11011100",
			"11001100",
			"01110110",
			"00000000"
		),
		(
			"00011000",
			"00011000",
			"00110000",
			"00000000",
			"00000000",
			"00000000",
			"00000000",
			"00000000"
		),
		(
			"00001100",
			"00011000",
			"00110000",
			"00110000",
			"00110000",
			"00011000",
			"00001100",
			"00000000"
		),
		(
			"00110000",
			"00011000",
			"00001100",
			"00001100",
			"00001100",
			"00011000",
			"00110000",
			"00000000"
		),
		(
			"00000000",
			"01100110",
			"00111100",
			"11111111",
			"00111100",
			"01100110",
			"00000000",
			"00000000"
		),
		(
			"00000000",
			"00011000",
			"00011000",
			"01111110",
			"00011000",
			"00011000",
			"00000000",
			"00000000"
		),
		(
			"00000000",
			"00000000",
			"00000000",
			"00000000",
			"00000000",
			"00011000",
			"00011000",
			"00110000"
		),
		(
			"00000000",
			"00000000",
			"00000000",
			"01111110",
			"00000000",
			"00000000",
			"00000000",
			"00000000"
		),
		(
			"00000000",
			"00000000",
			"00000000",
			"00000000",
			"00000000",
			"00011000",
			"00011000",
			"00000000"
		),
		(
			"00000110",
			"00001100",
			"00011000",
			"00110000",
			"01100000",
			"11000000",
			"10000000",
			"00000000"
		),
		(	-- '0'
			"00111000",
			"01101100",
			"11000110",
			"11010110",
			"11000110",
			"01101100",
			"00111000",
			"00000000"
		),
		(
			"00011000",
			"00111000",
			"00011000",
			"00011000",
			"00011000",
			"00011000",
			"01111110",
			"00000000"
		),
		(
			"01111100",
			"11000110",
			"00000110",
			"00011100",
			"00110000",
			"01100110",
			"11111110",
			"00000000"
		),
		(
			"01111100",
			"11000110",
			"00000110",
			"00111100",
			"00000110",
			"11000110",
			"01111100",
			"00000000"
		),
		(
			"00011100",
			"00111100",
			"01101100",
			"11001100",
			"11111110",
			"00001100",
			"00011110",
			"00000000"
		),
		(
			"11111110",
			"11000000",
			"11000000",
			"11111100",
			"00000110",
			"11000110",
			"01111100",
			"00000000"
		),
		(
			"00111000",
			"01100000",
			"11000000",
			"11111100",
			"11000110",
			"11000110",
			"01111100",
			"00000000"
		),
		(
			"11111110",
			"11000110",
			"00001100",
			"00011000",
			"00110000",
			"00110000",
			"00110000",
			"00000000"
		),
		(
			"01111100",
			"11000110",
			"11000110",
			"01111100",
			"11000110",
			"11000110",
			"01111100",
			"00000000"
		),
		(
			"01111100",
			"11000110",
			"11000110",
			"01111110",
			"00000110",
			"00001100",
			"01111000",
			"00000000"
		),
		(	-- ':'
			"00000000",
			"00011000",
			"00011000",
			"00000000",
			"00000000",
			"00011000",
			"00011000",
			"00000000"
		),
		(
			"00000000",
			"00011000",
			"00011000",
			"00000000",
			"00000000",
			"00011000",
			"00011000",
			"00110000"
		),
		(
			"00000110",
			"00001100",
			"00011000",
			"00110000",
			"00011000",
			"00001100",
			"00000110",
			"00000000"
		),
		(
			"00000000",
			"00000000",
			"01111110",
			"00000000",
			"00000000",
			"01111110",
			"00000000",
			"00000000"
		),
		(
			"01100000",
			"00110000",
			"00011000",
			"00001100",
			"00011000",
			"00110000",
			"01100000",
			"00000000"
		),
		(
			"01111100",
			"11000110",
			"00001100",
			"00011000",
			"00011000",
			"00000000",
			"00011000",
			"00000000"
		),
		(
			"01111100",
			"11000110",
			"11011110",
			"11011110",
			"11011110",
			"11000000",
			"01111000",
			"00000000"
		),
		(	-- 'A'
			"00111000",
			"01101100",
			"11000110",
			"11111110",
			"11000110",
			"11000110",
			"11000110",
			"00000000"
		),
		(	-- 'B'
			"11111100",
			"01100110",
			"01100110",
			"01111100",
			"01100110",
			"01100110",
			"11111100",
			"00000000"
		),
		(
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
		(
			"11000110",
			"11100110",
			"11110110",
			"11011110",
			"11001110",
			"11000110",
			"11000110",
			"00000000"
		),
		(
			"01111100",
			"11000110",
			"11000110",
			"11000110",
			"11000110",
			"11000110",
			"01111100",
			"00000000"
		),
		(
			"11111100",
			"01100110",
			"01100110",
			"01111100",
			"01100000",
			"01100000",
			"11110000",
			"00000000"
		),
		(
			"01111100",
			"11000110",
			"11000110",
			"11000110",
			"11000110",
			"11001110",
			"01111100",
			"00001110"
		),
		(
			"11111100",
			"01100110",
			"01100110",
			"01111100",
			"01101100",
			"01100110",
			"11100110",
			"00000000"
		),
		(
			"00111100",
			"01100110",
			"00110000",
			"00011000",
			"00001100",
			"01100110",
			"00111100",
			"00000000"
		),
		(
			"01111110",
			"01111110",
			"01011010",
			"00011000",
			"00011000",
			"00011000",
			"00111100",
			"00000000"
		),
		(
			"11000110",
			"11000110",
			"11000110",
			"11000110",
			"11000110",
			"11000110",
			"01111100",
			"00000000"
		),
		(
			"11000110",
			"11000110",
			"11000110",
			"11000110",
			"11000110",
			"01101100",
			"00111000",
			"00000000"
		),
		(
			"11000110",
			"11000110",
			"11000110",
			"11010110",
			"11010110",
			"11111110",
			"01101100",
			"00000000"
		),
		(
			"11000110",
			"11000110",
			"01101100",
			"00111000",
			"01101100",
			"11000110",
			"11000110",
			"00000000"
		),
		(
			"01100110",
			"01100110",
			"01100110",
			"00111100",
			"00011000",
			"00011000",
			"00111100",
			"00000000"
		),
		(
			"11111110",
			"11000110",
			"10001100",
			"00011000",
			"00110010",
			"01100110",
			"11111110",
			"00000000"
		)
	);

	-- Ermittelt das zu einem Zeichen gehoerende 8x8-Array.
	function getCharPixels(
		constant char : character
	) return Letter;
end VgaText;

package body VgaText is
	function getCharPixels(
		constant char : character
	) return Letter is
	begin
		return fnt(character'pos(char));
	end getCharPixels;
end VgaText;
