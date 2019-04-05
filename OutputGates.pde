//Contains all debug and output gates

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
