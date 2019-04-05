//Contains BinaryGate, and it's And, Or, Xor and Nand extensions

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
    outputs[0].name = "out";
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
