local module = {}

local function wifi_wait_ip()
  if not wifi.sta.getip() then
    print("IP unavailable, Waiting...")
  else
    tmr.stop(1)
    print("\n====================================")
    print("ESP8266 mode is: " .. wifi.getmode())
    print("MAC address is: " .. wifi.ap.getmac())
    print("IP is " .. wifi.sta.getip())
    print("====================================")
    app.start()
  end
end

local function wifi_start(list_aps)
  local found_ap = false
  if list_aps then
    for key,value in pairs(list_aps) do
      if config.SSID and config.SSID == key then
        wifi.setmode(wifi.STATION);
        wifi.sta.config(config.SSID, config.PASSWORD)
        wifi.sta.connect()
        print("Connecting to " .. key .. " ...")
        --config.SSID = nil  -- can save memory
         tmr.alarm(1, 2500, 1, wifi_wait_ip)
        found_ap = true
      end
  end
  else
    print("Error getting AP list")
  end
  if not found_ap then
    print("Configured WiFi " .. config.SSID .. " not found.")
  end
end

function module.start()
  if not wifi.sta.getip() then
    print("Configuring WiFi ...")
    wifi.setmode(wifi.STATION);
    wifi.sta.getap(wifi_start)
  else
    app.start()
  end
end

return module
