/*
 * Chai PCR - Software platform for Open qPCR and Chai's Real-Time PCR instruments.
 * For more information visit http://www.chaibio.com
 *
 * Copyright 2016 Chai Biotechnologies Inc. <info@chaibio.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

window.ChaiBioTech.ngApp.service('HomePageDelete', [
  '$window',
  function($window) {
    this.activeDelete = false;
    this.activeDeleteElem = false;
    var _this = this;

    angular.element($window).click(function(evt) {
      if(_this.activeDelete && evt.target.className !== 'home-page-bin' && !_this.activeDelete.deleting) {
        _this.disableActiveDelete();
        angular.element(_this.activeDeleteElem).parent()
          .removeClass('home-page-active-del-identifier');
      }
    });

    this.deactiveate = function(currentScope) {

      if(this.activeDelete) {
        if(currentScope.$id !== this.activeDelete.$id) {
          this.activeDelete.deleteClicked = false;
        } else if(currentScope.$id === this.activeDelete.$id) {
          this.activeDelete = false;
          this.activeDeleteElem = false;
        }
      }

    };

    this.disableActiveDelete = function() {
      this.activeDelete.deleteClicked = false;
    };
  }
]);
