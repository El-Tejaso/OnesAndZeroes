# OnesAndZeroes Logic Gate Simulator

A logic gate simulator made in processing to help myself understand a second year computer systems university course. Download Processing from their website, then download this entire repository and open OnesAndZeroes.pde in processing and run it in order to use the program

### Controls:

- Rightclick and drag to move the view around, use the mousewheel to zoom in and out.
- Drag a gate to move it. 
- Drag a rectangle to do a rectangle selection (hold shift while doing this to make it additive). 
- Hold right-click on a gate/selection to delete it
- Press `[Shift] D` to duplicate a selection (totally didnt steal that from blender or anything haha)
- Press `[Shift] C` to connect the selected inputs and outputs *in the order that they were selected*. Very useful

There are probably more controls out there, the bottom left of the screen will show you what actions you can do at any given moment

## How it works
I'd assume that your goal is to build some sort of computer using primitive logic gates only. The primitive gates are And, Or, Not, Xor, and Nand. There is also a clock gate that pulses at a speed defined by it's input, and relay gates that simply feed the signal forward.

The output gates exist to use the signals to produce some sort of output, like a coloured pixel, or a number. They also exist for debugging purposes.

### Selecting multiple gates
Dragging the mouse over the background will enable you to do a rectangular selection of gates. Selected gates can be dragged or deleted all at once. Holding down `Shift` while selecting things will ensure that the previous selection doesn't get cleared, allowing for additive selection. 

The selection can be duplicated with `Shift+D`, which is probably the best way to create more of the same element.

### Linking multiple I/O pins at once
As you make bigger and bigger circuits, linking pins by dragging will get quite frustrating. You can select several IO pins in the same way that you select gates, and then press `Shift+C` to link the selected inputs to the selected outputs. If there are fewer selected outputs than inputs, the outputs will be looped through again and linked to the remaining inputs. The linking occurs in the order the pins were selected, i.e the first selected output pin will link to the first selected input pin, and so on. 

### Loading, saving, and groups

In order to do things faster, you can save a layout with a name of your choice (can only be letters and numbers though). It is important that you don't put the layout into a group, so that you can still edit it later (although I might implement an ungroup function at some point). You can load a savefile as it's individual parts by using the Load button with it's name entered in, you can load it from the `ADD SAVED` menu, which will load it as a group, exposing all unused inputs and outputs, and give the group the name it was saved as.

You can also choose to manualy group objects, but this means that the only way to load another instance of that group is by selecting it and duplicating it. I dont recommend, although it might be handy every now and then. It's certainly handly when I myself am testing the grouping functionality, but it's really of no use otherwise (well not that I know of anyway).

### Naming inputs and outputs

Possibly the most usefull feature ever. Click on the input/output name, type in something new, and then hit enter. Extremely handy, since creating a group isn't going to make the pins appear in any particular order and it's very easy to lose track of which pin does what otherwise. (changing the order can be a future feature idea, but it won't be on my agenda anytime soon).

### So you actually read the instructions eh?
Thanks! There are still heaps of bugs to remove, but hopefully you won't encounter any of them while you're building your computer. (Don't worry too much about feedback loops though, the system is quite resilient to those). Good luck!

#### New features in the works:
- The option for a savefile to reference another savefile rather than embed all of the gates. Usefull for making a change to an implementation of a lower level part without having to rebuild everything else that used it
