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
