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
    content = first_table.css('td.description')
    events = content.css('li')
    event_urls = events.map do |event|
      event.css('a')[0]['href']
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

  def getEventData(url)
    first_event = Nokogiri::HTML(open("https://en.wikipedia.org" + url))
    
    heading = first_event.css('h1.firstHeading').text
    content = first_event.css('div.mw-body-content').css('div.mw-content-ltr')
    image_url = content.css('table.infobox').css('a.image')[0]['href']

    paragraphs = content.xpath('//p[count(preceding-sibling::h2) = 0 and count(following-sibling::div) > 0]')
    summary = ''
    paragraphs.each do |paragraph|
      summary = summary + paragraph.text
    end

    summary_stripped = strip_citations(summary)

    return {:summary => summary_stripped, :image_url => image_url, :title => heading}
  end

  def strip_citations(summary)
    idx_to_strip = []
    pair = []
    idx = 0
    (0..(summary.length - 1)).each do |idx|
      if summary[idx] == '[' || summary[idx] == ']'
        if pair.length == 2
          idx_to_strip.push(pair)
          pair = [idx]
        else
          pair.push(idx)
        end
      end 
    end

    if pair.length == 2
      idx_to_strip.push(pair)
    end

    summary_stripped = ''
    idx_to_strip.each do |pair|
      if idx < pair[0] + 1
        summary_stripped += summary[idx..pair[0]-1]
      end
      idx = pair[1]+1
    end

    if idx < summary.length
      summary_stripped += summary[idx+1..-1]
    end

    return summary_stripped
  end

  # not sure if Ruby String class uses a String builder... Trying
  # to avoid making new string copies for length of the string times
  def strip_citations_potentially_inefficient(summary)
    summary_stripped = ''
    str_len = summary.length
    idx = 0
    while idx < str_len
      summary_stripped += summary[idx]
      idx+=1
      while summary[idx] == '['
        while idx + 1 < str_len && summary[idx] != ']'
          idx+=1
        end
        idx+=1
      end
    end
    return summary_stripped
  end
end
