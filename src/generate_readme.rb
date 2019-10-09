require 'erb'
require 'json'
require 'date'

sites = Dir.chdir('stats') do
  Dir.glob('*').select { |f| File.directory? f }
end

json_files = sites.map do |site|
  Dir.glob(File.join('stats', site, '*.json'))
end.reject(&:nil?)

items = json_files.map do |files|
  files.map do |json|
    data = JSON.parse(File.read(json), symbolize_names: true)

    {
      json: json,
      requested_url: data.dig(:requestedUrl),
      created_at: DateTime.parse(data.dig(:fetchTime)),
      performance: data.dig(:categories, :performance, :score) * 100,
      accessibility: data.dig(:categories, :accessibility, :score) * 100,
      best_practices: data.dig(:categories, :"best-practices", :score) * 100,
      seo: data.dig(:categories, :seo, :score) * 100,
      pwa: data.dig(:categories, :pwa, :score) * 100
    }
  end
end

results = items.flatten(1).sort! { |a,b|  b[:created_at] <=> a[:created_at] }

# Create template.
template = %q{
  # Lighthouse Site Performance Report

  **Updated at <%= Time.now %> by [CircleCI #<%= ENV['CIRCLE_BUILD_NUM'] %>](<%= ENV['CIRCLE_BUILD_URL'] %>)**

  **This report was automatically generated by [Lighthouse stats](https://github.com/jamesmosier/lighthouse-stats-circleci)*

  | URL | Performance | Accessibility | Best Practices | SEO | PWA | Updated At |
  | --- | --- | --- | --- | --- | --- | --- |
  % results.each do |item|
    | [<%= item.dig(:requested_url) %>](./<%= item.dig(:json) %>) | <%= item.dig(:performance).round %>% | <%= item.dig(:accessibility).round %>% | <%= item.dig(:best_practices).round %>% | <%= item.dig(:seo).round %>% | <%= item.dig(:pwa).round %>% | <%= item.dig(:created_at).strftime("%m/%d/%Y %I:%M%p") %> |
  % end
}.gsub(/^ +/, '')

erb = ERB.new(template, 0, "%<>")

File.open('LIGHTHOUSE_REPORTS.md', 'w') do |f|
  f.write erb.result
end
