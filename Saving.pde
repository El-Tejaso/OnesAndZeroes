//all methods related to saving gates
Button saveButton;
Button loadButton;
Button embedToggle;
//determines whether or not the file will embed the gates. 
//embedding means that others won't need all of the acompanying gates, but makes it much harder to edit subcomponents
boolean embed = false;

//stores a mapping between group names and group strings
void BuildLookupTable(ArrayList<LogicGate> list, StringDict lt) throws Exception{
  Collections.sort(list);
  RecursiveBuild(lt, list.toArray(new LogicGate[list.size()]), new ArrayList<String>());
}

//build the lookup table by recursing through each group's gates
//we might be able to find cycles here as well
void RecursiveBuild(StringDict lt, LogicGate[] array,ArrayList<String> cycleStack) throws Exception {
  if(array==null)
    return;
  //This will sort the gates by abstraction. changing the order of the gates shouldn't mess with functionality unless done after indexing
  
  for(LogicGate lg : array){
    //add it to the lt if it's a group
    String lgName = lg.PartIDString(false); 
    if(lgName.charAt(0)=='N'){
      if(!lt.hasKey(lgName)){
        if(cycleStack.contains(lgName)){
          throw new Exception("File cannot be saved: " + lgName + " is being used in " + lgName + ", causing an infinite recursion");
        }
        cycleStack.add(lgName);
        RecursiveBuild(lt,lg.GetGates(),cycleStack);
        lt.set(lgName, lg.PartIDString(true));
        cycleStack.remove(cycleStack.size()-1);
      }
    }
  }
}

//write the gate to a text file
void SaveProject(String filePath){
  String[] s = { 
                  "OnesAndZeroes Savefile. Don't modify the next line if you want things to work proper", 
                  CircuitString(circuit)
                };
  saveStrings(filePath,s);
  
  //updates the menu
  UpdateGroups();
  notifications.add("Saved \""+filePath+"\" !");
}

String CircuitString(ArrayList<LogicGate> cir){
  String s = "";
  if(embed){
    //list of all gates used mapped to a saved version
    StringDict partsToEmbed = new StringDict();
    try{
      BuildLookupTable(circuit,partsToEmbed);
    } catch (Exception e){
      String notif = e.getMessage();
      println(notif);
      notifications.add(notif);
      return notif;
    }
    for(String k : partsToEmbed.keyArray()){
      s+=k;
      s+=partsToEmbed.get(k);
    }
  }
  s+=GateString(cir.toArray(new LogicGate[cir.size()]));
  return s;
}

String GateString(LogicGate[] gates){
  //looks like: {(part1)|pinnames,(part2)|pinnames..,(partn)|pinnames,|<part>[otherPart,outputFromOtherOart],<soOn>[AndSoForth]}
  String s = "{";
  s+=gates.length+",";
  //get all of the parts, and index the gates
  for(int i = 0; i < gates.length; i++){
    s+=gates[i].GetParts(false);
    gates[i].arrayIndex = i;
  }
  s+="|";
  for(int i = 0; i < gates.length; i++){
    s+=gates[i].GetInputs();
  }
  s+="}";
  return s;
}
