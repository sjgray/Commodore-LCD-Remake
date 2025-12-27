library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decoder_testbench is
end;

architecture rtl of decoder_testbench is

-- MMU register addresses
constant MMU_KERN_OFFSET  : std_logic_vector(15 downto 0) := x"FF00";
constant MMU_APPL4_OFFSET : std_logic_vector(15 downto 0) := x"FE80";
constant MMU_APPL3_OFFSET : std_logic_vector(15 downto 0) := x"FE00";
constant MMU_APPL2_OFFSET : std_logic_vector(15 downto 0) := x"FD80";
constant MMU_APPL1_OFFSET : std_logic_vector(15 downto 0) := x"FD00";

-- Mode switching addresses
constant MMU_MODE_KERN : std_logic_vector(15 downto 0) := x"FA00";
constant MMU_MODE_APPL : std_logic_vector(15 downto 0) := x"FB00";
constant MMU_MODE_RAM  : std_logic_vector(15 downto 0) := x"FB80";

-- I/O addresses
constant VIA1_BASE : std_logic_vector(15 downto 0) := x"F800";
constant VIA2_BASE : std_logic_vector(15 downto 0) := x"F880";
constant VDC_BASE  : std_logic_vector(15 downto 0) := x"F900";
constant ACIA_BASE : std_logic_vector(15 downto 0) := x"F980";

-- Signals matching decoder ports
signal a : std_logic_vector(15 downto 0) := (others => '0');
signal d : std_logic_vector(7 downto 0) := (others => '0');
signal resetb : std_logic := '0';
signal rwb : std_logic := '1';
signal phi2 : std_logic := '0';
signal osc : std_logic := '0';
signal ma : std_logic_vector(19 downto 10);
signal cs_vramb : std_logic;
signal cs_ram1b : std_logic;
signal cs_rom1b : std_logic;
signal cs_vdcb : std_logic;
signal cs_via1b : std_logic;
signal cs_via2b : std_logic;
signal cs_aciab : std_logic;
signal cpu_clk : std_logic := '0';
signal vdc_dclk : std_logic := '0';
signal vdc_romram : std_logic := '0';
signal vdc_fontopt : std_logic := '0';
signal j2 : std_logic_vector(7 downto 0);

begin
	uut: entity work.decoder
	port map (
		a => a,
		d => d,
		resetb => resetb,
		rwb => rwb,
		phi2 => phi2,
		osc => osc,
		ma => ma,
		cs_vramb => cs_vramb,
		cs_ram1b => cs_ram1b,
		cs_rom1b => cs_rom1b,
		cs_vdcb => cs_vdcb,
		cs_via1b => cs_via1b,
		cs_via2b => cs_via2b,
		cs_aciab => cs_aciab,
		cpu_clk => cpu_clk,
		vdc_dclk => vdc_dclk,
		vdc_romram => vdc_romram,
		vdc_fontopt => vdc_fontopt,
		j2 => j2
	);

	phi2_process: process
	begin
		while true loop
			wait for 500 ns;
			phi2 <= not phi2;
		end loop;
	end process;

	osc_process: process
	begin
		while true loop
			wait for 20 ns;
			osc <= not osc;
		end loop;
	end process;

	stimulus: process

	procedure cpuWrite(address: std_logic_vector(15 downto 0); data: std_logic_vector(7 downto 0)) is
	begin
		wait until phi2 = '1';
		rwb <= '0';
		a <= address;
		d <= data;
		wait until phi2 = '0';
		rwb <= '1';
		d <= (others => '0');
	end;

	procedure cpuRead(address: std_logic_vector(15 downto 0)) is
	begin
		wait until phi2 = '1';
		rwb <= '1';
		a <= address;
		wait until phi2 = '0';
	end;

	-- Initialize all MMU registers to known state (as firmware would do)
	procedure initMMU is
	begin
		cpuWrite(MMU_KERN_OFFSET, x"00");
		cpuWrite(MMU_APPL1_OFFSET, x"00");
		cpuWrite(MMU_APPL2_OFFSET, x"00");
		cpuWrite(MMU_APPL3_OFFSET, x"00");
		cpuWrite(MMU_APPL4_OFFSET, x"00");
		cpuWrite(MMU_MODE_KERN, x"00");  -- start in kernel mode
	end;

	begin
		-- Brief reset pulse (doesn't initialize MMU registers)
		resetb <= '0';
		wait for 100 ns;
		resetb <= '1';
		wait for 100 ns;

		-----------------------------------------------
		-- Initialize MMU (as boot firmware would)
		-----------------------------------------------
		report "Initializing MMU registers";
		initMMU;

		-----------------------------------------------
		-- Test 1: Chip select decoding
		-----------------------------------------------
		report "Test 1: Chip select decoding";

		-- VRAM ($0000-$3FFF)
		cpuRead(x"0000");
		wait until phi2 = '1';
		assert cs_vramb = '0' report "VRAM CS should be active at $0000" severity error;
		wait until phi2 = '0';

		cpuRead(x"3FFF");
		wait until phi2 = '1';
		assert cs_vramb = '0' report "VRAM CS should be active at $3FFF" severity error;
		wait until phi2 = '0';

		-- RAM1 ($4000-$7FFF)
		cpuRead(x"4000");
		wait until phi2 = '1';
		assert cs_ram1b = '0' report "RAM1 CS should be active at $4000" severity error;
		wait until phi2 = '0';

		-- VIA1 ($F800-$F80F)
		cpuRead(VIA1_BASE);
		assert cs_via1b = '0' report "VIA1 CS should be active at $F800" severity error;

		-- VIA2 ($F880-$F88F)
		cpuRead(VIA2_BASE);
		assert cs_via2b = '0' report "VIA2 CS should be active at $F880" severity error;

		-- VDC ($F900-$F901)
		cpuRead(VDC_BASE);
		assert cs_vdcb = '0' report "VDC CS should be active at $F900" severity error;

		-- ACIA ($F980-$F983)
		cpuRead(ACIA_BASE);
		assert cs_aciab = '0' report "ACIA CS should be active at $F980" severity error;

		-----------------------------------------------
		-- Test 2: Kernel mode address translation
		-----------------------------------------------
		report "Test 2: Kernel mode address translation";

		-- Set kernel offset to $10
		cpuWrite(MMU_KERN_OFFSET, x"10");
		cpuWrite(MMU_MODE_KERN, x"00");

		-- Kernel window ($4000-$7FFF): a(15:10)=010000 + $10 = $20
		cpuRead(x"4000");
		wait until phi2 = '1';
		assert ma(17 downto 10) = x"20"
			report "KERN: $4000 + offset $10 -> ma should be $20, got " &
				   integer'image(to_integer(unsigned(ma(17 downto 10))))
			severity error;
		wait until phi2 = '0';

		-- Test another address in kernel window
		cpuRead(x"5000");
		wait until phi2 = '1';
		-- a(15:10) = 010100 (20), + $10 = $24
		assert ma(17 downto 10) = x"24"
			report "KERN: $5000 + offset $10 -> ma should be $24"
			severity error;
		wait until phi2 = '0';

		-----------------------------------------------
		-- Test 3: Application mode with different windows
		-----------------------------------------------
		report "Test 3: Application mode address translation";

		-- Set up different offsets for each window
		cpuWrite(MMU_APPL1_OFFSET, x"10");  -- Window 1: $1000-$3FFF
		cpuWrite(MMU_APPL2_OFFSET, x"20");  -- Window 2: $4000-$7FFF
		cpuWrite(MMU_APPL3_OFFSET, x"30");  -- Window 3: $8000-$BFFF
		cpuWrite(MMU_APPL4_OFFSET, x"40");  -- Window 4: $C000-$F7FF
		cpuWrite(MMU_MODE_APPL, x"00");

		-- Window 1: $1000, a(15:10)=000100 (4), + $10 = $14
		cpuRead(x"1000");
		wait until phi2 = '1';
		assert ma(17 downto 10) = x"14"
			report "APPL W1: $1000 + offset $10 -> ma should be $14"
			severity error;
		wait until phi2 = '0';

		-- Window 2: $4000, a(15:10)=010000 (16), + $20 = $30
		cpuRead(x"4000");
		wait until phi2 = '1';
		assert ma(17 downto 10) = x"30"
			report "APPL W2: $4000 + offset $20 -> ma should be $30"
			severity error;
		wait until phi2 = '0';

		-- Window 3: $8000, a(15:10)=100000 (32), + $30 = $50
		cpuRead(x"8000");
		wait until phi2 = '1';
		assert ma(17 downto 10) = x"50"
			report "APPL W3: $8000 + offset $30 -> ma should be $50"
			severity error;
		wait until phi2 = '0';

		-- Window 4: $C000, a(15:10)=110000 (48), + $40 = $70
		cpuRead(x"C000");
		wait until phi2 = '1';
		assert ma(17 downto 10) = x"70"
			report "APPL W4: $C000 + offset $40 -> ma should be $70"
			severity error;
		wait until phi2 = '0';

		-----------------------------------------------
		-- Test 4: RAM mode (no offset applied)
		-----------------------------------------------
		report "Test 4: RAM mode address translation";

		cpuWrite(MMU_MODE_RAM, x"00");

		-- $4000: a(15:10)=010000 (16), no offset = $10
		cpuRead(x"4000");
		wait until phi2 = '1';
		assert ma(17 downto 10) = x"10"
			report "RAM: $4000 -> ma should be $10 (no offset)"
			severity error;
		wait until phi2 = '0';

		-- $8000: a(15:10)=100000 (32), no offset = $20
		cpuRead(x"8000");
		wait until phi2 = '1';
		assert ma(17 downto 10) = x"20"
			report "RAM: $8000 -> ma should be $20 (no offset)"
			severity error;
		wait until phi2 = '0';

		-----------------------------------------------
		-- Test 5: Non-windowed bottom 4K (always no offset)
		-----------------------------------------------
		report "Test 5: Non-windowed bottom 4K";

		-- Should have no offset regardless of mode
		cpuWrite(MMU_MODE_APPL, x"00");
		cpuWrite(MMU_APPL1_OFFSET, x"FF");  -- Set high offset

		cpuRead(x"0000");
		wait until phi2 = '1';
		assert ma(17 downto 10) = x"00"
			report "Bottom 4K: $0000 should always map to ma=$00"
			severity error;
		wait until phi2 = '0';

		cpuRead(x"0800");
		wait until phi2 = '1';
		-- a(15:10) = 000010 (2), no offset = $02
		assert ma(17 downto 10) = x"02"
			report "Bottom 4K: $0800 should map to ma=$02"
			severity error;
		wait until phi2 = '0';

		-----------------------------------------------
		-- Test 6: ROM chip select (read-only)
		-----------------------------------------------
		report "Test 6: ROM chip select";

		cpuRead(x"E000");
		wait until phi2 = '1';
		assert cs_rom1b = '0' report "ROM CS should be active on read" severity error;
		wait until phi2 = '0';

		cpuWrite(x"E000", x"00");
		wait until phi2 = '1';
		assert cs_rom1b = '1' report "ROM CS should be inactive on write" severity error;
		wait until phi2 = '0';

		-----------------------------------------------
		-- Test 7: Mode switching persistence
		-----------------------------------------------
		report "Test 7: Mode switching persistence";

		cpuWrite(MMU_KERN_OFFSET, x"05");
		cpuWrite(MMU_APPL2_OFFSET, x"0A");

		-- Switch to KERN, verify offset
		cpuWrite(MMU_MODE_KERN, x"00");
		cpuRead(x"4000");
		wait until phi2 = '1';
		assert ma(17 downto 10) = x"15"
			report "After KERN switch: $4000 + $05 -> $15"
			severity error;
		wait until phi2 = '0';

		-- Switch to APPL, verify different offset
		cpuWrite(MMU_MODE_APPL, x"00");
		cpuRead(x"4000");
		wait until phi2 = '1';
		assert ma(17 downto 10) = x"1A"
			report "After APPL switch: $4000 + $0A -> $1A"
			severity error;
		wait until phi2 = '0';

		-----------------------------------------------
		-- Done
		-----------------------------------------------
		wait for 1 us;
		assert false report "All tests completed successfully" severity failure;

	end process;

end;
