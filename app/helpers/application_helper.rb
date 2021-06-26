module ApplicationHelper
  # def redirect_later_tag
  #   return nil unless flash.key?(:redirect_later)

  #   url = flash[:redirect_later][:url]
  #   delay = flash[:redirect_later][:delay]
  #   flash.now[:notice] = flash[:redirect_later][:msg]
  #   flash.delete(:redirect_later)

  #   tag("meta", "http-equiv" => "refresh", content: "#{delay}; URL=#{url}")
  # end
end