library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.display_pack.all;
use work.vn_pack.all;

entity vga is
  generic (
    DIS_DESC            : Display_type := DIS_SIM_ONLY;
    CURSOR_BLINK_PERIOD : natural      := 350 -- in mSec
  );
  port (
    rst_i       : in  std_logic;
    clk_i       : in  std_logic;
    -- Display RAM ports (note fgColor_i and bgColor_i can come from the
    --                         Display RAM or be constants)
    disAddr_o   : out std_logic_vector;               -- screen buffer address
--    disData_i   : in  std_logic_vector(7 downto 0);   -- screen data (a byte even if the upper bit is not used)
    disData_i   : in  std_logic_vector;               -- screen data (7 or 8 bits)
    fgColor_i   : in  std_logic_vector(2 downto 0);   -- Foreground color triplet (2=>Red, 1=>Green, 0=>Blue)
    bgColor_i   : in  std_logic_vector(2 downto 0);   -- Background color triplet (2=>Red, 1=>Green, 0=>Blue)
    -- Cursor control
    cursLoc_i   : in  std_logic_vector;               -- cursor position (same size vector as disAddr_o)
    cursCntl_i  : in  std_logic_vector(2 downto 0);   -- sets type of cursor
    -- Video output enable
    vgaEn_i     : in  std_logic := '1';               -- enables sync outputs
    -- Video Outputs
    color_o     : out std_logic_vector(2 downto 0);   -- Video color triplet (2=>Red, 1=>Green, 0=>Blue)
    hSync_o     : out std_logic;
    vSync_o     : out std_logic
    );   
end vga;

architecture rtl of vga is
---------------
-- CONSTANTS --
---------------
-- Create a lot of constants (and subtypes) that will define the size of the 
-- counters required to create the VGA timing and accessing the screen memory.
-- All of these timing constants are based on the DIS_DESC generic.
  -- Horizontal Timing (in units of pixels):
  -- H_FULL_LENGTH is the total length of a horz line (visible plus nonvisible)
  constant H_FULL_LENGTH           : natural := DIS_DESC.Vga.H_Visible+DIS_DESC.Vga.H_FrontPorch+
                                                DIS_DESC.Vga.H_Sync+DIS_DESC.Vga.H_BackPorch;
  -- H_CNTR_WIDTH is the bit width of the horz counter
  constant H_CNTR_WIDTH            : natural := vecLen(H_FULL_LENGTH-1);
  -- define a subtype for the horz counter
  subtype  HCntr_type              is std_logic_vector(H_CNTR_WIDTH-1 downto 0);
  -- H_MAX_CNT is the terminal count for the horz counter
  constant H_MAX_CNT               : HCntr_type := to_slv(H_FULL_LENGTH-1, H_CNTR_WIDTH);
  -- H_VISIBLE_CNT, H_FRONT_PORCH_CNT, and H_SYNC_CNT are counts when the logic needs to toggle timing signals
  constant H_VISIBLE_CNT           : HCntr_type := to_slv(DIS_DESC.Vga.H_Visible-1, H_CNTR_WIDTH);
  constant H_FRONT_PORCH_END       : HCntr_type := to_slv(DIS_DESC.Vga.H_Visible+DIS_DESC.Vga.H_FrontPorch-1, H_CNTR_WIDTH);
  constant H_SYNC_END              : HCntr_type := to_slv(DIS_DESC.Vga.H_Visible+DIS_DESC.Vga.H_FrontPorch+DIS_DESC.Vga.H_Sync-1, H_CNTR_WIDTH);

  -- Vertical Timing (in units of lines):
  --   Same constants as needed for the horz timing but these refer to lines not horz pixels.
  constant V_FULL_LENGTH           : natural := DIS_DESC.Vga.V_Visible+DIS_DESC.Vga.V_FrontPorch+DIS_DESC.Vga.V_Sync+DIS_DESC.Vga.V_BackPorch;
  constant V_CNTR_WIDTH            : natural := vecLen(V_FULL_LENGTH-1);
  subtype  VCntr_type              is std_logic_vector(V_CNTR_WIDTH-1 downto 0);
  constant V_MAX_CNT               : VCntr_type := to_slv(V_FULL_LENGTH-1, V_CNTR_WIDTH);
  constant V_BLANK_END_CNT         : VCntr_type := to_slv(V_FULL_LENGTH-2, V_CNTR_WIDTH);
  constant V_VISIBLE_CNT           : VCntr_type := to_slv(DIS_DESC.Vga.V_Visible-1, V_CNTR_WIDTH);
  constant V_FRONT_PORCH_END       : VCntr_type := to_slv(DIS_DESC.Vga.V_Visible+DIS_DESC.Vga.V_FrontPorch-1, V_CNTR_WIDTH);
  constant V_SYNC_END              : VCntr_type := to_slv(DIS_DESC.Vga.V_Visible+DIS_DESC.Vga.V_FrontPorch+DIS_DESC.Vga.V_Sync-1, V_CNTR_WIDTH);

  -- Display constants (in units of chars):
  constant DIS_TOTAL               : natural := DIS_DESC.CharCols*DIS_DESC.CharRows;
  constant DIS_CTNR_WIDTH          : natural := vecLen(DIS_TOTAL-1);
  subtype  DisCntr_Type            is std_logic_vector(DIS_CTNR_WIDTH-1 downto 0);
  constant DIS_MAX_CNT             : DisCntr_Type := to_slv(DIS_TOTAL-1, DIS_CTNR_WIDTH);

  -- Font constants:
  constant FONT_X_CNTR_WIDTH       : natural := vecLen(DIS_DESC.Font.Width-1);
  subtype  FontXCntr_type          is std_logic_vector(FONT_X_CNTR_WIDTH-1 downto 0);
  constant FONT_X_MAX_CNT          : FontXCntr_type := to_slv(DIS_DESC.Font.Width-1, FONT_X_CNTR_WIDTH);
  constant FONT_Y_CNTR_WIDTH       : natural := vecLen(DIS_DESC.Font.Height-1+1); -- goes one farther than needed (used for end-of-row detection)
  subtype  FontYCntr_type          is std_logic_vector(FONT_Y_CNTR_WIDTH-1 downto 0);
  constant FONT_Y_MAX_CNT          : FontYCntr_type := to_slv(DIS_DESC.Font.Height-1+1, FONT_Y_CNTR_WIDTH); -- goes one farther than needed (used for end-of-col detection)
  constant FONT_ROM_ADDR_WIDTH     : natural := vecLen(DIS_DESC.Font.Height*DIS_DESC.Font.NumChars-1);
  
  -- Constants for the cursor blink counter (in units of frames):
  -- (Note the actual blink rate will not always be exactly as requested.)
  constant FRAME_TIME_US           : natural := (((H_FULL_LENGTH*V_FULL_LENGTH)/1000)*DIS_DESC.Vga.PixelClockPeriod)/1000; -- in microseconds
  constant FRAMES_PER_BLINK        : natural := (CURSOR_BLINK_PERIOD*1000)/FRAME_TIME_US;
  constant BLINK_CNTR_WIDTH        : natural := vecLen(FRAMES_PER_BLINK/2-1);
  constant ACTUAL_BLINK_RATE       : real := 1.0/(real((FRAMES_PER_BLINK/2)*2)*real(H_FULL_LENGTH*V_FULL_LENGTH)*(real(DIS_DESC.Vga.PixelClockPeriod)/1.0e12));
  subtype  BlinkCtr_type           is std_logic_vector(BLINK_CNTR_WIDTH-1 downto 0);
  constant BLINK_MAX_CNT           : BlinkCtr_type := to_slv(FRAMES_PER_BLINK/2-1, BLINK_CNTR_WIDTH);
  -- one last constant, at what count do we need to turn on the underline cursor
  constant CURSOR_UL_ON_CNT        : FontYCntr_type := to_slv(DIS_DESC.Font.Height-DIS_DESC.CursorHeight, FONT_Y_CNTR_WIDTH);

---------------
--  SIGNALS  --
---------------

  -- Horizontal scan signal
  signal hCntrR          : HCntr_type;
  signal hCntrTcR        : std_logic;
  signal hBlankR         : std_logic;
  signal hBlankStart     : std_logic;
  signal hSyncStart      : std_logic;
  signal hSyncEnd        : std_logic;
  signal hSyncR          : std_logic;

  -- Vertical scan signals
  signal vCntrR          : VCntr_type;
  signal vCntrTcR        : std_logic;
  signal vBlankR         : std_logic;
  signal vSyncR          : std_logic;
  signal vBlankStart     : std_logic;
  signal vBlankEnd       : std_logic;
  signal vSyncStart      : std_logic;
  signal vSyncEnd        : std_logic;

  -- Display RAM counter
  signal disCntrR        : DisCntr_Type;
  signal disCntrEn       : std_logic;
  signal currDisRowR     : DisCntr_Type;

  -- Character generation
  signal fontXCntrR      : FontXCntr_type;
  signal fontXCntrTcR    : std_logic;
  signal fontXCntrClr    : std_logic;
  signal fontYCntrR      : FontYCntr_type;
  signal fontYCntrTcR    : std_logic;
  signal fontYCntrDone   : std_logic;
  signal fontYCntrClr    : std_logic;
  signal fontYCntrEndR   : std_logic;
  
  -- Cursor
  signal atCursLocR      : std_logic;
  signal atCursLoc       : std_logic;
  signal cursOn          : std_logic;
  signal cursUlOnR       : std_logic;
  signal cursUlOn        : std_logic;
  signal blinkCntrR      : BlinkCtr_type;
  signal blinkCntrTcR    : std_logic;
  signal blinkR          : std_logic;

  -- Font signals
  signal fontAddr        : std_logic_vector(FONT_ROM_ADDR_WIDTH-1 downto 0);
  signal fontAddrR       : std_logic_vector(FONT_ROM_ADDR_WIDTH-1 downto 0);
  signal fontDataR       : std_logic_vector(DIS_DESC.Font.Width-1 downto 0);
  signal shiftDataR      : std_logic_vector(DIS_DESC.Font.Width-1 downto 0);

  -- Color signals
  signal outColor        : std_logic_vector(2 downto 0);
  signal fgColorR        : std_logic_vector(2 downto 0);
  signal bgColorR        : std_logic_vector(2 downto 0);
  
  -- Aliases
  alias cursEn           : std_logic is cursCntl_i(0);
  alias cursMode         : std_logic is cursCntl_i(1);
  alias cursBlink        : std_logic is cursCntl_i(2);
  alias outPixel         : std_logic is shiftDataR(shiftDataR'left);
  
begin
  -- The horizontal counter is free running.
  horz_cntr : entity work.vnCounter(rtl)
    port map (
      clk_i     => clk_i,           -- clock
      rst_i     => rst_i,           -- reset
      clr_i     => hCntrTcR,        -- clear on TC
      ldVal_i   => "0",             -- load feature not used
      tCntVal_i => H_MAX_CNT,       -- terminal count
      cnt_o     => hCntrR,          -- count value
      tc_o      => hCntrTcR);       -- Terminal count flag

  -- Generate the horizontal timing signals
  hBlankStart <= '1' when hCntrR=H_VISIBLE_CNT       else '0';
  hSyncStart  <= '1' when hCntrR=H_FRONT_PORCH_END   else '0';
  hSyncEnd    <= '1' when hCntrR=H_SYNC_END          else '0';
  --srReg:  q         set           clear     clk     rst   RST_VAL='0'
  scReg(hBlankR, hBlankStart, hCntrTcR, clk_i, rst_i);  -- gen the H blanking signal
  scReg(hSyncR,  hSyncStart,  hSyncEnd, clk_i, rst_i);  -- gen the H Sync signal
  
  -- The vertical counter
  vert_cntr : entity work.vnCounter(rtl)
    port map (
      clk_i     => clk_i,           -- clock
      rst_i     => rst_i,           -- reset
      cntEn_i   => hCntrTcR,        -- count on every horz. line
      clr_i     => vCntrTcR,        -- clear on TC
      ldVal_i   => "0",             -- load feature not used
      tCntVal_i => V_MAX_CNT,       -- terminal count
      cnt_o     => vCntrR,          -- count value
      tc_o      => vCntrTcR);       -- Terminal count flag

  -- Generate the vertical timing signals
  vBlankStart <= '1' when vCntrR=V_VISIBLE_CNT       else '0';
  vBlankEnd   <= '1' when vCntrR=V_BLANK_END_CNT     else '0';
  vSyncStart  <= '1' when vCntrR=V_FRONT_PORCH_END   else '0';
  vSyncEnd    <= '1' when vCntrR=V_SYNC_END          else '0';
  --srReg:  q         set           clear     clk     rst   RST_VAL='0'
--  scReg(vBlankR, vBlankStart, vCntrTcR, clk_i, rst_i);  -- gen the V blanking signal
  scReg(vBlankR, vBlankStart, vBlankEnd and hCntrTcR, clk_i, rst_i);  -- gen the V blanking signal
  scReg(vSyncR,  vSyncStart,  vSyncEnd,               clk_i, rst_i);  -- gen the V Sync signal

  -- Display char counter -- used to index the external display memory  
  display_cntr : entity work.vnCounter(rtl)
    port map (
      clk_i     => clk_i,           -- clock
      rst_i     => rst_i,           -- reset
      cntEn_i   => disCntrEn,
      clr_i     => vSyncR,          -- clear during vertical sync
      ldEn_i    => hSyncR,          -- Reload on horz sync
      ldVal_i   => currDisRowR,     -- load with the current char row
      tCntVal_i => DIS_MAX_CNT,     -- terminal count
      cnt_o     => disCntrR);       -- count value

  -- ***Increase margin of display RAM reads: change disCntrEn to (fontXCntrTcR or vSyncR)
  
  disCntrEn <= '1' when unsigned(fontXCntrR) = 1 else '0'; -- advance char counter after current one has started shifting out
  reg(currDisRowR, disCntrR, clk_i, rst_i, (disCntrR'range => '0'), (fontYCntrDone and hSyncR) or vSyncR); -- remember current char row

  -- Font X direction (column) counter -- used to control the shifter below
  font_x_cntr : entity work.vnCounter(rtl)
    port map (
      clk_i     => clk_i,           -- clock
      rst_i     => rst_i,           -- reset
      clr_i     => fontXCntrClr,           
      ldVal_i   => "0",
      tCntVal_i => FONT_X_MAX_CNT,
      cnt_o     => fontXCntrR,           
      tc_o      => fontXCntrTcR);
  fontXCntrClr <= fontXCntrTcR or hBlankR or vBlankR;

  font_shifter : entity work.vnShiftLeftReg(rtl)
    port map (
      clk_i     => clk_i,           -- clock
      rst_i     => rst_i,           -- reset
      ldEn_i    => fontXCntrClr,    -- load shifter
      ldVal_i   => fontDataR,       -- load value: a row of font data from the ROM
      reg_o     => shiftDataR);     -- shifted output

    -- ***Increase margin of display RAM reads: change shifter load to (fontXCntrTcR or vSyncR)

  -- Font Y (row) counter
  font_y_cntr : entity work.vnCounter(rtl)
    port map (
      clk_i     => clk_i,           -- clock
      rst_i     => rst_i,           -- reset
      cntEn_i   => hBlankStart,     -- bump counter during horizontal blank time
      clr_i     => fontYCntrClr,           
      ldVal_i   => "0",
      tCntVal_i => FONT_Y_MAX_CNT,
      cnt_o    => fontYCntrR,
      tc_o     => fontYCntrTcR);
  --srReg:  q              set           clear      clk    rst   RST_VAL='0'
  scReg(fontYCntrEndR, fontYCntrTcR, fontYCntrClr, clk_i, rst_i);
  fontYCntrDone <= fontYCntrTcR or fontYCntrEndR;
  fontYCntrClr <= (fontYCntrDone and hSyncR) or vBlankR;

  -- Hardware Cursor
  -- Are we at the display location of the cursor?
  atCursLoc <= '1' when disCntrR = cursLoc_i else '0';
  reg(atCursLocR, atCursLoc, clk_i, rst_i, '0', fontXCntrClr);  -- updates at each font row scan

  -- Are we at the font row where the under line cursor needs to be turn on?
  cursUlOn <= '1' when fontYCntrR = CURSOR_UL_ON_CNT else '0';
  --srReg:  q         set        clear      clk    rst   RST_VAL='0'
  scReg(cursUlOnR, cursUlOn, fontYCntrTcR, clk_i, rst_i);

  -- blinking cursor counter -- increments every frame and free running
  blink_cntr : entity work.vnCounter(rtl)
    port map (
      clk_i     => clk_i,           -- clock
      rst_i     => rst_i,           -- reset
      cntEn_i   => vCntrTcR,        -- bump counter every frame
      clr_i     => blinkCntrTcR,
      ldVal_i   => "0",
      tCntVal_i => BLINK_MAX_CNT,
      tc_o      => blinkCntrTcR,
      cnt_o     => blinkCntrR);
  reg(blinkR, not blinkR, clk_i, rst_i, '0', blinkCntrTcR);

  cursOn <= '0'                       when cursEn = '0'   or atCursLocR = '0' else
            blinkR or (not cursBlink) when cursMode = '1' or cursUlOnR = '1'  else
            '0';
  -- End of Hardware Cursor stuff

  -- Font ROM
  fontAddr  <= std_logic_vector((unsigned(disData_i) * to_unsigned(DIS_DESC.Font.Height, FONT_Y_CNTR_WIDTH)) + unsigned(fontYCntrR));
  reg(fontAddrR, fontAddr, clk_i, rst_i, (fontAddrR'range => '0'));
  -- A one VHDL line ROM:
  fontDataR <= DIS_DESC.Font.Data(to_integer(unsigned(fontAddrR))) when rising_edge(clk_i);
  
  -- Output pixel color mux (black if blanking and swap colors if drawing cursor)
  outColor  <= "000"    when (hBlankR or vBlankR)  = '1' else
               fgColorR when (outPixel xor cursOn) = '1' else
               bgColorR;

  -- Outputs (note all outputs are registered):
  disAddr_o <= disCntrR;		-- Address for the display RAM

  clk_output : process (clk_i, rst_i)
  begin
    if rst_i = '1' then
      hSync_o  <= '0';
      vSync_o  <= '0';
      fgColorR <= (others => '0');
      bgColorR <= (others => '0');
      color_o  <= (others => '0');
    elsif rising_edge(clk_i) then
      hSync_o <= (hSyncR and vgaEn_i) xor (not DIS_DESC.Vga.H_SyncPol);
      vSync_o <= (vSyncR and vgaEn_i) xor (not DIS_DESC.Vga.V_SyncPol);
      
      color_o <= outColor;
      
      if fontXCntrClr = '1' then
        -- grab the current color inputs at each font width boundary
        fgColorR <= fgColor_i;
        bgColorR <= bgColor_i;
      end if;
    end if;
  end process clk_output;
  
end rtl;
