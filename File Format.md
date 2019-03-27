# File Format
The saved file will look something like this:`partName.txt`.

The real data is on line 2 of the file. It is a `list of gates` and connections between the gates that are `{encapsulated in curly braces}`.
The user has the option of loading it as an actual list of gates, or as a single group. It has the following form:

```
{numParts, Part1, Part2, ... , PartN | <0>LinkedOutput0,<1>LinkedOutput1,..., <n>LinkedOutputN}

```

where: 
- `numParts` is a positive integer describing the number of parts
- `Part1,...,PartN` are `Part`s
- `<0>,...,<n>` are indices corresponding to a part in the list of parts
- `LinkedOutput0,...,LinkedOutputN` are a list of index pairs `[OutputGate,OutputIndex]` corresponding to a gate in the list and an output pin on that gate.
The number of pairs is equal to the number of inputs

#### Wait, but what is a `Part` ?

A `Part` is `(encapsulated in parentheses)` and has the following form:
```
(Gate, xPosition, yPosition, width(optional), height(optional), |I|input1Name,...,inputNName,|O|output1Name,output1Value, ..., outputNName,outputNValue)
```
where:
- `xPosition`, `yPosition`, `width`, and `height` are decimal values for the local x,y, width and height of the gate. (width and height aren't yet needed, but they might be for things
like pixels in the near future).
- `input1Name,...,inputNName` and `output1Name,...,outputNName` are strings corresponding to input and output pin names
- `output1Value,...,outputNValue` are either 1 or 0 depending on the value of the corresponding pin

#### Wait, but what is a `Gate` ??

A `Gate` is either a positive integer that corresponds to a primitive hardcoded gate, a string preceded by 'N' that corresponds to a custom saved gate
(e.g. if my gate was called "someGate.txt", the string would be "NsomeGate". The N simply denotes a saved group for the file parser), or a `list of gates` (recursive definition)
that will be loaded as a group (and hence considered a single part)
