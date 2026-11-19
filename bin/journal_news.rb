# frozen_string_literal: true

require 'date'

# Render the same journal records used by the bibliography, including papers
# entered by hand whose publishers did not deposit an ORCID.
def journal_news(records, works, settings, today: Date.today)
  work_by_title = works.values.to_h { |work| [title_key(text(work.fetch('title').first)), work] }
  pending_by_doi = settings.fetch('accepted').to_h { |paper| [doi_key(paper['doi']), paper] }.reject { |doi, _| doi.empty? }
  pending_by_title = settings.fetch('accepted').to_h { |paper| [title_key(paper.fetch('title')), paper] }
  summaries = settings.fetch('news_summaries', {}).transform_keys { |doi| doi_key(doi) }

  records.select { |entry| entry.type == :article }.map do |entry|
    title = entry[:title].to_s
    key = title_key(title)
    doi = doi_key(entry[:doi])
    work = works[doi] || work_by_title[key] || {}
    doi = doi_key(work['DOI']) if doi.empty?
    pending = pending_by_doi[doi] || pending_by_title[key] || {}
    if entry[:note].to_s == 'Accepted'
      date = Array(pending['accepted_on']&.split('-')).map(&:to_i)
      date = [entry[:year].to_i] if date.empty?
      status = 'Accepted'
    else
      date, status = news_publication_date(work, entry[:year].to_i, today)
    end

    stamp = Date.new(*date)
    summary = [pending['summary'], summaries[doi], entry[:annotation]].map { |v| v.to_s.strip }.find { |v| !v.empty? }
    summary ||= abstract_highlight(work['abstract'] || entry[:abstract])
    {
      'title' => title, 'doi' => doi, 'journal' => entry[:journal].to_s,
      'date' => stamp.strftime(date.length > 1 ? '%b %Y' : '%Y'),
      # Unscheduled accepted papers lead their year until dated by the publisher.
      'sort_date' => status == 'Accepted' && date.length == 1 ? "#{date.first}-99" : stamp.iso8601,
      'status' => status, 'summary' => summary
    }.compact
  end.uniq { |row| row['doi'].empty? ? title_key(row['title']) : row['doi'] }
     .sort_by { |row| [row['sort_date'], row['title']] }.reverse
end

def news_publication_date(work, year, today)
  online = work.dig('published-online', 'date-parts', 0)
  issued = work.dig('published', 'date-parts', 0) || [year]
  registered = work.dig('created', 'date-parts', 0)
  if !registered && work.dig('created', 'date-time')
    deposit = Date.iso8601(work['created']['date-time'][0, 10])
    registered = [deposit.year, deposit.month, deposit.day]
  end

  return [online, 'Published online'] if online && Date.new(*online) <= today
  return [issued, 'Published'] if issued.size > 1 && Date.new(*issued) <= today
  return [registered, 'DOI registered'] if registered && Date.new(*registered) <= today
  [issued, Date.new(*issued) <= today ? 'Published' : 'Forthcoming']
end

def abstract_highlight(abstract)
  sentences = text(abstract).sub(/\Aabstract\s*[:.]?\s*/i, '').split(/(?<=[.!?])\s+(?=[A-Z])/)
  concise = sentences.select { |s| s.split.size.between?(6, 40) && s.match?(/[.!?]\z/) }
  concise.find { |s| s.match?(/\b(?:we|this (?:paper|study|work)) (?:propos\w*|introduc\w*|build\w*|creat\w*|design\w*|use\w*|present\w*|develop\w*|investigat\w*|examin\w*|demonstrat\w*|show\w*|find\w*)\b/i) } ||
    concise.find { |s| s.match?(/\b(?:model|method|study|approach|framework|experiment|result)s?\b/i) }
end
