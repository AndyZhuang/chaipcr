App.directive('landscape', [
  'WindowWrapper'
  (WindowWrapper) ->

    restrict: 'AE'
    link: ($scope, elem) ->
      set = ->
        if not WindowWrapper.isLandscape()
          elem.addClass('landscape')
        else
          if (elem.hasClass('landscape')) then elem.removeClass('landscape')

      set()

      $scope.$on 'window:resize', set

])