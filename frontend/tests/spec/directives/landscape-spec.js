(function() {
  'use strict'

  describe('Landscape Directive', function() {

    var isLandscape

    beforeEach(function() {

      module('ChaiBioTech', function($provide) {
        mockCommonServices($provide)
      })

      inject(function($injector) {
        this.$window = $injector.get('$window')
        this.$rootScope = $injector.get('$rootScope')
        this.$compile = $injector.get('$compile')
        this.scope = this.$rootScope.$new()
        this.WindowWrapper = $injector.get('WindowWrapper')
      })

      isLandscape = false

      spyOn(this.WindowWrapper, 'isLandscape').and.callFake(function() {
        return isLandscape
      })

      this.directive = this.$compile(angular.element('<div landscape></div>'))(this.scope)
      this.scope.$digest()

    })

    it('rotates viewport when portrait', function() {
      spyOn(this.$rootScope, '$broadcast')
      this.directive = this.$compile(angular.element('<div landscape></div>'))(this.scope)
      this.scope.$digest()
      expect(this.directive.hasClass('landscape')).toBe(true)
      expect(this.$rootScope.$broadcast).toHaveBeenCalledWith('window:resize')
      expect(this.$rootScope.$broadcast).toHaveBeenCalledTimes(1)
      expect(this.directive.width()).toBe(this.WindowWrapper.width())
    })

    it('should not rotate the view when landscape', function() {
      isLandscape = true
      this.directive = this.$compile(angular.element('<div landscape></div>'))(this.scope)
      expect(this.directive.hasClass('landscape')).toBe(false)
    })

    it('should update when orientation changes to landscape', function() {
      expect(this.directive.hasClass('landscape')).toBe(true)
      isLandscape = true
      this.scope.$broadcast('window:resize')
      expect(this.directive.hasClass('landscape')).toBe(false)
    })

    it('should update when orientation changes to portrait', function() {
      isLandscape = true
      this.directive = this.$compile(angular.element('<div landscape></div>'))(this.scope)
      this.scope.$digest()
      expect(this.directive.hasClass('landscape')).toBe(false)
      isLandscape = false
      this.scope.$broadcast('window:resize')
      expect(this.directive.hasClass('landscape')).toBe(true)
    })

    afterEach(function () {
      $(window).off('resize')
    })

  })


})();
