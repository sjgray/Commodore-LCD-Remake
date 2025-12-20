#!/usr/bin/env python3

import os

here = os.path.abspath(os.path.dirname(__file__))

def rom(filename):
    if not os.path.isabs(filename):
        filename = os.path.join(here, filename)
    with open(filename, "rb") as f:
        return f.read()

# Make firmware image that matches the CLCD 256K address space ==============

image = bytearray([0xff] * (128*1024))         # 0x00000-0x1ffff (128K empty)
image.extend(rom("cbm/ss-calc13apr-u105.bin")) # 0x20000-0x27fff (32K)
image.extend(rom("cbm/sept-m-13apr-u104.bin")) # 0x28000-0x2ffff (32K)
image.extend(rom("cbm/sizapr-u103.bin"))       # 0x30000-0x37fff (32K)
image.extend(rom("kernal.bin"))                # 0x38000-0x3ffff (32K)
assert len(image) == 256*1024

# Write binaries for various EPROMs =========================================

# 128K image for 27C010
# 0x00000-0x1FFFF: CLCD 0x20000-0x3FFFF
with open("27c010.bin", "wb") as f:
    f.write(image[0x20000:])

# 256K image for 27C020
# 0x00000-0x3FFFF: CLCD 0x00000-0x3FFFF
with open("27c020.bin", "wb") as f:
    f.write(image)

# 512K image for 27C040
# 0x00000-0x3FFFF: Wasted
# 0x40000-0x7FFFF: CLCD 0x00000-0x3FFFF
with open("27c040.bin", "wb") as f:
    f.write(b'\xff' * (256*1024))
    f.write(image)

# 1024K image for 27C080
# 0x00000-0xBFFFF: Wasted
# 0xC0000-0xFFFFF: CLCD 0x00000-0x3FFFF
with open("27c080.bin", "wb") as f:
    f.write(b'\xff' * (768*1024))
    f.write(image)
