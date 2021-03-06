Admin.AdminGroupsFormController = Ember.ObjectController.extend({
  apiScopeOptions: function() {
    return Admin.ApiScope.find();
  }.property(),

  permissionOptions: function() {
    return Admin.AdminPermission.find();
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
          text: 'Successfully saved the admin group \'' + this.get('model').get('username') + '\'',
        });

        this.transitionToRoute('admin_groups');
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

Admin.AdminGroupsEditController = Admin.AdminGroupsFormController.extend();
Admin.AdminGroupsNewController = Admin.AdminGroupsFormController.extend();
