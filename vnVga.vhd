----------------------------------------------------------------------------------
-- Company: 
-- Engineer:       VHDLNerd
-- 
-- Create Date:    09:09:47 04/04/2012 
-- Design Name:    
-- Module Name:    vnVga - rtl 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: This is a wrapper arounf the lower level 'vga' module.
--              This wrapper implements a semi-Wishbone complient interface
--              to a set of 8-bit registers.  These registers are used to 
--              controller the 'vga' modlule and give access to the screen
--              memory (which is also create in this module).
--
-- Register Map
-- ------------
--
-- Write Registers:
--   Address      Description
--   ------- -------------------------------------------------
--    0x00 : Set Cursor Control (lower 3 bits)
--    0x01 : Set FG Color (lower 3 bits)
--    0x02 : Set BG Color (lower 3 bits)
--    0x03 : Set Inverse  (LSB)  -- only used for 2 Color output
--    0x04 : Set Cursor Position High Byte
--    0x05 : Set Cursor Position Low Byte
--    0x06 : Set Char Data -- Char to display at current cursor position
--    0x07 : Set Char Data++, display Char and increment cursor position
--    0x08 : Fill Display and home cursor
--    0x09 : HW Scroll (Future Feature -- not implemented, yet)
--
-- Read Registers:
--   Address      Description
--   ------- -------------------------------------------------
--    0x00 : Get Current Cursor Control (lower 3 bits)
--    0x01 : Get Current FG Color (lower 3 bits)
--    0x02 : Get Current BG Color (lower 3 bits)
--    0x03 : Get Current Inverse  (LSB)  -- only used for 2 Color output
--    0x04 : Get Current Cursor Position High Byte
--    0x05 : Get Current Cursor Position Low Byte
--    0x06 : Read Char Data at current cursor position (not tested, yet)
--    0x07 : Read Char Data at current cursor position and increment cursor position (not tested, yet)
--    0x08 : Read any upper bits of the current cursor position's screen RAM
--           This is either the 6-bits of color info (FG and BG) or 1-bit for the
--           invert flag for the 2 Color Only Mode (TWO_COLOR_ONLY set to true)
--    0x10 : Get number of columns in the display
--    0x11 : Get number of rows in the display
--    0x12 : Get number of color bits supported (always 3 in this design)
--    0x13 : Get color mode (0=two color mode, 1=full color mode)
--    0x14 : Get font ID
--
-- Warning:  There is a bug in XST (ver 13.4) where a VHDL constant is treated as something
--           varies!  See the RD_BACK_WIDTH constant below.  If this constant is hard-coded to
--           the literal 5 it works. If the constant is set to: 'vecLen(NUM_RD_REGS-1)' (which
--           is a constant value), XST complains about that the selector of a case statment cannot be
--           an unconstained vector.  
-- 
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.display_pack.all;
use work.vn_pack.all;


entity vnVga is
    generic (
      DIS_DESC       : Display_type;
      TWO_COLOR_ONLY : boolean := false
    );
    port ( clk_i    : in  std_logic;
           rst_i    : in  std_logic;
           -- Wishbone Bus Ports
           we_i     : in  std_logic;
           stb_i    : in  std_logic;
           ack_o    : out std_logic;
           adr_i    : in  std_logic_vector (7 downto 0);
           dat_i    : in  std_logic_vector (7 downto 0);
           dat_o    : out std_logic_vector (7 downto 0);
           -- VGA Output Ports
           color_o  : out std_logic_vector (2 downto 0);
           hSync_o  : out std_logic;
           vSync_o  : out std_logic);
end vnVga;

architecture rtl of vnVga is
  function vnIF(test : boolean; t : natural; f : natural) return natural is
  begin
    if test then return t; end if;
    return f;
  end function vnIF;
  
  constant NUM_WR_REGS        : natural := 16;
  constant NUM_RD_REGS        : natural := 32;
  --constant RD_BACK_WIDTH         : natural := vecLen(NUM_RD_REGS-1);   -- Stupid XST! This will cause an error later! Why!?
  constant RD_BACK_WIDTH         : natural := 5;    -- XST works with this.

  -- define the register map for writable registers.
  constant WR_CURSOR_CNTL_REG    : natural := 0;
  constant WR_FG_COLOR_REG       : natural := 1;
  constant WR_BG_COLOR_REG       : natural := 2;
  constant WR_COLOR_INV_REG      : natural := 3;
  constant WR_CURS_POS_HI_REG    : natural := 4;
  constant WR_CURS_POS_LO_REG    : natural := 5;
  constant WR_CHAR_WR_REG        : natural := 6;
  constant WR_CHAR_WR_INCR_REG   : natural := 7;
  constant WR_FILL_HOME_REG      : natural := 8;
--  constant SCROLL_REG      : natural := 9; -- future feature

  constant RD_CURSOR_CNTL_REG    : std_logic_vector(RD_BACK_WIDTH-1 downto 0) := to_slv(0,RD_BACK_WIDTH);
  constant RD_FG_COLOR_REG       : std_logic_vector(RD_BACK_WIDTH-1 downto 0) := to_slv(1,RD_BACK_WIDTH);
  constant RD_BG_COLOR_REG       : std_logic_vector(RD_BACK_WIDTH-1 downto 0) := to_slv(2,RD_BACK_WIDTH);
  constant RD_COLOR_INV_REG      : std_logic_vector(RD_BACK_WIDTH-1 downto 0) := to_slv(3,RD_BACK_WIDTH);
  constant RD_CURS_POS_HI_REG    : std_logic_vector(RD_BACK_WIDTH-1 downto 0) := to_slv(4,RD_BACK_WIDTH);
  constant RD_CURS_POS_LO_REG    : std_logic_vector(RD_BACK_WIDTH-1 downto 0) := to_slv(5,RD_BACK_WIDTH);
  constant RD_CHAR               : std_logic_vector(RD_BACK_WIDTH-1 downto 0) := to_slv(6,RD_BACK_WIDTH);
  constant RD_CHAR_INCR          : std_logic_vector(RD_BACK_WIDTH-1 downto 0) := to_slv(7,RD_BACK_WIDTH);
  constant RD_CHAR_ATTR          : std_logic_vector(RD_BACK_WIDTH-1 downto 0) := to_slv(8,RD_BACK_WIDTH);

  constant RD_DIS_COLS           : std_logic_vector(RD_BACK_WIDTH-1 downto 0) := to_slv(16#10#,RD_BACK_WIDTH);
  constant RD_DIS_ROWS           : std_logic_vector(RD_BACK_WIDTH-1 downto 0) := to_slv(16#11#,RD_BACK_WIDTH);
  constant RD_DIS_COLOR_BITS     : std_logic_vector(RD_BACK_WIDTH-1 downto 0) := to_slv(16#12#,RD_BACK_WIDTH);
  constant RD_DIS_COLOR_MODE     : std_logic_vector(RD_BACK_WIDTH-1 downto 0) := to_slv(16#13#,RD_BACK_WIDTH);
  constant RD_DIS_FONT_ID        : std_logic_vector(RD_BACK_WIDTH-1 downto 0) := to_slv(16#14#,RD_BACK_WIDTH);
  
  constant DISPLAY_DATA_WIDTH : natural := vnIF(TWO_COLOR_ONLY, 9, 16);
  constant DISPLAY_ADDR_WIDTH : natural := vecLen(DIS_DESC.CharCols*DIS_DESC.CharRows-1);
  constant DISPLAY_ADDR_MAX   : std_logic_vector(DISPLAY_ADDR_WIDTH-1 downto 0) := to_slv(DIS_DESC.CharCols*DIS_DESC.CharRows-1, DISPLAY_ADDR_WIDTH);
  constant CHAR_WIDTH         : natural := vecLen(DIS_DESC.Font.NumChars-1);

  type Regs_type is array (0 to NUM_WR_REGS-1) of std_logic_vector(7 downto 0);
  type Fsm_type  is (IDLE, FILL, INIT);
  
  signal fsmR         : Fsm_type;
  signal RegsR        : Regs_type;
  signal RegsWrR      : std_logic_vector(0 to NUM_WR_REGS-1);

  signal disData      : std_logic_vector(DISPLAY_DATA_WIDTH-1 downto 0);
  signal disAddr      : std_logic_vector(DISPLAY_ADDR_WIDTH-1 downto 0);
  signal cCntlR       : std_logic_vector(2 downto 0);

  signal disRdData    : std_logic_vector(DISPLAY_DATA_WIDTH-1 downto 0);
  signal charDataR    : std_logic_vector(CHAR_WIDTH-1 downto 0);
  signal wrCharR      : std_logic_vector(CHAR_WIDTH-1 downto 0);

  signal colorSwapR   : std_logic;
  signal disWrAddr    : std_logic_vector(DISPLAY_ADDR_WIDTH-1 downto 0);
  signal disWrData    : std_logic_vector(DISPLAY_DATA_WIDTH-1 downto 0);
  signal disLdValR    : std_logic_vector(DISPLAY_ADDR_WIDTH-1 downto 0);
  signal disLdEnR     : std_logic;
  signal disCntEnR    : std_logic;
  signal disClrR      : std_logic;
  signal disTcR       : std_logic;

  signal disWrEnR     : std_logic;

  signal fgColorR     : std_logic_vector(2 downto 0);
  signal bgColorR     : std_logic_vector(2 downto 0);
  signal currFgColor  : std_logic_vector(2 downto 0);
  signal currBgColor  : std_logic_vector(2 downto 0);

  signal ones         : std_logic_vector(DISPLAY_ADDR_WIDTH-1 downto 0);

  signal rdAckR       : std_logic;
begin
  vga_inst : entity work.vga(rtl)
    generic map(
      DIS_DESC    => DIS_DESC
    )
    port map (
      rst_i       =>  rst_i,
      clk_i       =>  clk_i,
      disAddr_o   =>  disAddr,   -- screen buffer address
      disData_i   =>  charDataR, -- screen data (a byte even if the upper bit is not used)
      fgColor_i   =>  fgColorR,  -- Foreground color triplet (2=>Red, 1=>Green, 0=>Blue)
      bgColor_i   =>  bgColorR,  -- Background color triplet (2=>Red, 1=>Green, 0=>Blue)
      cursLoc_i   =>  disWrAddr, -- cursor position (same size vector as disAddr_o)
      cursCntl_i  =>  cCntlR,    -- sets type of cursor
      color_o     =>  color_o,   -- Video color triplet (2=>Red, 1=>Green, 0=>Blue)
      hSync_o     =>  hSync_o,
      vSync_o     =>  vSync_o
      );

  -- Dual ported RAM used as the display (screen) memory
  display_RAM : entity work.vnDpRam(rtl)
    port map (
      -- Port A: read and write (for the Wishbone interface)
      clkaIn  => clk_i,
      wrEnaIn => disWrEnR,
      addraIn => disWrAddr,
      dataaIn => disWrData,
      qaOut   => disRdData,
      -- Port B: read only  (for the 'vga' module to read)
      clkbIn  => clk_i,
      addrbIn => disAddr,
      qbOut   => disData);
  reg(charDataR, disData(charDataR'range), clk_i, rst_i);

  -- This is the display counter (i.e. the current cursor position)
  dis_cntr : entity work.vnCounter(rtl)
    port map (
      clk_i     => clk_i,            -- clock
      rst_i     => rst_i,            -- reset
      cntEn_i   => disCntEnR,
      clr_i     => disClrR,          -- clear
      ldEn_i    => disLdEnR,         -- load enable
      ldVal_i   => disLdValR,        -- load value
      tCntVal_i => DISPLAY_ADDR_MAX,
      tc_o      => disTcR,           -- terminal count flag
      cnt_o     => disWrAddr         -- count value
      );

  -- 
  -- In two color mode, the text display has one FG and one BG color, only.
  -- However, the FG and BG color can be one of eight posibble colors.
  -- In this mode the display RAM is 9-bits wide, 8-bits for the char to
  -- display and the MSB is an inverse flag (if set, the FG and BG colors
  -- are swapped).
  TWO_COLOR : if TWO_COLOR_ONLY generate
    signal fgColor     : std_logic_vector(2 downto 0);
    signal bgColor     : std_logic_vector(2 downto 0);
  begin
    -- Read data from display RAM
    -- swap FG and BG colors if RAM data bit #8 is set
    fgColor <= currFgColor when disData(8)='0' else currBgColor;
    bgColor <= currBgColor when disData(8)='0' else currFgColor;
    reg(fgColorR, fgColor, clk_i, rst_i, "000");
    reg(bgColorR, bgColor, clk_i, rst_i, "000");

    -- Write data to display RAM
    disWrData(8)             <= colorSwapR;
    disWrData(wrCharR'range) <= wrCharR;
  end generate TWO_COLOR;

  --
  -- Glorious full color mode!!! In this mode you get
  -- eight (count them, eight) colors choices for the BG and FG 
  -- colors of each char on the display.  In this mode the 
  -- display RAM needs to be atleast 14-bits wide: 8-bits for
  -- char code, 3-bits for the FG color and 3-bits for the
  -- BG color.
  --  Display memory word: 
  --  |13|12|11|10| 9| 8| 7| 6| 5| 4| 3| 2| 1| 0|
  --  |<--BG-->|<--FG-->|<------Char Code------>|
  -- (Bits 16:14 are reserved for future use.)
  --
  FULL_COLOR : if not TWO_COLOR_ONLY generate
  begin
    -- Read data from display RAM
    reg(fgColorR, disData(10 downto 8) , clk_i, rst_i, "000");
    reg(bgColorR, disData(13 downto 11), clk_i, rst_i, "000");

    -- Write data to display RAM
    disWrData(wrCharR'range) <= wrCharR;
    disWrData(10 downto 8)   <= currFgColor;
    disWrData(13 downto 11)  <= currBgColor;
    disWrData(15 downto 14)  <= "00";
  end generate FULL_COLOR;

  ack_o <= (stb_i and we_i) or (rdAckR and stb_i);
  
  -- Create the writable registers:
  WR_REGS : for i in RegsR'range generate
    constant ADDR_WIDTH : natural := vecLen(NUM_WR_REGS-1);
    constant RST_VALS : Regs_type := (x"00", x"02", others => x"00"); -- default FG to green, BG to black
    signal match : std_logic;
  begin
    match <= '1' when to_integer(unsigned(adr_i(ADDR_WIDTH-1 downto 0)))=i and stb_i='1' and we_i='1' else '0';
    reg(RegsR(i),   dat_i, clk_i, rst_i, RST_VALS(i), match);
    reg(RegsWrR(i), match, clk_i, rst_i);
  end generate WR_REGS;
  
  -- Map the write regs to some internal signals
  cCntlR      <= RegsR(WR_CURSOR_CNTL_REG)(cCntlR'range);
  currFgColor <= RegsR(WR_FG_COLOR_REG)(currFgColor'range);
  currBgColor <= RegsR(WR_BG_COLOR_REG)(currBgColor'range);
  colorSwapR  <= RegsR(WR_COLOR_INV_REG)(0);
  
  -- FSM to handle the different "commands":
  --         write char, write char w/incr, fill screen
  fsm : process(clk_i, rst_i)
    variable locReg : std_logic_vector(15 downto 0);
  begin
    locReg := RegsR(WR_CURS_POS_HI_REG) & RegsR(WR_CURS_POS_LO_REG);
    if rst_i = '1' then
      fsmR      <= INIT;
      disWrEnR  <= '0';
      wrCharR   <= (others => '0');
      disLdValR <= (others => '0');
      disLdEnR  <= '0';
      disCntEnR <= '0';
      disClrR   <= '0';
    elsif rising_edge(clk_i) then
      disWrEnR  <= '0';
      disCntEnR <= '0';
      disClrR   <= '0';
      disLdValR <= locReg(disLdValR'range);
      disLdEnR  <= RegsWrR(WR_CURS_POS_LO_REG);

      case fsmR is
        when IDLE =>
          -- wait for a command to work on
          if RegsWrR(WR_CHAR_WR_REG) = '1' then
            wrCharR   <= RegsR(WR_CHAR_WR_REG)(wrCharR'range);
            disWrEnR  <= '1';
          elsif RegsWrR(WR_CHAR_WR_INCR_REG) = '1' then
            wrCharR   <= RegsR(WR_CHAR_WR_INCR_REG)(wrCharR'range);
            disWrEnR  <= '1';
            disCntEnR <= '1';
          elsif RegsWrR(WR_FILL_HOME_REG) = '1' then
            wrCharR   <= RegsR(WR_FILL_HOME_REG)(wrCharR'range);
            disClrR   <= '1';
            fsmR      <= FILL;
          end if;

        when FILL =>
          disLdEnR  <= '0'; -- lock out loading of the counter
          disWrEnR  <= '1';
          disCntEnR <= '1';
          if disTcR = '1' then
            disWrEnR  <= '0';
            disCntEnR <= '0';
            disClrR   <= '1';
            fsmR      <= IDLE;
          end if;

        when INIT =>
          -- fill screen with counting pattern
          -- (only done after a reset)
          wrCharR   <= disWrAddr(wrCharR'range);
          disLdEnR  <= '0'; -- lock out loading of the counter
          disWrEnR  <= '1';
          disCntEnR <= '1';
          if disTcR = '1' then
            disWrEnR  <= '0';
            disCntEnR <= '0';
            disClrR   <= '1';
            fsmR      <= IDLE;
          end if;
      end case;
    end if;
  end process fsm;

  -- Create the readable registers.
  -- (This is really just a registered mux.)
  ReadRegs : process (clk_i, rst_i)
  begin
    if rst_i = '1' then
      rdAckR <= '0';
      dat_o  <= (others => '0');
    elsif rising_edge(clk_i) then
      -- create the readback mux
      dat_o <= (others => '0');
      case adr_i(RD_BACK_WIDTH-1 downto 0) is
        when RD_CURSOR_CNTL_REG =>
          dat_o(cCntlR'range) <= cCntlR;

        when RD_FG_COLOR_REG =>
          dat_o(currFgColor'range) <= currFgColor;

        when RD_BG_COLOR_REG =>
          dat_o(currBgColor'range) <= currBgColor;

        when RD_COLOR_INV_REG =>
          dat_o(0) <= colorSwapR;

        when RD_CURS_POS_HI_REG =>
          dat_o <= RegsR(WR_CURS_POS_HI_REG);

        when RD_CURS_POS_LO_REG =>
          dat_o <= RegsR(WR_CURS_POS_LO_REG);

        when RD_CHAR =>
          dat_o <= disRdData(dat_o'range);

        when RD_CHAR_ATTR =>
          dat_o(DISPLAY_DATA_WIDTH-9 downto 0) <= disRdData(DISPLAY_DATA_WIDTH-1 downto 8);

        when RD_DIS_COLS =>
          dat_o <= to_slv(DIS_DESC.CharCols,8);
          
        when RD_DIS_ROWS =>
          dat_o <= to_slv(DIS_DESC.CharRows,8);
          
        when RD_DIS_COLOR_BITS =>
          dat_o <= to_slv(3,8);
          
        when RD_DIS_COLOR_MODE =>
          dat_o <= to_slv(vnIF(TWO_COLOR_ONLY, 0, 1),8);
          
        when RD_DIS_FONT_ID =>
          dat_o <= to_slv(DIS_DESC.Font.ID,8);

        when others =>
          dat_o <= (others => '1');

      end case;

      rdAckR <= stb_i and (not we_i);
    end if;
  end process ReadRegs;
end rtl;
