class InPin{
  float x,y;
  private LogicGate parent;
  LogicGate getParent(){
    return parent;
  }
  
  InPin(LogicGate p){
    parent = p;
  }
  
  private OutPin input;
  
  public void connect(OutPin in){
    input = in;
  }
  
  public boolean get(){
    if(input!=null){
      return input.output;
    } else {
      return false;
    }
  }
}

class OutPin{
  float x,y;
  private LogicGate parent;
  public LogicGate getParent(){
    return parent;
  }
  
  OutPin(LogicGate p){
    parent = p;
  }
  
  public void connect(InPin outputPin){
    out = outputPin;
    if(out!=null){
      out.connect(this);
      out.parent.Update();
    }
  }
  
  public void set(boolean val){
    if(val==output)
      return;
    
    output = val;
    if(out!=null){
      out.parent.Update();
    }
  }
  
  public boolean get(){
    return output;
  }
  
  public InPin getOut(){
    return out;
  }
  
  private InPin out;
  private boolean output;
}

//base class
class LogicGate{
  public float x = 0;
  public float y = 0;
  String title = "uninitializedGate";
  
  InPin[] inputs;
  OutPin[] outputs;
  private boolean clicked = false;
  private boolean ioInputHandled=false;
  private boolean beingDragged = false;
  
  public void OnClick(){}
  
  public void OnClickHold(){
    //drag functionality
    if(dragStarted)
      return;
      
    dragStarted = true;
    x+= toWorldX(mouseX)-toWorldX(pmouseX);
    y+= toWorldY(mouseY)-toWorldY(pmouseY);
  }
  public void OnHover(){}
  
  public void Draw(){
    fill(outputs[0].output ? trueCol : falseCol);
    
    float w = 10 + title.length()*10;
    float ioNodeWidth = 10;
    float h;
    if(inputs==null){
      h = 20+ (ioNodeWidth+4)*outputs.length;
    } else {
      h = 20 + (ioNodeWidth+4)*max(inputs.length,outputs.length);
    }
    
    float x1 = x-w/2;
    float y1 = y-h/2;
    
    //noFill();
    //handle mouse clicks in an override if we aren't clicking an in/output
    if(mousePressed&&(mouseButton==LEFT)){
      if(mouseInside(x1,y1,w,h)){
        OnHover();
        if(!clicked){
          clicked=true;
        } else {
          if(abs(mouseX-pmouseX)+abs(mouseY-pmouseY)>2)
            beingDragged = true;
        }
      } else {
      }
    } else {
      if(clicked){
        if(mouseInside(x1,y1,w,h)){
          if(!beingDragged)
            OnClick();
        }
        clicked = false;
      }
      beingDragged = false;
    }
    
    if(beingDragged){
      OnClickHold();
    }
    
    stroke(foregroundCol);
    //let overrides determine the fill color of the rect
    rect(x1,y1,w,h);
    textAlign(CENTER);
    fill(foregroundCol);
    text(title,x1+w/2,y1+h/2);
    //output connections
    
    if(inputs!=null){
      for(int i = 0; i < inputs.length;i++){
        float x2 = x1-ioNodeWidth-3;
        float y2 = y1+i*h/(float)(inputs.length+1);
        inputs[i].x=x2+ioNodeWidth/2;
        inputs[i].y=y2+ioNodeWidth/2;
        
        if(button(x2,y2,ioNodeWidth,ioNodeWidth,"")){
          if(!ioInputHandled){
            ioInputHandled = true;
            pushInput(inputs[i]);
          }
        } else {
          ioInputHandled = false;
        }
        
        if(inputs[i].get()){
          fill(trueCol);
        } else {
          fill(falseCol);
        }
        
        rect(x2,y2,ioNodeWidth,ioNodeWidth);
      }
    }
    
    for(int i = 0; i < outputs.length;i++){
      float x2 = x1+w+3;
      float y2 = y1+(i+1)*h/(float)(outputs.length+1)-ioNodeWidth/2;
      outputs[i].x=x2+ioNodeWidth/2;
      outputs[i].y=y2+ioNodeWidth/2;
      
      if(button(x2,y2,ioNodeWidth,ioNodeWidth,"")){
        if(!ioInputHandled){
          ioInputHandled = true;
          pushOutput(outputs[i]);
        }
      } else {
        ioInputHandled = false;
      }
      
      if(outputs[i].output){
        fill(trueCol);
      } else {
        fill(falseCol);
      }
      rect(x2,y2,ioNodeWidth,ioNodeWidth);
      
      fill(0,0,255);
      if(outputs[i].getOut()!=null){
        line(outputs[i].x,outputs[i].y, outputs[i].getOut().x, outputs[i].getOut().y);
      }
    }
  }
  //will involve setting outputs in overrides, which should cause a cascading change
  protected void Update(){}
}

class BoolGate extends LogicGate{
  public BoolGate(){    
    title = "1";
    //no inputs, these are the inputs
    outputs = new OutPin[1];
    outputs[0] = new OutPin(this);
    outputs[0].set(true);
  }
  
  @Override
  void OnClick(){
    outputs[0].set(!outputs[0].get());
    title = outputs[0].get() ? "1" : "0";
  }  
}

class AndGate extends LogicGate{
  public AndGate(){
    inputs = new InPin[2];
    inputs[0] = new InPin(this);
    inputs[1] = new InPin(this);
    title = "&&";
    
    outputs = new OutPin[1];
    outputs[0] = new OutPin(this);
  }
  
  @Override
  protected void Update(){
    outputs[0].set(inputs[0].get() && inputs[1].get());
  }
}

class OrGate extends LogicGate{
  public OrGate(){
    inputs = new InPin[2];
    inputs[0] = new InPin(this);
    inputs[1] = new InPin(this);
    title = "||";
    
    outputs = new OutPin[1];
    outputs[0] = new OutPin(this);
  }
  
  @Override
  protected void Update(){
    outputs[0].set(inputs[0].get() || inputs[1].get());
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
    outputs[0].set(!inputs[0].get());
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

//INPUT SYSTEM copy pasted from another project
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
color gateCol = color(0,0,255,100);

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

boolean button(float x, float y, float w, float h, String text){
  boolean res = false;
  if(mouseInside(x,y,w,h)){
    if(mousePressed){
      if(mouseButton==LEFT){
        noFill();
        res = true;
      }
    } else {
      fill(gateCol);
    }
  } else {
    noFill();
  }
  rect(x,y,w,h);
  fill(foregroundCol);
  textAlign(CENTER);
  text(text,x+w/2,y+h/2);
  return res;
}

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
      if(button(menuX,i*h+menuY,w,h,gateNames[i])){
        result = i;
        break;
      }
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

void pushInput(InPin in){
  if(in==null){
    outputToLink = null;
    inputToLink = null;
    return;
  }
    
  inputToLink = in;
  if(outputToLink!=null){
    outputToLink.connect(inputToLink);
    outputToLink = null;
    inputToLink = null;
  }
}

void pushOutput(OutPin out){
  if(out==null){
    outputToLink = null;
    inputToLink = null;
    return;
  }
  
  outputToLink = out;
  if(inputToLink!=null){
    outputToLink.connect(inputToLink);
    outputToLink = null;
    inputToLink = null;
  }
}

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