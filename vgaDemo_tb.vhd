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
         rst_i : IN  std_logic;
         
         spiSsel_i : in   std_logic;
         spiSck_i  : in   std_logic;
         spiMosi_i : in   std_logic;
         spiMiso_o : out  std_logic;

         led_o     : out  std_logic;

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

   -- Clock period definitions
   constant clk_i_period : time := 31.125 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: vgaDemo PORT MAP (
          clk_i     => clk_i,
          rst_i     => rst_i,
          spiSsel_i => '0',
          spiSck_i  => '0',
          spiMosi_i => '0',
          spiMiso_o => open,
          led_o     => open,
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
      rst_i <= '1';
      -- hold reset state for 100 ns.
      wait for 500 ns;	
      rst_i <= '0';
      
      wait for clk_i_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
