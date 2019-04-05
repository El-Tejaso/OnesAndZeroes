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
color selInputCol = color(0,255,255);

//Putting these here cause you cant make static vars in processing
//This is to prevent multiple things being dragged at once
UIElement draggedElement = null; 
boolean mouseOver = false;
//A rectangular UI element that all classes will derive from 
class UIElement{
  protected UIElement parent;
  public float x,y,w=5,h=5;
  private boolean clicked = false;
  protected int dragThreshold = 0;
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

class Pin extends UIElement implements Comparable<Pin>{
  protected LogicGate chip;
  protected LogicGate abstractedChip;
  protected String name = "pin of some sort";
  int align = CENTER;
  
  public String Name(){
    return name;
  }
  
  public void SetName(String val){
    name = val;
    nameChanged = true;
    abstractedChip.UpdateDimensions();
  }
  
  protected boolean nameChanged = false;
  public boolean NameChanged(){return nameChanged;}
  
  public void UpdateDimensions(){
    abstractedChip.UpdateDimensions();
  }
  
  @Override
  public int compareTo(Pin other){
    return Float.compare(WorldY(), other.WorldY());
  }
  
  public float NameWidth(){
    textSize(h);
    float wid = textWidth(name);
    textSize(TEXTSIZE);
    return wid;
  }
  
  //returns the chip that the pin is logically connected to 
  public LogicGate ActualChip(){
    return chip;
  }
  
  //returns the chip/group that it is visually connected to
  public LogicGate Chip(){
    return abstractedChip;
  }
  
  public void SetParent(LogicGate p){
    parent = p;
    abstractedChip = p;
  }
  
  public boolean IsDeleted(){
    return chip.deleted;
  }
  
  Pin(LogicGate parentChip){
    chip = parentChip;
    parent = parentChip;
    abstractedChip = parentChip;
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
  
  void nameUI(int al){
    fill(foregroundCol);
    textAlign(al);
    textSize(h);
    float x1;
    float y1 = WorldY()-h/2;
    float textW = textWidth(name);
    if(al==LEFT){
      x1 = WorldX()+w;
    } else if(al==RIGHT){
      x1 = WorldX()-w-textW;
    } else {
      x1 = WorldX();
    }
    
    int sign = (al == LEFT ? 1 :  (al == RIGHT ? -1 : 0));
    text(name,WorldX()+sign*w,WorldY()+h/4);
    
    textSize(TEXTSIZE);
    
    if(mouseInside(x1,y1,textW,h)){
      noFill();
      rect(x1,y1,textW,h);
      if(mousePressed){
        LinkTextField(WorldX()+sign*w, WorldY(),h, this,al);
      }
    }
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
  
  public void OnValueChange(){}
}

//An input pin on a logic gate. Every input can link to at most 1 output pin
class InPin extends Pin{
  private OutPin input;
  
  public InPin(LogicGate p){
    super(p);
    name = "i";
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
    nameUI(LEFT);
  }
  
  public void DrawLink(){
    if(IsConnected()){
      stroke(input.Value() ? trueColOpaque : falseColOpaque);
      float hMid = (WorldX() + 2*input.WorldX())/3;
      line(WorldX()+w/2,WorldY(),hMid,WorldY());
      line(hMid, WorldY(), hMid, input.WorldY());
      line(hMid, input.WorldY(),input.WorldX()-input.w/2, input.WorldY());
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
  
  @Override
  public void OnValueChange(){
    chip.UpdateLogic();
  }
}

//This is a pin that outputs a value to an input pin.
class OutPin extends Pin{    
  OutPin(LogicGate p){
    super(p);
    name = "o";
  }
  
  public void SetValue(boolean v){
    if(IsDeleted())
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
    if(!mousePressed){
      lastSelectedOutput = this;
    }
  }

  @Override
  public void Draw(){
    fill(Value() ? trueCol : falseCol);
    super.Draw();
    nameUI(RIGHT);
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
  String title = "?";
  public boolean deleted = false;
  protected boolean showText = true;
  boolean drawPins = true;
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
  
  public void UpdateDimensions(){ //<>//
    if(inputs.length==0)
      return;
    
    float maxInputWidth = 3;
    if(inputs.length>0){
      inputs[0].NameWidth();
    }
    
    for(Pin p : inputs){
      maxInputWidth = max(maxInputWidth,p.NameWidth());
    }
    float maxOutputWidth = 1;
    if(outputs!=null){
      if(outputs.length>0){
        maxOutputWidth = outputs[0].NameWidth();
        for(Pin p : outputs){
          maxOutputWidth = max(maxOutputWidth,p.NameWidth());
        }
        h = 2*max(inputs[0].h*inputs.length,outputs[0].h*outputs.length);
      }
    } else {
      h = inputs[0].h*inputs.length;
    }
    
    w = textWidth(title) + 5 + maxInputWidth + maxOutputWidth;
    
    ArrangeInputs();
    ArrangeOutputs();
  }
  
  int compareTo(LogicGate lg){
    return Integer.compare(level,lg.level);
  }
    
  public int NumGates(){
    return 1;
  }
  
  public int NumGates(String type){
    if(title==type)
      return 1;
    return 0;
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
  public abstract int PartID();
  
  //the embed property is used further down the line
  public String PartIDString(boolean embed){
    return nf(PartID(),0,0);
  }
  
  public String GetParts(boolean embed){
    //looks like: (partID,x,y,|I|inputName, inputname2, |O|outputname,value,name,value)
    String part = PartIDString(embed);
    String s = "("+ part + "," + str(x) + "," + str(y)+","; 
    s+="|I|";//have input metadata
    for(int i = 0; i < inputs.length;i++){
      //this way, the names are only saved once, where they are necessary
      if(inputs[i].Chip()==this){
        s+= inputs[i].Name();
      }
      s+= ",";
    }
    s+="|O|";//have output metadata
    if(outputs!=null){
      for(int i = 0; i < outputs.length;i++){
        s+= outputs[i].Name() + "," + (outputs[i].Value() ? "1" : "0") + ",";
      }
    }
    s+=")";
    return s;
  }
  
  //only works if the array it's supposed to be a part of has been indexed properly
  public String GetInputs(){
    //will look like: <thisGate>[gateindex,outputIndex][null][null], <anotherGate>[so on so forth]
    String s = "<"+arrayIndex+">";
    for(int i = 0; i < inputs.length; i++){
      s+="[";
      if(inputs[i].IsConnected()){
        OutPin out = inputs[i].input;
        //the indexing thing only works if the chip of the incoming output is in the same group
        if(out.Chip().parent==parent){
          s+= out.Chip().arrayIndex;
          s+=",";
          s+= out.Chip().OutputIndex(out);
        }
      }
      s+="]";
    }
    return s;
  }
  
  //won't work if the gates are of different kinds
  public void CopyValues(LogicGate other){
    x = other.x;
    y = other.y;
    parent = other.parent;
    for(int i = 0; i < inputs.length; i++){
      inputs[i].Connect(other.inputs[i].input);
      inputs[i].name = other.inputs[i].name;
    }
    
    if(outputs!=null){
      for(int i = 0; i < outputs.length; i++){
        outputs[i].SetValue(other.outputs[i].Value());
        outputs[i].name = other.outputs[i].name;
      }
    }
  }
  
  @Override 
  public void OnDragStart(){
    if(!selection.contains(this)){
      ClearGateSelection();
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
    stroke(foregroundCol);
    if(draggedElement != this){
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
    noFill();
    super.Draw();
    
    for(int i = 0; i < inputs.length; i++){
      inputs[i].DrawLink();
    }
    
    if(showText){
      textAlign(CENTER);
      fill(foregroundCol);
      text(title,WorldX(),WorldY()+TEXTSIZE/4.0);
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
    inputs[0].name = "a";
    inputs[1].name = "b";
    
    outputs = new OutPin[1];
    outputs[0] = new OutPin(this);
    outputs[0].name = "out"; //<>//
  }
}

class AndGate extends BinaryGate{
  public AndGate(){
    super();
    title = "&";
    UpdateDimensions();
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
  
  @Override
  public int PartID(){
    return ANDGATE;
  }
}

class OrGate extends BinaryGate{
  public OrGate(){
    super();
    title = "|";
    UpdateDimensions();
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
  
  @Override
  public int PartID(){
    return ORGATE;
  }
}

class XorGate extends BinaryGate{
  public XorGate(){
    super();
    title = "^";
    UpdateDimensions();
  }
  
  @Override
  protected void UpdateLogic(){
    outputs[0].SetValue(inputs[0].Value() ^ inputs[1].Value());
  }
  
  @Override
  public LogicGate CopySelf(){
    LogicGate lg = new XorGate();
    lg.CopyValues(this);
    return lg;
  }
  
  @Override
  public int PartID(){
    return XORGATE;
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
    outputs[0] = new OutPin(this);
    outputs[0].MoveTo(w/2+outputs[0].w/2,0);
    UpdateDimensions();
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
  
  @Override
  public int PartID(){
    return NOTGATE;
  }
}

class NandGate extends BinaryGate{
  public NandGate(){
    super();
    title = "!&";
    UpdateDimensions();
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
  
  @Override
  public int PartID(){
    return NANDGATE;
  }
}

class Ticker extends LogicGate{
  public Ticker(){
    super();
    title = "t:N/A";
    showText = false;
    inputs = new InPin[16];
    w = 50;
    h = 50;
    for(int i = 0; i < inputs.length; i++){
      inputs[i]=new InPin(this);
      inputs[i].w = w/16.0;
      inputs[i].h = inputs[i].w;
      inputs[i].MoveTo(-w/2-inputs[i].w/2, -h/2 + inputs[0].h/2 + i * inputs[i].h);
      inputs[i].name = str(pow(2,i));
    }
    
    outputs = new OutPin[1];
    outputs[0] = new OutPin(this);
    UpdateDimensions();
  }
  
  int phase = 0;
  int ticks = 0;
  @Override
  public void UpdateIOPins(){
    super.UpdateIOPins();
    if(ticks>0){
      phase ++;
      if(phase > ticks){
        outputs[0].SetValue(!outputs[0].Value());
        phase = 0;
      }
    }
  }
  
  @Override
  public void Draw(){
    super.Draw();
    fill(foregroundCol);
    textAlign(CENTER);
    if(ticks>0){
      text("t: "+phase,WorldX(),WorldY()-6);
      text("tn: "+ticks,WorldX(),WorldY()+6);
    } else {
      text("t:N/A",WorldX(),WorldY()-6);
      text("tn:N/A",WorldX(),WorldY()+6);
    }
  }
  
  @Override
  protected void UpdateLogic(){
    ticks = 0;
    for(int i = 0; i < inputs.length; i++){
      if(inputs[i].Value()){
        //we dont want negative numbers from bit shifting
        ticks += pow(2,i);
      }
    }
  }
  
  @Override
  public LogicGate CopySelf(){
    Ticker lg = new Ticker();
    lg.CopyValues(this);
    lg.ticks = ticks;
    lg.phase = phase;
    return lg;
  }
  
  @Override
  public int PartID(){
    return TICKGATE;
  }
}

class RelayGate extends LogicGate{
  public RelayGate(){
    super();
    w=20;
    h=15;
    inputs = new InPin[1];
    inputs[0] = new InPin(this);
    
    title = ">";
    outputs = new OutPin[1];
    outputs[0] = new OutPin(this);
    UpdateDimensions();
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
  
  @Override
  public int PartID(){
    return INPUTGATE;
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
  public void UpdateDimensions(){}//do nothing
  
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
  
  @Override
  public int PartID(){
    return LCDGATE;
  }
}

class Base10Gate extends LogicGate{
  public Base10Gate(float fontSize){
    super();
    showText=false;
    h = fontSize;
    textSize(h);
    w = textWidth("2,147,483,647")+20;
    textSize(TEXTSIZE);
    title = "Num";
    inputs = new InPin[32];
    for(int i = 0; i < 32; i++){
      inputs[i]=new InPin(this);
      inputs[i].w = w/32.0;
      inputs[i].h = inputs[i].w;
      inputs[i].MoveTo(-w/2 + i * inputs[i].w + inputs[0].w/2,h/2+inputs[i].h/2); 
    }
  }
  String number = "0";
  
  @Override
  public void Draw(){
    noFill();
    super.Draw();
    stroke(foregroundCol);
    textAlign(CENTER);
    textSize(h);
    fill(0,225,0);
    text(number,WorldX(),WorldY()+h/4);
    textSize(TEXTSIZE);
  }
  
  @Override
  void UpdateLogic(){
    int num = 0;
    for(int i = 0; i < inputs.length; i++){
      if(inputs[i].Value()){
        num = num | (1<<i);
      }
    }
    number = nf(num,0,0);
  }
  
  @Override
  public LogicGate CopySelf(){
    LogicGate lg = new Base10Gate(h);
    lg.CopyValues(this);
    return lg;
  }
  
  @Override
  public void UpdateDimensions(){}//do nothing
  
  @Override
  public int PartID(){
    return BASE10GATE;
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
  
  @Override
  public void UpdateDimensions(){}//do nothing
  
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
    textSize(TEXTSIZE);
  }
  
  @Override
  public int PartID(){
    return PIXELGATE;
  }
}

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

final String dir = "Saved Circuits\\"; 

String filepath(String filename){
  return dir+filename+".txt";
}

boolean LoadProject(String filePath){
  Cleanup();
  ClearGateSelection();
  ClearPinSelection();
  LogicGate[] loadedGates = LoadGatesFromFile(filePath);
  if(loadedGates!=null){
    for(LogicGate lg : loadedGates){
      circuit.add(lg);
      selection.add(lg);
    }
    notifications.add("Loaded \""+filePath+"\" !");
    return true;
  }
  notifications.add("Unable to load \""+filePath+"\" :(");
  return false;
}

LogicGate[] LoadGatesFromFile(String filepath){
  String[] file = loadStrings(filepath);
  if(file==null){
    println("Not a file :(");
    return null;
  }
  if(file.length < 2){
    println("not my type of file tbh");
    return null; 
  }
  String data = file[1];
  LogicGate[] loadedGates;
  try{
    loadedGates = RecursiveLoad(data);
  } catch(Exception e){
    println("Something went wrong: " + e.getMessage());
    return null;
  }
  return loadedGates;
}

//tf is this hackerrank? this is definately one of those questions you would find there lmao
int findCorrespondingBracket(String data, int start, int end, char openBrace, char closeBrace){
  int sum = 0;
  for(int i = start; i < end; i++){
    if(data.charAt(i)==openBrace){
      sum++;
    } else if(data.charAt(i)==closeBrace){
      sum--;
    }
    if(sum==0)
      return i;
  }
  return -1;
}

//Load all the parts in a string into an array
LogicGate[] RecursiveLoad(String data){
  int partsIndex = data.lastIndexOf('|');
  int start = data.indexOf('{');
  int end = data.indexOf(',',start+1);
  int n = int(data.substring(start+1,end));
  LogicGate[] loaded = new LogicGate[n];
  //start is at {   end is at ,
  for(int i =  0; i < n; i++){
    start = data.indexOf('(',end);
    if(data.charAt(start+1)=='{'){
      //Find the end of this part and recursive load the {} bit and then it's metadata with LoadGroup
      end = findCorrespondingBracket(data,start,data.length(), '(', ')');
      loaded[i] = LoadGroup(data,start,end);
    } else if(data.charAt(start+1)=='N'){
      //load an embedded group
      start += 2;
      end = data.indexOf(',', start);
      loaded[i] = LoadSavedGroup(data.substring(start,end));
      loadMetadata(loaded[i],data,end+1, partsIndex);
    } else {
      end = data.indexOf(')',start+1);
      //Normal load it since it's just a primitive
      loaded[i] = LoadPart(data,start,end);
    }
    if(loaded[i]==null){
      println("Circuit "+i+"Couldn't be loaded");
    }
  }
  
  //Connect all the parts we just loaded
  start = partsIndex;
  for(int i =  0; i < n; i++){
    start = data.indexOf('<',start)+1;
    end = data.indexOf('>',start);
    int gateIndex = int(data.substring(start,end));
    int start2 = start;
    int end2 = start;
    for(int j = 0; j < loaded[gateIndex].inputs.length;j++){
      start2 = data.indexOf('[',start2)+1;
      end2 = data.indexOf(']',start2);
      
      //Continue if no connections
      if(data.charAt(start2)==']'){
        continue;
      }
      
      //else make the connections
      int div = data.indexOf(',',start2);
      int outputGateIndex = int(data.substring(start2,div));
      int outputIndex = int(data.substring(div+1,end2));
      loaded[gateIndex].inputs[j].Connect(loaded[outputGateIndex].outputs[outputIndex]);
    }
  }
  
  return loaded;
}

//assigns a part's outputs. not to be called on it's own
void assignPins(LogicGate lg, String pins){
  int start = pins.indexOf('|'+1);
  start = pins.indexOf('|',start+1)+1;
  int end;
  for(int i = 0; i < lg.inputs.length; i++){
    if(pins.charAt(start)==','){
      start++;
      continue;
    }
    end = pins.indexOf(',',start);
    lg.inputs[i].SetName(pins.substring(start,end));
    start = end+1;
  }
  if(lg.outputs==null)
    return;
    
  start=pins.indexOf("|", start)+1;
  start=pins.indexOf("|", start)+1;
  end = pins.indexOf(',',start);
  
  for(int i = 0; i < lg.outputs.length; i++){
    if(pins.charAt(start)==','){
      start++;
    } else {
      //We must have a name to assign
      end = pins.indexOf(',',start);
      lg.outputs[i].SetName(pins.substring(start,end));
    }
    //whether we assigned a name or not, there should be a 1 or 0 every odd comma
    start = end+1;
    lg.outputs[i].SetValue(pins.charAt(start)=='1');
    start = pins.indexOf(',',start)+1;
  }
}

//assigns a group it's x,y,w,h values, pin names, and output values. start is the index of the start of the first value, and end is the ). not to be called on it's own
void loadMetadata(LogicGate lg, String data, int start, int end){
  int a = start;
  int b = data.indexOf(',',a+1);
  lg.x = float(data.substring(a,b));
  a = b+1;
  b = data.indexOf(',',a);
  lg.y = float(data.substring(a,b));

  a=b+1;
  if(data.charAt(a)=='|'){
    assignPins(lg,data.substring(a+1,end));
    return;
  }
  //otherwise we have to load in the width and height and then do so
  b = data.indexOf(',',a);
  lg.w = float(data.substring(a,b));
  a = b+1;
  b = data.indexOf(',',a);
  lg.h = float(data.substring(a,b));
  assignPins(lg,data.substring(a+1,end));
}

//loads a primitive part from a string.
//where start is the ( and end is the )
LogicGate LoadPart(String data, int start, int end){
  int a = start+1;
  int b = data.indexOf(',',a);
  LogicGate lg = CreateGate(int(data.substring(a,b)));
  a = b+1;
  loadMetadata(lg,data,a, end);
  return lg;
}

//Loads a group. start is the opening (, and end is the ). Groups can have more groups. The base case would be a regular LoadPart
LogicGate LoadGroup(String data, int start, int end){
  int partEnd = findCorrespondingBracket(data,start+1,end,'{','}')+1; 
  //Connections are resolved in here
  LogicGate[] gates = RecursiveLoad(data.substring(start+1,partEnd));
  LogicGateGroup lg = new LogicGateGroup(gates);
  start = partEnd + 1;
  loadMetadata(lg,data,start,end);
  lg.expose = false;
  return lg;
}

void SaveProject(String filePath){
  String[] s = {  
                  "OnesAndZeroes Savefile. Don't modify the next line if you want things to work proper", 
                  CircuitString(circuit)
                };
  saveStrings(filePath,s);
  UpdateGroups();
  notifications.add("Saved \""+filePath+"\" !");
}

String CircuitString(ArrayList<LogicGate> cir){
  String s = "";
  s+=GateString(cir.toArray(new LogicGate[cir.size()]));
  return s;
}

String GateString(LogicGate[] gates){
  //looks like: {(part1)|pinnames,(part2)|pinnames..,(partn)|pinnames,|<part>[otherPart,outputFromOtherOart],<soOn>[AndSoForth]}
  String s = "{";
  s+=gates.length+",";
  //get all of the parts, and index the gates
  for(int i = 0; i < gates.length; i++){
    s+=gates[i].GetParts(embed);
    gates[i].arrayIndex = i;
  }
  s+="|";
  for(int i = 0; i < gates.length; i++){
    s+=gates[i].GetInputs();
  }
  s+="}";
  return s;
}

void printPins(Pin[] arr){
  for(int i = 0; i < arr.length; i++){
    println(arr[i].name);
    println(arr[i].WorldY());
  }
}

class LogicGateGroup extends LogicGate{
  LogicGate[] gates;
  boolean expose = true;
  int numGates;
  //these dimensions are for when the inner gates are exposed
  float ew,eh;
  //`` are hidden
  float hw,hh;
  
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
    title = "Group";
    if(gateArray.length==0)
      return;
    //find the bounding box for the group
    //also find the abstraction level
    //also find exposed input pins
    float minX=gates[0].x;
    float maxX=gates[0].x;
    float minY=gates[0].y; 
    float maxY=gates[0].y;
    
    int maxAbstraction = 0; 
    ArrayList<InPin> unusedInputs = new ArrayList<InPin>();
    ArrayList<OutPin> usedOutputs = new ArrayList<OutPin>();
    
    for(LogicGate lg : gates){
      lg.drawPins = false;
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
          unusedInputs.add(p);
        } else {
          //we need to check if it is connected to an output from the outside the group, in which case it is techinically 'unused'
          LogicGate lg2 = p.input.Chip();
          boolean insideGroup = contains(gates, lg2);
          if(!insideGroup){
            unusedInputs.add(p);
          } else {
            usedOutputs.add(p.input);
          }
        }
      }
    }
    
    x = (minX+maxX)/2.0;
    y = (minY+maxY)/2.0;
    ew = maxX-minX;
    eh = maxY-minY;
    
    inputs = unusedInputs.toArray(new InPin[unusedInputs.size()]);
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
          }
        }
      }
    }
    
    outputs = unusedOutputs.toArray(new OutPin[unusedOutputs.size()]);
    
    if((inputs.length==0)&&(outputs.length==0)){
      notifications.add("THIS GROUP HAS NO INPUTS OR OUTPUTS, AND IS COMPLETELY POINTLESS.");
      notifications.add("Remember to expose inputs and outputs using relay points, and to avoid using CTRL+G and instead load saved parts from the 'add saved' menu");
    } else if(inputs.length==0){
      notifications.add("THIS GROUP HAS NO INPUTS AND WON'T BEHAVE PROPERLY :v");
    } else if(outputs.length==0){
      notifications.add("THIS GROUP HAS NO OUTPUTS AND MIGHT BE REDUNDANT!");
    }
    
    level = maxAbstraction+1;
    
    //sort the io pins while their parents haven't been cleared to this
    //that way we still have access to their true y position
    
    Arrays.sort(inputs);
    Arrays.sort(outputs);
    
    for(Pin p : inputs){
      p.SetParent(this);
    }
    for(Pin p : outputs){
      p.SetParent(this);
    }
    UpdateDimensions();
  }
  
  void SetName(String newName){
    title = newName;
    exposeChanged=true;
  }
  
  @Override 
  void OnMouseRelease(){
    float textW = textWidth(title);
    float x1 = WorldX() - textW/2;
    float y1 = WorldY()-TEXTSIZE/2;
    
    if(mouseInside(x1,y1,textW,TEXTSIZE)){
      if(draggedElement!=this){
        expose = !expose;
        exposeChanged = true;
      }
    }
  }
  
  @Override 
  void OnHover(){
    super.OnHover();
    if(title!=null);
    float textW = textWidth(title);
    float x1 = WorldX() - textW/2;
    float y1 = WorldY()-TEXTSIZE/2;
    if(mouseInside(x1,y1,textW,TEXTSIZE)){
      fill(gateHoverCol);
      rect(x1,y1,textW,TEXTSIZE);
    }
  }
  
  boolean exposeChanged = false;
  
  @Override
  public void Draw(){
    if(exposeChanged){
      exposeChanged = false;
      if(expose){
        h = eh;
        w = ew;
        
        ArrangeInputs();
        ArrangeOutputs();
      } else {
        UpdateDimensions();
      }
    }
    
    if(expose){
      for(LogicGate lg : gates){
        lg.Draw();
      }
      for(Pin p : inputs){
        stroke(foregroundCol);
        line(p.ActualChip().WorldX(),p.ActualChip().WorldY(),p.WorldX(),p.WorldY()); 
      }
      
      for(Pin p : outputs){
        stroke(foregroundCol);
        line(p.ActualChip().WorldX(),p.ActualChip().WorldY(),p.WorldX(),p.WorldY()); 
      }
    }
    
    super.Draw();
  }
  
  @Override
  public void Decouple(){
    super.Decouple();
    for(LogicGate lg : gates){
      lg.Decouple();
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
    LogicGateGroup lg = new LogicGateGroup(CopyPreservingConnections(gates));
    lg.CopyValues(this);
    lg.SetName(title);
    lg.expose = false;
    return lg;
  }
  
  @Override int PartID(){
    return -1;
  }
  
  //Save every gate recursively lmao
  @Override
  public String PartIDString(boolean embed){
    if(embed){
      return GateString(gates);
    } else {
      return "N"+title;
    }
  }
}

//----------------- CUSTOM UI ELEMENTS ----------------
//used by other ui elements
abstract class CallbackFunctionInt {
  public abstract void f(int i);
}


abstract class CallbackFunction {
  public abstract void f();
}


class StringMenu extends UIElement{
  ArrayList<Button> elements;
  float elementHeight = 11;
  float padding = 2;
  String heading;
  CallbackFunctionInt f;
  
  private void updateDimensions(String[] arr){
    if(arr.length==0)
      return;
    //setup the dimensions
    int max = arr[0].length();
    for(String s : arr){
      if(s.length() > max){
        max = s.toString().length();
      }
    }
    
    x -= w/2;
    y -= h/2;
    
    w = max * 7 + 20 + 2 * padding;
    h = (arr.length+1) * (elementHeight+padding) + padding;
    
    x += w/2;
    y += h/2;
  }
  
  public StringMenu(String[] arr, String title, CallbackFunctionInt intFunction){
    heading = title;
    elements = new ArrayList<Button>();
    f = intFunction;
    UpdateEntries(arr);
  }
  
  @Override
  public void MoveTo(float x1, float y1){
    x = x1+w/2; y = y1+h/2;
  }
  
  @Override
  public void OnMouseRelease(){
    listClicked = false;
  }
  
  public String GetEntry(int i){
    return elements.get(i).Text();
  }
  
  public void UpdateEntries(String[] arr){
    elements.clear();
    updateDimensions(arr);
    for(int i =0; i < arr.length; i++){
      float x1 = 0;
      float y1 = padding + (i+1.5)*(elementHeight+padding)-h/2;
      float w1 = w-2*padding;
      float h1 = elementHeight;
      final CallbackFunctionInt finalCallback = f;
      final int thisIndex = i;
      elements.add(new Button(arr[i],x1,y1,w1,h1,gateHoverCol, trueCol, new CallbackFunction(){
        @Override
        public void f(){
          finalCallback.f(thisIndex);
        }
      }));
      elements.get(i).parent = this;
    }
  }
  
  boolean listClicked = false;
  
  @Override
  public void Draw(){
    noFill();
    super.Draw();
    fill(menuHeadingCol);
    text(heading,WorldX(),WorldY()-h/2+elementHeight);
    for(int i = 0; i < elements.size();i++){
      elements.get(i).Draw();
    }
  }
}

TextLabel pinNameInput;
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
}

void SetName(){
  pinToEditName.SetName(pinNameInput.Text());
  pinToEditName.UpdateDimensions();
  pinToEditName = null;
}

//will be used to input names and stuff
class TextInput extends UIElement{
  boolean isTyping = false;
  boolean startedTyping = false;
  boolean persistent = false;
  boolean clicked1 = false;
  int align;
  char lastKey = 'r';
  float x0,y0,w0,h0;
  CallbackFunction f;
  
  TextInput(){
    w=100;
  }
  
  public void Show(float x1, float y1, float h1,int aline){
    Show(x1,y1,h1,aline,null);
  }
  
  public void Show(float x1, float y1, float h1,int align,CallbackFunction f1){
    isTyping = true;
    x=x1;y=y1;h=h1; this.align = align;
    x0=x;y0=y;h0=h;
    textSize(h);
    w0 = max(h*5,textWidth(edited)+10);
    textSize(TEXTSIZE);
    f=f1;
    updateDimensions(edited);
  }
  
  protected String text = "";
  protected String edited = "";
  
  String Text(){
    return text;
  }
  
  private boolean isLegit(char c){
    return (((c>='0')&&(c<='9'))||((c>='a')&&(c<='z'))||((c>='A')&&(c<='Z')));//&&("(){}[]/.,;'\"\\=!@#$%^&*~`".indexOf(c)==-1);
  }
  
  private void drawContents(String str){
    updateDimensions(str);
    stroke(foregroundCol);
    strokeWeight(1/scale);
    fill(backgroundCol);
    super.Draw();
    strokeWeight(1);
    fill(foregroundCol);
    textAlign(CENTER);
    text(str,WorldX(),WorldY()+h/4.0);
    //carat
    if(isTyping){
      line(WorldX()+w/2-5, WorldY()+h/1.5,WorldX()+w/2-5, WorldY()-h/1.5);
    }
  }
  
  protected void updateDimensions(String str){
    w = max(h*5,textWidth(str)+10);
    if(align==LEFT){
      x = x0 + (w)/2.0;
    } else if(align==RIGHT){
      x = x0 - (w)/2.0;
    }
  }
  
  protected boolean isLegit(String s){
    if(s.length()==0){
      return false;
    }
    
    return true;
  }
  
  @Override
  public void Draw(){
    textSize(h);
    if(isTyping){
      if(!startedTyping){
        startedTyping = true;
        edited = "";
      }
      drawContents(edited);
      if(keyPushed){
        keyPushed = false;
        if(keyThatWasPushed=='\n'){
          isTyping = false;
          if(isLegit(edited)){
            text = edited;
            if(f!=null){
              f.f();
              //we need to remove references to it
              if(!persistent){
                f=null;
              }
            }
          }
        } else if(keyThatWasPushed=='\b'){
          if(edited.length()>0){
            edited = edited.substring(0,edited.length()-1);
          }
        } else if(isLegit(keyThatWasPushed)) {
          edited += keyThatWasPushed;
        }
      }
    } else {
      if(persistent){
        drawContents(text);
      } else {
        f = null;
      }
      startedTyping = false;
    }
    textSize(TEXTSIZE);
    if(!clicked1){
      if(mousePressed){
        if(!mouseInside(WorldX()-w/2,WorldY()-h/2,w,h)){
          isTyping = false;
        }
      }
    }
  }
}

class TextLabel extends TextInput{
  String label;
  TextLabel(String l){
    label = l;
    text = "";
  }
  
  TextLabel(String l, String text1, float x, float y, float h,int aline){
    text = text1;
    Show(x,y,h,aline);
    isTyping = false;
    label = l;
    persistent = true;
    align = aline;
  }
  
  @Override
  void OnMousePress(){
    if(mouseButton==LEFT){
      isTyping = true;
    }
  }
  
  @Override
  void Draw(){
    super.Draw();
    if(isTyping||persistent){
      textSize(h);
      textAlign(align);
      int sign = (align==LEFT ? 1 : (align==RIGHT ? -1 : 0));
      text(label, WorldX()+sign*w/2,WorldY()+h/4);
      textSize(TEXTSIZE);
    }
  }
}

class Button extends UIElement{
  color hC, pC;
  String title;
  CallbackFunction func;
  Button(String content, float x1, float y1, float w1, float h1, color hoverColor, color pressColor, CallbackFunction f){
    x = x1; y = y1; w = w1; h = h1; hC = hoverColor; pC = pressColor;
    func = f;
    title = content;
  }
  
  public String Text(){
    return title;
  }
  
  @Override
  void OnHover(){
    fill(hC);
  }
  
  @Override
  void OnMouseDown(){
    fill(pC);
  }
  
  @Override
  void OnMouseRelease(){
    func.f();
  }
  
  @Override
  void Draw(){
    noFill();
    super.Draw();
    fill(foregroundCol);
    textSize(h - 2);
    textAlign(CENTER);
    text(title, WorldX(), WorldY() + (h-2)/4);
    textSize(TEXTSIZE);
  }
}

//INPUT SYSTEM copy pasted from another personal project
boolean[] keyJustPressed = new boolean[25];
boolean[] keyStates = new boolean[25];
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
final int LKey = 22;
final int PlusKey = 23;
final int MinusKey = 24;

boolean shiftChanged = false;
//maps the processing keys to integers in our key state array, so we can add new keys as we please
HashMap<Character, Integer> keyMappings = new HashMap<Character, Integer>();

boolean keyPushed = false;
char keyThatWasPushed; 
int keyCodeThatWasPushed;
void keyPressed(){
  keyPushed = true;
  keyThatWasPushed = key;
  keyCodeThatWasPushed = keyCode;
  
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
}

void setup(){
  size(800,600);
  frame.setResizable(true);
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
  
  UIElement outputGateAddMenu = new StringMenu(outputNames, "ADD OUTPUT GATE", new CallbackFunctionInt(){
    @Override
    public void f(int i){
      AddGate(CreateGate(outputGates[i]));
    }
  });
  outputGateAddMenu.MoveTo(logicGateAddMenu.w+10,0);
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
  
  fileNameField = new TextLabel("Circuit name: ","unnamed",-20,-50,20,RIGHT);
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
  
  pinNameInput = new TextLabel("(New pin name)");
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

String[] listFiles(String path) {
  File file = new File(path);
  if (file.isDirectory()) {
    String[] files = file.list();
    return files;
  } else {
    // If it's not a directory
    return null;
  }
}

//get a list of files in filepath
void UpdateGroups(){
  String[] files = listFiles(sketchPath()+"\\"+dir);
  ArrayList<String> finalGroups = new ArrayList<String>();
  for(String f : files){
    int dotIndex = f.lastIndexOf('.');
    if(dotIndex>=0){
      println(f.substring(dotIndex,f.length()));
      println(f);
      if(f.substring(dotIndex,f.length()).equals(".txt")){
        finalGroups.add(f.substring(0,dotIndex));
      }
    }
  }
  logicGateGroupAddMenu.UpdateEntries(finalGroups.toArray(new String[finalGroups.size()]));
}

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

LogicGateGroup LoadSavedGroup(String filename){
  LogicGate[] gates = LoadGatesFromFile(filepath(filename));
  if(gates==null)
    return null;
  LogicGateGroup lg = new LogicGateGroup(gates);
  lg.expose = false;
  lg.SetName(filename);
  return lg;
}

void AddGateGroup(int i){
  String filename = logicGateGroupAddMenu.GetEntry(i);
  LogicGate lg = LoadSavedGroup(filename);
  circuit.add(lg);
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

//used for the menus
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
  "[Shift]+[G]: combine 2+ gates into a group",
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
TextLabel fileNameField;  

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
      if(keyPushed(GKey)){
        CreateNewGroup();
      } else if(keyPushed(DKey)){
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
