//Contains callback function templates, and the following custom UI:
//StringMenu
//TextInput
//TextLabel

abstract class CallbackFunctionInt {
  public abstract void f(int i);
}

abstract class CallbackFunction {
  public abstract void f();
}

abstract class CallbackFunctionString{
  public abstract void f(String s);
}

//generates a key from a string. there are a number of ways to do this. goes with the sorting string menu
abstract class KeygenFunction{
  public abstract String f(String s);
}

//made of multiple string menus
class SortingStringMenu extends UIElement{
  ArrayList<StringMenu> menus;
  ArrayList<String> keys;
  String title;
  CallbackFunctionString f;
  KeygenFunction kgf;
  //for completeness, we can add another function that compares the keys that we can use to sort
  float elementHeight;
  float padding = 4;
  
  SortingStringMenu(String t, float elementHeight, CallbackFunctionString f, KeygenFunction kgf){
    title = t;
    this.elementHeight = elementHeight;
    this.f = f;
    this.kgf = kgf;
    menus = new ArrayList<StringMenu>();
    keys = new ArrayList<String>();
  }
  
  void updateDimensions(){
    for(StringMenu m : menus){
      m.updateDimensions();
    }
    
    float xPos = padding;
    float yPos = 3*padding+elementHeight;
    int numCols = 6;
    int currentCol = 0;
    float maxHeight = 0;
    float maxWidth = 0;
    for(StringMenu m : menus){
      m.MoveTo(xPos,yPos);
      xPos += m.w + padding;
      maxHeight = max(maxHeight, m.h);
      maxWidth = max(xPos,maxWidth);
      currentCol++;
      if(currentCol == numCols){
        yPos += maxHeight + 2*padding;
        xPos = padding;
        maxHeight = 0;
        currentCol = 0;
      }
    }
    x-=w/2;
    y-=h/2;
    w = maxWidth;
    h = yPos + maxHeight + 3*padding + elementHeight;
    x+=w/2;
    y+=h/2;
    
    for(StringMenu m : menus){
      m.x-=w/2;
      m.y-=h/2;
    }
  }
  
  void AddEntry(String s, boolean noRepeat){
    if((s==null)||(s.isEmpty()))
      return;
      
    //figure out which bin to group S into, and then add the entry
    String k = kgf.f(s);
    if(!keys.contains(k)){
      keys.add(k);
      Collections.sort(keys);
      StringMenu newMenu = new StringMenu(k, f, elementHeight*4/5);
      newMenu.parent = this;
      menus.add(keys.indexOf(k), newMenu);
    }
    if(noRepeat){
      if(!menus.get(keys.indexOf(k)).HasEntry(s)){
        menus.get(keys.indexOf(k)).AddEntry(s);
      }
    } else {
      menus.get(keys.indexOf(k)).AddEntry(s);
    }
    updateDimensions();
  }
  
  public void UpdateEntries(String[] arr){
    menus.clear();
    for(String s : arr){
      AddEntry(s,true);
      println(s);
    }
    updateDimensions();
  }
  
  @Override
  void Draw(){
    noFill();
    super.Draw();
    for(StringMenu m : menus){
      m.Draw();
    }
    text(title, WorldX(), WorldY()-h/2+elementHeight+padding);
  }
}

class StringMenu extends UIElement{
  ArrayList<Button> elements;
  float elementHeight = 11;
  float padding = 2;
  String heading;
  CallbackFunctionString f;
  
  private void updateDimensions(){
    //setup the dimensions
    textSize(elementHeight+2);
    float max = textWidth(heading);
    for(Button b : elements){
      max = max(max, textWidth(b.Text()));
    }
    textSize(TEXTSIZE);
    float cornerX = x-w/2;
    float cornerY = y-h/2;
    
    w = max + 2 * padding;
    h = (elements.size()+1) * (elementHeight+padding) + padding;
    
    x = cornerX + w/2;
    y = cornerY + h/2;
    
    float yPos = -h/2 + 1.5*elementHeight + 2*padding;
    for(int i = 0; i < elements.size(); i++){
      Button b = elements.get(i);
      b.x = 0;
      b.y = yPos;
      yPos += padding+elementHeight;
      b.w = max;
      b.h = elementHeight;
    }
  }
  
  public StringMenu(String title, CallbackFunctionString intFunction, float elementHeight){
    heading = title;
    this.elementHeight = elementHeight;
    elements = new ArrayList<Button>();
    f = intFunction;
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
  public void AddEntry(String s){
    AddEntry(s,true);
  }
  public boolean HasEntry(String s){
    for(Button m : elements){
      if(m.Text().equals(s)){
        return true;
      }
    }
    return false;
  }
  public void AddEntry(String s, boolean updateDims){
    int i = elements.size();
    final int thisIndex = i;
    final CallbackFunctionString finalCallback = f;
    elements.add(new Button(s,0,0,0,0,gateHoverCol, trueCol, new CallbackFunction(){
      @Override
      public void f(){
        finalCallback.f(elements.get(thisIndex).Text());
      }
    }));
    elements.get(i).parent = this;
    if(updateDims){
      updateDimensions();
    }
  }
  
  public void UpdateEntries(String[] arr){
    elements.clear();
    for(int i =0; i < arr.length; i++){
      AddEntry(arr[i],false);
    }
    updateDimensions();
  }
  
  boolean listClicked = false;
  
  @Override
  public void Draw(){
    noFill();
    stroke(foregroundCol);
    super.Draw();
    fill(menuHeadingCol);
    text(heading,WorldX(),WorldY()-h/2+elementHeight);
    for(int i = 0; i < elements.size();i++){
      elements.get(i).Draw();
    }
  }
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
  
  String label;
  
  public void SetLabel(String l){
    label = l;
  }
  
  TextInput(String l){
    w=100;
    text = "";
    label = l;
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
    return (((c>='0')&&(c<='9'))||((c>='a')&&(c<='z'))||((c>='A')&&(c<='Z')));
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
  void OnMousePress(){
    if(mouseButton==LEFT){
      isTyping = true;
    }
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
