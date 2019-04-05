//Contains all functions associated with loading gates from a file

final String dir = "Saved Circuits\\"; 

String filepath(String filename){
  return dir+filename+".txt";
}

//load a project from a filepath. not additive
boolean LoadProject(String filePath){
  LogicGate[] loadedGates = LoadGatesFromFile(filePath);
  if(loadedGates!=null){
    circuit = new ArrayList<LogicGate>();
    for(LogicGate lg : loadedGates){
      circuit.add(lg);
      selection.add(lg);
    }
    notifications.add("Loaded \""+filePath+"\" !");
    ClearGateSelection();
    ClearPinSelection();
    return true;
  }
  notifications.add("Unable to load \""+filePath+"\" :(");
  return false;
}

LogicGate[] LoadGatesFromFile(String filepath){
  String[] file = loadStrings(filepath);
  if(file==null){
    println("Not a file :(");
    return null;
  }
  if(file.length < 2){
    println("not my type of file tbh");
    return null; 
  }
  String data = file[1];
  LogicGate[] loadedGates;
  try{
    loadedGates = RecursiveLoad(data);
  } catch(Exception e){
    println("Something went wrong: " + e.getMessage());
    return null;
  }
  return loadedGates;
}

//tf is this hackerrank? this is definately one of those questions you would find there lmao
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
LogicGate[] RecursiveLoad(String data){
  int partsIndex = data.lastIndexOf('|');
  int start = data.indexOf('{');
  int end = data.indexOf(',',start+1);
  int n = int(data.substring(start+1,end));
  LogicGate[] loaded = new LogicGate[n];
  //start is at {   end is at ,
  for(int i =  0; i < n; i++){
    start = data.indexOf('(',end);
    if(data.charAt(start+1)=='{'){
      //Find the end of this part and recursive load the {} bit and then it's metadata with LoadGroup
      end = findCorrespondingBracket(data,start,data.length(), '(', ')');
      loaded[i] = LoadGroup(data,start,end);
    } else if(data.charAt(start+1)=='N'){
      //load an embedded group
      start += 2;
      end = data.indexOf(',', start);
      loaded[i] = LoadSavedGroup(data.substring(start,end));
      loadMetadata(loaded[i],data,end+1, partsIndex);
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
  start = partsIndex;
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
void assignPins(LogicGate lg, String pins){
  int start = pins.indexOf('|'+1);
  start = pins.indexOf('|',start+1)+1;
  int end;
  for(int i = 0; i < lg.inputs.length; i++){
    if(pins.charAt(start)==','){
      start++;
      continue;
    }
    end = pins.indexOf(',',start);
    lg.inputs[i].SetName(pins.substring(start,end));
    start = end+1;
  }
  if(lg.outputs==null)
    return;
    
  start=pins.indexOf("|", start)+1;
  start=pins.indexOf("|", start)+1;
  end = pins.indexOf(',',start);
  
  for(int i = 0; i < lg.outputs.length; i++){
    if(pins.charAt(start)==','){
      start++;
    } else {
      //We must have a name to assign
      end = pins.indexOf(',',start);
      lg.outputs[i].SetName(pins.substring(start,end));
    }
    //whether we assigned a name or not, there should be a 1 or 0 every odd comma
    start = end+1;
    lg.outputs[i].SetValue(pins.charAt(start)=='1');
    start = pins.indexOf(',',start)+1;
  }
}

//assigns a group it's x,y,w,h values, pin names, and output values. start is the index of the start of the first value, and end is the ). not to be called on it's own
void loadMetadata(LogicGate lg, String data, int start, int end){
  int a = start;
  int b = data.indexOf(',',a+1);
  lg.x = float(data.substring(a,b));
  a = b+1;
  b = data.indexOf(',',a);
  lg.y = float(data.substring(a,b));

  a=b+1;
  if(data.charAt(a)=='|'){
    assignPins(lg,data.substring(a+1,end));
    return;
  }
  //otherwise we have to load in the width and height and then do so
  b = data.indexOf(',',a);
  lg.w = float(data.substring(a,b));
  a = b+1;
  b = data.indexOf(',',a);
  lg.h = float(data.substring(a,b));
  assignPins(lg,data.substring(a+1,end));
}

//loads a primitive part from a string.
//where start is the ( and end is the )
LogicGate LoadPart(String data, int start, int end){
  int a = start+1;
  int b = data.indexOf(',',a);
  LogicGate lg = CreateGate(int(data.substring(a,b)));
  a = b+1;
  loadMetadata(lg,data,a, end);
  return lg;
}

//Loads a group. start is the opening (, and end is the ). Groups can have more groups. The base case would be a regular LoadPart
LogicGate LoadGroup(String data, int start, int end){
  int partEnd = findCorrespondingBracket(data,start+1,end,'{','}')+1; 
  //Connections are resolved in here
  LogicGate[] gates = RecursiveLoad(data.substring(start+1,partEnd));
  LogicGateGroup lg = new LogicGateGroup(gates);
  start = partEnd + 1;
  loadMetadata(lg,data,start,end);
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
      println(f.substring(dotIndex,f.length()));
      println(f);
      if(f.substring(dotIndex,f.length()).equals(".txt")){
        finalGroups.add(f.substring(0,dotIndex));
      }
    }
  }
  logicGateGroupAddMenu.UpdateEntries(finalGroups.toArray(new String[finalGroups.size()]));
}

LogicGateGroup LoadSavedGroup(String filename){
  LogicGate[] gates = LoadGatesFromFile(filepath(filename));
  if(gates==null)
    return null;
  LogicGateGroup lg = new LogicGateGroup(gates);
  lg.expose = false;
  lg.SetName(filename);
  return lg;
}

void AddGateGroup(int i){
  String filename = logicGateGroupAddMenu.GetEntry(i);
  LogicGate lg = LoadSavedGroup(filename);
  circuit.add(lg);
}
