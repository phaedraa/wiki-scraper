class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def scrape_wikipedia
    require 'nokogiri'
    require 'open-uri'
    doc = Nokogiri::HTML(open("https://en.wikipedia.org/wiki/Portal:Current_events/January_2010#2010_January_2"))
    #css_table = doc.at_css('table')
    tables = doc.css('table.vevent')
    first_table = tables[0]

    #title
    title_header = first_table.css('span.summary')
    title_text = title[0].text
    #"Current events of January 1, 2010 (2010-01-01) (Friday)"
    paren1_idx = title_text.index("(")
    paren2_idx = title_text.index(")")

    #date
    date = title_text[paren1_idx + 1 .. paren2_idx - 1]

    #content
    content = tables.css('td.description')
    events = content.css('li')
    event_urls = events.map do |event|
      event.css('a')[0]['href']
    end

    first_event = Nokogiri::HTML(open("https://en.wikipedia.org" + event_urls[0]))
    heading = first_event.css('h1.firstHeading')
    
    paragraphs = first_event.css('div.mw-body-content').css('div.mw-content-ltr')
    
    paragraphs2 = paragraphs.xpath('//p[count(preceding-sibling::h2) = 0 and count(following-sibling::div) > 0]')
    text = ''
    paragraphs2.each do |paragraph|
      text = text + paragraph.text
    end

    event_text = ''
    str_len = text.length
    idx = 0
    while idx < str_len
      event_text += text[idx]
      idx+=1
      if text[idx] == '['
        while idx + 1 < str_len && text[idx] != ']'
          idx+=1
        end
        idx+=1
      end
    end

    
    #event_text += text[idx]

    #rows = tables.css('tr')
    #column_names = rows.shift.css('th').map(&:text)
    #puts column_names
    #@occurances = []
    #text_all_rows = rows.map do |row|
    #  row_name = row.css('th').text
    #  row_values = row.css('td').map(&:text)
    #  [row_name, *row_values]
    #end

    #doc.xpath("//tr").each do |x|
    #   date = x.css("td")[0].text
    #   date2 = x.css("td")[1].text
    #   date3 = x.css("td")[2].text
    #   @occurances << {:date => date, :date2 => date2, :date3=>date3}
    #end
    #puts @occurances
    puts text_all_rows
    render text: doc 
  end

end
