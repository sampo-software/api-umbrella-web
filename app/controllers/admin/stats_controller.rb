require "csv_streamer"

class Admin::StatsController < Admin::BaseController
  set_tab :analytics

  around_filter :set_time_zone

  def index
  end

  def search
    @search = LogSearch.new({
      :start_time => params[:start],
      :end_time => params[:end],
      :interval => params[:interval],
      :search_type => "count",
    })
    policy_scope(@search)

    @search.search!(params[:search])
    @search.filter_by_date_range!
    @search.aggregate_by_interval!
    @search.aggregate_by_users!(10)
    @search.aggregate_by_request_ip!(10)
    @search.aggregate_by_response_time_average!
    @search.search_type!("count")

    @result = @search.result
  end

  def logs
    @search = LogSearch.new({
      :start_time => params[:start_time],
      :end_time => params[:end_time],
      :interval => params[:interval],
    })
    policy_scope(@search)

    offset = params[:start].to_i
    limit = params[:length].to_i
    if(request.format == "csv")
      limit = 500
    end

    @search.search!(params[:search])
    @search.filter_by_date_range!
    @search.offset!(offset)
    @search.limit!(limit)

    sort = datatables_sort
    if(sort.any?)
      @search.sort!(sort)
    end

    if(request.format == "csv")
      @search.query_options[:search_type] = "scan"
      @search.query_options[:scroll] = "10m"
    end

    @result = @search.result

    respond_to do |format|
      format.json
      format.csv do
        # Set Last-Modified so response streaming works:
        # http://stackoverflow.com/a/10252798/222487
        response.headers["Last-Modified"] = Time.now.httpdate

        scroll_id = @result.raw_result.raw_plain["_scroll_id"]
        headers = ["Time", "Method", "Host", "URL", "User", "IP Address", "Country", "State", "City", "Status", "Response Time", "Content Type", "Accept Encoding", "User Agent"]

        send_file_headers!(:disposition => "attachment", :filename => "api_logs (#{Time.now.strftime("%b %-e %Y")}).#{params[:format]}")
        self.response_body = CsvStreamer.new(scroll_id, headers) do |row|
          [
            Time.parse(row["request_at"]).utc.strftime("%Y-%m-%d %H:%M:%S"),
            row["request_method"],
            row["request_host"],
            row["request_url"],
            row["user_email"],
            row["request_ip"],
            row["request_ip_country"],
            row["request_ip_region"],
            row["request_ip_city"],
            row["response_status"],
            row["response_time"],
            row["response_content_type"],
            row["request_accept_encoding"],
            row["request_user_agent"],
          ]
        end
      end
    end
  end

  def users
    @search = LogSearch.new({
      :start_time => params[:start_time],
      :end_time => params[:end_time],
    })
    policy_scope(@search)

    offset = params[:start].to_i
    limit = params[:length].to_i
    if(request.format == "csv")
      limit = 100_000
    end

    sort = datatables_sort.first
    sort_field = sort.keys.first if(sort)
    sort_direction = sort.values.first if(sort)

    # If we're sorting by hits or last request date, then we can perform the
    # sorting directly in the elasticsearch query. Otherwise, for user-based
    # field, we'll need to defer sorting until we have all the results in ruby.
    aggregation_options = {}
    if sort
      case(sort_field)
      when "hits"
        aggregation_options[:order] = {
          "_count" => sort_direction,
        }
      when "last_request_at"
        aggregation_options[:order] = {
          "last_request_at" => sort_direction,
        }
      end
    end

    @search.search!(params[:search])
    @search.filter_by_date_range!
    @search.aggregate_by_user_stats!(aggregation_options)

    @result = @search.result
    buckets = @result.aggregations["user_stats"]["buckets"]
    @total = buckets.length

    # If we were sorting by one of the facet fields, then the sorting has
    # already been done by elasticsearch. We can improve the performance by
    # going ahead and truncating the results to the specified page.
    if(aggregation_options[:order])
      buckets = buckets.slice(offset, limit)
    end

    user_ids = buckets.map { |bucket| if(bucket) then bucket["key"] else nil end }
    users_by_id = ApiUser.where(:_id.in => user_ids).all.to_a.group_by { |user| user.id.to_s }

    # Build up the results, combining the stats facet information with the user
    # details.
    @user_data = []
    buckets.map do |bucket|
      user = {}
      if(users_by_id[bucket["key"]])
        user = users_by_id[bucket["key"]].first.attributes
      end

      @user_data << {
        :id => bucket["key"],
        :email => user["email"],
        :first_name => user["first_name"],
        :last_name => user["last_name"],
        :website => user["website"],
        :registration_source => user["registration_source"],
        :created_at => user["created_at"],
        :hits => bucket["doc_count"],
        :last_request_at => Time.at(bucket["last_request_at"]["value"] / 1000),
        :use_description => user["use_description"],
      }
    end

    # If sorting was on any of the user fields, now that we have a full result
    # set now we can manually sort and paginate.
    if(!aggregation_options[:order])
      @user_data.sort_by! { |user| user[:"#{sort_field}"].to_s }
      if(sort_direction == "desc")
        @user_data.reverse!
      end

      @user_data = @user_data.slice(offset, limit)
    end

    respond_to do |format|
      format.json
      format.csv
    end
  end

  def map
    @search = LogSearch.new({
      :start_time => params[:start],
      :end_time => params[:end],
      :region => params[:region],
    })
    policy_scope(@search)

    @search.search!(params[:search])
    @search.filter_by_date_range!
    @search.aggregate_by_region!

    @result = @search.result

    respond_to do |format|
      format.json
      format.csv
    end
  end

  private

  def set_time_zone
    old_time_zone = Time.zone
    if(params[:tz].present?)
      Time.zone = params[:tz]
    end

    yield
  ensure
    Time.zone = old_time_zone
  end
end
