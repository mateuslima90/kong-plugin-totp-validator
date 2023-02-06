-- If you're not sure your plugin is executing, uncomment the line below and restart Kong
-- then it will throw an error which indicates the plugin is being loaded at least.

--assert(ngx.get_phase() == "timer", "The world is coming to an end!")

---------------------------------------------------------------------------------------------
-- In the code below, just remove the opening brackets; `[[` to enable a specific handler
--
-- The handlers are based on the OpenResty handlers, see the OpenResty docs for details
-- on when exactly they are invoked and what limitations each handler has.
---------------------------------------------------------------------------------------------



local plugin = {
  PRIORITY = 1000, -- set the plugin priority, which determines plugin execution order
  VERSION = "0.1.0", -- version in X.Y.Z format. Check hybrid-mode compatibility requirements.
}

local http = require("resty.http")
local json = require("lunajson")

function plugin:init_worker()

  -- your custom code here
  kong.log.debug("saying hi from the 'init_worker' handler")

end --]]

--- Exit with an unauthorized http response
local function response_error_exit(http_status, msg)
  kong.response.set_header("Content-Type", "application/json; charset=utf-8")
  return kong.response.exit(http_status, '{"message": "' .. msg .. '"}')
end

local function validateCode(backend_url, backend_path, vault_token, username, code)

  local httpConnection = http.new()
  local connect_timeout = 5000
  local send_timeout = 5000
  local read_timeout = 5000
  httpConnection:set_timeouts(connect_timeout, send_timeout, read_timeout)

  local totpRequest = { code = code }

  local path = backend_path .. "/" .. username
  local response, err = httpConnection:request_uri(backend_url, {
    method = "POST",
    path = path,
    body = json.encode(totpRequest),
    headers = {
      ["x-vault-token"] = vault_token,
      ["Content-Type"] = "application/json",
    }
  })

  if not response then
    kong.log.err("request error :", err)
    return
  end

  local _, errorHttpC = httpConnection:close()
  if errorHttpC ~= nil then
    kong.log.debug(errorHttpC)
  end

  kong.log.inspect(response)
  local result = json.decode(response.body)
  kong.log.inspect(result)

  if  response.status == 200 and result.data.valid == true then
    return true
  else
    return false
  end


end

local function checkCodeCameFrom(plugin_conf)

  if kong.request.get_method() == "GET" then

    local header_code_location = plugin_conf.header_code_location
    local mfa_code = ''

    if header_code_location ~= nil then
      kong.log.inspect(kong.request.get_header(header_code_location))
      mfa_code = kong.request.get_header(header_code_location)

      return tonumber(mfa_code)
    end
  elseif kong.request.get_method() == "POST" or
    kong.request.get_method() == "PUT" or
    kong.request.get_method() == "PATCH" or
    kong.request.get_method() == "DELETE" then

    local body, err = kong.request.get_body()

    -- TODO: check in the request contains content-type
    if body == nil then
      kong.log.err("Body is nil")
      return response_error_exit(403, "You shall not pass")
    end

    if err == nil then
      local body_code_location = plugin_conf.body_code_location
      local mfa_code = ''
      -- if the code is from body, validate it
      if body_code_location ~= nil then
        -- playing with loadstring to allow body.level1.level2.code configs
        local funcstr = "local inner_mfa_code = kong.request.get_body()." .. body_code_location .. "; return inner_mfa_code;"

        local result, vars = pcall(loadstring(funcstr))
        mfa_code = tonumber(vars)
        if result == false then
          -- `loadstring(funcstr)' raised an error: take appropriate actions
          return response_error_exit(403, "You shall not pass")
        end
        return mfa_code
      end
    end

  end
end

-- runs in the 'access_by_lua_block'
function plugin:access(plugin_conf)

  -- your custom code here
  kong.log("phase access custom")
  kong.log.inspect(plugin_conf)   -- check the logs for a pretty-printed config!

  local mfa_code = checkCodeCameFrom(plugin_conf)

  -- TODO: It needs to validate username value
  local username = kong.request.get_header("Username")

  -- if fails here, is because i was unable to obtain code from both header and body
  if mfa_code == nil or mfa_code == {} then
    kong.log.err("Code is nil")
    return response_error_exit(403, "You shall not pass")
  end

  local backend_url = plugin_conf.backend_url
  local backend_path = plugin_conf.backend_path
  local vault_token = plugin_conf.vault_token
  local responseTOTP = validateCode(backend_url, backend_path, vault_token, username, mfa_code)

  kong.log.inspect("ResponseTOTP: ", responseTOTP)

  if responseTOTP == false or responseTOTP == nil then
    kong.log.err("you shall not pass")
    return response_error_exit(403, "You shall not pass! This code is not valid!")
  end
end

function plugin:header_filter(plugin_conf)
   local header_code_location = plugin_conf.header_code_location
   if header_code_location ~= nil then
      local mfa_code_from_header = kong.request.get_header(header_code_location)
      if mfa_code_from_header == nil then
        kong.log.err("Code is nil")
        return response_error_exit(403, "You shall not pass")
      end
   end
end

-- return our plugin object
return plugin
