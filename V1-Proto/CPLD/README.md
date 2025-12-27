# Commodore LCD CPLD Decoder

CLCD Re-Make Project by Steve Gray and Mike Naberezny (CBMSTEVE.CA)

MMU implementation by Frank Buss

This folder contains the CPLD code that implements the address decoder and MMU for the Commodore LCD remake.

## MMU Specification Summary

Based on the original 1984 specification documents.

## Overview

The MMU provides address translation for the 65C102 CPU to access up to 256K of physical memory from a 64K logical address space. It supports four modes of operation: KERNEL, APPLICATION, RAM, and TEST.

## Physical Memory Map (18-bit, 256K)

| Address Range       | Size | Description                    |
|---------------------|------|--------------------------------|
| `$28000`-`$3FFFF`   | 96K  | Internal ROM (Kernal & Apps)   |
| `$24000`-`$27FFF`   | 16K  | Internal Expansion ROM         |
| `$20000`-`$23FFF`   | 16K  | Wafer Tape I/O Slot            |
| `$10000`-`$1FFFF`   | 64K  | External Expansion ROM/RAM     |
| `$08000`-`$0FFFF`   | 32K  | External Expansion RAM         |
| `$00000`-`$07FFF`   | 32K  | Internal RAM                   |

## Local (CPU) Memory Map

### Non-Windowed Regions (No Address Translation)

| Address Range     | Description                          |
|-------------------|--------------------------------------|
| `$F800`-`$FFFF`   | I/O and MMU Registers                |
| `$0000`-`$0FFF`   | System RAM (4K, always at `$00000`)  |

### Windowed Regions (Address Translation Applied)

| Window | Address Range     | KERNEL Mode        | APPL Mode           | RAM Mode            |
|--------|-------------------|--------------------|---------------------|---------------------|
| W1     | `$1000`-`$3FFF`   | `$01000`-`$03FFF`  | addr + APPL1 offset | `$01000`-`$03FFF`   |
| W2     | `$4000`-`$7FFF`   | addr + KERN off    | addr + APPL2 offset | `$04000`-`$07FFF`   |
| W3     | `$8000`-`$BFFF`   | `$38000`-`$3BFFF`  | addr + APPL3 offset | `$08000`-`$0BFFF`   |
| W4     | `$C000`-`$F7FF`   | `$3C000`-`$3F7FF`  | addr + APPL4 offset | `$0C000`-`$0F7FF`   |

## I/O Register Map (`$F800`-`$F9FF`)

| Address Range     | Device          |
|-------------------|-----------------|
| `$F800`-`$F80F`   | VIA #1          |
| `$F880`-`$F88F`   | VIA #2          |
| `$F900`-`$F901`   | VDC (LCD)       |
| `$F980`-`$F983`   | ACIA            |

## MMU Control Registers (Write Only)

All registers are 128 bytes apart (`$80`).

### Offset Registers (8-bit value written)

| Address Range     | Register              |
|-------------------|-----------------------|
| `$FF00`-`$FF7F`   | KERN Window Offset    |
| `$FE80`-`$FEFF`   | APPL Window #4 Offset |
| `$FE00`-`$FE7F`   | APPL Window #3 Offset |
| `$FD80`-`$FDFF`   | APPL Window #2 Offset |
| `$FD00`-`$FD7F`   | APPL Window #1 Offset |

### Mode Control (Address-triggered, data ignored)

| Address Range     | Function             | Implemented |
|-------------------|----------------------|-------------|
| `$FA00`-`$FA7F`   | Set KERNEL Mode      | Yes |
| `$FA80`-`$FAFF`   | Set APPLICATION Mode | Yes |
| `$FB00`-`$FB7F`   | Set RAM Mode         | Yes |
| `$FB80`-`$FBFF`   | Recall Last Mode     | Yes |
| `$FC00`-`$FC7F`   | Save Current Mode    | Yes |
| `$FC80`-`$FCFF`   | Set TEST Mode        | No  |

#### SAVE/RECALL Mechanism

The MMU maintains two mode registers:
- **Current mode**: The active operating mode
- **Saved mode**: A backup register for mode switching

**SAVE** (`$FC00`): Copies current mode to saved mode register.
**RECALL** (`$FB80`): Restores saved mode to current mode register.

Typical use case (kernel accessing application memory):
1. Kernel running in KERNEL mode
2. Write to `$FC00` → saves KERNEL mode
3. Write to `$FA80` → switch to APPLICATION mode
4. Access application memory with app's window offsets
5. Write to `$FB80` → RECALL restores KERNEL mode

## Address Translation Algorithm

The physical address is computed by adding an 8-bit offset to the upper 6 bits of the CPU address:

```
CPU Address:    --  --  A15 A14 A13 A12 A11 A10
              +
Offset:         D7  D6  D5  D4  D3  D2  D1  D0
              =
Physical:       S17 S16 S15 S14 S13 S12 S11 S10
```

- A9 through A0 pass through unchanged
- Physical address bits 17:10 = A(15:10) + Offset(7:0)
- This allows mapping any 1K block of CPU space to any 1K block of physical space

## Mode Behavior Summary

### KERNEL Mode
- `$0000`-`$0FFF`: Direct (system RAM)
- `$1000`-`$3FFF`: Direct (`$01000`-`$03FFF`)
- `$4000`-`$7FFF`: Uses KERN offset (windowed)
- `$8000`-`$F7FF`: Fixed to ROM (`$38000`-`$3F7FF`, offset `$C0`)

### APPLICATION Mode
- `$0000`-`$0FFF`: Direct (system RAM)
- `$1000`-`$3FFF`: Uses APPL1 offset (Window 1)
- `$4000`-`$7FFF`: Uses APPL2 offset (Window 2)
- `$8000`-`$BFFF`: Uses APPL3 offset (Window 3)
- `$C000`-`$F7FF`: Uses APPL4 offset (Window 4)

### RAM Mode
- All addresses map directly to physical RAM
- `$0000`-`$0FFF` -> `$00000`-`$00FFF`
- `$1000`-`$3FFF` -> `$01000`-`$03FFF`
- `$4000`-`$7FFF` -> `$04000`-`$07FFF`
- `$8000`-`$BFFF` -> `$08000`-`$0BFFF`
- `$C000`-`$F7FF` -> `$0C000`-`$0F7FF`

## Chip Select Notes

- ROM chip select is only active during reads (rwb='1')
- RAM chip selects are active during phi2='1'
- I/O chip selects are active regardless of phi2
- Internal RAM located in bottom 32K of physical space
