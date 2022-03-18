require 'ostruct'
require 'json'

ignore 'frontend/*'

activate :external_pipeline,
  name: :parcel,
  command: "node_modules/.bin/parcel #{build? ? 'build' : 'watch'} --dist-dir tmp/ source/frontend/search.js source/frontend/bootstrap.js",
  source: "tmp/"

games = @app.data.games.collect do |game|
  # Gymnastics so the OpenStruct is recursive
  JSON.parse JSON.generate(game), object_class: OpenStruct
end

# To easily find similar games
lookup = games.each_with_object({}) { _2[_1.id] = _1 }

for game in games
  game.similar_games = (game.similar_games || []).collect { lookup[_1] }.compact
  proxy "#{game.id}.html", "game.html", locals: { game: game }, ignore: true
end
