<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>

sr = 44100
nchnls = 2
0dbfs = 1
ksmps = 64

#define MAXREPETITIONS  #5#

;GLOBALS: 
giPseudoSlendro[] fillarray  1, 8/7, 4/3,   14/9,  16/9, 2
giPelogHarrison[]  fillarray 1, 35/32, 5/4, 21/16, 49/32, 105/64, 7/4, 2

giBohlenJust[]  fillarray 1, 25/21, 9/7, 7/5, 5/3, 9/5, 15/7, 7/3, 25/9, 3/1 

giSteps[] init 16
giSteps  =  giPseudoSlendro ;giBohlenJust ;giPelogHarrison
giBaseFrequency = 440

giPatternLength = 7 ; chech taht would be same as in html interface
gimaxPitches  lenarray  giSteps
print gimaxPitches
giSquareDuration = 0.25

giMatrix[]  init   giPatternLength   ; table to contain which step from scale to play. -1 for don't play  0 - 1st step etc

gaSignal init 0

gkIsPlaying[] init 3 ; flags the show if the voice is playing

;CHANNELS:
chn_k "active", 2
chnset 0, "active"


seed 0



;schedule "randomPattern", 0, 0, 1 ; last 1 if to repeat
instr randomPattern
	index = 0
	iloop = p4
loophere:
	giMatrix[index] = limit(int(random:i(-gimaxPitches/2,gimaxPitches)), -1, gimaxPitches)
	
	print index, giMatrix[index]
	loop_lt index, 1, giPatternLength, loophere
	schedule "playPattern",0,0,  int(random:i(0,4)), int(random:i(2,8))
	if (iloop>0) then
		schedule	"randomPattern", (giPatternLength+1)*giSquareDuration, 0, iloop
	endif
endin

;schedule "playPattern",0,0,0, 4
instr playPattern
	itimes = p4 ; how many times to repeat: 1 means original + 1 repetition
	irepeatAfter = p5 ; repeat after given squareDurations
	ivoice = p6 ; three voices
	itotalTime = giPatternLength*giSquareDuration + itimes*irepeatAfter*giSquareDuration
	print itotalTime
	index = 0

	schedule "loopPlay", 0, itotalTime,  itimes, irepeatAfter, ivoice  
	; play sounds
loophere:
	if (giMatrix[index]!= -1) then
		schedule	"sound", index*giSquareDuration, giSquareDuration, 0.2, giBaseFrequency*giSteps[giMatrix[index] ]
	endif
	loop_lt index, 1, giPatternLength, loophere
		
endin

; schedule "sound", 0,  0.25, 0.1, 440
instr sound
	iamp = p4
	ifreq =  p5
	iatt = 0.05
	aenv expseg 0.001, iatt, iamp, p3-iatt, 0.0001
	asig poscil aenv,ifreq
	gaSignal += asig
	; TODO: panning/postitionig
	
	;outs asig, asig
	
endin

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
	
	iloopTime = irepeatAfter * giSquareDuration
	;ilastLoop = itimes * irepeatAfter * giSquareDuration
	print itimes, irepeatAfter ;, ilastLoop
	
	if (itimes>0) then 
		;adelayed delayr ilastLoop
		adelayed multitap gaSignal, iloopTime, iamp[0], iloopTime*2, iamp[1], iloopTime*3, iamp[2], iloopTime*4, iamp[3], iloopTime*5, iamp[4]  
	else
		adelayed = 0	
	endif
	
	
;	adel1 deltapi  irepeatAfter * giSquareDuration
;	adel2 deltapi  2 * irepeatAfter *giSquareDuration
;	adel3 deltapi  3* irepeatAfter * giSquareDuration
;	delayw gaSignal
	aout = gaSignal + adelayed
	
	;adelayed multitap gaSignal, iLooptTime, 1, iLooptTime*2, 0.8, iLooptTime*3, 0.7
	
;	adelaytime init  iLooptTime*1000
;	adelaytime expon iLooptTime*1000, p3,  iLooptTime*1000/2
;	adelayed vdelay gaSignal, adelaytime,  iLooptTime*1000

	;aout = gaSignal + gaDelayed 
	outs aout, aout
	gaSignal = 0
	if (release()==1) then
		gkIsPlaying[ivoice] = 0
	endif
endin



alwayson "countInstances"
instr countInstances
	chnset gkIsPlaying[0], "active1"
	chnset gkIsPlaying[1], "active2"
	chnset gkIsPlaying[2], "active3"
	
	kactive active "loopPlay" 
	chnset  kactive, "active"
	; later - do in host, check, if "active" < 1 etc
	if (changed(kactive)==1 && kactive==0)  then
		event "i","randomPattern",0,0,0
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
 <width>0</width>
 <height>0</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="nobackground">
  <r>255</r>
  <g>255</g>
  <b>255</b>
 </bgcolor>
 <bsbObject version="2" type="BSBButton">
  <objectName>play pattern</objectName>
  <x>58</x>
  <y>101</y>
  <width>100</width>
  <height>30</height>
  <uuid>{fd46780e-b7e0-4087-9b8b-311012e6066d}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <type>event</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>button0</text>
  <image>/</image>
  <eventLine>i "randomPattern" 0 0 0</eventLine>
  <latch>false</latch>
  <latched>true</latched>
 </bsbObject>
 <bsbObject version="2" type="BSBDisplay">
  <objectName>active</objectName>
  <x>78</x>
  <y>194</y>
  <width>80</width>
  <height>25</height>
  <uuid>{77252a9a-278b-4382-a4b5-d989407aacc6}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>1.000</label>
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
</bsbPanel>
<bsbPresets>
</bsbPresets>
