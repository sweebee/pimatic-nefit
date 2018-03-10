module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  NefitEasyClient = require 'nefit-easy-commands'

  class nefit extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      #Register devices
      deviceConfigDef = require("./device-config-schema.coffee")

      deviceClasses = [
        NefitThermostat
      ]

      for Cl in deviceClasses
        do (Cl) =>
          @framework.deviceManager.registerDeviceClass(Cl.name, {
            configDef: deviceConfigDef[Cl.name]
            createCallback: (config,lastState) =>
              device  =  new Cl(config, lastState)
              return device
          })

  class NefitThermostat extends env.devices.HeatingThermostat

    constructor: (@config, lastState) ->
      @id = @config.id
      @name = @config.name
      @_temperatureSetpoint = lastState?.temperatureSetpoint?.value or 20
      @_synced = true
      @_valve = false
      @_mode = lastState?.mode?.value or "manu"
      @_temperature = lastState?.temperature?.value

      @addAttribute('temperature', {
        label: "House temperature"
        description: "House temperature",
        type: "number"
        displaySparkline: false
        unit: "C"
      })
      @['temperature'] = ()-> Promise.resolve(@_temperature)

      @client = NefitEasyClient({
        serialNumber : @config.SerialNumber,
        accessKey    : @config.AccessKey,
        password     : @config.Password,
      })

      @requestData()

      super()

    getTemperature: () -> Promise.resolve(@_temperature)

    changeTemperatureTo: (temperatureSetpoint) ->
      @_setSetpoint(temperatureSetpoint)
      @client.connect().then( () =>
        return @client.setTemperature(temperatureSetpoint)
      ).then( (result) =>
        return Promise.resolve()
        @requestData()
      ).catch( (e) =>
        return Promise.resolve()
        @requestData()
      )

    changeModeTo: (mode) ->
      if mode == "boost"
        env.logger.info('Boost is not supported')
        return

      @_setMode(mode)
      if mode == "manu"
        userMode = "manual"
      else
        userMode = "clock"
      @client.connect().then( () =>
        return @client.setUserMode(userMode)
      ).then( (status) =>
        @requestData()
        return Promise.resolve()
      ).catch( (e) =>
        @requestData()
        return Promise.resolve()
      )

    _setTemperature: (temperature) ->
      if temperature is @_temperature then return
      @_temperature = temperature
      @emit "temperature", @_temperature

    requestData: () =>
      env.logger.debug("polling thermostat")

      clearTimeout @requestTimeout if @requestTimeout?

      @client.connect().then( () =>
        return @client.status()
      ).then( (status) =>
        #env.logger.debug(status)

        # get the mode
        if status["user mode"] == "clock"
          mode = "clock"
        else
          mode = "manu"
        @_setMode(mode)

        # get temperature setpoint of thermostat
        @_setSetpoint(parseFloat(status["temp setpoint"]))

        # Get the heating status
        if status['boiler indicator'] == 'off'
          @_setValve(0)
        else
          @_setValve(100)

        # get house temperature
        @_setTemperature(parseFloat(status["in house temp"]))

      ).catch( (e) =>
        env.logger.error(e)
      )

      @requestTimeout = setTimeout(@requestData, 10000)

    destroy: ->
      @client.end()
      clearTimeout @requestTimeout if @requestTimeout?
      super()

  nefit = new nefit

  return nefit