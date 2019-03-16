//---------A logic gate simulator----------
//By Tejas Hegde
//To add:
//-Load/save circuits
//-Composite circuits --first priority
//-----------------------------------------

//Putting these here cause you cant make static vars in processing
//This is to prevent multiple things being dragged at once
UIElement draggedElement = null; 
boolean mouseOver = false;
//A rectangular UI element that all classes will derive from 
class UIElement{
  protected UIElement parent;
  public float x,y,w=5,h=5;
  private boolean clicked = false;
  protected int dragThreshold = 2;
  protected boolean acceptUIInput = true;
  
  public void MoveTo(float x1, float y1){
    x = x1; y = y1;
  }
  
  public float WorldX(){
    if(parent!=null)
      return parent.WorldX()+x;
      
    return x;
  }
  
  public float WorldY(){
    if(parent!=null)
      return parent.WorldY()+y;
      
    return y;
  }
  
  public void UIRespond(){
    if(!acceptUIInput)
      return;
    
    float x1 = WorldX()-w/2;
    float y1 = WorldY()-h/2; 
    //handle mouse clicks in an override if we aren't clicking an in/output
    if(mouseInside(x1,y1,w,h)){
      OnHover();
      mouseOver = true;
      if(mousePressed){
        if(!clicked){
          OnMousePress();
          clicked=true;
        } else {
          if(!(draggedElement==this))
            OnMouseDown();
        }
        
        if(abs(mouseX-pmouseX)+abs(mouseY-pmouseY)>dragThreshold){
            if(draggedElement==null){
              draggedElement = this;
              OnDragStart();
            }
        }
      } else if(clicked) {
        clicked = false;
        OnMouseRelease();
        draggedElement = null;
      }
    } else {
      if(clicked){
        clicked = false;
        if(!mousePressed){
          OnMouseRelease();
        }
      }
      
      if(draggedElement==this){
        if(!mousePressed)
          draggedElement = null;
      }
    }
    
    if(draggedElement==this){
      OnDrag();
    }
  }
  
  //this function is called every frame, and can also be used to start events
  public void Draw(){    
    float x1 = WorldX()-w/2;
    float y1 = WorldY()-h/2; 
    
    UIRespond();
    //let the input overrides determine the colour of this rectangle
    rect(x1,y1,w,h);
  }
  
  public void OnMousePress(){}
  
  public void OnMouseRelease(){}
  
  public void OnMouseDown(){}

  public void OnHover(){}
  
  public void OnDrag(){}
  
  public void OnDragStart(){}
}

class Pin extends UIElement{
  protected LogicGate chip;
  
  public boolean IsDeleted(){
    return chip.deleted;
  }
  
  Pin(LogicGate parentChip){
    chip = parentChip;
    parent = parentChip;
    dragThreshold = -1;
  }
  
  @Override
  public void OnHover(){
    stroke(foregroundCol);
    rect(WorldX()-w/2+2,WorldY()-w/2+2,w-4,h-4);
    if(!mousePressed){
      lastSelectedPin = this;
    }
  }
  
  @Override
  public void Draw(){
    stroke(foregroundCol);
    if(IsConnected()){
      fill(Value() ? trueCol : falseCol);
    } else {
      noFill();
    }
    super.Draw();
  }
  
  public void UpdatePin(){
    if(Value()!=lastValue){
      OnValueChange();
    }
    lastValue = Value();
  }
  
  boolean lastValue = false;
  public boolean Value(){return false;}
  public boolean IsConnected(){return true;}
  
  public void OnValueChange(){
    chip.UpdateLogic();
  }
}

//An input pin on a logic gate. Every input can link to at most 1 output pin
class InPin extends Pin{
  private OutPin input;
  
  public InPin(LogicGate p){
    super(p);
  }
  
  public void Connect(OutPin in){
    input = in;
    OnValueChange();
  }

  @Override
  public void OnHover(){
    super.OnHover();
  }
  
  @Override
  public void Draw(){
    super.Draw();
    if(IsConnected()){
      line(WorldX(),WorldY(),input.WorldX(),input.WorldY());
    }
  }
  
  @Override
  public boolean IsConnected(){
    return (input!=null);
  }
  
  @Override
  void UpdatePin(){
    super.UpdatePin();
    if(IsConnected()){
      if(input.IsDeleted()){
        //We need to remove all references to the deleted chip in order for the garbage collecter to collect it
        Connect(null);
      }
    }
  }

  @Override
  public boolean Value(){
    if(input!=null){
      return input.Value();
    } else {
      return false;
    }
  }
  
  @Override
  public void OnDragStart(){
    ClearPinSelection();
    Connect(null);
  }
  
  @Override
  public void OnDrag(){
    if(mouseButton==LEFT){
      lastSelectedInput = this;
      stroke(gateHoverCol);
      line(WorldX(), WorldY(), MouseXPos(), MouseYPos());
    }
  }
  
  @Override
  public void OnMouseRelease(){
    if(mouseButton==LEFT){
      MakeConnection(lastSelectedOutput, this);
    }
  }
}

//This is a pin that outputs a value to an input pin.
class OutPin extends Pin{  
  int index;
  int Index(){return index;}
  
  OutPin(LogicGate p, int i){
    super(p);
    index = i;
  }
  
  public void SetValue(boolean v){
    if(IsDeleted())
      return;
      
    value = v;
  }
  
  public long ChipID(){
    return chip.ID();
  }
  
  @Override
  public boolean Value(){
    return value;
  }

  @Override
  public void OnHover(){
    super.OnHover();
    if(!mousePressed){
      lastSelectedOutput = this;
    }
  }

  @Override
  public void Draw(){
    fill(Value() ? trueCol : falseCol);
    super.Draw();
  }
  
  @Override
  public void OnDragStart(){
    ClearPinSelection();
  }
  
  @Override
  public void OnDrag(){
    if(mouseButton==LEFT){
      lastSelectedOutput = this;
      stroke(gateHoverCol);
      line(WorldX(), WorldY(), MouseXPos(), MouseYPos());
    }
  }
  
  @Override
  public void OnMouseRelease(){
    if(mouseButton==LEFT){
      MakeConnection(this, lastSelectedInput);
    }
  }
  
  boolean value = false;
}

//a different number for each logic gate
//does not need to be saved for each gate
long logicGateID = 0;
LogicGate gateUnderMouse = null;

//The base class for all logic gates. contains most of the functionality
abstract class LogicGate extends UIElement implements Comparable<LogicGate>{
  String title = "uninitializedGate";
  public boolean deleted = false;
  protected boolean showText = true;
  boolean drawPins = true;
  private long id;
  protected int level = 0;
  InPin[] inputs;
  
  //This will be set by any function traversing a list of logicgates
  public int arrayIndex;
  
  void ArrangeInputs(){
    if(inputs==null)
      return;
    
    for(int i = 0; i < inputs.length; i++){
      inputs[i].x = -w/2-inputs[i].w/2;
      inputs[i].y = -h/2.0 + h*((float)(i+1)/((float)inputs.length+1));
    }
  }
  
  OutPin[] outputs;
  void ArrangeOutputs(){
    if(outputs==null)
      return;
    for(int i = 0; i < outputs.length; i++){
      outputs[i].x = w/2+outputs[i].w/2;
      outputs[i].y = -h/2.0 + h*((float)(i+1)/((float)outputs.length+1));
    }
  }
  
  int compareTo(LogicGate lg){
    return Integer.compare(level,lg.level);
  }
  
  LogicGate(){
    id = logicGateID;
    logicGateID++;
  }
  
  public int NumGates(){
    return 1;
  }
  
  public int NumGates(String type){
    if(title==type)
      return 1;
    return 0;
  }
  
  //returns the memory address of this object as an unsigned integer
  public long ID(){
    return id;
  }
  
  public int OutputIndex(OutPin output){
    for(int i = 0; i < outputs.length; i++){
      if(outputs[i]==output){
        return i;
      }
    }
    return -1;
  }
  
  public void Decouple(){
    deleted = true;
    if(inputs!=null){
      for(InPin p : inputs){
        p.Connect(null);
      }
    }
  }
  
  public abstract LogicGate CopySelf();
  
  //won't work if the gates are of different kinds
  public void CopyValues(LogicGate other){
    x = other.x;
    y = other.y;
    parent = other.parent;
    for(int i = 0; i < inputs.length; i++){
      inputs[i].Connect(other.inputs[i].input);
    }
  }
  
  @Override
  public void OnDrag(){
    if(mouseButton==LEFT){
      //drag functionality
      if(dragStarted)
        return;
        
      float dX = ToWorldX(mouseX)-ToWorldX(pmouseX);
      float dY = ToWorldY(mouseY)-ToWorldY(pmouseY);
      dragStarted = true;
      if(selection.size()==0){
        x+= dX;
        y+= dY;
      } else {
        for(int i = 0; i < selection.size(); i++){
          selection.get(i).x += dX;
          selection.get(i).y += dY;
        }
      }
    }
  }
  
  @Override
  public void OnHover(){
    fill(gateHoverCol);
    gateUnderMouse = this;
  }
  
  @Override
  public void Draw(){
    if(outputs!=null){
      if(outputs.length>0){
        fill(outputs[0].Value() ? trueCol : falseCol);
      }
    }
    stroke(foregroundCol);
    super.Draw();
    if(showText){
      textAlign(CENTER);
      fill(foregroundCol);
      text(title,WorldX(),WorldY());
    }
    
    stroke(foregroundCol);
    
    if(drawPins){
      if(inputs!=null){
        for(int i = 0; i < inputs.length; i++){
          inputs[i].Draw();
        }
      }
      
      if(outputs!=null){
        for(int i = 0; i < outputs.length; i++){
          outputs[i].Draw();
        }
      }
    }
  }
  
  //will involve setting outputs in overrides, which should cause a cascading change
  protected void UpdateLogic(){}
  
  public void UpdateIOPins(){
    if(inputs!=null){
      for(InPin in : inputs){
        in.UpdatePin();
      }
    }
    
    if(outputs!=null){
      for(OutPin out : outputs){
        out.UpdatePin();
      }
    }
  }
}

//should not be instantiated
abstract class BinaryGate extends LogicGate{
  public BinaryGate(){
    super();
    w = 50; 
    h = 30;    
    
    inputs = new InPin[2];
    inputs[0] = new InPin(this);
    inputs[1] = new InPin(this);
    /*
    inputs[0] = new InPin(this);
    inputs[0].MoveTo(-w/2-inputs[0].w/2,inputs[0].h);
    inputs[1] = new InPin(this);
    inputs[1].MoveTo(-w/2-inputs[1].w/2,-inputs[1].h);
    */
    ArrangeInputs();
    
    outputs = new OutPin[1];
    outputs[0] = new OutPin(this,0);
    ArrangeOutputs();
  }
}

class AndGate extends BinaryGate{
  public AndGate(){
    super();
    title = "&";
  }
  
  @Override
  protected void UpdateLogic(){
    outputs[0].SetValue(inputs[0].Value() && inputs[1].Value());
  }
  
  @Override
  public LogicGate CopySelf(){
    LogicGate lg = new AndGate();
    lg.CopyValues(this);
    return lg;
  }
}

class OrGate extends BinaryGate{
  public OrGate(){
    super();
    title = "|";
  }
  
  @Override
  protected void UpdateLogic(){
    outputs[0].SetValue(inputs[0].Value() || inputs[1].Value());
  }
  
  @Override
  public LogicGate CopySelf(){
    LogicGate lg = new OrGate();
    lg.CopyValues(this);
    return lg;
  }
}

class NotGate extends LogicGate{
  public NotGate(){
    super();
    w=20;
    h=20;
    inputs = new InPin[1];
    inputs[0] = new InPin(this);
    inputs[0].MoveTo(-w/2-inputs[0].w/2,0);
    
    title = "!";
    outputs = new OutPin[1];
    outputs[0] = new OutPin(this,0);
    outputs[0].MoveTo(w/2+outputs[0].w/2,0);
  }
  
  @Override
  protected void UpdateLogic(){
    outputs[0].SetValue(!inputs[0].Value());
  }
  
  @Override
  public LogicGate CopySelf(){
    LogicGate lg = new NotGate();
    lg.CopyValues(this);
    return lg;
  }
}

class NandGate extends BinaryGate{
  public NandGate(){
    super();
    title = "!&";
  }
  
  @Override
  protected void UpdateLogic(){
    outputs[0].SetValue(!(inputs[0].Value() && inputs[1].Value()));
  }
  
  @Override
  public LogicGate CopySelf(){
    LogicGate lg = new NandGate();
    lg.CopyValues(this);
    return lg;
  }
}


class RelayGate extends LogicGate{
  public RelayGate(){
    super();
    w=15;
    h=15;
    inputs = new InPin[1];
    inputs[0] = new InPin(this);
    inputs[0].MoveTo(-w/2-inputs[0].w/2,0);
    
    title = "->";
    outputs = new OutPin[1];
    outputs[0] = new OutPin(this,0);
    outputs[0].MoveTo(w/2+outputs[0].w/2,0);
  }
  
  @Override
  void OnMouseRelease(){
    super.OnMouseRelease();
    if((mouseButton==LEFT)&&(draggedElement!=this)){
      outputs[0].SetValue(!outputs[0].Value());
    }
  }  
  
  @Override
  protected void UpdateLogic(){
    if(inputs[0].IsConnected()){
      outputs[0].SetValue(inputs[0].Value());
    }
  }
  
  @Override
  public LogicGate CopySelf(){
    LogicGate lg = new RelayGate();
    lg.CopyValues(this);
    return lg;
  }
}

class LCDGate extends LogicGate{
  public LCDGate(float wid,float hei){
    super();
    showText=false;
    w=wid; h=hei;
    title = "LC";
    inputs = new InPin[1];
    inputs[0] = new InPin(this);
    inputs[0].MoveTo(-w/2-inputs[0].w/2,0);
  }
  
  @Override
  public void Draw(){
    super.Draw();
    stroke(foregroundCol);
    fill(inputs[0].Value() ? foregroundCol : backgroundCol);
    rect(WorldX()-w/2,WorldY()-h/2,w,h);
  }
  
  @Override
  public LogicGate CopySelf(){
    LogicGate lg = new LCDGate(w,h);
    lg.CopyValues(this);
    return lg;
  }
}

class PixelGate extends LogicGate{
  public PixelGate(float wid, float hei){
    super();
    w=wid; h = hei;
    showText=false;
    title = "PX";
    inputs = new InPin[24];
    for(int i = 0; i < 8; i++){
      inputs[i] = new InPin(this);
      inputs[i].w = hei/8.0;
      inputs[i].h = inputs[i].w;
      inputs[i].MoveTo(-w/2.0-inputs[i].w/2.0, h/2.0 - (i)*inputs[i].h - inputs[i].h/2.0);
    }
    for(int i = 8; i < 16; i++){
      inputs[i] = new InPin(this);
      inputs[i].w = hei/8.0;
      inputs[i].h = inputs[i].w;
      inputs[i].MoveTo(w/2.0+inputs[i].w/2.0, h/2.0 - (i-8)*inputs[i].h - inputs[i].h/2.0);
    }
    for(int i = 16; i < 24; i++){
      inputs[i] = new InPin(this);
      inputs[i].w = hei/8.0;
      inputs[i].h = inputs[i].w;
      inputs[i].MoveTo(-w/2.0+inputs[i].w/2.0 + (i-16)*inputs[i].w, h/2.0 + inputs[i].h/2.0);
    }
  }
  
  @Override
  public LogicGate CopySelf(){
    LogicGate lg = new PixelGate(w,h);
    lg.CopyValues(this);
    return lg;
  }
  
  public void Draw(){
    super.Draw();
    int r = 0,g=0,b=0;
    for(int i = 0; i < 8; i++){
      if(inputs[i].Value()){
        r += pow(2,i);
      }
      
      if(inputs[i+8].Value()){
        g += pow(2,i);
      }
      
      if(inputs[i+16].Value()){
        b += pow(2,i);
      }
    }
    
    stroke(foregroundCol);
    fill(r,g,b);
    rect(WorldX()-w/2,WorldY()-h/2,w,h);
    fill(foregroundCol);
    
    textAlign(CENTER);
    textSize(inputs[0].h/2);
    for(int i = 0; i < 8; i ++){
      text((int)pow(2,i), inputs[i].WorldX(),inputs[i].WorldY());
      text((int)pow(2,i), inputs[i+8].WorldX(),inputs[i+8].WorldY());
      text((int)pow(2,i), inputs[i+16].WorldX(),inputs[i+16].WorldY());
    }
    textSize(12);
  }
}

//Makes sure that the copied gates aren't connected to the old ones
LogicGate[] CopyPreservingConnections(LogicGate[] gates){
  LogicGate[] newGates = new LogicGate[gates.length];
  
  for(int i = 0; i < gates.length; i++){
    newGates[i] = gates[i].CopySelf();
    if(gates[i].inputs!=null){
    //we need to know what their array positions are in order to do the next part
    gates[i].arrayIndex = i;
    }
  }
  
  //make the connections copied -> copied instead of original -> copied
  for(int i = 0; i < gates.length; i++){
    for(int j = 0; j < gates[i].inputs.length; j++){
      //get the output gate from our gates 
      if(!gates[i].inputs[j].IsConnected())
        continue;
      LogicGate outputLg = gates[i].inputs[j].input.chip; 
      int gateIndex = outputLg.arrayIndex;
      int outputIndex = outputLg.OutputIndex(gates[i].inputs[j].input);
      InPin copiedInput = newGates[i].inputs[j]; 
      OutPin copiedOutput = newGates[gateIndex].outputs[outputIndex];
      copiedInput.Connect(copiedOutput);
    }
  }
  
  return newGates;
}

class LogicGateGroup extends LogicGate{
  LogicGate[] gates;
  boolean expose = true;
  int numGates;
  @Override
  int NumGates(){
    int sum = 0;
    for(LogicGate lg : gates){
      sum += lg.NumGates();
    }
    return sum;
  }
  
  //creates a group using an array of existing gates (they can also be groups themselves :0)
  //exposes all unlinked inputs and outputs
  LogicGateGroup(LogicGate[] gateArray){
    gates = gateArray;
    title = "LG";
    showText = false;
    
    //find the bounding box for the group
    //also find the abstraction level
    //also find exposed input pins
    
    float minX=gates[0].x;
    float maxX=gates[0].x;
    float minY=gates[0].y; 
    float maxY=gates[0].y;
    
    int maxAbstraction = 0; 
    ArrayList<InPin> temp = new ArrayList<InPin>();
    ArrayList<OutPin> usedOutputs = new ArrayList<OutPin>();
    for(LogicGate lg : gates){
      lg.drawPins = true;
      lg.acceptUIInput = false;
      
      minX=min(lg.x-lg.w/2-5, minX);
      maxX = max(lg.x+lg.w/2+5, maxX);
      minY=min(lg.y-lg.h/2-5,minY);
      maxY=max(lg.y+lg.h/2+5,maxY);
      lg.parent = this;
      maxAbstraction = max(lg.level, maxAbstraction);
      numGates += lg.NumGates();
      
      //expose inputs
      for(InPin p : lg.inputs){
        if(!p.IsConnected()){
          temp.add(p);
          //Only changes the UI parent and not the connected logic chip
          p.parent = this;
        } else {
          usedOutputs.add(p.input);
        }
      }
    }
    
    x = (minX+maxX)/2.0;
    y = (minY+maxY)/2.0;
    w = maxX-minX;
    h = maxY-minY;
    inputs = temp.toArray(new InPin[temp.size()]);
    
    //make the x and y positions of the gates relative to this
    //and also find all the unlinked outputs
    ArrayList<OutPin> unusedOutputs = new ArrayList<OutPin>();
    for(LogicGate lg : gates){
      lg.x -= x;
      lg.y -= y;
      if(lg.outputs!=null){
        for(OutPin p : lg.outputs){
          if(!usedOutputs.contains(p)){
            unusedOutputs.add(p);
            p.parent = this;
          }
        }
      }
    }
    outputs = unusedOutputs.toArray(new OutPin[unusedOutputs.size()]);
    
    ArrangeInputs();
    ArrangeOutputs();
    level = maxAbstraction+1;
  }
  
  @Override
  public void Draw(){
    noFill();
    super.Draw();
    
    if(expose){
      for(LogicGate lg : gates){
        lg.Draw();
      }
    }
  }
  
  @Override
  public void UpdateIOPins(){
    for(LogicGate lg : gates){
      lg.UpdateIOPins();
    }
  }
  
  @Override
  public LogicGate CopySelf(){
    LogicGate lg = new LogicGateGroup(CopyPreservingConnections(gates));
    lg.CopyValues(this);
    return lg;
  }
}

//----------------- CUSTOM UI ELEMENTS ----------------
//used by other ui elements
class CallbackFunctionInt {
  public void f(int i){}
}

class StringMenu extends UIElement{
  ArrayList<String> elements;
  float elementHeight = 11;
  float padding = 2;
  String heading;
  CallbackFunctionInt f;
  
  public StringMenu(String[] arr, String title, CallbackFunctionInt intFunction){
    heading = title;
    elements = new ArrayList<String>();
    for(String s : arr){
      elements.add(s);
    }
    f = intFunction;
    
    //setup the dimensions
    int max = heading.length();
    for(Object s : elements){
      if(s.toString().length() > max){
        max = s.toString().length();
      }
    }
    
    w = max * 7 + 20 + 2 * padding;
    h = (elements.size()+1) * (elementHeight+padding) + padding;
    x = w/2;
    y = h/2;
  }
  
  @Override
  public void MoveTo(float x1, float y1){
    x = x1+w/2; y = y1+h/2;
  }
  
  @Override
  public void OnMouseRelease(){
    listClicked = false;
  }
  
  public void AddEntry(String s){
    elements.add(s);
  }
  
  boolean listClicked = false;
  
  @Override
  public void Draw(){
    noFill();
    stroke(foregroundCol);
    super.Draw();
    fill(menuHeadingCol);
    textAlign(CENTER);
    text(heading,WorldX(),WorldY()-h/2+elementHeight);
    for(int i = 0; i < elements.size();i++){
      noFill();
      float x1 = WorldX()-w/2+padding;
      float y1 = WorldY()+padding + i*(elementHeight+padding)-h/2+elementHeight;
      float w1 = w-2*padding;
      float h1 = elementHeight;
      if(mouseInside(x1,y1,w1,h1)){
        mouseOver = true;
        fill(gateHoverCol);
        if(mousePressed && (mouseButton==LEFT)){
          noFill();
          if(!listClicked){
            listClicked = true;
            f.f(i);
          }
        }
      }
      rect(x1,y1, w1, h1);
    }
    
    fill(foregroundCol);
    textAlign(CENTER);
    for(int i = 0; i < elements.size();i++){
      float x1 = WorldX();
      float y1 = WorldY()+ (i+1)*(elementHeight+padding)-h/2+elementHeight-padding;      
      text(elements.get(i),x1,y1);
    }
  }
}


//INPUT SYSTEM copy pasted from another personal project
boolean[] keyJustPressed = new boolean[22];
boolean[] keyStates = new boolean[22];
boolean keyDown(int Key) { return keyStates[Key]; }
boolean keyPushed(int Key){
  if(!keyDown(Key))
    return false;
    
  if(!keyJustPressed[Key]){
    keyJustPressed[Key] = true;
    return true;
  }
  return false;
}

final int AKey = 0;
final int DKey = 1;
final int WKey = 2;
final int SKey = 3;
final int CKey = 4;
final int QKey = 5;
final int EKey = 6;
final int ShiftKey = 7;
final int CtrlKey = 8;
final int PKey = 9;
final int RKey = 10;
final int BKey = 11;
final int ZKey = 12;
final int XKey = 13;
final int VKey = 14;
final int SpaceKey = 15;
final int FKey = 16;
final int NKey = 17;
final int TabKey = 18;
final int FSlashKey = 19;
final int TKey = 20;
final int GKey = 21;

boolean shiftChanged = false;
//maps the processing keys to integers in our key state array, so we can add new keys as we please
HashMap<Character, Integer> keyMappings = new HashMap<Character, Integer>();

void keyPressed(){
  if(keyMappings.containsKey(key)){
    keyStates[keyMappings.get(key)]=true;
  }
  
  if(keyCode==SHIFT){
    if(!keyStates[ShiftKey]){
      keyStates[ShiftKey] = true;
      shiftChanged = true;
    }
  }
  
  if(keyCode==CONTROL){
    keyStates[CtrlKey] = true;
  }
  
  if(keyCode==TAB){
    keyStates[TabKey] = true;
  }
}

void keyReleased(){
  if(keyMappings.containsKey(key)){    
    keyStates[keyMappings.get(key)]=false;
    keyJustPressed[keyMappings.get(key)]=false;
  }
  
  if(keyCode==SHIFT){
    if(keyStates[ShiftKey]){
      keyStates[ShiftKey]=false;
      shiftChanged = true;
    }
    keyJustPressed[ShiftKey]=false;
  }
  
  if(keyCode==CONTROL){
    keyStates[CtrlKey]=false;
    keyJustPressed[CtrlKey]=false;
  }
  
  if(keyCode==TAB){
    keyStates[TabKey] = false;
    keyJustPressed[TabKey]=false;
  }
  
  dragStartPos = -1;
  dragDelta = 0;
}

float dragStartPos = 0;
float dragDelta = 0;

void setup(){
  size(800,600);
  
  textFont(createFont("Monospaced",12));
  circuit = new ArrayList<LogicGate>();
  circuitGroups = new ArrayList<LogicGateGroup>();
  deletionQueue = new ArrayList<LogicGate>();
  selection = new ArrayList<LogicGate>();
  AddGate(0);
  
  //setup the input system
  keyMappings.put('a', AKey);
  keyMappings.put('A', AKey);
  keyMappings.put('s', SKey);
  keyMappings.put('S', SKey);
  keyMappings.put('d', DKey);
  keyMappings.put('D', DKey);
  keyMappings.put('w', WKey);
  keyMappings.put('W', WKey);
  keyMappings.put('q', QKey);
  keyMappings.put('Q', QKey);
  keyMappings.put('e', EKey);
  keyMappings.put('E', EKey);
  keyMappings.put('c', CKey);
  keyMappings.put('C', CKey);
  keyMappings.put('p', PKey);
  keyMappings.put('P', PKey);
  keyMappings.put('r', RKey);
  keyMappings.put('R', RKey);
  keyMappings.put('b', BKey);
  keyMappings.put('B', BKey);
  keyMappings.put('z', ZKey);
  keyMappings.put('Z', ZKey);
  keyMappings.put('x', XKey);
  keyMappings.put('X', XKey);
  keyMappings.put('v', VKey);
  keyMappings.put('V', VKey);
  keyMappings.put('f', FKey);
  keyMappings.put('F', FKey);
  keyMappings.put('n', NKey);
  keyMappings.put('N', NKey);
  keyMappings.put('/', FSlashKey);
  keyMappings.put('?', FSlashKey);
  keyMappings.put('t', TKey);
  keyMappings.put('T', TKey);
  keyMappings.put(' ', SpaceKey);
  keyMappings.put('g',GKey);
  keyMappings.put('G',GKey);
  
  menus = new ArrayList<UIElement>();
  UIElement logicGateAddMenu = new StringMenu(gateNames, "ADD GATE", new CallbackFunctionInt(){
    @Override
    public void f(int i){
      AddGate(i);
    }
  });
  
  menus.add(logicGateAddMenu);
  
  UIElement outputGateAddMenu = new StringMenu(outputNames, "ADD OUTPUT GATE", new CallbackFunctionInt(){
    @Override
    public void f(int i){
      AddGate(i+gateNames.length);
    }
  });
  outputGateAddMenu.MoveTo(logicGateAddMenu.w+10,0);
  menus.add(outputGateAddMenu);
  
  UIElement logicGateGroupAddMenu = new StringMenu(new String[]{}, "ADD A GROUP", new CallbackFunctionInt(){
    @Override
    public void f(int i){
      AddGateGroup(i);
    }
  });
  
  logicGateGroupAddMenu.MoveTo(outputGateAddMenu.WorldX()+outputGateAddMenu.w/2f+10,0);
  
  menus.add(logicGateGroupAddMenu);
}


ArrayList<UIElement> menus;

//moving the screen around
float xPos=0;
float yPos=0;
float scale=1;

color backgroundCol = color(255);
color foregroundCol = color(0);
color trueCol = color(0,255,0,100);
color falseCol = color(255,0,0,100);
color gateHoverCol = color(0,0,255,100);
color menuHeadingCol = color(0,0,255);
color warningCol = color(255,0,0);

float ToWorldX(float screenX){
  return ((screenX-width/2)/scale)+xPos;
}

float MouseXPos(){
  return ToWorldX(mouseX);
}

float ToWorldY(float screenY){
  return ((screenY-height/2)/scale)+yPos;
}

float MouseYPos(){
  return ToWorldY(mouseY);
}

//Have some helper functions here
boolean pointInside(float mX, float mY,float x, float y, float w, float h){
  if(mX>x){
    if(mX < x+w){
      if(mY > y){
        if(mY < y + h){
          return true;
        }
      }
    }
  }
  
  return false;
}

boolean mouseInside(float x, float y, float w, float h){
  return pointInside(ToWorldX(mouseX), ToWorldY(mouseY), x, y,w,h);
}

ArrayList<LogicGate> circuit;
ArrayList<LogicGateGroup> circuitGroups;
//related to the dragging of buttons
boolean dragStarted = false;

//deletes the given gate, else deletes everything that's selected
void DeleteGates(LogicGate lg){
  if(selection.size()==0){
    deletionQueue.add(lg);
    lg.Decouple();
  } else {
    for(LogicGate selectedGate : selection){
      deletionQueue.add(selectedGate);
      selectedGate.Decouple();
    }
  }
}

void DeleteGates(LogicGate[] lg){
  for(LogicGate g : lg){
    deletionQueue.add(g);
    g.Decouple();
  }
}

ArrayList<LogicGate> deletionQueue;

void Cleanup(){
  if(deletionQueue.size()>0){
    for(LogicGate lg : deletionQueue){
      circuit.remove(lg);
      lg.Decouple();
    }
    deletionQueue.clear();
    
    ClearGateSelection();
    ClearPinSelection();
  }
}

String gateNames[] = {"input / relay point","And", "Or", "Not", "Nand"};

//creates a new group from the selected elements
void CreateNewGroup(){
  if(numSelected <= 1)
    return;
  if(selection.size()<=1)
    return;
    
  LogicGate[] gates = selection.toArray(new LogicGate[selection.size()]);
  LogicGateGroup g = new LogicGateGroup(gates);
  circuit.add(g);
  for(LogicGate lg: gates){
    circuit.remove(lg);
  }
  
  ClearGateSelection();
}

//Copies the selection
void Duplicate(){
  if(selection.size()==0)
    return;
    
  LogicGate[] newGates = CopyPreservingConnections(selection.toArray(new LogicGate[selection.size()]));
  selection.clear();
  for(LogicGate lg : newGates){
    selection.add(lg);
    circuit.add(lg);      
  }
  /*
  float xOffset = cursor.WorldX() - newGates[0].WorldX();
  float yOffset = cursor.WorldY() - newGates[0].WorldY();
  for(LogicGate lg : newGates){
    lg.x += xOffset;
    lg.y += yOffset;      
  }
  */
}

//soon my brodas, soon
void AddGateGroup(int i){
  
}

//This function can add every primitive gate
void AddGate(int g){
  LogicGate lg;
  switch(g){
    case(1):{
      lg = new AndGate();
      break;
    }
    case(2):{
      lg = new OrGate();
      break;
    }
    case(3):{
      lg = new NotGate();
      break;
    }
    case(4):{
      lg = new NandGate();
      break;
    }
    case(5):{
      lg = new LCDGate(20,20);
      break;
    }
    case(6):{
      lg = new PixelGate(20,20);
      break;
    }
    case(7):{
      lg = new LCDGate(80,80);
      break;
    }
    case(8):{
      lg = new PixelGate(80,80);
      break;
    }
    default:{
      lg = new RelayGate();
      break;
    }
  }
  lg.x=cursor.WorldX();
  lg.y=cursor.WorldY();
  circuit.add(lg);
}

String outputNames[] = {"LCD Pixel", "24-bit Pixel", "LCD Pixel large", "LCD 24-bit Pixel large"};

Pin lastSelectedPin;
OutPin lastSelectedOutput = null;
InPin lastSelectedInput = null;
ArrayList<OutPin> selectedOutputs = new ArrayList<OutPin>();
ArrayList<InPin> selectedInputs = new ArrayList<InPin>();
void ConnectSelected(){
  int n = min(selectedInputs.size(),selectedOutputs.size());
  if(n==0){
    for(InPin p : selectedInputs){
      p.Connect(null);
    }
  }
  for(int i = 0; i < selectedInputs.size(); i++){
    MakeConnection(selectedOutputs.get(i%selectedOutputs.size()),selectedInputs.get(i));
  }
}

void ClearPinSelection(){
  lastSelectedPin = null;
  lastSelectedOutput = null;
  lastSelectedInput = null;
  selectedOutputs.clear();
  selectedInputs.clear();
}

void ClearGateSelection(){
  selection.clear();
  numSelected = 0;
}

void MakeConnection(OutPin from, InPin to){
  if(from==null)
    return;
  if(to==null)
    return;
  to.Connect(from);
}

ArrayList<LogicGate> selection;
int numSelected = 0;
//2D cursor. will be used to make selections
class Cursor2D extends UIElement{
  float xBounds = 0;
  float yBounds = 0;
  boolean cursorPlaced = false;
  
  @Override
  public void Draw(){
    w=20.0/scale;
    h=w;
    stroke(foregroundCol);
    noFill();
    ellipse(WorldX(),WorldY(),w,w);
    drawCrosshair(WorldX(),WorldY(),w);
    UIRespond();
  }
  
  @Override
  public void OnDragStart(){
    Reset();
  }
  
  @Override
  public void OnDrag(){
    float dX = ToWorldX(mouseX)-ToWorldX(pmouseX);
    float dY = ToWorldY(mouseY)-ToWorldY(pmouseY);
    xBounds += dX;
    yBounds += dY;
  }
  
  public void Place(float x1, float y1){
    if(draggedElement!=this){
      x=x1; y=y1;
    }
  }
  
  public void DrawSelect(){
    rect(WorldX(),WorldY(),xBounds,yBounds);
  }
  
  public void Reset(){
    xBounds = 0;
    yBounds = 0;
  }
}

Cursor2D cursor = new Cursor2D();

float deleteTimer = 0;
void IncrementDeleteTimer(float x, float y, float w, float h, LogicGate lg){
  deleteTimer += TAU/60.0;
  if(deleteTimer > 0.01f){
    noFill();
    stroke(warningCol);
    strokeWeight(3);
    arc(x,y,2*w,2*w,0,deleteTimer);
    strokeWeight(1);
    fill(255,0,0);
    text("deleting...",x,y+h+10);
  }
  
  if(deleteTimer > TAU){
    deleteTimer = 0;
    DeleteGates(lg);
  }
}


void draw(){
  if(gateUnderMouse!=null){
    cursor(MOVE);
  } else {
    noCursor();
  }
  
  //needs to be manually reset
  mouseOver = false;
  gateUnderMouse = null;
  
  //UI space
  dragStarted = false;
  background(backgroundCol);
  fill(foregroundCol);
  stroke(foregroundCol);
  drawCrosshair(mouseX,mouseY,10);
  
  textAlign(LEFT);
  if(numSelected > 0){
    text("Selected gates: "+numSelected+" primitive, "+selection.size()+" groups",0,10);
  }
  if((selectedInputs.size()+selectedOutputs.size())>0){
    text("Selected IO: "+selectedInputs.size()+" input nodes, "+selectedOutputs.size()+" output nodes",0,20);
  }
  
  //World space
  translate(width/2,height/2);
  scale(scale);
  translate(-xPos,-yPos);
  drawCrosshair(0,0,30);
  textAlign(RIGHT);
  text("0,0", -12,12);
  
  
  for(LogicGate lGate : circuit){
    lGate.Draw();
    lGate.UpdateIOPins();
  }
  
  for(UIElement element : menus){
    element.Draw();
  }
  
  if(mousePressed){
    if(mouseButton==RIGHT){
      float xAmount = mouseX-pmouseX;
      float yAmount = mouseY-pmouseY;
      adjustView(-xAmount,-yAmount,0);
      
      if(gateUnderMouse!=null){
        IncrementDeleteTimer(gateUnderMouse.x, gateUnderMouse.y,40,gateUnderMouse.h, gateUnderMouse);
      }
    } else {
      if(!((draggedElement!=null)||(mouseOver))){
        cursor.Place(MouseXPos(),MouseYPos());
        if(!keyDown(ShiftKey)){
          ClearGateSelection();
          ClearPinSelection();
        }
      }
      
      //Object selection logic
      if(draggedElement==cursor){
        noFill();
        cursor.DrawSelect();
        
        //Select gates
        float x1 = cursor.WorldX();
        float y1 = cursor.WorldY();
        float w1 = cursor.xBounds;
        float h1 = cursor.yBounds;
        if(w1<0){
            x1+=w1; w1=-w1;
        }
        if(h1<0){
          y1+=h1; h1=-h1;
        }
        
        for(LogicGate lgate : circuit){
          if(pointInside(lgate.WorldX(),lgate.WorldY(),x1,y1,w1,h1)){
            if(!selection.contains(lgate)){
              selection.add(lgate);
              numSelected+= lgate.NumGates();
            }
          }
          
          //Select pins while looking at this gate
          if(lgate.inputs!=null){
            for(InPin p : lgate.inputs){
              if(pointInside(p.WorldX(), p.WorldY(),x1,y1,w1,h1)){
                if(!selectedInputs.contains(p)){
                  selectedInputs.add(p);
                }
              }
            }
          }
          
          if(lgate.outputs!=null){
            for(OutPin p : lgate.outputs){
              if(pointInside(p.WorldX(), p.WorldY(),x1,y1,w1,h1)){
                if(!selectedOutputs.contains(p)){
                  selectedOutputs.add(p);
                }
              }
            }
          }
        }
      } else {
        cursor.Reset();
      }
    }
  } else {
    deleteTimer = 0;
  }
  
  cursor.Draw();
  
  for(LogicGate lGate : selection){
    stroke(255,0,0);
    drawCrosshair(lGate.WorldX(),lGate.WorldY(),max(10.0/scale,lGate.w));
  }
  
  strokeWeight(2);
  stroke(0,255,255);
  int i = 0;
  for(InPin p : selectedInputs){
    drawArrow(p.WorldX(), p.WorldY(),10,-1,false);
    text(i,p.WorldX(), p.WorldY());
    i++;
  }
  stroke(255,255,0);
  i = 0;
  for(OutPin p : selectedOutputs){
    drawArrow(p.WorldX(), p.WorldY(),10,-1,false);
    text(i,p.WorldX(), p.WorldY());
    i++;
  }
  strokeWeight(1);
  //handle all key shortcuts
  if(keyDown(ShiftKey)){
    if(keyPushed(GKey)){
      CreateNewGroup();
    } else if(keyPushed(DKey)){
      Duplicate();
    } else if(keyPushed(CKey)){
      ConnectSelected();
    }
  }
  
  Cleanup();
}

void drawArrow(float x, float y, float size, int dir, boolean vertical){
  if(vertical){
    line(x,y,x-dir*size,y+dir*size);
    line(x,y,x+dir*size,y+dir*size);
  } else {
    line(x,y,x+dir*size,y+dir*size);
    line(x,y,x+dir*size,y-dir*size);
  }
}

void mouseWheel(MouseEvent e){
  xPos = lerp(xPos,MouseXPos(),0.1*-e.getCount());
  yPos = lerp(yPos,MouseYPos(),0.1*-e.getCount());
  adjustView(0,0,-zoomSpeed*e.getCount());
}

void drawCrosshair(float x,float y, float r){
  line(x-r,y,x+r,y);
  line(x,y-r,x,y+r);
}

float viewSpeed = 5;
float zoomSpeed = 0.2;
void adjustView(float xAmount, float yAmount, float scaleAmount){
  float sensitivity = 1.0/scale;
  xPos+=xAmount*sensitivity;
  yPos+=yAmount*sensitivity;
  scale=constrain(scale+scaleAmount*scale,0.1,10);
}