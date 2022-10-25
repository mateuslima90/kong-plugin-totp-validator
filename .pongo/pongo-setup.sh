
luarocks install lunajson

export KONG_DATABASE=off
export KONG_DECLARATIVE_CONFIG=/kong-plugin/kong.yml

echo '_format_version: "2.1"
_transform: true
services:
- name: httpbin-service
  url: http://httpbin:80
  retries: 0
  connect_timeout: 5000
  write_timeout: 5000
  read_timeout: 5000
  routes:
  - name: my-route-anything
    regex_priority: 200
    strip_path: false
    methods: [POST, GET]
    protocols: [http]
    paths:
    - /anything
    plugins:
    - name: kong-plugin-totp-validator
      config:
        backend_url: http://vault:8200
        backend_path: /v1/totp/code
        vault_token: root
        body_code_location: mfa.code
  - name: my-route-image
    regex_priority: 201
    strip_path: false
    methods: [GET]
    protocols: [http]
    paths:
    - /image
    plugins:
    - name: kong-plugin-totp-validator
      config:
        backend_url: http://vault:8200
        backend_path: /v1/totp/code
        vault_token: root
        header_code_location: x-mfa-code' > kong.yml


