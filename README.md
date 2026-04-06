# Siphon - Home Assistant Add-on

![Siphon Logo](https://raw.githubusercontent.com/mekops-labs/siphon-ha-addon/main/siphon/logo.png)

**Siphon** is a high-performance, modular IoT data aggregator, parser, and dispatcher (ETL engine) written in Go. 

This repository provides the official Home Assistant Add-on for Siphon. Running Siphon natively within Home Assistant unlocks powerful capabilities, including a built-in web configuration editor, automatic MQTT credential injection, and zero-configuration access to the Home Assistant internal REST API.

## ✨ Features
* **Zero-Setup MQTT:** Automatically discovers and connects to your Home Assistant Mosquitto broker.
* **Native API Access:** Polls Home Assistant entities directly without needing Long-Lived Access Tokens.
* **Embedded Web UI:** Edit your pipelines directly from the Home Assistant sidebar with syntax highlighting.
* **Hot-Reloading:** Save your configuration in the web UI and Siphon instantly reboots the engine—no container restarts required.

---

## 🚀 Installation

To install Siphon, add this custom repository to your Home Assistant instance:

1. Navigate to your Home Assistant dashboard.
2. Go to **Settings** > **Add-ons** > **Add-on Store**.
3. Click the three dots (`...`) in the top right corner and select **Repositories**.
4. Paste the URL of this repository: `https://github.com/mekops-labs/siphon-ha-addon`
5. Click **Add** and close the dialog.
6. Refresh the page (or wait a moment). Scroll down to the bottom or search for **Siphon ETL**.
7. Click the Add-on, click **Install**, and once finished, toggle on **Show in sidebar**.
8. Start the Add-on!

---

## ⚙️ Configuration

Siphon routes your data using a powerful `config.yaml` file. 

Clicking the **Siphon Config** button in your Home Assistant sidebar will open the embedded Web Editor. From here, you can define your Collectors, Pipelines, and Sinks.

### Managing Secrets & API Keys
Never hardcode passwords or API keys in your `config.yaml`. Instead, define them in the Home Assistant Add-on UI:
1. Go to the Add-on's **Configuration** tab.
2. Under `Env Vars`, define your secrets (e.g., `IOT_PLOTTER_API_KEY: abc123xyz`).
3. In your web editor `config.yaml`, reference them using `%%VAR_NAME%%` (e.g., `apikey: "%%IOT_PLOTTER_API_KEY%%"`).

*(Note: Siphon automatically exposes `%%MQTT_HOST%%`, `%%MQTT_PORT%%`, `%%MQTT_USER%%`, and `%%MQTT_PASS%%` for you if the Mosquitto broker is installed!)*

---

## 📡 The Native Home Assistant Collector

Because Siphon runs as an Add-on, it automatically receives a secure `SUPERVISOR_TOKEN`. This allows you to use the special `hass` collector to pull states directly from Home Assistant entities without dealing with authentication headers or IP addresses.

### How to use the `hass` collector:

In your `config.yaml`, set up the collector and map your logical **aliases** to your Home Assistant **entity_ids**.

```yaml
version: 2

collectors:
  # 1. Define the Home Assistant Collector
  local_ha:
    type: hass
    params:
      interval: 60  # Poll the Home Assistant API every 60 seconds
    topics:
      # Map an Alias -> HA Entity ID
      outdoor_temp: "sensor.backyard_temperature"
      living_room: "climate.living_room"

pipelines:
  # 2. Process the data from Home Assistant
  - name: process_ha_temps
    topics: ["outdoor_temp"] # Listen to the alias!
    bus_mode: volatile
    parser:
      type: jsonpath
      vars:
        # The HA API always returns a standard JSON object. 
        # You can extract the main state or nested attributes.
        temp: "$.state" 
        unit: "$.attributes.unit_of_measurement"
    
    # 3. Transform and Dispatch...
    transform:
      temp_float: "float(temp)"
```
How it works:

1. Every interval seconds, the collector asks Home Assistant for the state of sensor.backyard_temperature.
2. Home Assistant responds with a JSON payload (e.g., {"state": "24.5", "attributes": {...}}).
3. Siphon pushes this raw JSON to the internal Event Bus under the alias outdoor_temp.
4. Your pipeline grabs the JSON, parses out $.state, and pushes it to your downstream sinks (like Windy, Gotify, or IoTPlotter).

## 📚 Documentation

For complete documentation on writing expressions, setting up Cron aggregations, and configuring other Sinks (like ntfy, gotify, iotplotter, etc.), please visit the core [Siphon GitHub Repository](https://github.com/mekops-labs/siphon).
