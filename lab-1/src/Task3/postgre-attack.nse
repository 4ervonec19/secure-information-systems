local pgsql = require "pgsql"
local stdnse = require "stdnse"
local nmap = require "nmap"
local shortport = require "shortport"

local function connect(host, port)
  local socket = nmap.new_socket()
  socket:set_timeout(5000)
  local status, err = socket:connect(host, port)
  if not status then return nil end
  return socket
end

portrule = shortport.port_or_service(5432, "postgresql")

action = function(host, port)
    local pg = pgsql.detectVersion(host, port)
    local credentials = { {"postgres", "postgres"}, {"admin", "12345"} }
    local valid_accounts = {}

    for _, cred in ipairs(credentials) do
        local user, pass = cred[1], cred[2]
        local socket = connect(host, port)
        
        if socket then
            local status, response = pg.sendStartup(socket, user, "postgres")
            
            if status then
                status, response = pg.loginRequest(socket, response, user, pass, response.salt)
                
                if status then
                    table.insert(valid_accounts, string.format("ACCESS GRANTED AND DATABASE MODIFIED: %s/%s", user, pass))
                end
            end
            socket:close()
        end
    end

    return stdnse.format_output(true, valid_accounts)
end