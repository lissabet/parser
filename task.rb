require 'open-uri'
require 'nokogiri'
require 'csv'
require 'mechanize'

def csv_export(url, filename)
  agent = Mechanize.new
  page = agent.get(url)
  CSV.open(filename, "w")
  pages = page.search('//*[@id="pagination_bottom"]/ul/li')
  if (pages.count > 0)
    index_last_page = pages.count - 1
    clicks = page.xpath('//*[@id="pagination_bottom"]/ul/li[%d]/a/span'%index_last_page).text.strip
  else
    clicks = 1
  end

  num = 2
  while (num <(clicks.to_i+2))
    page.xpath('//*[@id="center_column"]/div[3]/div').each do |elem|
      links = page.links_with(class: "lnk_view")
      links.each do |link|
        item = link.click
        new_page = item.parser
        if (new_page.search('//*[@id="attributes"]/fieldset/div').count == 0)
          name = new_page.xpath('//*[@id="right"]/div/div[1]/div/h1/text()').text.strip
          prise = new_page.xpath('//*[@id="price_display"]').text.strip
          image = new_page.xpath('//*[@id="bigpic"]/@src')
          CSV.open(filename, "a+") do |wr|
            wr << [name, prise, image]
          end
        end
        new_page.xpath('//li/span[1]').each do |el|
          weight = el.text.strip
          if (/^\d{0,3}\s\w{1,8}.|(\w)&/.match(weight))
            name = new_page.xpath('//*[@id="right"]/div/div[1]/div/h1/text()').text.strip
            image = new_page.xpath('//*[@id="bigpic"]/@src')
            name += " - " + weight
            prise_per_weight = ''
            new_page.xpath('//li/span[3]').each do |pris|
              prise_per_weight = pris.text.strip
            end
            CSV.open(filename, "a+") do |wr|
              wr << [name, prise_per_weight, image]
            end
          end
        end
      end
    end
    num +=1
    next_page = page.search('//*[@id="pagination_bottom"]/ul/li[%d]/a/@href'%num).first
    new_page = "http://www.petsonic.com"
    if (next_page)
      new_page += next_page
      page = agent.get(new_page)
    end
  end
end

csv_export('http://www.petsonic.com/es/perros/snacks-y-huesos-perro/higiene-dental-perro', 'new2.csv')

