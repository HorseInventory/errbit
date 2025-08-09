Fabricator(:app) do
  name { sequence(:app_name) { |n| "App ##{n}" } }
  repository_branch 'master'
  custom_backtrace_url_template 'https://github.com/foo/bar/blob/%{branch}/%{file}#L%{line}'
end
