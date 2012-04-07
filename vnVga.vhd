----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:09:47 04/04/2012 
-- Design Name: 
-- Module Name:    vnVga - rtl 
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.display_pack.all;
use work.vn_pack.all;

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
  
  -- define the register map for writable registers.
  constant CURSOR_CNTL_REG    : natural := 0;
  constant FG_COLOR_REG       : natural := 1;
  constant BG_COLOR_REG       : natural := 2;
  constant COLOR_INV_REG      : natural := 3;
  constant CURS_POS_HI_REG    : natural := 4;
  constant CURS_POS_LO_REG    : natural := 5;
  constant CHAR_WR_REG        : natural := 6;
  constant CHAR_WR_INCR_REG   : natural := 7;
  constant FILL_HOME_REG      : natural := 8;
--  constant SCROLL_REG      : natural := 9; -- future feature
  
  constant NUM_WR_REGS        : natural := 16;
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

  display_RAM : entity work.vnDpRam(rtl)
    port map (
      -- Port A: read and write
      clkaIn  => clk_i,
      wrEnaIn => disWrEnR,
      addraIn => disWrAddr,
      dataaIn => disWrData,
      qaOut   => disRdData,
      -- Port B: read only
      clkbIn  => clk_i,
      addrbIn => disAddr,
      qbOut   => disData);
  reg(charDataR, disData(charDataR'range), clk_i, rst_i);

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

  ack_o <= stb_i;
  
  -- Create the writable registers:
  WR_REGS : for i in RegsR'range generate
    constant ADDR_WIDTH : natural := vecLen(NUM_WR_REGS-1);
    constant RST_VALS : Regs_type := (x"00", x"02", others => x"00");
    signal match : std_logic;
  begin
    match <= '1' when to_integer(unsigned(adr_i(ADDR_WIDTH-1 downto 0)))=i and stb_i='1' and we_i='1' else '0';
    reg(RegsR(i),   dat_i, clk_i, rst_i, RST_VALS(i), match);
    reg(RegsWrR(i), match, clk_i, rst_i);
  end generate WR_REGS;
  
  -- Map the write regs to some signals
  cCntlR      <= RegsR(CURSOR_CNTL_REG)(cCntlR'range);
  currFgColor <= RegsR(FG_COLOR_REG)(currFgColor'range);
  currBgColor <= RegsR(BG_COLOR_REG)(currBgColor'range);
  colorSwapR  <= RegsR(COLOR_INV_REG)(0);
  
  -- FSM to handle the different "commands":
  --         write char, write char w/incr, fill screen
  fsm : process(clk_i, rst_i)
    variable locReg : std_logic_vector(15 downto 0);
  begin
    locReg := RegsR(CURS_POS_HI_REG) & RegsR(CURS_POS_LO_REG);
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
      disLdEnR  <= RegsWrR(CURS_POS_LO_REG);

      case fsmR is
        when IDLE =>
          -- wait for a command to work on
          if RegsWrR(CHAR_WR_REG) = '1' then
            wrCharR   <= RegsR(CHAR_WR_REG)(wrCharR'range);
            disWrEnR  <= '1';
          elsif RegsWrR(CHAR_WR_INCR_REG) = '1' then
            wrCharR   <= RegsR(CHAR_WR_INCR_REG)(wrCharR'range);
            disWrEnR  <= '1';
            disCntEnR <= '1';
          elsif RegsWrR(FILL_HOME_REG) = '1' then
            wrCharR   <= RegsR(FILL_HOME_REG)(wrCharR'range);
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
end rtl;

