#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//Modified from "Simulation1_tuningHH_readyJan232020"
//basic subthreshold neuron: Cm*(dV/dt)=-(Ileak+ih+im+inap-Istim)
//Based on paper Vera et al 2013 version simulation__veraetal2014_igor_mod_abr2016
//Conductance values according to experimental data (VC experiments)
//-------------------------------------------------------------------
//Modified from InapIM_may262013_4 on dec112019

//Model properties
//Rin -80 mv (Iholding -205 pA), 55.7 mV

Function Simular(tagsim,tpulse,ipulse,ioffset,style,savetraces,GNaP,GM,delay)

//all time variables in "s"
string tagsim //tag to identify waves from current simulation, leave empty if you prefer
variable tpulse,ipulse,ioffset //current pulse time (s), current pulse amplitude (pA), DC current offset  (pA)
variable style//stimulus type: 0 = zap, 1 = squared, 2 = ramp
variable savetraces //if 1, traces are saved for further analysis
variable GNaP,GM
variable delay//before time t=0, normally -10 sec for ZAP


//variable timerRefNum,elapsedtime
//TimerRefNum = startMSTimer

//-------------------------------------------------------------------
//Internal variables
Variable i,j,k,l,m,n,o,p,npts,dvdt,imem,t,tsim

//some Global variables
Variable/G Rin,Istim,Vmavg
//-------------------------------------------------------------------
//simulation variables defined as in Richardson et al, 2003; then modified for Stroke project 2019/2020
variable/G dt,vm,Cm,ena,ek,temp//delay,

dt=4e-5//low sampling to test //1e-5 //delta t simulation, "s"
Cm= 120//*1.1//pF, AVG value  HP neurons Vera el at 2019
vm=-65 //mV
ena=47//47.1 //mV Na+ inversion potential
ek=-99//mV K+ inversion potential
//delay=-10 //s, delay to reach steady state
temp=35 //temperature of simulations (C)


//-------------------------------------------------------------------
//Definition of transmembrane currents

//-------------------------------------------------------------------
//variables I leak (0.1 nS/pF Richardson)

variable/G Ileak,gleak,eleak

eleak=-70 //mV
gleak= 0.125*Cm//0.08*Cm works dec12//AVG value  HP neurons Vera el at 2019//Value before changing INaHH kinetics =0.08*Cm
//gleak= 0.15*Cm  first simulations     //Value for first round of simulation=0.14*Cm (120 pF).. jan2020
//-------------------------------------------------------------------
//variables ih
variable/G gh,eh
variable ih,hfinf,hsinf,hf,hs,tauhf,tauhs,dhfdt,dhsdt

gh= 0.025*Cm//0.025*Cm//AVG value  HP neurons Vera el at 2019
tauhf=0.038/(4.5^((temp-38)/10)) //s
tauhs=0.319/(4.5^((temp-38)/10)) //s
eh=-41 //mV

//-------------------------------------------------------------------
//variables INaP

variable inap,w,winf,taunap,dwdt//,gnap

//gnap=4//2,4,6 2.9 old model, 4.0 new model
inap=0
w=0
taunap=5e-3 //s


//-------------------------------------------------------------------
////variables IM

variable im,r,rinf,taum,drdt//,gm

//gm=10//2,6,10 Vera 2017 // nS according to experimental data .... Vera et al value was 4.5*4/3 //nS
im=0
r=0


//-------------------------------------------------------------------
//variables INaHH

variable/G gnahh
variable inahh,minst,hinst, alfam, alfah, betam, betah,hinf,tauh,dhdt
//working with tuning 2950
gnahh= 1800//2000,2850   //0.8*3.25*510*4/3// nS, 19240 nS Richardson
minst=0 // all deactivated
hinst=1 // all deinactivated 
alfam=0
alfah=0
betam=0
betah=0
hinf=0

//-------------------------------------------------------------------
//variables IKHH
variable/G gkhh
variable ikhh,ninst, alfan, betan,ninf,taun,dndt

gkhh= 1600//1600,1800// nS, 7400 nS Richardson //original value befire changing INaHH kinetics was 1400
ninst=0 // all deactivated
ninf=0
alfan=0
betan=0

//-------------------------------------------------------------------
//Variables zap

variable fi,ff,tzap
fi=0 //Hz, initial freq
ff=20 //Hz, final freq
tzap=tpulse//s, time of pulse

tsim=tpulse+0.9+delay*-1 //for 0.6 s silent window before stiim (second window includes a test pulse)
npts=ceil(tsim/dt)
//print npts

//-------------------------------------------------------------------
//Creating current and voltage waves
make/O/N=0 $"Vm_wave"
wave wvm=$"Vm_wave"
setscale/P x,delay,dt,"",wvm

make/O/N=0 $"Ileak_wave"
wave wileak=$"Ileak_wave"
setscale/P x,delay,dt,"",wileak

make/O/N=0 $"Istim_wave"
wave wistim=$"Istim_wave"
setscale/P x,delay,dt,"",wistim

make/O/N=0 $"Ih_wave"
wave wih=$"Ih_wave"
setscale/P x,delay,dt,"",wih

make/O/N=0 $"Inap_wave"
wave winap=$"Inap_wave"
setscale/P x,delay,dt,"",winap

make/O/N=0 $"Im_wave"
wave wim=$"Im_wave"
setscale/P x,delay,dt,"",wim

make/O/N=0 $"Inahh_wave"
wave winahh=$"Inahh_wave"
setscale/P x,delay,dt,"",winahh

make/O/N=0 $"mhh_wave"
wave wmhh=$"mhh_wave"
setscale/P x,delay,dt,"",wmhh

make/O/N=0 $"hhh_wave"
wave whhh=$"hhh_wave"
setscale/P x,delay,dt,"",whhh

make/O/N=0 $"Ikhh_wave"
wave wikhh=$"Ikhh_wave"
setscale/P x,delay,dt,"",wikhh

make/O/N=0 $"nhh_wave"
wave wnhh=$"nhh_wave"
setscale/P x,delay,dt,"",wnhh

make/O/N=0 $"tauh_wave"
wave wtauh=$"tauh_wave"
setscale/P x,delay,dt,"",wtauh

make/O/N=0 $"taun_wave"
wave wtaun=$"taun_wave"
setscale/P x,delay,dt,"",wtaun

make/O/N=0 $"alfam_wave"
wave walfam=$"alfam_wave"
setscale/P x,delay,dt,"",walfam

make/O/N=0 $"alfan_wave"
wave walfan=$"alfan_wave"
setscale/P x,delay,dt,"",walfan

//-------------------------------------------------------------------
//Main dt loop

for(i=0 ; i<npts ; i+=1)
	
	//time definition
	t=dt*i+delay
	
	//stim current: Squared pulse or ZAP... decomment to implement
	if(t>0 && t<tpulse) 

		if(style==0)
		
			//ZAP
			istim=ipulse*sin(2*pi*t*(fi+(ff-fi)*t/(2*tzap)))+ioffset
		
		endif
		
		if(style==1)
	
			//squared pulse		
			istim=ipulse+ioffset
		
		endif
		
		if(style==2)
	
			//ramp
			istim=ipulse*dt*(i+delay/dt)/tpulse+ioffset
		
		endif
		
	else

	istim=ioffset
	
	endif

	//Test pulse at end of simulation
	if(t>tpulse+0.5 && t<tpulse+0.7) 

		//test squared pulse		
		istim=-1*Ipulse+ioffset //pA
		
	
	
	endif



	//Membrane currents
	
	//-------------------------------------------------------------------		
	//I leak
	
		ileak=gleak*(vm-eleak) // nS*mV=1e-9*1e-3A=1e-12A=pA

//-------------------------------------------------------------------
	//INaP  inap=gnap*w*(vm-ena)
	
		//winf
		winf=1/(1+exp(-1*(vm+52.9)/5.22)) //according to VC experiments. V0.5 original =53.4
		//For Model 2, low conductance, control condition V05=53.4
		//Now testing 1 mV roght shift in V05
		
		dwdt=(winf-w)/taunap
		
		w+=dwdt*dt
		
		//calculating current
		 inap=gnap*w*(vm-ena)
		 
	//-------------------------------------------------------------------
	//IM  im=gm*r*(vm-ek), according to Vera et al 2014
	
		//rinf
		rinf=1/(1+exp(-1*(vm+32.18)/7.35)) //VC experiments
		//rinf=1/(1+exp(-1*(vm+42.18)/7.35)) //values from experimental data V0.5=32.18. This is for initial model stroke
		taum=1/(3.3*(exp((vm+35)/40))+exp(-1*(vm+35)/20))// VC experiments
		//taum=1/(3.3*(exp((vm+45)/40))+exp(-1*(vm+45)/20))// values from experimental data V0.5=35. This is for initial model stroke
		taum/=3^((temp-22)/10) //temp correction
		
		drdt=(rinf-r)/taum
		
		r+=drdt*dt
		
		//calculating current
		 im=gm*r*(vm-ek)

	//-------------------------------------------------------------------	
	//Ih
	
		//ih fast
		hfinf=1/(1+exp((vm+78)/7)) //		hfinf=1/(1+exp((vm+78)/7)) original values
	
		dhfdt=(hfinf-hf)/tauhf
	
		hf+=dhfdt*dt
	
		//ih slow
		hsinf=1/(1+exp((vm+78)/7))  //		hsinf=1/(1+exp((vm+78)/7))
	
		dhsdt=(hsinf-hs)/tauhs
	
		hs+=dhsdt*dt
	
		//calculating current
		ih=gh*(0.8*hf+0.2*hs)*(vm-eh) //nS*mV=pA 


	//-------------------------------------------------------------------
	//INahh  inahh=gnahh*m^3*h*(vm-ena)
	
		//m instantaneous		
		//V05=52.5, 53
		alfam=(-0.1*(vm+55))/(exp(-0.4*(vm+55))-1)//original value V05=32. -0.4 was modified from -0.1 to increase the slope of the minst curve (jan2020)			
		//alfam=(-0.1*(vm+38))/(exp(-0.1*(vm+38))-1)//original value V05=32] This is the original equation			
		betam=4*exp(-1*(vm+65)/18)//original value 57
		minst=alfam/(alfam+betam) //Tau=0, then minst=minf
		
		//h inst	***Modified on jan232020 to increase voltage sensitivity (slope) of the inactivation	
		alfah=0.07*exp(-1*(vm+52)/20)//original value 46, original function
		//alfah=0.07*exp(-1*(vm+54)/5)//original value V05=46, midified jan2020
		betah=1/(exp(-0.1*(vm+22))+1)//original value 16, original function
		//betah=1/(exp(-0.1*(vm+24))+1)//original value 16, modified jan2020
		hinf=alfah/(alfah+betah)
		
		tauh=1/(alfah+betah) //ms
		tauh/=3^((temp-6.3-5)/10) //correction to go from 30 to 35 deegres 
		//tauh/=3^((temp-6.3)/10) //temp correction Richardson, et al 2003.
		tauh*=1e-3 //from ms to s
		
		dhdt=(hinf-hinst)/tauh
		hinst+=dhdt*dt
		
		//calculating current
		inahh=gnahh*(minst^3)*hinst*(vm-ena)

	//-------------------------------------------------------------------
	//IKhh  inkhh=gkhh*n^4*(vm-ek)
	
		//n instantaneous		
		//V05 working 42
		alfan=-0.01*(vm+38)/(exp(-0.1*(vm+38))-1)//original value 36
		//V05 working 52
		betan=0.125*exp(-1*(vm+48)/80)////original value 46
		
		ninf=alfan/(alfan+betan)
		
		taun=1/(alfan+betan) //ms
		taun/=3^((temp-6.3-5)/10) //correction to go from 30 to 35 deegres, jan2020 to simulate IM at 35 
		//taun/=3^((temp-6.3)/10) //temp correction Richardson, et al 2003.
		taun*=1e-3 //from ms to s
				
		dndt=(ninf-ninst)/taun
		ninst+=dndt*dt
		
		//calculating current
		ikhh=gkhh*(ninst^4)*(vm-ek)
	//-------------------------------------------------------------------

	//updating vm
	//imem=ileak+ih+inap+im+inahh+ikhh //I membrane
	imem=ileak+ih+inap+im+inahh+ikhh
	dvdt=-(imem-istim)/Cm //V/s
	
	vm+=dvdt*dt*1e3//+enoise(0.01) //mV
	
	//-------------------------------------------------------------------
	//writting variables
		
		updatewave(wistim,istim)
		updatewave(wileak,ileak)
		updatewave(wvm,vm)
		updatewave(wih,ih)
		updatewave(winahh,inahh)
		updatewave(wmhh,minst)
		updatewave(whhh,hinst)
		updatewave(wikhh,ikhh)
		updatewave(wnhh,ninst)
		updatewave(wtauh,tauh)
		updatewave(wtaun,taun)
		updatewave(walfam,alfam)
		updatewave(walfan,alfan)
		updatewave(winap,inap)
		updatewave(wim,im)
		

	//Some restrictions in case of pproblems
	if(vm > 300)
	
		print "Vm out of range, change parameters"
		break
	
	endif
	
	if(vm < -300)
	
		print "Vm out of range, change parameters"
		break
	
	endif	
		
endfor

//Additional data processing

Rin=F_rin(tpulse+0.5,Ipulse) //will mesure Rin always on test pulse
//Print "Rin sim = ",rin, " M½"
//elapsedtime=stopMSTimer(timerRefNum)
//print "Simulation time: ",elapsedtime*1e-6, " s"

wavestats/Q/R=(0,tpulse) wvm
vmavg=V_avg

if (savetraces==1)
	
	//tagsim
	Savewaves(tagsim,cm,ena,ek,temp,eleak,gleak,gh,eh,gnap,gm,gnahh,gkhh,ioffset,ipulse,rin,vmavg)
	//savewaves(wavetag,cm,ena,ek,temp,eleak,gleak,gh,eh,gnap,gm,gnahh,gkhh)
	
	print "traces saved as ",tagsim

endif


End function 

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Function tu add "value" to "wavex" aas a new point
Function updatewave(wavex,value)

wave wavex
variable value

variable np

np=numpnts(wavex)

insertpoints np,1,wavex

wavex[np]=value

end function

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function F_rin(t,Ipulse)

variable t,Ipulse//time of test pulse
variable i,j,k

wave wvm=$"Vm_wave"
k=wvm(t+0.19)-wvm(t-0.01) //delta V, 200 ms pulse
k*=-1000/Ipulse // Rin en M½

Return k

End
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function naniando()

string nom1,nom2
variable i,j,k

i=nan
nom1=num2str(i)

if(strlen(nom1)) 

	print "1"
	
	else
	
	print "esto funciona"
	print i
	print strlen(nom1)
	
endif

end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function savewaves(wavetag,cm,ena,ek,temp,eleak,gleak,gh,eh,gnap,gm,gnahh,gkhh,ioffset,zap,rin,vmavg)

string wavetag //to define outputwaves
variable cm,ena,ek,temp,eleak,gleak,gh,eh,gnap,gm,gnahh,gkhh,ioffset,zap,rin,vmavg

string stg1,stg2,stg3,stg4,stg5,stg6,stg7,stg8,stg9,stg10

variable i,j,k,l,m,n,o


stg1="Vm_"+wavetag
duplicate/O/R=(0,11) $"Vm_wave" $stg1

stg2="Istim_"+wavetag
duplicate/O/R=(0,11) $"Istim_wave" $stg2

stg3="Ih_"+wavetag
duplicate/O/R=(0,11) $"Ih_wave" $stg3

stg4="INaP_"+wavetag
duplicate/O/R=(0,11) $"INaP_wave" $stg4

stg5="IM_"+wavetag
duplicate/O/R=(0,11) $"IM_wave" $stg5

stg6="IKHH_"+wavetag
duplicate/O/R=(0,11) $"IKHH_wave" $stg6

stg7="INaHH_"+wavetag
duplicate/O/R=(0,11) $"INaHH_wave" $stg7

stg9="ParamsText"+wavetag
make/T/O/N=12 $stg9
wave/T wparams=$stg9
wparams={"Cm","ENa","EK","temp","ELeak","Gleak","GH","EH","GNaP","GM","GNaHH","GKHH","Ioffset","ZAP","Rin","VmAVG"}

stg10="ParamsVal"+wavetag
make/O/N=16 $stg10
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
wVal[14]=rin
wVal[15]=VmAVG

edit wParams,wVal

newdatafolder/O $wavetag
stg8=":"+wavetag+":"

movewave $stg1,$stg8
movewave $stg2,$stg8
movewave $stg3,$stg8
movewave $stg4,$stg8
movewave $stg5,$stg8
movewave $stg6,$stg8
movewave $stg7,$stg8
movewave $stg9,$stg8
movewave $stg10,$stg8

end function

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////