ChaiBioTech.app.Views = ChaiBioTech.app.Views || {}

ChaiBioTech.app.Views.menuOverlayOptionsContent = Backbone.View.extend({

	className: "menu-overlay-options-content",

	template: JST["backbone/templates/app/menu-overlay-options-content"],

	initialize: function() {
		
	},

	render: function() {
		$(this.el).html(this.template());
		return this;
	}
});