/*********************************************
 * OPL 12.3 Model
 * Author: jie_li
 *********************************************/
using CP;  

float beforeTime;
execute{
var before = new Date();
beforeTime = before.getTime();
}

float Epsilon = 1e-6;

tuple Item {
	string itemID;
	string stimulusID;
	float pValue;
	string content;
	string answerkey;
};

ordered {Item} Items = ...;
ordered {string} ContentOrder = ...;
int M_Answerkey = ...;
 
{Item} Items_by_Content[c in ContentOrder] = union (i in Items : i.content == c) {i};
{string} StimulusIDs = union(i in Items : i.stimulusID != "" ) {i.stimulusID};
{Item} Items_by_StimulusID[s in StimulusIDs] = union (i in Items : i.stimulusID == s) {i};
float AvgPValue[s in StimulusIDs] = ( sum(i in Items : i.stimulusID == s) i.pValue ) / card(Items_by_StimulusID[s]);
float Item_AvgPValue[Items] = [];
execute {
  for (var tmp_i in Items) {
    if (tmp_i.stimulusID=="") {
    	Item_AvgPValue[tmp_i] = tmp_i.pValue;
    } else {
    	Item_AvgPValue[tmp_i] = AvgPValue[tmp_i.stimulusID];      
    }          	
  }    
}  
{string} Answerkeys = union(i in Items : i.answerkey != "") {i.answerkey};
{Item} Items_by_Answerkey[a in Answerkeys] = union(i in Items : i.answerkey == a) {i};


int N = card(Items);
range Positions = 1..N ;
dvar int X[Items] in Positions;
dvar int V[Answerkeys][Positions] in 0..1;
dvar int R_AnswerkeySeq[Answerkeys][Positions] in 0..1;
dvar int R_PValueSeq[Items][Items] in 0..1;


dexpr int total_R_pValueSeq = sum(i,j in Items) R_PValueSeq[i][j];
dexpr int total_R_AnswerkeySeq = sum(a in Answerkeys, p in Positions) R_AnswerkeySeq[a][p] ;
dexpr int modelobj = 1 * total_R_AnswerkeySeq + 10 * total_R_pValueSeq;  	// notice: T2 + T1

minimize modelobj;


subject to {
  
	allDifferent(X); 	//C1

	forall(s in StimulusIDs)	//C2
	  max(i in Items_by_StimulusID[s]) X[i] - min(j in Items_by_StimulusID[s]) X[j] ==  card(Items_by_StimulusID[s]) - 1;

	forall(c in ContentOrder : c != last(ContentOrder))		//C3
	  max(i in Items_by_Content[c]) X[i] < min(j in Items_by_Content[next(ContentOrder, c)]) X[j];
        
    forall(c in ContentOrder) 	//C4
	  forall(i,j in Items_by_Content[c] : i != j)
 		(Item_AvgPValue[i] >= Item_AvgPValue[j] + Epsilon) => (X[i] < X[j]);
     	      
	forall(s in StimulusIDs)	//C5
	  forall(i,j in Items_by_StimulusID[s] : i != j) 	  	
	  	((i.pValue >= j.pValue + Epsilon) && (X[i] > X[j])) => (R_PValueSeq[i][j] == 1);		//count compromise


    forall(a in Answerkeys)		
	  forall(i in Items : i.answerkey == a)
	    forall(p in Positions)
	      (X[i]==p) => (V[a][p]==1);
	
	forall(a in Answerkeys)   //C6
	  forall(p in 1..N-M_Answerkey)
	    (sum(q in p..p+M_Answerkey) V[a][q] >= M_Answerkey+1) => (R_AnswerkeySeq[a][p]==1);		//count compromise

}



main{  
  thisOplModel.generate(); 
  var myModel = thisOplModel;

  cp.startNewSearch();
  while (cp.next()){
    var after = new Date();    
  	writeln((after.getTime()-myModel.beforeTime)/1000, "\t", cp.getObjValue());
  }    
  cp.end();
  
//  cp.solve();
  writeln("----------items-----------")
  for(var p in myModel.Positions)
  	for(var i in myModel.Items) {
  	    var sInfo;
  		if (i.stimulusID =="") {
  		  	sInfo = i.pValue
    	} else {
    	  	sInfo = Math.round(myModel.AvgPValue[i.stimulusID] * 10000)/10000;
     	}    	    		
  		if (myModel.X[i]==p) writeln(p, "\t", i.itemID, "\t", i.stimulusID, "\t", i.answerkey, "\t", Math.round(i.pValue*10000)/10000, "\t", sInfo , "\t", i.content, "\t");
    }
       	
   writeln("\nrelaxation - answerkey sequence ");
   for(var c in myModel.Answerkeys)
   	for(p in myModel.Positions) {
		if (myModel.R_AnswerkeySeq[c][p] == 1) writeln("answerkey=", c, "\tPosition=", p);
    }   	  
   	
   writeln("\nrelaxation - within stimulus item p-value sequence ");
   for(var i1 in myModel.Items)
   	for(var i2 in myModel.Items){
   		if (myModel.R_PValueSeq[i1][i2]==1) writeln("item1=", i1, "\titem2=", i2);
    }   	  
}
