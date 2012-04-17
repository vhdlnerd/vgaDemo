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

library work;
use work.font_pack.all;
use work.vga_pack.all;

package display_pack is

  type Display_type is record
    -- VGA Timing
    Vga              : VgaTiming_type;
    -- Font info
    CursorHeight     : natural;       -- in pixels - height of underline cursor
    Font             : Font_type;     -- the font description
    -- Character Screen
    CharCols         : natural;       -- in Chars
    CharRows         : natural;       -- in Chars
  end record Display_type;

  -- Naming convention:
  --  DIS_wwwxhhh_cwxchxfff
  --    Where: www => Display width in pixels
  --           hhh => Display height in pixels
  --           cw  => Display width in chars
  --           ch  => Display heigth in chars
  --           fff => # chars defined in the font ROM
  constant DIS_640x480_80x40x256 : Display_type := (
    Vga              => VGA_640x480_60,   
    CursorHeight     => 2,
    Font             => FONT_8X12X256,
    CharCols         => VGA_640x480_60.H_Visible/FONT_8X12X256.Width,   -- =80
    CharRows         => VGA_640x480_60.V_Visible/FONT_8X12X256.Height   -- =40
  );

  constant DIS_SIM_ONLY : Display_type := (
    Vga              => VGA_SIM_ONLY,   
    CursorHeight     => 2,
    Font             => FONT_8X12X256,
    CharCols         => VGA_SIM_ONLY.H_Visible/FONT_8X12X256.Width,   -- =8
    CharRows         => VGA_SIM_ONLY.V_Visible/FONT_8X12X256.Height   -- =4
  );

  constant DIS_800x600_100x50x256 : Display_type := (
    Vga              => VGA_800x600_72,   
    CursorHeight     => 2,
    Font             => FONT_8X12X256,
    CharCols         => VGA_800x600_72.H_Visible/FONT_8X12X256.Width,   -- =100
    CharRows         => VGA_800x600_72.V_Visible/FONT_8X12X256.Height   -- =50
  );

  constant DIS_1024x768_128x64x256 : Display_type := (
    Vga              => VGA_1024x768_60,
    CursorHeight     => 2,
    Font             => FONT_8X12X256,
    CharCols         => VGA_1024x768_60.H_Visible/FONT_8X12X256.Width,   -- =128
    CharRows         => VGA_1024x768_60.V_Visible/FONT_8X12X256.Height   -- =64
  );

  constant DIS_1152x864_144x72x256 : Display_type := (
    Vga              => VGA_1152x864_60,
    CursorHeight     => 2,
    Font             => FONT_8X12X256,
    CharCols         => VGA_1152x864_60.H_Visible/FONT_8X12X256.Width,   -- =144
    CharRows         => VGA_1152x864_60.V_Visible/FONT_8X12X256.Height   -- =72
  );

  constant DIS_640x480_80x30x128 : Display_type := (
    Vga              => VGA_640x480_60,   
    CursorHeight     => 3,
    Font             => FONT_8X16X128,
    CharCols         => VGA_640x480_60.H_Visible/FONT_8X16X128.Width,   -- =80
    CharRows         => VGA_640x480_60.V_Visible/FONT_8X16X128.Height   -- =30
  );

  constant DIS_1152x864_144x54x128 : Display_type := (
    Vga              => VGA_1152x864_60,
    CursorHeight     => 3,
    Font             => FONT_8X16X128,
    CharCols         => VGA_1152x864_60.H_Visible/FONT_8X16X128.Width,   -- =144
    CharRows         => VGA_1152x864_60.V_Visible/FONT_8X16X128.Height   -- =54
  );

  constant DIS_1024x768_128x48x128 : Display_type := (
    Vga              => VGA_1024x768_60,
    CursorHeight     => 3,
    Font             => FONT_8X16X128,
    CharCols         => VGA_1024x768_60.H_Visible/FONT_8X16X128.Width,   -- =128
    CharRows         => VGA_1024x768_60.V_Visible/FONT_8X16X128.Height   -- =48
  );

  constant DIS_1280x1024_160x64x128 : Display_type := (
    Vga              => VGA_1280x1024_60,
    CursorHeight     => 3,
    Font             => FONT_8X16X128,
    CharCols         => VGA_1280x1024_60.H_Visible/FONT_8X16X128.Width,   -- =160
    CharRows         => VGA_1280x1024_60.V_Visible/FONT_8X16X128.Height   -- =64
  );
  
  constant DIS_1600x1200_200x75x128 : Display_type := (
    Vga              => VGA_1600x1200_60,
    CursorHeight     => 3,
    Font             => FONT_8X16X128,
    CharCols         => VGA_1600x1200_60.H_Visible/FONT_8X16X128.Width,   -- =200
    CharRows         => VGA_1600x1200_60.V_Visible/FONT_8X16X128.Height   -- =75
  );

  constant DIS_1152x864_144x54x128_FONT2 : Display_type := (
    Vga              => VGA_1152x864_60,
    CursorHeight     => 3,
    Font             => FONT_8X16X128_2,
    CharCols         => VGA_1152x864_60.H_Visible/FONT_8X16X128_2.Width,   -- =144
    CharRows         => VGA_1152x864_60.V_Visible/FONT_8X16X128_2.Height   -- =54
  );
  
end display_pack;

package body display_pack is
 
end display_pack;
