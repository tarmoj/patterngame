// main functions for pattergame.html

	var MAX_NOTES = 10, MAX_PITCHES = 10;
	var INACTIVE = 0; ACTIVE = 1;
	var color = ["darkgreen", "lawngreen"]; 
	//var value_matrix = []; // values of the notes - []
	var steps =  [1, 25/21, 9/7, 7/5, 5/3, 9/5, 15/7, 7/3, 25/9, 3/1 ]; // Bohlen-Pierce just //[1, 8/7, 4/3,   14/9,  16/9, 2]; // pseudo slendro // kind of natural:[1,11/10, 5/4, 4/3, 3/2, 7/4,2];
	var baseFrequency = 110; // TODO: sama, mis Csoundi mootoris

// 	function invert(value) {return (value==0) ? 1 : 0;} // since js !(not) operation works only on booleans
	
	var note_rect = [[]];  // 2d array with rects and also on-off info [time_index - column][pitch_index - row]
	
	      // WEBAUDIO functions --------------------------

      
    var context; // miks class-ist väljas?
    var squareDuration = 0.25;
      
	function PlayPattern() {  // parem pane see window.onload ja kasuta play tavalise funktsioonina...
	
		
		this.repeatCount=1;
		this.delay=4;
	}
	
	PlayPattern.prototype.getPitchIndex =  function(column) { // returns pitchindex (which square is selected in a column) or -1
		var selected = -1;
		for (var i=0; i<MAX_PITCHES; i++) {
			if (note_rect[column][i].getAttr('onoff') == 1 ) {
				selected = i;
			}
		}
		return selected;
      }
	
	PlayPattern.prototype.playSound = function(frequency, startTime,duration) {
			
		var oscillator = context.createOscillator();
		oscillator.type = "triangle"; // Square wave
		var gainNode = context.createGain();
		oscillator.connect(gainNode);
		gainNode.connect(context.destination);
		var now = context.currentTime + startTime;
		var amp = 0.2;
		
		gainNode.gain.cancelScheduledValues(now);
		gainNode.gain.linearRampToValueAtTime(0, now );
		gainNode.gain.linearRampToValueAtTime(amp, now +0.01);
		gainNode.gain.linearRampToValueAtTime(amp, now +0.01);
		gainNode.gain.exponentialRampToValueAtTime(0.001, now +duration);
		gainNode.gain.linearRampTo
		oscillator.frequency.value = frequency;
		
		oscillator.start(now);   
		oscillator.stop(now+duration);
	};
	
	PlayPattern.prototype.play= function() {
		var now = context.currentTime;
		var startTime = 0;
		var pitchIndex = -1;
		var voice = parseInt(getRadioValue("octave"));
		console.log("Voice: ",voice);
		console.log(this.repeatCount);
		for (var a= 0; a<=this.repeatCount; a++ ) {
			console.log("Repeat: ",this.repeatCount);
			for (var i=0;i<MAX_NOTES; i++) {
				pitchIndex = this.getPitchIndex(i);
				startTime = a*this.delay*squareDuration+i*squareDuration ;
				//console.log("Iter, Start: ", a, startTime);
				if (pitchIndex!=-1) { 
					this.playSound(baseFrequency*steps[pitchIndex]*(1<<voice),startTime ,squareDuration*1.25);	
				}
			}
		}
	};
	
	 var oscil = new PlayPattern();
     
	window.onload = function() {
		doConnect();
        // webaudio:
        try {
		// Fix up for prefixing
		window.AudioContext = window.AudioContext||window.webkitAudioContext;
		context = new AudioContext();
		}
		catch(e) {
			alert('Web Audio API is not supported in this browser');
			return;
		}  
	
		// for compatibility
		if (!context.createGain)
			context.createGain = context.createGainNode;
		if (!context.createDelay)
			context.createDelay = context.createDelayNode;
		if (!context.createScriptProcessor)
			context.createScriptProcessor = context.createJavaScriptNode;
                //oscil.playSound(10,0.1,0.1) ; // to activate sound engine an let it crackle... - vist pole abi
		oscil.repeatCount = parseInt(document.myform.repeatCount.value);
		oscil.delay = parseInt(document.myform.delay.value);
		
		// UI values
		document.getElementById("repeat_label").innerHTML = parseInt(document.getElementById("repeatCount").value)+1;
		document.getElementById("delay_label").innerHTML = document.getElementById("delay").value;
		document.myform.mode.value="0";
		setMode(0);
		drawEverything();
		
     };
     
     function getRadioValue(name) {
		var elements = document.getElementsByName(name);
		var radioValue;
		for (var i=0;  i<elements.length; i++) {
			if (elements[i].checked) {
				radioValue = elements[i].value;
			}
		}
		return radioValue;
	}
	
     
// 	function handleClick(rectangle) {
// 					console.log("clicked. Object:", rectangle);
// 		var this_column = rectangle.getAttr("time_index");
// 		var newValue = (rectangle.getAttr('onoff')==0) ? 1 : 0 ; // toggle the value
// 			
// 		if (newValue == 1) // play sound to give idea about the pitch
// 			oscil.playSound(baseFrequency*steps[rectangle.getAttr("pitch_index")],0.05,0.5);
// 			
// 		// check if any other rect is swithced on, and turn it off - only one note selected in a column:
// 		for (var i=0; i<MAX_PITCHES; i++) {
// 			if (note_rect[this_column][i].getAttr('onoff') == 1 ) {
// 				note_rect[this_column][i].setAttr('onoff', 0);
// 				note_rect[this_column][i].fill(color[INACTIVE]);
// 			}
// 		}
// 		rectangle.setAttr('onoff', newValue);
// 		rectangle.fill(color[newValue]);
// 	}
	
	//var imageObj = new Image();
      //imageObj.onload = function() {  
      function drawEverything() { 
       var stage = new Kinetic.Stage({
          container: 'container',
          width: 460,
          height: 460
        });
        
        var padding = (stage.getHeight()-32)*0.2/MAX_PITCHES;
		var square_width = (stage.getHeight()-32)*0.7/MAX_PITCHES; //(stage.getHeight()-24)*0.8/MAX_PITCHES; //((Math.min( (stage.getWidth()-8)*0.8/MAX_NOTES, (stage.getHeight()+8)*0.8/MAX_PITCHES );
		//console.log(padding, square_width);
		//stage.setHeight();
        
        var layer = new Kinetic.Layer();
        
        var label1 =  new Kinetic.Text({ x: 4, y: 4,text: "1", fill: 'yellow', fontSize: 24  });
        layer.add(label1);
        var label2 =  new Kinetic.Text({ x: stage.getWidth()-20, y: 4,text: "2", fill: 'yellow', fontSize: 24  });
        layer.add(label2);
        var label3 =  new Kinetic.Text({ x: 4, y: 150,text: "3", fill: 'yellow', fontSize: 24  });
        layer.add(label3);
        var label4 =  new Kinetic.Text({ x: stage.getWidth()-20, y: 150,text: "4", fill: 'yellow', fontSize: 24  });
        layer.add(label4);
        var label5 =  new Kinetic.Text({ x: 4, y: 350,text: "5", fill: 'yellow', fontSize: 24  });
        layer.add(label5);
        var label6 =  new Kinetic.Text({ x: stage.getWidth()-20, y: 350,text: "6", fill: 'yellow', fontSize: 24  });
        layer.add(label6);
        var label7 =  new Kinetic.Text({ x: stage.getWidth()/2+4, y: 4,text: "7", fill: 'yellow', fontSize: 24  });
        layer.add(label7);
        var label8 =  new Kinetic.Text({ x: stage.getWidth()/2+4, y: 440,text: "8", fill: 'yellow', fontSize: 24  });
        layer.add(label8);
        
        
        
        var border_rect = new Kinetic.Rect({
			width: (square_width+padding)*MAX_NOTES+padding,
			height: (square_width+padding)*MAX_PITCHES+padding,
			x: 32, y:32,
			stroke: 'lightgrey',
			strokeWidth: 3
		});
		layer.add(border_rect);
        
//         function handleClick(rectangle) {
// 				console.log("clicked.");
// 	}
		
		for (var column=0; column<MAX_NOTES; column++) {
			for (var row=0; row<MAX_PITCHES; row++) {
				note_rect[column][row] = new Kinetic.Rect({
					pitch_index: row,
					time_index: column,
					onoff:0,
					width: square_width,
					height: square_width, 
					x: column*(padding+square_width) + border_rect.x() + padding/2, 
					y: border_rect.y()+border_rect.getHeight() - (row+1)*(padding+square_width),
					fill: color[INACTIVE],
					stroke: color[ACTIVE], 
					cornerRadius: square_width/8,
					strokeWidth: 1, 
				});
				//note_rect[column][row].setAttr('onoff',0); // add a property about wether on or off default is off
				layer.add(note_rect[column][row]);
				
				
				// TODO: leia, miks ei saa kasutada eraldi funktsiooni (function handleClick
				note_rect[column][row].on("touchstart", function () { 
					var this_column = this.getAttr("time_index");
					var newValue = (this.getAttr('onoff')==0) ? 1 : 0 ; // toggle the value
					var voice = parseInt(getRadioValue("octave"));
						
					if (newValue == 1) // play sound to give idea about the pitch
						oscil.playSound(baseFrequency*steps[this.getAttr("pitch_index")]*(1<<voice),0,0.75);
						
					// check if any other rect is swithced on, and turn it off - only one note selected in a column:
					for (var i=0; i<MAX_PITCHES; i++) {
						if (note_rect[this_column][i].getAttr('onoff') == 1 ) {
							note_rect[this_column][i].setAttr('onoff', 0);
							note_rect[this_column][i].fill(color[INACTIVE]);
						}
					}
					this.setAttr('onoff', newValue);
					this.fill(color[newValue]);
					layer.draw();
				});
				
				
				note_rect[column][row].on("click", function () { 
					var this_column = this.getAttr("time_index");
					var newValue = (this.getAttr('onoff')==0) ? 1 : 0 ; // toggle the value
					var voice = parseInt(getRadioValue("octave"));	
					if (newValue == 1) // play sound to give idea about the pitch
						oscil.playSound(baseFrequency*steps[this.getAttr("pitch_index")]*(1<<voice),0,0.75);
						
					// check if any other rect is swithced on, and turn it off - only one note selected in a column:
					for (var i=0; i<MAX_PITCHES; i++) {
						if (note_rect[this_column][i].getAttr('onoff') == 1 ) {
							note_rect[this_column][i].setAttr('onoff', 0);
							note_rect[this_column][i].fill(color[INACTIVE]);
						}
					}
					this.setAttr('onoff', newValue);
					this.fill(color[newValue]);
					layer.draw();
				});
			}
			note_rect.push([]); // to define next row
		}
        stage.add(layer); 
        
        
        layer.draw(); 
      };
      //imageObj.src = 'img.png';

      
      
      
	function setMode(mode) {
		//var mode = parseInt(document.myform.mode.value);
		document.myform.mode.value = mode;
		//document.myform.mode.disabled = true;
		switch (mode) {
			case 0:
				MAX_NOTES = 6;
				MAX_PITCHES = 6;
				steps = [1, 8/7, 4/3,   14/9,  16/9, 2];
				drawEverything();
				break;
			case 1: 
				MAX_NOTES = 8;
				MAX_PITCHES = 8;
				steps = [1, 35/32, 5/4, 21/16, 49/32, 105/64, 7/4, 2]; // pelog-harrsion
				drawEverything();
				break;
			case 2:
				MAX_NOTES = 10;
				MAX_PITCHES = 10;
				steps = [1, 25/21, 9/7, 7/5, 5/3, 9/5, 15/7, 7/3, 25/9, 3/1 ]; 
				drawEverything();
				break;
		}
	}
	
	function onMessage(evt)
	{
		// does server send any messages at all?
		writeToScreen("Message from server: " + evt.data + '\n');
 		var mess_array = evt.data.split(",");
 		//console.log(mess_array[0]);
 		if (mess_array[0] == "mode") {	
			setMode(parseInt(mess_array[1]));
 		}
	}
	
	
	function sendEvent() {
		// message format: 'pattern' name voice repeatNtimes afterNsquares  speaker/pan steps: pitch_index11 pitch_index2 etc
		var parameters = ['pattern'];
		parameters.push(document.myform.name.value); // TODO: check if there is comma, either split in server may not work
		parameters.push(getRadioValue("octave"));
		parameters.push(document.myform.repeatCount.value);
		parameters.push(document.myform.delay.value);
		parameters.push(getRadioValue("speaker"));
		parameters.push("steps:")
		// add all pitchindexes (either step number of -1 if nunselected
		for (var i=0;i<MAX_NOTES; i++) {
				parameters.push(oscil.getPitchIndex(i));
		}
		
		var messageString = parameters.join(","); // join with comma
		console.log("To be sent: ",messageString)
		doSend(messageString);
		myform.sendButton.disabled = true;
		setTimeout(function(){ myform.sendButton.disabled = false;},2000);
	}