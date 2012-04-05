----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:23:49 03/27/2012 
-- Design Name: 
-- Module Name:    vgaDemo - rtl 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.display_pack.all;
use work.vn_pack.all;

entity vgaDemo is
    generic (
--      DIS_DESC          : Display_type := DIS_SIM_ONLY
--      DIS_DESC          : Display_type := DIS_640x480_80x40x256
--      DIS_DESC          : Display_type := DIS_1280x1024_160x64x128
--      DIS_DESC          : Display_type := DIS_1600x1200_200x75x128
      DIS_DESC          : Display_type := DIS_1152x864_144x72x256
    );
    port ( clk_i     : in   std_logic;
           rst_i     : in   std_logic;
           spiSsel_i : in   std_logic;
           spiSck_i  : in   std_logic;
           spiMosi_i : in   std_logic;
           spiMiso_o : out  std_logic;

           led_o     : out  std_logic;
           
           hSync_o   : out  std_logic;
           vSync_o   : out  std_logic;
           r_o       : out  std_logic;
           g_o       : out  std_logic;
           b_o       : out  std_logic);
end vgaDemo;

architecture rtl of vgaDemo is

constant DISPLAY_ADDR_WIDTH : natural := vecLen(DIS_DESC.CharCols*DIS_DESC.CharRows-1);
constant DIDPLAY_ADDR_MAX   : std_logic_vector(DISPLAY_ADDR_WIDTH-1 downto 0) := to_slv(DIS_DESC.CharCols*DIS_DESC.CharRows-1, DISPLAY_ADDR_WIDTH);

signal color    : std_logic_vector(2 downto 0);
signal fgColor  : std_logic_vector(2 downto 0);
signal bgColor  : std_logic_vector(2 downto 0);

signal disData  : std_logic_vector(7 downto 0);
signal disDataR : std_logic_vector(7 downto 0);
signal disAddr  : std_logic_vector(DISPLAY_ADDR_WIDTH-1 downto 0);
signal cLoc     : std_logic_vector(DISPLAY_ADDR_WIDTH-1 downto 0);
signal nc       : std_logic_vector(7 downto 0);

signal disWrAddr  : std_logic_vector(DISPLAY_ADDR_WIDTH-1 downto 0) := (others => '0');
signal disWrData  : std_logic_vector(7 downto 0) := x"42";
signal disWrEn    : std_logic := '0';
signal disTc      : std_logic;
signal clk        : std_logic;
signal rst        : std_logic;

signal zero8      : std_logic_vector(7 downto 0);

signal spiInData  : std_logic_vector(7 downto 0);
signal spiInDataEn: std_logic;

begin
zero8 <= (others => '0');

syscon_inst: entity work.syscon(structure)
  generic map (
          VGA_CLK_OUT_PERIOD => DIS_DESC.Vga.PixelClockPeriod
  )
  port map (
          sysClk_i       => clk_i,     -- external system clock input
          rst_i          => rst_i,     -- external async. reset input
          clkDiv2_o      => open,     -- sysClk / 2 output
          clkVga_o       => clk,      -- VGA pixel clock
          clk_o          => open,     -- sysClk
          clk2x_o        => open,     -- sysClk * 2
          rst_o          => open,     -- sysClk domain reset
          vgaRst_o       => rst,      -- VGA Pixel clock domain reset
          locked_o       => open);    -- DCM locked signal

spi_inst : entity work.spi_slave(rtl)
    generic map(   
        N => 8
        )
    port map(  
        clk_i      => clk,
        spi_ssel_i => spiSsel_i,
        spi_sck_i  => spiSck_i,
        spi_mosi_i => spiMosi_i,
        spi_miso_o => spiMiso_o,
        di_req_o   => open,             -- preload lookahead data request line
        di_i       => zero8,            -- parallel load data in (clocked in on rising edge of clk_i)
        wren_i     => '0',              -- user data write enable
        wr_ack_o   => open,             -- write acknowledge
        do_valid_o => spiInDataEn,      -- do_o data valid strobe, valid during one clk_i rising edge.
        do_o       => spiInData         -- parallel output (clocked out on falling clk_i)
    );

led_o   <= spiInData(7);

fgColor <= "010";   -- green
bgColor <= "000";   -- black

dis_cntr : entity work.vnCounter(rtl)
  port map (
    clk_i     => clk,              -- clock
    rst_i     => rst,              -- reset
    clr_i     => disTc,            -- clear on TC
    ldVal_i   => "0",              -- load feature not used
    tCntVal_i => DIDPLAY_ADDR_MAX, -- terminal count
    cnt_o     => disWrAddr,        -- count value
    tc_o      => disTc);           -- Terminal count flag

reg(disWrEn, '0', clk, rst, '1', disTc);

--disWrData <= "000" & disWrAddr;
disWrData <= disWrAddr(disWrData'range);

vga_inst : entity work.vga(rtl)
  generic map(
    DIS_DESC          => DIS_DESC
  )
  port map (
    rst_i       =>  rst,
    clk_i       =>  clk,
    disAddr_o   =>  disAddr,   -- screen buffer address
    disData_i   =>  disDataR(6 downto 0),  -- screen data (a byte even if the upper bit is not used)
    fgColor_i   =>  fgColor,   -- Foreground color triplet (2=>Red, 1=>Green, 0=>Blue)
    bgColor_i   =>  bgColor,   -- Background color triplet (2=>Red, 1=>Green, 0=>Blue)
    cursLoc_i   =>  cLoc,      -- cursor position (same size vector as disAddr_o)
    cursCntl_i  =>  "000",     -- sets type of cursor
    color_o     =>  color,     -- Video color triplet (2=>Red, 1=>Green, 0=>Blue)
    hSync_o     =>  hSync_o,
    vSync_o     =>  vSync_o
    );   

  r_o <= color(2);
  g_o <= color(1);
  b_o <= color(0);

display_RAM : entity work.vnDpRam(rtl)
  port map (
    -- Port A: read and write
    clkaIn  => clk,
    wrEnaIn => disWrEn,
    addraIn => disWrAddr,
    dataaIn => disWrData,
    qaOut   => nc,
    -- Port B: read only
    clkbIn  => clk,
    addrbIn => disAddr,
    qbOut   => disData);

reg(disDataR, disData, clk, rst);

end rtl;

-- Write Registers:
--    0x00 : Cursor Control (lower 3 bits)
--    0x01 : FG Color (lower 3 bits)
--    0x02 : BG Color (lower 3 bits)
--    0x03 : Inverse  (LSB)  -- only used for 2 Color output
--    0x04 : Cursor Position High Byte
--    0x05 : Cursor Position Low Byte
--    0x06 : Char Data -- Char to display at current cursor position
--    0x07 : Char Data++, display Char and increment cursor position
--    0x08 : Fill Display and home cursor
--    0x09 : HW Scroll (Future Feature)

