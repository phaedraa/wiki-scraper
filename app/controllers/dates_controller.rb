class DatesController < ApplicationController
  require 'Date'
  require 'nokogiri'
  require 'open-uri'
  require 'URI'
  
  def index
    date = '2016-3-2'
    #debugger
    date = Date.parse(date)
    month = Date::MONTHNAMES[date.mon]
    year = date.year
    day = date.day
    if !Date.valid_date?(year, date.mon, day)
      raise TypeError, 'Parsed invalid date: #{year}-#{date.mon}-#{day}'
    end
    date_url = "#{month}_#{year}" + "#" + "#{year}_#{month}_#{day}"
    doc = Nokogiri::HTML(open("https://en.wikipedia.org/wiki/Portal:Current_events/#{date_url}"))
    div_id = "#{year}_#{month}_#{day < 10 ? '0' : ''}#{day}"
    table = doc.xpath("//div[@id='#{div_id}']").first.next_element
    #next_date = date.next
    #next_div_id = "#{next_date.year}_#{Date::MONTHNAMES[next_date.month]}_#{next_date.day}"
    #tables = doc.css('table.vevent')
    #first_table = tables[0]
    #title_header = first_table.css('span.summary')
    #title_text = title_header[0].text
    ##"Current events of January 1, 2010 (2010-01-01) (Friday)"

    #content
    content = table.css('td.description')
    events = content.css('li')

    data_to_log = []
    events.each do |event|
      data_to_log.push(getEventData(event.css('a')[0]))
    end

    #Cash this locally
    @event_data = Hash[date.strftime('%s') => data_to_log]
  end

  def getEventData(anchor_image)
    url = anchor_image['href']
    title = anchor_image.text
    summary = ''
    image_url = ''
    wiki_url = "https://en.wikipedia.org#{url}"
    begin
      first_event = Nokogiri::HTML(open("https://en.wikipedia.org#{url}"))
      content = first_event.css('div.mw-body-content').css('div.mw-content-ltr')
      title = first_event.css('h1.firstHeading').text
      image_box = content.css('table.infobox').css('a.image')
      image_url = image_box.length < 1 ? '' : image_box[0]['href']
      
      paragraphs = content.xpath(
        '//p[count(preceding-sibling::h2) = 0 and count(preceding-sibling::table) > 0 and count(following-sibling::div) > 0]'
      )
      paragraphs.each do |paragraph|
        summary = summary + paragraph.text
      end
    rescue OpenURI::HTTPError => e
      print "URI: #{url} no longer exists: " + e.to_s
    rescue
      print "Not an HTTPError"
    end

    summary_stripped = strip_citations(summary)

    return {
      :wiki_url => wiki_url,
      :title => title == nil || title.length < 1 ? '' : title,
      :summary => summary_stripped,
      :image_url => image_url
    }
  end

  def strip_citations(summary)
    if summary.length == 0
      return ''
    end

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
