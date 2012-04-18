#include <SPI.h>

// set pin 53 as the slave select for Papilio One w/ vgaDemo:
//const int slaveSelectPin = 10;
const int slaveSelectPin = 53;


////////////////////////////////////////
#define _SpiVGA_WR_CURS_CNTL  (0x00)
#define _SpiVGA_WR_FG_COLOR   (0x01)
#define _SpiVGA_WR_BG_COLOR   (0x02)
#define _SpiVGA_WR_INVERSE    (0x03)
#define _SpiVGA_WR_POS_HI     (0x04)
#define _SpiVGA_WR_POS_LO     (0x05)
#define _SpiVGA_WR_EMIT       (0x06)
#define _SpiVGA_WR_EMIT_INCR  (0x07)
#define _SpiVGA_WR_FILL       (0x08)

#define _SpiVGA_RD_CURS_CNTL  (0x80)
#define _SpiVGA_RD_FG_COLOR   (0x81)
#define _SpiVGA_RD_BG_COLOR   (0x82)
#define _SpiVGA_RD_INVERSE    (0x83)
#define _SpiVGA_RD_POS_HI     (0x84)
#define _SpiVGA_RD_POS_LO     (0x85)
#define _SpiVGA_RD_CHAR       (0x86)
#define _SpiVGA_RD_CHAR_ATTR  (0x88)
#define _SpiVGA_RD_DIS_COLS   (0x90)
#define _SpiVGA_RD_DIS_ROWS   (0x91)
#define _SpiVGA_RD_DIS_COLOR_BITS   (0x92)
#define _SpiVGA_RD_DIS_COLOR_MODE   (0x93)
#define _SpiVGA_RD_DIS_FONT_ID (0x94)

#define CURSOR_ON             (0x01)
#define CURSOR_OFF            (0x00)
#define CURSOR_BLOCK          (0x02)
#define CURSOR_BLINK          (0x04)

enum LineParts {hBar=0,vBar,lTee,rTee,uTee,bTee,cross,ulC,urC,blC,brC};
const uint8_t fontLines1[11] = {0xCA,0xC5,0xCD,0xC7,0xCB,0xCE,0xCF,0xC6,0xCC,0xC3,0xC9};
const uint8_t fontLinesX[11] = {'-','|','+','+','+','+','+','+','+','+','+'};

class SpiVGA {
private:
  uint8_t  slaveSelectPin;
  boolean  rawMode;
  uint8_t dCols, dRows;    // in chars
  uint8_t dColorBits, dColorMode;
  uint8_t dFontId;
  const uint8_t *fontLines;

public:
  SpiVGA(uint8_t SSPin);

  void Init(void);
  void SetFG(uint8_t color);
  void SetBG(uint8_t color);
  void SetInv(uint8_t flag);
  void FillScreen(byte fillChar);
  void Cls(void) {FillScreen(' ');};
  void SetLoc(uint16_t offset);
  void SetLoc(uint16_t row, uint16_t col);
  void CursorStyle(uint8_t style);
  void EmitChar(char c);
  void OutChar(char c);
  void OutStr(char *s);
  void Box(uint8_t x1, uint8_t y1, uint8_t x2, uint8_t y2, boolean dl=false); 
  void hLine(uint8_t x1, uint8_t x2, uint8_t y, boolean dl=false); 
  void vLine(uint8_t x, uint8_t y1, uint8_t y2, boolean dl=false); 
  uint8_t toLineChar(LineParts n) {return fontLines[n];};
  
  uint8_t FetchCursorStyle(void) {return rd(_SpiVGA_RD_CURS_CNTL);};
  uint8_t FetchFGColor(void) {return rd(_SpiVGA_RD_FG_COLOR);};
  uint8_t FetchBGColor(void) {return rd(_SpiVGA_RD_BG_COLOR);};
  uint8_t FetchInv(void) {return rd(_SpiVGA_RD_INVERSE);};
  uint8_t FetchDisCols(void) {return rd(_SpiVGA_RD_DIS_COLS);};
  uint8_t FetchDisRows(void) {return rd(_SpiVGA_RD_DIS_ROWS);};
  uint8_t FetchDisColorBits(void) {return rd(_SpiVGA_RD_DIS_COLOR_BITS);};
  uint8_t FetchDisColorMode(void) {return rd(_SpiVGA_RD_DIS_COLOR_MODE);};
  uint8_t FetchDisFontId(void) {return rd(_SpiVGA_RD_DIS_FONT_ID);};

  uint8_t GetDisCols(void) {return dCols;};
  uint8_t GetDisRows(void) {return dRows;};
  uint8_t GetDisColorBits(void) {return dColorBits;};
  uint8_t GetDisColorMode(void) {return dColorMode;};
  uint8_t GetDisFontId(void) {return dFontId;};

private:
  void wrReg(uint8_t addr, uint8_t data);
  uint8_t rd(uint8_t addr);
  
};

SpiVGA::SpiVGA(uint8_t SSPin) {
  slaveSelectPin = SSPin;
  rawMode        = true;
  dCols          = 128;
  dRows          = 64;
  dColorBits     = 3;
  dColorMode     = 1;
  dFontId        = 1;
}

void SpiVGA::Init(void) {
  dCols      = FetchDisCols();
  dRows      = FetchDisRows();
  dColorBits = FetchDisColorBits();
  dColorMode = FetchDisColorMode();
  dFontId    = FetchDisFontId();
  if (dFontId==1) 
    fontLines  = fontLines1;
  else
    fontLines  = fontLinesX;
}

void SpiVGA::hLine(uint8_t x1, uint8_t x2, uint8_t y, boolean dl) {
  uint8_t  i, n;

  if (x2<=x1) return;
  
  n = x2-x1+1;
  SetLoc(y,x1);
  for (i=0; i<n; i++)
    OutChar(fontLines[hBar]);
}

void SpiVGA::vLine(uint8_t x, uint8_t y1, uint8_t y2, boolean dl) {
  uint8_t  i, n;

  if (y2<=y1) return;

  n = y2-y1+1;
  for (i=0; i<n; i++) {
    SetLoc(y1+i,x);
    OutChar(fontLines[vBar]);
  }
}

void SpiVGA::Box(uint8_t x1, uint8_t y1, uint8_t x2, uint8_t y2, boolean dl) {
  uint8_t  i, n;
  
  if (x2<=x1 || y2<=y1) return;
  
  SetLoc(y1,x1);
  OutChar(fontLines[ulC]);
  n = x2-x1-1;
  for (i=0; i<n; i++)
    OutChar(fontLines[hBar]);
  OutChar(fontLines[urC]);

  n = y2-y1-1;
  for (i=0; i<n; i++) {
    SetLoc(y1+i+1,x1);
    OutChar(fontLines[vBar]);
    SetLoc(y1+i+1,x2);
    OutChar(fontLines[vBar]);
  }

  SetLoc(y2,x1);
  OutChar(fontLines[blC]);
  n = x2-x1-1;
  for (i=0; i<n; i++)
    OutChar(fontLines[hBar]);
  OutChar(fontLines[brC]);
}

uint8_t SpiVGA::rd(uint8_t addr) {
  uint8_t ret;
  
  // take the SS pin low to select the chip:
  digitalWrite(slaveSelectPin,LOW);
  SPI.transfer(addr);
  SPI.transfer(0xAA);  // does not matter what we write
  ret = SPI.transfer(0xAA);  // does not matter what we write
  // take the SS pin high to de-select the chip:
  digitalWrite(slaveSelectPin,HIGH); 
  return ret;
}


void SpiVGA::wrReg(uint8_t addr, uint8_t data) {
  // take the SS pin low to select the chip:
  digitalWrite(slaveSelectPin,LOW);
  SPI.transfer(addr);
//  digitalWrite(slaveSelectPin,HIGH); 
//  digitalWrite(slaveSelectPin,LOW);
  SPI.transfer(data);
  // take the SS pin high to de-select the chip:
  digitalWrite(slaveSelectPin,HIGH); 
}

void SpiVGA::FillScreen(byte fillChar) {
  wrReg(_SpiVGA_WR_FILL, fillChar);
  delay(40);
}

void SpiVGA::SetLoc(uint16_t offset) {
  wrReg(_SpiVGA_WR_POS_HI, (offset>>8)&0xFF);
  wrReg(_SpiVGA_WR_POS_LO, offset&0xFF);
}

void SpiVGA::SetLoc(uint16_t row, uint16_t col) {
  SetLoc(row*dCols+col);
}

void SpiVGA::CursorStyle(uint8_t style) {
  wrReg(_SpiVGA_WR_CURS_CNTL, style);
}

void SpiVGA::EmitChar(char c) {
  wrReg(_SpiVGA_WR_EMIT, c);
}

void SpiVGA::OutChar(char c) {
  wrReg(_SpiVGA_WR_EMIT_INCR, c);
}

void SpiVGA::OutStr(char *s) {
  digitalWrite(slaveSelectPin,LOW);
  while (*s != 0) {
    SPI.transfer(_SpiVGA_WR_EMIT_INCR);
    SPI.transfer(*s++);
  }
  digitalWrite(slaveSelectPin,HIGH); 
}

void SpiVGA::SetFG(uint8_t color) {
  wrReg(_SpiVGA_WR_FG_COLOR, color);
}

void SpiVGA::SetBG(uint8_t color) {
  wrReg(_SpiVGA_WR_BG_COLOR, color);
}

void SpiVGA::SetInv(uint8_t flag) {
  wrReg(_SpiVGA_WR_INVERSE, flag);
}

////////////////////////////////////////

SpiVGA vga(slaveSelectPin);

void setup() {
  // start the SPI library:
  SPI.setDataMode(SPI_MODE0);
  SPI.setBitOrder(MSBFIRST);
  SPI.setClockDivider(SPI_CLOCK_DIV2);
  SPI.begin();
  vga.Init();
}

const char hexLut[] = "0123456789ABCDEF";

void OutHex2 (uint8_t n) {
  vga.OutChar(hexLut[(n>>4)&0xF]);
  vga.OutChar(hexLut[n&0xF]);
}

void repeatStr(char *s, uint8_t n) {
  for (uint8_t i=0; i<n; i++)
    vga.OutStr(s);
}

void loop() {
  uint8_t  cs, n, m, i, j, c, off;
  
  vga.Cls();
  vga.CursorStyle(CURSOR_OFF);
  // set BG color to black
  vga.SetBG(0x00);
  // set FG color to green
  vga.SetFG(0x02);
  
  n = vga.GetDisCols()-1;
  m = vga.GetDisRows()-1;
  c=1;
  for (i=0; i<vga.GetDisRows()/2; i++,n--, m--) {
    if (vga.GetDisColorMode() == 1) {
      vga.SetFG(c);
    }
    vga.Box(i,i,n,m);
    c++;
    if (c==1<<vga.GetDisColorBits()) {
        c =1;
    }
  }
  delay(3000);
  
  // demo the HW cursor
  vga.SetFG(0x03);
  vga.Cls();
  vga.CursorStyle(CURSOR_ON|CURSOR_BLINK);
  vga.SetLoc(5,0);
  vga.OutStr("This is the blinking underline HW cursor");
  delay(2000);
  vga.SetLoc(5,0);
  delay(2000);

  vga.Cls();
  vga.CursorStyle(CURSOR_ON|CURSOR_BLINK|CURSOR_BLOCK);
  vga.SetLoc(6,0);
  vga.OutStr("This is the blinking block HW cursor");
  delay(2000);
  vga.SetLoc(6,0);
  delay(2000);

  vga.Cls();
  vga.CursorStyle(CURSOR_ON);
  vga.SetLoc(7,0);
  vga.OutStr("This is the non-blinking underline HW cursor");
  delay(2000);
  vga.SetLoc(7,0);
  delay(2000);

  vga.Cls();
  vga.CursorStyle(CURSOR_ON|CURSOR_BLOCK);
  vga.SetLoc(8,0);
  vga.OutStr("This is the non-blinking block HW cursor");
  delay(2000);
  vga.SetLoc(8,0);
  delay(2000);

  // Display a nice looking ASCII Table
  off = 3;
  vga.Cls();
  vga.CursorStyle(CURSOR_OFF);
  if (vga.GetDisColorMode() == 1) {
    vga.SetBG(0x06);
    vga.SetFG(0x00);
  } else {
    vga.SetBG(0x00);
    vga.SetFG(0x06);
    vga.SetInv(1);
  }
  n = (vga.GetDisCols()-(8*8+7))/2+1;
  m = (vga.GetDisFontId()==1?32:16);
  vga.SetLoc(off+1, n);
  repeatStr(" ", 24);
  vga.OutStr("--== ASCII Table ==--");
  repeatStr(" ", 24);
  vga.SetBG(0x00);
  vga.SetFG(0x06);
  vga.SetInv(0x00);
  
  for (i=0; i<m; i++) {
    vga.SetLoc(i+off+3, n);
    for (j=0; j<8; j++) {
      OutHex2(i+j*m);
      vga.OutStr(" : ");
      vga.OutChar(i+j*m);
      vga.OutStr("   ");
    }
  }
  vga.Box(n-2, off, n+70, off+2+m+1);
  vga.hLine(n-1, n+69, off+2);
  vga.SetLoc(off+2, n-2);
  vga.OutChar(vga.toLineChar(rTee)); 
  vga.SetLoc(off+2, n+70);
  vga.OutChar(vga.toLineChar(lTee)); 
  for (i=0; i<7; i++) {
    j = n+(i*9)+7;
    vga.vLine(j, off+3, off+2+m);
    vga.SetLoc(off+2, j);
    vga.OutChar(vga.toLineChar(bTee)); 
    vga.SetLoc(off+3+m, j);
    vga.OutChar(vga.toLineChar(uTee)); 
  }
  delay(4000);

  vga.SetBG(0x00);
  vga.SetFG(0x04);
  vga.Cls();
  vga.SetLoc(0x01, 0x01);
  vga.OutStr("   Display Columns : 0x");
  OutHex2(vga.GetDisCols());
  vga.SetLoc(0x02, 0x01);
  vga.OutStr("      Display Rows : 0x");
  OutHex2(vga.GetDisRows());
  vga.SetLoc(0x03, 0x01);
  vga.OutStr("Display Color Bits : 0x");
  OutHex2(vga.GetDisColorBits());
  vga.SetLoc(0x04, 0x01);
  vga.OutStr("Display Color Mode : 0x");
  OutHex2(vga.GetDisColorMode());
  vga.SetLoc(0x05, 0x01);
  vga.OutStr("   Display Font ID : 0x");
  OutHex2(vga.GetDisFontId());
  vga.SetFG(0x07);
  vga.Box(0,0,26,6);
  delay(3000);
}

