
class ButtonGate extends LogicGate{
  public ButtonGate(float wid, float hei){
    super();
    w=wid; h = hei;
    title = "";
    showText = false;
    outputs = new OutPin[1];
    outputs[0]= new OutPin(this);
    outputs[0].SetName("outpin name");
    ArrangeOutputs();
  }
  
  @Override
  public LogicGate CopySelf(){
    LogicGate lg = new ButtonGate(w,h);
    lg.CopyValues(this);
    return lg;
  }
  
  @Override
  public void UpdateDimensions(){}//do nothing
  
  public void Draw(){
    fill(foregroundCol);
    textSize(h*5 / 6f);
    textAlign(CENTER);
    text(outputs[0].name,WorldX(),WorldY()+h/4);
    textSize(TEXTSIZE);
    super.Draw();
  }
  
  @Override
  public void OnMousePress(){
    outputs[0].SetValue(true);
  }
  
  @Override
  public void OnMouseRelease(){
    outputs[0].SetValue(false);
  }
  
  @Override
  public int PartID(){
    return BUTTONINGATE;
  }
}
