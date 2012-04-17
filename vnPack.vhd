--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library ieee;		use ieee.std_logic_1164.all;
                use ieee.numeric_std.all;
                use ieee.math_real.all;

package vn_pack is

-- type <new_type> is
--  record
--    <type_name>        : std_logic_vector( 7 downto 0);
--    <type_name>        : std_logic;
-- end record;
--
-- Declare constants
--
-- constant <constant_name>		: time := <time_unit> ns;
-- constant <constant_name>		: integer := <value;
--
-- Declare functions and procedure
--
-- function <function_name>  (signal <signal_name> : in <type_declaration>) return <type_declaration>;
-- procedure <procedure_name> (<type_declaration> <constant_name>	: in <type_declaration>);
--

function to_std_logic_vector(i : natural; len : natural) return std_logic_vector;
function to_slv(i : natural; len : natural) return std_logic_vector;

function vecLen(n : natural) return natural;
function vecLen2(n : natural) return natural;
 
procedure reg(signal   q       :   out std_logic;
              constant d       : in    std_logic;
              signal   clk     : in    std_logic;
              signal   rst     : in    std_logic;
              constant RST_VAL : in    std_logic := '0';
              constant clkEn   : in    std_logic := '1');

procedure reg(signal   q       :   out std_logic_vector;
              constant d       : in    std_logic_vector;
              signal   clk     : in    std_logic;
              signal   rst     : in    std_logic;
              constant RST_VAL : in    std_logic_vector := "0";
              constant clkEn   : in    std_logic := '1');

procedure scReg(signal   q      :   out std_logic;
               constant set     : in    std_logic;
               constant clr     : in    std_logic;
               signal   clk     : in    std_logic;
               signal   rst     : in    std_logic;
               constant RST_VAL : in    std_logic := '0';
               constant CLR_PRI : in    std_logic := '0');
              
end vn_pack;

---------------------------------------------------

package body vn_pack is

function to_std_logic_vector(i : natural; len : natural) return std_logic_vector is
begin
  return std_logic_vector(to_unsigned(i, len));
end function to_std_logic_vector;

function to_slv(i : natural; len : natural) return std_logic_vector is
begin
  return std_logic_vector(to_unsigned(i, len));
end function to_slv;

--
-- Compute the length of a bit vector that can count up to 'n'
-- If you need a counter to count from 0 to 203, you can pass
-- 203 to this function and it will return 8 (i.e. an 8 bit
-- counter is required).  255 will return 8, also and 256 will 
-- return 9.
--
function vecLen(n : natural) return natural is
  variable t : unsigned(31 downto 0) := to_unsigned(n,32);
begin
  for i in t'range loop
    if t(i) = '1' then
      return i+1;
    end if;
  end loop;
  return 0;
end function vecLen;

function vecLen2(n : natural) return natural is
begin
  return natural(floor(log2(real(n))+1.0));
end function vecLen2;

procedure reg(signal   q       :   out std_logic;
              constant d       : in    std_logic;
              signal   clk     : in    std_logic;
              signal   rst     : in    std_logic;
              constant RST_VAL : in    std_logic := '0';
              constant clkEn   : in    std_logic := '1') is
begin
  if rst = '1' then
    q <= RST_VAL;
  elsif rising_edge(clk) then
    if clkEn = '1' then
      q <= d;
    end if;
  end if;
end procedure reg;

procedure reg(signal   q       :   out std_logic_vector;
              constant d       : in    std_logic_vector;
              signal   clk     : in    std_logic;
              signal   rst     : in    std_logic;
              constant RST_VAL : in    std_logic_vector := "0";
              constant clkEn   : in    std_logic := '1') is
begin
  if rst = '1' then
    if RST_VAL'length = 1 then
      q <= (q'range => RST_VAL(0));
    else
      q <= RST_VAL;
    end if;
  elsif rising_edge(clk) then
    if clkEn = '1' then
      q <= d;
    end if;
  end if;
end procedure reg;

procedure scReg(signal   q       :   out std_logic;
                constant set     : in    std_logic;
                constant clr     : in    std_logic;
                signal   clk     : in    std_logic;
                signal   rst     : in    std_logic;
                constant RST_VAL : in    std_logic := '0';
                constant CLR_PRI : in    std_logic := '0') is
begin
  if rst = '1' then
    q <= RST_VAL;
  elsif rising_edge(clk) then
    if CLR_PRI = '1' and clr = '1' then
      q <= '0';
    elsif set = '1' then
      q <= '1';
    elsif clr = '1' then
      q <= '0';
    end if;
  end if;
end procedure scReg;

---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;

---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;

---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;
 
end vn_pack;
