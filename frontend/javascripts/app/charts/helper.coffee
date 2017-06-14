
superscript = "⁰¹²³⁴⁵⁶⁷⁸⁹"

window.ChartHelper =

  formatPower: (d) ->
    d.toExponential()
    # (d.toString()).split('').map((c) -> superscript[c]).join('')

window.ChaiBioCharts = window.ChaiBioCharts || {}
window.ChaiBioCharts.ChartHelper = ChartHelper