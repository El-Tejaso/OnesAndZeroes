# OnesAndZeroes Logic Gate Simulator

A logic gate simulator made in processing to help myself understand a second year computer systems university course. Download Processing from their website, then download this entire repository and open OnesAndZeroes.pde in processing and run it in order to use the program

### Controls:

- Rightclick and drag to move the view around, use the mousewheel to zoom in and out.
- Drag a gate to move it. 
- Drag a rectangle to do a rectangle selection (hold shift while doing this to make it additive). 
- Hold right-click on a gate/selection to delete it
- Press `[Shift] G` to group a selection into a group. Groups can be collapsed for easier viewing. They can't be ungrouped at the moment
- Press `[Shift] D` to duplicate a selection (totally didnt steal that from blender or anything haha)
- Press `[Shift] C` to connect the selected inputs and outputs *in the order that they were selected*. Very useful

There are probably more controls out there, the bottom left of the screen will show you what actions you can do at any given moment

## How it works
I'd assume that your goal is to build some sort of computer using these logic gates.

You initially have a list of primitive gates, being And, Or, Not, Nand, and Ticker. The And, Or, and Not gates can actually be made with the Nand gates, but I added them in as well for convenience. The Ticker is a gate that will pulse on and off according to a tick length defined by it's input, which is a 16 bit number. It's the only way to get sequential logic, which is a low level computer thing that most people overlook when writing hardware descriptions. Defining the tick length is crucial - too short, and your circuit is unstable; too long, and your circuit isn't as fast as it could be. I'll add something about how to do this once I've figured it out myself

### Loading, saving, and groups

In order to do things faster, you can save a layout with a name of your choice (can only be letters and numbers though). It is important that you don't put the layout into a group, so that you can still edit it later (although I might implement an ungroup function at some point). You can load the group by pressing Shift+L with it's name entered in, or, you can load it from the `ADD SAVED` menu. Doing this will put the entire layout into it's own group, and even give the group the name of the file it was saved as. You can use this mechanism to build more and more complex parts from the older parts. None of the parts have dependancies on other parts, so you can delete anything you don't need by yourself in the file browser. This also means that updating a dependancy part won't update the part in other saved files, though I might implement this later.

You can also choose to manualy group objects, but this means that the only way to load another instance of that group is by selecting it and deleting it. I dont recommend, although it might be handy every now and then. It's certainly handly when I myself am testing the grouping functionality, but it's really of no use otherwise (well not that I know of anyway).

### Naming inputs and outputs

Possible the most usefull feature ever. Click on the input/output name, type in something new, and then hit enter. Extremely handy, since creating a group isn't going to make the pins appear in any particular order and it's very easy to lose track of which pin does what otherwise. (changing the order can be a future feature idea, but it won't be on my agenda anytime soon).

### So you actually read the instructions eh?
Thanks! There are still heaps of bugs to remove, but hopefully you won't encounter any of them while you're building your computer. (Don't worry too much about feedback loops though, the system is quite resilient to those). Good luck!
