//INPUT SYSTEM copy pasted from another personal project
//Also contains the 2d cursor, as it's used to 'input' selection boxes
//Now it's in it's own file

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
