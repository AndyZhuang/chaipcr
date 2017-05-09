App.directive('landscape', [
  '$rootScope'
  'WindowWrapper'
  ($rootScope, WindowWrapper) ->

    restrict: 'AE'
    link: ($scope, elem) ->
      set = ->
        if not WindowWrapper.isLandscape()
          elem.addClass('landscape')
          elem.css( width: WindowWrapper.width())
        else
          if (elem.hasClass('landscape')) then elem.removeClass('landscape')

      $scope.$on 'window:resize', set

      set()

      $rootScope.$broadcast('window:resize') if not WindowWrapper.isLandscape()

])