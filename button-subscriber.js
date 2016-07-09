// Usage: node button-subscriber [<MQTT Broker address>]

const mqtt = require('mqtt')  
const client = mqtt.connect({host: '192.168.0.180', port: 1883})
const castip = '192.168.0.47'
const p3url = 'http://sverigesradio.se/topsy/direkt/164-hi.mp3'
const stopurl = 'http://olle'
const open = require('open')
const fs = require('fs')
const sys = require('sys')
const exec = require('child_process').exec;

console.log('Starting subscriber.')

client.on('connect', () => {  
  client.subscribe('sensors/button')
})

client.on('message', (topic, message) => {  
    if (message.toString() == "down") {
      // Start streaming with castaway targeting google chrome speaker and using
      // sr api, probably:
      console.log('button down!')
      var d = new Date();
      fs.appendFile('/tmp/buttondowns.txt', d.toTimeString() + ': button down');
      // or more concisely
      function puts(error, stdout, stderr) { console.log(stdout) }
      exec("castnow --address " + castip + " " + p3url, puts);
    } else {
      exec("castnow --address " + castip + " " + stopurl, puts);
    }
})
