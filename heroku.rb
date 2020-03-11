#!/usr/bin/env ruby

# <bitbar.title>Heroku Info</bitbar.title>
# <bitbar.version>v0.0.1</bitbar.version>
# <bitbar.author>Eric Boehs</bitbar.author>
# <bitbar.author.github>ericboehs</bitbar.author.github>
# <bitbar.desc>This plugin displays Heroku info for a given app. You must be logged in via heroku-cli.</bitbar.desc>
# <bitbar.dependencies>ruby</bitbar.dependencies>
# <bitbar.dependencies>heroku-toolbelt</bitbar.dependencies>

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'dotenv'
  gem 'pry'
end

require 'dotenv'; Dotenv.load "#{File.dirname($0)}/.env"
require 'json'

data = JSON.parse DATA.read
heroku_error_glossary = data['heroku_error_glossary']

HEROKU_CMD='/usr/local/bin/heroku'

# Configuration options
app = ENV.fetch 'BITBAR_HEROKU_APP_NAME'
team = ENV.fetch 'BITBAR_HEROKU_TEAM'
hours = 24      # how many hours should the error window contain?

total = 0
copy = ''
status = `#{HEROKU_CMD} apps:errors -a #{app} --json --hours #{hours}`
status = JSON.parse(status)

status.keys.each do |level|
  status[level].keys.each do |type|
    if status[level][type].is_a? Numeric
      # router errors
      total += status[level][type]
      copy += "#{type}: #{status[level][type]} (#{heroku_error_glossary[type]})\n"
    else
      status[level][type].keys.each do |error|
        # dyno errors
        total += status[level][type][error]
        copy += "#{error}: #{status[level][type][error]} (#{heroku_error_glossary[error]})\n"
      end
    end
  end
end

addons = JSON.parse `#{HEROKU_CMD} addons -a #{app} --json`
addons_output = String.new
addons.each do |addon|
  attachment_name = addon.fetch('attachments', []).fetch(0, {})['name']
  secondary = "(#{attachment_name})" if %w[heroku-redis heroku-postgresql].include? addon['addon_service']['name']
  addons_output += "#{addon['addon_service']['human_name']} #{secondary}|href=#{addon['web_url']}\n"
end

releases = `#{HEROKU_CMD} releases -a #{app} --json`
releases = JSON.parse releases
deploys = String.new
require 'time'
releases.each do |release|
  time = Time.parse(release['created_at']).localtime.strftime('%b %d @ %-I:%M:%S %p')

  deploys += "v#{release['version']} - #{time}\n" +
  "--#{release['description']} | href='https://dashboard.heroku.com/apps/#{app}/activity'\n" +
  "--#{release['user']['email']}\n"
end

apps = JSON.parse `#{HEROKU_CMD} apps -t #{team} --json`
apps_output = String.new
apps.each do |app_result|
  apps_output += "#{app_result['name']}\n"
  apps_output += "--Open App|href='#{app_result['web_url']}'\n"
  apps_output += "--Resources|href='https://dashboard.heroku.com/apps/#{app_result['name']}/resources'\n"
  apps_output += "--Metrics|href='https://dashboard.heroku.com/apps/#{app_result['name']}/metrics'\n"
  apps_output += "--Activity|href='https://dashboard.heroku.com/apps/#{app_result['name']}/activity'\n"
end

puts "HK: #{total}"
puts '---'
puts "#{total} #{app} errors:"
puts "In the last #{hours} hours"
puts copy

puts '---'
puts "#{app} addons:"
puts addons_output

puts '---'
puts "Current Apps for #{team}:"
puts apps_output

puts '---'
puts "Last 15 deploys for #{app}:"
puts deploys

puts '---'
puts 'Refresh... | refresh=true'

__END__
{
  "heroku_error_glossary": {
    "H10": "App crashed",
    "H11": "Backlog too deep",
    "H12": "Request timeout",
    "H13": "Connection closed without response",
    "H14": "No web dynos running",
    "H15": "Idle connection",
    "H16": "Redirect to herokuapp.com",
    "H17": "Poorly formatted HTTP response",
    "H18": "Server Request Interrupted",
    "H19": "Backend connection timeout",
    "H20": "App boot timeout",
    "H21": "Backend connection refused",
    "H22": "Connection limit reached",
    "H23": "Endpoint misconfigured",
    "H24": "Forced close",
    "H25": "HTTP Restriction",
    "H26": "Request Error",
    "H27": "Client Request Interrupted",
    "H28": "Client Connection Idle",
    "H80": "Maintenance mode",
    "H81": "Blank app",
    "H82": "Free dyno quota exhausted",
    "H99": "Platform error",
    "R10": "Boot timeout",
    "R12": "Exit timeout",
    "R13": "Attach error",
    "R14": "Memory quota exceeded",
    "R15": "Memory quota vastly exceeded",
    "R16": "Detached",
    "R17": "Checksum error",
    "R99": "Platform error",
    "L10": "Drain buffer overflow",
    "L11": "Tail buffer overflow",
    "L12": "Local buffer overflow",
    "L13": "Local delivery error",
    "L14": "Certificate validation error",
    "L15": "Tail buffer temporarily unavailable"
  }
}
