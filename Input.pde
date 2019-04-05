//INPUT SYSTEM copy pasted from another personal project
//Also contains the 2d cursor, as it's used to 'input' selection boxes
//Now it's in it's own file

boolean[] keyJustPressed = new boolean[27];
boolean[] keyStates = new boolean[27];
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
final int CommaKey = 25;
final int DotKey = 26;

void registerInputMappings(){
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
  keyMappings.put(',',CommaKey);
  keyMappings.put('<',CommaKey);
  keyMappings.put('.',DotKey);
  keyMappings.put('>',DotKey);
}

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

//handle all key shortcuts
void handleKeyShortcuts(){
    if(!fileNameField.isTyping){
    if(keyDown(ShiftKey)){
      if(keyPushed(DKey)){
        Duplicate();
      } else if(keyPushed(CKey)){
        ConnectSelected();
      }
    }
    
    if(keyPushed(SpaceKey)){
      paused = !paused;
    }
    
    if(paused){
      if(keyPushed(DotKey)){
        StepSimulation();
      }
    } else {
      if(keyPushed(CommaKey)){
        simSpeed=max(simSpeed-1,1);
      } else if(keyPushed(DotKey)){
        simSpeed=min(simSpeed+1,1000);
      }
    }
    
    if(keyPushed(PlusKey)){
      zoom(1);
    }
    if(keyPushed(MinusKey)){
      zoom(-1);
    }
  }
}
