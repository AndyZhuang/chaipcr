
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

  getMaxY: ->
    return @config.axes.y.max if @config.axes.y.max
    max_y = d3.max @config.series, (s) =>
              d3.max @data[s.dataset], (d) =>
                d[s.y]

    max_y || 1

window.ChaiBioCharts = window.ChaiBioCharts || {}
window.ChaiBioCharts.AmplificationChart = AmplificationChart