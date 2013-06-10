require "rspec"
require 'solr'
require_relative "../lib/solr_performance_testing"

describe SolrPerformanceTesting do
  let(:comp) { SolrPerformanceTesting.new }

  it 'should search solr' do
    comp.search('http://datanode29.companybook.no:8360/solr/gb_companies_20130418')
  end

  it 'should benchmark' do
    comp.search_companies(100, 10)
  end

  it 'should get random companies' do
    companies = comp.random_companies
    puts companies.take(10)
  end

  it 'should read lines' do
    lines = comp.companies.take(100)
    p lines
  end

end