--
-- Dual Port RAM -- modeled after a Xilinx example
--

library ieee;     use ieee.std_logic_1164.all;
                  use ieee.std_logic_unsigned.all;

entity vnDpRam is
  port (
    -- Port A: read and write
    clkaIn  : in std_logic;
    wrEnaIn : in std_logic;
    enaIn   : in std_logic := '1';
    addraIn : in std_logic_vector;
    dataaIn : in std_logic_vector;
    qaOut   : out std_logic_vector;
    -- Port B: read only
    clkbIn  : in std_logic;
    enbIn   : in std_logic := '1';
    addrbIn : in std_logic_vector;
    qbOut   : out std_logic_vector);
end vnDpRam;

architecture rtl of vnDpRam is
  constant RAM_LENGTH : natural := 2 ** addraIn'length;
  
  type ram_type is array (RAM_LENGTH-1 downto 0) of std_logic_vector (dataaIn'range);
  
  signal RAM: ram_type;
begin
  process (clkaIn)
  begin
    if rising_edge(clkaIn) then
      if enaIn = '1' then
        if wrEnaIn = '1' then
          RAM(conv_integer(addraIn)) <= dataaIn;
        end if;
        qaOut <= RAM(conv_integer(addraIn)) ;
      end if;
    end if;
  end process;
  
  process (clkbIn)
  begin
    if rising_edge(clkbIn) then
      if enbIn = '1' then
        qbOut <= RAM(conv_integer(addrbIn));
      end if;
    end if;
  end process;
end rtl;
