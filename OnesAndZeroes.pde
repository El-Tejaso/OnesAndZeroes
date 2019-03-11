//---------A logic gate simulator----------
//By Tejas Hegde
//-----------------------------------------


//A rectangular UI element that all classes will derive from 
class UIElement{
  protected UIElement parent;
  public float x,y,w=10,h=10;
  private boolean beingDragged = false;
  private boolean clicked = false;
  public boolean visible = true;
  
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
      if(mousePressed&&(mouseButton==LEFT)){
        if(!clicked){
          OnMouseClick();
          clicked=true;
        } else {
          OnMouseDown();
        }
        
        if(abs(mouseX-pmouseX)+abs(mouseY-pmouseY)>2)
            beingDragged = true;
      } else if(clicked) {
        clicked = false;
        if(!beingDragged){
          OnMouseRelease();
        }
        beingDragged = false;
      }
    } else {
      clicked = false;
      if((!mousePressed)||(mouseButton!=LEFT))
        beingDragged = false;
    }
    
    if(beingDragged){
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
}

//An input pin on a logic gate. Every input can link to at most 1 output pin
class InPin extends UIElement{
  private OutPin input;
  
  public InPin(LogicGate p){
    parent = p;
    w = 10;
    h = 10;
  }
  
  @Override
  public void Draw(){
    if(IsConnected()){
      fill(Value() ? trueCol : falseCol);
    } else {
      noFill();
    }
    super.Draw();
  }
  
  public void Connect(OutPin in){
    input = in;
  }

  public boolean IsConnected(){
    return (input!=null);
  }

  public boolean Value(){
    if(input!=null){
      return input.Value();
    } else {
      return false;
    }
  }
}

//This is a pin that outputs a value to an input pin.
class OutPin extends UIElement{
  OutPin(LogicGate p){
    parent = p;
  }
  
  public void SetValue(boolean v){
    value = v;
  }
  
  public boolean Value(){
    return value;
  }
  
  @Override
  public void Draw(){
    fill(Value() ? trueCol : falseCol);
    super.Draw();
  }
  
  boolean value = false;
}

//The base class for all logic gates. contains most of the functionality
class LogicGate extends UIElement {
  String title = "uninitializedGate";
  
  InPin[] inputs;
  OutPin[] outputs;
  
  public void OnClick(){}
  
  public void OnClickHold(){
    //drag functionality
    if(dragStarted)
      return;
      
    dragStarted = true;
    x+= toWorldX(mouseX)-toWorldX(pmouseX);
    y+= toWorldY(mouseY)-toWorldY(pmouseY);
  }
  
  public void OnHover(){
    fill(gateHoverCol);
  }
  
  public void Draw(){
    fill(outputs[0].Value() ? trueCol : falseCol);
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
  void OnClick(){
    outputs[0].SetValue(!outputs[0].Value());
    title = outputs[0].Value() ? "1" : "0";
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
    title = "&&";
  }
  
  @Override
  protected void Update(){
    outputs[0].SetValue(inputs[0].Value() && inputs[1].Value());
  }
}

class OrGate extends BinaryGate{
  public OrGate(){
    super();
    title = "||";
  }
  
  @Override
  protected void Update(){
    outputs[0].SetValue(inputs[0].Value() || inputs[1].Value());
  }
}

class NotGate extends LogicGate{
  public NotGate(){
    inputs = new InPin[1];
    inputs[0] = new InPin(this);
    
    title = "!";
    outputs = new OutPin[1];
    outputs[0] = new OutPin(this);
  }
  
  @Override
  protected void Update(){
    outputs[0].SetValue(!inputs[0].Value());
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

class StringMenu extends UIElement{
  String[] elements;
  public StringMenu(String[] arr){
    elements = arr;
    int max = 0;
    for(String s : elements){
      if(s.length() > max){
        max = s.length();
      }
    }
    
    w = max * 3 + 20;
    h = elements.length * 15;
  }
  
  @Override
  public void OnHover(){
    
  }
  
  @Override
  public void OnMouseRelease(){
    
  }
  
  @Override
  public void OnDrag(){
    
  }
  
  @Override
  public void Draw(){
    super.Draw();
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
  
  circuit = new ArrayList<LogicGate>();
  circuit.add(new BoolGate());
  
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
}
//moving the screen around
float xPos=0;
float yPos=0;
float scale=1;

color backgroundCol = color(255);
color foregroundCol = color(0);
color trueCol = color(0,255,0,100);
color falseCol = color(255,0,0,100);
color gateHoverCol = color(0,0,255,100);

float toWorldX(float screenX){
  return ((screenX-width/2)/scale)+xPos;
}

float mouseXPos(){
  return toWorldX(mouseX);
}

float toWorldY(float screenY){
  return ((screenY-height/2)/scale)+yPos;
}

float mouseYPos(){
  return toWorldY(mouseY);
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
  return pointInside(toWorldX(mouseX), toWorldY(mouseY), x, y,w,h);
}

ArrayList<LogicGate> circuit;
//related to the dragging of buttons
boolean dragStarted = false;

boolean displayAddGatesMenu = false;
float menuX=-9999999999.0, menuY;

String gateNames[] = {"0/1 Out","And", "Or", "Not"};

void addGatesMenu(float x, float y){
  if(menuX<-999999){
    menuX=x;
    menuY=y;
  }
  
  int result = -1;
  for(int i = 0; i < gateNames.length;i++){
    if(result < 0){
      float w = 40;
      float h = 20;
    }
  }
  
  if(result == -1)
    return;
  
  LogicGate lg;
  switch(result){
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
    default:{
      lg = new BoolGate();
      break;
    }
  }
  
  lg.x = mouseXPos();
  lg.y = mouseYPos();
  circuit.add(lg);
  
  displayAddGatesMenu = false;
  menuX = -99999999999.0;
}

OutPin outputToLink;
InPin inputToLink;

void draw(){
  //UI space
  dragStarted = false;
  background(backgroundCol);
  fill(foregroundCol);
  drawCrosshair(mouseX,mouseY,10,foregroundCol);
  text(mouseXPos(),mouseX+30,mouseY);
  text(-mouseYPos(),mouseX,mouseY-30);
  text(nf(scale,0,2)+"x",mouseX-30,mouseY+30);
  
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
  
  if(keyPushed(AKey)&&keyDown(ShiftKey)){
    displayAddGatesMenu = true;
  }
  
  if(displayAddGatesMenu){
    addGatesMenu(mouseXPos(),mouseYPos());
  }
  
  noFill();
  for(LogicGate lGate : circuit){
    lGate.Draw();
  }
  
  if(inputToLink!=null){
    drawCrosshair(inputToLink.x,inputToLink.y,10,color(255,0,0));
  }
  
  if(outputToLink!=null){
    drawCrosshair(outputToLink.x,outputToLink.y,10,color(255,0,0));
  }
}

void mouseWheel(MouseEvent e){
  xPos = lerp(xPos,mouseXPos(),0.1*-e.getCount());
  yPos = lerp(yPos,mouseYPos(),0.1*-e.getCount());
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