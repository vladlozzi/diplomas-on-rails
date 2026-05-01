module MainHelper
  # Виносимо мапінг у константу
  INSTITUTION_REPLACEMENTS = {
    /\AМіністерство / => "Міністерством ",
    /\AНаціональне агентство / => "Національним агентством ",
    /\AЦентральне агентство / => "Центральним агентством ",
    /\AДержавна служба / => "Державною службою ",
    /\AДепартамент / => "Департаментом ",
    /\AУправління / => "Управлінням "
  }.freeze # Заморожуємо, щоб уникнути випадкових змін у коді

  def institution_to_instrumental(name)
    return "" if name.blank?

    result = name.strip
    result[0] = result[0].upcase if result[0]

    INSTITUTION_REPLACEMENTS.each do |pattern, instrumental|
      if result.match?(pattern)
        return result.sub(pattern, instrumental)
      end
    end

    result
  end
end