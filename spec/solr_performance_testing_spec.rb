require "rspec"
require 'solr'
require_relative "../lib/solr_performance_testing"

describe SolrPerformanceTesting do
  let(:comp) { SolrPerformanceTesting.new }

  it 'should search solr' do
    comp.search('http://datanode29.companybook.no:8360/solr/gb_companies_20130418')
  end

  it 'should benchmark' do
    comp.search_companies(1, 1)
  end

  it 'should read lines' do
    lines = comp.companies.take(100)
    p lines
  end

  it 'convert query from log into rsolr query' do
    a = 'facet=true&utf8=?&location=150-154-GB&shards.qt=dismax_flat&facet.limit=3&f.location.facet.limit=10&hl=true&version=2&fl=name,company_id,revenue,org_num,city,geolocation,geolocation_source,country_iso,industry_code,nace_2,naics_4,naics_6,employees_count,structure,profit,location,region,sub_region&bq=country_iso:GB^500+company_id:GB0000000288451024^9999&shards=localhost:8360/solr/no_companies_20130418_stem,localhost:8360/solr/gb_companies_20130602_stem,localhost:8360/solr/se_companies_20130423,localhost:8360/solr/dk_companies_20130423,localhost:8360/solr/global_20130423&geolocation={}&facet.query=employees_count:[1+TO+10]&facet.query=employees_count:[11+TO+50]&facet.query=employees_count:[51+TO+200]&facet.query=employees_count:[201+TO+500]&facet.query=employees_count:[501+TO+1000]&facet.query=employees_count:[1001+TO+5000]&facet.query=employees_count:[5001+TO+10000]&facet.query=employees_count:[10001+TO+10000000]&facet.query=revenue:[0.02+TO+500000]&facet.query=revenue:[0.05+TO+500000]&facet.query=revenue:[1+TO+500000]&facet.query=revenue:[10+TO+500000]&facet.query=revenue:[80+TO+500000]&facet.query=revenue:[200+TO+500000]&facet.query=revenue:[500+TO+500000]&facet.query=profit:[-2100+TO+-0.0001]&facet.query=profit:[0.02+TO+500000]&facet.query=profit:[0.05+TO+500000]&facet.query=profit:[1+TO+500000]&facet.query=profit:[10+TO+500000]&facet.query=profit:[80+TO+500000]&facet.query=profit:[200+TO+500000]&facet.query=profit:[500+TO+500000]&bf=log(max(1,boost_revenue))^200&action=show&facet.field=location&facet.field=region&facet.field=naics_6&qt=dismax_flat&fq=location:150-154-GB&fq=-active:1&fq=-region:039&fq=naics_6:551112+OR+name:"holding"&f.naics_6.facet.limit=30&hl.fragsize=280&industry_classification=naics_6&industry_coverage=0.6&facet.mincount=1&qf=body_1^0.05+body^0.1+body_2^0.01+chairman+structure^0.1+keywords^0.3+ext_link_texts^0.5+city^4+key_people+ceo+title^0.3+meta_description^0.3+name^10+board_member&resource=search&hl.fl=body&hl.fl=body_1&hl.fl=body_2&hl.fl=name&hl.fl=title&hl.fl=keywords&hl.fl=meta_description&hl.fl=ceo&hl.fl=chairman&hl.fl=board_member&hl.fl=key_people&hl.maxAnalyzedChars=500000&wt=javabin&f.region.facet.limit=5&rows=15&pf=title^10+meta_description^10+keywords^10+name^10&guess_facets=&start=0&q=holding+OR+company_id:GB0000000288451024&user_country_iso=GB&controller=companies/search&hl.usePhraseHighlighter=true'

    b = a.split('&').map { |it| it.split('=').map { |p| "'#{p}'" } }

    result = Hash.new { |hash, key| hash[key] = [] }

    b.each do |a, b|
      result[a] << b
    end

    result2 = {}
    result.each do |k,v|
      result2[k] = v.size > 1 ? "[#{v.join(',')}]" : v[0]
    end

    result2.each do |a,b|
      puts "#{a} => #{b}, "
    end
  end

end