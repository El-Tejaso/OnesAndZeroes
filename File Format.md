# File Format
The saved file will look something like this: `partName.txt`.

The real data is on line 2 of the file. It is a list of embedded parts, followed by the actual part/circuit that will be loaded. The embedded gates are saved in order of abstraction, so no gate can be loaded before it's dependancies. It has the following form:
```
NembeddedPart1{...}Nembeddedpart2{...}...NembeddedpartN{...}{}
```
where:
- `NembeddedPart0{...},...,NembeddedPartN{...}` are embedded parts which are referenced by the main part
- `{}` is the main part

A part has the following form:
```
{numSubParts, Part1, Part2, ... , PartN | <0>LinkedOutput0,<1>LinkedOutput1,..., <n>LinkedOutputN}
```

where: 

- `numSubParts` is a positive integer describing the number of sub-parts that make up the part
- `Part1,...,PartN` are the sub-parts.
- `<0>,...,<n>` are indices corresponding to a sub-part
- `LinkedOutput0,...,LinkedOutputN` are a list of incoming connections as index pairs `[OutputGate,OutputIndex]` corresponding to a sub-part, and an output pin on that sub-part. They can be blank, indicating no connections `[]`. The ith connection corresponds to the ith input on this part

Sub-parts have the following form:
```
(Gate, xPosition, yPosition, width(optional), height(optional), |I|input1Name,...,inputNName,|O|output1Name,output1Value, ..., outputNName,outputNValue)
```
where:
- `Gate` is a predefined gate, either as a primitive, an embedded gate, or a saved gate. Embeded gates will take precedence over saved gates.
- `xPosition`, `yPosition`, `width`, and `height` are decimal values for the local x,y, width and height of the gate. (width and height aren't yet needed, but they might be for things like pixels in the near future).
- `input1Name,...,inputNName` and `output1Name,...,outputNName` are strings corresponding to input and output pin names
- `output1Value,...,outputNValue` are either 1 or 0 depending on the value of the corresponding pin