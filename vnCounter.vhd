----------------------------------------------------------------------------------
-- Designer: VhdlNerd
-- 
-- Create Date:    17:46:29 03/18/2012 
-- Design Name: 
-- Module Name:    vnCounter - rtl 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:    A Up/down counter with optional load and clear.
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--         o The width of the counter is determined by the length of the 'cnt_o'
--           port.
--         o Clear and load are synchronous to the clock (clear has priority over
--           load.
--         o All input control ports (rst_i, clr_i, upDn_i, cntEn_i, ldEn_i) are
--           active high.
--         o RST_VAL, ldVal_i, and tCntVal_i can by a vector of length one (i.e.
--           "0" or "1") or must be the same length as cnt_o.  (There is no
--           error checking and sim. and syn. will crash and burn if this is
--           violated.) 
--
----------------------------------------------------------------------------------
library ieee;		use ieee.std_logic_1164.all;
                use ieee.numeric_std.all;

entity vnCounter is
    generic (
           INCR_VAL  : integer := 1;                    -- How much the counter will increment by
           RST_VAL   : std_logic_vector := "0"          -- Async reset (and sync. clear) value
    );
    port ( clk_i     : in    std_logic;                 -- clock
           rst_i     : in    std_logic;                 -- Active high reset
           clr_i     : in    std_logic := '0';          -- Sync. clear
           upDn_i    : in    std_logic := '1';          -- 1=up/0=down
           cntEn_i   : in    std_logic := '1';          -- Counter enable (counter updates when this is 1)
           ldEn_i    : in    std_logic := '0';          -- 1=load counter with ldVal_i/0=count
           ldVal_i   : in    std_logic_vector := "0";   -- Load value
           tCntVal_i : in    std_logic_vector := "1";   -- Terminal Count Value
           cnt_o	   :   out std_logic_vector;          -- Current counter value
           tc_o	     :   out std_logic                  -- 1 = Terminal Count reached
			  );
end vnCounter;

architecture rtl of vnCounter is
  -- A helper function to expand a vector from length one to a vector of length 'size'.
  -- If the input vector is > length one then the input vector is returned.
  -- Note: there is no error checking for mismatched input and size given.
  function expand(value : std_logic_vector; size : natural) return std_logic_vector is
    variable ret : std_logic_vector(size-1 downto 0) := (others => value(0));
  begin
    if value'length /= 1 then
      ret := value;
    end if;
    return ret;
  end function expand;

  constant RESET_VAL : std_logic_vector(cnt_o'range) := expand(RST_VAL, cnt_o'length);

	signal cntR : std_logic_vector(cnt_o'range);
	signal tcR  : std_logic;

begin
  -- outputs
	tc_o  <= tcR;
	cnt_o <= cntR;

  ----------------------------------
	clkProc : process (clk_i, rst_i, ldVal_i, tCntVal_i, upDn_i, cntR)
          -- Note: the last 4 in the sensitivity list are not really needed
          --       but quiets a XST warning.
    variable  newCnt   : std_logic_vector(cnt_o'range);
    variable  ldVal    : std_logic_vector(cnt_o'range);
    variable  termVal  : std_logic_vector(cnt_o'range);
	begin
    ldVal    := expand(ldVal_i,   cnt_o'length);
    termVal  := expand(tCntVal_i, cnt_o'length);

    if upDn_i = '1' then
      newCnt := std_logic_vector(unsigned(cntR) + INCR_VAL);
    else
      newCnt := std_logic_vector(unsigned(cntR) - INCR_VAL);
    end if;

    if (rst_i = '1') then 
      -- Async reset
      tcR  <= '0';
      cntR <= RESET_VAL;
    elsif rising_edge(clk_i) then
      -- Deal with the counter:
      if clr_i = '1' then
        -- clear has the highest priority
        cntR <= RESET_VAL;
      elsif ldEn_i = '1' then
        cntR <= ldVal;
      elsif cntEn_i = '1' then
        cntR <= newCnt;
      end if;

      -- Deal with the terminal count flag:
      if newCnt = tCntVal_i and cntEn_i = '1' and ldEn_i = '0' and clr_i = '0' then
        -- do the easy thing and do not assert TC on a load or clear.
        tcR <= '1';
      else
        tcR <= '0';
      end if;
    end if;
	end process clkProc;
end rtl;
