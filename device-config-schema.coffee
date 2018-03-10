module.exports = {
  title: "pimatic-nefit device config options"
  NefitThermostat: {
    title: "NefitThermostat config options"
    type: "object"
    properties:
      SerialNumber:
        type: "string"
        required: true
        description: "Can be found in the user manual"
      AccessKey:
        type: "string"
        required: true
        description: "Can be found in the user manual"
      Password:
        type: "string"
        required: true
        description: "By default '0000'"
      Polling:
        type: "number",
        default: 30000,
        description: "Default polling interval (ms)"
      guiShowModeControl:
        description: "Show the mode buttons in the GUI"
        type: "boolean"
        default: true
      guiShowValvePosition:
        description: "Show the valve position in the GUI"
        type: "boolean"
        default: true
      guiShowTemperatureInput:
        description: "Show the temperature input spinbox in the GUI"
        type: "boolean"
        default: true

  }
}