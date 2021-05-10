module AllHelpers
  # Given a IGDB image id and one of the standard images size names will
  # return the URL of the image. Image sizes can be found at:
  #
  # https://api-docs.igdb.com/#images
  def image_url id, size
    "https://images.igdb.com/igdb/image/upload/t_#{size}/#{id}.jpg"
  end

  def stars score
    return unless score
    case
      when score <= 0 then   '     '
      when score < 20 then   '+    '
      when score < 40 then   '*+   '
      when score < 60 then   '**+  '
      when score < 80 then   '***+ '
      when score < 100 then  '****+'
      when score >= 100 then '*****'
    end.chars.collect do |char|
      case char
        when ' ' then ''
        when '+' then '-half'
        when '*' then '-fill'
      end
    end.collect { |suffix| icon "star#{suffix}" }.join
  end

  def icon name
    File.read Pathname.new(__dir__).join("../source/icons/#{name}.svg")
  end
end
