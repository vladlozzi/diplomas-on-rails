class MainController < ApplicationController
  def index
    @orders = Order.order(:name)
  end

  def create
    if params[:xml_file].present?
      order = Order.new(name: params[:xml_file].original_filename, xml_file: params[:xml_file])
      order.save
    end
    redirect_to root_url
  end
end