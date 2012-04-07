--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   20:33:37 03/28/2012
-- Design Name:   
-- Module Name:   C:/Users/Brian/Documents/Xilnix/vgaDemo/vgaDemo_tb.vhd
-- Project Name:  vgaDemo
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: vgaDemo
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY vgaDemo_tb IS
END vgaDemo_tb;
 
ARCHITECTURE behavior OF vgaDemo_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT vgaDemo
    PORT(
         clk_i : IN  std_logic;
         rstLow_i : IN  std_logic;
         
         spiSsel_i : in   std_logic;
         spiSck_i  : in   std_logic;
         spiMosi_i : in   std_logic;
         spiMiso_o : out  std_logic;

--         led_o     : out  std_logic;

         hSync_o : OUT  std_logic;
         vSync_o : OUT  std_logic;
         r_o : OUT  std_logic;
         g_o : OUT  std_logic;
         b_o : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk_i : std_logic := '0';
   signal rst_i : std_logic := '1';

 	--Outputs
   signal hSync_o : std_logic;
   signal vSync_o : std_logic;
   signal r_o : std_logic;
   signal g_o : std_logic;
   signal b_o : std_logic;

   signal spiStart : std_logic := '0';
   signal spiSsel  : std_logic := '1';
   signal spiSck   : std_logic := '0';
   signal spiMosi  : std_logic := '0';

   signal sendData : std_logic_vector(7 downto 0);
   signal data     : std_logic_vector(7 downto 0) := (others => '0');
   
   -- Clock period definitions
   constant clk_i_period : time := 31.125 ns;
   constant SPI_PERIOD   : time := 50.000 ns;
   
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: vgaDemo PORT MAP (
          clk_i     => clk_i,
          rstLow_i  => rst_i,
          spiSsel_i => spiSsel,
          spiSck_i  => spiSck,
          spiMosi_i => data(7),
          spiMiso_o => open,
--          led_o     => open,
          hSync_o   => hSync_o,
          vSync_o   => vSync_o,
          r_o       => r_o,
          g_o       => g_o,
          b_o       => b_o
        );

   -- Clock process definitions
   clk_i_process :process
   begin
		clk_i <= '0';
		wait for clk_i_period/2;
		clk_i <= '1';
		wait for clk_i_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin
      rst_i <= '0';
      -- hold reset state for 100 ns.
      wait for 500 ns;	
      rst_i <= '1';
      
      wait for clk_i_period*16;

      -- insert stimulus here 
      sendData <= x"01";
      spiStart <= '1';
      wait for 1 ns;
      spiStart <= '0';
      wait until rising_edge(spiSsel);
      wait for SPI_PERIOD;
      sendData <= x"02";
      spiStart <= '1';
      wait for 1 ns;
      spiStart <= '0';
      wait until rising_edge(spiSsel);
      wait for SPI_PERIOD;
      
      sendData <= x"04";
      spiStart <= '1';
      wait for 1 ns;
      spiStart <= '0';
      wait until rising_edge(spiSsel);
      wait for SPI_PERIOD;
      sendData <= x"00";
      spiStart <= '1';
      wait for 1 ns;
      spiStart <= '0';
      wait until rising_edge(spiSsel);
      wait for SPI_PERIOD;
      
      sendData <= x"05";
      spiStart <= '1';
      wait for 1 ns;
      spiStart <= '0';
      wait until rising_edge(spiSsel);
      wait for SPI_PERIOD;
      sendData <= x"0A";
      spiStart <= '1';
      wait for 1 ns;
      spiStart <= '0';
      wait until rising_edge(spiSsel);
      wait for SPI_PERIOD;

      sendData <= x"06";
      spiStart <= '1';
      wait for 1 ns;
      spiStart <= '0';
      wait until rising_edge(spiSsel);
      wait for SPI_PERIOD;
      sendData <= x"42";
      spiStart <= '1';
      wait for 1 ns;
      spiStart <= '0';
      wait until rising_edge(spiSsel);
      wait for SPI_PERIOD;
      
      sendData <= x"07";
      spiStart <= '1';
      wait for 1 ns;
      spiStart <= '0';
      wait until rising_edge(spiSsel);
      wait for SPI_PERIOD;
      sendData <= x"55";
      spiStart <= '1';
      wait for 1 ns;
      spiStart <= '0';
      wait until rising_edge(spiSsel);
      wait for SPI_PERIOD;

      sendData <= x"07";
      spiStart <= '1';
      wait for 1 ns;
      spiStart <= '0';
      wait until rising_edge(spiSsel);
      wait for SPI_PERIOD;
      sendData <= x"AA";
      spiStart <= '1';
      wait for 1 ns;
      spiStart <= '0';
      wait until rising_edge(spiSsel);
      wait for SPI_PERIOD;


      wait for SPI_PERIOD*4;

      sendData <= x"08";
      spiStart <= '1';
      wait for 1 ns;
      spiStart <= '0';
      wait until rising_edge(spiSsel);
      wait for SPI_PERIOD;
      sendData <= x"37";
      spiStart <= '1';
      wait for 1 ns;
      spiStart <= '0';
      wait until rising_edge(spiSsel);
      wait for SPI_PERIOD;
      
      
      wait;
   end process;


  spi_send : process
  begin
    spiSsel <= '1';
    spiSck  <= '0';
    wait until spiStart = '1';
    data    <= sendData;
    spiSsel <= '0';
    for i in data'range loop
      wait for SPI_PERIOD/2;
      spiSck <= '1';
      wait for SPI_PERIOD/2;
      spiSck <= '0';
      data <= data(6 downto 0) & '0';
    end loop;
    wait for SPI_PERIOD/2;
    spiSsel <= '1';
  end process;
  
END;
