Admin.StatsUsersController = Admin.StatsBaseController.extend({
  downloadUrl: function() {
    return '/admin/stats/users.csv?' + $.param(this.get('query.params'));
  }.property('query.params', 'query.params.search', 'query.params.start', 'query.params.end'),
});

Admin.StatsUsersDefaultController = Admin.StatsUsersController.extend({
  renderTemplate: function() {
    this.render('stats/users');
  }
});
