----------------------------------------------------------------------------------
-- Company: 
-- Engineer:       VHDLNerd
-- 
-- Create Date:    22:23:49 03/27/2012 
-- Design Name:    
-- Module Name:    vgaDemo - rtl 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: This is the toplevel of the VGA Demo design.  It has been tested on
--              a Papilio One 250k.  This file creates a simple SPI interface to the vnVGA
--              module.  Setting the two generics, TWO_COLOR_ONLY and DIS_DESC will
--              determine the VGA resolution and font used.  Beware XST will die on the
--              the design if too many BRAMs are required.
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
              use work.display_pack.all;    -- define all the support VGA display configurations
              use work.vn_pack.all;

entity vgaDemo is
    generic (
    -- For the full eight color mode displays, uncomment the folowing line and one of the
    -- display mode below it. 
      TWO_COLOR_ONLY : boolean := false;
--      DIS_DESC          : Display_type := DIS_640x480_80x40x256
      DIS_DESC          : Display_type := DIS_640x480_80x30x128
--      DIS_DESC          : Display_type := DIS_800x600_100x50x256
--      DIS_DESC          : Display_type := DIS_1024x768_128x64x256
--      DIS_DESC          : Display_type := DIS_1152x864_144x54x128
--      DIS_DESC          : Display_type := DIS_1152x864_144x54x128_FONT2
--------------------------------------------------------------------------------------

    -- For the two color mode displays, uncomment the folowing line and one of the
    -- display mode below. 
--      TWO_COLOR_ONLY : boolean := true;
--      DIS_DESC          : Display_type := DIS_1280x1024_160x64x128
--      DIS_DESC          : Display_type := DIS_1600x1200_200x75x128
--      DIS_DESC          : Display_type := DIS_1152x864_144x72x256
    );
    port ( clk_i     : in   std_logic;
           rstLow_i  : in   std_logic;
           spiSsel_i : in   std_logic;
           spiSck_i  : in   std_logic;
           spiMosi_i : in   std_logic;
           spiMiso_o : out  std_logic;
           hSync_o   : out  std_logic;
           vSync_o   : out  std_logic;
           r_o       : out  std_logic;
           g_o       : out  std_logic;
           b_o       : out  std_logic);
end vgaDemo;

architecture rtl of vgaDemo is

constant DISPLAY_ADDR_WIDTH : natural := vecLen(DIS_DESC.CharCols*DIS_DESC.CharRows-1);
constant DIDPLAY_ADDR_MAX   : std_logic_vector(DISPLAY_ADDR_WIDTH-1 downto 0) := to_slv(DIS_DESC.CharCols*DIS_DESC.CharRows-1, DISPLAY_ADDR_WIDTH);

type spiFsm is (IDLE, WR_DATA, WR_ACK_WAIT, WR_WAIT_1, RD_ACK_WAIT, RD_SPI_REQ_WAIT1, RD_SPI_REQ_WAIT2, RD_SPI_DATA1, RD_SPI_DATA2, RD_SPI_DATA3);

signal spiFsmR       : spiFsm;
signal color         : std_logic_vector(2 downto 0);
signal fgColor       : std_logic_vector(2 downto 0);
signal bgColor       : std_logic_vector(2 downto 0);

signal weR           : std_logic;
signal stbR          : std_logic;
signal ack           : std_logic;
signal clk           : std_logic;
signal rst           : std_logic;
signal reset         : std_logic;

signal zero8         : std_logic_vector(7 downto 0);
signal addrR         : std_logic_vector(7 downto 0);
signal dataToVgaR    : std_logic_vector(7 downto 0);
signal dataFromVgaR  : std_logic_vector(7 downto 0);

signal spiData       : std_logic_vector(7 downto 0);
signal toSpiDataR    : std_logic_vector(7 downto 0);
signal spiDataEn     : std_logic;
signal spiWrEnR      : std_logic;
signal spiReq        : std_logic;
signal spiWrAck      : std_logic;


begin
  zero8 <= (others => '0'); 
  reset <= not rstLow_i;

  syscon_inst: entity work.syscon(structure)
    generic map (
            VGA_CLK_OUT_PERIOD => DIS_DESC.Vga.PixelClockPeriod
    )
    port map (
            sysClk_i       => clk_i,     -- external system clock input
            rst_i          => reset,     -- external async. reset input
            clkDiv2_o      => open,     -- sysClk / 2 output
            clkVga_o       => clk,      -- VGA pixel clock
            clk_o          => open,     -- sysClk
            clk2x_o        => open,     -- sysClk * 2
            rst_o          => open,     -- sysClk domain reset
            vgaRst_o       => rst,      -- VGA Pixel clock domain reset
            locked_o       => open);    -- DCM locked signal

  -- This SPI moldule is from OpenCores.  It is a little quirky but it works.
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
          di_req_o   => spiReq,           -- preload lookahead data request line
          di_i       => toSpiDataR,       -- parallel load data in (clocked in on rising edge of clk_i)
          wren_i     => spiWrEnR,         -- user data write enable
          wr_ack_o   => spiWrAck,         -- write acknowledge
          do_valid_o => spiDataEn,        -- do_o data valid strobe, valid during one clk_i rising edge.
          do_o       => spiData           -- parallel output (clocked out on falling clk_i)
      );

  -- The fancy thing we are showing off: the vnVGA controller
  vga_inst : entity work.vnVga(rtl)
    generic map(
      DIS_DESC          => DIS_DESC,
      TWO_COLOR_ONLY    => TWO_COLOR_ONLY
    )
    port map (
      rst_i       =>  rst,
      clk_i       =>  clk,
      -- wishbone bus
      we_i        =>  weR,
      stb_i       =>  stbR,
      ack_o       =>  ack,
      adr_i       =>  addrR,
      dat_i       =>  dataToVgaR,
      dat_o       =>  dataFromVgaR,
      -- VGA Outputs
      color_o     =>  color,     -- Video color triplet (2=>Red, 1=>Green, 0=>Blue)
      hSync_o     =>  hSync_o,
      vSync_o     =>  vSync_o
      );   

  r_o <= color(2);
  g_o <= color(1);
  b_o <= color(0);

  -- A simple (and crude) FSM to handle SPI traffic and hand it off
  -- to the vnVGA module.
  SPI_FSM : process(clk, rst)
  begin
    if rst = '1' then
      spiFsmR    <= IDLE;
      addrR      <= (others => '0');
      dataToVgaR <= (others => '0');
      toSpiDataR <= (others => '0');
      weR        <= '0';
      stbR       <= '0';
      spiWrEnR   <= '0';
    elsif rising_edge(clk) then
      weR      <= '0';
      stbR     <= '0';
      spiWrEnR <= '0';
      case spiFsmR is
        when IDLE =>
          if spiDataEn = '1' then
            addrR   <= spiData;
            if spiData(7) = '0' then
              -- a write
              spiFsmR <= WR_WAIT_1;
            else
              -- a read
              weR        <= '0';
              stbR       <= '1';
              spiFsmR    <= RD_ACK_WAIT;
            end if;
          end if;

        when RD_ACK_WAIT =>
          weR        <= '0';
          stbR       <= '1';
          toSpiDataR <= dataFromVgaR;
          if ack = '1' then
            weR        <= '0';
            stbR       <= '0';
            spiFsmR    <= RD_SPI_REQ_WAIT2;
          end if;

        when RD_SPI_REQ_WAIT1 =>
          if spiReq = '1' then
            spiFsmR <= RD_SPI_REQ_WAIT2;
          end if;

        when RD_SPI_REQ_WAIT2 =>
          if spiReq = '1' then
            spiWrEnR <= '1';
            spiFsmR <= RD_SPI_DATA1;
          end if;

        when RD_SPI_DATA1 =>
          if spiWrAck = '1' then
            spiFsmR <= RD_SPI_DATA2;
          end if;
         
        when RD_SPI_DATA2 =>
          if spiDataEn = '1' then
            spiFsmR <= RD_SPI_DATA3;
          end if;

        when RD_SPI_DATA3 => 
          if spiDataEn = '0' then
            spiFsmR <= IDLE;
          end if;
         
        when WR_WAIT_1 =>
          if spiDataEn = '0' then
            spiFsmR <= WR_DATA;
          end if;
            
        when WR_DATA =>
          if spiDataEn = '1' then
            dataToVgaR <= spiData;
            weR        <= '1';
            stbR       <= '1';
            spiFsmR    <= WR_ACK_WAIT;
          end if;
          
        when WR_ACK_WAIT =>
          weR  <= '1';
          stbR <= '1';
          if ack = '1' then
            weR        <= '0';
            stbR       <= '0';
            spiFsmR    <= IDLE;
          end if;
      end case;
    end if;
  end process SPI_FSM;

end rtl;


