
class AmplificationChart

  constructor: (elem, data, config) ->
    @elem = elem
    @data = data
    @config = config

    @initChart()

  initChart: ->
    d3.select(@elem).selectAll("*").remove()
    @width = @elem.parentElement.offsetWidth - @config.margin.left - @config.margin.right
    @height = @elem.parentElement.offsetHeight - @config.margin.top - @config.margin.bottom
    @chartSVG = d3.select(@elem).append("svg")
                  .attr('id', 'chart-svg')
                  .attr("width", @width + @config.margin.left + @config.margin.right)
                  .attr("height", @height + @config.margin.top + @config.margin.bottom)

    g = @chartSVG.append("g")
            .attr('id', 'chart-g')
            .attr("transform", "translate(" + @config.margin.left + "," + @config.margin.top + ")")
            .attr('class', 'chart-g')

    @viewSVG = g.append('svg')
                  .attr('id', 'view-svg')
                  .attr('width', @width)
                  .attr('height', @height)
                  .append('g')
                  .attr('width', @width)
                  .attr('height', @height)
                  .attr('class', 'viewSVG')

    @mouseOverlay = @viewSVG.append('rect')
        .attr('id', 'chart-mouse-overlay')
        .attr('width', @width)
        .attr('height', @height)
        .attr('fill', 'transparent')
        # .on('mousemove', mouseMoveCb)
        # .on('mouseenter', showMouseIndicators)
        # .on('mouseout', hideMouseIndicators)

  setYAxis: ->
    @chartSVG.selectAll('g.axis.y-axis').remove()
    svg = @chartSVG.select('.chart-g')
    max = @getMaxY()
    min = @getMinY()
    diff = max - min

    allowance = diff * (if @config.axes.y.scale is 'log' then 0.2 else 0.05)
    max += allowance
    min = if @config.axes.y.scale is 'log' then 5 else min - allowance

    @yScale = if @config.axes.y.scale is 'log' then d3.scaleLog() else d3.scaleLinear()
    @yScale.range([@height, 0])
        .domain([min, max])

    @yAxis = d3.axisLeft(@yScale)
    @yAxis.tickFormat(@config.axes.y.tickFormat) if @config.axes.y.tickFormat

    if @config.axes.y.scale is 'log'
      @yAxis.tickValues(@getYLogTicks())
      @yAxis.tickFormat (d) -> '10' + formatPower(Math.round(Math.log(d) / Math.LN10))

  getMaxY: ->
    return @config.axes.y.max if @config.axes.y.max
    max_y = d3.max @config.series, (s) =>
              d3.max @data[s.dataset], (d) =>
                d[s.y]
    max_y || 1

  getMinY: ->
    return @config.axes.y.min if @config.axes.y.min
    min_y = d3.min @config.series, (s) =>
              d3.min @data[s.dataset], (d) =>
                d[s.y]

    min_y || 1

  getYLogTicks: ->
    num = @getMaxY()
    num = num + num * 0.2
    num_length = num.toString().length
    roundup = '1'
    for i in [0...num_length] by 1
      roundup = roundup + "0"

    roundup = roundup * 1
    calibs = []
    calib = 10

    while calib <= roundup
      calibs.push(calib)
      calib = calib * 10

    calibs

window.ChaiBioCharts = window.ChaiBioCharts || {}
window.ChaiBioCharts.AmplificationChart = AmplificationChart