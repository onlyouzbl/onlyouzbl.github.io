# frozen_string_literal: true

# Run from the repository root: bundle exec ruby bin/sync_publications.rb
require 'bibtex'
require 'digest'
require 'json'
require 'net/http'
require 'nokogiri'
require 'set'
require 'tempfile'
require 'uri'
require 'yaml'
require_relative 'journal_news'

MANUAL_BIB = '_bibliography/papers.bib'
GENERATED_BIB = '_bibliography/crossref.bib'

def fetch_message(uri, allow_missing: false)
  attempts = 0
  loop do
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 30
    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = 'onlyouzbl-homepage/1.0 (https://onlyouzbl.github.io/)'
    response = http.request(request)
    return nil if allow_missing && response.code == '404'
    return JSON.parse(response.body).fetch('message') if response.is_a?(Net::HTTPSuccess)

    attempts += 1
    if attempts < 3 && (response.code == '429' || response.code.start_with?('5'))
      sleep [[response['retry-after'].to_i, 2**attempts].max, 45].min
      next
    end
    raise "Crossref returned HTTP #{response.code} for #{uri.path}"
  end
end

def doi_key(value)
  value.to_s.strip.sub(%r{\Ahttps?://(?:dx\.)?doi\.org/}i, '').downcase
end

def title_key(value)
  value.to_s.unicode_normalize(:nfkc).downcase.gsub(/[^[:alnum:]]/, '')
end

def text(value)
  # Crossref can supply inline JATS markup. Store readable text in BibTeX.
  plain = Nokogiri::HTML.fragment(value.to_s).text
  plain.tr('{}', '()').gsub('\\', '').gsub(/[[:space:]]+/, ' ').strip
end

def works_for(orcid)
  works = {}
  cursor = '*'
  loop do
    uri = URI('https://api.crossref.org/works')
    uri.query = URI.encode_www_form(filter: "orcid:#{orcid},type:journal-article", rows: 100, cursor: cursor)
    page = fetch_message(uri)
    items = page.fetch('items')
    before = works.size
    items.each do |item|
      # Keep the ORCID tied to its own author object in the publisher record.
      next unless Array(item['author']).any? { |author| author['ORCID'].to_s.split('/').last == orcid }
      works[doi_key(item.fetch('DOI'))] = item
    end
    break if items.size < 100
    raise 'Crossref pagination made no progress' if before == works.size
    cursor = page.fetch('next-cursor')
  end
  works
end

def bib_entry(key, fields)
  fields = fields.reject { |_, value| value.to_s.empty? }
  BibTeX::Entry.new(bibtex_type: :article, bibtex_key: key, **fields, selected: 'true', bibtex_show: 'true')
end

def published_entry(doi, item)
  authors = item.fetch('author').map do |a|
    a['family'] ? [a['family'], a['given']].compact.map { |name| text(name) }.join(', ') : text(a.fetch('name'))
  end
  venue = text(item.fetch('container-title').fetch(0))
  year = item.fetch('published').fetch('date-parts').first.fetch(0)
  bib_entry("journal-#{Digest::SHA256.hexdigest(doi)[0, 16]}",
            title: text(item.fetch('title').fetch(0)), author: authors.join(' and '), journal: venue,
            abbr: text(Array(item['short-container-title']).first || venue),
            year: year.to_s, volume: text(item['volume']), number: text(item['issue']),
            pages: text(item['page']), doi: doi, url: "https://doi.org/#{doi}")
end

def refresh
  settings = YAML.safe_load_file('_data/publication_sync.yml')
  curated = BibTeX.open(MANUAL_BIB).entries.values
  curated_dois = curated.map { |entry| doi_key(entry[:doi]) }.reject(&:empty?).to_set
  curated_titles = curated.map { |entry| title_key(entry[:title]) }.to_set
  works = {}
  settings.fetch('orcids').uniq.each { |orcid| works.merge!(works_for(orcid)) }
  accepted = settings.fetch('accepted')
  # An explicitly entered DOI also covers a publisher deposit lacking the author's ORCID.
  accepted.each do |paper|
    doi = doi_key(paper['doi'])
    next if doi.empty? || works.key?(doi) || curated_dois.include?(doi)
    raise "Invalid DOI: #{doi}" unless doi.match?(%r{\A10\.\d{4,9}/[^\s<>"{}]+\z})
    uri = URI("https://api.crossref.org/works/#{URI.encode_www_form_component(doi)}")
    item = fetch_message(uri, allow_missing: true)
    next unless item
    raise "Expected a journal article for #{doi}" unless item.fetch('type') == 'journal-article'
    works[doi] = item
  end

  entries = []
  known_titles = curated_titles.dup
  works.each do |doi, item|
    title = title_key(text(item.fetch('title').fetch(0)))
    known_titles.add(title)
    next if curated_dois.include?(doi) || curated_titles.include?(title)
    # Deposit date orders early-access records even if the issue lists only a year.
    entries << [item.fetch('created').fetch('date-time'), published_entry(doi, item)]
  end
  early = []
  seen_dois = works.keys.to_set.merge(curated_dois)
  accepted.each do |paper|
    title = text(paper.fetch('title'))
    doi = doi_key(paper['doi'])
    next if (!doi.empty? && seen_dois.include?(doi)) || known_titles.include?(title_key(title))
    known_titles.add(title_key(title))
    seen_dois.add(doi) unless doi.empty?
    key = Digest::SHA256.hexdigest(title_key(title))[0, 16]
    early << bib_entry("accepted-#{key}", title: title, journal: text(paper.fetch('journal')),
                       author: paper.fetch('authors').map { |name| text(name) }.join(' and '),
                       year: Integer(paper.fetch('year')).to_s, note: 'Accepted', doi: doi)
  end
  records = early + entries.sort_by { |date, entry| [date, entry.key] }.reverse.map(&:last)
  news = journal_news(curated + records, works, settings)
  write_if_changed(GENERATED_BIB, records.map(&:to_s).join("\n"))
  write_if_changed('_data/journal_news.json', JSON.pretty_generate(news) + "\n")
  puts "#{works.size} indexed journal articles, #{entries.size} beyond the curated bibliography, #{early.size} awaiting publication."
end

def write_if_changed(path, contents)
  return if File.exist?(path) && File.read(path) == contents

  Tempfile.create(['.publication-sync-', '.tmp'], File.dirname(path)) do |file|
    file.write(contents)
    file.close
    File.rename(file.path, path)
  end
end

refresh if $PROGRAM_NAME == __FILE__
