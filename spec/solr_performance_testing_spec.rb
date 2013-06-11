require "rspec"
require 'solr'
require_relative "../lib/solr_performance_testing"

describe SolrPerformanceTesting do
  let(:comp) { SolrPerformanceTesting.new }

  it 'should search solr' do
    comp.search('http://datanode29.companybook.no:8360/solr/gb_companies_20130418')
  end

  it 'should benchmark' do
    comp.search_companies(500, 5)
  end

  it 'should read lines' do
    lines = comp.companies.take(100)
    p lines
  end

end