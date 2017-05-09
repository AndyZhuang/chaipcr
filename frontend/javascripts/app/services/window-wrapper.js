(function() {
  'use strict';

  App.service('WindowWrapper', [
    '$window',
    '$rootScope',
    'IsMobile',
    function windowCommon($window, $rootScope, IsMobile) {

      this.width = function() {
        if (IsMobile()) {
          return $window.innerWidth;
        } else {
          return $($window).width();
        }
      };

      this.height = function() {
        return angular.element($window).height();
      };

      this.documentHeight = function() {
        // http://stackoverflow.com/questions/1145850/how-to-get-height-of-entire-document-with-javascript
        var body = $window.document.body,
          html = $window.document.documentElement;

        var height = Math.max(body.scrollHeight, body.offsetHeight,
          html.clientHeight, html.scrollHeight, html.offsetHeight);

        return height;
      };

      this.orientation = function() {
        var orientation = $window.screen.orientation || $window.screen.mozOrientation || $window.screen.msOrientation;
        return orientation.type;
      };

      this.isLandscape = (function (_this) {
        return function() {
          return _this.orientation().indexOf('landscape') > -1;
        };
      })(this);

      angular.element($window).resize(function() {
        $rootScope.$apply(function() {
          $rootScope.$broadcast('window:resize');
        });
      });

    }
  ]);

}).call(window);
