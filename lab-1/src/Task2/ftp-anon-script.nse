local shortport = require "shortport"
local nmap = require "nmap"
local stdnse = require "stdnse"

portrule = shortport.port_or_service({21}, {"ftp"})

action = function(host, port)
    print("DEBUG: script started")
    local socket = nmap.new_socket()
    local try = nmap.new_try()
    
    try(socket:connect(host, port))
    
    local status, line = socket:receive_lines(1)
    if not status then
        socket:close()
        return nil
    end
    
    try(socket:send("USER anonymous\r\n"))
    local status, line = socket:receive_lines(1)
    if not status then
        socket:close()
        return nil
    end
    
    if line:match("331") then
        try(socket:send("PASS anonymous@example.com\r\n"))
        local status, line = socket:receive_lines(1)
        if not status then
            socket:close()
            return nil
        end
        if line:match("230") then
            socket:close()
            return "Access granted!"
        end
    end
    
    socket:close()
    return "Access denied!"
end