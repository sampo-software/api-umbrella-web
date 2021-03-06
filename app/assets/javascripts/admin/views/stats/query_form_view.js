Admin.StatsQueryFormView = Ember.View.extend({
  templateName: 'stats/_query_form',

  enableInterval: false,

  datePickerRanges: {
    'Today': [
      moment().startOf('day'),
      moment().endOf('day'),
    ],
    'Yesterday': [
      moment().subtract(1, 'days'),
      moment().subtract(1, 'days').endOf('day'),
    ],
    'Last 7 Days': [
      moment().subtract(6, 'days'),
      moment().endOf('day'),
    ],
    'Last 30 Days': [
      moment().subtract(29, 'days').startOf('day'),
      moment().endOf('day'),
    ],
    'This Month': [
      moment().startOf('month'),
      moment().endOf('month'),
    ],
    'Last Month': [
      moment().subtract(1, 'month').startOf('month'),
      moment().subtract(1, 'month').endOf('month'),
    ]
  },

  didInsertElement: function() {
    this.updateInterval();
    this.updateDateRange();

    $('#reportrange').daterangepicker({
      ranges: this.datePickerRanges,
      startDate: moment(this.get('controller.query.params.start'), 'YYYY-MM-DD'),
      endDate: moment(this.get('controller.query.params.end'), 'YYYY-MM-DD'),
    }, _.bind(this.handleDateRangeChange, this));
  },

  updateInterval: function() {
    var interval = this.get('controller.query.params.interval');
    $('#interval_buttons').find('button[value="' + interval + '"]').button('toggle');
  }.observes('controller.query.params.interval'),

  updateDateRange: function() {
    var start = moment(this.get('controller.query.params.start'));
    var end = moment(this.get('controller.query.params.end'));

    $('#reportrange span.text').html(start.format('MMM D, YYYY') + ' - ' + end.format('MMM D, YYYY'));
  }.observes('controller.query.params.start', 'controller.query.params.end'),

  handleDateRangeChange: function(start, end) {
    this.setProperties({
      'controller.query.params.start': start.format('YYYY-MM-DD'),
      'controller.query.params.end': end.format('YYYY-MM-DD'),
    });
  },

  actions: {
    clickInterval: function(interval) {
      this.set('controller.query.params.interval', interval);
    },
  },
});
