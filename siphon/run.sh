#!/usr/bin/with-contenv bashio

bashio::log.info "Starting Siphon Add-on..."

# 1. --- Auto-Discover Home Assistant MQTT Credentials ---
if bashio::services.available 'mqtt'; then
    bashio::log.info "Home Assistant MQTT service discovered! Injecting credentials..."

    export MQTT_HOST=$(bashio::services mqtt "host")
    export MQTT_PORT=$(bashio::services mqtt "port")
    export MQTT_USER=$(bashio::services mqtt "username")
    export MQTT_PASS=$(bashio::services mqtt "password")

    bashio::log.debug "Exported MQTT connection for ${MQTT_HOST}:${MQTT_PORT}"
else
    bashio::log.warning "No internal MQTT service found. Make sure the Mosquitto broker add-on is installed."
fi

# 2. --- Read remaining environment variables from HA UI ---
if bashio::config.has_value 'env_vars'; then
    bashio::log.info "Exporting custom environment variables from configuration..."

    # Safely iterate through the array of objects using jq
    while IFS='=' read -r key value; do
        if [ -n "${key}" ] && [ "${key}" != "null" ]; then
            export "${key}"="${value}"
            bashio::log.debug "Exported ENV: ${key}=***"
        fi
    done < <(bashio::jq "/data/options.json" ".env_vars[] | \"\(.name)=\(.value)\"" -r)
fi

CONFIG_DIR="/config"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"

# 3. Ensure the configuration directory exists
if [ ! -d "${CONFIG_DIR}" ]; then
    bashio::log.info "Creating configuration directory at ${CONFIG_DIR}..."
    mkdir -p "${CONFIG_DIR}"
fi

# 4. Create a barebones default config with HA MQTT defaults
if [ ! -f "${CONFIG_FILE}" ]; then
    bashio::log.warning "Config file not found. Creating a default template."
    cat <<EOF > "${CONFIG_FILE}"
version: 2

collectors:
  ha_mqtt:
    type: mqtt
    params:
      # Siphon will automatically replace these with the injected HA variables!
      url: "tcp://%%MQTT_HOST%%:%%MQTT_PORT%%"
      user: "%%MQTT_USER%%"
      pass: "%%MQTT_PASS%%"
    topics:
      example_sensor: "homeassistant/sensor/example/state"

sinks: {}
pipelines: []
EOF
fi

# 5. Start Siphon with the web editor
bashio::log.info "Launching Siphon Engine with Web Editor on port 8099..."
exec /usr/bin/siphon -editor-port 8099 "${CONFIG_FILE}"
