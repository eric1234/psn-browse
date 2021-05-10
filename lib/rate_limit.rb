# A naive rate limiting class.
class RateLimit

  # `delay` is the min time between operations
  def initialize delay
    @delay = delay
    @last_at = Time.at 0
  end

  # Called every time we are ready for the next operation. Will sleep if the
  # `delay` time has not passed since the last call to `next`
  def next
    sleep wait_for if wait?
    @last_at = Time.now
  end

  private

  def elapsed_time = Time.now.to_f - @last_at.to_f
  def wait_for = 0.25 - elapsed_time
  def wait? = wait_for > 0
end
