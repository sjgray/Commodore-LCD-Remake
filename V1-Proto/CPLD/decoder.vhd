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

	-- MMU
	type mmu_mode_t is (MODE_KERN, MODE_APPL, MODE_RAM);
	signal mmu_kern_offset: std_logic_vector(7 downto 0);
	signal mmu_appl4_offset: std_logic_vector(7 downto 0);
	signal mmu_appl3_offset: std_logic_vector(7 downto 0);
	signal mmu_appl2_offset: std_logic_vector(7 downto 0);
	signal mmu_appl1_offset: std_logic_vector(7 downto 0);
	signal mmu_mode: mmu_mode_t;
	signal window_select: std_logic_vector(1 downto 0);
	signal active_offset: std_logic_vector(7 downto 0);
   signal is_bottom_4k : std_logic;  -- $0000-$0FFF: system RAM
   signal is_io_rom : std_logic;     -- $F800-$FFFF: I/O and ROM

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
	
	--ma(15 downto 10) <= a(15 downto 10);
	
	--ma(16) <= '1'; -- 27C010
	--ma(17) <= '1'; -- 27C020
	--ma(19 downto 18) <= "11"; -- 27C040 (will never be used)

	
	----------
	-- MMU
	-- determine which window we're in based on address bits 15:14
	is_bottom_4k <= '1' when a(15 downto 12) = x"0" else '0';
	is_io_rom <= '1' when a(15 downto 11) = "11111" else '0';  -- $F800-$FFFF

	-- select active offset based on mode and address
	active_offset <= 
		-- non-windowed regions: no offset
		(others => '0') when is_bottom_4k = '1' else
		(others => '0') when is_io_rom = '1' else
		  
		-- RAM mode: bottom 62K direct-mapped, no offset
		(others => '0') when mmu_mode = MODE_RAM else
		  
		-- KERN mode:
		-- $1000-$3FFF: direct-mapped (offset 0)
		(others => '0') when mmu_mode = MODE_KERN and a(15 downto 14) = "00" else
		-- $4000-$7FFF: kernel window (uses kernel offset)
		mmu_kern_offset when mmu_mode = MODE_KERN and a(15 downto 14) = "01" else
		-- $8000-$F7FF: maps to top of physical memory (fixed offset $C0)
		x"C0" when mmu_mode = MODE_KERN else
		  
		-- APPL mode (we've already excluded bottom 4K and I/O region above):
		mmu_appl1_offset when a(15 downto 14) = "00" else  -- $1000-$3FFF
		mmu_appl2_offset when a(15 downto 14) = "01" else  -- $4000-$7FFF
		mmu_appl3_offset when a(15 downto 14) = "10" else  -- $8000-$BFFF
		mmu_appl4_offset;                                   -- $C000-$F7FF

	-- apply offset to memory address
	ma(17 downto 10) <= std_logic_vector(unsigned("00" & a(15 downto 10)) + unsigned(active_offset));
	ma(19 downto 18) <= "11"; -- unused address lines for larger ROMs
	 
	process(phi2)
	begin
		if falling_edge(phi2) then
			if rwb = '0' then
				case a(15 downto 7) is  -- 9 bits: page + upper/lower half
					when x"FF" & '0' => mmu_kern_offset <= d;   -- FF00-FF7F
					when x"FE" & '1' => mmu_appl3_offset <= d;  -- FE80-FEFF
					when x"FE" & '0' => mmu_appl2_offset <= d;  -- FE00-FE7F
					when x"FD" & '1' => mmu_appl1_offset <= d;  -- FD80-FDFF
					when x"FD" & '0' => null;                   -- FD00-FD7F: TEST MODE
					when x"FC" & '1' => null;                   -- FC80-FCFF: SAVE/RECALL
					 
					-- mode switching (only address matters, data ignored)
					when x"FB" & '1' => mmu_mode <= MODE_RAM;   -- FB80-FBFF
					when x"FB" & '0' => mmu_mode <= MODE_APPL;  -- FB00-FB7F
					when x"FA" & '1' => mmu_mode <= MODE_APPL;  -- FA80-FAFF
					when x"FA" & '0' => mmu_mode <= MODE_KERN;  -- FA00-FA7F
						 
						when others => null;
				end case;
			end if;
		end if;
	end process;

end architecture rtl;
