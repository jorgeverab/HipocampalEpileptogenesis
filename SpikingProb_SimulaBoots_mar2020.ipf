#pragma rtGlobals=1		// Use modern global access method. 
//Update del procedure de mayo de que la onda zap se hace en fundi—n del largo y el dt, el dt no es fijo
///////////////////////
//1. Spike_finder: encontrar espigas EN TODAS LAS ONDAS DEL FOLDER
//2. Makezap & Frec_prob_bin: definir intervalos (bins) para calculra la probabilidad en funcion de la frecuencia
//3. Spk_prob: calcular probabilidad

//***************************************
//Modified on dec112019 to analyse simulations


/////////////////////////////////////////////////////////////
Function spk_finder(inputwave,tagondas)//trial,sampleo)

wave inputwave //simulated Vm
string tagondas// se usa para nombrar las ondas de salida

//Global variables
variable/G spkthre,vmperi,spknum

variable sampleo=1e-2 //en "ms"

string nom,nom0,nom1,nom2,nom3,nom4,nom5,listaondas,nom4df,nom6,nom7,nom20
variable i,j,k,l,m,n,npnts,z,a,veintems
variable numspks,nondas

numspks=0

inputwave/=1000 // from mV to V

nom1="thr_"+tagondas//contiene los Vm umbrales
make/O/N=0 $nom1
wave w1=$nom1

nom2="tm_"+tagondas //contiene el timing de los umbrales detectados
make/O/N=0 $nom2
wave w2=$nom2


nom6="thrdf_"+tagondas //contiene los umbrales detectados como dv/dt
make/O/N=0 $nom6
wave w6=$nom6

nom5="df_avg_"+tagondas
make/O/N=0 $nom5
wave w5=$nom5
w5=0

nom7="thr_index_"+tagondas
make/O/N=0 $nom7
wave w7=$nom7

string nom15
nom15="vmperi_"+tagondas
make/O/N=0 $nom15
wave w15=$nom15

nom20="df_"+nameofwave(inputwave)
Differentiate inputwave/D=$nom20  //genera la deribada de Vm
wave w4df=$nom20
	
npnts=numpnts(inputwave)
	
wavestats/Q w4df  //no sŽ pa que es esta onda...
w5+=V_avg
	
j=10
	
	
Do
		
		m=w4df[j]
		//print m
		n=w4df[j+1]
		
		
		//*** Dado que es posible que el ruido de la onda dv/dt sobrepase el umbral que se reconoce como biol—gico (5 mV/ms) voy a poner un umbral alto
		//de 30 mV/ms y luego buscarŽ hacia atr‡s el umbral que corresponde a 5 mV/ms
				
		if( m>=40 && n > m) //el umbral esta en mV/s
			
			for(z=j ; m >=5 ; z-=1) //Ac‡ me devuelvo hasta el umbral estandar
			
				m=w4df[z]
				j=z+1
				
			endfor
			
			//print m	
			insertpoints 0,1,w1		
			w1[0]=inputwave[j]
			
			insertpoints 0,1,w2		
			w2[0]=j*sampleo/1000 //	en "s"	
			
			insertpoints 0,1,w6		
			w6[0]=w4df[j]
			
			insertpoints 0,1,w7		
			w7[0]=i+1 //psk index
			
			veintems=20/sampleo
			wavestats/Q/R=[j-veintems,j] inputwave
			
			insertpoints 0,1,w15		
			w15[0]=V_avg 
			
			j+=50/sampleo //descanso de 10 ms para seguir buscando
			k+=1
			
			numspks+=1
				
		endif
	
		j+=1
		
while( j<=npnts)
	
//To display trace and detected threshold
//display/K=1 vm_wave ///W=(0,50,250,180)
//appendtograph w1 vs w2
//appendtograph w15 vs w2
//ModifyGraph mode($nom1)=3,marker($nom1)=19,rgb($nom1)=(1,16019,65535),mode($nom15)=3,marker($nom15)=46,rgb($nom15)=(19675,39321,1)
//SetAxis bottom 0,10
//ModifyGraph fSize=12
//label left "Voltage (Vm)"
//label bottom "Time (s)"

//Getting parameters
wavestats/Q w15
vmperi=V_avg*1e3

wavestats/Q w1
spkthre=V_avg*1e3
spknum=V_npnts

inputwave*=1e3 //from V to mV

killwaves/Z w4df 


end
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////
		
Function graficardvdt_1(tagonda)

string tagonda

string nom1,nom2,nom3,nom4,listaondas
variable i,j,k,l,m,n,nondas

nom1=tagonda+"*p"
listaondas=wavelist(nom1,",","")
nondas=itemsinlist(listaondas,",")

//print listaondas

display/K=1/W=(405,50,705,250)

for( i=0 ; i<nondas ; i+=1 )

	nom2=stringfromlist(i,listaondas,",")
	wave w2=$nom2
	
	nom3="df_"+nom2
	Differentiate w2/D=$nom3
	wave w3=$nom3
	
	appendtograph w3 vs w2
	
endfor

ModifyGraph rgb=(0,0,0)
ModifyGraph fSize=12;DelayUpdate
Label left "\\u#2dV/dt (mV/ms)"
Label bottom "\\u#2Membrane voltage (mV)"


End Function
	
////////////////////////////////////////////////////////////////////////////////
// Calculo umbral promedio agrupado por orden en el tren de disparo (i.e. 1ra espiga, 2da espiga...etc)
//***************************************************************

Function spk_prob(tagondas,ondaumbral,ondaindex,minfrec,frmaxloc)

string tagondas
wave ondaumbral,ondaindex
wave minfrec// contiene los tiempos (coord x) de los m’nimos de la onda zap
wave frmaxloc // los m‡ximos locales de cada bin.. ondas creadas por spk_prob_bin
 
string nom1,nom2,nom3,nom4,nom5
variable i,j,k,l,m,n,o,q,np,val,nondas,nk,bin

nom1=tagondas+"_*p" //Es importante que no hayan m‡s ondas que comiencen con el tag de la onda
nom2=wavelist(nom1,",","")
nondas=itemsinlist(nom2,",") //Contiene numero de sweeps del experimento
print "N¼ ondas= ",nondas

nom1="spkprob_"+tagondas
duplicate/O frmaxloc $nom1
wave w1=$nom1
w1=0

np=numpnts(ondaumbral)
wavestats/Q ondaindex

nk=numpnts(frmaxloc)

for(i=0 ; i<np ; i+=1) //loop para cada sweep a cuantificar

	val=ondaumbral[i]
	
	//loop para asignar spk al bin correspondiente
	k=0
	
	Do
	
		bin=minfrec[k+1]
		
			if(val < bin) //si el spk timing es menor que el l’mite superior del intervalo, o asigno a dicho intervalo.
		
				w1[k]+=1//para el valor k+1-esimo de min_wave se corresponde con el valor k-esimo de spk_prob
				k=nK
				
			endif
			
			k+=1
			
	while(k<nk)

endfor

//Divisi—n por numero de ondas
w1/=nondas

//corregir si prob>1 en primeros bins

for(i=0 ; i<8 ; i+=1)

	if(w1[i] > 1)

			w1[i]=1
	
	endif

endfor

//graficar registros
Display/K=1/W=(0,200,250,400)
for(i=0 ; i<nondas ; i+=1)

	nom4=stringfromlist(i,nom2,",")
	appendtograph $nom4
	
endfor
Label left "\\u#2Vm (mV)"
label bottom "Time (s)"


Display/K=1/W=(0,420,250,620) w1 vs frmaxloc
ModifyGraph mode=4,marker=19
label left "Spk prob."
label bottom "Frecuency (Hz)"


end function

///////////////////////////////////
Function makezap(tagonda,tzap,dtzap,fi,ff)

string tagonda
variable tzap//tiempo del zap
variable dtzap //sampleo de la onda en ms... que debe coinsidir con el sampleo de la onda a analizar
variable fi,ff //frec inicial y final del zap

string nom1,nom2

//crear onda zap y fdet
nom1="zap_"+tagonda
make/O/N=(tzap*1000) $nom1
wave wzap=$nom1
setscale/I x,0,tzap,"s",wzap

nom2="fdet_"+tagonda
make/O/N=(tzap*1000/dtzap) $nom2
wave wfdet=$nom2
//setscale/I x,0,tzap,"s",wfdet
setscale/P x,0,dtzap/1000,"s",wfdet

wzap=sin(2*pi*x*(fi+(ff-fi)*x/(2*tzap)))
wfdet=fi+(ff-fi)*x/tzap

frec_prob_bin(tagonda,wzap,tzap,fi,ff) 

end function

//////////////////////////////////////
//Crea la onda que ser‡ el eje x del grafico de spiking probability... 
//Generla las siguientes onda:
//M’nimo de onda zap (que definen los bins de frecuencia para cuantificar la probabilidad)
//Onda de frec max que alverga los valores maximos de frecuencia de cada bin
Function frec_prob_bin(tagonda,wzap,tzap,fi,ff) 

string tagonda
wave wzap
variable tzap,fi,ff

string nom1,nom2,nom3,nom4,nom5
variable i,j,k,l,m,n,np,a,b,c,val,frec,h,d,e

np=numpnts(wzap)

nom1="min_"+tagonda
make/O/N=500 $nom1
wave w1=$nom1

nom2="frmaxloc_"+tagonda
make/O/N=500 $nom2
wave w2=$nom2

//asignando onda de los tiempos en que ocurren los m’nimos

w1[0]=0
k=1

for(i=0 ; i<np-12 ; i+=1)

	a=wzap[i]
	b=wzap[i+1]
	c=wzap[i+2]
	d=wzap[i+3]
	e=wzap[i+4]
	
	if(a>b && b>c && e>d && d>c) //define a b como m’nimo
	
		w1[k]=(i+2)/1000 //para que quede en segundos
		k+=1
		
	endif
	
endfor

//sacando puntos no utilizados		
deletepoints k,(500-k),w1


//Buscando m‡ximos para onda frmaxloc
k=0
for(i=0 ; i<np; i+=1)

	a=wzap[i]
	b=wzap[i+1]
	c=wzap[i+2]
	d=wzap[i+3]
	e=wzap[i+4]
	
	if(a<b && b<c && e<d && d<c) //define a b como maximo
	
		val=(i+2)/1000 //para que quede en segundos
		frec=fi+(ff-fi)*(val)/tzap
		w2[k]=frec
		k+=1
		
	endif
	
endfor

print k
deletepoints k,(500-k),w2

End function

//////////////////////////////////////////
Function name(tagwave)

string tagwave

variable i,j,k,l,m,n,nondas
string nom1,nom2,nom3,listaondas

nom1="*"+tagwave+"*"

listaondas=wavelist(nom1,",","")
nondas=itemsinlist(listaondas,",")

//print listaondas

for( i=0 ; i<nondas ; i+=1 )

	nom2=stringfromlist(i,listaondas,",")
	wave w2=$nom2
	//w2*=1e3

	nom3="I"+tagwave+"_"+num2str(i)
	
	rename w2 $nom3
	
endfor

end function