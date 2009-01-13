namespace :wxr do

task :export => :environment do
  require 'uuidtools'
  if ENV['MEPHISTO_SITE']
    site = Site.find_by_host(ENV['MEPHISTO_SITE'])
  else
    site = Site.find(:first)
  end
  
  xml = Builder::XmlMarkup.new(:target => STDOUT, :indent => 2)
  
  xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
  xml.rss 'version' => "2.0",
          'xmlns:content' => "http://purl.org/rss/1.0/modules/content/",
          'xmlns:wfw' => "http://wellformedweb.org/CommentAPI/",
          'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
          'xmlns:wp' => "http://wordpress.org/export/1.0/" do
    xml.channel do
      xml.title site.title
      xml.link "http://#{site.host}"
      xml.language "en-us"
      xml.ttl "40"
      xml.description site.subtitle
  
      site.articles.each do |a|
        a.published_at ||= a.created_at
          xml.item do
            xml.title a.title
            xml.content(:encoded) { |x| x << a.body_html }
            xml.pubDate a.published_at.rfc2822
            xml.guid "urn:uuid:#{UUID.random_create}", "isPermaLink" => "false"
            author = a.user.name rescue a.author
            xml.author author
            xml.dc :creator, author
            a.tags.each do |tag|
              xml.category tag
            end
            xml.wp :post_id, a.id
            xml.wp :post_date, a.published_at.strftime("%Y-%m-%d %H:%M:%S")
            xml.wp :comment_status, 'closed'
            xml.wp :ping_status, 'closed'
            xml.wp :post_name, a.permalink
            xml.wp :status, 'publish'
            xml.wp :post_parent, '0'
            xml.wp :post_type, 'post'
            for comment in a.comments
              xml.wp(:comment) do
                xml.wp :comment_id, comment.id
                xml.wp :comment_author, comment.author
                xml.wp :comment_author_email, comment.author_email
                xml.wp :comment_author_url, comment.author_url
                xml.wp :comment_author_IP, comment.author_ip
                xml.wp :comment_date, comment.published_at.strftime("%Y-%m-%d %H:%M:%S")
                xml.wp(:comment_content) { |x| x << comment.body_html }
                xml.wp :comment_approved, '1'
                xml.wp :comment_parent, '0'
              end
            end
         end
      end
    end
  end
end

end