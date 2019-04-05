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


class StringMenu extends UIElement{
  ArrayList<Button> elements;
  float elementHeight = 11;
  float padding = 2;
  String heading;
  CallbackFunctionInt f;
  
  private void updateDimensions(String[] arr){
    if(arr.length==0)
      return;
    //setup the dimensions
    int max = heading.length();
    for(String s : arr){
      if(s.length() > max){
        max = s.toString().length();
      }
    }
    
    x -= w/2;
    y -= h/2;
    
    w = max * 7 + 20 + 2 * padding;
    h = (arr.length+1) * (elementHeight+padding) + padding;
    
    x += w/2;
    y += h/2;
  }
  
  public StringMenu(String[] arr, String title, CallbackFunctionInt intFunction){
    heading = title;
    elements = new ArrayList<Button>();
    f = intFunction;
    UpdateEntries(arr);
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
  
  public void UpdateEntries(String[] arr){
    elements.clear();
    updateDimensions(arr);
    for(int i =0; i < arr.length; i++){
      float x1 = 0;
      float y1 = padding + (i+1.5)*(elementHeight+padding)-h/2;
      float w1 = w-2*padding;
      float h1 = elementHeight;
      final CallbackFunctionInt finalCallback = f;
      final int thisIndex = i;
      elements.add(new Button(arr[i],x1,y1,w1,h1,gateHoverCol, trueCol, new CallbackFunction(){
        @Override
        public void f(){
          finalCallback.f(thisIndex);
        }
      }));
      elements.get(i).parent = this;
    }
  }
  
  boolean listClicked = false;
  
  @Override
  public void Draw(){
    noFill();
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
    return (((c>='0')&&(c<='9'))||((c>='a')&&(c<='z'))||((c>='A')&&(c<='Z')));//&&("(){}[]/.,;'\"\\=!@#$%^&*~`".indexOf(c)==-1);
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
