<CsoundSynthesizer>
<CsOptions>
-d
-odac:system:playback_ -+rtaudio=jack 
</CsOptions>
<CsInstruments>

sr = 44100
nchnls = 2 ;8;2
0dbfs = 1
ksmps = 4

#define MAXREPETITIONS  #5#
#define SLENDRO #0#
#define PELOG #1#
#define BOHLEN #2#

; TABLES:
; frequency ratios of the scales
giPseudoSlendro ftgen 0,0,-10,-2, 1, 8/7, 4/3,   14/9,  16/9, 2
giPelogHarrison ftgen 0,0,-10,-2, 1, 35/32, 5/4, 21/16, 49/32, 105/64, 7/4, 2
giBohlenJust  ftgen 0,0,-10, -2, 1, 25/21, 9/7, 7/5, 5/3, 9/5, 15/7, 7/3, 25/9, 3/1 


;GLOBALS: 

;giSteps[] init 16
;giSteps  =  giPseudoSlendro ;giPelogHarrison;giBohlenJust ;

giBaseFrequency = 110 ;cpspch(5.02)

giScales[] fillarray giPseudoSlendro, giPelogHarrison, giBohlenJust ; array of id-s to according tables 

; initialize for slendro
giPatternLength = 6
gimaxPitches = 6

gkScale init $SLENDRO

gkSquareDuration[] fillarray 0.25, 0.25, 0.25
gkClock[] init 3
giPan[] fillarray 0.5, 1, 0
gkSoundType[] init 3


giMatrix[][]  init   3,16  ; first dimension - voice, second: step or -1


gaSignal[] init 3
gkDeviation[] init 3 ; changing delaytime for loopPlay
gkDeviation[0] init 1
gkDeviation[1] init 1
gkDeviation[2] init 1

gkIsPlaying[] init 3 ; flags the show if the voice is playing

;CHANNELS:

chnset 0.5, "level"
chnset 0.25, "square1"
chnset 0.25, "square2"
chnset 0.25, "square3"

chnset 1, "delayLevel"
chnset 0.1, "longDelayLevel"

seed 0

; to test:



;gkSquareDuration[0] init 2
;gkSquareDuration[1] init 1
;gkSquareDuration[2] init 4

;schedule "setMode",0,0,1
;schedule "setMode",0,0,2
instr setMode ; sets the scale and load right ratios to giSteps
	imode = p4
	gkScale init imode
	if (imode==$BOHLEN ) then
		;giSteps = giBohlenJust
		giPatternLength = 10
		gimaxPitches = 10	
	elseif (imode==$PELOG ) then
		;giSteps = giPseudoSlendro
		giPatternLength = 8
		gimaxPitches = 8	
	else  		
		;giSteps = giPseudoSlendro
		giPatternLength = 6
		gimaxPitches = 6	
	endif
	;print imode, giPatternLength, gimaxPitches
endin


;schedule "randomPattern", 0, 0, 0, 1
;schedule "randomPattern", 1, 0, 1, 1
;schedule "randomPattern", 2.1, 0, 2, 1 ; last 1 if to repeat
instr randomPattern
	index = 0
	ivoice = p4
	iloop = p5
	;print giPatternLength
	
loophere:
	giMatrix[ivoice][index] = limit(int(random:i(-gimaxPitches/2,gimaxPitches)), -1, gimaxPitches)
	;print index, giMatrix[ivoice][index]
	loop_lt index, 1, giPatternLength, loophere
	
	schedule "playPattern",0,0,  int(random:i(0,4)), int(random:i(2,8)), ivoice, int(random:i(1,9))
	if (iloop>0) then
		schedule	"randomPattern", (giPatternLength+1)*i(gkSquareDuration[ivoice]), 0, ivoice, iloop
	endif
endin


alwayson "clockAndChannels"
instr clockAndChannels 
	
	;gkTempo chnget "tempo" ; 1 - normal, <1 - slower, >1 - faster
	chnset gkIsPlaying[0], "active1"
	chnset gkIsPlaying[1], "active2"
	chnset gkIsPlaying[2], "active3"
		outvalue "display", gkIsPlaying[0]
	
	gkLevel chnget "level"

	gkSoundType[0] chnget "sound1" 
	gkSoundType[1] chnget "sound2"
	gkSoundType[2] chnget "sound3"
	
	if (metro(2)==1) then ; allow square duration changes only "on tick"	
		gkSquareDuration[0] chnget "square1"
		gkSquareDuration[1] chnget "square2"
		gkSquareDuration[2] chnget "square3"
	endif
	
	; to sync incoming messages:		
	gkClock[0] metro 1/gkSquareDuration[0]
	gkClock[1] metro 1/gkSquareDuration[1]
	gkClock[2] metro 1/gkSquareDuration[2]

	;test:
	;schedkwhen gkClock[0], 0, 0, "testTick", 0, 0.05
endin

; schedule "setSquare",0,10,0,1.11
instr setSquare ; sets the square duration change only on tick, to keep some rythimc pattern
	ivoice = p4
	isquareDuration = p5
	if (gkClock[ivoice]==1) then
		if (isquareDuration!=0) then
			gkSquareDuration[ivoice] = isquareDuration ; to protect agains div by zero in clockAndChannels
		endif
		turnoff
	endif
endin


;schedule "playPattern",0.21,0,3, 4, 0
;schedule 6.0123,0,0,1, 4, 1
instr playPattern_previous ; takes care that incoming messages start "on tick"
	idur = p3
	p3 = 10 ; for any case
	ivoice = p6
	; võibolla viga siin nendes tingimustes:
	schedule "playPattern_i", 0, 0,p4,p5,p6,p7
;	if (gkClock[ivoice]==1 && gkIsPlaying[ivoice]==0 ) then 
;		event "i", "playPattern_i", 0, idur,p4,p5,p6,p7
;		turnoff	
;	endif
endin

;schedule 7.1,0,0,1, 4, 0,4
instr playPattern,66 ; name and number to bea able to call by number from host ;_i
	itimes = p4 ; how many times to repeat: 1 means original + 1 repetition,	
	

	irepeatAfter = p5 ; repeat after given squareDurations
	ivoice = p6 ; three voices
	ipanOrSpeaker = (p7==0) ? int(random:i(1,7)) : p7; number of speaker if 8 channels, otherwise expresse pan 1-left, 8- right
	itotalTime = giPatternLength*i(gkSquareDuration[ivoice]) + itimes*irepeatAfter*i(gkSquareDuration[ivoice])
	if (frac(p1)==0) then 
		iloopPlay = nstrnum("loopPlay") + (ivoice+1)/10
	else
		iloopPlay = nstrnum("loopPlay")+frac(p1) ; if called with fractional number, call loopPlay with it, then the gkIsPlaying flag is not set - useful for creating thicker textures
	;print iloopPlay
	endif
	print ivoice, itotalTime
	; TODO: how to handle csound-played pattern only? ie, not sent by user?
	
	if (frac(iloopPlay)>0.05 && i(gkIsPlaying[ivoice])==1) then ; if loopPlay is already on and the instrument is called by user (ie without fractional part), don't start it and stop here.
		turnoff
	endif
		;schedule iloopPlay, 0, itotalTime,  itimes, irepeatAfter, ivoice, ipanOrSpeaker ; set the loop player to be on for pattern+ repetitions;
	;endif
	
	
		; play sounds
; play sounds on clock's ticks to bea able to change tempo
	p3 = 40 ; for any case, maximal pattern duration 10*4 seconds
	kcounter init 0
	if (gkClock[ivoice]==1 && kcounter<giPatternLength ) then
		if (kcounter==0) then ; start loopPlay on first note allow normal loopplay o
			schedkwhen 1, 0, 0, iloopPlay, 0, itotalTime,  itimes, irepeatAfter, ivoice, ipanOrSpeaker
		endif
		kstep = giMatrix[ivoice][kcounter] 		
		if (kstep >= 0) then
			;printk2 kstep 
			kfreqRatio = tab:k(kstep,giScales[i(gkScale)])
			kfreq = (1<<ivoice)*giBaseFrequency*kfreqRatio; 
			event "i","sound", 0, gkSquareDuration[ivoice], 0.2,kfreq, ivoice 
		endif
		kcounter += 1
		;printk2 kcounter
	endif		
	if (kcounter==giPatternLength) then
		turnoff
	endif
	
; i-time loop
;	index = 0
;loophere:
;	istep = giMatrix[ivoice][index]
;	;print istep 
;	if (istep != -1) then
;			ifreqRatio = tab_i(istep,giScales[i(gkScale)]) 
;		ifreq =	(1<<ivoice)*giBaseFrequency*ifreqRatio  
;		;print istep,ifreq
;		schedule	"sound", index*i(gkSquareDuration[ivoice]), i(gkSquareDuration[ivoice]), 0.2,ifreq , ivoice 
;	endif
;	loop_lt index, 1, giPatternLength, loophere
		
endin

; schedule "deviationLine",0,20, 1, 1
gkDelayFadeIn init 0
instr deviationLine ; TODO: klõpsud sees!
	ichange4sound = p4 ; change gkDelayFadein
	ichange4loopPlay = p5 ; change the looptime
	
	if (ichange4sound > 0) then
		gkDelayFadeIn linseg 0, p3/2,1,p3/4,1, p3/4,0
		;gkDelayFadeIn *= chnget:k("delayLevel")
	endif
	
	if (ichange4loopPlay > 0) then
		
		klongLevel chnget "longDelayLevel"
		klongLevel port klongLevel, 0.08
		gkDeviation[0] = 1+ poscil(0.1*klongLevel*2 ,1/10*(1+klongLevel))
		gkDeviation[1] = 1+ poscil(0.1*klongLevel*2 ,1/10*(1+klongLevel));poscil(0.1,1/20)
		gkDeviation[2] = 1+ poscil(0.1*klongLevel*2 ,1/10*(1+klongLevel));poscil(0.1,1/30)
		
		if (release()==1) then
			gkDeviation[0] = 1
			gkDeviation[1] = 1
			gkDeviation[2] = 1
		endif
	endif
endin

;giSine ftgen 0,0,16384,10,1,0.05,0.04,0.003,0.002,0.001
; schedule "sound", 0,  0.25, 0.1, 440
; schedule "sound", 0,  0.25, 0.1, 440
instr sound
	iamp = p4
	ifreq =  p5
	ivoice = p6
	iatt = 0.05
	;ipan = p7
	
	;gkLastPlay[ivoice] init times:i()
	
		
	;aenv expseg 0.0001, iatt, 1, p3-iatt, 0.0001
	aenv adsr 0.01,0.01,0.6, p3/2
	; TODO: proovi adsr
	isound = i(gkSoundType[ivoice]) ;chnget "sound"
	if (isound==0) then 
		asig poscil 1,ifreq ;,giSine
		asig chebyshevpoly asig, 0, 1, rnd(0.2), rnd(0.1),rnd(0.1), rnd(0.1), rnd(0.05), rnd(0.03) ; add some random timbre
	elseif (isound==1) then
		;kcx     line    0.1, p3, 1; max -15 ... 15
		;krx line 0.1,p3, 0.5
		kcx   init random:i(0.1,0.5);  line    0, p3, 0.2
		krx     linseg  0.1, p3/2, random:i(0.2,0.6), p3/2, 0.1
		awterr      wterrain    1, ifreq,kcx, 0, krx/2, krx, -1, -1
		asig      dcblock awterr ; DC blocking filter
	elseif (isound==3) then 
		asig fmbell	1, ifreq,random:i(0.8,2), random:i(0.5,1.1),0.005,4
	
	elseif (isound==2) then	
		asig vco2 1, ifreq
		asig moogladder asig, line(ifreq*(1+rnd(6)),p3,ifreq*(2+rnd(2))), 0.8
	elseif (isound==4) then	
		ix random 4,10
		kcx   line -ix,p3,ix 
		krx line random:i(0.1,4) ,p3, random:i(0.1,4)
		awterr      wterrain    1, ifreq,kcx, 0, krx/2, krx, -1, -1
		asig      dcblock awterr ; DC blocking filte
		asig butterlp asig,2000
	elseif (isound==5) then ; additive, close frequencies
		a1 poscil 0.5,ifreq
		a2 poscil 0.5, ifreq*(1+jspline(0.05, 1, 6))	
		asig ntrpol a1,a2,0.5+jspline(0.4,0.5,2)
	elseif (isound==6) then ; pluck with tail
		kfreq expseg ifreq,p3/2,ifreq,p3/2,ifreq*random:i(0.666,1.333)
		asig pluck 1, kfreq,ifreq,-1,3,0
	elseif (isound==7) then ; pluck with tail
		kfreq expseg ifreq,p3/2,ifreq,p3/2,ifreq*random:i(0.5,2)
		anoise pinkish 0.8
		asig rezzy butterbp(anoise, kfreq, kfreq/16),kfreq,100,1
		asig balance asig, anoise

		
	
	else
		asig pinker
		asig moogvcf asig, line(ifreq*(1+rnd(6)),p3,ifreq*(2+rnd(2))), random:i(0.5,0.9)
	endif
	
	asig = asig*iamp*aenv
	;aL,aR pan2 asig, ipan
	;outs aL*gkVolume,aR*gkVolume	
	
	gaSignal[ivoice] = gaSignal[ivoice] + asig
endin


instr sound_old
	iamp = p4
	ifreq =  p5
	ivoice = p6
	iatt = 0.05
	;aenv expseg 0.0001, iatt, 1, p3-iatt, 0.0001
	aenv adsr 0.01,0.01,1, p3/2
	; TODO: proovi adsr
	isound = i(gkSoundType[ivoice]) ;chnget "sound"
	if (isound==0) then 
		asig poscil 1,ifreq ;,giSine
		asig chebyshevpoly asig, 0, 1, rnd(0.2), rnd(0.1),rnd(0.1), rnd(0.1), rnd(0.05), rnd(0.03) ; add some random timbre
	elseif (isound==1) then
		;kcx     line    0.1, p3, 1; max -15 ... 15
		;krx line 0.1,p3, 0.5
		kcx   init random:i(0.1,0.5);  line    0, p3, 0.2
		krx     linseg  0.1, p3/2, random:i(0.2,0.6), p3/2, 0.1
		awterr      wterrain    1, ifreq,kcx, 0, krx/2, krx, -1, -1
		asig      dcblock awterr ; DC blocking filter
	elseif (isound==3) then 
		asig fmbell	1, ifreq,random:i(0.8,2), random:i(0.5,1.1),0.005,4
	
	elseif (isound==2) then	
		asig vco2 1, ifreq
		asig moogladder asig, line(ifreq*(1+rnd(6)),p3,ifreq*(2+rnd(2))), 0.8
	elseif (isound==4) then	
		ix random 4,10
		kcx   line -ix,p3,ix 
		krx line random:i(0.1,4) ,p3, random:i(0.1,4)
		awterr      wterrain    1, ifreq,kcx, 0, krx/2, krx, -1, -1
		asig      dcblock awterr ; DC blocking filte
		asig butterlp asig,2000
	else
		asig pinker
		asig moogvcf asig, line(ifreq*(1+rnd(6)),p3,ifreq*(2+rnd(2))), random:i(0.5,0.9)
	endif
	
	asig = asig*iamp*aenv
	
	
	gaSignal[ivoice] = gaSignal[ivoice] + asig
endin


instr loopPlay
	iamp[] init  $MAXREPETITIONS
	itimes = p4 ; how many times to repeat: 1 means original + 1 repetition

;find amplitudes for multitap, insert 0, when not needed
	index = 0
mark1:
	iamp[index] =  (index<itimes)  ?  1 - (index+1)/8 : 0
	loop_lt index, 1, $MAXREPETITIONS, mark1
	
	irepeatAfter = p5 ; repeat after given squareDurations
	ivoice = p6
	ipanOrSpeaker = p7
	
	print frac(p1)
	if (frac(p1)>=0.0999) then ; if just play, dont look for beginning and end, let the fractional part be under 0.1 (like 0.01)
		gkIsPlaying[ivoice]= 1 ;init i(gkIsPlaying[ivoice])+1 ; mark only when called without fractional part
	endif
	;gkIsPlaying[ivoice] = gkIsPlaying[ivoice] + 1 ; to allow more than 1 instruments to play
	
	iloopTime = irepeatAfter * i(gkSquareDuration[ivoice])
	;ilastLoop = itimes * irepeatAfter * i(gkSquareDuration[ivoice])
	prints "LOOPPLAY"
	print itimes, irepeatAfter, iloopTime;, ilastLoop
		
	if (itimes>0) then 
		adummy delayr iloopTime*6
		atime interp gkDeviation[ivoice]
;		ktempfreq =5 + jspline(4,0.1,10)
;		atime = 0.005 + poscil(0.001, ktempfreq)

		adel1 deltapi  iloopTime*atime
		adel2 deltapi  iloopTime*2*atime
		adel3 deltapi  iloopTime*3*atime
		adel4 deltapi iloopTime*4*atime
		adel5 deltapi iloopTime*5*atime
		
		adelayed = (adel1*iamp[0]+ adel2*iamp[1] + adel3*iamp[2] + adel4*iamp[3] + adel5*iamp[4] ) * port(chnget:k("delayLevel"),0.02,chnget:i("delayLevel"))		
		delayw gaSignal[ivoice]
		;adelayed multitap gaSignal[ivoice], iloopTime, iamp[0], iloopTime*2, iamp[1], iloopTime*3, iamp[2], iloopTime*4, iamp[3], iloopTime*5, iamp[4]  
	else
		adelayed = 0	
	endif
	
	
	adeclick linen 1,0.05,p3,0.5
	asig = (gaSignal[ivoice] + adelayed) * adeclick
	
	; short delay to change the timbre
	atime2 = 0.05 + jspline:a(0.04, 0.1, 1)
	adummy2 delayr p3
	ad1 deltapi  atime2
	ad2 deltapi  atime2*2;0.02 + poscil:a(0.003+kamp/2, ktempfreq)
	adelay2 = (ad1+ad2)*gkDelayFadeIn* port(chnget:k("delayLevel"),0.02,chnget:i("delayLevel"))*adeclick
	delayw asig + 0.1*adelay2
	
	
	
	aout = (asig+adelay2)*port(gkLevel,0.02,i(gkLevel)) ;*(0.1+gkattention*0.9)
	aout clip aout, 0, 0dbfs ; for any case
	
	
	
	
	if (nchnls == 8) then
		outch ipanOrSpeaker, aout
	else ; for stereo
		ipan = (ipanOrSpeaker-1) / 7 ; 1..8 -> 0..1
		aL, aR pan2 aout, ipan
		outs aL, aR		
	endif 	 
	
	gaSignal[ivoice] = 0
	if (release()==1  && frac(p1)>=0.06 )then  
		gkIsPlaying[ivoice] = 0;gkIsPlaying[ivoice] - 1 ; 0 ; to allow more than 1 to play
	endif
endin
;
;instr testTick
;	asig poscil linen(0.051,0.05,p3,p3/2), 1000
;	outs asig, asig
;endin
;

</CsInstruments>
<CsScore>

</CsScore>
</CsoundSynthesizer>
<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>0</x>
 <y>0</y>
 <width>366</width>
 <height>384</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="nobackground">
  <r>255</r>
  <g>255</g>
  <b>255</b>
 </bgcolor>
 <bsbObject type="BSBButton" version="2">
  <objectName>play pattern</objectName>
  <x>17</x>
  <y>72</y>
  <width>137</width>
  <height>30</height>
  <uuid>{fd46780e-b7e0-4087-9b8b-311012e6066d}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <type>event</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>pattern 1</text>
  <image>/</image>
  <eventLine>i "randomPattern" 0 0 0 0</eventLine>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
 <bsbObject type="BSBDisplay" version="2">
  <objectName>display</objectName>
  <x>78</x>
  <y>194</y>
  <width>80</width>
  <height>25</height>
  <uuid>{77252a9a-278b-4382-a4b5-d989407aacc6}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>0.000</label>
  <alignment>left</alignment>
  <font>Liberation Sans</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>border</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject type="BSBButton" version="2">
  <objectName>play pattern</objectName>
  <x>19</x>
  <y>107</y>
  <width>137</width>
  <height>30</height>
  <uuid>{56e42de5-2a60-4e81-99a8-2eb0d06ce627}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <type>event</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>pattern 2</text>
  <image>/</image>
  <eventLine>i "randomPattern" 0 0 1 0</eventLine>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
 <bsbObject type="BSBButton" version="2">
  <objectName>play pattern</objectName>
  <x>19</x>
  <y>143</y>
  <width>137</width>
  <height>30</height>
  <uuid>{63b8b219-1259-49b7-a398-aa909950b935}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <type>event</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>pattern 3</text>
  <image>/</image>
  <eventLine>i "randomPattern" 0 0 2 0</eventLine>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
 <bsbObject type="BSBSpinBox" version="2">
  <objectName>sound1</objectName>
  <x>112</x>
  <y>291</y>
  <width>80</width>
  <height>25</height>
  <uuid>{8a4b41b7-ef02-4ab1-95f0-817710599202}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <alignment>left</alignment>
  <font>Liberation Sans</font>
  <fontsize>10</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>1.00000000</resolution>
  <minimum>0</minimum>
  <maximum>8</maximum>
  <randomizable group="0">false</randomizable>
  <value>1</value>
 </bsbObject>
 <bsbObject type="BSBButton" version="2">
  <objectName>button5</objectName>
  <x>45</x>
  <y>251</y>
  <width>100</width>
  <height>30</height>
  <uuid>{81a0ce30-293f-454a-9fd7-b3e8c080e944}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <type>event</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>Deviation</text>
  <image>/</image>
  <eventLine>i "deviationLine"  0 60 1 1</eventLine>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
 <bsbObject type="BSBSpinBox" version="2">
  <objectName>square1</objectName>
  <x>113</x>
  <y>325</y>
  <width>80</width>
  <height>25</height>
  <uuid>{7fa3a8f4-7dcb-4b42-90ed-532ef23e1b68}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <alignment>left</alignment>
  <font>Liberation Sans</font>
  <fontsize>10</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>0.05000000</resolution>
  <minimum>0.1</minimum>
  <maximum>4</maximum>
  <randomizable group="0">false</randomizable>
  <value>0.25</value>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>27</x>
  <y>325</y>
  <width>80</width>
  <height>25</height>
  <uuid>{48dc336b-032a-4296-8073-f278c91c3e58}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>square1</label>
  <alignment>left</alignment>
  <font>Liberation Sans</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>27</x>
  <y>292</y>
  <width>80</width>
  <height>25</height>
  <uuid>{5514d75c-01dd-4c2c-9073-d39fa6494fb3}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>instrument 1
</label>
  <alignment>left</alignment>
  <font>Liberation Sans</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject type="BSBSpinBox" version="2">
  <objectName>square2</objectName>
  <x>118</x>
  <y>359</y>
  <width>80</width>
  <height>25</height>
  <uuid>{7f148e07-c97d-4cfc-a675-74f42ba4fb21}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <alignment>left</alignment>
  <font>Liberation Sans</font>
  <fontsize>10</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>0.05000000</resolution>
  <minimum>0.1</minimum>
  <maximum>4</maximum>
  <randomizable group="0">false</randomizable>
  <value>0.25</value>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>delayLevel</objectName>
  <x>244</x>
  <y>212</y>
  <width>20</width>
  <height>100</height>
  <uuid>{94cb95cb-4130-448c-b153-996420e2a8f3}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>2.00000000</maximum>
  <value>0.25000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>228</x>
  <y>317</y>
  <width>64</width>
  <height>51</height>
  <uuid>{28a0be51-7461-48b9-ab9d-fb5e2bcc723d}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>Short delay level</label>
  <alignment>left</alignment>
  <font>Liberation Sans</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>longDelayLevel</objectName>
  <x>318</x>
  <y>213</y>
  <width>20</width>
  <height>100</height>
  <uuid>{eb095077-87cf-45b6-89d1-fe9b31382312}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.10000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>302</x>
  <y>318</y>
  <width>64</width>
  <height>51</height>
  <uuid>{1dd8439d-3b05-4191-a8f4-8104a7208c5d}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>Long delay freq</label>
  <alignment>left</alignment>
  <font>Liberation Sans</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
</bsbPanel>
<bsbPresets>
</bsbPresets>
