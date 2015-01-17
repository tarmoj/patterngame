<CsoundSynthesizer>
<CsOptions>
-d
-odac:system:playback_ -+rtaudio=jack 
</CsOptions>
<CsInstruments>

sr = 44100
nchnls = 2
0dbfs = 1
ksmps = 8

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
	print imode, giPatternLength, gimaxPitches
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
	
	print index, giMatrix[ivoice][index]
	loop_lt index, 1, giPatternLength, loophere
	
	schedule "playPattern",0,0,  int(random:i(0,4)), int(random:i(2,8)), ivoice
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

	;outvalue 	"active",gkIsPlaying[0]
	
	gkLevel chnget "level"

	gkSoundType[0] chnget "sound1" 
	gkSoundType[1] chnget "sound2"
	gkSoundType[2] chnget "sound3"
		

	; to sync incoming messages:		
	gkClock[0] metro 1/gkSquareDuration[0]
	gkClock[1] metro 1/gkSquareDuration[1]
	gkClock[2] metro 1/gkSquareDuration[2]
	
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


;schedule "playPattern",0.21,0,0, 4, 0
;schedule "playPattern",0,0,1, 4, 2
instr playPattern ; takes care thta incoming messages start "on tick"
	idur = p3
	p3 = 10 ; for any case
	ivoice = p6
	if (gkClock[ivoice]==1 && gkIsPlaying[ivoice]==0 ) then 
		event "i", "playPattern_i", 0, idur,p4,p5,p6
		printk2 gkClock[ivoice] 
		turnoff	
	endif
endin

;schedule "playPattern_i",0,0,1, 4, 2
instr playPattern_i
	itimes = p4 ; how many times to repeat: 1 means original + 1 repetition
	irepeatAfter = p5 ; repeat after given squareDurations
	ivoice = p6 ; three voices
	itotalTime = giPatternLength*i(gkSquareDuration[ivoice]) + itimes*irepeatAfter*i(gkSquareDuration[ivoice])
	print ivoice, itotalTime
	index = 0

	schedule "loopPlay", 0, itotalTime,  itimes, irepeatAfter, ivoice  
	; play sounds
loophere:
	istep = giMatrix[ivoice][index]
	print istep 
	if (istep != -1) then
			ifreqRatio = tab_i(istep,giScales[i(gkScale)]) 
		ifreq =	(1<<ivoice)*giBaseFrequency*ifreqRatio  
		print istep,ifreq
		schedule	"sound", index*i(gkSquareDuration[ivoice]), i(gkSquareDuration[ivoice]), 0.2,ifreq , ivoice 
	endif
	loop_lt index, 1, giPatternLength, loophere
		
endin

;giSine ftgen 0,0,16384,10,1,0.05,0.04,0.003,0.002,0.001
; schedule "sound", 0,  0.25, 0.1, 440
instr sound
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
		asig fmbell	1, ifreq,random:i(0.8,2), random:i(0.5,1.1),0.005,4
	
	elseif (isound==2) then	
		asig vco2 1, ifreq
		asig moogladder asig, line(ifreq*(1+rnd(6)),p3,ifreq*(2+rnd(2))), 0.8
	else
		asig pinker
		asig moogvcf asig, line(ifreq*(1+rnd(6)),p3,ifreq*(2+rnd(2))), random:i(0.5,0.9)
	endif
	
	gaSignal[ivoice] = gaSignal[ivoice] + asig*iamp *aenv
endin

;schedule "startDeviation",0,30
instr startDeviation 
	idur = p3
	schedule "deviationLine",0,idur,random:i(0.1,0.9), random:i(0.25,0.75), 0 
	schedule "deviationLine",2,idur,random:i(0.1,0.9), random:i(0.25,0.75), 0 
	schedule "deviationLine",4,idur,random:i(0.1,0.9), random:i(0.25,0.75), 0 
endin

; schedule "deviationLine",0,30,0.75, 0.5, 1
instr deviationLine ; calculates a factor that will be applied to deltapi line in loopPlay value always from 1 to some lesser value. The line stays at 1 for p5*p3 seconds
	iendValue = (p4==0) ? 0.0001 : p4 ; protext exp from 0
	ipeakTime = p3*p5
	ivoice = p6
	kdeviation init 1
	;kdeviation poscil 0.
	kdeviation linseg 1,ipeakTime, iendValue, p3-ipeakTime, 1
	gkDeviation[ivoice] = kdeviation
	;gkDeviation[ivoice] interp kdeviation
;	if (release()==1) then
;		gkDeviation = 1
;	endif
endin
gkDeviation[1] init 0.05

instr loopPlay
	iamp[] init  $MAXREPETITIONS
	itimes = p4 ; how many times to repeat: 1 means original + 1 repetition

;find amplitudes for multitap, insert 0, when not needed
	index = 0
mark1:
	iamp[index] =  (index<itimes)  ?  1 - (index+1)/5 : 0
	loop_lt index, 1, $MAXREPETITIONS, mark1
	
	irepeatAfter = p5 ; repeat after given squareDurations
	ivoice = p6
	
	gkIsPlaying[ivoice] init 1
	
	iloopTime = irepeatAfter * i(gkSquareDuration[ivoice])
	ilastLoop = itimes * irepeatAfter * i(gkSquareDuration[ivoice])
	print itimes, irepeatAfter ;, ilastLoop
		
	if (itimes>0) then 
		adummy delayr iloopTime*6
		atime interp gkDeviation[ivoice]
		;ktempfreq =5 + jspline(4,0.1,10)
		;atime = 0.01 + poscil(0.005, ktempfreq)

		adel1 deltapi  iloopTime*atime
		adel2 deltapi  iloopTime*2*atime
		adel3 deltapi  iloopTime*3*atime
		adel4 deltapi iloopTime*4*atime
		adel5 deltapi iloopTime*5*atime
		
		adelayed = adel1*iamp[0]+ adel2*iamp[1] + adel3*iamp[2] + adel4*iamp[3] + adel5*iamp[4] 		
		delayw gaSignal[ivoice]
		;adelayed multitap gaSignal[ivoice], iloopTime, iamp[0], iloopTime*2, iamp[1], iloopTime*3, iamp[2], iloopTime*4, iamp[3], iloopTime*5, iamp[4]  
	else
		adelayed = 0	
	endif
	
	adeclick linen 1,0.1,p3,0.5 ;1,0.1,0.5, 0.001
	aout = gaSignal[ivoice] + adelayed
	aout clip aout, 0, 0dbfs ; for any case
	aout = aout*port(gkLevel,0.02)*adeclick ;*(0.1+gkattention*0.9)
	
	aL, aR pan2 aout, giPan[ivoice] ; now: hard left, center, hard right
	outs aL, aR
	gaSignal[ivoice] = 0
	if (release()==1) then
		gkIsPlaying[ivoice] = 0
	endif
endin



</CsInstruments>
<CsScore>

</CsScore>
</CsoundSynthesizer>
<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>0</x>
 <y>0</y>
 <width>158</width>
 <height>317</height>
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
  <objectName>active</objectName>
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
  <x>39</x>
  <y>292</y>
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
  <maximum>3</maximum>
  <randomizable group="0">false</randomizable>
  <value>0</value>
 </bsbObject>
</bsbPanel>
<bsbPresets>
</bsbPresets>
