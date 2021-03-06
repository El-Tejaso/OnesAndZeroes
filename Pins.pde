//The pins used by the LogicGates

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
   // nameChanged = true;
    UpdateDimensions();
  }
  
  Pin(LogicGate parentChip){
    chip = parentChip;
    parent = parentChip;
    abstractedChip = parentChip;
    dragThreshold = -1;
  }
  
 // protected boolean nameChanged = false;
  //public boolean NameChanged(){return nameChanged;}
  
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
  
  boolean lastValue = false;
  public boolean Value(){return false;}
  public boolean IsConnected(){return true;}
}

//An input pin on a logic gate. Every input can link to at most 1 output pin
class InPin extends Pin{
  private OutPin input;
  boolean prevValue = false;
  
  public InPin(LogicGate p){
    super(p);
    name = "i";
  }
  
  public void Connect(OutPin in){
    input = in;
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
      stroke(input.Value() ? trueCol : falseCol);
      float dir = (WorldX() - input.WorldX()) > 0 ? 1 : -1;
      int dirY = (WorldY() - input.WorldY()) > 0 ? 1 : -1;
      float offsetIn; 
      if(dirY == 1){
        offsetIn = (dir * (y+parent.h/2))/2;
      } else {
        offsetIn = (dir * (-y+parent.h/2))/2;
      }
      //float offsetOut = dir * (input.y+input.parent.h/2);
      line(WorldX()+w/2,WorldY(),WorldX()-offsetIn,WorldY());
      line(WorldX()-offsetIn, WorldY(), WorldX()-offsetIn, input.WorldY());
      line(WorldX()-offsetIn, input.WorldY(),input.WorldX()-input.w/2, input.WorldY());
    }
  }
  
  //removes references to deleted nodes. if the node that was deleted had only one input and output, we can simply dissolve the node
  public void CleanupDissolve(){
    if(input==null)
      return;
    if(!input.Chip().deleted)
      return;
    
    boolean dissolved = false;
    if((input.Chip().inputs!=null)&&(input.Chip().outputs!=null)){
      int thisIndex = input.Chip().OutputIndex(input);
      if(thisIndex < input.Chip().inputs.length){
        dissolved = true;
        Connect(input.Chip().inputs[thisIndex].input);
      }
    }
    
    if(!dissolved){
      Connect(null);
    }
  }
  
  @Override
  public boolean IsConnected(){
    return (input!=null);    
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
  OutPin(LogicGate p){
    super(p);
    name = "o";
  }
  
  public void SetValue(boolean v){
    if(IsDeleted())
      return;
      
    nextValue = v;
  }
  
  public void SetState(boolean s){
    value = s;
    nextValue = s;
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
  
  public void PropagateSignal(){
    value = nextValue;
  }
  
  boolean nextValue = false;
  boolean value = false;
}
