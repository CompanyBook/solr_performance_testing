require "rspec"
require "solr"
require 'rsolr'
require "json"
require "benchmark"
require_relative '../lib/logging'

class SolrPerformanceTesting
  include Logging

  def companies
    @companies ||= open(File.dirname(__FILE__) + '/../data/search_queries.txt', "r:UTF-8").lines.map { |line| line.strip }
  end

  def companies_skip_and_take(skip_cnt, take_cnt)
    companies.drop(skip_cnt).take(take_cnt)
  end

  def companies_search(thread_num, max_count, url)
    result_cnt = 0
    total_q_time = 0
    slowest = [0, 'none']
    companies_skip_and_take(thread_num*max_count, max_count).each do |company|
      q_time, hit_cnt = search(url, '"' + company + '"')
      result_cnt += hit_cnt
      total_q_time += q_time
      slowest = [q_time, company] if (q_time > slowest[0])
    end
    return total_q_time, result_cnt, slowest
  end

  def search_companies(max_count=1, thread_cnt=1, serves = {
      'n29' => 'http://datanode29.companybook.no:8360/solr/gb_companies_20130418',
  })

    puts "will search #{max_count} companies"

    result_counts = Hash.new { |k, v| k[v] = 0 }
    q_times = Hash.new { |k, v| k[v] = 0 }
    slowest_counts = Hash.new { |k, v| k[v] = [0, ''] }

    Benchmark.bm(1) do |x|
      serves.each do |name, url|
        x.report(name) do
          threads = []
          thread_cnt.to_i.times do |n|
            threads << Thread.new do
              q_time, result_cnt, slowest = companies_search(n, max_count, url)
              q_times["#{name}_Qtime_#{n}"] = q_time
              result_counts["#{name}_hits_#{n}"] = result_cnt
              slowest_counts["#{name}_maxTime_#{n}"] = slowest
            end
          end
          threads.each { |t| t.join }
        end
      end

      result_counts.sort_by { |name, value| name }.each { |k, v| puts "#{k} - #{v}" }
      q_times.sort_by { |name, value| name }.each { |k, v| puts "#{k} - #{v}" }
      slowest_counts.sort_by { |name, value| name }.each { |k, v| puts "#{k} - #{v}" }
      puts "Total Qtime used:" + q_times.values.inject { |sum, v| sum + v }.to_s
      puts "Total Worst used:" + slowest_counts.values.map { |v| v[0] }.inject { |sum, v| sum + v }.to_s
    end
  end

  def search(url, search_text="*:*")
    #puts search_text
    solr = RSolr.connect :url => url

    params = {
        :q => search_text,
        #:facet => 'true',
        :utf8 => '?',
        :location => '150-154-GB',
        'shards.qt' => 'dismax_flat2',
        'facet.limit' => '3',
        'f.location.facet.limit' => '10',
        :hl => 'true',
        :version => '2',
        :fl => 'name,company_id,revenue,org_num,city,geolocation,geolocation_source,country_iso,industry_code,nace_2,naics_4,naics_6,employees_count,structure,profit,location,region,sub_region',
        :bq => 'country_iso:GB^500+company_id:GB0000000288451024^9999',
        'facet.query' => ['employees_count:[1+TO+10]', 'employees_count:[11+TO+50]', 'employees_count:[51+TO+200]', 'employees_count:[201+TO+500]', 'employees_count:[501+TO+1000]', 'employees_count:[1001+TO+5000]', 'employees_count:[5001+TO+10000]', 'employees_count:[10001+TO+10000000]', 'revenue:[0.02+TO+500000]', 'revenue:[0.05+TO+500000]', 'revenue:[1+TO+500000]', 'revenue:[10+TO+500000]', 'revenue:[80+TO+500000]', 'revenue:[200+TO+500000]', 'revenue:[500+TO+500000]', 'profit:[-2100+TO+-0.0001]', 'profit:[0.02+TO+500000]', 'profit:[0.05+TO+500000]', 'profit:[1+TO+500000]', 'profit:[10+TO+500000]', 'profit:[80+TO+500000]', 'profit:[200+TO+500000]', 'profit:[500+TO+500000]'],
        :bf => 'log(max(1,boost_revenue))^200',
        :action => 'show',
        'facet.field' => ['location', 'region', 'naics_6'],
        :qt => 'dismax_flat',
        'f.naics_6.facet.limit' => '30',
        'hl.fragsize' => '280',
        :industry_classification => 'naics_6',
        :industry_coverage => '0.6',
        'facet.mincount' => '1',
        :resource => 'search',
        'hl.fl' => ['body', 'body_1', 'body_2', 'name', 'title', 'keywords', 'meta_description', 'ceo', 'chairman', 'board_member', 'key_people'],
        'hl.maxAnalyzedChars' => '500000',
        'f.region.facet.limit' => '5',
        :rows => '15',
        :user_country_iso => 'GB',
        :controller => 'companies/search',
        'hl.usePhraseHighlighter' => 'true',
        :pf => 'title^10 meta_description^10 keywords^10 name^10',
        :qf => 'body_1^0.05 body^0.1 body_2^0.01 chairman structure^0.1 keywords^0.3 ext_link_texts^0.5 city^4 key_people ceo title^0.3 meta_description^0.3 name^10 board_member',
        :fq => ['location:150-154-GB', '-active:1', '-region:039', 'naics_6:551112 OR name:"holding"'],
    }

    #response = solr.get 'select', :params => {q: search_text, rows:1, fl:'company_id', facet: true, 'shards.qt' => 'dismax_flat'}
    response = solr.get 'select', :params => params

    query_time = response['responseHeader']['QTime'].to_i
    hits = response['response']['numFound'].to_i
    log.info "#{search_text} qTime:#{query_time} hits:#{hits}"
    return query_time, hits
  end
end


