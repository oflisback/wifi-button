// Usage: node button-subscriber [<MQTT Broker address>]

const mqtt = require('mqtt')  
const client = mqtt.connect({host: '192.168.0.180', port: 1883})
const castip = '192.168.0.47'
const p3url = 'http://sverigesradio.se/topsy/direkt/164-hi.mp3'
const stopurl = 'http://olle'
const open = require('open')
const fs = require('fs')
const exec = require('child_process').exec;

console.log('Starting subscriber.')

var process = null;

client.on('connect', () => {  
  client.subscribe('button')
})

client.on('message', (topic, message) => {  
    var state = message.toString();
    if (state == "down") {
      // Start streaming with castaway targeting google chrome speaker and using
      // sr api, probably:
      console.log('button down!')
      var d = new Date();
      fs.appendFile('/tmp/buttondowns.txt', d.toTimeString() + ': button down');
      // or more concisely
      if (process != null) {
        process.kill();
      }
      var cmd = "castnow --address " + castip + " " + p3url;
      console.log("cmd: " + cmd);
      process = exec(cmd, (error, stdout, stderr) => {
        if (error) {
          console.error(`exec error: ${error}`);
          return;
        }
        console.log(`stdout: ${stdout}`);
        console.log(`stderr: ${stderr}`);
      });
    } else if (state == 'up') {
      if (process != null) {
        process.kill();
      }
      var cmd = "castnow --address " + castip + " " + stopurl;
      console.log("cmd: " + cmd);
      process = exec(cmd, (error, stdout, stderr) => {
        if (error) {
          console.error(`exec error: ${error}`);
          return;
        }
        console.log(`stdout: ${stdout}`);
        console.log(`stderr: ${stderr}`);
      });
    }
})
