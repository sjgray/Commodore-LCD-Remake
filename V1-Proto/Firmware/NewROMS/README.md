# ROMs

This directory contains the ROM code and a script that will generate ready-to-burn images for EPROM sizes 27C010 to 27C080.  Any of these EPROMs can be inserted directly into the EPROM socket on the SteveLCD when the CPLD is used as the address decoder.  When the EPROM-as-PLA board is used, a hardware change on that board is required (see below).

## Building EPROM Images

Run `make` to generate images using the memory map described below.  Each image is a complete system that contains all the original CLCD applications and the KERNAL modified to run on SteveLCD.

```shell
$ make

$ ls *.bin
27c010.bin	27c020.bin	27c040.bin	27c080.bin
```

The 27C020 is the best choice, as described below.

## EPROM Memory Map

Address spaces:

- 6502 address space: 64K: 16 lines: A0-A15
- CLCD physical address space: 256K: 18 lines: A0-A17

32-pin EPROM sizes:
- 27C010 = 128K = A0-A16  
- 27C020 = 256K = A0-A17 ← The 27C020 matches the CLCD so it the best choice.
- 27C040 = 512K = A0-A18  
- 27C080 = 1024K = A0-A19

The SteveLCD board accepts a 32-pin EPROM up to a 27C080.  We store the CLCD firmware in a 27C020.  The 27C020 was chosen because it exactly matches the physical address space of the CLCD, as shown above.  A 27C040 or 27C080 can also used but the extra space will be wasted.  This is not limiting since there is already a huge 128K area free in the 27C020.

The 27C020 needs this memory map to match the CLCD:

- `0x00000-0x1ffff` (128K empty: fill with 0xFF)
- `0x20000-0x27fff` (32K: `ss-calc13apr-u105.bin`)
- `0x28000-0x2ffff` (32K: `sept-M-13apr-u104.bin`)
- `0x30000-0x37fff` (32K: `sizapr-u103.bin`)
- `0x38000-0x3ffff` (32K: `kizapr-u102.bin`)

## EPROM-as-PLA Board Fix

In order to use a 27C020 with the correct CLCD memory map shown above, the EPROM-as-PLA board needed to be reworked.  The EPROM-as-PLA board originally had these hardwired connections:

 - GND → MA16  (A16)
 - GND → MA17  (A17)
 - GND → MA18  (/PGM on 27C020, A18 on 27C040 and 27C080)
 - GND → MA19  (Vpp on 27C020 and 27C040, A19 on 27C080)

The connections were changed to:

 - Vcc → MA16  (A16)
 - Vcc → MA17  (A17)
 - Vcc → MA18  (/PGM on 27C020, A18 on 27C040 and 27C080)
 - Vcc → MA19  (Vpp on 27C020 and 27C040, A19 on 27C080)

The above changes allow any EPROM from 27C010 to 27C080 to be used for the CLCD firmware:

| Pin   | 27C010 | 27C020 | 27C040 | 27C080 |
|-------|--------|--------|--------|--------|
|Pin 2  | A16    | A16    | A16    | A16    |
|Pin 30 | NC     | A17    | A17    | A17    |
|Pin 31 | /PGM   | /PGM   | A18    | A18    |
|Pin 1  | Vpp    | Vpp    | Vpp    | A19    |

27C010:
 - 0x00000-0x1FFFF: CLCD 0x20000-0x3FFFF

27C020:
 - 0x00000-0x3FFFF: CLCD 0x00000-0x3FFFF ← The 27C020 matches the CLCD so it the best choice.

27C040:
 - 0x00000-0x3FFFF: Wasted
 - 0x40000-0x7FFFF: CLCD 0x00000-0x3FFFF

27C080:
 - 0x00000-0xBFFFF: Wasted
 - 0xC0000-0xFFFFF: CLCD 0x00000-0x3FFFF

The 27C010 (128K) can be used since the ROMs from Bil's prototype are only 128K.  However, the lower 128K of the CLCD's 256K address space is lost, so there's no room for expansion.

The 27C020 (256K) is the best choice because its address space exactly matches the CLCD address space.  The upper 128K holds the ROMs dump from Bil Herd's prototype.  The lower 128K is available for new code.

For the 27C040 (512K) and 27C080 (1024K), the CLCD address space is the highest 256K in the EPROM address space.  The rest of the EPROM is inaccessible.

The changes are made at the expansion header on the EPROM-as-PLA board.  MA16 and MA17 are connected to MA18 and MA19 on the bottom side of the board, which in turn connects to GND.  The connection to GND is cut and connected to Vcc instead.

## EPROM Emulator Adapter

The firmware is a 27C020 (256K).  However, my EPROM emulator only emulates up to a 27C256 (32K).  In order to have the built-in applications while being able to program custom KERNALs with my emulator, I built an adapter.  The adapter plugs into the original socket in place of the 27C020.  It has two sockets: one for a 27C020 and one for a 27C256.  The 32K KERNAL area (0x38000-0x3FFFF) goes to the 27C256 so the emulator can be used.  The rest (0x0000-0x37FFFF) goes to the 27C020.

The address lines of the 27C020 are:

 - 27C020 = 256K = A0-17

The EPROM emulator emulates a 27C256.  The address lines of the 27C256 are:

 - 27C256 = 32K = A0-14

The three highest address lines (A15-A17) go to a 74LS138.  It decodes the 256K space of the 27C020 into eight 32K selects.  We use those to select either the 27C020 or the 27C256 on the adapter:

| /CE_ORIGINAL | /LS138_KERNAL_SEL | /CE_27C020 | /CE_27C256 |
|--------------|-------------------|------------|------------|
|    0         |       0           |         1  |      0     |
|    0         |       1           |         0  |      1     |
|    1         |       0           |         1  |      1     |
|    1         |       1           |         1  |      1     |

Requirements:
 - `/CE_27C256` is low only when `/CE_ORIGINAL` is low and `/LS138_KERNAL_SEL` is low.
 - `/CE_27C020` is low only when `/CE_ORIGINAL` is low and `/LS138_KERNAL_SEL` is high.

Equations:
 - `/CE_27C256 = /CE_ORIGINAL OR `/LS138_KERNAL_SEL`
 - `/CE_27C020 = /CE_ORIGINAL OR (NOT /LS138_KERNAL_SEL)`

Since only one output of the 74LS138 can be low at any time, we don't need to invert `/LS138_KERNAL_SEL`.  We can just take any other 74LS138 output to simplify the design.

Final Equations:
  - `/CE_27C256 = /CE_ORIGINAL OR /LS138_KERNAL_SEL`
  - `/CE_27C020 = /CE_ORIGINAL OR /LS138_WRONG_SEL`

The "OR" gates are not needed, since the 74LS138 has active low chip selects.  The `/CE_ORIGINAL` signal is fed to /E1 and /E2 on the 74LS138.  Therefore, a single 74LS138 is all that is required.

74LS138 Connections:

 - Pin 16 Vcc
 - Pin 15 /O0 (no connect)
 - Pin 14 /O1 (no connect)
 - Pin 13 /O2 (no connect)
 - Pin 12 /O3 (no connect)
 - Pin 11 /O4 (no connect)
 - Pin 10 /O5 (no connect)
 - Pin 9 /O6 "/LS138_WRONG_SEL" -> /CE_27C020
 - Pin 8 GND
 - Pin 7 /O7 "/LS138_KERNAL_SEL" -> /CE_27C256
 - Pin 6 E3 to Vcc
 - Pin 5 /E2 to /CE_ORIGINAL
 - Pin 4 /E1 to /CE_ORIGINAL
 - Pin 3 A2 to A17
 - Pin 2 A1 to A16
 - Pin 1 A0 to A15
