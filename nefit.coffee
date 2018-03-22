module.exports = (env) ->

  Promise = env.require 'bluebird'
  NefitEasyClient = require 'nefit-easy-commands'

  class nefit extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      # wait till all plugins are loaded
      @framework.on "after init", =>
        # Check if the mobile-frontend was loaded and get a instance
        mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
        if mobileFrontend?
          mobileFrontend.registerAssetFile 'js', "pimatic-nefit/app/nefit-page.coffee"
          mobileFrontend.registerAssetFile 'css', "pimatic-nefit/app/nefit-template.css"
          mobileFrontend.registerAssetFile 'html', "pimatic-nefit/app/nefit-template.jade"
        else
          env.logger.warn "your plugin could not find the mobile-frontend. No gui will be available"

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

    template: "nefit"

    constructor: (@config, lastState) ->
      @id = @config.id
      @name = @config.name
      @_temperatureSetpoint = lastState?.temperatureSetpoint?.value or 20
      @_valve = false
      @_mode = lastState?.mode?.value or "manual"
      @_temperature = lastState?.temperature?.value
      @_pressure = lastState?.pressure?.value

      @addAttribute('temperature', {
        label: "House temperature"
        description: "House temperature",
        type: "number"
        displaySparkline: false
        unit: "°C"
      })
      @['temperature'] = ()-> Promise.resolve(@_temperature)

      @addAttribute('pressure', {
        label: "Pressure"
        description: "Pressure of the water",
        type: "number"
        displaySparkline: false
        unit: "bar"
      })
      @['pressure'] = ()-> Promise.resolve(@_pressure)

      @client = NefitEasyClient({
        serialNumber : @config.SerialNumber,
        accessKey    : @config.AccessKey,
        password     : @config.Password,
      })

      @client.connect().then( () =>
        @requestData()
      ).catch( (e) =>
        env.logger.debug(e)
      )

      super()

    changeTemperatureTo: (temperatureSetpoint) ->
      clearTimeout @requestTimeout if @requestTimeout?
      @requestTimeout = setTimeout(@requestData, @config.Polling)
      @_setSetpoint(temperatureSetpoint)
      @client.setTemperature(temperatureSetpoint).then( (result) =>
        return Promise.resolve()
      ).catch( (e) =>
        env.logger.debug(e)
        return Promise.resolve()
      )

    changeModeTo: (mode) ->
      @_setMode(mode)
      clearTimeout @requestTimeout if @requestTimeout?
      @requestTimeout = setTimeout(@requestData, @config.Polling)
      @client.setUserMode(mode).then( (status) =>
        return Promise.resolve()
      ).catch( (e) =>
        env.logger.debug(e)
        return Promise.resolve()
      )

    requestData: () =>
      env.logger.debug("polling thermostat")

      clearTimeout @requestTimeout if @requestTimeout?

      @client.status().then( (status) =>
        env.logger.debug(status)

        # get the mode
        @_setMode(status["user mode"])

        # get temperature setpoint of thermostat
        @_setSetpoint(parseFloat(status["temp setpoint"]))

        # Get the heating status
        if status['boiler indicator'] == 'off'
          @_setValve(0)
        else
          @_setValve(100)

        # get house temperature
        temperature = parseFloat(status["in house temp"])
        unless temperature is @_temperature
          @_temperature = temperature
          @emit "temperature", @_temperature

      ).catch( (e) =>
        env.logger.debug(e)
      )

      @client.pressure().then( (result) =>
        # get the pressure
        pressure = parseFloat(result.pressure)
        unless pressure is @_pressure
          @_pressure = pressure
          @emit "pressure", @_pressure
      ).catch( (e) =>
        env.logger.debug(e)
      )

      @requestTimeout = setTimeout(@requestData, @config.Polling)

    destroy: ->
      @client.end()
      clearTimeout @requestTimeout if @requestTimeout?
      super()

    getTemperature: () -> Promise.resolve(@_temperature)
    getPressure: () -> Promise.resolve(@_pressure)

  nefit = new nefit

  return nefit
