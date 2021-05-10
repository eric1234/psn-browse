require_relative 'rank'
require_relative 'ext/hash'
require_relative 'ext/integer'

using Ext::Hash
using Ext::Integer

class GameNormalization
  def initialize data
    @data = data
  end

  def clean!
    studio_only
    image_ids_only
    facet_values
    release_fmt_and_move
    assign_rank
    fallback_rating
    map_age_ratings

    @data
  end

  private

  def studio_only
    studio = @data['involved_companies']&.find { _1['developer'] }
    @data['studio'] = studio['company'] if studio
    @data.delete 'involved_companies'
  end

  def image_ids_only
    @data.dig_and_replace 'cover', 'image_id'
    @data['studio']&.dig_and_replace 'logo', 'image_id'
    @data.dig_and_replace_all 'artworks', 'image_id'
    @data.dig_and_replace_all 'screenshots', 'image_id'
  end

  def release_fmt_and_move
    @data['release_date'] = @data.delete('first_release_date')&.to_time

    # We sort by release date and search engine doesn't deal well with a blank
    # value. Use epoch as placeholder to put them as oldest
    @data['release_date'] ||= '1970-01-01'
  end

  def facet_values
    @data.dig_and_replace 'collection', 'name'
    @data.dig_and_replace_all 'franchises', 'name'
    @data.dig_and_replace_all 'genres', 'name'
    @data.dig_and_replace_all 'keywords', 'name'
    @data.dig_and_replace_all 'themes', 'name'
    @data.dig_and_replace_all 'player_perspectives', 'name'
  end

  # We sort by rating but the search engine doesn't deal well with null
  # values so using 0 for a rating. In the output we will assume a rating
  # of 0 meant there wasn't one to begin with
  def fallback_rating
    @data['aggregated_rating'] ||= 0
    @data['rating'] ||= 0
  end

  RATINGS = %w[Three Seven Twelve Sixteen Eighteen RP EC E E10 T M AO]
  private_constant :RATINGS

  def map_age_ratings
    @data['age_ratings']&.each do |rating|
      rating['category'] = case rating['category']
        when 1 then 'ESRB'
        when 2 then 'PEGI'
      end

      rating.dig_and_replace_all 'content_descriptions', 'description'

      rating['rating'] = RATINGS[rating['rating']+1]
    end
  end

  def assign_rank
    @data['rank'] = Rank.new(
      Rank::Rating.new(@data['aggregate_rating'], @data['aggregate_rating_count']),
      Rank::Rating.new(@data['rating'], @data['rating_count']),
    ).value
  end
end
