//A special logic gate made up of other logic gates. I think it deserves it's own file

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
    if(gateArray==null)
      return;
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
  public void UpdateLogic(){
    for(LogicGate lg : gates){
      lg.UpdateLogic();
    }
  }
  
  @Override
  public void PropagateSignal(){
    for(LogicGate lg : gates){
      lg.PropagateSignal();
    }
  }
  
  @Override
  public LogicGateGroup CopySelf(){
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
      //return "E"+title;
    } else {
      return "N"+title;
    }
  }
  
  @Override
  public LogicGate[] GetGates(){
    return gates;
  }
}
