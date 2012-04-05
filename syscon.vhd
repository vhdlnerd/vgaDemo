--
-- Module: syscon
-- Based on Xilinx Architecture Wizard output
--

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
library UNISIM;
use UNISIM.Vcomponents.ALL;

entity syscon is
  generic (
    SYS_CLK_IN_PERIOD  : real := 31.125;         -- default to 32MHz input clock
    VGA_CLK_OUT_PERIOD : natural := 39722        -- default to ~25.175MHz
  );
   port ( sysClk_i       : in    std_logic;     -- external system clock input
          rst_i          : in    std_logic;     -- external async. reset input
          clkDiv2_o      : out   std_logic;     -- sysClk / 2 output
          clkVga_o       : out   std_logic;     -- VGA pixel clock
          clk_o          : out   std_logic;     -- sysClk
          clk2x_o        : out   std_logic;     -- sysClk * 2
          rst_o          : out   std_logic;
          vgaRst_o       : out   std_logic;
          locked_o       : out   std_logic);    -- DCM locked signal
end syscon;

architecture structure of syscon is
  type lut_rec_type is record 
    freq   : real;     -- in MHz
    period : natural;  -- in ps
    mul    : natural;  -- DCM's CLKFX_MULTIPLY value
    div    : natural;  -- DCM's CLKFX_DIVIDE value
  end record lut_rec_type;
  
  type lut_type is array (natural range <>) of lut_rec_type;
  
  constant LUT : lut_type := (
            ( 25.175, 39722, 11, 14),      -- ~ 0.13% error
            ( 50.000, 20000, 25, 16),      
            ( 65.000, 15385,  2,  1),      -- ~ 1.50% error
            ( 81.620, 12252, 23,  9),      -- ~ 0.19% error
            (108.000,  9259, 27,  8),
            (162.000,  6173,  5,  1)       -- ~ 1.23% error
           );
  
  function luDiv(key : natural) return natural is
  begin
    for i in LUT'range loop
      if LUT(i).period = key then
        return LUT(i).div;
      end if;
    end loop;
    -- ERROR!  Key not found
    assert false
    report "Key could not be found in the LUT, in function luDiv()!!!  Unsupported pixel clock period!"
    severity FAILURE;
    return 1;
  end function luDiv;

  function luMul(key : natural) return natural is
  begin
    for i in LUT'range loop
      if LUT(i).period = key then
        return LUT(i).mul;
      end if;
    end loop;
    -- ERROR!  Key not found
    assert false
    report "Key could not be found in the LUT, in function luMul()!!!  Unsupported pixel clock period!"
    severity FAILURE;
    return 1;
  end function luMul;

   constant CLKFX_MULTIPLY  : natural := luMul(VGA_CLK_OUT_PERIOD);
   constant CLKFX_DIVIDE    : natural := luDiv(VGA_CLK_OUT_PERIOD);
   
   signal CLKDV_BUF         : std_logic;
   signal clkFb             : std_logic;
   signal CLKFX_BUF         : std_logic;
   signal CLKIN_IBUFG       : std_logic;
   signal CLK0_BUF          : std_logic;
   signal CLK2X_BUF         : std_logic;
   signal GND_BIT           : std_logic;
   signal clkVga            : std_logic;
   signal locked            : std_logic;
   signal rstVec            : std_logic_vector(3 downto 0);
   signal vgaRstVec         : std_logic_vector(3 downto 0);

   attribute keep : boolean ;
   attribute keep of rstVec, vgaRstVec : signal is true ;
   
begin
   GND_BIT  <= '0';
   clk_o    <= clkFb;
   clkVga_o <= clkVga;
   locked_o <= locked;
   rst_o    <= rstVec(rstVec'left);
   vgaRst_o <= vgaRstVec(vgaRstVec'left);
   
   CLKDV_BUFG_INST : BUFG
      port map (I=>CLKDV_BUF, O=>clkDiv2_o);
   
   CLKFX_BUFG_INST : BUFG
      port map (I=>CLKFX_BUF, O=>clkVga);
   
   CLKIN_IBUFG_INST : IBUFG
      port map (I=>sysClk_i, O=>CLKIN_IBUFG);
   
   CLK0_BUFG_INST : BUFG
      port map (I=>CLK0_BUF, O=>clkFb);
   
   CLK2X_BUFG_INST : BUFG
      port map (I=>CLK2X_BUF, O=>clk2x_o);
   
   DCM_SP_INST : DCM_SP
   generic map( CLK_FEEDBACK => "1X",
            CLKDV_DIVIDE          => 2.0,
            CLKFX_DIVIDE          => CLKFX_DIVIDE,
            CLKFX_MULTIPLY        => CLKFX_MULTIPLY,
            CLKIN_DIVIDE_BY_2     => FALSE,
            CLKIN_PERIOD          => SYS_CLK_IN_PERIOD,
            CLKOUT_PHASE_SHIFT    => "NONE",
            DESKEW_ADJUST         => "SYSTEM_SYNCHRONOUS",
            DFS_FREQUENCY_MODE    => "LOW",
            DLL_FREQUENCY_MODE    => "LOW",
            DUTY_CYCLE_CORRECTION => TRUE,
            FACTORY_JF            => x"C080",
            PHASE_SHIFT           => 0,
            STARTUP_WAIT          => FALSE)
      port map (CLKFB     => clkFb,
                CLKIN     => CLKIN_IBUFG,
                DSSEN     => GND_BIT,
                PSCLK     => GND_BIT,
                PSEN      => GND_BIT,
                PSINCDEC  => GND_BIT,
                RST       => rst_i,
                CLKDV     => CLKDV_BUF,
                CLKFX     => CLKFX_BUF,
                CLKFX180  => open,
                CLK0      => CLK0_BUF,
                CLK2X     => CLK2X_BUF,
                CLK2X180  => open,
                CLK90     => open,
                CLK180    => open,
                CLK270    => open,
                LOCKED    => locked,
                PSDONE    => open,
                STATUS    => open);
   

  sysRst_inst : entity work.vnShiftLeftReg(rtl)
    generic map(
           RST_VAL   => "1"       -- Async reset value
    )
    port map(
           clk_i     => clkFb,    -- clock
           rst_i     => rst_i,    -- Active high reset
           data_i    => '0',      -- New serial data input
           ldVal_i   => "0",      -- Load value
           reg_o	   => rstVec    -- The shift register output
			  );

  vgaSysRst_inst : entity work.vnShiftLeftReg(rtl)
    generic map(
           RST_VAL   => "1"       -- Async reset value
    )
    port map(
           clk_i     => clkVga,   -- clock
           rst_i     => rst_i,    -- Active high reset
           data_i    => '0',      -- New serial data input
           ldVal_i   => "0",      -- Load value
           reg_o	   => vgaRstVec    -- The shift register output
			  );

end structure;


