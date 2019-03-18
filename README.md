# OnesAndZeroes Logic Gate Simulator

A logic gate simulator made in processing to help myself understand a second year computer systems university course. Download Processing from their website, then download this entire repository and open OnesAndZeroes.pde in processing and run it in order to use the program

### Controls:

- Rightclick and drag to move the view around, use the mousewheel to zoom in and out.
- Drag a gate to move it. 
- Drag a rectangle to do a rectangle selection (hold shift while doing this to make it additive). 
- Hold right-click on a gate/selection to delete it
- Press `[Shift] G` to group a selection into a group. Groups can be collapsed for easier viewing. They can't be ungrouped at the moment
- Press `[Shift] D` to duplicate a selection (totally didnt steal that from blender or anything haha)
- Press `[Shift] C` to connect the selected inputs and outputs *in the order that they were selected*. Very usefull

There are probably more controls out there, the bottom left of the screen will show you what actions you can do at any given moment

## How it works
I'd assume that your goal is to build some sort of computer using these logic gates.

You initially have a list of around 10 or so primitive gates, the main ones being And, Or, Not, Nand and  the Relay/IO gate (Technically we only need Nand and the Relay IO gate but I added the others as well for convenience's sake). There is also a Ticker, which can be used to send a signal every 0 to 2147483647 virtual cpu ticks. Timing is crucial, and that is one of the relay/IO gate's many uses. You can add gates, drag them around, and connect their outputs to inputs on other gates using a mouse drag. More parts are being added as I learn more about the workings of computers.

### Loading, saving, and groups

In order to do things faster, you can save a layout with a name of your choice (can only be letters and numbers though). It is important that you don't put the layout into a group, so that you can still edit it later (although I might implement an ungroup function at some point). You can load the group by pressing Shift+L with it's name entered in, or, you can load it from the `ADD SAVED` menu. Doing this will put the entire layout into it's own group, and even give the group the name of the file it was saved as. You can use this mechanism to build more and more complex parts from the older parts. None of the parts have dependancies on other parts, so you can delete anything you don't need by yourself in the file browser. This also means that updating a dependancy part won't update the part in other saved files, though I might implement this later.

You can also choose to manualy group objects, but this means that the only way to load another instance of that group is by selecting it and deleting it. I dont recommend, although it might be handy every now and then. It's certainly handly when I myself am testing the grouping functionality.

# Good luck!
