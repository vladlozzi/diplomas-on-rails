class MainController < ApplicationController
  def index
    @orders = Order.all
  end

  def create
    if params[:xml_file].present?
      order = Order.new(name: params[:xml_file].original_filename, xml_file: params[:xml_file])
      unless order.save; end
    end
    redirect_to root_path
  end
end