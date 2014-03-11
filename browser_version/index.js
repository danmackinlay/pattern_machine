var httpServer = require('http').createServer().listen(3000);
var socketIoServer = require('socket.io')();
var fs = require('fs');
var url = require('url');
var path = require('path');
var osc = require('osc-min');
var udp = require('dgram');
var util = require ('util');

util.log('requires done');

socketIoServer.serveClient(true);
socketIoServer.attach(httpServer);

httpServer.on('connection', function (socket) {
  socket.on('message', function () { });
  socket.on('close', function () { });
});
socketIoServer.on('connection', function(socket){
  socket.on('event', function(data){});
  socket.on('disconnect', function(){});
});
httpServer.on('request',function(request, response){
  console.log('request.url', request.url);
  
  if (request.url!=='/index.html') return;
  
  var filename = path.join(process.cwd(), 'public', 'index.html');
  console.log('filename', filename);
  
  fs.exists(filename, function(exists) {
   if(!exists) {
     response.writeHead(404, {'Content-Type': 'text/plain'});
     response.write('404 Not Found\n');
     response.end();
     return;
   }

   fs.readFile(filename, 'binary', function(err, file) {
     if(err) {        
       response.writeHead(500, {'Content-Type': 'text/plain'});
       response.write(err + '\n');
       response.end();
       return;
     }
     response.writeHead(200);
     response.write(file, 'binary');
     response.end();
   });
 });
});
var sock = udp.createSocket("udp4", function(msg, rinfo) {
  var error;
  try {
    return console.log(osc.fromBuffer(msg));
  } catch (_error) {
    error = _error;
    return console.log("invalid OSC packet");
  }
});
sock.bind(3001);
