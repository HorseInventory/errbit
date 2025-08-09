describe ErrorReport do
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
        user_attributes:    {
          "id"       => "123",
          "name"     => "Mr. Bean",
          "email"    => "mr.bean@example.com",
          "username" => "mrbean",
        },
      }
    end
  end
  let(:notice_attrs) { notice_attrs_for.call(app.api_key) }
  let!(:app) do
    Fabricate(
      :app,
      api_key: 'APIKEY',
    )
  end
  let!(:user) { Fabricate(:user) }
  let(:error_report) { ErrorReport.new(notice_attrs) }

  before { user }

  describe "#app" do
    it 'find the good app' do
      expect(error_report.app).to(eq(app))
    end
  end

  describe "#generate_notice!" do
    it "save a notice" do
      expect do
        error_report.generate_notice!
      end.to(change do
        app.reload.problems.count
      end.by(1))
    end

    describe "notice create" do
      before { error_report.generate_notice! }
      subject { error_report.notice }

      it 'has correct framework' do
        expect(subject.framework).to(eq('Rails: 3.2.11'))
      end

      it 'has a backtrace' do
        expect(subject.backtrace_lines.size).to(be > 0)
      end

      it 'has server_environement' do
        expect(subject.server_environment['environment-name']).to(eq('development'))
      end

      it 'has request' do
        expect(subject.request).to(be_a(Hash))
      end

      it 'get user_attributes' do
        expect(subject.user_attributes['id']).to(eq('123'))
        expect(subject.user_attributes['name']).to(eq('Mr. Bean'))
        expect(subject.user_attributes['email']).to(eq('mr.bean@example.com'))
        expect(subject.user_attributes['username']).to(eq('mrbean'))
      end

      it 'valid env_vars' do
        expect(subject.env_vars).to(be_a(Hash))
      end
    end
  end

  describe '#cache_attributes_on_problem' do
    it 'sets the latest notice properties on the problem' do
      error_report.generate_notice!
      problem = error_report.problem.reload
      notice = error_report.notice.reload

      expect(problem.environment).to(eq('development'))
      expect(problem.last_notice_at).to(eq(notice.created_at))
      expect(problem.message).to(eq(notice.message))
      expect(problem.where).to(eq(notice.where))
    end

    it 'unresolves the problem' do
      error_report.generate_notice!
      problem = error_report.problem
      problem.update(
        resolved_at: Time.zone.now,
        resolved:    true,
      )

      error_report = ErrorReport.new(notice_attrs)
      error_report.generate_notice!
      problem.reload

      expect(problem.resolved_at).to(be(nil))
      expect(problem.resolved).to(be(false))
    end
  end

  it 'save a notice assigned to a problem' do
    error_report.generate_notice!
    expect(error_report.notice.problem).to(be_a(Problem))
  end

  it 'memoize the notice' do
    expect do
      error_report.generate_notice!
      error_report.generate_notice!
    end.to(change do
      Notice.count
    end.by(1))
  end

  it 'find the correct (duplicate) Problem (and resolved) for the Notice' do
    error_report.generate_notice!
    error_report.problem.resolve!

    expect do
      ErrorReport.new(notice_attrs).generate_notice!
    end.to(change do
      error_report.problem.reload.resolved?
    end.from(true).to(false))
  end

  context "with notification service configured" do
    before do
      app.notify_on_errs = true
      app.save
    end

    it 'send email' do
      notice = error_report.generate_notice!
      email = ActionMailer::Base.deliveries.last
      expect(email.to).to(include(User.first.email))
      expect(email.subject).to(include(notice.message.truncate(50)))
    end

    context 'when email_at_notices config is specified', type: :mailer do
      before do
        allow(Errbit::Config).to(receive(:email_at_notices).and_return(email_at_notices))
      end

      context 'as [0]' do
        let(:email_at_notices) { [0] }

        it "sends email on 1st occurrence" do
          1.times { described_class.new(notice_attrs).generate_notice! }
          expect(ActionMailer::Base.deliveries.length).to(eq(1))
        end

        it "sends email on 2nd occurrence" do
          2.times { described_class.new(notice_attrs).generate_notice! }
          expect(ActionMailer::Base.deliveries.length).to(eq(2))
        end

        it "sends email on 3rd occurrence" do
          3.times { described_class.new(notice_attrs).generate_notice! }
          expect(ActionMailer::Base.deliveries.length).to(eq(3))
        end
      end

      context "as [1,3]" do
        let(:email_at_notices) { [1, 3] }

        it "sends email on 1st occurrence" do
          1.times { described_class.new(notice_attrs).generate_notice! }
          expect(ActionMailer::Base.deliveries.length).to(eq(1))
        end

        it "does not send email on 2nd occurrence" do
          2.times { described_class.new(notice_attrs).generate_notice! }
          expect(ActionMailer::Base.deliveries.length).to(eq(1))
        end

        it "sends email on 3rd occurrence" do
          3.times { described_class.new(notice_attrs).generate_notice! }
          expect(ActionMailer::Base.deliveries.length).to(eq(2))
        end

        it "sends email on all occurrences when problem was resolved" do
          3.times do
            notice = described_class.new(notice_attrs).generate_notice!
            notice.problem.resolve!
          end
          # With simplified behavior, resolution triggers an email on the next occurrence only
          expect(ActionMailer::Base.deliveries.length).to(eq(2))
        end
      end
    end
  end

  describe "#notice" do
    context "before generate_notice!" do
      it 'return nil' do
        expect(error_report.notice).to(be(nil))
      end
    end

    context "after generate_notice!" do
      before do
        error_report.generate_notice!
      end

      it 'return the notice' do
        expect(error_report.notice).to(be_a(Notice))
      end
    end
  end
end
