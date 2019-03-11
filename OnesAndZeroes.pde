//---------A logic gate simulator----------
//By Tejas Hegde
//-----------------------------------------

//This is to prevent multiple things being dragged at once
UIElement draggedElement = null;

//A rectangular UI element that all classes will derive from 
class UIElement{
  protected UIElement parent;
  public float x,y,w=5,h=5;
  private boolean clicked = false;
  public boolean visible = true;
  protected int dragThreshold = 2;
  
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
  
  //this function is called every frame, and can also be used to start events
  public void Draw(){
    if(!visible)
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
  private LogicGate chip;
  
  public boolean isDeleted(){
    return chip.deleted;
  }
  
  public void Update(){
    chip.Update();
  }
  
  Pin(LogicGate parentChip){
    chip = parentChip;
    dragThreshold = -1;
  }
  
  @Override
  public void OnHover(){
    stroke(foregroundCol);
    rect(WorldX()-w/2+2,WorldY()-w/2+2,w-4,h-4);
    lastSelectedPin = this;
  }
  
  @Override
  public void Draw(){
    stroke(foregroundCol);
    if(IsConnected()){
      if(Value()!=lastValue){
        OnValueChange();
      }
      fill(Value() ? trueCol : falseCol);
      lastValue = Value();
    } else {
      noFill();
    }
    super.Draw();
  }
  
  boolean lastValue = false;
  public boolean Value(){return false;}
  public boolean IsConnected(){return true;}
  public void OnValueChange(){
    chip.Update();
  }
}

//An input pin on a logic gate. Every input can link to at most 1 output pin
class InPin extends Pin{
  private OutPin input;
  
  public InPin(LogicGate p){
    super(p);
    parent = p;
  }
  
  public void Connect(OutPin in){
    input = in;
    Update();
  }

  @Override
  public void OnHover(){
    super.OnHover();
    lastSelectedInput = this;
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
  public void OnValueChange(){
    if(IsConnected()){
      if(input.isDeleted()){
        //We need to remove all references to the deleted chip in order for the garbage collecter to collect it
        Connect(null);
      }
    }
    Update();
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
      NodeConnectionInToOut(this);
    }
  }
}

//This is a pin that outputs a value to an input pin.
class OutPin extends Pin{  
  OutPin(LogicGate p){
    super(p);
    parent = p;
  }
  
  public void SetValue(boolean v){
    if(isDeleted())
      return;
      
    value = v;
  }
  
  @Override
  public boolean Value(){
    return value;
  }

  @Override
  public void OnHover(){
    super.OnHover();
    lastSelectedOutput = this;
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
      NodeConnectionOutToIn(this);
    }
  }
  
  boolean value = false;
}

//The base class for all logic gates. contains most of the functionality
class LogicGate extends UIElement {
  String title = "uninitializedGate";
  public boolean deleted = false;
  InPin[] inputs;
  OutPin[] outputs;
  
  void Decouple(){
    if(inputs!=null){
      for(InPin p : inputs){
        p.Connect(null);
      }
    }
    
    //change their value to trigger an automatic decoupling
    for(OutPin p : outputs){
      p.SetValue(!p.Value());
    }
    
    deleted = true;
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
    fill(outputs[0].Value() ? trueCol : falseCol);
    stroke(foregroundCol);
    super.Draw();
    textAlign(CENTER);
    fill(foregroundCol);
    text(title,WorldX(),WorldY());
    
    stroke(foregroundCol);
    if(inputs!=null){
      for(int i = 0; i < inputs.length; i++){
        inputs[i].Draw();
      }
    }
    
    //All logic gates must have outputs
    for(int i = 0; i < outputs.length; i++){
      outputs[i].Draw();
    }
    
    if(deleteTimer > 0.01f){
      noFill();
      stroke(255,0,0);
      arc(WorldX(),WorldY(),w,w,0,deleteTimer);
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
  protected void Update(){}
}

class BoolGate extends LogicGate{
  public BoolGate(){    
    title = "1";
    w = 30;
    h = 20;
    //just one output that can be toggled
    outputs = new OutPin[1];
    outputs[0] = new OutPin(this);
    outputs[0].SetValue(true);
    outputs[0].MoveTo(w/2+outputs[0].w/2,0);
  }
  
  @Override
  void OnMouseRelease(){
    super.OnMouseRelease();
    if((mouseButton==LEFT)&&(draggedElement!=this)){
      outputs[0].SetValue(!outputs[0].Value());
      title = outputs[0].Value() ? "1" : "0";
    }
  }  
}

//should not be instantiated
class BinaryGate extends LogicGate{
  public BinaryGate(){
    w = 50; 
    h = 30;    
    
    inputs = new InPin[2];
    inputs[0] = new InPin(this);
    inputs[0].MoveTo(-w/2-inputs[0].w/2,inputs[0].h);
    inputs[1] = new InPin(this);
    inputs[1].MoveTo(-w/2-inputs[1].w/2,-inputs[1].h);
    
    outputs = new OutPin[1];
    outputs[0] = new OutPin(this);
    outputs[0].MoveTo(w/2+outputs[0].w/2,0);
  }
}

class AndGate extends BinaryGate{
  public AndGate(){
    super();
    title = "&";
  }
  
  @Override
  protected void Update(){
    outputs[0].SetValue(inputs[0].Value() && inputs[1].Value());
  }
}

class OrGate extends BinaryGate{
  public OrGate(){
    super();
    title = "|";
  }
  
  @Override
  protected void Update(){
    outputs[0].SetValue(inputs[0].Value() || inputs[1].Value());
  }
}

class NotGate extends LogicGate{
  public NotGate(){
    w=20;
    h=20;
    inputs = new InPin[1];
    inputs[0] = new InPin(this);
    inputs[0].MoveTo(-w/2-inputs[0].w/2,0);
    
    title = "!";
    outputs = new OutPin[1];
    outputs[0] = new OutPin(this);
    outputs[0].MoveTo(w/2+outputs[0].w/2,0);
  }
  
  @Override
  protected void Update(){
    outputs[0].SetValue(!inputs[0].Value());
  }
}

class NandGate extends BinaryGate{
  public NandGate(){
    super();
    title = "!&";
  }
  
  @Override
  protected void Update(){
    outputs[0].SetValue(!(inputs[0].Value() && inputs[1].Value()));
  }
}

//someday lmao
/*
class CompositeLogicGate extends LogicGate {
  LogicGate[] gates;
  public CompositeLogicGate(String script){
    
  }
}
*/

//----------------- CUSTOM UI ELEMENTS ----------------
//used by other ui elements
class CallbackFunctionInt {
  public void f(int i){}
}

class StringMenu extends UIElement{
  String[] elements;
  float elementHeight = 11;
  float padding = 2;
  String heading;
  CallbackFunctionInt f;
  
  public StringMenu(String[] arr, String title, CallbackFunctionInt intFunction){
    heading = title;
    elements = arr;
    f = intFunction;
    
    //setup the dimensions
    int max = heading.length();
    for(String s : elements){
      if(s.length() > max){
        max = s.length();
      }
    }
    
    w = max * 5 + 20 + 2 * padding;
    h = (elements.length+1) * (elementHeight+padding) + padding;
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
  
  boolean listClicked = false;
  
  @Override
  public void Draw(){
    noFill();
    stroke(foregroundCol);
    super.Draw();
    fill(menuHeadingCol);
    textAlign(CENTER);
    text(heading,WorldX(),WorldY()-h/2+elementHeight);
    for(int i = 0; i < elements.length;i++){
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
    for(int i = 0; i < elements.length;i++){
      float x1 = WorldX();
      float y1 = WorldY()+ (i+1)*(elementHeight+padding)-h/2+elementHeight-padding;      
      text(elements[i],x1,y1,10);
    }
  }
}

//INPUT SYSTEM copy pasted from another personal project
//not used by the input system, but by us to do stuff only once
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
//related to the dragging of buttons
boolean dragStarted = false;

boolean displayAddGatesMenu = false;
float menuX=-9999999999.0, menuY;

String gateNames[] = {"1/0 Out","And", "Or", "Not", "Nand"};

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
    default:{
      lg = new BoolGate();
      break;
    }
  }
  lg.x=lg.w;
  lg.y=-lg.h;
  circuit.add(lg);
}

Pin lastSelectedPin;
OutPin lastSelectedOutput = null;
InPin lastSelectedInput = null;

void ClearSelection(){
  lastSelectedPin = null;
  lastSelectedOutput = null;
  lastSelectedInput = null;
}

void NodeConnectionInToOut(InPin in){
  stroke(gateHoverCol);
  line(in.WorldX(), in.WorldY(), MouseXPos(), MouseYPos());
  if(lastSelectedOutput!=null){
    in.Connect(lastSelectedOutput);
  }
}

void NodeConnectionOutToIn(OutPin out){
  stroke(gateHoverCol);
  line(out.WorldX(), out.WorldY(), MouseXPos(), MouseYPos());
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
  /*
  text(mouseXPos(),mouseX+30,mouseY);
  text(-mouseYPos(),mouseX,mouseY-30);
  text(nf(scale,0,2)+"x",mouseX-30,mouseY+30);
  */
  
  //World space
  translate(width/2,height/2);
  scale(scale);
  translate(-xPos,-yPos);
  drawCrosshair(0,0,30,foregroundCol);
  textAlign(RIGHT);
  text("0,0", -12,12);
  
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