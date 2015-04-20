What is this?
-------------

This is neither a demomaker nor a tutorial how to learn making Amiga demos in 21 days.
This is just a showcase of how we "Oxyron" make Amiga demos.
So this is more useful for the advanced user/coder as for beginners.
I am not starting to awnser questions like: "What is Amiga, what is a demo, what is UAE, what is assembler, ...?".
Google and Wikipedia can pretty much help you on these things.
You can try using our full framework and follow our workflow, but i´m not sure if this is going to work.
Even though i tried to add some documentation and examples.
But I am sure some of you will find interesting partial solutions for problems they struggle for a long time.
E.g. Doynax ultrafast packer or the automation of MOD to P61 conversion.
Also this is completely based on Microsoft Windows (Batches, Visual studio, ...). Sorry to the Linux and MacOS users.
But since all sources for the tools are included or atleast available on the interweb, it should not be too hard
to port the whole project to other operating system.


Third party libs:
-----------------

This software uses:

DevIl - http://openil.sourceforge.net
Freetype - http://www.freetype.org
Microsoft DirectX - www.microsoft.com
WinUAE - http://www.winuae.net
VASM - http://sun.hasenbraten.de/vasm
The player p61a - http://aminet.net/package/mus/misc/P6112
Doynamite68k

Serveral code snippets taken from:

WinUAE Demo ToolChain - http://www.pouet.net/prod.php?which=58703
Photon/Scoopex  - http://coppershade.org/asmskool/SOURCES/Photon-old-snippets


Known issues and advices:
-------------------------

- There is one thing I cant put into this package for legal reasons. The kickstart 1.3 ROM. So, go search the interweb to find one and copy it to demo\winuae\roms.
- The emulator always starts in warp mode to speedup the startup process. The hotkey to switch back is 'end' + 'pause'.
- Always assemble without optimizations!
- Sometimes VASM merges sections which can cause out of memory conditions. Reorder or merge sections if this happens!
- Always secure that your first section is the section starting with the entrypoint.
- Alternative parts (Transitions in alternative memory) must start with a jump-table for entry- and shutdown-point.
- Avoid cyclic references between sections. The framework only supports 1 relocation hunk per executable.
- Avoid relocations with offsets >128KB. Use smaller sections or place referenced variables at the beginning of a section.
- P61con has no real command line interface. Its only using the command line to detect that no user interface is needed. So always use tune.mod and tune.p61 as filenames.


Nice to have features for future releases or exercise for you:
--------------------------------------------------------------

- Implement both 16 bit and 32 bit relocation hunks.
- Compress relocation hunks.
- Store framework compressed to disk. This needs a 2 stage bootblock since there is not enough space for a depacker in the 1KB bootblock.
- Decrompress parts inplace to free up some extra fastmem for the parts.
- Automate generation of library vector offsets for framework.
- Add calling-macros to simplify framework calls.
- Add api to transfer data from part to part.
- Extend loader api. E.g. add configuration for motor on/off during parts, improve turn disk logic, multi-drive support, ...


How to start:
-------------

A good starting point to look at is demo/example/example.asm.
This is an example of how to implement a simple part showing a picture and moving a sprite.
Its the only well documented part in the demo.
The assemble.bat in the same folder will build and run a standalone executable of the part.
Other interesting spots are demo/launcher/script.asm and demo/build/build.bat.
They show how the linking of the demo is done.
You see there is not much extra work to make your standalone executable part run in the trackmo.
No fiddeling with memory and sections involved. 
Just add assembly, compression and copy to disk of the part to the build.bat and call it from the script.asm. voila!
Also demo/framework/framework.i is an interesting thing to look at.
There you will find what the framework offers you to make your life a bit easier.


The 'Planet Rocklobster' code:
------------------------------

The framework:

The framework is mostly the part of the code that makes my life and hopefully also your life a little bit easier.
The basic blocks of the framework are trackloader, depacker, soundplayer, memory handler, executable launcher, startup code and lots of small helper functions.

The trackloader is based on Photon/Scoopex old MFM-loader and is used to load tracks/sectors from an Amiga floppy disk.

The packer/depacker is a 68K optimized version of the famous "Doynamite" packer on C64 done by Johan "Doynax" Forslöf.
It is used to depack LZ-compressed data after loading it from disk. The depacking is unbelievable fast (about 180KB/s on a stock Amiga 500).

The soundplayer is "The player P61" by Guru/Sahara Surfers and Photon/Scoopex. The fastest player and most compact MOD-compatible fileformat available on Amiga.
I dont think there is need to explain this further.

The memory handler is a stack based allocator. Basically its administrating a stack of stacks.
Advantage of the stack based approach is, there is no fragmentation of memory through the whole demo.
Every memory stack can grow in both directions. You can allocate blocks from the top or bottom of the stack. And it can always be switched between these 2 modes.
This allows the user to have 2 succeeding parts in the memory at once, which is pretty nice for transitions between parts.
Additionally the whole system uses a stack of these memory states.
You can always push and pop a memory state, just like the OpenGL matrix-stack.
So you can secure things to reside in the memory over a longer period, e.g. your music or a part/gfx that is reused later in the demo.

The executable launcher executes Amiga executables just as the operating system would do.
It parses the hunks of the executable, allocates the requested type of memory from the active memory state and depacks every single section in place.
Also references between sections get automatically relocated.
If you take care of a few simple rules (see "Known issues and advices") every valid Amiga Executable should be compatible to this launcher.
So you dont need to fiddle around with allocating memory, copy your code and data in place and relocate stuff by hand.

The startup code is mostly there to hide the ugly details of Amiga system programming from you.
This means things like shutting down the system on startup and restore it correctly at the end, handle caches, different chipsets and CPU´s, etc...
It also hides the difference of stand-alone parts and trackmo builds from you.

Additionally there are a lot of small helpers in the framework.
Like waiting for the blitter, waiting for VSync, switching of copperlists and IRQ´s, a global framecounter.
There is also an empty coppperlist and IRQ inside the framework, which is nice to have for a first fast rough linking.

I guess, thats it folks.


The parts:

Here follows a description of the algorithms and trickery in the demoparts of Planet Rocklobster.
I hope my explanations are halfway correct, since most of the parts were coded 2 years ago.

Starfield intro:

The transformation of the stars is completely realtime. Translated on one axis and rotated in X, Y & Z.
Every frame a transformation matrix and a lerptable per matrix-entry is calculated.
For the perspective projection a log-/exp-table divide is performed to be both accurate and fast.
The version in the demo shows 470 plots with z-shading and without any noticeable jitter.
Without sprite overlay there would be about 520 Plots.
The most tricky part is the sprite overlay. It can display up to 8 sprites in 16 colors in every row without re-using sprite data.
This is done with a sprite-multiplexer that fills the sprite data with the copper instead of the DMA.


Planet:

Just a simple filled vector used as transition.
The drawing of the planet outline is done using the CPU to allow subpixel accuracy.
Then a top-down blitter eor-fill-pass is executed.
The most tricky part is the color-fade that uses ordered dithering to overcome the problem that slow OCS-fades always look jerky.


Voxel:

The part you all love so much.
Basically its just what it looks like. A voxel in HAM6.
The screenmode is pretty much what everyone was doing back in the 90´s on AGA-machines. Only with 4 instead of 6 colorbits per channel.
The algorithm is based on a raytable with 64 non-linear depths.
It renders front to back setting visible border-pixels eor-encoded relative to the last set pixel.
So a top-down blitter eor-fill-pass generates the final image.
After that 2 passes of C2P merge are done also with the blitter to distribute the pixel data into the 4 color bitplanes.
The texture is stored in 128 colors and gets extended to 4096 colors due to fogging via a shadetable.
The most tricky part is, that displaying HAM6 usually nearly stops your CPU & blitter.
So I use 2 tricks to reduce the DMA-stress.
First the HAM6 runs in an illegal screenmode. Turning on 7 bitplanes on OCS results in displaying 6 bitplanes, which is fine for HAM6.
But only 4 of them are fetched by the DMA. The other 2 planes (The HAM logic planes) can be set as constants via the bitplane DMA registers.
This is also fine for this "hi-color" chunky-mode. Because the logic planes are completely static here (RGBB RGBB).
The other trick to reduce DMA-stress is to turn off the screen every second rasterline.
Both together give a speedup of about 40%.
Last thing to mention is the hiding of the HAM6 color-bleed with sprites.


Tunnel & satellite:

This part is transforming, sorting and clipping precalculated and drawing in realtime.
So basically what Spaceballs is doing for decades now.
The tool for precalculating the math is pretty tricky and fully automated.
Its generating a 2D BSP-tree for every single frame to hide the covered parts and create a 2d-convex output mesh.
The drawing is just the Amiga standard blitter linedrawing and filling.


Wireframe:

The same as tunnel & satellite, only without filling.


Morph:

The morph is based on increment-/decrement-lists for pixels based on their morphing delta.
Its using the fact that with a little bit of number theory you only need 7 increment-list-speedcodes to morph 128 frames.
A bit hard to explain. For every bit set in your delta, you add your plot to the increment list of that specific bit.
And these lists get called in a specific pattern and order, that the morphing looks linear and the amount of increments in the end fits.
This means the list for bit 0 is called once in frame 64, the list for bit 1 is called twice in frames 32 and 96, ...
The plotting is just a speedcode of bset.b, and the increment lists directly manipulate these opcodes (bits and adresses).


Vectorplots:

One of the technical hi-lights in the demo.
2816 z-shaded morphing vectorplots. Before adding sprite-overlays and design-stuff I had 3172.
A transformation matrix is generated every frame.
The morphing is just the result of using lots of prescaled sintables.
Half of the pixels are transformed with one add.l for X, Y & Z.
Then the blitter extracts the bits and adresses for the plots including z-shading.
The blitter also mirrors the bits, adresses and shading for the other half of the symmetric object.
The CPU sets the pixels with a bset.b per pixel.


Rotzoom:

From my point of view this is technically the best part in the demo.
It shows a rotzoom with 64x64 pixel sized texture in 16 colors in single pixel resolution on an area of 272x200 pixels in 25 fps.
I guess the algorithm is pretty close to what Mr.Pet/Sanity did in Roots 2.0.
Atleast it produces exactly the same artifacts.
The basic idea is to not rotate the texture, but double shear it.
With this technique and a bit of math to correct the fact that there occurs a scale of sqrt(2) on the diagonals you can rotate a texture 45° to left and right.
The rest is switching pre-rotated textures every 90° and swapping all the uv-values with em.
The shearing in Y and the scaling in X is done with the blitter, while the shearing in X and the scaling in Y is done with the copper. 
On C64 we would call this Dypp + FPP + Techtech.
But the rendering is still far too slow. 
The area to calculate is even bigger than with a correct rotzoom per pixel, because the width to calculate is 372 pixels not 272. 
Otherwise the techtech will show trash on the left and right.
With a closer look it gets obvious that when texel 64 is reached in x, everything wraps.
So after 64 texels the algorithm can switch from the costly shearing with the blitter to a fast block-copy.
The same applies for Y. After 64 texels, the copper can be used to wrap to the starting line.
So the area that really needs to be calculated is only 64x64*zoomfactor pixels. Voila!


Cracking glass:

This is a simple vector transition in overscan (368x285 pixels).
All calculations including tracking motions and setting up a transformation for every single piece up to clipping is done in realtime.
Calling this physics is a bit over the top.
Its just starting every piece with a random linear and angular momentum, add some gravity force and euler integrate it every frame.


Textured city:

This is another chunky part. Screen-mode is 160x100 pixels on a 2x2 dithered grid with 16 colors.
The reason for the black grid is pretty simple. It cuts down the memory throughput of the CPU & blitter for the C2P by a half.
The CPU OR´s 4 pixels of preprocessed textures, containing all bits needed for a pixel in 4 planes, into words.
After that 2 passes of C2P merge are done with the blitter to distribute the pixel data into the bitplanes.
The bits for 2 successive planes are always directly side by side.
So the videochip of the Amiga displays exactly the same data for bitplane 0 & 1. And it displays the same data for bitplane 2 & 3.
A mask on bitplane 4 and a techtech with the copper secure that the planes are shifted right to build the 16 colors and that the trashed bits dont get visible.
Also the illegal 7 plane-mode trick is used to reduce DMA-stress for the mask (see Voxel).
The city-effect itself is done using the blitter to copy lerptables (prescaled for every possible height) self modifying into the c2p speedcode.
Rendering is front to back with some kind of coverage buffer to avoid overdraw. The blitter is fast, but not soo fast... ;o)


Motion blur:

Guess what, another chunky part. Screen-mode is 160x60 on a 2x3 dithered grid with 16 colors.
C2P is basically the same as in the textured city.
The effect itself is a rotzoom combined with the good old Amiga rubber vector trick.
In words it doesnt throw away the calculated lerped uv´s for the last 60 frames, but reuses them every row a different uv-frame.
The algorithm for the motion blur is, adding the pixels of the actual frame and subtracting the pixels that got added 16 frames ago.
The drawing code again self modifies the C2P code. No time and space for framebuffers on Amiga.


Spacecut:

This effect is completely done in realtime (25 fps). The logo in the background has 8 colors and the vectors also have 8 colors.
First it transforms both vectors without projection.
Then 3d-plane equations from the visible planes of one of the 2 objects are created.
Based on these plane equations a BSP-tree is created.
This sounds harder than it is in practice. 
Due to the fact that there are maximum 3 splitplanes, there are also maximum 8 possible combinations how the tree can look.
So the tree-construction is just a few speedcodes.
The more complex part is the clipping and rendering.
The clipping directly creates both clipped polygons for the 2 sides of the tree in 1 pass to avoid duplicate calculations.
After clipping, the polygons get transformed using a log-/exp-table divide.
For the drawing an extremely flexible CPU-based flood-fill routine is used.
This allows us to display and mask out the logo in background.


Greets:

This is just the loading part for the fractal flight, so only 50KB of memory were available for this.
Basic idea is to convert a true-type font into a format that stores all border pixels in Y for every collumn of every character.
So we can subpixel correct scale these pixels in X and Y with the CPU into an area of 64 pixels height.
Then a top-down blitter eor-fill-pass is executed.
The scaling in Y is done with the copper.
The whole process is done twice per frame because there are 2 visible names at once with different scale.


Fracflight:

From my point of view this is another technical hi-light.
It zooms into a fractal on an area of 224x224 pixels in 16 colors in 50 fps.
The zoom consists of 14 images in 448x448 pixels size to avoid artifacts while zooming.
Without the background/border image and some diskspace-saving issues this would have been possible in 240x240 or even in 256x256 pixels.
The algorithm itself is a variation of the famous Elysium zoomer by Chaos/Sanity.
So its not really zooming, but inserting rows and collumns at the right places.
Try it yourself and you will see that finding the right places is the crucial part and not as easy as it sounds.
Especially in combination with the fractal-flight that brings you new constraints.
E.g. that the zooming must be pixel-perfect, so after 112 iterations you must have exactly zoom-factor 2, or everything falls apart.
The first implementation nearly used a full disk for the images, so saving diskspace was the big task in the development.
There are a lot of disk saving techniques used in this. 
E.g. not storing the pixels in the images, that will never reach the screen, because they are zoomed out before they are used by the zoom.
Or storing the columns that get inserted as rows, so they compress better. 
But this needs a C2P just to convert the buffers which slows down the zoom, because the blitter needs to free up some cycles for the CPU.
You see, this part was a bitch to code!


Starwars scroll:

Last but not least a copper trick.
This part uses a different copperlist for every possible width to display a rotating star wars scroll in 3 bitplanes with z-shading.
These copperlists update the scroll-registers of the Amiga every 8 pixels to skip texels.
With this technique it is possible to shrink down the width of a row by up to 16 pixels without any CPU or blitter interaction.
To choose from the different copperlists a JSR/RTS scheme for the copper was implemented using 2 copperlist-pointers to store the 2 involved adresses.
The rest of the shrinking (16 pixel steps) is done with generating the upscroll in 9 different widths with the blitter in the background.
I think up to now there is nothing new. This has all been seen in old Sanity demos.
So, what is new? I think the Z-shading is. And also the perspective correct mapping is.
This was also a bitch to do, because UAE doesnt show all the nice bugs the Amiga copper has.
So I had to code it completely from scratch after watching it the first time on a real A500.


Thats it, I hope you had fun reading this.



Contact:
--------

For questions, ideas of improvement, bug-reports and bug-fixes contact me Michael 'Axis' Hillebrandt at:
axtmann@gmx.de


Have fun with this and make a demo about it...
Axis/Oxyron
