/*********************************************
 * OPL 12.3 Model
 * Author: jie_li
 *
 * Note: This is only the ATFG for one stage in the multistage Shadow Test, not the complete run of the multistage shadow test. 
 *
 *********************************************/
 

using CP;  
float Epsilon = 1e-6;

tuple Item {
	int administeredPosition;	//1,2,...- administered position; 0 - not administered but in shadow test;
	string itemID;
	string stimulusID;
	float itemInfo;
};

ordered {Item} Items = {
<0, "307947", "34082", 1.48958>,
<0, "307949", "34082", 0.0854966>,
<0, "308419", "34103", 0.764026>,
<0, "308427", "34103", 0.386852>,
<0, "308421", "34103", 0.297889>,
<0, "308429", "34103", 0.22395>,
<0, "308505", "34085", 0.484795>,
<0, "308517", "34085", 0.349816>,
<0, "308509", "34085", 0.285455>,
<0, "308511", "34085", 0.2757>,
<0, "308503", "34085", 0.224503>,
<0, "308513", "34085", 0.166181>,
<0, "307376", "34075", 0.779636>,
<0, "307372", "34075", 0.503783>,
<0, "307370", "34075", 0.18632>,
<0, "307366", "34075", 0.182204>,
<0, "307364", "34075", 0.0860112>,
<0, "307374", "34075", 0.0302978>,
<0, "308407", "34096", 0.703893>,
<0, "308415", "34096", 0.33398>,
<0, "308411", "34096", 0.185846>,
<0, "308413", "34096", 0.163392>,
<0, "308409", "34096", 0.158218>,
<0, "308417", "34096", 0.149162>,
<0, "307534", "", 0.0152136>
};


{string} StimulusIDs = union(i in Items : i.stimulusID != "" ) {i.stimulusID};
{Item} Items_by_StimulusID[s in StimulusIDs] = union (i in Items : i.stimulusID == s) {i};
float StimulusInfo[s in StimulusIDs] = ( sum(i in Items : i.stimulusID == s) i.itemInfo ) / card(Items_by_StimulusID[s]);
{string} NotAdministeredStimulusIDs = StimulusIDs diff (union(i in Items : i.administeredPosition > 0) {i.stimulusID});
{Item} NotAdministeredStandAloneItems = union(i in Items : i.administeredPosition == 0 && i.stimulusID == "") {i};

int N = card(Items);
range Positions = 1..N ;
dvar int X[Items] in Positions;

subject to {
  
	allDifferent(X);


	forall(i in Items : i.administeredPosition > 0)
	  X[i] == i.administeredPosition;     
	      
	forall(s in StimulusIDs)
	  forall(ordered i,j in Items_by_StimulusID[s]) {	  	
	  	abs(X[i] - X[j]) <= card(Items_by_StimulusID[s]) - 1;	  	  	
	  	((i.administeredPosition==0) && (j.administeredPosition==0) && (i.itemInfo >= j.itemInfo + Epsilon)) => (X[i] < X[j]);
	  	((i.administeredPosition==0) && (j.administeredPosition==0) && (j.itemInfo >= i.itemInfo + Epsilon)) => (X[i] > X[j]);	  	
	}	
		
	forall(ordered i,j in NotAdministeredStandAloneItems) {
	  (i.itemInfo >= j.itemInfo + Epsilon) => (X[i] < X[j]);
	  (j.itemInfo >= i.itemInfo + Epsilon) => (X[i] > X[j]);	  
 	}
 	  
	forall(ordered s,t in NotAdministeredStimulusIDs)
	  forall(i in Items_by_StimulusID[s])
	    forall(j in Items_by_StimulusID[t]) {
	    	(StimulusInfo[s] >= StimulusInfo[t] + Epsilon) => X[i] < X[j];
	    	(StimulusInfo[t] >= StimulusInfo[s] + Epsilon) => X[i] > X[j];
		}
	  	  
	forall(i in NotAdministeredStandAloneItems )
	  forall(s in NotAdministeredStimulusIDs)
	    forall(j in Items_by_StimulusID[s]) {
	      (i.itemInfo >= StimulusInfo[s] + Epsilon) => X[i] < X[j];
	      (StimulusInfo[s] >= i.itemInfo + Epsilon) => X[i] > X[j];	      
     	}	      	
			
}


//main{  
//  thisOplModel.generate(); 
//  var myModel = thisOplModel;
//
//  cp.solve();
//  for(var p in myModel.Positions)
//  	for(var i in myModel.Items)
//  		if (myModel.X[i]==p) writeln(p, "-----", i);
//  			  
//}

