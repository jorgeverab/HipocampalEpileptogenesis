#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
//////////***************************************/////////////////////////////////////
//Modified from MasterBootsTrap procedure
//This procedure requires
//BootstrapMonte_apr302020
//*********************************************
//***************INSTRUCTIONS******************
//Run simulations with BootstrapMonte() to run ALL combination of simulations
// Algorithm:
//1. Use BootstrapMonte(TagBoots) to run the 110 possible combinations. It will create result waves with all the parameters
//		-it does impedance analysis
//		-it stores result waves inside an independent folder
//2. Use MonteSimRepetitions(tagMonte,tagBoots,numcells,numrepet) to run Montecarlo simulations //It uses MonteSimCells(numcells,tagBoots) to run the simulaitons
//3. Run simulations at 1 pA below reaching spike threhold (delta V 4-5 mV) and one sim reaching spikes
//
//*********************************************
//These things below were fixed and now is not necessary use them. I leave them just in case.
//To fix parameters values
//PatchingDeltaV() //sometimes is not written
//PatchingPhi() //old verions had an error writing phase lag
//CollectingVariable(VarName,tagsim,indexa,indexb) to collect fixed values into summary waves
//////////***************************************/////////////////////////////////////
////***********************************/////
//MonteSimRepetitions(tagMonte,tagBoots,numcells,numrepet)
//WriteAVGdata(tagmonte)
Function MonteSimRepetitions(tagMonte,tagBoots,numcells,numrepet)

string tagMonte //to tag output waves. It CAN'T be empty, as it will match with waves used within the simulation
string tagBoots//to identify waves results from Bootstrap simulations. It does not include Dep or Sup 
variable numcells //cells per repetitions
variable numrepet//number of repetitions. 

String nom1,nom2,nom3

variable i,j,res,nores,resper,noresper,n,ranval
Variable/G simnum,qvalue,CellIndex



//make wave results for depolarized condition
nom1=TagMonte+"Dep"
MakeResultWaves(nom1)

//make wave results for suprathreshold condition
//nom2=TagMonte+"Sup"
//MakeResultWaves(nom2)

j=0
SimNum=1


//Loop for montecarlo simulations
for(i=0;i<=numrepet;i+=1)
	
	MonteSimCells(numcells,tagBoots)
	
	//Writing AVG results Depo
	WriteResultMonteAVG(nom1,"Dep")
	
	
	//Writing AVG results Supra
	//WriteResultMonteAVG(nom2,"Sup")

endfor

//WriteAVGdata(tagmonte)
Sendtofolder(tagmonte)

End function 

////***********************************/////

Function MonteSimCells(numcells,tagBoots) //works well

variable numcells//number of cells for each simulation: 20 in BBBd experiments
string TagBoots //to identify result waves from Bootstrap simulations

String nom1,nom2,nom3,tagsim

variable i,j,res,nores,resper,noresper,n,ranval
Variable/G simnum,qvalue,CellIndex

//make wave results for depolarized condition
nom1="Dep"
MakeResultWaves(nom1)

//make wave results for suprathreshold condition
nom2="Sup"
MakeResultWaves(nom2)

nom3=tagBoots+"Dep"

make/O/N=(numcells) $"TempIndex"
wave wtemp=$"TempIndex"

j=0
res=0
nores=0
SimNum=1

//Loop for GNaP, 11 values
for(i=0;i<numcells;i+=1)
	
		//getting random value between 1 and 110
		
		ranval=enoise(110) //ran num between ± 110.. Gets index between 0 and 109.. tested!
		
		if(ranval==110)
			
			ranval=14.9 //to avoid having an index of 110 (range will go from 0 to 109)
		
		endif
		
		CellIndex=floor(sqrt(ranval*ranval))// random index between 0 and 109
		Simnum=CellIndex
		//print cellindex
		wtemp[i]=cellindex
		
		//loadingvalues from TABLE RESULTS simulation corresponding to CellIndex
		LoadingResultValues(CellIndex,nom3) //deltaVm,rin,vmavg,qvalue,fr,zmax,phi6hz,phifR,Spkthre,Vmperi,SpkNum
		//nom3 must include Dep or Sup
		
		//Writing results from simulation index "cellindex"
		WriteResultWaves("Dep")
		//nom3 must include Dep or Sup
	
endfor
	

End function 

//////////***************************************/////////////////////////////////////
//It will use the result wave from each montecarlo simulation to compute the AVG value and store them in AVG waves
Function WriteResultMonteAVG(TagMonte,tagSim)// It writes the AVG values from each Montecarlo simulations. Waves are created by MakeResultWaves and apropiate Tag

//WriteResultMonteAVG(nom1,"Dep")
string tagMonte //it must incorporate the tag "dep" (depolarized) or "sup" (suprathreshold) plus a name before.. tagmonte="TestDep"
string TagSim // Dep or Sup
variable/G SimNum //simulation number

//Variable/G deltaVm,Rin,vmavg,qvalue,fr,zmax,phi6hz,phifR,Spkthre,Vmperi,SpkNum

String nomA,nomB,nom1,nom2,nom3,nom4,nom5,nom6,nom7,nom8,nom9,nom10
String nom11,nom12,nom13,nom14,nom15,nom16,nom17,nom18,nom19,nom20,nom21,nom22
String nom23,nom24,nom25,nom26,nom27,nom28,nom29,nom30

//deltaVm,rin,vmavg,qvalue,fr,zmax,phi6hz

//***********************************Calling result waves to be writen***********************************

nomA="ResRatio_"+Tagmonte
wave wResRatio=$nomA

//1.DeltaV waves
nom1="DeltaVRes_"+TagMonte
wave wDVRes=$nom1
nom2="DeltaVNores_"+TagMonte
wave wDVNores=$nom2

//2.Rin waves
nom3="RinRes_"+TagMonte
wave wRinRes=$nom3
nom4="RinNores_"+TagMonte
wave wRinNores=$nom4

//3.VmAvg waves
nom5="VmRes_"+TagMonte
wave wVmRes=$nom5
nom6="VmNores_"+TagMonte
wave wVmNores=$nom6

//4.Q waves
nom7="QRes_"+tagMonte
wave wQRes=$nom7
nom8="QNores_"+tagMonte
wave wQNores=$nom8

//5. fr waves
nom9="fRRes_"+tagMonte
wave wfRRes=$nom9
nom10="fRNores_"+tagMonte
wave wfRNores=$nom10

// 6.Zmax waves
nom11="ZmaxRes_"+tagMonte
wave wZmaxRes=$nom11
nom12="ZmaxNores_"+tagMonte
wave wZmaxNores=$nom12

//7.Phi6Hz waves
nom13="Phi6Res_"+tagMonte
wave wPhi6Res=$nom13
nom14="Phi6Nores_"+tagMonte
wave wPhi6Nores=$nom14

//phifR,Spkthre,Vmperi,SpkNum

//8.PhifR waves
nom15="PhifRRes_"+tagMonte
wave wPhifRRes=$nom15
nom16="PhifRNores_"+tagMonte
wave wPhifRNores=$nom16

// 9.Spk Thr waves
nom17="ThrRes_"+tagMonte
wave wThrRes=$nom17
nom18="ThrNores_"+tagMonte
wave wThrNores=$nom18

//10. VmPeri waves
nom19="PeriRes_"+tagMonte
wave wPeriRes=$nom19
nom20="PeriNores_"+tagMonte
wave wPeriNores=$nom20

// 11.spks waves
nom21="SpksRes_"+tagMonte
wave wSpksRes=$nom21
nom22="SpksNores_"+tagMonte
wave wSpksNores=$nom22

// 12.GNaP
nom23="GNaPRes_"+tagMonte
wave wGNaPRes=$nom23
nom24="GNaPNores_"+tagMonte
wave wGNaPNores=$nom24

// 13.GM
nom25="GMRes_"+tagMonte
wave wGMRes=$nom25
nom26="GMNores_"+tagMonte
wave wGMNores=$nom26

// 14.GL
nom27="GLRes_"+tagMonte
wave wGLRes=$nom27
nom28="GLNores_"+tagMonte
wave wGLNores=$nom28

// 15.GM
nom29="GhRes_"+tagMonte
wave wGhRes=$nom29
nom30="GhNores_"+tagMonte
wave wGhNores=$nom30

//Writing data (splitted in two just to make it less messi)
		
//Resonant waves
insertpoints 0,1,wResRatio,wDVRes,wRinRes,wVmRes,wQRes,wfRRes,wZmaxRes,wPhi6Res
insertpoints 0,1,wPhifRRes,wThrRes,wPeriRes,wSpksRes,wGNaPRes,wGMRes,wGLRes,wGhRes

wResRatio[0]=returnResRatio(tagsim) //This works
wDVRes[0]=returnavg("DeltaVRes",tagsim)
wRinRes[0]=returnavg("RinRes",tagsim)
wVmRes[0]=returnavg("VmRes",tagsim)
wQRes[0]=returnavg("QRes",tagsim)
wfRRes[0]=returnavg("fRRes",tagsim)
wZmaxRes[0]=returnavg("ZmaxRes",tagsim)
wPhi6Res[0]=returnavg("Phi6Res",tagsim)
wPhifRRes[0]=returnavg("PhifRRes",tagsim)
wThrRes[0]=returnavg("ThrRes",tagsim)
wPeriRes[0]=returnavg("PeriRes",tagsim)
wSpksRes[0]=returnavg("SpksRes",tagsim)		
wGNaPRes[0]=returnavg("GNaPRes",tagsim)						
wGMRes[0]=returnavg("GMRes",tagsim)						
wGLRes[0]=returnavg("GLRes",tagsim)						
wGhRes[0]=returnavg("GhRes",tagsim)						
	
//Nonresonant waves	
insertpoints 0,1,wDVNores,wRinNores,wVmNores,wQNores,wfRNores,wZmaxNores,wPhi6Nores
insertpoints 0,1,wPhifRNores,wThrNores,wPeriNores,wSpksNores,wGNaPNores,wGMNores,wGLNores,wGhNores

wDVNoRes[0]=returnavg("DeltaVNoRes",tagsim) //This works
wRinNoRes[0]=returnavg("RinNoRes",tagsim)
wVmNoRes[0]=returnavg("VmNoRes",tagsim)
wQNoRes[0]=returnavg("QNoRes",tagsim)
wfRNoRes[0]=returnavg("frNoRes",tagsim)
wZmaxNoRes[0]=returnavg("ZmaxNoRes",tagsim)
wPhi6NoRes[0]=returnavg("Phi6NoRes",tagsim)
wPhifRNoRes[0]=returnavg("PhifRNoRes",tagsim)
wThrNoRes[0]=returnavg("ThrNoRes",tagsim)
wPeriNoRes[0]=returnavg("PeriNoRes",tagsim)
wSpksNoRes[0]=returnavg("SpksNoRes",tagsim)
wGNaPNores[0]=returnavg("GNaPNores",tagsim)						
wGMNores[0]=returnavg("GMNores",tagsim)						
wGLNores[0]=returnavg("GLNores",tagsim)						
wGhNores[0]=returnavg("GhNores",tagsim)						
				
End function
//////////***************************************/////////////////////////////////////
Function returnResRatio(tagsim)

string tagsim

string nom1,nom2

variable i,j,k

nom1="QRes_"+tagsim
nom2="QNoRes_"+tagsim

k=numpnts($nom1)/(numpnts($nom1)+numpnts($nom2))

return k

end
//////////***************************************/////////////////////////////////////
Function ReturnAVG(wavetag,tagsim) //to be used on WriteResultMonteAVG(TagMonte,tagSim)

string wavetag// as in "SpksNores_"+tagsim... "SpkNores" is wavetag
string tagsim //Dep or Sup

string nom1

variable i,j,k

nom1=wavetag+"_"+tagsim
wave wnom1=$nom1

wavestats/Q wnom1

return V_avg

end

//////////***************************************/////////////////////////////////////

//Asign values to G/variables from data stored in waves
Function LoadingResultValues(index,tagBoots) //deltaVm,rin,vmavg,qvalue,fr,zmax,phi6hz,phifR,Spkthre,Vmperi,SpkNum

variable index //from 0 to 109
string tagBoots// to identify waves from Bootstrap simulation

variable/G SimNum //simulation number

Variable/G deltaVm,Rin,vmavg,qvalue,fr,zmax,phi6hz,phifR,Spkthre,Vmperi,SpkNum,GNaP,GM,GLeak,Gh

String nomA,nomB,nom1,nom2,nom3,nom4,nom5,nom6,nom7,nom8,nom9,nom10
String nom11,nom12,nom13,nom14,nom15,nom16,nom17,nom18,nom19,nom20,nom21,nom22,nom23,nom24,nom25

//deltaVm,rin,vmavg,qvalue,fr,zmax,phi6hz

//1.DeltaV waves
nom1="DeltaV_"+tagBoots
wave wDV=$nom1

//2.Rin waves
nom3="Rin_"+tagBoots
wave wRin=$nom3

//3.VmAvg waves
nom5="Vm_"+tagBoots
wave wVm=$nom5

//4.Q waves
nom7="Q_"+tagBoots
wave wQ=$nom7

//5. fr waves
nom9="fR_"+tagBoots
wave wfR=$nom9

// 6.Zmax waves
nom11="Zmax_"+tagBoots
wave wZmax=$nom11

//7.Phi6Hz waves
nom13="Phi6_"+tagBoots
wave wPhi6=$nom13

//8.PhifR waves
nom15="PhifR_"+tagBoots
wave wPhifR=$nom15

// 9.Spk Thr waves
nom17="Thr_"+tagBoots
wave wThr=$nom17

//10. VmPeri waves
nom19="Peri_"+tagBoots
wave wPeri=$nom19

// 11.spks waves
nom21="Spks_"+tagBoots
wave wSpks=$nom21

// 12.GNaP
nom22="GNaP_"+tagBoots
wave wGNaP=$nom22

// 13.GM
nom23="GM_"+tagBoots
wave wGM=$nom23

// 14.GNaP
nom24="GL_"+tagBoots
wave wGL=$nom24

// 15.Gh
nom25="Gh_"+tagBoots
wave wGh=$nom25


//Writing data

deltaVm=wDV[index]
rin=wRin[index]
vmavg=wVm[index]
qvalue=wQ[index]
fr=wfR[index]
zmax=wZmax[index]
phi6hz=wPhi6[index]
phifr=wPhifR[index]
spkthre=wThr[index]
vmperi=wPeri[index]
spknum=wSpks[index]
GNaP=wGNaP[index]
GM=wGM[index]
GLeak=wGL[index]
Gh=wGh[index]
						

End function


//////////***************************************/////////////////////////////////////