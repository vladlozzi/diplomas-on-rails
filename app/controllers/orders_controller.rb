class OrdersController < ApplicationController
  before_action :set_order, only: %i[ show destroy ]

  def show
    xml_doc = REXML::Document.new(@order.xml_file.download.force_encoding('UTF-8'))
    @order_xml_formatted = ""
    xml_doc.write(output: @order_xml_formatted, indent: 2)
  end

  def destroy
    # Спочатку видаляємо всі дипломи, які належать замовленню
    Diploma.where(order_id: @order.id).all.each do |diploma|
      diploma.diploma_file.purge
    end
    Diploma.delete_by(order_id: @order.id)
    # Тепер видаляємо замовлення
    @order.destroy
    respond_to do |format|
      format.html { redirect_to root_url, notice: "Замовлення " + @order.name + " видалене" }
      format.json { head :no_content }
    end
  end

  private
    def set_order
      @order = Order.find(params[:id])
    end
end