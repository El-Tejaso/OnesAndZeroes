void SaveProject(String filePath){
  String[] s = {  
                  "OnesAndZeroes Savefile. Don't modify the next line if you want things to work proper", 
                  CircuitString(circuit)
                };
  saveStrings(filePath,s);
  UpdateGroups();
  notifications.add("Saved \""+filePath+"\" !");
}

String CircuitString(ArrayList<LogicGate> cir){
  String s = "";
  s+=GateString(cir.toArray(new LogicGate[cir.size()]));
  return s;
}

String GateString(LogicGate[] gates){
  //looks like: {(part1)|pinnames,(part2)|pinnames..,(partn)|pinnames,|<part>[otherPart,outputFromOtherOart],<soOn>[AndSoForth]}
  String s = "{";
  s+=gates.length+",";
  //get all of the parts, and index the gates
  for(int i = 0; i < gates.length; i++){
    s+=gates[i].GetParts(embed);
    gates[i].arrayIndex = i;
  }
  s+="|";
  for(int i = 0; i < gates.length; i++){
    s+=gates[i].GetInputs();
  }
  s+="}";
  return s;
}
