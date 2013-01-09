LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY vga_test IS
END vga_test;
 
ARCHITECTURE behavior OF vga_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT VgaCore
    PORT(
         clock : IN  std_logic;
         hsync : OUT  std_logic;
         vsync : OUT  std_logic;
         red : OUT  std_logic_vector(1 downto 0);
         green : OUT  std_logic_vector(1 downto 0);
         blue : OUT  std_logic_vector(1 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clock : std_logic := '0';

 	--Outputs
   signal hsync : std_logic;
   signal vsync : std_logic;
   signal red : std_logic_vector(1 downto 0);
   signal green : std_logic_vector(1 downto 0);
   signal blue : std_logic_vector(1 downto 0);

   -- Clock period definitions
   constant clock_period : time := 0.02 us;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: VgaCore PORT MAP (
          clock => clock,
          hsync => hsync,
          vsync => vsync,
          red => red,
          green => green,
          blue => blue
        );

   -- Clock process definitions
   clock_process :process
   begin
		clock <= '0';
		wait for clock_period/2;
		clock <= '1';
		wait for clock_period/2;
   end process;
 

   -- Stimulus process
--   stim_proc: process
--   begin		
      -- hold reset state for 100 ns.
--      wait for 100 ns;	

--      wait for clock_period*10;

      -- insert stimulus here 

--      wait;
--   end process;

END;
