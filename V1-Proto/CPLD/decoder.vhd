library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decoder is
	port(
		a: in std_logic_vector (15 downto 0);

		d: in std_logic_vector (7 downto 0);
		
		resetb: in std_logic;
		rwb: in std_logic;
		phi2: in std_logic;
		osc: in std_logic;
		
		ma: out std_logic_vector (19 downto 10);
		
		cs_vramb: out std_logic;
		cs_ram1b: out std_logic;
		cs_rom1b: out std_logic;
		cs_vdcb: out std_logic;
		cs_via1b: out std_logic;
		cs_via2b: out std_logic;
		cs_aciab: out std_logic;

		cpu_clk: in std_logic;
		vdc_dclk: in std_logic;
		vdc_romram: in std_logic;
		vdc_fontopt: in std_logic;
		
		j2: out std_logic_vector (7 downto 0)  -- J2 49=bit 7, 39=bit 0
	);
end decoder;

architecture rtl of decoder is

	signal vram : std_logic;
	signal ram1 : std_logic;
	signal f8xx : std_logic;
	signal f9xx : std_logic;
	signal via1 : std_logic;
	signal via2 : std_logic;
	signal vdc : std_logic;
	signal acia : std_logic;
	signal rom : std_logic;

begin

	vram <= '1' when a(15 downto 14) = "00" else '0';
	ram1 <= '1' when a(15 downto 14) = "01" else '0';

	via1 <= '1' when a(15 downto 4) = x"F80" else '0';
			  
	via2 <= '1' when a(15 downto 4) = x"F88" else '0';

	vdc  <= '1' when a(15 downto 4) = x"F90" and a(3 downto 1) = "000" else '0';

	acia <= '1' when a(15 downto 4) = x"F98" and a(3 downto 2) = "00" else '0';
	
	rom <= (not vram) and (not ram1) and (not via1) and 
			 (not via2) and (not vdc) and (not acia);

	-- vram, ram1, via1, via2, acia, vdc, rom 
	--   are active-high variables decoded from a0-15 only
	-- 
	-- phi2 and rwb are signals direct from the 6502
	-- 
	-- all chip select outputs are active-low
	cs_vramb <= not(phi2 and vram);
	cs_ram1b <= not(phi2 and ram1);
	cs_via1b <= not(via1);
	cs_via2b <= not(via2);
	cs_vdcb  <= not(vdc);
	cs_aciab <= not(acia);
	cs_rom1b <= not(rwb and rom);
	
	ma(15 downto 10) <= a(15 downto 10);
	
	ma(16) <= '1'; -- 27C010
	ma(17) <= '1'; -- 27C020
	ma(19 downto 18) <= "11"; -- 27C040 (will never be used)

end architecture rtl;
