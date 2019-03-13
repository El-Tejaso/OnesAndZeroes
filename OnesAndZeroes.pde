//---------A logic gate simulator----------
//By Tejas Hegde
//To add:
//-Load/save circuits
//-Composite circuits --first priority
//-----------------------------------------

//This is to prevent multiple things being dragged at once
UIElement draggedElement = null; 

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
      if(mousePressed){
        if(!clicked){
          OnMouseClick();
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
        OnMouseRelease();
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
  
  public void OnMouseClick(){}
  
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
    if(!mousePressed){
      lastSelectedInput = this;
    }
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
    if(input!=null){
      if(input.IsDeleted()){
        //We need to remove all references to the deleted chip in order for the garbage collecter to collect it
        Connect(null);
        print("yeet");
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
    ClearSelection();
    Connect(null);
  }
  
  @Override
  public void OnDrag(){
    if(mouseButton==LEFT){
      NodeConnectionInToOut(this,false);
    }
  }
  
  @Override
  public void OnMouseRelease(){
    if(mouseButton==LEFT){
      NodeConnectionInToOut(this,true);
    }
  }
}

//This is a pin that outputs a value to an input pin.
class OutPin extends Pin{  
  int index;
  int getIndex(){return index;}
  
  OutPin(LogicGate p, int i){
    super(p);
    index = i;
  }
  
  public void SetValue(boolean v){
    if(IsDeleted())
      return;
      
    value = v;
  }
  
  public long getChipID(){
    return chip.getID();
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
    ClearSelection();
  }
  
  @Override
  public void OnDrag(){
    if(mouseButton==LEFT){
      NodeConnectionOutToIn(this,false);
    }
  }
  
  @Override
  public void OnMouseRelease(){
    if(mouseButton==LEFT){
      NodeConnectionOutToIn(this,true);
    }
  }
  
  boolean value = false;
}

//a different number for each logic gate
//does not need to be saved for each gate
long logicGateID = 0;

//The base class for all logic gates. contains most of the functionality
class LogicGate extends UIElement implements Comparable<LogicGate>{
  String title = "uninitializedGate";
  public boolean deleted = false;
  protected boolean showText = true;
  private long id;
  protected int level = 0;
  InPin[] inputs;
  OutPin[] outputs;
  
  int compareTo(LogicGate lg){
    return Integer.compare(level,lg.level);
  }
  
  LogicGate(){
    id = logicGateID;
    logicGateID++;
  }
  
  public int getNumGates(){
    return 1;
  }
  
  public int getNumGates(String type){
    if(title==type)
      return 1;
    return 0;
  }
  
  //returns the memory address of this object as an unsigned integer
  long getID(){
    return id;
  }
  
  int getOutputIndex(OutPin output){
    for(int i = 0; i < outputs.length; i++){
      if(outputs[i]==output){
        return i;
      }
    }
    return -1;
  }
  
  void Decouple(){
    if(inputs!=null){
      for(InPin p : inputs){
        p.Connect(null);
      }
    }
  }
  
  @Override
  public void OnDrag(){
    if(mouseButton==LEFT){
      //drag functionality
      if(dragStarted)
        return;
        
      dragStarted = true;
      x+= ToWorldX(mouseX)-ToWorldX(pmouseX);
      y+= ToWorldY(mouseY)-ToWorldY(pmouseY);
    }
  }
  
  @Override
  public void OnHover(){
    fill(gateHoverCol);
    cursorOverDragableObject = true;
  }
  
  @Override
  public void Draw(){
    if(outputs!=null){
      fill(outputs[0].Value() ? trueCol : falseCol);
    }
    stroke(foregroundCol);
    super.Draw();
    if(showText){
      textAlign(CENTER);
      fill(foregroundCol);
      text(title,WorldX(),WorldY());
    }
    
    stroke(foregroundCol);
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
    
    if(deleteTimer > 0.01f){
      noFill();
      stroke(warningCol);
      arc(WorldX(),WorldY(),2*w,2*w,0,deleteTimer);
      fill(255,0,0);
      text("deleting...",WorldX(),WorldY()+h+10);
    }
  }
  
  float deleteTimer = 0;
  @Override
  void OnMouseDown(){
    if(mouseButton==RIGHT){
      deleteTimer += TWO_PI/60.0;
      if(deleteTimer > TWO_PI){
        DeleteGate(this);
      }
    }
  }
  
  @Override
  void OnMouseRelease(){
    deleteTimer = 0;
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
class BinaryGate extends LogicGate{
  public BinaryGate(){
    super();
    w = 50; 
    h = 30;    
    
    inputs = new InPin[2];
    inputs[0] = new InPin(this);
    inputs[0].MoveTo(-w/2-inputs[0].w/2,inputs[0].h);
    inputs[1] = new InPin(this);
    inputs[1].MoveTo(-w/2-inputs[1].w/2,-inputs[1].h);
    
    outputs = new OutPin[1];
    outputs[0] = new OutPin(this,0);
    outputs[0].MoveTo(w/2+outputs[0].w/2,0);
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

//*/
//UNFINISHED

class LogicGateGroup extends LogicGate{
  LogicGate[] gates;
  boolean expose = true;
  int numGates;
  LogicGateGroup(LogicGate[] gateArray){
    gates = gateArray;
    title = "LG";
    
    showText = false;
    float minX=0;
    float maxX=1;
    float minY=0; 
    float maxY=1;
    int maxAbstraction = 0; 
    for(LogicGate lg : gates){
      lg.acceptUIInput = false;
      lg.parent = this;
      minX=min(lg.x-lg.w, minX);
      maxX = max(lg.x+lg.w, maxX);
      minY=min(lg.y-lg.h,minY);
      maxY=max(lg.y+lg.h,maxY);
      maxAbstraction = max(lg.level, maxAbstraction);
      numGates += lg.getNumGates();
    }
    x = (minX+maxX)/2.0;
    y = (minY+maxY)/2.0;
    w = maxX-minX;
    h = maxY-minY;
    level = maxAbstraction+1;
  }
  
  @Override
  public void Draw(){
    super.Draw();
    if(expose){
      for(LogicGate lg : gates){
        lg.Draw();
      }
    }
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
boolean[] keyJustPressed = new boolean[21];
boolean[] keyStates = new boolean[21];
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
  AddGate(0);
  
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

void DeleteGate(LogicGate lg){
  deletionQueue.add(lg);
  lg.Decouple();
}

ArrayList<LogicGate> deletionQueue;

void Cleanup(){
  if(deletionQueue.size()>0){
    for(LogicGate lg : deletionQueue){
      circuit.remove(lg);
    }
    deletionQueue.clear();
  }
}

String gateNames[] = {"input / relay point","And", "Or", "Not", "Nand"};

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
  lg.x=lg.w;
  lg.y=-lg.h;
  circuit.add(lg);
}

String outputNames[] = {"LCD Pixel", "24-bit Pixel", "LCD Pixel large", "LCD 24-bit Pixel large"};

Pin lastSelectedPin;
OutPin lastSelectedOutput = null;
InPin lastSelectedInput = null;

void ClearSelection(){
  lastSelectedPin = null;
  lastSelectedOutput = null;
  lastSelectedInput = null;
}

void NodeConnectionInToOut(InPin in,boolean connect){
  stroke(gateHoverCol);
  line(in.WorldX(), in.WorldY(), MouseXPos(), MouseYPos());
  if(!connect)
    return;
  if(lastSelectedOutput!=null){
    in.Connect(lastSelectedOutput);
  }
}

void NodeConnectionOutToIn(OutPin out,boolean connect){
  stroke(gateHoverCol);
  line(out.WorldX(), out.WorldY(), MouseXPos(), MouseYPos());
  if(!connect)
    return;
  if(lastSelectedInput!=null){
    lastSelectedInput.Connect(out);
  }
}

boolean cursorOverDragableObject = false;

void draw(){
  if(cursorOverDragableObject){
    cursor(MOVE);
  } else {
    noCursor();
  }
  
  //UI space
  dragStarted = false;
  background(backgroundCol);
  fill(foregroundCol);
  drawCrosshair(mouseX,mouseY,10,foregroundCol);
  
  //World space
  translate(width/2,height/2);
  scale(scale);
  translate(-xPos,-yPos);
  drawCrosshair(0,0,30,foregroundCol);
  textAlign(RIGHT);
  text("0,0", -12,12);
  /*
  3DCursor.Draw();
  */
  
  if(mousePressed){
    if(mouseButton==RIGHT){
      float xAmount = mouseX-pmouseX;
      float yAmount = mouseY-pmouseY;
      adjustView(-xAmount,-yAmount,0);
    } else {
      //drag the logic gates around or open up some sort of menu
    }
  }
  
  cursorOverDragableObject=false;
  for(LogicGate lGate : circuit){
    lGate.Draw();
    lGate.UpdateIOPins();
  }
  
  for(UIElement element : menus){
    element.Draw();
  }
  
  Cleanup();
}

void mouseWheel(MouseEvent e){
  xPos = lerp(xPos,MouseXPos(),0.1*-e.getCount());
  yPos = lerp(yPos,MouseYPos(),0.1*-e.getCount());
  adjustView(0,0,-zoomSpeed*e.getCount());
}

void drawCrosshair(float x,float y, float r, color col){
  stroke(col);
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