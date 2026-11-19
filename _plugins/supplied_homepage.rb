# frozen_string_literal: true

require 'base64'
require 'nokogiri'

# Preserve the supplied HTML verbatim until a publication section has new data.
module SuppliedHomepage
  def self.publications(section, selector)
    section.css(selector).map do |node|
      [node.text.gsub(/[[:space:]]+/, ''), node['href'].to_s.downcase]
    end
  end

  def self.write(site)
    path = site.in_dest_dir('index.html')
    original = File.binread(site.in_source_dir('_includes', 'supplied-homepage.html'))
    page = Nokogiri::HTML(original, nil, 'UTF-8')
    built = Nokogiri::HTML(File.binread(path), nil, 'UTF-8')
    changed = false

    { '#news + div' => 'li, li a',
      '.papers' => 'article, h3 a, .resources a',
      '#full-list' => 'li > :first-child' }.each do |selector, items|
      before = page.at_css(selector)
      after = built.at_css(selector)
      raise "Missing homepage section #{selector}" unless before && after
      previous = publications(before, items)
      current = publications(after, items)
      # Records sharing a date can be returned in either order by the source.
      if selector == '#news + div'
        previous.sort!
        current.sort!
      end
      next if previous == current

      if selector == '.papers'
        after.css('.paper-figure a').each do |link|
          img = link.at_css('img')
          filename = site.in_dest_dir(img['src'].delete_prefix(site.config['baseurl'].to_s).sub(%r{\A/}, ''))
          type = File.extname(filename).downcase.delete_prefix('.').sub(/\Ajpg\z/, 'jpeg')
          img['src'] = "data:image/#{type};base64,#{Base64.strict_encode64(File.binread(filename))}"
          link['href'] = '#figure-viewer'
          link.add_class('zoom-figure')
        end
      elsif selector == '#full-list'
        after.at_css('summary').content = "View all publications (#{after.css('li').size})"
        after.css('h2.bibliography').each { |heading| heading.name = 'h3' }
        after.css('ol.bibliography').each { |list| list.name = 'ul' }
      end
      before.replace(after)
      changed = true
    end
    File.binwrite(path, changed ? page.to_html : original)
  end
end

Jekyll::Hooks.register(:site, :post_write) { |site| SuppliedHomepage.write(site) }
