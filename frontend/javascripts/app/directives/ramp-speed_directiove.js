window.ChaiBioTech.ngApp.directive('rampSpeed', [
  'ExperimentLoader',
  '$timeout',
  'alerts',

  function(ExperimentLoader, $timeout, alerts) {
    return {
      restric: 'EA',
      replace: true,
      scope: {
        caption: "@",
        unit: "@",
        reading: '='
      },
      templateUrl: 'app/views/directives/ramp-speed.html',

      link: function(scope, elem, attr) {

        scope.edit = false;
        scope.delta = true; // This is to prevent the directive become disabled, check delta in template, this is used for auto delta field
        scope.cbar = "C/";
        scope.s = "s";
        var editValue;

        scope.$watch("reading", function(val) {

          if(angular.isDefined(scope.reading)) {

            if(Number(scope.reading) <= 0) {
              scope.shown = "AUTO";
              scope.cbar = scope.s = "";
            } else {
              scope.shown = scope.reading;
              scope.cbar = "C/";
              scope.s = "s";
            }

            scope.hidden = scope.reading;
          }
        });


        scope.editAndFocus = function(className) {
          console.log(className);

          scope.edit = ! scope.edit;
          editValue = Number(scope.hidden);

          $timeout(function() {
            $('.' + className).focus();
          });
        };

        scope.save = function() {

          console.log(editValue, Number(scope.hidden));
          scope.edit = false;
          if(! isNaN(scope.hidden) && Number(scope.hidden) < 1000) {
            if(editValue !== Number(scope.hidden)) {
              if(Number(scope.hidden) % 1 === 0) { // if the number enrered is an integer.
                scope.reading = (Number(scope.hidden).toFixed(1));
                scope.hidden = scope.reading;
              } else {
                scope.reading = Number(scope.hidden);
              }

              $timeout(function() {
                ExperimentLoader.changeRampSpeed(scope.$parent).then(function(data) {
                  console.log(data);
                });
              });

            }
            return ;
          }
          scope.hidden = scope.reading;
          var warningMessage = alerts.rampSpeedWarning;
          scope.$parent.showMessage(warningMessage);
        };
      }
    };
  }
]);
