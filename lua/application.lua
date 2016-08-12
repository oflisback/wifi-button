local module = {}
m = nil
lastButtonState = nil

local function connectMqtt(done)
  m:connect(config.HOST, config.PORT, 0, 1, function(con)
      done()
    end, function(con, reason)
      print("Connect failed, reason: " .. reason)
    end)
end


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
        connectMqtt(function ()
          m:publish(config.ENDPOINT, label, 0, 0)
          m:close()
        end)
      end
      lastButtonState = buttonState
    end
end

local function send_ping()
  connectMqtt(function ()
    m:publish(config.ENDPOINT, "ping", 0, 0)
    m:close()
  end)
end

function module.start()
  print("Starting app ...")
  gpio.mode(1, gpio.INPUT, gpio.PULLUP)

  m = mqtt.Client(config.ID, 120)

  tmr.stop(0)
  tmr.alarm(0, 100, 1, check_button)
  tmr.stop(1)
  tmr.alarm(1, 20 * 1000, tmr.ALARM_AUTO, send_ping)
end

return module
