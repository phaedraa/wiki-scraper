class DatesController < ApplicationController
  require 'Date'
  require 'nokogiri'
  require 'open-uri'
  require 'URI'
  require 'Event'
  
  def show_date_events
    #date = '2016-3-4'
    day = Date.parse(params[:date])
    @event_date = day.strftime('%B %d, %Y')
    @events = Event.where(:day => day)
    #if @events.length == 0
      fetch_and_store_date_events(day)
      @events = Event.where(:day => day)
    #end
  end

  def index
    @stored_dates = Event.uniq.pluck(:day)
  end

  def fetch_and_store_date_events(date)
    #date = '2016-3-2'
    #debugger
    #date = Date.parse(date)
    month = Date::MONTHNAMES[date.mon]
    year = date.year
    day = date.day
    if !Date.valid_date?(year, date.mon, day)
      raise TypeError, 'Parsed invalid date: #{year}-#{date.mon}-#{day}'
    end

    date_url = "#{month}_#{year}" + "#" + "#{year}_#{month}_#{day}"
    doc = Nokogiri::HTML(open("https://en.wikipedia.org/wiki/Portal:Current_events/#{date_url}"))
    div_id = "#{year}_#{month}_#{day < 10 ? '0' : ''}#{day}"

    # TODO: Handle case if data doesn't exists/no events for this date
    table = doc.xpath("//div[@id='#{div_id}']").first.next_element

    content = table.css('td.description')
    events = content.css('li')

    data_to_log = []
    events.each do |event|
      data_to_log.push(getEventData(event.css('a')[0]))
    end

    day = date.strftime('%s')
    # TODO: create data first, then save
    data_to_log.each do |events_data|
      #puts events_data
      @event = Event.new(
        day: date,
        wiki_url: events_data[:wiki_url],
        title: events_data[:title],
        summary: events_data[:summary],
        image_url: events_data[:image_url]
      )
      #@event.save
      # add some error handling for saving
    end

    #return data_to_log
  end

  def getEventData(anchor_image)
    url = anchor_image['href']
    title = anchor_image.text
    summary = ''
    image_file = ''
    image_url = ''
    wiki_url = "https://en.wikipedia.org#{url}"
    begin
      first_event = Nokogiri::HTML(open("https://en.wikipedia.org#{url}"))
      content = first_event.css('div.mw-body-content').css('div.mw-content-ltr')
      title = first_event.css('h1.firstHeading').text
      table_infobox = content.css('table.infobox')
      if table_infobox.length < 1
        image_box = content.css('img').first
        image_url = "https:" + image_box['src']
      else
        image_box = table_infobox.css('a.image')
        image_url = image_box.length < 1 ? '' : "https:" + image_box.first.css('img')[0]['src']
      end
      puts "IMAGE URL"
      puts image_url
      #if image_file.length != 0
      #  image_page = Nokogiri::HTML(open("https://en.wikipedia.org#{image_file}"))
      #  # decode URI and remove _ to utilize as image ID
      #  # image_id = URI.decode(image_file).gsub('_', ' ');
      #  # image_id = image_id.slice(6, image_id.length) # Remove the '/wiki/' prefix
      #  image_path = image_page.xpath("//div[@class='fullImageLink']").first.css('img').first['src']
      #  image_url = "https:#{image_path}"
      #  puts image_url
      #  puts "FOUND IMAGE"
      #  #image_url = image['src']
      #end
      paragraphs = content.xpath(
        '//p[count(preceding-sibling::h2) = 0 and count(preceding-sibling::table) > 0 and count(following-sibling::div) > 0]'
      )
      paragraphs.each do |paragraph|
        summary = summary + paragraph.text
      end
    rescue OpenURI::HTTPError => e
      print "URI: #{url} no longer exists: " + e.to_s
    rescue Exception => e
      print "Unclassified Error: " + e.to_s
    end

    summary_stripped = strip_citations(summary)

    return {
      :wiki_url => wiki_url,
      :title => title == nil || title.length < 1 ? '' : title,
      :summary => summary_stripped,
      :image_url => image_url
    }
  end

  def default_image
    return "data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9InllcyI/PjxzdmcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgdmlld0JveD0iMCAwIDIwMCAyMDAiIHByZXNlcnZlQXNwZWN0UmF0aW89Im5vbmUiPjwhLS0KU291cmNlIFVSTDogaG9sZGVyLmpzLzIwMHgyMDAKQ3JlYXRlZCB3aXRoIEhvbGRlci5qcyAyLjYuMC4KTGVhcm4gbW9yZSBhdCBodHRwOi8vaG9sZGVyanMuY29tCihjKSAyMDEyLTIwMTUgSXZhbiBNYWxvcGluc2t5IC0gaHR0cDovL2ltc2t5LmNvCi0tPjxkZWZzPjxzdHlsZSB0eXBlPSJ0ZXh0L2NzcyI+PCFbQ0RBVEFbI2hvbGRlcl8xNWI1NDFjN2M3NCB0ZXh0IHsgZmlsbDojQUFBQUFBO2ZvbnQtd2VpZ2h0OmJvbGQ7Zm9udC1mYW1pbHk6QXJpYWwsIEhlbHZldGljYSwgT3BlbiBTYW5zLCBzYW5zLXNlcmlmLCBtb25vc3BhY2U7Zm9udC1zaXplOjEwcHQgfSBdXT48L3N0eWxlPjwvZGVmcz48ZyBpZD0iaG9sZGVyXzE1YjU0MWM3Yzc0Ij48cmVjdCB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgZmlsbD0iI0VFRUVFRSIvPjxnPjx0ZXh0IHg9Ijc0LjA1NDY4NzUiIHk9IjEwNC41Ij4yMDB4MjAwPC90ZXh0PjwvZz48L2c+PC9zdmc+"
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
