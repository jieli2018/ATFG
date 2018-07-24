/*********************************************
 * OPL 12.3 Model
 * Author: jie_li
 *********************************************/
using CPLEX;

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
 
int M = card(Items); //big_M
int N = card(Items);
range Positions = 1..N;

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

{Item} Items_by_Content[c in ContentOrder] = union (i in Items : i.content == c) {i};
int Num_Items_by_Content[c in ContentOrder] = card(Items_by_Content[c]);
int P_start_by_Content[ContentOrder]=[];
execute {
  var tmp_p= 0
  for (var tmp_c in ContentOrder){
    P_start_by_Content[tmp_c] = tmp_p + 1;
    tmp_p = tmp_p + Num_Items_by_Content[tmp_c];
  }    
}  

{string} Answerkeys = union(i in Items : i.answerkey != "") {i.answerkey};
{Item} Items_by_Answerkey[a in Answerkeys] = union(i in Items : i.answerkey == a) {i};



dvar boolean X[Items][Positions];
dvar boolean Y[StimulusIDs][Positions];
dvar boolean R_pValueSeq[StimulusIDs][Positions][Positions][Positions];
dvar boolean R_AnswerkeySeq[Answerkeys][Positions];


dexpr int total_R_pValueSeq = sum(s in StimulusIDs, sp in Positions, ip1 in Positions, ip2 in Positions) R_pValueSeq[s][sp][ip1][ip2];
dexpr int total_R_AnswerkeySeq = sum(a in Answerkeys, p in Positions) R_AnswerkeySeq[a][p];
dexpr int modelobj = 1 * total_R_AnswerkeySeq + 10 * total_R_pValueSeq;		// notice: T2 + T1

minimize modelobj;

subject to {
  
forall(i in Items) sum(p in Positions) X[i][p] == 1;	//C1 
forall(p in Positions) sum(i in Items) X[i][p] == 1;	//C1
  
forall(s in StimulusIDs) sum(p in Positions) Y[s][p] == 1;		//C1
forall(s1 in StimulusIDs, s2 in StimulusIDs, p in Positions : s1 > s2) Y[s1][p] + Y[s2][p] <= 1;	//C1 


forall(s in StimulusIDs) {			
  forall(sp in N-card(Items_by_StimulusID[s])+1+1..N)	//C2
    Y[s][sp] == 0;
    
  forall(sp in 1..N-card(Items_by_StimulusID[s])+1) {		//C2
    card(Items_by_StimulusID[s])*Y[s][sp] <= sum(i in Items_by_StimulusID[s], ip in sp..sp+card(Items_by_StimulusID[s])-1) X[i][ip]; 
	
	forall(ip1, ip2 in sp..sp+card(Items_by_StimulusID[s])-1: ip1 < ip2) {		//C5
		sum(i in Items_by_StimulusID[s]) i.pValue*X[i][ip2] - sum(i in Items_by_StimulusID[s]) i.pValue*X[i][ip1] + M * Y[s][sp] <= M + R_pValueSeq[s][sp][ip1][ip2] + Epsilon;
 	}	   	      		
  }    
  
}



forall(c in ContentOrder) {
  sum(i in Items_by_Content[c], p in P_start_by_Content[c]..P_start_by_Content[c]+Num_Items_by_Content[c]-1) X[i][p] == Num_Items_by_Content[c];	//C3
  
  forall(p in P_start_by_Content[c]..P_start_by_Content[c]+Num_Items_by_Content[c]-1-1) 	//C4
  	sum(i in Items_by_Content[c]) Item_AvgPValue[i]*X[i][p+1] - sum(i in Items_by_Content[c]) Item_AvgPValue[i]*X[i][p] <= Epsilon;
}
 


forall(a in Answerkeys)	//C6
  forall(p in 1..N-M_Answerkey) 
  	sum(i in Items_by_Answerkey[a], ap in p..p+M_Answerkey) X[i][ap] <= M_Answerkey + R_AnswerkeySeq[a][p];
  

  
}  


execute {  
  var after = new Date();    
  writeln((after.getTime()- beforeTime)/1000, "\t", modelobj);
}  



//main{  
//  thisOplModel.generate(); 
//  var myModel = thisOplModel;
////  cplex.exportModel("testformat.lp"); 
//
//	
//  if (cplex.solve()){
//	writeln("----------items-----------")
//    for (var p in myModel.Positions) {
//      for(var i in myModel.Items) {
//  	    var sInfo;
//  		if (i.stimulusID =="") {
//  		  	sInfo = i.pValue
//    	} else {
//    	  	sInfo = Math.round(myModel.AvgPValue[i.stimulusID] * 10000)/10000;
//     	}    	    		
//  		if (myModel.X[i][p]==1) writeln(p, "\t", i.itemID, "\t", i.stimulusID, "\t", i.answerkey, "\t0.", Math.round(i.pValue*10000), "\t", sInfo , "\t", i.content, "\t");
//      }
//	}
//	
//	writeln("----------stimulus-----------")
//	for (p in myModel.Positions) {
// 	  for (var s in myModel.StimulusIDs) {
//        if (myModel.Y[s][p]==1) writeln(p, "\t", s);
//      } 	    
// 	}	        
//            
//	writeln("");
//	writeln("total_R_pValueSeq = ", myModel.total_R_pValueSeq);
//	for(s in myModel.StimulusIDs){
//		for(var sp in myModel.Positions){
//			for(var ip1 in myModel.Positions){
//				for(var ip2 in myModel.Positions) {
//				  if (myModel.R_pValueSeq[s][sp][ip1][ip2]==1) {
//      			  	writeln(s,"\t",sp,"\t",ip1,"\t",ip2);
//      			  }				    
//    			}				  
//   			}
// 		}
//	}    					
//
//    writeln("\nrelaxation - answerkey sequence ");
//    for(var a in myModel.Answerkeys)
//   	  for(p in myModel.Positions) {
//		if (myModel.R_AnswerkeySeq[a][p] == 1) writeln("answerkey=", a, "\tPosition=", p);
//    }  
//
//  } else { writeln("Problem Infeasible!"); }    
//  		
//}  
//
