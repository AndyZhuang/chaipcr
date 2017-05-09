(function() {
  'use strict';

  App.service('WindowWrapper', [
    '$window',
    '$rootScope',
    'IsMobile',
    function windowCommon($window, $rootScope, IsMobile) {

      var self = this;

      this.width = function() {
        if (self.isLandscape()) {
          if (IsMobile()) {
            return $window.innerWidth;
          } else {
            return angular.element($window).width();
          }
        } else {
          if (IsMobile()) {
            return $window.innerHeight;
          } else {
            return angular.element($window).height();
          }
        }
      };

      this.height = function() {
        if (self.isLandscape()) {
          if (IsMobile()) {
            return $window.innerHeight;
          } else {
            return angular.element($window).height();
          }
        } else {
          if (IsMobile()) {
            return $window.innerWidth;
          } else {
            return angular.element($window).width();
          }
        }
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

      this.isLandscape = function() {
        return self.orientation().indexOf('landscape') > -1;
      };

      angular.element($window).resize(function() {
        $rootScope.$apply(function() {
          $rootScope.$broadcast('window:resize');
        });
      });

    }
  ]);

}).call(window);
