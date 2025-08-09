Fabricator(:problem) do
  app { Fabricate(:app) }
  error_class 'FooError'
  environment 'production'
  message 'FooError: Too Much Bar'
  where 'app#bar'
end

Fabricator(:problem_with_notices, from: :problem) do
  after_create do |parent|
    3.times do
      Fabricate(:notice, problem: parent)
    end
  end
end

Fabricator(:problem_resolved, from: :problem) do
  after_create do |pr|
    Fabricate(:notice, problem: pr)
    pr.resolve!
  end
end
