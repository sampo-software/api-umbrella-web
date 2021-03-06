Admin.AdminsFormController = Ember.ObjectController.extend({
  groupOptions: function() {
    return Admin.AdminGroup.find();
  }.property(),

  currentAdmin: function() {
    return currentAdmin;
  }.property(),

  actions: {
    submit: function() {
      var button = $('#save_button');
      button.button('loading');

      // Force dirty to force save (ember-model's dirty tracking fails to
      // account for changes in nested, non-association objects:
      // http://git.io/sbS1mg This is mainly for ApiSettings's errorTemplates
      // and errorDataYamlStrings, but we've seen enough funkiness elsewhere,
      // it seems worth disabling for now).
      this.set('model.isDirty', true);

      this.get('model').save().then(_.bind(function() {
        button.button('reset');
        new PNotify({
          type: 'success',
          title: 'Saved',
          text: 'Successfully saved the admin \'' + this.get('model').get('username') + '\'',
        });

        this.transitionToRoute('admins');
      }, this), function(response) {
        var message = '<h3>Error</h3>';
        try {
          var errors = response.responseJSON.errors;
          for(var prop in errors) {
            message += prop + ': ' + errors[prop].join(', ') + '<br>';
          }
        } catch(e) {
          message = 'An unexpected error occurred: ' + response.responseText;
        }

        button.button('reset');
        bootbox.alert(message);
      });
    },
  },
});

Admin.AdminsEditController = Admin.AdminsFormController.extend();
Admin.AdminsNewController = Admin.AdminsFormController.extend();
