[Foo Café](http://www.foocafe.org/) Malmö recently hosted an excellent beginner friendly IoT workshop where [Carl Wolff](https://gitlab.com/u/carlwolff) showed how to build a WiFi enabled button based on the small affordable ESP8266 chip. The idea was to let the button trigger a message to Slack but it can of course be used to control pretty much anything. :)

These are my notes based on the [workshop](https://gitlab.com/iot-malmo/emergency-fika-button) and some additional experiments. The complete implementation is available in this repository and most of the Lua implementation is based on a foobarflies.io [blog post](http://www.foobarflies.io/a-simple-connected-object-with-nodemcu-and-MQTT/).

## Hardware
Foo Café and their sponsors where generous enough to provide us with an ESP8266 SoC, wires and an emergency break button roomy enough to also hold the chip.

<p align="center">
  <img src="https://cloud.githubusercontent.com/assets/12221141/16176059/22bd81f0-3603-11e6-88c5-e581c9e5fc6f.jpg" width="220"/>
  <img src="https://cloud.githubusercontent.com/assets/12221141/16176060/22bf91d4-3603-11e6-9b42-9530092a440d.jpg" width="220"/>
  <img src="https://cloud.githubusercontent.com/assets/12221141/16176341/7b02e95a-360c-11e6-8cfc-0023fb059142.jpg" width="220"/>
  <img src="https://cloud.githubusercontent.com/assets/12221141/16176342/7b188436-360c-11e6-8892-bc3260faa098.jpg" width="220"/>
</p>

## Connect the chip

To flash, configure and program the chip we will use its microUSB connector. Connect it with the USB wire to your Linux computer. Windows or OS X will do too (at least for this specific project ..) but requires installation of additional drivers (links on [workshop page](https://gitlab.com/iot-malmo/emergency-fika-button)).

Verify that the chip is properly recognized:

```
$ lsusb
```

In the output you should have a line saying something like:

```
Bus 003 Device 015: ID 10c4:ea60 Cygnal Integrated Products, Inc. CP210x UART Bridge / myAVR mySmartUSB light
```

Now let's see which USB device the chip has been mapped to:

```
$ dmesg
```

Look for something like:

```
[33838.032229] usb 3-1: cp210x converter now attached to ttyUSB0
```

## Replace the firmware

The chip comes with some pre-installed firmware which we replace with the very beginner friendly [NodeMCU firmware](https://github.com/nodemcu/nodemcu-firmware), the main benefits for this project is that it comes with Lua support and easy to use modules for WiFi and MQTT.

Download a contemporary version of the nodemcu firmware, in the workshop we used this one:

```
http://nodemcu-build.com/builds/nodemcu-dev-15-modules-2016-06-12-21-15-31-integer.bin
```

Install [esptool.py](https://github.com/themadinventor/esptool), one way is to clone the repo and run:

```
$ sudo python setup.py install
```

Then flash the firmware:

```
$ esptool.py --baud 115200 --port /dev/ttyUSB0 write_flash --flash_mode dio --flash_size 32m 0x00000 nodemcu-dev-15-modules-2016-06-12-21-15-31-integer.bin
```

## Transfer files

To get a terminal connection to the chip and to transfer files among other things we can use use the Java tool [ESPlorer] http://esp8266.ru/esplorer/. Download then start:

```
$ java -jar ESPlorer.jar
```
 
On the left you'll see a file editor where Lua files can be written and then uploaded and written to flash. To the right we have device selection and need to set the baud rate 115200. Click open to connect.

## Hello, World!

 With a connection established in ESPlorer we can give Lua commands to be interpreted on the chip in the input box on the right, obligatory:

```
> print('Hello, World!')
```
We can also toggle the state of a led on the chip:

```
> gpio.mode(0,gpio.OUTPUT)
> gpio.write(0, gpio.LOW)
> gpio.write(0, gpio.HIGH)
```

## Connect WiFi

First let's ask the WiFi module to report the chip's IP-address:

```
> print(wifi.sta.getip())
nil
```

Unsurprisingly no IP-address is assigned, we need to configure WiFi:

```
> wifi.setmode(wifi.STATION)
> wifi.sta.config("My WiFi SSID", "My WiFi Password")
```

Now give it a few seconds and try again:

```
> print(wifi.sta.getip())
192.168.0.107	255.255.255.0	192.168.0.1
```

It's working!

## Wiring

From the chip, connect the pins named gnd to one side of the button and the pin named d1 to the other. Gnd is the second pin from one end of the board and d1 is the second pin from the other end.

If you don't have a button, you can fake the behavior if you like. Putting the loose ends of the cables together has the same effect as pressing the button, it closes the circuit between D1 and ground.

Configure the chip input:

```
> gpio.mode(1, gpio.INPUT, gpio.PULLUP)
```

Then poll the input expecting different values depending on if the button is pressed or not:

```
> print(gpio.read(1))
1
```

## Let the world know about the button event

When the button is pressed we want to send a message using our WiFi connection to give another system a chance to act,
our method of choice is MQTT.

### MQTT

The MQTT approach to message passing fits the IoT use-case really well. There are three roles in MQTT:

**Broker** Receives messages categorized by topic from publishers, passes them on to registered subscribers.

**Subscriber** Registers with the Broker to receive messages sent with a specific topic.

**Publisher** Sends messages with a specific topic to the broker.

The button will take on the role as publisher, we will also need to use a third-party broker and implement a simple subscriber.

### Broker installation

A broker must be online at all times, there are public ones available and one was mentioned during the workshop, but I didn't catch which. Preferring self-hosted solutions anyway I installed Mosquitto, in Ubuntu it's really simple:

```
$ sudo apt-get install mosquitto
```

Mosquitto is automatically started after installation and by defaults listens on port 1883.

To make sure Mosquitto is working correctly we can do:

```
$ sudo apt-get install mosquitto-clients
```

which provides convenient ways to both subscribe and publish messages. Start a subscriber that subscribes to the topic sensors/button:

```
$ mosquitto_sub -v -t 'sensors/button'
```
Send a message to the broker which will be passed along to the subscriber:

```
$ mosquitto_pub -h localhost -t 'sensors/button' -m "down"
```

Which results in the following output from the mosquitto_sub program:

```
sensors/button down
```

Excellent!

### Button publisher

The button publisher is based on the examples in the foobarflies.io [blog post](http://www.foobarflies.io/a-simple-connected-object-with-nodemcu-and-MQTT/) and are available under \\lua in this repository. The button publisher is split into four files:

**application.lua** Does the button polling and MQTT message passing

**config.lua** Configuration parameters such as WiFi SSID and password

**test.lua** The main entry point that starts the program

**wifimanager.lua** Logs on to the WiFi network specified in config.lua.

The ESPlorer tool has a Upload button, use it to browse for, upload and write the Lua files to flash.

Start the program to poll for button presses and send button events to the MQTT broker:

```
> dofile('test.lua')
```

### Basic nodejs subscriber

With [NodeJS](https://nodejs.org/) installed, we can create our own simple MQTT subscriber to be able to act on button events. Here's an example of one that plays a youtube video when the button is pressed:

```javascript
const mqtt = require('mqtt')  
const client = mqtt.connect({host: process.argv[2], port: 1883})
const open = require('open')

client.on('connect', () => {  
  client.subscribe('sensors/button')
})

client.on('message', (topic, message) => {  
    if (message.toString() == "down") {
      open("https://www.youtube.com/watch?v=oHg5SJYRHA0")
    }
})
```

It takes a single parameter, the address of the MQTT broker:

```
$ node button-subscriber <MQTT broker address>
```

## Gotchas

### Permission problems for /dev/ttyUSBx

Originally my user didn't have permission to use /dev/ttyUSBx, this was solved by adding myself
to the dialout group, see this askubuntu [question](http://askubuntu.com/questions/133235/how-do-i-allow-non-root-access-to-ttyusb0-on-12-04).

### node.restart()

I didn't understand exactly when or why it happened but sometimes an older version of an uploaded file was used when executing dofile, in those cases it helped to restart the chip:

```
> node.restart()
```

### node.compile()

To reduce memory usage it is recommended to compile all Lua files used (except init.lua which needs to be in text format). This is done on the chip after uploading the Lua files to flash:

```
> node.compile('mymodule.lua')
```

The output is a compiled version, mymodule.lc which I'm assuming will be used over the .lua file when doing things like:

```
mymodule = require('mymodule')
```

### init.lua

When the Lua program is working as intended it can be renamed init.lua which will make the chip execute it automatically at startup. This is of course what we want in the end but during testing it's better to trigger the Lua program manually via dofile. If init.lua gets stuck somehow you may need to reflash the firmware to get a chance to fix it.

### keepalive

Both the subscriber and the publisher should send pingreq message to the broker within the configured keepalive period, otherwise the broker will consider them disconnected. In the mqtt.Client call in application.lua the second parameter specifies a maximum keepalive time that we can expect the broker to wait for a pingreq until it considers us disconnected.

The node [mqtt](https://www.npmjs.com/package/mqtt) library handles ping communication automatically, it seems like this is the case for the NodeMCU too although it's not [documented](https://nodemcu.readthedocs.io/en/dev/en/modules/mqtt/).
