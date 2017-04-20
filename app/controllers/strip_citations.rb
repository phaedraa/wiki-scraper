  require 'Date'
  require 'nokogiri'
  require 'open-uri'
  require 'URI'

def show_date_events
    day = Date.parse(params[:date])
    @event_date = day.strftime('%B %d, %Y')
    events = WikiDate.where(:day => day)
    if events.length == 0
      fetch_and_store_date_events(day)
      events = WikiDate.where(:day => day)
    end
    titles = events.map{|row| row.event}
    @events_data = Event.where(title: titles)
  end

  def index
    @stored_dates = WikiDate.uniq.pluck(:day).sort{|row| row.day}
  end

  def fetch_and_store_date_events(date)
    #temp_delete = Event.where(day: date)
    #temp_delete.each do |delete_event|
    #  Event.find(delete_event[:id]).destroy
    #end
    month_num = date.mon
    month = Date::MONTHNAMES[month_num]
    year = date.year
    day = date.day
    if !Date.valid_date?(year, month_num, day)
      raise TypeError, 'Parsed invalid date: #{year}-#{month_num}-#{day}'
    end

    date_url = "#{month}_#{year}" + "#" + "#{year}_#{month}_#{day}"
    date_div_id = "#{year}_#{month}_#{day < 10 ? '0' : ''}#{day}"
    
    data_to_log = get_data_to_log(date_url, date_div_id)
    log_new_events_data(data_to_log, date)
    #day = date.strftime('%s')
  end

  def log_new_events_data(data_to_log, date)
    data_to_log.each do |events_data|
      title = events_data[:title]
      @wikidate = WikiDate.new(
        day: date,
        event: title,
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
    end
  end

  def get_data_to_log(date_url, date_div_id)
    doc = Nokogiri::HTML(open("https://en.wikipedia.org/wiki/Portal:Current_events/#{date_url}"))
    table = doc.xpath("//div[@id='#{date_div_id}']").first
    # If table div for this date doesn't exist, assume no wiki data for
    # this date exists. As such, don't store empty data in table.
    if !table
      return []
    end
    
    table = table.next_element
    content = table.css('td.description')
    events = content.css('li')

    data_to_log = []
    events.each do |event|
      article_anchor = event.css('a')[0]
      if article_anchor != nil
        # article_anchor_url is of format 'wiki/SOME_NAME'
        wiki_url = "https://en.wikipedia.org#{article_anchor['href']}"
        dom = get_dom(wiki_url)
        if dom != nil
          data_to_log.push(get_event_data(dom, wiki_url))
        end
      end
    end

    return data_to_log
  end

  def get_dom(wiki_url)
    begin
      dom = Nokogiri::HTML(open(wiki_url))
    rescue OpenURI::HTTPError => e
      print "URI: #{wiki_url} no longer exists: " + e.to_s
      return nil
    rescue Exception => e
      print "Unclassified Error: " + e.to_s
      return nil
    end
  
    return dom
  end

  def run_tests
    test_urls = [
      "https://en.wikipedia.org/wiki/Legally_Blonde_(musical)",
      "https://en.wikipedia.org/wiki/Ward_Parkway",
      "https://en.wikipedia.org/wiki/Liberation_Tigers_of_Tamil_Eelam",
      "https://en.wikipedia.org/wiki/United_States",
      "https://en.wikipedia.org/wiki/United_States_Department_of_Veterans_Affairs",
      "https://en.wikipedia.org/wiki/Human_rights_in_Tajikistan"
    ]
    test_urls.each do |url|
      dom = get_dom(url)
      data = get_event_data(url)
      puts "**************"
      puts data
      puts "**************"
    end
  end

  def get_event_data(dom, wiki_url)
    test_urls = [
      "https://en.wikipedia.org/wiki/Legally_Blonde_(musical)",
      "https://en.wikipedia.org/wiki/Ward_Parkway",
      "https://en.wikipedia.org/wiki/Liberation_Tigers_of_Tamil_Eelam",
      "https://en.wikipedia.org/wiki/United_States",
      "https://en.wikipedia.org/wiki/United_States_Department_of_Veterans_Affairs",
      "https://en.wikipedia.org/wiki/Human_rights_in_Tajikistan",
      "https://en.wikipedia.org/wiki/Turkey",
      "https://en.wikipedia.org/wiki/United_States",
      "https://en.wikipedia.org/wiki/Space_burial",
      # No images
      "https://en.wikipedia.org/wiki/Prison_riot",
      "https://en.wikipedia.org/wiki/Abortion_in_Mexico",
      "https://en.wikipedia.org/wiki/Avraham_Hirschson",
      "https://en.wikipedia.org/wiki/Governor_of_Punjab,_Pakistan",
      "https://en.wikipedia.org/wiki/Human_rights_activists"
    ]
    wiki_url = "https://en.wikipedia.org/wiki/Space_burial"
    dom = get_dom(wiki_url)
    content_body = dom.css('div.mw-body-content').css('div.mw-content-ltr')
    image_url = get_image_url(content_body)
    summary = get_summary(content_body)
    title = dom.css('h1.firstHeading').text
    puts "*********************************"
    if title == nil || title.length < 1
      raise Error, 'Unable to find title in Wiki article: #{wiki_url}'
    end
  
    return {
      :wiki_url => wiki_url,
      :title => title,
      :summary => summary,
      :image_url => image_url
    }
  end

  # This function accomplishes two primary feats:
  # 1) Balancing the brackets such that we don't have lone brackets
  # 2) If a balanced bracket pair exists, and it's content is a
  #    digit between 1-4 characters, then it will be excluded
  def strip_citations(summary)
      if summary.length < 1
        raise Error, 'No summary text found'
      end
      
      puts "SUMMARY: "
      puts summary
      left_brackets = [];
      summary_len = summary.length
      idx = 0
      while idx < summary_len
        if summary[idx] == '['
          left_brackets.push(idx);
        elsif summary[idx] == ']'
          left_idx = left_brackets.pop
          if left_idx != nil
            # If values between brackets are ints or in format of word+int (e.g. 'note 9'),
            # remove content and surrounding brackets.
            # Only check for integers <= 9,999 as
            # it's unlikely we'll ever have a citation which exits such a limit
            if idx - left_idx == 1 ||
              /[A-Za-z]*\s*[0-9]{1,4}$/.match(summary[left_idx + 1, idx - left_idx - 1])
              while left_idx <= idx
                summary[left_idx] = "*"
                left_idx += 1
              end
            end
          else
            summary[idx] = "*"
          end
        end
        idx += 1
      end
  
      # Set all loner left brackets to be "*"
      left_bracket_to_remove = left_brackets.pop
      while left_bracket_to_remove != nil
        summary[left_bracket_to_remove] = "*"
        left_bracket_to_remove = left_brackets.pop
      end
  
      # Replace all "*"'s with empty spaces to filter out desired content.
      return summary.gsub("*", "")
  end
  
  def get_image_url(content_body)
    #table_infobox = content_body.css('table.infobox')
    #images = content_body.xpath(
    #  '//img[
    #    count(preceding-sibling::table) = 1 and
    #    count(following-sibling::h1) > 0
    #  ]'
    #)
    image_box = content_body.css('div.thumbinner').css('img')
    if image_box == nil || image_box.length < 1
      image_box = content_body.css('table.vertical-navbox').css('img')
    end
    if image_box == nil || image_box.length < 1
      plainlinks_table = content_body.css('table.plainlinks')
      next_element = plainlinks_table.next_element rescue nil
      if next_element == nil
        image_box = content_body.css('table.infobox').css('img')
      else
        image_box = next_element.css('img')
      end
    end
    
    if image_box != nil && image_box.length > 0
      return 'https:' + image_box.first['src']
    else
      return ''
    end
      
    #return image_box.length < 1 ? '' : 'https:' + image_box.first.css('img')[0]['src']
  end
  
  def get_summary(content_body)
    # Case 1 where table exists before element (seems most common)
    paragraphs = content_body.xpath(
      '//p[
        count(preceding-sibling::h2) = 0 and
        count(following-sibling::h2) > 0 and
        count(following-sibling::div) > 0
      ]'
    )
    puts paragraphs
    puts "*********************************"
    summary = ""
    # Case 2 where images exist
    if paragraphs.length < 1
      img_div = content_body.xpath('.//div[@class="thumb tright" or @class="thumb tmulti tright"]').first
      # There are no images and no table preceding the text, so assume
      # that the first paragraph elements we find contain the desired
      # text. Grab until we exit a series of p's.
      node = img_div == nil ? content_body.css('p').first : img_div
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
  
    return strip_citations(summary)
  end

puts get_event_data('', '')
