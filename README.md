This is a Unity project which can procedurally generate a random water surface.

It uses a sum of sines approach, using an arbitrary number of randomly generated sine waves as a heightmap on a plane mesh.
Correct normals for the water surface are calculated to allow for lighting.

water surface is transparent and colour becomes darker with greater depth. Objects placed under water surface will become more obscured
by water "fog" with greater depth.

Note that frequency is inversely proportional to amplitude, so a surface made of many waves should have a high frequency to appear correct

![alt text](https://github.com/Grez00/Procedural-Water/blob/e1189363d241d0dfef75a843be1f68d60964ba17/Assets/Screenshots/Screenshot%202025-11-09%20184505.png "water surface")
