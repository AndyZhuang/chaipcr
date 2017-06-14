fdescribe 'Chart Helper', ->

  beforeEach ->
    @helper = window.ChaiBioCharts.ChartHelper

  it 'should format number with exponent', ->
    expect(@helper.formatPower(Math.round(Math.log(1000) / Math.LN10))).toBe("10²")