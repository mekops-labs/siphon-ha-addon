#!/usr/bin/with-contenv bashio

bashio::log.info "Starting Siphon Add-on..."

# 1. Read environment variables from HA UI and export them
if bashio::config.has_value 'env_vars'; then
    bashio::log.info "Exporting environment variables from Add-on configuration..."
    
    # Iterate over the keys in the env_vars dictionary
    for key in $(bashio::jq "/data/options.json" ".env_vars | keys[]" -r); do
        value=$(bashio::jq "/data/options.json" ".env_vars[\"${key}\"]" -r)
        
        # Export the variable so Siphon's Go process can substitute it
        export "${key}"="${value}"
        bashio::log.debug "Exported ENV: ${key}=***"
    done
fi

CONFIG_DIR="/config/siphon"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"

# 2. Ensure the configuration directory exists
if [ ! -d "${CONFIG_DIR}" ]; then
    bashio::log.info "Creating configuration directory at ${CONFIG_DIR}..."
    mkdir -p "${CONFIG_DIR}"
fi

# 3. Create a barebones default config if the user hasn't made one yet
if [ ! -f "${CONFIG_FILE}" ]; then
    bashio::log.warning "Config file not found at ${CONFIG_FILE}. Creating a default template."
    cat <<EOF > "${CONFIG_FILE}"
version: 2
collectors: {}
sinks: {}
pipelines: []
EOF
fi

# 4. Start Siphon
bashio::log.info "Launching Siphon..."
exec /usr/bin/siphon "${CONFIG_FILE}"
