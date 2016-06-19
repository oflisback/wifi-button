// Usage: node button-subscriber [<MQTT Broker address>]

const mqtt = require('mqtt')  
const client = mqtt.connect({host: process.argv.length == 3 ? process.argv[2] : "localhost", port: 1883})
const open = require('open')

client.on('connect', () => {  
  client.subscribe('sensors/button')
})

client.on('message', (topic, message) => {  
    if (message.toString() == "down") {
      open("https://www.youtube.com/watch?v=oHg5SJYRHA0")
    }
})
