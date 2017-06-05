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

  describe 'Get Max Y', ->

    it 'should return config.axes.y.max', ->
      @config.axes.y.max = 1234
      expect(@chart.getMaxY()).toBe 1234

    it 'should return max fluorecense from data', ->
      delete @config.axes.y.max
      expect(@chart.getMaxY()).toBe 50000

  afterEach ->
    $('#amplification-chart-container').remove()
    expect($('#amplification-chart-container').length).toBe 0