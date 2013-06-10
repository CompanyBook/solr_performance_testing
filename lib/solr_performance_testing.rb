require "rspec"
require "solr"
require 'rsolr'
require "json"
require "benchmark"

class SolrPerformanceTesting
  def companies
    @companies ||= open(File.dirname(__FILE__) + '/../data/search_queries.txt', "r:UTF-8").lines.map { |line| line.strip }
  end

  def random_companies(max=10000)
    companies.take(max).shuffle
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
              #sleep(0.1)
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
      puts "Total Worst used:" + slowest_counts.values.map { |v| v[0] }. inject { |sum, v| sum + v }.to_s
    end

  end

  def search(url, search_text="*:*")
    puts search_text
    solr = RSolr.connect :url => url
    response = solr.get 'select', :params => {q: search_text, rows:1, fl:'company_id'}
    return response['responseHeader']['QTime'].to_i, response['response']['numFound'].to_i
  end
end


