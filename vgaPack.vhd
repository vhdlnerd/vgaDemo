--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package vga_Pack is
  constant SYNC_POL_NEG : std_logic := '0';
  constant SYNC_POL_POS : std_logic := '1';

  type VgaTiming_type is record
    PixelClockPeriod : natural;       -- in ps
    RefreshRate      : natural;       -- in Hz (not used, informational only)
    -- Horz. timing
    H_Visible        : natural;       -- in pixel clks
    H_FrontPorch     : natural;       -- in pixel clks
    H_Sync           : natural;       -- in pixel clks
    H_BackPorch      : natural;       -- in pixel clks
    H_SyncPol        : std_logic;     -- 0 = Neg/1 = Pos Polarity 
    -- Vert. timing
    V_Visible        : natural;       -- in scanlines
    V_FrontPorch     : natural;       -- in scanlines
    V_Sync           : natural;       -- in scanlines
    V_BackPorch      : natural;       -- in scanlines
    V_SyncPol        : std_logic;     -- 0 = Neg/1 = Pos Polarity 
  end record VgaTiming_type;

  -- Naming convention:
  --  VGA_wwwxhhh_rr
  --    Where: www => Display width in pixels
  --           hhh => Display height in pixels
  --           rr  => Refresh Rate
  constant VGA_640x480_60 : VgaTiming_type := (
    PixelClockPeriod => 39722,  -- in ps -> 25.175Mhz -- (or use 25Mhz -- its close enough)
    RefreshRate      => 60,
    H_Visible        => 640,
    H_FrontPorch     => 16, 
    H_Sync           => 96, 
    H_BackPorch      => 48, 
    H_SyncPol        => SYNC_POL_NEG,
    V_Visible        => 480,
    V_FrontPorch     => 10, 
    V_Sync           => 2,  
    V_BackPorch      => 33,
    V_SyncPol        => SYNC_POL_NEG
  );

  constant VGA_SIM_ONLY : VgaTiming_type := (
    PixelClockPeriod => 39722,  -- in ps -> 25.175Mhz -- (or use 25Mhz -- its close enough)
    RefreshRate      => 60,
    H_Visible        => 64,
    H_FrontPorch     => 6, 
    H_Sync           => 8, 
    H_BackPorch      => 4, 
    H_SyncPol        => SYNC_POL_NEG,
    V_Visible        => 48,
    V_FrontPorch     => 4, 
    V_Sync           => 2,  
    V_BackPorch      => 5,
    V_SyncPol        => SYNC_POL_POS
  );

--  constant VGA_640x480_60 : VgaTiming_type := (
--    PixelClockPeriod => 40000,  -- in ps -> 25Mhz
--    RefreshRate      => 60,
--    H_Visible        => 640,
--    H_FrontPorch     => 17, 
--    H_Sync           => 93, 
--    H_BackPorch      => 44, 
--    H_SyncPol        => '0',
--    V_Visible        => 480,
--    V_FrontPorch     => 10, 
--    V_Sync           => 2,  
--    V_BackPorch      => 33,
--    V_SyncPol        => '0'
--  );

  constant VGA_800x600_72 : VgaTiming_type := (
    PixelClockPeriod => 20000,  -- in ps -> 50Mhz
    RefreshRate      => 72,
    H_Visible        => 800,
    H_FrontPorch     => 56, 
    H_Sync           => 120, 
    H_BackPorch      => 64, 
    H_SyncPol        => SYNC_POL_POS,
    V_Visible        => 600,
    V_FrontPorch     => 37, 
    V_Sync           => 6,  
    V_BackPorch      => 23, 
    V_SyncPol        => SYNC_POL_POS
  );

  constant VGA_1024x768_60 : VgaTiming_type := (
    PixelClockPeriod => 15385,  -- in ps -> 65Mhz
    RefreshRate      => 60,
    H_Visible        => 1024,
    H_FrontPorch     => 24, 
    H_Sync           => 136, 
    H_BackPorch      => 160, 
    H_SyncPol        => SYNC_POL_NEG,
    V_Visible        => 768,
    V_FrontPorch     => 3, 
    V_Sync           => 6,  
    V_BackPorch      => 29, 
    V_SyncPol        => SYNC_POL_NEG
  );

    constant VGA_1152x864_60 : VgaTiming_type := (
    PixelClockPeriod => 12252,  -- in ps -> 81.62Mhz
    RefreshRate      => 60,
    H_Visible        => 1152,
    H_FrontPorch     => 64, 
    H_Sync           => 120, 
    H_BackPorch      => 184, 
    H_SyncPol        => SYNC_POL_NEG,
    V_Visible        => 864,
    V_FrontPorch     => 1, 
    V_Sync           => 3,  
    V_BackPorch      => 27, 
    V_SyncPol        => SYNC_POL_POS
  );

    constant VGA_1280x1024_60 : VgaTiming_type := (
    PixelClockPeriod => 9259,  -- in ps -> 108Mhz
    RefreshRate      => 60,
    H_Visible        => 1280,
    H_FrontPorch     => 48, 
    H_Sync           => 112, 
    H_BackPorch      => 248, 
    H_SyncPol        => SYNC_POL_POS,
    V_Visible        => 1024,
    V_FrontPorch     => 1, 
    V_Sync           => 3,  
    V_BackPorch      => 38, 
    V_SyncPol        => SYNC_POL_POS
  );

    constant VGA_1600x1200_60 : VgaTiming_type := (
    PixelClockPeriod => 6173,  -- in ps -> 162Mhz
    RefreshRate      => 60,
    H_Visible        => 1600,
    H_FrontPorch     => 64, 
    H_Sync           => 192, 
    H_BackPorch      => 304, 
    H_SyncPol        => SYNC_POL_POS,
    V_Visible        => 1200,
    V_FrontPorch     => 1, 
    V_Sync           => 3,  
    V_BackPorch      => 46, 
    V_SyncPol        => SYNC_POL_POS
  );

end vga_Pack;

package body vga_Pack is
 
end vga_Pack;
