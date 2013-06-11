require "rspec/core/rake_task"

require_relative "lib/solr_performance_testing"

desc "Run RSpec unit tests"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/*_spec.rb'
end

desc "solr performance testing"
task :solr_bench, [:comp_cnt, :thread_cnt, :servers] do |t, args|
  args.with_defaults(
      :comp_cnt => 10,
      :thread_cnt => 1,
      :servers => {
          '29' => 'http://datanode29.companybook.no:8360/solr/gb_companies_20130418',
          '30' => 'http://datanode30.companybook.no:8360/solr/gb_companies_20130418'
      }
  )
  p args
  bench = SolrPerformanceTesting.new
  bench.search_companies(args[:comp_cnt].to_i, args[:thread_cnt].to_i, args[:servers])
end


