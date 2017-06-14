fdescribe 'AmplificationChart Class', ->

  beforeEach ->
    @data = angular.copy(PARSED_AMPLIFICATION_DATA)
    @config = angular.copy(AMPLIFICATION_CONFIG)

  beforeEach ->
    $('body').append('<div id="amplification-chart-container" style="width: 200px; height: 100px;"></div>')
    $('#amplification-chart-container').append('<div id="amplification-chart"><p></p></div>')
    @elem = $('#amplification-chart')

    @chart = new window.ChaiBioCharts.AmplificationChart(@elem[0], @data, @config)

  describe 'Init', ->

    it 'should remove previous contents', ->
      expect(@elem.html()).not.toContain '<p></p>'

    it 'should have chart svg', ->
      svg = d3.select('#chart-svg')
      expect(svg.attr('width')).toBe('200')
      expect(svg.attr('height')).toBe('100')

    it 'should have svg group element', ->
      g = d3.select('#chart-g')
      expect(g.attr('transform')).toBe("translate(#{@config.margin.left},#{@config.margin.top})")

    it 'should have view svg element', ->
      viewSVG = d3.select('#view-svg')
      expect(viewSVG.attr('width')).toBe("#{200 - @config.margin.left - @config.margin.right}")
      expect(viewSVG.attr('height')).toBe("#{100 - @config.margin.top - @config.margin.bottom}")
      g = d3.select('#view-svg > g')
      expect(g.attr('width')).toBe("#{200 - @config.margin.left - @config.margin.right}")
      expect(g.attr('height')).toBe("#{100 - @config.margin.top - @config.margin.bottom}")

    it 'should have mouse overlay', ->
      overlay = d3.select('#chart-mouse-overlay')
      expect(overlay.attr('width')).toBe("#{200 - @config.margin.left - @config.margin.right}")
      expect(overlay.attr('height')).toBe("#{100 - @config.margin.top - @config.margin.bottom}")

  describe 'Set Y Axis', ->

    it 'should remove previous y axis', ->
      yaxis = d3.select('.chart-svg').append('g').attr('class', 'axis y-axis')
      @chart.setYAxis()
      expect(yaxis.empty()).toBe(true)

    it 'should have log scale', ->
      spyOn(d3, 'scaleLog').and.callThrough()
      @config.axes.y.scale = 'log'
      @chart.setYAxis()
      expect(d3.scaleLog).toHaveBeenCalled()

    it 'should have linear scale', ->
      spyOn(d3, 'scaleLinear').and.callThrough()
      @config.axes.y.scale = 'linear'
      @chart.setYAxis()
      expect(d3.scaleLinear).toHaveBeenCalled()

    it 'should have range and domain', ->
      rangeSpy = jasmine.createSpy('yScale.range')
      domainSpy = jasmine.createSpy('yScale.range.domain')
      spyOn(@chart, 'getMinY').and.returnValue(0)
      spyOn(@chart, 'getMaxY').and.returnValue(100)
      spyOn(d3, 'scaleLinear').and.callFake ->
        range: (r) ->
          rangeSpy(r)
          domain: domainSpy
      @config.axes.y.scale = 'linear'
      @chart.setYAxis()
      expect(rangeSpy).toHaveBeenCalledWith([@chart.height, 0])
      expect(domainSpy).toHaveBeenCalledWith([-5, 105])

    it 'should have y axis', ->
      spyOn(d3, 'axisLeft').and.callThrough()
      @chart.setYAxis()
      expect(d3.axisLeft).toHaveBeenCalledWith(@chart.yScale)


    it 'should have tick format', ->
      tickFormatSpy = jasmine.createSpy('tickFormat')
      spyOn(d3, 'axisLeft').and.callFake ->
        tickFormat: tickFormatSpy
      @config.axes.y.tickFormat = mockTickFormat = -> true
      @chart.setYAxis()
      expect(tickFormatSpy).toHaveBeenCalledWith(mockTickFormat)

    it 'should use log tick values and tick format', ->
      @config.axes.y.scale = 'log'
      tickFormatSpy = jasmine.createSpy('tickFormat')
      tickValuesSpy = jasmine.createSpy('tickValues')
      spyOn(d3, 'axisLeft').and.callFake ->
        tickFormat: tickFormatSpy
        tickValues: tickValuesSpy

      @chart.setYAxis()
      expect(tickFormatSpy).toHaveBeenCalledWith (d) -> '10' + formatPower(Math.round(Math.log(d) / Math.LN10))



  describe 'Get Max Y', ->

    it 'should return config.axes.y.max', ->
      @config.axes.y.max = 1234
      expect(@chart.getMaxY()).toBe 1234

    it 'should return max fluorecense from data', ->
      delete @config.axes.y.max
      expect(@chart.getMaxY()).toBe 50000

  describe 'Get Min X', ->

    it 'should return config.axes.y.min', ->
      @config.axes.y.min = 1234
      expect(@chart.getMinY()).toBe 1234

    it 'should return min fluorecense from data', ->
      delete @config.axes.y.min
      expect(@chart.getMinY()).toBe -13366

  describe 'Get Y Log Ticks', ->

    it 'should use custom y ticks', ->
      max_y = 4321
      spyOn(@chart, 'getMaxY').and.returnValue max_y
      expect(@chart.getYLogTicks()).toEqual([ 10, 100, 1000, 10000, 100000, 1000000 ])

  afterEach ->
    $('#amplification-chart-container').remove()
    expect($('#amplification-chart-container').length).toBe 0