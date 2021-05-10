class Rank
  def initialize critic_rating, user_rating
    @critic = critic_rating
    @user = user_rating
  end

  # Returns the value based on the weighted value of both the critic and
  # user rating. Is weighted towards what the critic thinks.
  def value
    values = [@critic, @critic, @user].collect(&:weighted_value).compact
    if values.size > 0
      values.sum.to_f / values.size
    else
      0
    end
  end

  Rating = Struct.new :value, :votes do
    def weighted_value
      return unless value && votes

      value * weight(1, votes-1)
    end

    private

    # The second vote offsets the score by 1%. Each vote after that will
    # be 90% of the weight of the last person.
    def weight percent, votes_remaining
      return 1 if votes_remaining.zero?

      direction = good? ? 1 : -1
      factor = (1 + direction * percent.to_f / 100)
      factor * weight(percent * 0.9, votes_remaining - 1)
    rescue SystemStackError
      # We had so many votes we blew the stack. At this point each vote isn't
      # adding much so just stop the recusion
      1
    end

    # If the score is 90 we generally would consider that good and additional
    # votes would only confirm that making perhaps a 90 with many votes higher
    # than a 92 with few votes.
    #
    # But if the score is 10 we assume the opposite. Many votes confirm it is
    # bad. Perhaps a 10 with many votes is more troublesome than a game with
    # a score of 8 but only one vote.
    #
    # But at what point do we consider a score a vote for bad vs good? In
    # gradeschool below a 70 was failure. Some schools do below 60 as a failure.
    # But many online ratings are based on 5 stars. 3 stars would be a sixty
    # but I don't really consider 3 starts a failure. 2 stars starts to seem
    # more like a failure. Split the difference so anything 50 or below is
    # considered bad.
    def good?
      value > 50
    end
  end
end
