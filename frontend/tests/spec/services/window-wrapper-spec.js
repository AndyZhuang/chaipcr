(function() {
  'use strict'

  describe('Testing WindowWrapper Service', function() {

    describe('On Mobile', function() {

      var windowMock = {
        navigator: {
          userAgent: 'Mozilla/5.0 (iPad; CPU OS 8_0_2 like Mac OS X)\
                      AppleWebKit/60.1.4 (KHTML, like Gecko) Version/8.0\
                      Mobile/12A405 Safari/600.1.4'
        },
        innerWidth: 200
      }

      beforeEach(function() {
        module('ChaiBioTech', function($provide) {
          mockCommonServices($provide)
          $provide.value('$window', windowMock)
        })

        inject(function($injector) {
          this.WindowWrapper = $injector.get('WindowWrapper')
        })
      })

      it('should return width of mobile browser window', function() {
        expect(this.WindowWrapper.width()).toEqual(windowMock.innerWidth)
      })

      describe('View Orientation Detection', function() {

        beforeEach(function() {
          windowMock.screen = windowMock.screen || {}
        })

        it('should return orientation', function() {
          windowMock.screen.orientation = {
            type: 'landscape-primary'
          }
          expect(this.WindowWrapper.orientation()).toBe('landscape-primary')
        })

        it('should detect window orientation', function() {
          windowMock.screen.orientation = {
            type: 'landscape-primary'
          }
          expect(this.WindowWrapper.isLandscape()).toBe(true)
          windowMock.screen.orientation = {
            type: 'landscape-secondary'
          }
          expect(this.WindowWrapper.isLandscape()).toBe(true)
          windowMock.screen.orientation = {
            type: 'portrait-primary'
          }
          expect(this.WindowWrapper.isLandscape()).toBe(false)
          windowMock.screen.orientation = {
            type: 'portrait-secondary'
          }
          expect(this.WindowWrapper.isLandscape()).toBe(false)
        })

      })

    })

    describe('On Desktop', function() {

      beforeEach(function() {
        module('ChaiBioTech', function($provide) {
          mockCommonServices($provide)
        })

        inject(function($injector) {
          this.$rootScope = $injector.get('$rootScope')
          this.$window = $injector.get('$window')
          this.WindowWrapper = $injector.get('WindowWrapper')
        })
      })

      it('should return width of desktop browser window', function() {
        expect(this.WindowWrapper.width()).toEqual($(this.$window).width())
      })

      it('should return window height', function() {
        expect(this.WindowWrapper.height()).toBe(angular.element(this.$window).height())
      })

      it('should return document height', function() {
        angular.element('body').css({ margin: 0, padding: 0 }).append('<div style="height: 1234px"></div>')
        expect(this.WindowWrapper.documentHeight()).toBe(1234)
      })

      it('should broadcast window:resize event', function() {
        spyOn(this.$rootScope, '$apply').and.callFake(function(fn) {
          fn()
        })
        spyOn(this.$rootScope, '$broadcast').and.callFake(function() {})
        angular.element(this.$window).triggerHandler('resize')
        expect(this.$rootScope.$broadcast).toHaveBeenCalledWith('window:resize')
        expect(this.$rootScope.$broadcast).toHaveBeenCalledTimes(1)
      })

    })

    afterEach(function() {
      $(window).off('resize')
    })

  })

})();
