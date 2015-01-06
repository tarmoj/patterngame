<CsoundSynthesizer>
<CsOptions>
-d
-odac 
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
giSteps  =  giBohlenJust ;giBohlenJust ;giPelogHarrison
giBaseFrequency = cpspch(6.02)

giPatternLength = 7 ; chech taht would be same as in html interface
gimaxPitches  lenarray  giSteps
print gimaxPitches
giSquareDuration[] fillarray 0.22, 0.55, 0.1
giPan[] fillarray 0.5, 1, 0

giMatrix[]  init   3,giPatternLength  ; first dimension - voice, second: step or -1
;giMatrix[]  init   giPatternLength   ; table to contain which step from scale to play. -1 for don't play  0 - 1st step etc


gaSignal[] init 3

gkIsPlaying[] init 3 ; flags the show if the voice is playing

;CHANNELS:
chn_k "active", 2
chnset 0, "active"


seed 0

; schedule "randomPattern", 0, 0, 0, 1
; schedule "randomPattern", 0, 0, 1, 1
; schedule "randomPattern", 0, 0, 2, 1 ; last 1 if to repeat
instr randomPattern
	index = 0
	ivoice = p4
	iloop = p5
	
loophere:
	giMatrix[ivoice][index] = limit(int(random:i(-gimaxPitches/2,gimaxPitches)), -1, gimaxPitches)
	
	print index, giMatrix[ivoice][index]
	loop_lt index, 1, giPatternLength, loophere
	schedule "playPattern",0,0,  int(random:i(0,4)), int(random:i(2,8)), ivoice
	if (iloop>0) then
		schedule	"randomPattern", (giPatternLength+1)*giSquareDuration[ivoice], 0, ivoice, iloop
	endif
endin

;schedule "playPattern",0,0,0, 4, 0
instr playPattern
	itimes = p4 ; how many times to repeat: 1 means original + 1 repetition
	irepeatAfter = p5 ; repeat after given squareDurations
	ivoice = p6 ; three voices
	itotalTime = giPatternLength*giSquareDuration[ivoice] + itimes*irepeatAfter*giSquareDuration[ivoice]
	print ivoice, itotalTime
	index = 0

	schedule "loopPlay", 0, itotalTime,  itimes, irepeatAfter, ivoice  
	; play sounds
loophere:
	istep = giMatrix[ivoice][index] 
	if (istep != -1) then
		schedule	"sound", index*giSquareDuration[ivoice], giSquareDuration[ivoice], 0.2, (1<<ivoice)*giBaseFrequency*istep, ivoice 
	endif
	loop_lt index, 1, giPatternLength, loophere
		
endin

; schedule "sound", 0,  0.25, 0.1, 440
instr sound
	iamp = p4
	ifreq =  p5
	ivoice = p6
	iatt = 0.05
	aenv expseg 0.001, iatt, iamp, p3-iatt, 0.0001
	isound chnget "sound"
	if (isound==0) then 
		asig poscil aenv,ifreq
	elseif (isound==1) then	
		asig vco2 k(aenv), ifreq
		asig moogladder asig, line(ifreq*6,p3,ifreq*2), 0.8
	else
		asig pinker
		asig moogvcf asig*iamp, line(ifreq*6,p3,ifreq*2), 0.9	
	endif
	gaSignal[ivoice] = gaSignal[ivoice] + asig
	
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
	
	iloopTime = irepeatAfter * giSquareDuration[ivoice]
	;ilastLoop = itimes * irepeatAfter * giSquareDuration
	print itimes, irepeatAfter ;, ilastLoop
	
	if (itimes>0) then 
		;adelayed delayr ilastLoop
		adelayed multitap gaSignal[ivoice], iloopTime, iamp[0], iloopTime*2, iamp[1], iloopTime*3, iamp[2], iloopTime*4, iamp[3], iloopTime*5, iamp[4]  
	else
		adelayed = 0	
	endif
	
	
;	adel1 deltapi  irepeatAfter * giSquareDuration
;	adel2 deltapi  2 * irepeatAfter *giSquareDuration
;	adel3 deltapi  3* irepeatAfter * giSquareDuration
;	delayw gaSignal
	aout = gaSignal[ivoice] + adelayed
	aout clip aout, 0, 0dbfs ; for any case
	
	;adelayed multitap gaSignal, iLooptTime, 1, iLooptTime*2, 0.8, iLooptTime*3, 0.7
	
;	adelaytime init  iLooptTime*1000
;	adelaytime expon iLooptTime*1000, p3,  iLooptTime*1000/2
;	adelayed vdelay gaSignal, adelaytime,  iLooptTime*1000

	;aout = gaSignal + gaDelayed 
	aL, aR pan2 aout, giPan[ivoice] ; now: hard left, center, hard right
	outs aL, aR
	gaSignal[ivoice] = 0
	if (release()==1) then
		gkIsPlaying[ivoice] = 0
	endif
endin



alwayson "countInstances"
instr countInstances
	chnset gkIsPlaying[0], "active1"
	chnset gkIsPlaying[1], "active2"
	chnset gkIsPlaying[2], "active3"
	
	;kactive active "loopPlay" 
	;chnset  kactive, "active"
	; later - do in host, check, if "active" < 1 etc
;	if (changed(kactive)==1 && kactive==0)  then
;		event "i","randomPattern",0,0,0
;	endif
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
 <height>219</height>
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
  <objectName>sound</objectName>
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
  <maximum>2</maximum>
  <randomizable group="0">false</randomizable>
  <value>0</value>
 </bsbObject>
</bsbPanel>
<bsbPresets>
</bsbPresets>
