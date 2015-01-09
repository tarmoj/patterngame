<CsoundSynthesizer>
<CsOptions>
-d
-odac:system:playback_ -+rtaudio=jack 
</CsOptions>
<CsInstruments>

sr = 44100
nchnls = 2
0dbfs = 1
ksmps = 1

#define MAXREPETITIONS  #5#

;GLOBALS: 
giPseudoSlendro[] fillarray  1, 8/7, 4/3,   14/9,  16/9, 2
giPelogHarrison[]  fillarray 1, 35/32, 5/4, 21/16, 49/32, 105/64, 7/4, 2

giBohlenJust[]  fillarray 1, 25/21, 9/7, 7/5, 5/3, 9/5, 15/7, 7/3, 25/9, 3/1 

giSteps[] init 16
giSteps  =  giBohlenJust ;giPelogHarrison;giBohlenJust ;
giBaseFrequency = 110 ;cpspch(5.02)

giPatternLength = 10;7 ; check taht would be same as in html interface
gimaxPitches  lenarray  giSteps

gkSquareDuration[] fillarray 0.25, 0.25, 0.25
gkClock[] init 3
giPan[] fillarray 0.5, 1, 0


giMatrix[][]  init   3,giPatternLength  ; first dimension - voice, second: step or -1
;giMatrix[]  init   giPatternLength   ; table to contain which step from scale to play. -1 for don't play  0 - 1st step etc


gaSignal[] init 3

gkIsPlaying[] init 3 ; flags the show if the voice is playing

;CHANNELS:
; for brainwaves:
chn_k "attention", 1
chn_k "meditation", 1
chn_k "lowBetaRelative", 1
chn_k "highBetaRelative", 1
chn_k "lowGammaRelative", 1
chn_k "midGammaRelative",1 

chnset 1, "active1" ; if init 1 then it will set to 0 in first k-cycle?
chnset 1,"tempo"
chnset 0.8, "level"
;

seed 0

; to test:

;gkSquareDuration[0] init 2
;gkSquareDuration[1] init 1
;gkSquareDuration[2] init 4

;schedule "randomPattern", 0, 0, 0, 1
;schedule "randomPattern", 1, 0, 1, 1
;schedule "randomPattern", 2.1, 0, 2, 1 ; last 1 if to repeat
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
		schedule	"randomPattern", (giPatternLength+1)*i(gkSquareDuration[ivoice]), 0, ivoice, iloop
	endif
endin

alwayson "clockAndChannels"
instr clockAndChannels 
	
	;gkTempo chnget "tempo" ; 1 - normal, <1 - slower, >1 - faster
	gkLevel chnget "level"
	
	; for brainwavese version:
	; for brainwaves: ----------
	kmed chnget "meditation"
	gkattention = port(chnget:k("attention"),0.1 )
	gkmeditation = port(chnget:k("meditation"),0.1 )
	gklowBetaRelative = port(chnget:k("lowBetaRelative"),0.1) 
	gkhighBetaRelative = port(chnget:k("highBetaRelative"),0.1)
	gklowGammaRelative chnget "lowGammaRelative"
	gkmidGammaRelative chnget "midGammaRelative"
	
	
	
	; to sync incoming messages:		
	gkClock[0] metro (0.5+gkattention)*1/gkSquareDuration[0]
	gkClock[1] metro 1/gkSquareDuration[1]
	gkClock[2] metro 1/gkSquareDuration[2]
	
endin


;schedule "playPattern",0.21,0,0, 4, 0
;schedule "playPattern",0,0,0, 4, 2
instr playPattern ; takes care thta incoming messages start "on tick"
	idur = p3
	p3 = 10 ; for any case
	ivoice = p6
	if (gkClock[ivoice]==1) then 
		event "i", "playPattern_i", 0, idur,p4,p5,p6
		printk2 gkClock[ivoice] 
		turnoff	
	endif
endin

;schedule "playPattern",0,0,0, 4, 2
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
	if (istep != -1) then
		ifreq =	(1<<ivoice)*giBaseFrequency*giSteps[istep]
		print istep,ifreq
		schedule	"sound", index*i(gkSquareDuration[ivoice]), i(gkSquareDuration[ivoice]), 0.2,ifreq , ivoice 
	endif
	loop_lt index, 1, giPatternLength, loophere
		
endin

; schedule "sound", 0,  0.25, 0.1, 440
instr sound
	iamp = p4
	ifreq =  p5
	ivoice = p6
	iatt = 0.05
	;aenv expseg 0.0001, iatt, 1, p3-iatt, 0.0001
	aenv adsr 0.01,0.01,0.5, p3/2
	; TODO: proovi adsr
	isound chnget "sound"
	if (isound==0) then 
		asig poscil aenv,ifreq*(0.5+gkattention*1.5)	 ; gkattention to test only for brainwaves
	elseif (isound==1) then	
		asig vco2 k(aenv), ifreq
		asig moogladder asig, line(ifreq*6,p3,ifreq*2), 0.8
	else
		asig pinker
		asig moogvcf asig*iamp, line(ifreq*6,p3,ifreq*2), 0.9	
	endif
	
	
	; for brainwaves version:	
	
	kchebLevel = 1+gkmeditation
	; ei toimi rahuldavalt, - kmeditaioni muutus pole piisavalt kuulda
	;asig chebyshevpoly asig, 1,  gklowBetaRelative *kchebLevel,  gkhighBetaRelative*kchebLevel  
	
;	1,0, gklowBetaRelative *kchebLevel, 
;	0, gkhighBetaRelative*kchebLevel, gklowGammaRelative*kchebLevel, 
;	0, gkmidGammaRelative*kchebLevel
	
	gaSignal[ivoice] = gaSignal[ivoice] + asig*iamp ;*aenv*iamp
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
	
	iloopTime = irepeatAfter * i(gkSquareDuration[ivoice])
	;ilastLoop = itimes * irepeatAfter * gkSquareDuration
	print itimes, irepeatAfter ;, ilastLoop
	
	if (itimes>0) then 
		;adelayed delayr ilastLoop
		adelayed multitap gaSignal[ivoice], iloopTime, iamp[0], iloopTime*2, iamp[1], iloopTime*3, iamp[2], iloopTime*4, iamp[3], iloopTime*5, iamp[4]  
	else
		adelayed = 0	
	endif
	
	
;	adel1 deltapi  irepeatAfter * gkSquareDuration
;	adel2 deltapi  2 * irepeatAfter *gkSquareDuration
;	adel3 deltapi  3* irepeatAfter * gkSquareDuration
;	delayw gaSignal
	aout = gaSignal[ivoice] + adelayed
	aout clip aout, 0, 0dbfs ; for any case
	
	;adelayed multitap gaSignal, iLooptTime, 1, iLooptTime*2, 0.8, iLooptTime*3, 0.7
	
;	adelaytime init  iLooptTime*1000
;	adelaytime expon iLooptTime*1000, p3,  iLooptTime*1000/2
;	adelayed vdelay gaSignal, adelaytime,  iLooptTime*1000

	;aout = gaSignal + gaDelayed 
	aL, aR pan2 aout*port(gkLevel,0.02), giPan[ivoice] ; now: hard left, center, hard right
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
 <bsbObject version="2" type="BSBButton">
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
 <bsbObject version="2" type="BSBButton">
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
  <latched>true</latched>
 </bsbObject>
 <bsbObject version="2" type="BSBButton">
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
  <latched>true</latched>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
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
 <bsbObject version="2" type="BSBHSlider">
  <objectName>meditation</objectName>
  <x>260</x>
  <y>108</y>
  <width>108</width>
  <height>30</height>
  <uuid>{ceaf72bd-ea45-4832-a6f5-28fb9834d99d}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>173</x>
  <y>110</y>
  <width>80</width>
  <height>26</height>
  <uuid>{d4bddaac-f239-47cd-8fba-8fde41a73fcd}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>Meditation</label>
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
 <bsbObject version="2" type="BSBHSlider">
  <objectName>attention</objectName>
  <x>263</x>
  <y>145</y>
  <width>108</width>
  <height>30</height>
  <uuid>{53512250-33af-4df4-badb-1d7d657537e8}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.50925926</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>172</x>
  <y>145</y>
  <width>80</width>
  <height>26</height>
  <uuid>{c28ebf97-4c5a-496b-8c26-9530354bae4d}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>Attention</label>
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
 <bsbObject version="2" type="BSBHSlider">
  <objectName>lowBetaRelative</objectName>
  <x>264</x>
  <y>178</y>
  <width>108</width>
  <height>30</height>
  <uuid>{29189bb2-45ed-4c6c-ad46-00ee2c064799}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>1.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>172</x>
  <y>181</y>
  <width>80</width>
  <height>26</height>
  <uuid>{f95640a2-4be1-4c9d-a0d9-06dbfd7cf31b}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>Lowbeta</label>
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
 <bsbObject version="2" type="BSBHSlider">
  <objectName>highBetaRelative</objectName>
  <x>263</x>
  <y>219</y>
  <width>108</width>
  <height>30</height>
  <uuid>{9b3079ab-97b1-46e9-bb31-6271b2862802}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.88888889</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>172</x>
  <y>220</y>
  <width>80</width>
  <height>26</height>
  <uuid>{144456d7-768a-4ade-a4fa-af24c7fdc857}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>Highbeta</label>
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
