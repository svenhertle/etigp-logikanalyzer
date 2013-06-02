library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VgaText;
use work.GlobalTypes.all;

entity Trigger is
    port (
		start : out  std_logic;
		
		state : in AllTriggers;
		
		current_data : in std_logic_vector(7 downto 0);
		last_data : in std_logic_vector(7 downto 0)
	);
end Trigger;

architecture TriggerImplementation of Trigger is
	signal start_intern : std_logic := '0';
	signal start_channels : std_logic_vector(7 downto 0);
begin
	start <= start_intern;
	
	process(current_data)
	begin
		-- Jeden Kanal überprüfen
		for i in 0 to 7 loop
			case state(i) is
				when Off =>
					start_channels(i) <= '1';
				when High =>
					start_channels(i) <= current_data(i);
				when Low =>
					start_channels(i) <= not current_data(i);
				when Rising =>
					start_channels(i) <= current_data(i) and not last_data(i);
				when Falling =>
					start_channels(i) <= not current_data(i) and last_data(i);
			end case;
		end loop;
		
		start_intern <= start_channels(0) and 
							 start_channels(1) and 
							 start_channels(2) and
							 start_channels(3) and
							 start_channels(4) and
							 start_channels(5) and
							 start_channels(6) and
							 start_channels(7);
	end process;
end TriggerImplementation;
