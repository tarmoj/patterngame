// WEBSOCKET FUNCTIONS -----------------------------------
	
	//var serverURL = "ws://johannes.homeip.net:8008/ws";
	
	function doConnect()
	{
		websocket = new WebSocket(document.myform.url.value);
		websocket.onopen = function(evt) { onOpen(evt) };
		websocket.onclose = function(evt) { onClose(evt) };
		websocket.onmessage = function(evt) { onMessage(evt) };
		websocket.onerror = function(evt) { onError(evt) };
	}

	function onOpen(evt)
	{
		writeToScreen("connected\n");
		document.myform.connectButton.disabled = true;
		document.myform.sendButton.disabled = false;
	}

	function onClose(evt)
	{
		writeToScreen("state: disconnected\n");
		document.myform.connectButton.disabled = false;
		document.myform.sendButton.disabled = true;
	}

	function onMessage(evt)
	{
		// does server send any messages at all?
		writeToScreen("Message from server: " + evt.data + '\n');
 		var mess_array = evt.data.split(" ");
 		//console.log(mess_array[0]);
 		if (mess_array[0] == "pause") {	
			listenButton.disabled = true;
			document.getElementById("messageText").innerHTML = "Wait and listen!"
 		}
 		if (mess_array[0] == "continue") {	
			listenButton.disabled = false;
			document.getElementById("messageText").innerHTML = "";
 		}
	}

	function onError(evt)
	{
		writeToScreen('error (' + document.myform.url.value + ') ' + evt.data + '\n');
		websocket.close();
		connectButton.disabled = false;
		document.myform.sendButton.disabled = true;
	}

	function doSend(message)
	{
		// how to check if websocket is open?
		if (websocket.readyState == 1) {
			websocket.send(message);
			writeToScreen("sent: " + message + '\n');
		} else 
			writeToScreen("WebSocket is not open!");
	}

	
	function writeToScreen(message)
	{
	//alert(message);
	var outputtext = document.getElementById("outputtext");
	outputtext.value += message;
	outputtext.scrollTop = outputtext.scrollHeight;
	}