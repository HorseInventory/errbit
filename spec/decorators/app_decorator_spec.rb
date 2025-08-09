describe AppDecorator do
  describe "#email_at_notices" do
    it 'return the list separate by comma' do
      expect(AppDecorator.new(double(email_at_notices: [2, 3])).email_at_notices).to eql '2, 3'
    end
  end

  describe "#notify_err_display" do
    it 'return display:none if no notify' do
      expect(AppDecorator.new(double(notify_on_errs: false)).notify_err_display).to eql 'display: none;'
    end

    it 'return blank if no notify' do
      expect(AppDecorator.new(double(notify_on_errs: true)).notify_err_display).to eql ''
    end
  end

  context '#custom_backtrace_url' do
    it 'should correctly replace the unescaped fields' do
      app = Fabricate(
        :app,
        custom_backtrace_url_template: 'https://example.com/repo/name/src/branch/%{branch}/%{file}#L%{line}',
        repository_branch: 'feature/branch'
      )
      expect(AppDecorator.new(app).custom_backtrace_url("test/file.rb", 42)).to \
        eq 'https://example.com/repo/name/src/branch/feature/branch/test/file.rb#L42'
    end

    it 'should correctly replace the escaped fields' do
      app = Fabricate(
        :app,
        custom_backtrace_url_template: 'https://example.com/repo/name/src/branch/%{ebranch}/%{efile}#L%{line}',
        repository_branch: 'feature/branch'
      )
      expect(AppDecorator.new(app).custom_backtrace_url("test/file.rb", 42)).to \
        eq 'https://example.com/repo/name/src/branch/feature%2Fbranch/test%2Ffile.rb#L42'
    end
  end
end
