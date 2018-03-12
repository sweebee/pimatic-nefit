$(document).on( "templateinit", (event) ->

  class NefitItem extends pimatic.DeviceItem

    constructor: (templData, @device) ->
      super(templData, @device)
      # The value in the input
      @inputValue = ko.observable()

      # temperatureSetpoint changes -> update input + also update buttons if needed
      @stAttr = @getAttribute('temperatureSetpoint')
      @inputValue(@stAttr.value())

      attrValue = @stAttr.value()
      @stAttr.value.subscribe( (value) =>
        @inputValue(value)
        attrValue = value
      )

      # input changes -> call changeTemperature
      ko.computed( =>
        textValue = @inputValue()
        if textValue? and attrValue? and parseFloat(attrValue) isnt parseFloat(textValue)
          @changeTemperatureTo(parseFloat(textValue))
      ).extend({ rateLimit: { timeout: 1000, method: "notifyWhenChangesStop" } })

    afterRender: (elements) ->
      super(elements)
      # find the buttons
      @clockButton = $(elements).find('[name=clockButton]')
      @manualButton = $(elements).find('[name=manualButton]')
      @boostButton = $(elements).find('[name=boostButton]')
      @ecoButton = $(elements).find('[name=ecoButton]')
      @comfyButton = $(elements).find('[name=comfyButton]')
      # @vacButton = $(elements).find('[name=vacButton]')
      @input = $(elements).find('.spinbox input')
      @valvePosition = $(elements).find('.valve-position-bar')
      @input.spinbox()

      @updateButtons()
      @updatePreTemperature()
      @updateValvePosition()

      @getAttribute('mode')?.value.subscribe( => @updateButtons() )
      @stAttr.value.subscribe( => @updatePreTemperature() )
      @getAttribute('valve')?.value.subscribe( => @updateValvePosition() )
      return

# define the available actions for the template
    modeClock: -> @changeModeTo "clock"
    modeManual: -> @changeModeTo "manual"
    modeEco: -> @changeTemperatureTo "#{@device.config.ecoTemp}"
    modeComfy: -> @changeTemperatureTo "#{@device.config.comfyTemp}"
    modeVac: -> @changeTemperatureTo "#{@device.config.vacTemp}"
    setTemp: -> @changeTemperatureTo "#{@inputValue.value()}"

    updateButtons: ->
      modeAttr = @getAttribute('mode')?.value()
      switch modeAttr
        when 'clock'
          @manualButton.removeClass('ui-btn-active')
          @clockButton.addClass('ui-btn-active')
        when 'manual'
          @manualButton.addClass('ui-btn-active')
          @clockButton.removeClass('ui-btn-active')
      return

    updatePreTemperature: ->
      if parseFloat(@stAttr.value()) is parseFloat("#{@device.config.ecoTemp}")
        @boostButton.removeClass('ui-btn-active')
        @ecoButton.addClass('ui-btn-active')
        @comfyButton.removeClass('ui-btn-active')
      else if parseFloat(@stAttr.value()) is parseFloat("#{@device.config.comfyTemp}")
        @boostButton.removeClass('ui-btn-active')
        @ecoButton.removeClass('ui-btn-active')
        @comfyButton.addClass('ui-btn-active')
      else
        @ecoButton.removeClass('ui-btn-active')
        @comfyButton.removeClass('ui-btn-active')
      return

    updateValvePosition: ->
      valveVal = @getAttribute('valve')?.value()
      if valveVal?
        @valvePosition.css('height', "#{valveVal}%")
        @valvePosition.parent().css('display', '')
      else
        @valvePosition.parent().css('display', 'none')

    changeModeTo: (mode) ->
      @device.rest.changeModeTo({mode}, global: no)
        .done(ajaxShowToast)
        .fail(ajaxAlertFail)

    changeTemperatureTo: (temperatureSetpoint) ->
      @input.spinbox('disable')
      @device.rest.changeTemperatureTo({temperatureSetpoint}, global: no)
        .done(ajaxShowToast)
        .fail(ajaxAlertFail)
        .always( => @input.spinbox('enable') )

  # register the item-class
  pimatic.templateClasses['nefit'] = NefitItem
)