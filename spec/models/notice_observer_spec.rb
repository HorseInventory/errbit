describe "Callback on Notice", type: 'model' do
  let(:notice_attrs_for) do
    lambda do |api_key|
      {
        error_class:        "TestingException",
        message:            "some message",
        backtrace:          [
          {
            "number" => "425",
            "file"   => "[GEM_ROOT]/callbacks.rb",
            "method" => "__callbacks",
          },
        ],
        request:            { "component" => "application" },
        server_environment: {
          "project-root"     => "/path/to/sample/project",
          "environment-name" => "development",
        },
        api_key:            api_key,
        notifier:           {
          "name"    => "Example Notifier",
          "version" => "2.3.2",
          "url"     => "http://example.com",
        },
        framework:          "Rails: 3.2.11",
      }
    end
  end

  describe 'email notifications (configured individually for each app)' do
    let(:notice_attrs) { notice_attrs_for.call(app.api_key) }
    custom_thresholds = [2, 4, 8, 16, 32, 64]
    let(:app) do
      Fabricate(:app, email_at_notices: custom_thresholds)
    end

    before do
      Fabricate(:user)
      Errbit::Config.per_app_email_at_notices = true
      error_report = ErrorReport.new(notice_attrs)
      error_report.generate_notice!
      @problem = error_report.notice.problem
    end

    after { Errbit::Config.per_app_email_at_notices = false }

    custom_thresholds.each do |threshold|
      it "sends an email notification after #{threshold} notice(s)" do
        notices_needed = threshold - @problem.notices_count - 1
        notices_needed.times { Fabricate(:notice, problem: @problem) }

        expect(Mailer).to(receive(:err_notification).
          and_return(double('email', deliver_now: true)))

        error_report = ErrorReport.new(notice_attrs)
        error_report.generate_notice!
        expect(error_report.should_email?).to(be(true))
      end
    end
  end
end
