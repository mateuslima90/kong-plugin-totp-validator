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

-- do initialization here, any module level code runs in the 'init_by_lua_block',
-- before worker processes are forked. So anything you add here will run once,
-- but be available in all workers.



-- handles more initialization, but AFTER the worker process has been forked/created.
-- It runs in the 'init_worker_by_lua_block'
function plugin:init_worker()

  -- your custom code here
  kong.log.debug("saying hi from the 'init_worker' handler")

end --]]



--[[ runs in the 'ssl_certificate_by_lua_block'
-- IMPORTANT: during the `certificate` phase neither `route`, `service`, nor `consumer`
-- will have been identified, hence this handler will only be executed if the plugin is
-- configured as a global plugin!
function plugin:certificate(plugin_conf)

  -- your custom code here
  kong.log.debug("saying hi from the 'certificate' handler")

end --]]



--[[ runs in the 'rewrite_by_lua_block'
-- IMPORTANT: during the `rewrite` phase neither `route`, `service`, nor `consumer`
-- will have been identified, hence this handler will only be executed if the plugin is
-- configured as a global plugin!
function plugin:rewrite(plugin_conf)

  -- your custom code here
  kong.log.debug("saying hi from the 'rewrite' handler")

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

  local result = json.decode(response.body)
  kong.log.inspect(result)
  if result.isValid == true then
    return true
  end
  return false

end

-- runs in the 'access_by_lua_block'
function plugin:access(plugin_conf)

  -- your custom code here
  kong.log("phase access custom")
  kong.log.inspect(plugin_conf)   -- check the logs for a pretty-printed config!

  if kong.request.get_method() == "POST" then

    local username = kong.request.get_header("Username")

    local body, err = kong.request.get_body()

    if body == nil then
      kong.log.err("Body is nil")
      return response_error_exit(403, "You shall not pass")
    end

    if err == nil then
      if body.mfa.code == nil then
        kong.log.err("Code is nil")
        return response_error_exit(403, "You shall not pass")
      end

      local backend_url = plugin_conf.backend_url
      local backend_path = plugin_conf.backend_path
      local vault_token = plugin_conf.vault_token
      local responseTOTP = validateCode(backend_url, backend_path, vault_token, username, body.mfa.code)

      kong.log.inspect("ResponseTOTP: ", responseTOTP)

      if responseTOTP == false or responseTOTP == nil then
        kong.log.err("you shall not pass")
        return response_error_exit(403, "You shall not pass")
      end
    end
  end

end --]]

-- runs in the 'header_filter_by_lua_block'
function plugin:header_filter(plugin_conf)

  -- kong.log.inspect(plugin_conf)
  -- your custom code here, for example;

  -- kong.log.inspect(kong.request.get_headers())

  --kong.response.set_header("mkth", "on this side")
  --kong.response.set_header(plugin_conf.response_header, "this is on the response")

  -- kong.log.inspect(kong.response)

end --]]


--[[ runs in the 'body_filter_by_lua_block'
function plugin:body_filter(plugin_conf)

  -- your custom code here
  kong.log.debug("saying hi from the 'body_filter' handler")

end --]]


--[[ runs in the 'log_by_lua_block'
function plugin:log(plugin_conf)

  -- your custom code here
  kong.log.debug("saying hi from the 'log' handler")

end --]]


-- return our plugin object
return plugin
