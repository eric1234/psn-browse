require 'nokogiri'
require 'faraday'
require 'json'
require 'ruby-progressbar'
require 'fuzzy_match'

begin
  require 'dotenv/load'
rescue LoadError
end

require_relative '../lib/game_normalization'
require_relative '../lib/rate_limit'
require_relative '../lib/ext/string'
using Ext::String

TITLES_PAGE = 'https://www.playstation.com/en-us/ps-now/ps-now-games/'
AUTH_URI = 'https://id.twitch.tv/oauth2/token'
GAME_URI = 'https://api.igdb.com/v4/games'
FIELDS = %w[
  name
  storyline
  summary

  age_ratings.category
  age_ratings.content_descriptions.description
  age_ratings.rating

  aggregated_rating
  aggregated_rating_count
  rating
  rating_count

  artworks.image_id
  cover.image_id
  screenshots.image_id

  videos.name
  videos.video_id

  first_release_date

  collection.name
  franchises.name
  similar_games

  genres.name
  keywords.name
  themes.name
  player_perspectives.name

  involved_companies.company.name
  involved_companies.company.logo.image_id
  involved_companies.developer
]

# Hardcoded mapping of titles to IGDB mapping for special cases
TITLES_MAP = {
  # These two get results but they are the wrong ones
  'Bolt' => 4723,
  'The Darkness' => 1347,

  # These all get no results from IGDB but I can manually find them
  'Atari Flashback Classics Vol 1' => 24891,
  'Atelier Escha & LOGY - ALCHEMISTS OF THE DUST SKY' => 7279,
  'Batman: Arkam Asylum Game of the Year' => 27862,
  'BloodRayne: Betryal' => 2606,
  'Burn Zombie Burn: The Diarrhea Bundle' => 16174,
  'Comet Crash Bionic Bundle' => 21246,
  'Counter Spy' => 7612,
  'Cuboid Ultimate Bundle' => 23024,
  'Earth Defense Force: Insect Armaggedon' => 5584,
  'Guacamelee! Bundle Fantástico' => 4838,
  'ICO™ Classics HD' => 21084,
  'LEGO Batman: The Videogame' => 2738,
  'Moto GP 13' => 7450,
  'MotorStorm RC Complete Edition' => 43016,
  'MouseCraft' => 8992,
  'Pure Farming 18' => 58066,
  "Pure Hold'em World Poker Championship" => 17840,
  'Red Faction Guerilla Re-MARS-tered' => 96027,
  "Red Johson's Chronicles" => 21148,
  'Resident Evil Revelations 2 Complete Season' => 7725,
  'Resident Evil: The Darkside Chronicles HD' => 497,
  'Resident Evil: The Umbrella Chronicles HD' => 975,
  'Sam and Max: BT&S – Chariots of the Dogs' => 27838,
  'Sam and Max: BT&S – Ice Station Santa' => 27835,
  'Sam and Max: BT&S – Moai Better Blues' => 27836,
  'Sam and Max: BT&S – Night of the Raving Dead' => 27837,
  'Sam and Max: BT&S – What’s New Beelzebub?' => 27839,
  'Soldner-X: Himmelssturmer' => 21270,
  'Split/Second Velocity' => 2150,
  'Street Fighter 3 Third-Strike Online Edition' => 43666,
  "Strong Bad's Cool Game for Attractive People Season Pass" => 9463,
  'Super Stacker Party' => 52894,
  'The Metronomicon: Slay the Dance Floor' => 19880,
}

# Titles I cannot find on IGDB
# 'Sam and Max Episode 4: Beyoind the Alley of the Dolls'
# 'Hot Shots Golf: World Invitational'
# 'Hot Shots Tennis'
# 'Penny Arcade Adventures: OTRSPOD Ep 1'
# 'Penny Arcade Adventures: OTRSPOD Ep 2'

def auth_headers
  access_token = JSON.parse(File.read('data/access_token.json'))['access_token']
  { 'Client-ID' => ENV['CLIENT_ID'], 'Authorization' => "Bearer #{access_token}" }
end

def with_retry count=1
  attempts = 0
  begin
    yield
  rescue
    attempts += 1
    if attempts < count
      LOGGER.warn "Retrying after: #{$!.message}"
      retry
    else
      LOGGER.error "Failed with: #{$!.message}"
      raise
    end
  end
end

file 'data/titles.html' do |t|
  LOGGER.info "Downloading game titles"

  response = Faraday.get TITLES_PAGE
  raise "Cannot retrieve titles" unless response.status == 200

  File.write t.name, response.body
end

file 'data/titles.txt' => 'data/titles.html' do |t|
  LOGGER.info "Parsing titles"

  doc = Nokogiri::HTML File.open t.source
  File.open t.name, 'w' do |io|
    doc.css('[role="tabpanel"] p').each do |title|
      title = title.content.strip_all

      next if title.empty?
      next if title.alpha_header?

      io.puts title
    end
  end
end

file 'data/access_token.json' do |t|
  response = Faraday.post AUTH_URI,
    client_id: ENV['CLIENT_ID'], client_secret: ENV['CLIENT_SECRET'],
    grant_type: 'client_credentials'
  raise "Failed to obtain access token" unless response.status == 200

  File.write t.name, response.body
end

file 'data/games.json' => ['data/titles.txt', 'data/access_token.json'] do |t|
  LOGGER.info "Downloading game details"

  titles = File.readlines 'data/titles.txt', chomp: true
  progress = ProgressBar.create total: titles.size, format: '%B %c/%C'
  limit = RateLimit.new 0.25
  not_found = []
  found = Set.new
  db = titles.collect do |title|
    with_retry 2 do
      progress.increment

      game_id = if TITLES_MAP[title]
        TITLES_MAP[title]
      else
        # Things like a ® symbol tend to cause search problems. Strip the odd stuff
        normalized_title = title.gsub /[®™]/, ''

        # The search works pretty well but often it gets related titles instead
        # of the desired titles. For examples "Cities: Skyline" gets
        # "Cities: Skylines - Green Cities" (a related DLC). To reduce this gets
        # full page of possibilities and find the title that is lexically the
        # closest.
        query = %Q{search "#{normalized_title}"; fields name; limit 10;}
        limit.next
        response = Faraday.post GAME_URI, query, auth_headers
        raise "Failed to query #{title}" unless response.status == 200

        possibilities = JSON.parse response.body
        matcher = FuzzyMatch.new(possibilities, read: ->(g) { g['name'] })
        closest = matcher.find(title)
        not_found << title and next unless closest
        closest['id']
      end

      fields = FIELDS.join ', '
      query = %Q{where id = #{game_id}; fields #{fields}; limit 1;}
      limit.next
      response = Faraday.post GAME_URI, query, auth_headers
      raise "Failed to query #{title}" unless response.status == 200

      data = JSON.parse(response.body).first
      unless data
        LOGGER.warn "Failed to get #{title} (#{game_id})"
        next
      end

      # Shouldn't really get duplicates. This is an indication the search not
      # going right. May later try to track down the faulty searches. But for
      # now just skipping as search page cannot handle duplicate ids.
      next if found.include? data['id']
      found << data['id']

      # Store name as it was on PS site so we can compare with what we found
      # to make sure they match
      data['ps_name'] = title

      GameNormalization.new(data).clean!
    end
  end.compact

  File.write t.name, JSON.pretty_generate(db)

  File.write 'data/not_found.txt', not_found.join("\n") unless not_found.empty?
end

# A data file similar to the games.json but removing anything not needed for
# the search (such as screenshots) as well as flattening the tree as the
# search engine can't work well with nested data
file 'data/search.json' => 'data/games.json' do |t|
  full_data = JSON.parse(File.read t.source)
  search_data = []
  for game in full_data
    game['studio'] = game.dig('studio', 'name') if game.dig('studio', 'name')
    game['content_descriptions'] = game['age_ratings'].collect { _1['content_descriptions'] }.compact.flatten if game['age_ratings']
    game.delete 'content_descriptions' if game['content_descriptions']&.empty?

    %w[
      aggregated_rating aggregated_rating_count rating rating_count
      screenshots similar_games ps_name videos artwork age_ratings
    ].each { game.delete _1 }

    search_data << game
  end

  File.write t.name, JSON.generate(search_data)
end

task :compare_titles => 'data/games.json' do |t|
  db = JSON.parse File.read t.source
  for game in db
    # If they are exactly the same assume correct. Don't care about casing
    next if game['name'].downcase == game['ps_name'].downcase

    # Output any that might not be correct
    puts "#{game['name']} <=> #{game['ps_name']}"
  end
end

task :game_query => 'data/access_token.json' do
  $stdout << "Query: "
  query = $stdin.gets.chomp

  response = Faraday.post GAME_URI, query, auth_headers
  raise "Failed to query" unless response.status == 200

  puts response.body
end

desc "Download game data"
task :download => ['data/games.json', 'data/search.json']
