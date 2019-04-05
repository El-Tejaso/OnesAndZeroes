//Called AUIElement for this to appear first in the alphabetical ordering
//base class for all ui elements. There is a small chance I'm reinventing the wheel here, 
//but I get a lot more control as opposed to >other options that I don't yet know about go here<

//Putting these here cause you cant make static vars in processing
//This is to prevent multiple things being dragged at once
UIElement draggedElement = null; 
boolean mouseOver = false;
//A rectangular UI element that all classes will derive from 
class UIElement{
  protected UIElement parent;
  public float x,y,w=5,h=5;
  private boolean clicked = false;
  protected int dragThreshold = 0;
  protected boolean acceptUIInput = true;
  
  public void MoveTo(float x1, float y1){
    x = x1; y = y1;
  }
  
  public float WorldX(){
    if(parent!=null)
      return parent.WorldX()+x;
      
    return x;
  }
  
  public float WorldY(){
    if(parent!=null)
      return parent.WorldY()+y;
      
    return y;
  }
  
  public void UIRespond(){
    if(!acceptUIInput)
      return;
    
    float x1 = WorldX()-w/2;
    float y1 = WorldY()-h/2; 
    //handle mouse clicks in an override if we aren't clicking an in/output
    if(mouseInside(x1,y1,w,h)){
      OnHover();
      mouseOver = true;
      if(mousePressed){
        if(!clicked){
          OnMousePress();
          clicked=true;
        } else {
          if(!(draggedElement==this))
            OnMouseDown();
        }
        
        if(abs(mouseX-pmouseX)+abs(mouseY-pmouseY)>dragThreshold){
            if(draggedElement==null){
              draggedElement = this;
              OnDragStart();
            }
        }
      } else if(clicked) {
        clicked = false;
        OnMouseRelease();
        draggedElement = null;
      }
    } else {
      if(clicked){
        clicked = false;
        if(!mousePressed){
          OnMouseRelease();
        }
      }
      
      if(draggedElement==this){
        if(!mousePressed)
          draggedElement = null;
      }
    }
    
    if(draggedElement==this){
      OnDrag();
    }
  }
  
  //this function is called every frame, and can also be used to start events
  public void Draw(){    
    float x1 = WorldX()-w/2;
    float y1 = WorldY()-h/2; 
    
    UIRespond();
    //let the input overrides determine the colour of this rectangle
    rect(x1,y1,w,h);
  }
  
  public void OnMousePress(){}
  
  public void OnMouseRelease(){}
  
  public void OnMouseDown(){}

  public void OnHover(){}
  
  public void OnDrag(){}
  
  public void OnDragStart(){}
}
