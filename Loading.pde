//Contains all functions associated with loading gates from a file
final String dir = "Saved Circuits\\"; 

String filepath(String filename){
  return dir+filename+".txt";
}

//load a project from a filepath. not additive
boolean LoadProject(String filePath, String filename){
  long time = millis();
  LogicGate[] loadedGates;
  try{
    ArrayList<String> cycleStack = new ArrayList<String>();
    cycleStack.add(filename);
    loadedGates = LoadGatesFromFile(filePath,new HashMap<String,LogicGateGroup>(), cycleStack);
  } catch (Exception e){
    String notif = e.getMessage();
    println(notif);
    notifications.add(notif);
    return false;
  }
  if(loadedGates!=null){
    circuit = new ArrayList<LogicGate>();
    for(LogicGate lg : loadedGates){
      circuit.add(lg);
      selection.add(lg);
    }
    ClearGateSelection();
    ClearPinSelection();
    String notif = "Loaded \""+filePath+"\" in "+(millis()-time)+"ms"; 
    println(notif);
    notifications.add(notif+" !");
    return true;
  }
  notifications.add("Unable to load \""+filePath+"\" :(");
  return false;
}

String LoadStringData(String filepath){
  String[] file;
  try{
    file = loadStrings(filepath);
  } catch(RuntimeException e){
    notifications.add("\"" + filepath + "\" is close to but not a real file. For some reason, this exception isn't thrown when the name is completely different");
    return "";
  }
  if(file==null){
    String err = "\"" + filepath + "\" wasn't found"; 
    println(err);
    notifications.add(err);
    return "";
  }
  if(file.length < 2){
    println("\"" + filepath + " is not my type of file tbh");
    return ""; 
  }
  
  return file[1];
}

LogicGate[] LoadGatesFromFile(String filepath, HashMap<String,LogicGateGroup> lookupTable,ArrayList<String> cycleStack) throws Exception{
  String data = LoadStringData(filepath);
  //so that we don't load files we've already loaded
  return LoadGatesFromString(data, lookupTable,cycleStack);
}

int LoadEmbeddedData(String data, HashMap<String,LogicGateGroup> lt,ArrayList<String> cycleStack) throws Exception{
  int start = 0;
  int end = 1;
  while(data.charAt(start)=='N'){
    start++;
    end = data.indexOf('{', start);
    String name = data.substring(start, end);
    start = end;
    
    LogicGate[] gates = RecursiveLoad(data,lt,start,cycleStack);
    
    lt.put(name, new LogicGateGroup(gates));
    start = findCorrespondingBracket(data,start,data.length(),'{','}')+1;
  }
  return start;
}

LogicGate[] LoadGatesFromString(String data, HashMap<String,LogicGateGroup> lt,ArrayList<String> cycleStack) throws Exception{
  LogicGate[] loadedGates = null;
  
  //load all embbeded gates to the lookup table
  int start = LoadEmbeddedData(data,lt,cycleStack);
  //Load in the embedded groups
  loadedGates = RecursiveLoad(data,lt,start,cycleStack);
  
  return loadedGates;
}

//start is the index of the openBrace
int findCorrespondingBracket(String data, int start, int end, char openBrace, char closeBrace){
  int sum = 0;
  for(int i = start; i < end; i++){
    if(data.charAt(i)==openBrace){
      sum++;
    } else if(data.charAt(i)==closeBrace){
      sum--;
    }
    if(sum==0)
      return i;
  }
  return -1;
}

//Load all the parts in a string into an array
//s is the index of the '{' for the new part
LogicGate[] RecursiveLoad(String data, HashMap<String,LogicGateGroup> lt, int s,ArrayList<String> cycleStack) throws Exception{
  int start = s;
  int end = data.indexOf(',',start+1);
  int n = int(data.substring(start+1,end));
  LogicGate[] loaded = new LogicGate[n];
  //start is at {   end is at ,
  for(int i =  0; i < n; i++){
    start = data.indexOf('(',end);
    if(data.charAt(start+1)=='{'){
      //Find the end of this part and recursive load the {} bit and then it's metadata with LoadGroup
      end = findCorrespondingBracket(data,start,data.length(), '(', ')');
      loaded[i] = LoadGroup(data,start,end,lt,cycleStack);
    } else if(data.charAt(start+1)=='N'){
      //load either an embedded group or a file
      start += 2;
      end = data.indexOf(',', start);
      String gateName = data.substring(start,end);
      
      loaded[i] = LoadSavedGroup(gateName, lt,cycleStack);
      
      /*
      if(loaded[i].GetGates()==null){
        throw new Exception("Invalid gate. It either has a cycle, or a ");
      }
      */
      loadMetadata(loaded[i],data,end+1);
    } else {
      end = data.indexOf(')',start+1);
      //Normal load it since it's just a primitive
      loaded[i] = LoadPart(data,start,end);
    }
    if(loaded[i]==null){
      println("Circuit "+i+"Couldn't be loaded");
    }
  }
  //Connect all the parts we just loaded
  start = data.lastIndexOf('|', findCorrespondingBracket(data,s,data.length(),'{','}'));
  
  for(int i =  0; i < n; i++){
    start = data.indexOf('<',start)+1;
    end = data.indexOf('>',start);
    int gateIndex = int(data.substring(start,end));
    int start2 = start;
    int end2 = start;
    for(int j = 0; j < loaded[gateIndex].inputs.length;j++){
      start2 = data.indexOf('[',start2)+1;
      end2 = data.indexOf(']',start2);
      
      //Continue if no connections
      if(data.charAt(start2)==']'){
        continue;
      }
      
      //else make the connections
      int div = data.indexOf(',',start2);
      int outputGateIndex = int(data.substring(start2,div));
      int outputIndex = int(data.substring(div+1,end2));
      loaded[gateIndex].inputs[j].Connect(loaded[outputGateIndex].outputs[outputIndex]);
    }
  }
  
  return loaded;
}


//assigns a part's outputs. not to be called on it's own
void assignPins(LogicGate lg, String data, int start){
  start = data.indexOf('|',start+1)+1;
  int end;
  for(int i = 0; i < lg.inputs.length; i++){
    if(data.charAt(start)==','){
      start++;
      continue;
    }
    end = data.indexOf(',',start);
    String pinName = data.substring(start,end);
    lg.inputs[i].SetName(pinName);
    start = end+1;
  }
  if(lg.outputs==null)
    return;
    
  start=data.indexOf("|", start)+1;
  start=data.indexOf("|", start)+1;
  end = data.indexOf(',',start);
  
  for(int i = 0; i < lg.outputs.length; i++){
    if(data.charAt(start)==','){
      start++;
    } 
    
    //We must have a name to assign
    end = data.indexOf(',',start);
    lg.outputs[i].SetName(data.substring(start,end));
    
    //whether we assigned a name or not, there should be a 1 or 0 every odd comma
    start = end+1;
    lg.outputs[i].SetState(data.charAt(start)=='1');
    start = data.indexOf(',',start)+1;
  }
}

//assigns a group it's x,y,w,h values, pin names, and output values. start is the index of the start of the first value, and end is the ). not to be called on it's own
void loadMetadata(LogicGate lg, String data, int start){
  int a = start;
  int b = data.indexOf(',',a+1);
  lg.x = float(data.substring(a,b));
  a = b+1;
  b = data.indexOf(',',a);
  lg.y = float(data.substring(a,b));

  a=b+1;
  if(data.charAt(a)=='|'){
    assignPins(lg,data,a+1);
    return;
  }
  //otherwise we have to load in the width and height and then do so
  b = data.indexOf(',',a);
  lg.w = float(data.substring(a,b));
  a = b+1;
  b = data.indexOf(',',a);
  lg.h = float(data.substring(a,b));
  assignPins(lg,data,a+1);
}

//loads a primitive part from a string.
//where start is the ( and end is the )
LogicGate LoadPart(String data, int start, int end){
  int a = start+1;
  int b = data.indexOf(',',a);
  LogicGate lg = CreateGate(int(data.substring(a,b)));
  a = b+1;
  loadMetadata(lg,data,a);
  return lg;
}

//Loads a group. start is the opening (, and end is the ). Groups can have more groups. The base case would be a regular LoadPart
LogicGateGroup LoadGroup(String data, int start, int end, HashMap<String,LogicGateGroup> lt,ArrayList<String> cycleStack) throws Exception{
  int partEnd = findCorrespondingBracket(data,start+1,end,'{','}')+1; 
  //Connections are resolved in here
  LogicGate[] gates = RecursiveLoad(data,lt,start+1,cycleStack);
  
  LogicGateGroup lg = new LogicGateGroup(gates);
  start = partEnd + 1;
  loadMetadata(lg,data,start);
  lg.expose = false;
  return lg;
}

String[] listFiles(String path) {
  File file = new File(path);
  if (file.isDirectory()) {
    String[] files = file.list();
    return files;
  } else {
    // If it's not a directory
    return null;
  }
}

//get a list of files in filepath
void UpdateGroups(){
  String[] files = listFiles(sketchPath()+"\\"+dir);
  ArrayList<String> finalGroups = new ArrayList<String>();
  for(String f : files){
    int dotIndex = f.lastIndexOf('.');
    if(dotIndex>=0){
      if(f.substring(dotIndex,f.length()).equals(".txt")){
        finalGroups.add(f.substring(0,dotIndex));
      }
    }
  }
  logicGateGroupAddMenu.UpdateEntries(finalGroups.toArray(new String[finalGroups.size()]));
}

//loads a gate from a file, if not already present in the lookup table. only if it isn't on the cycle stack.
LogicGateGroup LoadSavedGroup(String filename, HashMap<String,LogicGateGroup> lt,ArrayList<String> cycleStack) throws Exception{
  //save unknown gates to the lookup table.
  if(cycleStack.contains(filename)){
    String err = filename + " is a dependancy of itself, causing an infinite recursion. The file couldn't be loaded;"; 
    println(err);
    notifications.add(err);
    throw new Exception(err);
  }
  
  cycleStack.add(filename);
  if(!lt.containsKey(filename)){
    String data = LoadStringData(filepath(filename));
    LogicGate[] gates = LoadGatesFromString(data, lt,cycleStack);
    lt.put(filename, new LogicGateGroup(gates));
  }
  //now get the gate from the lt
  LogicGateGroup lg = lt.get(filename).CopySelf();
  cycleStack.remove(cycleStack.size()-1);
  lg.expose = false;
  lg.SetName(filename);
  return lg;
}

void AddGateGroup(String s){
  String filename = s;
  int time = millis();
  LogicGate lg;
  try{
    ArrayList<String> stack = new ArrayList<String>();
    lg = LoadSavedGroup(filename, new HashMap<String,LogicGateGroup>(),stack);
  } catch (Exception e){
    String notif = e.getMessage();
    println(notif);
    notifications.add(notif);
    return;
  }
  String notif = "Loaded group \""+filename+"\" in "+(millis()-time)+"ms";
  println(notif);
  notifications.add(notif);
  lg.x = cursor.x;
  lg.y = cursor.y;
  circuit.add(lg);
}
