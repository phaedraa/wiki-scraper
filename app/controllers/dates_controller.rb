class DatesController < ApplicationController
  require 'Date'
  require 'nokogiri'
  require 'open-uri'
  require 'URI'
  require 'Event'
  
  def show_date_events
    #date = '2016-3-4'
    day = Date.parse(params[:date])
    #@event_date = day.strftime('%B %d, %Y')
    events = WikiDate.where(:day => day)
    if events.length == 0
      fetch_and_store_date_events(day)
      events = WikiDate.where(:day => day)
    end
    @events_data = Event.find(events).map(&:title)
  end

  def index
    @stored_dates = WikiDate.uniq.pluck(:day)
  end

  def fetch_and_store_date_events(date)
    temp_delete = Event.where(day: date)
    temp_delete.each do |delete_event|
      Event.find(delete_event[:id]).destroy
    end
    #date = '2016-3-2'
    #debugger
    #date = Date.parse(date)
    month_num = date.mon
    month = Date::MONTHNAMES[month_num]
    year = date.year
    day = date.day
    if !Date.valid_date?(year, month_num, day)
      raise TypeError, 'Parsed invalid date: #{year}-#{month_num}-#{day}'
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
      data_to_log.push(getEventData(event.css('a')[0], date))
    end

    day = date.strftime('%s')
    # TODO: create data first, then save

    data_to_log.each do |events_data|
      #puts events_data
      title = events_data[:title]
      @wikidate = WikiDate.new(
        day: date,
        title: title,
      )
      @wikidate.save

      if (Event.where(:title => title)).length < 1
        @event = Event.new(
          title: title,
          wiki_url: events_data[:wiki_url],
          summary: events_data[:summary],
          image_url: events_data[:image_url]
        )
        @event.save
      end
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
        image_box = content.css('img').first || first_event.css('img').first
        image_url = "https:" + image_box['src']
      else
        image_box = table_infobox.css('a.image')
        image_url = image_box.length < 1 ? '' : "https:" + image_box.first.css('img')[0]['src']
      end

      # Case 1 where table exists before element (seems most common)
      paragraphs = content.xpath(
        '//p[count(preceding-sibling::h2) = 0 and count(preceding-sibling::table) > 0 and count(following-sibling::div) > 0]'
      )
      # Case 2 where images exist
      if paragraphs.length < 1
        img_div = content.xpath('.//div[@class="thumb tright" or @class="thumb tmulti tright"]').first
        # There are no images and no table preceding the text, so assume
        # that the first paragraph elements we find contain the desired
        # text. Grab until we exit a series of p's.
        node = img_div == nil ? content.css('p').first : img_div
        while node.name != "p" do
          node = node.next_element
        end
        while node.name == "p" or node.name == "b" do
          summary += node.text
          node = node.next_element
        end
      else
        paragraphs.each do |paragraph|
          summary += paragraph.text
        end
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

  def strip_citations(summary)
    if summary.length == 0
      return ''
    end

    idx_to_strip = []
    pair = []
    (0..(summary.length - 1)).each do |idx|
      if summary[idx] == '[' || summary[idx] == ']'
        if pair.length == 2
          # Validate pairs create a [] set. There should be no nested
          # brackets. Ignore stripping of pairs which don't fit citation
          # criteria.
          if summary[pair[0]] != '[' && summary[idx] != ']'
            pair = []
          else
            idx_to_strip.push(pair)
            pair = [idx]
          end
        else
          pair.push(idx)
        end
      end 
    end

    if pair.length == 2
      idx_to_strip.push(pair)
    end

    j = 0
    summary_stripped = ''
    idx_to_strip.each do |pair|
      if j < pair[0]
        summary_stripped += summary[j..pair[0]-1]
      end
      # If values between the brackets are not integers, keep them
      bracket_val = summary[pair[0] + 1, pair[1] - pair[0]]
      if /\A\d+\z/.match(bracket_val)
        summary_stripped += summary[pair[0], pair[1]]
      end
      j = pair[1]+1
    end

    if j < summary.length
      summary_stripped += summary[j..-1]
    end

    return summary_stripped
  end

  # not sure if Ruby String class uses a String builder... Trying
  # to avoid making new string copies for length of the string times.
  # This is also O(n*m), where m is the sum of the length of all bracket
  # pairs and their contents.
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
