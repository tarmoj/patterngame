Patterngame
=============

Interactive soundgame developed for Participation concerts http://tarmo.uuu.ee/osaluskontserdid/

Languages used:
User interface: written in html5, javascript
Communication between clients and server: websockets
Sound syntehsis: Csound
Main server program (WS-server, Csound-API, GUI): Qt C++, QML
Controller app (control.qml): QML

Users need to go to local wifi network, open the user interface (for example patterngame.html),
build using the matrix a melodu, determine how many times to repeat and after chich duration. Users can 
listen to the melody (using WebAudio functions) and send it to the server.

WS server sends incoming commands to Csound soundengine and UI that displays the melodies in three different voices.

The Csound engine plays back the sounds from PA, with the control app it is possible to change unit durations, 
sounds of the isntruments, delay durations, scales etc.

Copyright: Tarmo Johannes 2014 tarmo@otsakool.edu.ee
