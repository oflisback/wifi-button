local module = {}

module.SSID = "My WiFi SSID"
module.PASSWORD = "my password"

module.HOST = "127.0.0.1"
module.PORT = 1883
module.ID = node.chipid()

module.ENDPOINT = "sensors/button"

return module
