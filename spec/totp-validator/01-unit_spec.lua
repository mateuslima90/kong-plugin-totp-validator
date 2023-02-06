local PLUGIN_NAME = "totp-validator"

-- helper function to validate data against a schema
local validate do
  local validate_entity = require("spec.helpers").validate_plugin_config_schema
  local plugin_schema = require("kong.plugins."..PLUGIN_NAME..".schema")

  function validate(data)
    return validate_entity(data, plugin_schema)
  end
end

describe(PLUGIN_NAME .. ": (schema)", function()

  it("totp validator with required attributes", function()
    local ok, err = validate({
      backend_url = "localhost:9090",
      backend_path = "/generate",
      vault_token = "root",
      body_code_location = "mfa.code",
    })
    assert.is_nil(err)
    assert.is_truthy(ok)
  end)

  it("totp validator without all the required attributes", function()
      local ok, err = validate({
        backend_url = "localhost:9090",
        backend_path = "/generate",
      })
      assert.is_not_nil(err)
      assert.is_falsy(ok)
    end)

  --it("does not accept identical request_header and response_header", function()
  --  local ok, err = validate({
  --    request_header = "they-are-the-same",
  --    response_header = "they-are-the-same",
  --  })

  --  assert.is_same({
  --    ["config"] = {
  --      ["@entity"] = {
  --        [1] = "values of these fields must be distinct: 'request_header', 'response_header'"
  --      }
  --    }
  --  }, err)
  --  assert.is_falsy(ok)
  --end)


end)
