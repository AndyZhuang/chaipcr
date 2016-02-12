App.controller 'MeltCurveCtrl', [
  '$scope'
  'Experiment'
  '$stateParams'
  'MeltCurveService'
  '$timeout'
  ($scope, Experiment, $stateParams, MeltCurveService, $timeout) ->

    $scope.curve_type = 'derivative'
    $scope.chartConfig = MeltCurveService.chartConfig()
    $scope.loading = null

    getMeltCurveData = (cb) ->
      $scope.loading = true
      $timeout ->
        Experiment.getMeltCurveData($stateParams.id)
        .then (resp) ->
          $scope.loading = false
          cb(resp.data) if !!cb
      , 1500

    getExperiment = (cb) ->
      Experiment.get(id: $stateParams.id).then (data) ->
        $scope.experiment = data.experiment
        cb(data.experiment) if !!cb

    getExperiment (exp) ->
      getMeltCurveData (data) ->
        temp_range = MeltCurveService.getTempRange(data.melt_curve_data)
        $scope.chartConfig.axes.x.min = temp_range.min
        $scope.chartConfig.axes.x.max = temp_range.max
        $scope.chartConfig.axes.x.ticks = MeltCurveService.XTicks(temp_range.min, temp_range.max)
        console.log $scope.chartConfig
        $scope.data = MeltCurveService.parseData data.melt_curve_data
        # console.log $scope.data

]