local typedefs = require "kong.db.schema.typedefs"


local PLUGIN_NAME = "kong-plugin-totp-validator"


local schema = {
  name = PLUGIN_NAME,
  fields = {
    -- the 'fields' array is the top-level entry with fields defined by Kong
    { consumer = typedefs.no_consumer },  -- this plugin cannot be configured on a consumer (typical for auth plugins)
    { protocols = typedefs.protocols_http },
    { config = {
        -- The 'config' record is the custom part of the plugin schema
        type = "record",
        fields = {
          -- a standard defined field (typedef), with some customizations
          { backend_url = { type = "string", required = true }, },
          { backend_path = { type = "string", required = true }, },
          { vault_token = { type = "string", required = true }, },
          { body_code_location = { type = "string", required = false }, },
          { header_code_location = { type = "string", required = false }, }
        },
      },
    },
  },
}

return schema
