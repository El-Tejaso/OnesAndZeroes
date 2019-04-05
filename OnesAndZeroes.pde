//---------A logic gate simulator---------- //<>// //<>//
//By Tejas Hegde
//To add:
// Cycle detection when loading non-embedded groups
//-----------------------------------------
import java.util.Arrays;

final int TEXTSIZE = 12;

color backgroundCol = color(255);
color foregroundCol = color(0);
color trueCol = color(0,255,0,100);
color trueColOpaque = color(0,255,0);
color falseCol = color(255,0,0,100);
color falseColOpaque = color(255,0,0);
color gateHoverCol = color(0,0,255,100);
color menuHeadingCol = color(0,0,255);
color warningCol = color(255,0,0);
color selOutputCol = color(255,0,255);
color selInputCol = color(0,255,255); //<>// //<>//

boolean contains(LogicGate[] arr, LogicGate lg){
  for(LogicGate l : arr){
    if(l==lg)
      return true;
  }
  return false;
}

//Makes sure that the copied gates aren't connected to the old ones
LogicGate[] CopyPreservingConnections(LogicGate[] gates){
  LogicGate[] newGates = new LogicGate[gates.length];
  
  for(int i = 0; i < gates.length; i++){
    newGates[i] = gates[i].CopySelf();
      //we need to know what their array positions are in order to do the next part
    gates[i].arrayIndex = i;
  }
  
  //make the connections copied -> copied instead of original -> copied
  for(int i = 0; i < gates.length; i++){
    for(int j = 0; j < gates[i].inputs.length; j++){
      InPin input = gates[i].inputs[j];
      //get the output gate from our gates 
      if(!input.IsConnected())
        continue;
      
      //Only carry over connections if they are within the array/group
      if(contains(gates,input.input.Chip())){
        int gateIndex = input.input.Chip().arrayIndex;        
        int outputIndex = input.input.Chip().OutputIndex(input.input);
        InPin copiedInput = newGates[i].inputs[j];
        OutPin copiedOutput = newGates[gateIndex].outputs[outputIndex];
        copiedInput.Connect(copiedOutput);
      }
    }
  }
  
  return newGates;
}



void printPins(Pin[] arr){
  for(int i = 0; i < arr.length; i++){
    println(arr[i].name);
    println(arr[i].WorldY());
  }
}

TextInput pinNameInput;
Pin pinToEditName;
CallbackFunction setNameCallback = new CallbackFunction(){
  @Override
  public void f(){
    SetName();
  }
}; 

void LinkTextField(float x, float y, float h, Pin p, int align){
  pinToEditName = p;
  pinNameInput.Show(x,y,h,align,setNameCallback);
  boolean labelSet = false;
  if((selectedInputs.size()>0)^(selectedOutputs.size()>0)){
    if(selectedInputs.contains(pinToEditName) || selectedOutputs.contains(pinToEditName)){
      pinNameInput.SetLabel("Batch Rename:");
      labelSet = true;
    }
  }
  
  if(!labelSet){
    pinNameInput.SetLabel("New Pin Name:");
  }
}

void SetName(){
  //if either input or output is selected, then do a batch rename
  boolean nameSet = false;
  if((selectedInputs.size()>0)^(selectedOutputs.size()>0)){
    if(selectedInputs.size()>0){
      if(selectedInputs.contains(pinToEditName)){
        for(int i = 0; i < selectedInputs.size(); i++){
          selectedInputs.get(i).SetName(pinNameInput.Text()+i);
        }
        nameSet = true;
      }
    } else if(selectedOutputs.size()>0){
      if(selectedOutputs.contains(pinToEditName)){
        for(int i = 0; i < selectedOutputs.size(); i++){
          selectedOutputs.get(i).SetName(pinNameInput.Text()+i);
        }
        nameSet = true;
      }
    }
  }
  
  if(!nameSet){
    pinToEditName.SetName(pinNameInput.Text());
  }
  pinToEditName = null;
}

void setup(){
  size(800,600);
  surface.setResizable(true);
  //textFont(createFont("Monospaced",TEXTSIZE));
  circuit = new ArrayList<LogicGate>();
  circuitGroups = new ArrayList<LogicGateGroup>();
  deletionQueue = new ArrayList<LogicGate>();
  selection = new ArrayList<LogicGate>();
  
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
  keyMappings.put('l',LKey);
  keyMappings.put('L',LKey);
  keyMappings.put('=',PlusKey);
  keyMappings.put('+',PlusKey);
  keyMappings.put('-',MinusKey);
  keyMappings.put('_',MinusKey);
  
  menus = new ArrayList<UIElement>();
  UIElement logicGateAddMenu = new StringMenu(gateNames, "ADD GATE", new CallbackFunctionInt(){
    @Override
    public void f(int i){
      AddGate(CreateGate(primitiveGates[i]));
    }
  });
  
  logicGateAddMenu.MoveTo(4,0);
  
  menus.add(logicGateAddMenu);
  UIElement inputGateAddMenu = new StringMenu(inputNames, "ADD INPUT GATE", new CallbackFunctionInt(){
    @Override
    public void f(int i){
      AddGate(CreateGate(inputGates[i]));
    }
  });
  menus.add(inputGateAddMenu);
  inputGateAddMenu.MoveTo(logicGateAddMenu.w+10,0);
  
  UIElement outputGateAddMenu = new StringMenu(outputNames, "ADD OUTPUT GATE", new CallbackFunctionInt(){
    @Override
    public void f(int i){
      AddGate(CreateGate(outputGates[i]));
    }
  });
  outputGateAddMenu.MoveTo(inputGateAddMenu.x+inputGateAddMenu.w/2f+10,0);
  menus.add(outputGateAddMenu);
  
  logicGateGroupAddMenu = new StringMenu(new String[]{}, "ADD SAVED", new CallbackFunctionInt(){
    @Override
    public void f(int i){
      AddGateGroup(i);
    }
  });
  
  logicGateGroupAddMenu.MoveTo(outputGateAddMenu.WorldX()+outputGateAddMenu.w/2f+10,0);
  menus.add(logicGateGroupAddMenu);
  UpdateGroups();
  
  fileNameField = new TextInput("Circuit name:");
  fileNameField.text = "unnamed";
  fileNameField.Show(-20,-50,20,RIGHT);
  fileNameField.persistent = true;
  fileNameField.isTyping = false;
  
  menus.add(fileNameField);  
  
  //text("[Shift]+[S] to save \"" + filePath +"\"" ,-20,20);
    //text("[Shift]+[L] to load \"" + filePath +"\"" ,-20,40);
  
  saveButton = new Button("Save", -90,-20, textWidth("Save")+20, TEXTSIZE + 4, gateHoverCol, trueCol,
                  new CallbackFunction(){
                    @Override
                    public void f(){
                      Save();
                    }
                  });
  menus.add(saveButton);
  
  loadButton = new Button("Load", -40,-20, textWidth("Save")+20, TEXTSIZE + 4, gateHoverCol, trueCol,
                  new CallbackFunction(){
                    @Override
                    public void f(){
                      Load();
                    }
                  });
                  
  menus.add(loadButton);
  
  textSize(TEXTSIZE + 4);
  final String noEmbedText = "groups will be saved as filenames pointing to other savefiles";
  final String embedText = "groups will be saved recursively as primitives";
  float textW = textWidth(noEmbedText);
  textSize(TEXTSIZE);
  embedToggle = new Button(embed ? embedText : noEmbedText, -20 - textW/2,-80, textW+20, TEXTSIZE + 4, gateHoverCol, trueCol,
                new CallbackFunction(){
                  @Override
                  public void f(){
                    embed=!embed;
                    embedToggle.title = embed ? embedText : noEmbedText;
                  }
                });
  
  menus.add(embedToggle);
  
  pinNameInput = new TextInput("(New pin name)");
  menus.add(pinNameInput);
  
  cursor.MoveTo(100,-100);
  AddGate(CreateGate(INPUTGATE));
}

Button saveButton;
Button loadButton;
Button embedToggle;
//determines whether or not the file will embed the gates. 
//embedding means that others won't need all of the acompanying gates, but makes it much harder to edit subcomponents
boolean embed = true;
StringMenu logicGateGroupAddMenu;
ArrayList<UIElement> menus;

//moving the screen around
float xPos=0;
float yPos=0;
float scale=1;

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

//Copies the selection
void Duplicate(){
  if(selection.size()==0)
    return;
    
  LogicGate[] newGates = CopyPreservingConnections(selection.toArray(new LogicGate[selection.size()]));
  selection.clear();
  float xMax=newGates[0].x,yMax=newGates[0].y;
  float xMin=newGates[0].x,yMin=newGates[0].y;
  for(LogicGate lg : newGates){
    xMax = max(xMax,lg.x);
    xMin = min(xMin,lg.x);
    yMax = max(yMax,lg.y);
    yMin = min(yMin,lg.y);
  }
  
  for(LogicGate lg : newGates){
    lg.x += xMax-xMin;
    lg.y -= yMax-yMin;
    selection.add(lg);
    circuit.add(lg);      
  }
}
 
final int INPUTGATE = 0;
final int ANDGATE = 1;
final int ORGATE = 2;
final int NOTGATE = 3;
final int NANDGATE = 4;
final int TICKGATE = 5;
final int LCDGATE = 6;
final int PIXELGATE = 7;
final int XORGATE = 8;
final int BASE10GATE = 10;//there used to be 8 and 9
final int BUTTONINGATE = 11;

//used for the menus
String inputNames[] = {"Button"};
int inputGates[] = {   BUTTONINGATE};
String outputNames[] = {"LCD Pixel", "24-bit Pixel","Int32 readout"};
int outputGates[] = {    LCDGATE,     PIXELGATE,     BASE10GATE};
String gateNames[] = {"input / relay point", "And(&)",   "Or(|)",   "Xor(^)",   "Not(!)",   "Nand(!&)",   "Clock"};
int primitiveGates[] = {INPUTGATE,           ANDGATE,   ORGATE,   XORGATE,     NOTGATE,     NANDGATE,   TICKGATE};

LogicGate CreateGate(int g){
  LogicGate lg;
  switch(g){
    case(INPUTGATE): {
      lg = new RelayGate();
      break;
    }
    case(ANDGATE):{
      lg = new AndGate();
      break;
    }
    case(ORGATE):{
      lg = new OrGate();
      break;
    }
    case(XORGATE):{
      lg = new XorGate();
      break;
    }
    case(NOTGATE):{
      lg = new NotGate();
      break;
    }
    case(NANDGATE):{
      lg = new NandGate();
      break;
    }
    case(TICKGATE):{
      lg = new Ticker();
      break;
    }
    case(LCDGATE):{
      lg = new LCDGate(80,80);
      break;
    }
    case(PIXELGATE):{
      lg = new PixelGate(80,80);
      break;
    }
    case (BASE10GATE):{
      lg = new Base10Gate(30);
      break;
    }
    case (BUTTONINGATE):{
      lg = new ButtonGate(80,80);
      break;
    }
    default:{
      lg = new RelayGate();
      break;
    }
  }
  return lg;
}

//This function can add every primitive gate
void AddGate(LogicGate lg){
  lg.x=cursor.WorldX();
  lg.y=cursor.WorldY();
  circuit.add(lg);
}

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
  if(selectedOutputs.size()>0){
    for(int i = 0; i < selectedInputs.size(); i++){
      MakeConnection(selectedOutputs.get(i%selectedOutputs.size()),selectedInputs.get(i));
    }
  } else {
    for(int i = 0; i < selectedInputs.size(); i++){
      MakeConnection(null,selectedInputs.get(i));
    }
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
  abstraction = 0;
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
int abstraction = 0;

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

String[] normalActions = {
  "[RMB]+drag: pan view",
  "[LMB]: move 2D cursor",
  "[LMB]+drag: select things",
  "[Shift]+[LMB]+drag: additively select things"
};

String[] gateActions = {
  "[LMB]: interact",
  "[LMB]+drag: move gate(s)",
  "[RMB] hold: delete gate(s)"
};

String[] nodeActions = {
  "[LMB]+drag to another pin: create a link between two pins"
};

String[] selectedActions = {
  "[Shift]+[D]: duplicate selection"
};

String[] selectedPinActions = {
  "[Shift]+[C]: connect inputs to outputs"
};

String[] selectedInputActions = {
  "[Shift]+[C]: disconnect"
};

float DrawInstructions(String[] actions,float h, float v,float spacing){
    for(int i = actions.length-1; i >= 0; i --){
      String s = actions[i];
      text(s,h,v);
      v+=spacing;
    }
    return v;
}

//will be used by various things for renaming, etc
TextInput fileNameField;  

void DrawAvailableActions(){
  float v = height - 10;
  float h = 0;
  float spacing = -10;
  textAlign(LEFT);
  fill(255,0,0);
  if(selection.size()>0){
    v = DrawInstructions(selectedActions,h,v,spacing);
  }
  fill(0,200,200);
  if((selectedInputs.size()>0)&&(selectedOutputs.size()>0)){
    v = DrawInstructions(selectedPinActions,h,v,spacing);
  } else if(selectedInputs.size()>0){
    v=DrawInstructions(selectedInputActions,h,v,spacing);
  }
  
  fill(foregroundCol);
  if(lastSelectedPin!=null){
    v = DrawInstructions(nodeActions,h,v,spacing);
  } else if(gateUnderMouse!=null){
    fill(255,0,0);
    v = DrawInstructions(gateActions,h,v,spacing);
  } else {
    v = DrawInstructions(normalActions,h,v,spacing);
  }
  textSize(TEXTSIZE+4);
  text("Actions available: ",h,v);
  textSize(TEXTSIZE);
  v+=spacing;
}

boolean prevMouseState=false;
void draw(){
  if(gateUnderMouse!=null){
    cursor(MOVE);
  } else {
    noCursor();
  }
  
  //UI space
  dragStarted = false;
  background(backgroundCol);
  fill(foregroundCol);
  stroke(foregroundCol);
  
  drawCrosshair(mouseX,mouseY,10);
  
  textAlign(LEFT);
  if(numSelected > 0){
    text("Selected gates: "+numSelected+" primitive, "+selection.size()+" groups",0,10);
    text("Abstraction: "+abstraction+" levels deep",0,30);
  }
  if((selectedInputs.size()+selectedOutputs.size())>0){
    text("Selected IO: "+selectedInputs.size()+" input nodes, "+selectedOutputs.size()+" output nodes",0,20);
  }
  
  DrawAvailableActions();
  fill(255,0,0);
  textAlign(RIGHT);
  textSize(16);
  DrawNotifications();
  textSize(TEXTSIZE);
    
  //needs to be manually reset
  mouseOver = false;
  gateUnderMouse = null;
  lastSelectedPin = null;
  
  //World space
  translate(width/2,height/2);
  scale(scale);
  translate(-xPos,-yPos);
  strokeWeight(1/scale);
  drawCrosshair(0,0,30);
  strokeWeight(1);
  
  for(int i = circuit.size()-1; i >=0 ;i--){
    LogicGate lGate = circuit.get(i);
    lGate.Draw();
    lGate.UpdateIOPins();
  }
  
  for(UIElement element : menus){
    element.Draw();
  }
  
  strokeWeight(1/scale);
  cursor.Draw();
  strokeWeight(1);
  
  if(mousePressed){
    if(mouseButton==RIGHT){
      float xAmount = mouseX-pmouseX;
      float yAmount = mouseY-pmouseY;
      adjustView(-xAmount,-yAmount,0);
      
      if(gateUnderMouse!=null){
        IncrementDeleteTimer(gateUnderMouse.x, gateUnderMouse.y,40,gateUnderMouse.h, gateUnderMouse);
      }
    } else {
      boolean mouseJustPressed = false;
      if(prevMouseState != mousePressed){
        mouseJustPressed = true;
      }
      if(mouseJustPressed){
        if(!((draggedElement!=null)||(mouseOver))){
          cursor.Place(MouseXPos(),MouseYPos());
          if(!keyDown(ShiftKey)){
            ClearGateSelection();
            ClearPinSelection();
          }
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
              abstraction = max(abstraction, lgate.Abstraction());
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
  
  for(LogicGate lGate : selection){
    stroke(255,0,0);
    drawCrosshair(lGate.WorldX(),lGate.WorldY(),max(10.0/scale,lGate.w));
  }
  
  stroke(selInputCol);
  fill(selInputCol);
  int i = 0;
  for(InPin p : selectedInputs){
    drawCrosshair(p.WorldX(), p.WorldY(),5);
    text(i,p.WorldX()-5, p.WorldY());
    i++;
  }
  stroke(selOutputCol);
  fill(selOutputCol);
  i = 0;
  for(OutPin p : selectedOutputs){
    drawCrosshair(p.WorldX(), p.WorldY(),5);
    text(i,p.WorldX()+5, p.WorldY());
    i++;
  }
  
  //handle all key shortcuts
  if(!fileNameField.isTyping){
    if(keyDown(ShiftKey)){
      if(keyPushed(DKey)){
        Duplicate();
      } else if(keyPushed(CKey)){
        ConnectSelected();
      }
    }
    textAlign(RIGHT);
    
    if(keyPushed(PlusKey)){
      zoom(1);
    }
    if(keyPushed(MinusKey)){
      zoom(-1);
    }
  }
  
  Cleanup();
  prevMouseState = mousePressed;
}

ArrayList<String> notifications = new ArrayList<String>();
int timer = 0;
void DrawNotifications(){
  if(notifications.size()==0) 
    return;
  
  timer ++;
  if(timer > 240){
    for(int i = 0; i < max(floor(0.7 * notifications.size()),1); i++){
      notifications.remove(i);
    }
    timer = 0;
  }
  
  float h = TEXTSIZE;
  for(int i = notifications.size()-1; i >=0; i--){
    text(notifications.get(i), width, height-h);
    h+=TEXTSIZE;
  }
}

void Save(){
  String filePath = filepath(fileNameField.Text());
  if(!fileNameField.isTyping){
    SaveProject(filePath);
  }
}

void Load(){
  String filePath = filepath(fileNameField.Text());
  if(!fileNameField.isTyping){
    LoadProject(filePath);
  }
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

void zoom(int dir){
  xPos = lerp(xPos,MouseXPos(),0.1*-dir);
  yPos = lerp(yPos,MouseYPos(),0.1*-dir);
  adjustView(0,0,-zoomSpeed*dir);
}

void mouseWheel(MouseEvent e){
  zoom(e.getCount());
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
