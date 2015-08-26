window.ChaiBioTech.ngApp
.directive 'experimentStartStopButton', [
  'Status'
  'Experiment'
  (Status, Experiment) ->

    restrict: 'EA'
    replace: true
    scope:
      experimentId: '='
    templateUrl: 'app/views/directives/experiment-start-stop-button.html'
    link: ($scope, elem) ->

      getExperiment = (cb) ->
        Experiment.get {id: $scope.experimentId}, (resp) ->
          $scope.experiment = resp.experiment
          cb()

      $scope.$watch 'experimentId', (val) ->
        if angular.isNumber val
          getExperiment $scope.init

      $scope.init = ->
        Status.startSync()
        elem.on '$destroy', ->
          Status.stopSync()

        $scope.stopped = false

        $scope.$watch ->
          Status.getData()
        , (val) ->
          $scope.data = val

      $scope.startExperiment = (expId) ->
        $scope.stopped = false
        Experiment.startExperiment(expId)

      $scope.stopExperiment = ->
        $scope.stopped = true
        Experiment.stopExperiment().then ->
          getExperiment angular.noop

      $scope.completedAndStopped = ->
        ($scope.data?.experimentController?.machine.state is 'Complete') and $scope.stopped

]