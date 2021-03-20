#pragma rtGlobals=3		// Use modern global access method and strict wave access.
//////////***************************************/////////////////////////////////////
//Modified from MasterBootsTrap procedure
//This procedure requires
//BootstrapMonte_apr302020
//Simulation_BootsTuning_apr202020.ipf as the neuronal model to do simulations
//BootstrapImpedance_mar292020.ipf to do impedance analysis
//SpikingProb_SimulaBoots_mar2020.ipf to measure threshold and firing
//*********************************************
//***************INSTRUCTIONS******************
//1. Use BootstrapMonte(TagBoots) to run the 110 possible combinations. It will create result waves with all the parameters
//		-it does impedance analysis
//		-it stores result waves inside an independent folder

//Runs all GNaP and IM combinations and stores result values in waves having TagBoots (plus "dep" or "sup").
//It does not separate in Res and Non Res. that is job of montecarlo simulations
//*********************************************
Function BootstrapMonte(TagBoots)

string Tagboots// tag for output waves

variable timerRefNum,elapsedtime
TimerRefNum = startMSTimer


variable n//number of simulations

String nom1,nom2,nom3

//Experimental values of GMaP and GM
Variable/G GNaP,GM,qvalue,Rin,phi6hz
Make/O/N=11 $"GmaxNaPExpData"
wave GNaPlist=$"GmaxNaPExpData"
GNaPlist={3.92,2.96,4.88,6.04,5.16,5.87,4.79,6.8,5.84,7.53,7.45}

Make/O/N=10 $"GmaxMExpData"
wave GMlist=$"GmaxMExpData"
GMlist={3.95,19.52,4.96,7.33,24.1,34.81,6.06,7.49,4.5,6.91}

variable i,j,res,nores,resper,noresper,k
Variable/G simnum

//make wave results for depolarized condition
nom1=tagBoots+"Dep"
MakeResultWavesBoots(nom1)

//make wave results for suprathreshold condition
//nom2=tagBoots+"Sup"
//MakeResultWavesBoots(nom2)

j=0
res=0
nores=0
SimNum=1

//Loop for GNaP, 11 values
for(i=0;i<=10;i+=1)
	
	//Loop for GM, 10 values
	for(k=0; k<=9; k+=1)
	
		//getting random value between 1 and 10
		GNaP=GNaPlist[i]//*0.9
	
		GM=1.8*GMlist[k]*1.4
	
		Print "Simulation #",simnum,"out of ",n, "GNaP=",GNaP,"nS","GM=",GM,"nS"
		SimulateThis(GNaP,GM,tagBoots)

		SimNum+=1
	
		//quatification of resonance
		if(qvalue>=1.1)
	
			res+=1
		
		else
		
			nores+=1

		endif
	
	endfor
	
endfor

//Sendtofolder(nom1)
//Sendtofolder(nom2)

resper=100*res/(res+nores)
noresper=100*nores/(res+nores)

Print "----------------------------"
Print "******Simulation Done*******"
Print "Res=",res,";",resper,"%"
Print "NonRes=",nores,";",noresper,"%"
Print "----------------------------"

elapsedtime=stopMSTimer(timerRefNum)
print "Simulation time: ",elapsedtime*1e-6/60, " s"

End 

//////////***************************************/////////////////////////////////////

Function SimulateThis(GNaP,GM,tagsim)

Variable GNaP,GM
String tagsim

Variable/G SimNum //simulation number to identify the simulation

variable/G zapA,Iholding,Spkthre,Vmperi,SpkNum
variable timerRefNum,elapsedtime
string SimTag//simulationtag
string nom1,nom2,nom3,nom4,nom5

TimerRefNum = startMSTimer

//Simulating
Print "Getting ZAP amplitude..."
ZAP_amplitude(GNaP,GM) //this function set zapA and Iholding to start simulation
Print "Getting I holding..."
DepolarizationProtocol(GNaP,GM) //this function depolarize the cell and finds the Iholding for suprathreshold and depolarized (Iholding-1) potentials

//Since zapA and Iholding are global variables, are updated automatically

//	//1.suprathreshold simulation
//	Print "Simulating suprathreshold condition"
//	simular("",10,zapA,Iholding,0,0,GNaP,GM,-5)
//		
//		//Analyzing simulation
//		SimTag="Na"+num2str(floor(GNaP))+"M"+num2str(floor(GM))+"SupS"+num2str(simnum)
//		nom1=SimTag+"Vm"
//
//		Analizar(simTag) //tagwave defines the name of outputwaves that are all saved
//		spk_finder($nom1,SimTag) //tagwave defines the name of outputwaves that are all saved
////
////		//Saving data per simulation
//		nom4=tagsim+"Sup"//suprathreshold
//		WriteResultWavesBoots(nom4)
//		SavingData(SimTag,GNaP,GM)
//		SendtoFolder(SimTag)



	//2.depolarized simulation
	Print "Simulating depolarized condition"
	SimTag="Na"+num2str(floor(GNaP))+"M"+num2str(floor(GM))+"DepoS"+num2str(simnum)
	simular("",10,zapA,Iholding-1,0,0,GNaP,GM,-10)


		//Analyzing
		Analizar(SimTag) //tagwave defines the name of outputwaves that are all saved
		Spkthre=0
		Vmperi=0
		SpkNum=0
		
		//Saving data per simulation
		nom5=tagsim+"Dep"//depolarized potential
		WriteResultWavesBoots(nom5) //Writes results in the general Res and Nonres family waves (Rin, fR, etc). Are kept in root
		SavingData(SimTag,GNaP,GM) //writes parameters of each simularion, then goes to each folder
		SendtoFolder(SimTag) //send all related waves to a folder

elapsedtime=stopMSTimer(timerRefNum)
print "Simulation time: ",elapsedtime*1e-6, " s"

end function
//////////***************************************/////////////////////////////////////
Function SavingData(Wavetag,GNaP,GM)

String Wavetag
Variable GNaP,GM

variable/G cm,ena,ek,temp,eleak,gleak,gh,eh,gnahh,gkhh,Iholding,zapA,deltaVm,rin,vmavg,qvalue,fr,zmax,phi6hz,phifR,Spkthre,Vmperi,SpkNum

SaveSimBoots(wavetag,cm,ena,ek,temp,eleak,gleak,gh,eh,gnap,gm,gnahh,gkhh,Iholding,zapA,deltaVm,rin,vmavg,qvalue,fr,zmax,phi6hz,phifR,Spkthre,Vmperi,SpkNum)

End
//////////***************************************/////////////////////////////////////
Function SendtoFolder(Wavetag)

string wavetag

string nom1,nom2,nom3,nom4
variable i,j,k,n

nom1="*"+wavetag+"*"
nom2=wavelist(nom1,",","")

n=itemsinlist(nom2,",")

newdatafolder/O $wavetag

for(i=0;i<n;i+=1)

	nom3=":"+wavetag+":"
	nom4=stringfromlist(i,nom2,",")
	movewave $nom4,$nom3

endfor

End
//////////***************************************/////////////////////////////////////


Function DepolarizationProtocol(GNaP,GM)

Variable GNaP,GM

variable/G zapA,Iholding

string nom1,nom2
variable i,j,k,spiking,delay,timezap

delay=-5
timezap=10

//Checking ZapA and Iholding in a complete simulation

//"Fast" (10 pA increments) depolarization to reach spiking regime
spiking=0

Do

	Iholding+=10
	
	simular("",timezap,zapA,Iholding,0,0,GNaP,GM,delay)

	wavestats/Q/R=(0,5) $"vm_wave"
	
	if(V_max>=-30)
	
		spiking=1
		
	endif
	

While(spiking==0)

//"Slow" (3 pA increments) hyperpolarization to go below spike threshold
//The model is already spiking according to Iholding and zapA
spiking=1

Do

	Iholding-=3
	
	simular("",timezap,zapA,Iholding,0,0,GNaP,GM,delay)

	wavestats/Q/R=(0,5) $"vm_wave"
	
	if(V_max<=-30)
	
		spiking=0
		
	endif

While(spiking==1)


//"Slow" (1 pA increments) depolarization to reach spiking regime
//according to previous simulatio, th emodel is not spiking
spiking=0

Do

	Iholding+=1
	
	simular("",timezap,zapA,Iholding,0,0,GNaP,GM,delay)

	wavestats/Q/R=(0,5) $"vm_wave"
	
	if(V_max>=-30)
	
		spiking=1
		
	endif

While(spiking==0)

//At this point, withi these zapA and Iholding, the simulation is 1pA above threshold




End function
//////////***************************************/////////////////////////////////////

Function ZAP_amplitude(GNaP,GM)

variable GNaP,GM

variable/G zapA,Iholding,deltaVm

variable delta,loops1,loops2

RampForHolding(GNaP,GM)
Iholding=ReturnHolding(-58)
//Print "IHolding=",Iholding
zapA=4

loops1=0
loops2=0

//Timer
//variable timerRefNum,elapsedtime
//TimerRefNum = startMSTimer

Do

	//print "Running loop1#",loops1
	//1.simulate ZAP to measure amplitude, 5 seconds
	simular("",5,zapA,Iholding,0,0,GNaP,GM,-0.5)

	wavestats/Q/R=(0,5) $"vm_wave"
	delta=V_max-V_min
	//print delta
	
		if(V_max>=-20)
		
			Iholding-=5
			delta=0

			else
			
			zapA+=5
						
		endif

	loops1+=1
	
While(delta<=4)
//while(loops<4)

//Correcting if delta>5
if(delta>=5)

	Do

		//print "Running loop2#",loops2

		zapA-=2

		//simulate ZAP to measure amplitude, 5 seconds
		simular("",2,zapA,Iholding,0,0,GNaP,GM,-0.5)

		wavestats/Q/R=(0,5) $"vm_wave"
		delta=V_max-V_min
		//print delta
	
While(delta>5)

deltaVm=delta

endif


//print "Loops #=",loops
//print "Delta Vm=",delta
//print "Amp=",ZapA
//print "Iholding=",Iholding

//elapsedtime=stopMSTimer(timerRefNum)
//print "Simulation time: ",elapsedtime*1e-6, " s"

end function

//////////***************************************/////////////////////////////////////
//RampForHolding(GNaP,GM) must be run before
Function CheckingHolding(GNaP,GM,Iholding)// No spikes

variable GNaP,GM,Iholding

variable spiking

spiking=0 //meaning no spiking
simular("",5,5,Iholding,0,0,GNaP,GM,-2)

	wavestats/Q/R=(0,5) $"vm_wave"
	
	if(V_max>=-50) //meaning spiking
	
		spiking=1
		
	endif
	
	return spiking

End function

//////////***************************************/////////////////////////////////////
Function RampForHolding(GNaP,GM)

variable GNaP,GM
string nom1,nom2,nom3

string tagsim
variable Iholding

//1.simulate ramp depolarization
simular("",10,400,-100,2,0,GNaP,GM,-2)
//simular(tagsim,tpulse,ipulse,ioffset,style,savetraces,GNaP,GM,delay)

//2. Getting starting Iholding
//Iholding=ReturnHolding()



End function
//////////***************************************/////////////////////////////////////

Function ReturnHolding(Vm)

variable Vm//The Voltage paired with IHolding

wave vvm=$"Vm_wave"
wave vIstim=$"Istim_wave"

variable i,j,m

for(i=200000;i<=numpnts(vvm);i+=200)

	j=vvm[i]
	m=vIstim[i]
	
	if(j>=Vm) //arbitrary voltage value so set a subthreshold regime according to this model
	
		break
	
	endif

endfor

return m

End
//////////***************************************/////////////////////////////////////

Function WriteResultWaves(tagsim)

string tagsim //it must incorporate the thag "dep" (depolarized) or "sup" (suprathreshold)

variable/G SimNum //simulation number

Variable/G deltaVm,Rin,vmavg,qvalue,fr,zmax,phi6hz,phifR,Spkthre,Vmperi,SpkNum,GNaP,GM,GLeak,Gh

String nomA,nomB,nom1,nom2,nom3,nom4,nom5,nom6,nom7,nom8,nom9,nom10
String nom11,nom12,nom13,nom14,nom15,nom16,nom17,nom18,nom19,nom20,nom21,nom22
String nom23,nom24,nom25,nom26,nom27,nom28,nom29,nom30

//deltaVm,rin,vmavg,qvalue,fr,zmax,phi6hz

//0. Simulation number
nomA="SimNumRes_"+tagsim
wave wSimNumRes=$nomA
nomB="SimNumNores_"+tagsim
wave wSimNumNores=$nomA


//1.DeltaV waves
nom1="DeltaVRes_"+tagsim
wave wDVRes=$nom1
nom2="DeltaVNores_"+tagsim
wave wDVNores=$nom2

//2.Rin waves
nom3="RinRes_"+tagsim
wave wRinRes=$nom3
nom4="RinNores_"+tagsim
wave wRinNores=$nom4

//3.VmAvg waves
nom5="VmRes_"+tagsim
wave wVmRes=$nom5
nom6="VmNores_"+tagsim
wave wVmNores=$nom6

//4.Q waves
nom7="QRes_"+tagsim
wave wQRes=$nom7
nom8="QNores_"+tagsim
wave wQNores=$nom8

//5. fr waves
nom9="fRRes_"+tagsim
wave wfRRes=$nom9
nom10="fRNores_"+tagsim
wave wfRNores=$nom10

// 6.Zmax waves
nom11="ZmaxRes_"+tagsim
wave wZmaxRes=$nom11
nom12="ZmaxNores_"+tagsim
wave wZmaxNores=$nom12

//7.Phi6Hz waves
nom13="Phi6Res_"+tagsim
wave wPhi6Res=$nom13
nom14="Phi6Nores_"+tagsim
wave wPhi6Nores=$nom14

//phifR,Spkthre,Vmperi,SpkNum

//8.PhifR waves
nom15="PhifRRes_"+tagsim
wave wPhifRRes=$nom15
nom16="PhifRNores_"+tagsim
wave wPhifRNores=$nom16

// 9.Spk Thr waves
nom17="ThrRes_"+tagsim
wave wThrRes=$nom17
nom18="ThrNores_"+tagsim
wave wThrNores=$nom18

//10. VmPeri waves
nom19="PeriRes_"+tagsim
wave wPeriRes=$nom19
nom20="PeriNores_"+tagsim
wave wPeriNores=$nom20

// 11.spks waves
nom21="SpksRes_"+tagsim
wave wSpksRes=$nom21
nom22="SpksNores_"+tagsim
wave wSpksNores=$nom22

//12. GNaP
nom23="GNaPRes_"+tagsim
wave wGNaPRes=$nom23
nom24="GNaPNores_"+tagsim
wave wGNaPNores=$nom24


//13. GM
nom25="GMRes_"+tagsim
wave wGMRes=$nom25
nom26="GMNores_"+tagsim
wave wGMNores=$nom26

//14. GLeak
nom27="GLRes_"+tagsim
wave wGLRes=$nom27
nom28="GLNores_"+tagsim
wave wGLNores=$nom28

//15. Gh
nom29="GhRes_"+tagsim
wave wGhRes=$nom29
nom30="GhNores_"+tagsim
wave wGhNores=$nom30



//Writing data
		
		if(qvalue>=1.1)

			insertpoints 0,1,wDVRes,wSimNumRes,wRinRes,wVmRes,wQRes,wfRRes,wZmaxRes
			insertpoints 0,1,wPhi6Res,wPhifRRes,wThrRes,wPeriRes,wSpksRes,wGNaPRes,wGMRes,wGLRes,wGhRes
			
			wSimNumRes[0]=simnum
			wDVRes[0]=deltaVm
			wRinRes[0]=rin
			wVmRes[0]=vmavg
			wQRes[0]=qvalue
			wfRRes[0]=fR
			wZmaxRes[0]=zmax
			wPhi6Res[0]=phi6hz
			wPhifRRes[0]=phifr
			wThrRes[0]=spkthre
			wPeriRes[0]=vmperi
			wSpksRes[0]=spknum
			wGNaPRes[0]=GNaP
			wGMRes[0]=GM
			wGLRes[0]=GLeak
			wGhRes[0]=Gh
						
		else
		
			insertpoints 0,1,wSimNumNores,wDVNores,wRinNores,wVmNores,wQNores,wfRNores,wZmaxNores,wPhi6Nores
			insertpoints 0,1,wPhifRNores,wThrNores,wPeriNores,wSpksNores,wGNaPNores,wGMNores,wGLNores,wGhNores
			
			wSimNumNores[0]=simnum
			wDVNores[0]=deltaVm
			wRinNores[0]=rin
			wVmNores[0]=vmavg
			wQNores[0]=qvalue
			wfRNores[0]=fR
			wZmaxNores[0]=zmax
			wPhi6Nores[0]=phi6hz
			wPhifRNores[0]=phifr
			wThrNores[0]=spkthre
			wPeriNores[0]=vmperi
			wSpksNores[0]=spknum
			wGNaPNores[0]=GNaP
			wGMNores[0]=GM
			wGLNores[0]=GLeak
			wGhNores[0]=Gh
				
		endif

End function

//////////***************************************/////////////////////////////////////
//It doesnt split between Res and non res
Function WriteResultWavesBoots(tagBoots)

string tagBoots //it must incorporate the tag "dep" (depolarized) or "sup" (suprathreshold)

variable/G SimNum //simulation number

Variable/G deltaVm,Rin,vmavg,qvalue,fr,zmax,phi6hz,phifR,Spkthre,Vmperi,SpkNum,GNaP,GM,GLeak,Gh

String nomA,nomB,nom1,nom2,nom3,nom4,nom5,nom6,nom7,nom8,nom9,nom10
String nom11,nom12,nom13,nom14,nom15,nom16,nom17,nom18,nom19,nom20,nom21,nom22

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

//phifR,Spkthre,Vmperi,SpkNum

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

//*******************

//G using recycled number
nom2="GNaP_"+tagBoots
wave wGNaP=$nom2

//GM
nom4="GM_"+tagBoots
wave wGM=$nom4

//GL
nom6="GL_"+tagBoots
wave wGL=$nom6

//Gh
nom8="Gh_"+tagBoots
wave wGh=$nom8

//Writing data
insertpoints 0,1,wDV,wRin,wVm,wQ,wfR,wZmax,wPhi6,wPhifR,wThr,wPeri,wSpks,wGNaP,wGM,wGL,wGh
			
wDV[0]=deltaVm
wRin[0]=rin
wVm[0]=vmavg
wQ[0]=qvalue
wfR[0]=fr
wZmax[0]=zmax
wPhi6[0]=phi6hz
wPhifR[0]=phifr
wThr[0]=spkthre
wPeri[0]=vmperi
wSpks[0]=spknum
wGNaP[0]=GNaP
wGM[0]=GM
wGL[0]=GLeak
wGh[0]=Gh

End function



//////////***************************************/////////////////////////////////////

Function MakeResultWaves(tagsim)

string tagsim

String nomA,nomB,nomC,nom1,nom2,nom3,nom4,nom5,nom6,nom7,nom8,nom9,nom10
String nom11,nom12,nom13,nom14,nom15,nom16,nom17,nom18,nom19,nom20,nom21,nom22
String nom23,nom24,nom25,nom26,nom27,nom28,nom29,nom30

//deltaVm,rin,vmavg,qvalue,fr,zmax,phi6hz

nomC="ResRatio_"+tagsim
Make/O/N=0 $nomC
wave wResRatio=$nomC
wResRatio=0

//0. Simulation number
nomA="SimNumRes_"+tagsim
Make/O/N=0 $nomA
wave wSimNumRes=$nomA
wSimNumRes=0
nomB="SimNumNores_"+tagsim
Make/O/N=0 $nomB
wave wSimNumNores=$nomB
wSimNumNores=0

//1.DeltaV waves
nom1="DeltaVRes_"+tagsim
make/O/N=0 $nom1
wave wDVRes=$nom1
wDVRes=0
nom2="DeltaVNores_"+tagsim
make/O/N=0 $nom2
wave wDVNores=$nom2
wDVNores=0

//2.Rin waves
nom3="RinRes_"+tagsim
make/O/N=0 $nom3
wave wRinRes=$nom3
wRinRes=0
nom4="RinNores_"+tagsim
make/O/N=0 $nom4
wave wRinNores=$nom4
wRinNores=0

//3.VmAvg waves
nom5="VmRes_"+tagsim
make/O/N=0 $nom5
wave wVmRes=$nom5
wVmRes=0
nom6="VmNores_"+tagsim
make/O/N=0 $nom6
wave wVmNores=$nom6
wVmNores=0

//4.Q waves
nom7="QRes_"+tagsim
make/O/N=0 $nom7
wave wQRes=$nom7
wQRes=0

nom8="QNores_"+tagsim
make/O/N=0 $nom8
wave wQNores=$nom8
wQNores=0


//5. fr waves
nom9="fRRes_"+tagsim
make/O/N=0 $nom9
wave wfRRes=$nom9
wfRRes=0
nom10="fRNores_"+tagsim
make/O/N=0 $nom10
wave wfRNores=$nom10
wfRNores=0


// 6.Zmax waves
nom11="ZmaxRes_"+tagsim
make/O/N=0 $nom11
wave wZmaxRes=$nom11
wZmaxRes=0
nom12="ZmaxNores_"+tagsim
make/O/N=0 $nom12
wave wZmaxNores=$nom12
wZmaxNores=0


//7.Phi6Hz waves
nom13="Phi6Res_"+tagsim
make/O/N=0 $nom13
wave wPhi6Res=$nom13
wPhi6Res=0

nom14="Phi6Nores_"+tagsim
make/O/N=0 $nom14
wave wPhi6Nores=$nom14
wPhi6Nores=0

//phifR,Spkthre,Vmperi,SpkNum

//8.PhifR waves
nom15="PhifRRes_"+tagsim
make/O/N=0 $nom15
wave wPhifRRes=$nom15
wPhifRRes=0
nom16="PhifRNores_"+tagsim
make/O/N=0 $nom16
wave wPhifRNores=$nom16
wPhifRNores=0


// 9.Spk Thr waves
nom17="ThrRes_"+tagsim
make/O/N=0 $nom17
wave wThrRes=$nom17
wThrRes=0
nom18="ThrNores_"+tagsim
make/O/N=0 $nom18
wave wThrNores=$nom18
wThrNores=0

//10. VmPeri waves
nom19="PeriRes_"+tagsim
make/O/N=0 $nom19
wave wPeriRes=$nom19
wPeriRes=0
nom20="PeriNores_"+tagsim
make/O/N=0 $nom20
wave wPeriNores=$nom20
wPeriNores=0


// 11.spks waves
nom21="SpksRes_"+tagsim
make/O/N=0 $nom21
wave wSpksRes=$nom21
wSpksRes=0
nom22="SpksNores_"+tagsim
make/O/N=0 $nom22
wave wSpksNores=$nom22
wSpksNores=0

// 12.GNaP
nom23="GNaPRes_"+tagsim
make/O/N=0 $nom23
wave wGNaPRes=$nom23
wGNaPRes=0
nom24="GNaPNores_"+tagsim
make/O/N=0 $nom24
wave wGNaPNores=$nom24
wGNaPNores=0

// 13.GM
nom25="GMRes_"+tagsim
make/O/N=0 $nom25
wave wGMRes=$nom25
wGMRes=0
nom26="GMNores_"+tagsim
make/O/N=0 $nom26
wave wGMNores=$nom26
wGMNores=0

// 14.GL
nom27="GLRes_"+tagsim
make/O/N=0 $nom27
wave wGLRes=$nom27
wGLRes=0
nom28="GLNores_"+tagsim
make/O/N=0 $nom28
wave wGLNores=$nom28
wGLNores=0

// 15.GM
nom29="GhRes_"+tagsim
make/O/N=0 $nom29
wave wGhRes=$nom29
wGhRes=0
nom30="GhNores_"+tagsim
make/O/N=0 $nom30
wave wGhNores=$nom30
wGhNores=0

End function

//////////***************************************/////////////////////////////////////

Function MakeResultWavesBoots(tagBoots)

string tagBoots

String nomA,nomB,nomC,nom1,nom2,nom3,nom4,nom5,nom6,nom7,nom8,nom9,nom10
String nom11,nom12,nom13,nom14,nom15,nom16,nom17,nom18,nom19,nom20,nom21,nom22

//deltaVm,rin,vmavg,qvalue,fr,zmax,phi6hz

//GNaP
nom2="GNaP_"+tagBoots
make/O/N=0 $nom2
wave wGNaP=$nom2
wGNaP=0

//GM
nom4="GM_"+tagBoots
make/O/N=0 $nom4
wave wGM=$nom4
wGM=0

//GL
nom6="GL_"+tagBoots
make/O/N=0 $nom6
wave wGL=$nom6
wGL=0

//Gh
nom8="Gh_"+tagBoots
make/O/N=0 $nom8
wave wGh=$nom8
wGh=0


//1.DeltaV
nom1="DeltaV_"+tagBoots
make/O/N=0 $nom1
wave wDV=$nom1
wDV=0

//2.Rin
nom3="Rin_"+tagBoots
make/O/N=0 $nom3
wave wRin=$nom3
wRin=0

//3.VmAvg
nom5="Vm_"+tagBoots
make/O/N=0 $nom5
wave wVm=$nom5
wVm=0

//4.Q 
nom7="Q_"+tagBoots
make/O/N=0 $nom7
wave wQ=$nom7
wQ=0

//5. fr
nom9="fR_"+tagBoots
make/O/N=0 $nom9
wave wfR=$nom9
wfR=0

// 6.Zmax
nom11="Zmax_"+tagBoots
make/O/N=0 $nom11
wave wZmax=$nom11
wZmax=0

//7.Phi6Hz
nom13="Phi6_"+tagBoots
make/O/N=0 $nom13
wave wPhi6=$nom13
wPhi6=0

//8.PhifR
nom15="PhifR_"+tagBoots
make/O/N=0 $nom15
wave wPhifR=$nom15
wPhifR=0

// 9.Spk Thr
nom17="Thr_"+tagBoots
make/O/N=0 $nom17
wave wThr=$nom17
wThr=0

//10. VmPeri
nom19="Peri_"+tagBoots
make/O/N=0 $nom19
wave wPeri=$nom19
wPeri=0

// 11.spks
nom21="Spks_"+tagBoots
make/O/N=0 $nom21
wave wSpks=$nom21
wSpks=0

End function

//////////***************************************/////////////////////////////////////

Function WriteAVGdata(tagsim)

string tagsim //without "dep" (depolarized) or "sup" (suprathreshold) tag

Variable/G numsim
//string for data waves
String nomA,nomB,nom1,nom2,nom3,nom4,nom5,nom6,nom7,nom8,nom9,nom10
String nom11,nom12,nom13,nom14,nom15,nom16,nom17,nom18,nom19,nom20,nom21,nom22
String nom23,nom24,nom25,nom26,nom27,nom28,nom29,nom30,nom31,nom32,nom33,nom34

//Making AVG result waves
String stg1,stg2,stg3,stg4,stg5

stg1="Params_"+tagsim
make/O/T/N=16 $stg1
wave/T wRestext=$stg1
wRestext={"deltaV","Rin","Vmavg","Q","fR","Zmax","Phi6Hz","PhifR","SpkThr","VmPeri","SpkNum","ResRatio","GNaP","GM","GLeak","Gh"}

//Resonant
stg2="Res_AVG_"+tagsim
make/O/N=16 $stg2
wave wResAVG=$stg2
wResAVG=0

stg3="Res_SD_"+tagsim
make/O/N=16 $stg3
wave wResSD=$stg3
wResSD=0

//Non Resonant
stg4="NoRes_AVG_"+tagsim
make/O/N=16 $stg4
wave wNoResAVG=$stg4
wNoResAVG=0

stg5="NoRes_SD_"+tagsim
make/O/N=16 $stg5
wave wNoResSD=$stg5
wNoResSD=0

//Writing waves-----------------------------

//1.DeltaV waves
nom1="DeltaVRes_"+tagsim
wavestats/Q $nom1
wResAVG[0]=V_avg
wResSD[0]=V_sdev

nom2="DeltaVNores_"+tagsim
wavestats/Q $nom2
wNoResAVG[0]=V_avg
wNoResSD[0]=V_sdev

//2.Rin waves
nom3="RinRes_"+tagsim
wavestats/Q $nom3
wResAVG[1]=V_avg
wResSD[1]=V_sdev

nom4="RinNores_"+tagsim
wavestats/Q $nom4
wNoResAVG[1]=V_avg
wNoResSD[1]=V_sdev

//3.VmAvg waves
nom5="VmRes_"+tagsim
wavestats/Q $nom5
wResAVG[2]=V_avg
wResSD[2]=V_sdev

nom6="VmNores_"+tagsim
wavestats/Q $nom6
wNoResAVG[2]=V_avg
wNoResSD[2]=V_sdev

//4.Q waves
nom7="QRes_"+tagsim
wavestats/Q $nom7
wResAVG[3]=V_avg
wResSD[3]=V_sdev

nom8="QNores_"+tagsim
wavestats/Q $nom8
wNoResAVG[3]=V_avg
wNoResSD[3]=V_sdev

//5. fr waves
nom9="fRRes_"+tagsim
wavestats/Q $nom9
wResAVG[4]=V_avg
wResSD[4]=V_sdev

nom10="fRNores_"+tagsim
wavestats/Q $nom10
wNoResAVG[4]=V_avg
wNoResSD[4]=V_sdev

// 6.Zmax waves
nom11="ZmaxRes_"+tagsim
wavestats/Q $nom11
wResAVG[5]=V_avg
wResSD[5]=V_sdev

nom12="ZmaxNores_"+tagsim
wavestats/Q $nom12
wNoResAVG[5]=V_avg
wNoResSD[5]=V_sdev

//7.Phi6Hz waves
nom13="Phi6Res_"+tagsim
wavestats/Q $nom13
wResAVG[6]=V_avg
wResSD[6]=V_sdev

nom14="Phi6Nores_"+tagsim
wavestats/Q $nom14
wNoResAVG[6]=V_avg
wNoResSD[6]=V_sdev

//8.PhifR waves
nom15="PhifRRes_"+tagsim
wavestats/Q $nom15
wResAVG[7]=V_avg
wResSD[7]=V_sdev

nom16="PhifRNores_"+tagsim
wavestats/Q $nom16
wNoResAVG[7]=V_avg
wNoResSD[7]=V_sdev

// 9.Spk Thr waves
nom17="ThrRes_"+tagsim
wavestats/Q $nom17
wResAVG[8]=V_avg
wResSD[8]=V_sdev

nom18="ThrNores_"+tagsim
wavestats/Q $nom18
wNoResAVG[8]=V_avg
wNoResSD[8]=V_sdev


//10. VmPeri waves
nom19="PeriRes_"+tagsim
wavestats/Q $nom19
wResAVG[9]=V_avg
wResSD[9]=V_sdev

nom20="PeriNores_"+tagsim
wavestats/Q $nom20
wNoResAVG[9]=V_avg
wNoResSD[9]=V_sdev

// 11.spks waves
nom21="SpksRes_"+tagsim
wavestats/Q $nom21
wResAVG[10]=V_avg
wResSD[10]=V_sdev

nom22="SpksNores_"+tagsim
wavestats/Q $nom22
wNoResAVG[10]=V_avg
wNoResSD[10]=V_sdev

// 12.Res ratio
nom23="ResRatio_"+tagsim
wavestats/Q $nom23
wResAVG[11]=V_avg
wResSD[11]=V_sdev

wNoResAVG[11]=1-V_avg
wNoResSD[11]=0

// 13.GNaP
nom24="GNaPRes_"+tagsim
wavestats/Q $nom24
wResAVG[12]=V_avg
wResSD[12]=V_sdev

nom25="GNaPNoRes_"+tagsim
wavestats/Q $nom25
wNoResAVG[12]=V_avg
wNoResSD[12]=V_sdev

// 14.GM
nom26="GMRes_"+tagsim
wavestats/Q $nom26
wResAVG[13]=V_avg
wResSD[13]=V_sdev

nom27="GMNoRes_"+tagsim
wavestats/Q $nom27
wNoResAVG[13]=V_avg
wNoResSD[13]=V_sdev

// 15.GLeak
nom28="GLRes_"+tagsim
wavestats/Q $nom28
wResAVG[4]=V_avg
wResSD[14]=V_sdev

nom29="GLNoRes_"+tagsim
wavestats/Q $nom29
wNoResAVG[14]=V_avg
wNoResSD[14]=V_sdev

// 16.Gh
nom30="GhRes_"+tagsim
wavestats/Q $nom30
wResAVG[15]=V_avg
wResSD[15]=V_sdev

nom31="GhNoRes_"+tagsim
wavestats/Q $nom31
wNoResAVG[15]=V_avg
wNoResSD[15]=V_sdev



edit wRestext,wResAVG,wResSD,wNoResAVG,wNoResSD

End function
///////////////////////////////////////////////////////////////////////////////////////////////////////////
//*******************************************************************************************************
///////////////////////////////////////////////////////////////////////////////////////////////////////////

//To collect new values of a variable into Res and Non Res waves
Function CollectingVariable(VarName,tagsim,indexa,indexb)
//CollectingVariable("Phi6","tag",20,6)
//CollectingVariable("DeltaV","tag",14,0)
//CollectingVariable("Spks","tag",24,10)

String VarName //phi6hz
String tagsim//Ctrl100
Variable indexa// internal, in Params wave inside the folders. of variable within Variable List
Variable indexb// external, in Summary wave in Root. of variable within Variable List

string stg1,stg2,stg3,stg4,stg5,stg6,stg7,stg8,stg9,stg10,stg11
variable var1,var2,var3,numfolder,qval,condition

string folder
variable i,j,k,l,m,n,value,p

//setdatafolder "root:"


//loop to go inside each folder
folder=getdatafolder(1)

numfolder=countobjects(":",4)//count folders inside current folder 
make/O/N=(numfolder) $"temp1"
wave wtemp=$"temp1"

//Loop for Dep folders, first---------------------------------------------------

//Creating name of waves. These waves already exists and need to be rewritten
stg6=Varname+"Res_"+tagsim+"Dep"
Make/O/N=0 $stg6
wave w6=$stg6
w6=0
stg7=Varname+"Nores_"+tagsim+"Dep"
Make/O/N=0 $stg7
wave w7=$stg7
w7=0

k=0
p=0

for(i=0;i<numfolder;i+=1)
	
	stg1=GetIndexedObjName("",4,i)
	setdatafolder $stg1
	
	stg2="ParamsVal"+stg1
	wave w2=$stg2
	stg3="ParamsText"+stg1
	wave/T w3=$stg3
		
	condition=stringmatch(stg1,"*Dep*")	
		
	if(exists(stg2)==1 && condition==1)
	
		qval=w2[17]
		
		if(qval>=1.1) //Res?
			
			insertpoints 0,1,w6
			w6[0]=w2[indexa]	

			else
			
			insertpoints 0,1,w7
			w7[0]=w2[indexa]		
			
		endif
		

	endif	
	//print getdatafolder(0)
	setdatafolder $folder
	
endfor	

//Writing new data values
stg8="Res_AVG_"+tagsim+"Dep"
wave w8=$stg8
stg9="Res_SD_"+tagsim+"Dep"
wave w9=$stg9
stg10="Nores_AVG_"+tagsim+"Dep"
wave w10=$stg10
stg11="Nores_SD_"+tagsim+"Dep"
wave w11=$stg11

wavestats/Q w6
w8[indexb]=V_avg
w9[indexb]=V_sdev

wavestats/Q w7
w10[indexb]=V_avg
w11[indexb]=V_sdev

//Loop for Sup folders ---------------------------------------------------

//Creating name of waves. These waves already exists and need to be rewritten
stg6=Varname+"Res_"+tagsim+"Sup"
wave w6=$stg6
w6=0
stg7=Varname+"Nores_"+tagsim+"Sup"
wave w7=$stg7
w7=0

k=0
p=0

for(i=0;i<numfolder;i+=1)
	
	stg1=GetIndexedObjName("",4,i)
	setdatafolder $stg1
	
	stg2="ParamsVal"+stg1
	wave w2=$stg2
	stg3="ParamsText"+stg1
	wave/T w3=$stg3
		
	condition=stringmatch(stg1,"*Sup*")	
		
	if(exists(stg2)==1 && condition==1)
	
		qval=w2[17]
		
		if(qval>=1.1) //Res?
			
			w6[k]=w2[indexa]	
			k+=1	

			else
			
			w7[p]=w2[indexa]		
			p+=1
			
		endif
		

	endif	
	//print getdatafolder(0)
	setdatafolder $folder
	
endfor	

//Writing new data values
stg8="Res_AVG_"+tagsim+"Sup"
wave w8=$stg8
stg9="Res_SD_"+tagsim+"Sup"
wave w9=$stg9
stg10="Nores_AVG_"+tagsim+"Sup"
wave w10=$stg10
stg11="Nores_SD_"+tagsim+"Sup"
wave w11=$stg11

wavestats/Q w6
w8[indexb]=V_avg
w9[indexb]=V_sdev

wavestats/Q w7
w10[indexb]=V_avg
w11[indexb]=V_sdev


end function	
///////////////////////////////////////////////////////////
//Function extracts the AVG±SD of a variable from the variable list inside each folder (simulation)
Function GetVarfromFolders(index)

Variable index// of variable within Variable List

string stg1,stg2,stg3,stg4,stg5
variable var1,var2,var3,numfolder

string folder
variable i,j,k,l,m,n,value

//setdatafolder "root:"

//loop to go inside each folder
folder=getdatafolder(1)

numfolder=countobjects(":",4)//count folders inside current folder 
make/O/N=(numfolder) $"temp1"
wave wtemp=$"temp1"

//display/W=(50,50,350,220)

for(i=0;i<numfolder;i+=1)
	
	stg1=GetIndexedObjName("",4,i)
	setdatafolder $stg1
	
	stg2="ParamsVal"+stg1
	wave w2=$stg2
	stg3="ParamsText"+stg1
	wave/T w3=$stg3
		
	if(exists(stg2)==1)

		wtemp[i]=w2[index]
		stg4=w3[index]

//			if(operation==1)
//
//				wavestats/Q/R=(-0.1,0) w2
//				w2-=V_avg
//		
//
//			endif
//
//		appendtograph $stg2

	endif	
	//print getdatafolder(0)
	setdatafolder $folder
	
endfor	

	stg5=stg4+"_waveALL"
	rename $"temp1" $stg5

	wavestats/Q wtemp
	print stg4,"=",V_avg,"±",V_sdev


end function	
///////////////////////////////////////////////////////////
Function DisplayfromFolders(tagwave,condition)

String tagwave//other than foldername
Variable condition//0=Dep, 1=Sup

string stg1,stg2,stg3,stg4,stg5
variable var1,var2,var3,numfolder,visitedfolders,added
string code1,code2//for condition

string folder
variable i,j,k,l,m,n,value,supra,depo,include

//setdatafolder "root:"

//loop to go inside each folder
folder=getdatafolder(1)
numfolder=countobjects(":",4)//count folders inside current folder 
visitedfolders=0
added=0

display/W=(50,50,350,220)

supra=0
depo=0

for(i=0;i<numfolder;i+=1)
	
	stg1=GetIndexedObjName("",4,i)
	setdatafolder $stg1
	visitedfolders+=1

	//Getting Dep or Sup, it is in 5th or 6th position, depending if GM has one or 2 digits
	if(condition==0)
	
	include=stringmatch(stg1,"*Dep*")	
	
	endif
	
	if(condition==1)
	
	include=stringmatch(stg1,"*Sup*")	
	
	endif
	
	
	//Wave of interest	
	stg2=stg1+tagwave

	if(exists(stg2)==1 && include==1)

		appendtograph $stg2
		added+=1

	endif	

	//print getdatafolder(0)
	setdatafolder $folder
	
endfor	

print "Folders=",visitedfolders
Print "Added traces=",added

end function	
///////////////////////////////////////////////////////////
//To fix variables that show wrong measurements during the simulation.
//It goes folder by folder doing a new measurement of the parameter. Check traces are correct, with "DisplayfromFolders()"
Function PatchingDeltaV()

Variable/G index=14// Index for deltaVm

string stg1,stg2,stg3,stg4,stg5
variable var1,var2,var3,numfolder

string folder
variable i,j,k,l,m,n,value

//setdatafolder "root:"

//loop to go inside each folder
folder=getdatafolder(1)

numfolder=countobjects(":",4)//count folders inside current folder 
make/O/N=(numfolder) $"temp1"
wave wtemp=$"temp1"

//display/W=(50,50,350,220)

for(i=0;i<numfolder;i+=1)
	
	stg1=GetIndexedObjName("",4,i)
	setdatafolder $stg1
	
	stg2="ParamsVal"+stg1
	wave w2=$stg2
	
	//getting voltage wave
	stg3=stg1+"Vm"
	wave wvoltage=$stg3
		
	if(exists(stg3)==1)

	wavestats/Q wvoltage

		w2[index]=V_max-V_min

	endif	
	//print getdatafolder(0)
	setdatafolder $folder
	
endfor	


end function	
///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////
//To fix variables that show wrong measurements during the simulation.
//It goes folder by folder doing a new measurement of the parameter. Check traces are correct, with "DisplayfromFolders()"
Function PatchingPhi()

Variable/G index=20// Index for Phi6Hz

string stg1,stg2,stg3,stg4,stg5,fit
variable var1,var2,var3,numfolder

string folder
variable i,j,k,l,m,n,value

//setdatafolder "root:"

//loop to go inside each folder
folder=getdatafolder(1)

numfolder=countobjects(":",4)//count folders inside current folder 
make/O/N=(numfolder) $"temp1"
wave wtemp=$"temp1"

//display/W=(50,50,350,220)

for(i=0;i<numfolder;i+=1)
	
	stg1=GetIndexedObjName("",4,i)
	setdatafolder $stg1
	
	stg2="ParamsVal"+stg1
	wave w2=$stg2
	
	//getting voltage wave
	stg3=stg1+"Vm_fase"
	wave wfase=$stg3
		
	if(exists(stg3)==1)

	CurveFit/Q/M=2/W=0 line, wfase[48,68]/D
	fit="fit_"+stg3
	wave wfit=$fit
	
	w2[index]=wfit(6)//phi6Hz
	w2[index+1]=wfase(w2[18]) //phifR
	

	endif	
	//print getdatafolder(0)
	setdatafolder $folder
	
endfor	


end function	
///////////////////////////////////////////////////////////
//To correct to high firing when Zmax is too high. if spks # > 10, then =10
Function PatchingSpkNum()

Variable/G index=24// Index for deltaVm

string stg1,stg2,stg3,stg4,stg5
variable var1,var2,var3,numfolder

string folder
variable i,j,k,l,m,n,value

//setdatafolder "root:"

//loop to go inside each folder
folder=getdatafolder(1)

numfolder=countobjects(":",4)//count folders inside current folder 
make/O/N=(numfolder) $"temp1"
wave wtemp=$"temp1"

//display/W=(50,50,350,220)

for(i=0;i<numfolder;i+=1)
	
	stg1=GetIndexedObjName("",4,i)
	setdatafolder $stg1
	
	stg2="ParamsVal"+stg1
	wave w2=$stg2
			
	if(exists(stg2)==1)

		//getting spknum value
		value=w2[index]

		if(value>10)
		
			w2[index]=10
			
		endif

	endif	
	//print getdatafolder(0)
	setdatafolder $folder
	
endfor	


end function	


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function SaveSimBoots(wavetag,cm,ena,ek,temp,eleak,gleak,gh,eh,gnap,gm,gnahh,gkhh,ioffset,zap,deltaVm,rin,vmavg,qvalue,fr,zmax,phi6hz,phifR,spkthr,Vmperi,SpkNum)

string wavetag //to define outputwaves
variable cm,ena,ek,temp,eleak,gleak,gh,eh,gnap,gm,gnahh,gkhh,ioffset,zap,deltaVm,rin,vmavg,qvalue,fr,zmax,phi6hz,phifR,spkthr,Vmperi,SpkNum

string stg1,stg2,stg3,stg4,stg5,stg6,stg7,stg8,stg9,stg10

variable i,j,k,l,m,n,o



stg9="ParamsText"+wavetag
make/T/O/N=25 $stg9
wave/T wparams=$stg9
wparams={"Cm","ENa","EK","temp","ELeak","Gleak","GH","EH","GNaP","GM","GNaHH","GKHH","Ioffset","ZAP","deltaVm","Rin","VmAVG","Q","fR","Zmax","phi6Hz","phifR","thr","Vm peri","Spk #"}

stg10="ParamsVal"+wavetag
make/O/N=25 $stg10
wave wVal=$Stg10

wVal[0]=cm
wVal[1]=ena
wVal[2]=ek
wVal[3]=temp
wVal[4]=eleak
wVal[5]=gleak
wVal[6]=gh
wVal[7]=eh
wVal[8]=gnap
wVal[9]=gm
wVal[10]=gnahh
wVal[11]=gkhh
wVal[12]=ioffset
wVal[13]=zap
wVal[14]=deltaVm
wVal[15]=rin
wVal[16]=VmAVG
wVal[17]=qvalue
wVal[18]=fr
wVal[19]=zmax
wVal[20]=phi6hz
wVal[21]=phifr
wVal[22]=spkthr
wVal[23]=VmPeri
wVal[24]=spkNum

//edit wParams,wVal

//newdatafolder/O $wavetag
//stg8=":"+wavetag+":"
//
//movewave $stg1,$stg8
//movewave $stg2,$stg8
//movewave $stg3,$stg8
//movewave $stg4,$stg8
//movewave $stg5,$stg8
//movewave $stg6,$stg8
//movewave $stg7,$stg8
//movewave $stg9,$stg8
//movewave $stg10,$stg8

end function

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

