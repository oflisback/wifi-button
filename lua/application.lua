local module = {}
m = nil
lastButtonState = nil

local function check_button()
    buttonState = gpio.read(1)
    if buttonState ~= lastButtonState then
      -- Skip publishing the initial state
      if lastButtonState then
        if buttonState == 0 then
          label = "up"
        else
          label = "down"
        end
          print("Publishing update " .. label .. " to " .. config.ENDPOINT)
        m:publish(config.ENDPOINT, label, 0, 0)
      end
      lastButtonState = buttonState
    end
end

local function send_ping()
    m:publish(config.ENDPOINT, "ping", 0, 0)
end

local function mqtt_start()
    m = mqtt.Client(config.ID, 120)
    print("Connecting to MQTT broker ...")
    m:connect(config.HOST, config.PORT, 0, function(con)
      print("Connected to MQTT Broker!")
      tmr.stop(0)
      tmr.alarm(0, 100, 1, check_button)
      tmr.stop(1)
      tmr.alarm(1, 10 * 1000, tmr.ALARM_AUTO, send_ping)
    end, function(con, reason)
      print("Connect failed, reason: " .. reason)
    end)
end

function module.start()
  print("Starting app ...")
  gpio.mode(1, gpio.INPUT, gpio.PULLUP)

  mqtt_start()
end

return module
