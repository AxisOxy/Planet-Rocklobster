Rapid prototyping framework by Michael "Axis" Hillebrandt.

This is not a showcase of how to write nice C++ code. Actually its the opposite.
Most of the framework code is about 15 years old.
So its neither clean code nor its good OOP-design. Its not even nicely documented.
But if you get used to it, you will love it!

This framework offers you easy adding and invocation of new effects,
access to the framebuffer/timers/input devices, simple drawing functions, loading of images/true-type fonts, 
slim classes for 3d-math, endianess swapping and writing out everything as binary.
This should cover at minimum 90% of everything you want for retro-platform-prototyping.

To add a new effect derive a class from "Effect", overwrite the virtual functions Init, Exit and Update.
A template for this is the class Empty.
And add a line "effect = your_classname" to the startup.ini. Voila!

In the running prototype you can switch effects with "Escape".

Have fun,
Axis
