Fabricator :notice do
  problem { Fabricate(:problem) }
  error_class 'FooError'
  message 'FooError: Too Much Bar'
  backtrace
  server_environment  { { 'environment-name' => 'production' } }
  request             { { 'component' => 'foo', 'action' => 'bar' } }
  notifier            { { 'name' => 'Notifier', 'version' => '1', 'url' => 'http://toad.com' } }
end
