module.exports = {
  title: "pimatic-nefit device config options"
  NefitThermostat: {
    title: "NefitThermostat config options"
    type: "object"
    properties:
      SerialNumber:
        type: "string"
        required: true
      AccessKey:
        type: "string"
        required: true
      Password:
        type: "string"
        required: true
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