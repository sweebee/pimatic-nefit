# pimatic-nefi
Control the Nefit (Bosch) thermostat

## Setup

Install this plugin from the plugins page within pimatic

Add a new device and pick the "NefitThermostat"
Fill in the Serialnumber, AccessKey and Password. You can find these on your manual

## Rules

You can change the mode:
```
set mode of thermostat to "clock"
```
```
set mode of thermostat to "manual"
```

Or you can set the temperature
```
set temperature of thermostat to 20
```
