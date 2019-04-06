//The base class for all logic gates. contains most of the functionality

LogicGate gateUnderMouse = null;

abstract class LogicGate extends UIElement implements Comparable<LogicGate>{
  String title = "?";
  public boolean deleted = false;
  protected boolean showText = true;
  boolean drawPins = true;
  protected int level = 0;
  public int Abstraction(){
    return level;
  }
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
  
  public void UpdateDimensions(){
    if(inputs==null)
      return;
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
    if(inputs!=null){
      for(int i = 0; i < inputs.length; i++){
        inputs[i].Connect(other.inputs[i].input);
        inputs[i].name = other.inputs[i].name;
      }
    }
    
    if(outputs!=null){
      for(int i = 0; i < outputs.length; i++){
        outputs[i].SetState(other.outputs[i].Value());
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
    
    DrawLinks();
    
    if(showText){
      textAlign(CENTER);
      fill(foregroundCol);
      text(title,WorldX(),WorldY()+TEXTSIZE/4.0);
    }
  }
  
  public void DrawLinks(){
    if(inputs!=null){
      for(int i = 0; i < inputs.length; i++){
        inputs[i].DrawLink();
      }
    }
  }
    
  //will update the logic. complex gates can optimize based on pinsChanged
  protected void UpdateLogic(){}
  
  public void PropagateSignal(){
    if(outputs!=null){
      for(OutPin p : outputs){
        p.PropagateSignal();
      }
    }
  }
}
