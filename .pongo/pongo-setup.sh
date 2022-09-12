
luarocks install lunajson

export KONG_DATABASE=off
export KONG_DECLARATIVE_CONFIG=/kong-plugin/kong.yml

echo '_format_version: "2.1"
_transform: true
services:
- name: httpbin-service
  url: http://httpbin.org
  retries: 0
  connect_timeout: 5000
  write_timeout: 5000
  read_timeout: 5000
  plugins:
  - name: kong-plugin-totp-validator
    config:
      backend_url: http://192.168.1.117:9090
      backend_path: /totp/validate
  routes:
  - name: my-route
    regex_priority: 200
    strip_path: false
    methods: [POST]
    protocols: [http]
    paths:
    - /anything
- name: vault-service
  url: http://192.168.1.117:9090
  retries: 0
  connect_timeout: 5000
  write_timeout: 5000
  read_timeout: 5000
  routes:
  - name: vault-generate-totp
    strip_path: false
    methods: [POST]
    protocols: [http]
    paths:
    - /totp/generate/(?<user>\S+)' > kong.yml


