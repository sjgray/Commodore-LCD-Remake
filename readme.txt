CLCD Re-Make Project  by Steve Gray		cbmsteve.ca
====================  and Mike Naberezny        mikenaberezny.com

The goal of this project is to remake/recreate the never released
Commodore LCD computer. Only a few working prototypes were ever
made. These were almost production ready and luckily a few survived
and information about them was released. Thanks go to Jeff Porter
and Bil Herd for helping with this project. Since the LCD computer
was never produced there are no spare parts and no way to replace
them. Several things are no longer available, such as the custom
chips, keyboard, case and LCD Panel, so we must recreate them or
adapt the design to use modern replacements and similar available parts.

Please see the webpage for more info: http://www.cbmsteve.ca/clcd/index.html

*** This is a work in progress!!! The project is currently incomplete.
    Files are provided for information only. Do not attempt to build
    it unless you are willing to debug and fix things. I will not be
    able to support you. As this is a personal project I can not say
    if or when this might be fully functional!

*** GERBER files have not been provided. They may be made available when
    the project is in a more stable/working state.


DESIGN
======

Schematics
----------

Bil Herd had saved all 4 original pages of the CLCD schematics however
one was misplaced. The 3 pages were sent to Mike, scanned in high-res,
and returned to Bil. Later Bil eventually found the missing page and took
several photos. I (Steve) stitched them together into one photo and used
it as a guide for recreating the missing page.


Design Changes
--------------

Since the custom chips and other parts of the computer were not available
I decided to use a CPLD for the MMU/glue and the C128's VDC chip for the
video. A 32K Dual-port RAM was used for the main memory. Both the CPU and
VDC can access this memory independently/simultaneously and the CPU can
write to it directly without the need to go through the VDC registers. This
means writing to the (text) screen works like the original machine. Only
a small patch is needed for the KERNAL.

Western Design Center still makes 6502-series chips and these were used in
the new design. The original 65C102 CPU was replaced with a 65C02 which is
fully compatible. Similarly equivalent WDC IO chips were also available but
in a smaller PLCC package.

Everything is powered by a simple 12V supply.


LCD Panel/Video
---------------

The original 80x16 (480x128 pixel) monochrome LCD panel was replaced by a
modern widescreen colour panel of roughly the same size. It includes a
controller board with HDMI and composite video inputs. We will use the HDMI
input for best quality. The VDC's RGBI output will be converted to HDMI
using an RGB2HDMI converter. There is an RGBI output connector for an
external display.


Keyboard
--------

Two keyboards were designed with MX switches. One design is like the
original keyboard and uses the diamond arrow cursor. The other design uses
an inverted-T cursor. This design was chosen so that normal keycaps
could be used. Included are files to create custom printed keycaps from
maxkeyboard.com. Custom 3D printed keycaps that match the original, including
the diamond cursor, are in progress for the next revision.


EPROM-PLA
---------

The V1 board initially required the EPROM-PLA board, which plugged into the
expansion connector. This board used an EPROM to emulate a PLA that did
decoding for basic functionality. It is no longer required as it has been
replaced by Mike's CPLD implementation.


Case
----

I have designed a case that can be 3D printed. I used Light-beige PLA.
It must be assembled from multiple pieces and requires brass screw inserts
to hold it together. The initial case is an approximation and has been
designed to accommodate the new LCD panel and it's controller and the
RGB2HDMI adapter. All ports are on the back.


Missing Features
----------------

The battery/power, modem, and barcode port features were not implemented in
the initial design but can hopefully be added later as the design progresses.


V1 PROTO
========

V1 is the first prototype that was developed and demonstrated to Jeff Porter
and Bil Herd.

The first prototype PCB was produced but it requires multiple fixes to
correct errors. These were done by Mike. Mike also did further disassembly of
the CLCD KERNAL to be able to re-assemble it back to an original binary and
then patch it to get the VDC working. He also added serial IO for debug purposes.
Mike wrote the CPLD code that functions like a programmed logic array (PLA) to
map in the 32K RAM, KERNAL ROM and IO. The machine is able to boot.

The MMU has not been implemented yet, so the machine can only boot to the
machine-language monitor at this time. The first prototype PCB was a
proof-of-concept and the ports and placement were not designed to match
the original PCB.

I designed a 3D printed case based on existing prototype photos and some original
documentation, but without any complete measurements. It is split into multiple
pieces for easier printing. It is able to open like the original and uses the
inverted-T keyboard version, colour LCD panel with controller and RGB2HDMI adapter.
All ports are along the back of the computer, and the battery compartment allows
access to the RGB2HDMI adapter's buttons.

When Mike visited Jeff he was able to take detailed photographs and measurements
which will be used for the next version. 


V2 PROTO
========

A V2 design is in the works to correct the errors in the V1 Proto PCB.
Additional work is required for the CPLD to add the MMU functionality that
will allow the machine to run the application ROMS, including the normal
menu system.

As of the initial GitHub commit some fixes have been made but there is more
to do. Routing and parts placement is not complete.

A better keyboard will be designed that will support the low-profile MX
switches and use the replica 3D-designed keycaps.


Future Goals
------------

These are just ideas for future goals.

- Better PCB layout to more match the original pcb
- Better keyboard - Low Profile switches and replica keycaps
- Better case
- MMU support for ROM banking and menu system
- Smaller RGBI to HDMI adapter (current is very tight fit)
- Support for graphics mode.
- Modem support? Perhaps a WIFI solution?
- Internal IEC drive?
- Battery power
- Recreation of custom chips.. not easy
- Disassembly of other built-in apps
- Add support for colour or more screen sizes (40x25, 80x25 etc)
- Replica disk drive (1581 case) and printer (Epson P-80)


Additional Info
---------------

My Facebook group............: https://www.facebook.com/groups/806261867281489
Mike's firmware disassembly..: https://github.com/mnaberez/clcd
Mike's firmware and info page: https://mikenaberezny.com/2008/10/04/commodore-lcd-firmware/
Jeff Porter's LCD prototype..: https://flickr.com/photos/mnaberez/albums/72177720308500331/
Jeff Porter's LCD printer....: https://flickr.com/photos/mnaberez/albums/72177720308512645/
Commodore LCD Emulator Online: http://commodore-lcd.lgb.hu/emulator.html
MAME (Has CLCD emulation)....: https://www.mamedev.org/