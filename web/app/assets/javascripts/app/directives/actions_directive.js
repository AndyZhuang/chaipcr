window.ChaiBioTech.ngApp.directive('actions', [
  'ExperimentLoader',
  '$timeout',
  'canvas',
  function(ExperimentLoader, $timeout, canvas) {
    return {
      restric: 'EA',
      replace: true,
      templateUrl: 'app/views/directives/actions.html',

      link: function(scope, elem, attr) {
        scope.actionPopup = false;

        scope.addStep = function() {
          ExperimentLoader.addStep(scope)
            .then(function(data) {
              console.log(data);
              //scope.reloadAll();
              //Now create a new step and insert it...!
              scope.fabricStep.parentStage.addNewStep(data, scope.fabricStep);
            });
        };

        scope.deleteStep = function() {
          ExperimentLoader.deleteStep(scope)
            .then(function(data) {
              console.log("deleted", data);
              scope.fabricStep.parentStage.deleteStep(data, scope.fabricStep);
            });
        };

        scope.addStage = function(type) {
          ExperimentLoader.addStage(scope, type)
            .then(function(data) {
              scope.actionPopup = false;
              scope.fabricStep.parentStage.parent.addNewStage(data, scope.fabricStep.parentStage);
            });
        };

      }
    };
  }
]);