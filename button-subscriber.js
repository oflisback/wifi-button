// Usage: node button-subscriber [<MQTT Broker address>]

const mqtt = require('mqtt')  
const client = mqtt.connect({host: '77.80.148.164', port: 1883})
const open = require('open')
const fs = require('fs')

console.log('Starting subscriber.')

client.on('connect', () => {  
  client.subscribe('sensors/button')
})

client.on('message', (topic, message) => {  
    if (message.toString() == "down") {
       console.log('button down!')
       fs.appendFile('/tmp/buttondowns.txt', date.toTimeString() + ': button down'); 
    }
})
