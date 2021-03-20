#pragma rtGlobals=1		// Use modern global access method.

/////////////////////////////////////////////////
//Modified from ImpedanceProfile_RTXi_jun2017
/////////////////////////////////////////////////

//Procedure to analyze simulated experiments
///////////////////////////////////////////////

Function Analizar(wavetag)

String wavetag// of simulation to tag outputwaves,i.e. "Na5IM5"
//wave onda_v,onda_i
variable dt //dt en "ms" de la onda de entrada

string nom1,nom2,nom3,nom4,nom5,nom6,nom7,nom8
variable i,rzap

nom1=wavetag+"Vm" //voltage
nom2=wavetag+"Is" //I stim

duplicate/O/R=(0,10) $"Vm_wave" $nom1
wave wVm=$nom1

duplicate/O/R=(0,10) $"Istim_wave" $nom2
wave wIm=$nom2
 

dt=deltax(wVm)*1e3 // in ms
ImpedanceProfile(wVm,wIm,dt)

//graficar(wvm)

//edit wRest,wResv

End

/////////////////////////////////////////////////////////////////////////////////////////////////////////

Function ImpedanceProfile(onda_V,onda_I,dt)

wave onda_V,onda_I
variable dt// deltat de la onda de entrada en ms

//Global variables
variable/G fr,zmax,qvalue,phi6hz,phifr

//internal variables
string nom1,nom2,nom3,nom4,nom5,nom6,nom7,nom7a
string nom8,nom9,nom10,nom11,nom11a,nom12,nom12a,nom13,nom13a,fit
variable deltaf // en "segundos"que tendran las ondas en dominiuo de frecuencia
variable i,j,k,npntsv,npntsi,restov,restoi

///////////////// haciendo pares las ondas de entrada /////////////////////////////////

npntsv=numpnts(onda_V)
npntsi=numpnts(onda_I)

restov=mod(npntsv,2)
restoi=mod(npntsi,2)

if (restov != 0 )
	
	DeletePoints 0,1,onda_V
	
endif 

if (restoi != 0 )
	
	DeletePoints 0,1,onda_I
	
endif


/////////////////// MAGNITUDE //////////////////////////////
deltaf=1000/(dt*numpnts(onda_v)) //en Hz segun FFT de onda real 

//le resto el promedio para FFT
wavestats/Q onda_v
onda_v-=V_avg
variable savevmavg=V_avg

//FFT magnitud al cuadrado
nom5="Vmag_FFT"
FFT/OUT=3/DEST=$nom5 onda_v
wave w5=$nom5 

//le resto el promedio para FFT
wavestats/Q onda_I
onda_I-=V_avg

//FFT magnitud al cuadrado
nom6="Imag_FFT"
FFT/OUT=3/DEST=$nom6 onda_I
wave w6=$nom6


nom7=nameofwave(onda_V)+"_Zap"
Duplicate/O $nom5 $nom7
wave w7=$nom7

w7=w5/w6*1e3// escalando la onda de salida a M½, 

DeletePoints (20/deltaf),(numpnts(onda_v)-20/deltaf), $nom7
DeletePoints 0,2, $nom7
setscale/P x,2*deltaf,deltaf,"Hz",w7
Smooth 4, $nom7


//Measuring Qvalue and Zmax
CurveFit/Q/NTHR=0 poly 5,  w7(0.5,12) /D // Cambio inicio del fit de V_minloc a 0.5 
nom3="fit_"+nameofwave(w7)
wave w3=$nom3

wavestats/Q/R=(0.5,12) w3 //statistic to fitted curve

fr=V_maxloc
zmax=V_max
qvalue=V_max/w3(0.5)

Killwaves $nom5,$nom6

///////////////////  Phase //////////////////////////////

nom8="V_FFTcpx"
FFT/OUT=1/DEST=$nom8 onda_V
wave/C w8c=$nom8

nom9="I_FFTcpx"
FFT/OUT=1/DEST=$nom9 onda_I
wave/C w9c=$nom9

nom10="Impedancia"

Duplicate/O $nom8 $nom10
wave/C w10c=$nom10

w10c=w8c/w9c

nom11=nameofwave(onda_v)+"_real"
make/O/N=(numpnts(onda_V)/2) $nom11
wave w11=$nom11
w11=real(w10c)*1e3 //Para escalar a M½, según perfil de impedancia "magnitud"

nom12=nameofwave(onda_v)+"_imag"
make/O/N=(numpnts(onda_V)/2) $nom12
wave w12=$nom12
w12=imag(w10c)*-1e3 

nom13=nameofwave(onda_V)+"_fase"
make/O/N=(numpnts(w11)) $nom13
wave w13=$nom13
w13=(atan(w12/w11))*180/pi

//Getting phase parameters

//CurveFit/Q/M=2/W=0 line, w13[48,68]/D
//fit="fit_"+nom13
//wave wfit=$fit



//podado y alisado de ondas... sacar regiones que sobran
//Phase
DeletePoints (20/deltaf),(numpnts(onda_v)/2-20/deltaf), w13
DeletePoints 0,2, w13
setscale/P x,2*deltaf,deltaf,"Hz",w13
Smooth 4, w13


phi6hz=w13(6)//[58]//wfit(6)
phifr=w13(fr)

Killwaves w8c,w9c,w10c,w11,w12

//Le sumo promedio para volver al voltaje original
onda_v+=savevmavg

//print "Q= ",qvalue
//print "fR= ",fR
//print "Zmax= ",Zmax
//print "phi6Hz= ",phi6Hz
//print "phifR= ",phifR



End Function

////////////////////////////////////////////////////////////////////////////////////////////////////7

Function graficar(ondav)//and collecting data

wave ondav

string name1,name2,name3,name4,name5,name6
variable i,j,k


//////Grafincando ZAP///////////////////////////////
name1=nameofwave(ondav)+"_zap"
name2=name1+"n"
wave onda1=$name1

display/W=(275,30,545,230)/K=1 $name1,$name2
SetAxis bottom 0,20
Label left "Imp (M½)"
ModifyGraph lsize=2
ModifyGraph mode($name2)=2,rgb($name2)=(0,0,0)
ModifyGraph fSize=12

//ajustando polinomial a la onda zap
//wavestats/Q/R=(0,3) $name1
CurveFit/Q/NTHR=0 poly 5,  onda1(0.5,12) /D // Cambio inicio del fit de V_minloc a 0.5 
name3="fit_"+name1
wave w3=$name3
ModifyGraph rgb($name3)=(0,0,0)

//Creando ondas que mostraran el máximo y mínimo de impedancia
string minwave=name1+"_min"
string maxwave=name1+"_max"

//wavestats/Q/R=(0,3) $name1
Make/O/N=50 $minwave
wave wmin=$minwave
setscale/I x 0,20,"",wmin
//wmin=V_min
wmin=w3(0.5) //set to impedance at freq 0.5 Hz according to fitted curve

appendtograph $minwave
ModifyGraph rgb($minwave)=(0,0,0)
ModifyGraph lstyle($minwave)=3

wavestats/Q/R=(0.5,15) w3 //statistic to fitted curve
duplicate/O wmin $maxwave
wave wmax=$maxwave
setscale/I x 0,20,"",wmax

variable res_frec=V_maxloc
variable zmax=V_max
variable q_coef

wmax=V_max
zmax=V_max
q_coef=V_max/w3(0.5)



appendtograph $maxwave
ModifyGraph rgb($maxwave)=(0,0,0)
ModifyGraph lstyle($maxwave)=3
SetAxis left 0,(V_max+10)

TextBox/C/N=text0/X=0/Y=0/F=0/A=RT "\\f01\\Z12Q="+num2str(q_coef)
TextBox/C/N=text1/X=0/Y=15/F=0/A=LB "\\f01\\Z12F="+num2str(res_frec)+" Hz"
TextBox/C/N=text2/X=0/Y=0/F=0/A=LB "\\f01\\Z12Zmax="+num2str(Zmax)+" M½"

Print "Impedance coef. (Q)= ",q_coef
Print "Resonant Frequency= ",res_frec," Hz"
Print "Z max= ",Zmax," M½"

//Saving resonant values
wavestats/Q ondav

//wRest={"Vavg","Rin","Q","fR","Zmax","phi6Hz","phifR"}
wave wResv=$"result_var"

wResv[2]=q_coef
wResv[3]=res_frec
wResv[4]=zmax


//end saving

//////////////////Graficando la fase////////////////////////////////

name4=nameofwave(ondav)+"_fase"
name5=name4+"n"

display/W=(550,30,820,230)/K=1 $name4,$name5
//SetAxis bottom 0,20
//SetAxis left 10,-70
label left "Phase"
ModifyGraph lsize=2
ModifyGraph zero(left)=3
ModifyGraph mode($name5)=2,rgb($name5)=(0,0,0)
ModifyGraph fSize=12

//Obtaining phase values
wave w13=$name4
wResv[5]=w13(6)
wResv[6]=w13(res_frec)

//end saving

end

//////////////***************************//////////////////
//Supousing a squared pulse from 10.5 to 10.7 sec
Function rinzap(onda_v,onda_i)

wave onda_v,onda_i

string nom1,nom2,nom3
variable ipulso,deltav,rzap

deltav=onda_v(10.69)-onda_v(10.49)

ipulso=onda_i(10.6)-onda_I(10.4)
print "Amplitud ZAP=",ipulso," pA"

rzap=(deltav/ipulso)*1e3 //en M½

return rzap

end

/////////****************************//////////////////////
