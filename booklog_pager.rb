# encoding: utf-8

require "nokogiri"
require "open-uri"
require "uri"

class BooklogPager
  include Enumerable

  attr_accessor :doc
  
  def initialize(keyword)
    @continue = true
    @page     = 2
    url       = URI.escape("http://booklog.jp/users/gmobooks?display=front&keyword=#{keyword}")
    @doc      = Nokogiri::HTML(open(url))
    next_link = @doc.xpath("//*[@id=\"shelf\"]/div[3]/ul/li[#{@page}]/a")
    if next_link.empty?
      self.stop
    end
  end

  def stop
    @continue = false
  end

  def next
    next_link = @doc.xpath("//*[@id=\"shelf\"]/div[3]/ul/li[#{@page}]/a")
    if next_link.empty?
      self.stop
      return self
    end
    
    next_link = next_link[0].get_attribute('href')
    next_link = 'http://booklog.jp/users/gmobooks' + next_link unless /^http/ =~ next_link

    @continue = true
    @page += 1
    @doc = Nokogiri::HTML(open(next_link))

    self
  end

  def each
    yield @doc

    if @continue
      self.next.each do |doc|
        yield doc
      end
    end
  end
end

pager = BooklogPager.new(ARGV[0])

pager.each do |doc|
  doc.xpath('//h2[@class="shelfItemInfoTitle"]/a').each do |node|
    puts node.text
  end
end

