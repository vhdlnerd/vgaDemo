----------------------------------------------------------------------------------
-- Designer: VhdlNerd
-- 
-- Create Date:    03/24/2012 
-- Design Name: 
-- Module Name:    vnShiftLeftReg - rtl 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:    A shift left register with load feature and serial input.
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--         o The width of the shift register is determined by the length of the 'reg_o'
--           port.
--         o RST_VAL and ldVal_i can by a vector of length one (i.e.
--           "0" or "1") or must be the same length as reg_o.  (There is no
--           error checking and sim. and syn. will crash and burn if this is
--           violated.) 
--
----------------------------------------------------------------------------------
library ieee;		use ieee.std_logic_1164.all;
                use ieee.numeric_std.all;

entity vnShiftLeftReg is
    generic (
           RST_VAL   : std_logic_vector := "0"          -- Async reset value
    );
    port ( clk_i     : in    std_logic;                 -- clock
           rst_i     : in    std_logic;                 -- Active high reset
           data_i    : in    std_logic := '0';          -- New serial data input
           ldEn_i    : in    std_logic := '0';          -- 1=load counter with ldVal_i/0=count
           ldVal_i   : in    std_logic_vector;          -- Load value
           shEn_i    : in    std_logic := '1';          -- shift enable
           reg_o	   :   out std_logic_vector           -- The shift register output
			  );
end vnShiftLeftReg;

architecture rtl of vnShiftLeftReg is
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

  constant RESET_VAL : std_logic_vector(reg_o'range) := expand(RST_VAL, reg_o'length);

	signal regR : std_logic_vector(reg_o'length-1 downto 0);

begin
  -- output
	reg_o <= regR;

  ----------------------------------
	clkProc : process (clk_i, rst_i, ldVal_i)
    variable  ldVal    : std_logic_vector(reg_o'range);
	begin
    ldVal    := expand(ldVal_i, reg_o'length);

    if (rst_i = '1') then 
      -- Async reset
      regR <= RESET_VAL;
    elsif rising_edge(clk_i) then
      if ldEn_i = '1' then
        regR <= ldVal;
      elsif shEn_i = '1' then
        regR <= regR(regR'left-1 downto 0) & data_i;
      end if;
    end if;
	end process clkProc;
end rtl;
