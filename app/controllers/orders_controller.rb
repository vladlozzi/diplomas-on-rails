class OrdersController < ApplicationController
  before_action :set_order, only: %i[ show destroy ]

  def show
  end

  def destroy
    @order.destroy
    respond_to do |format|
      format.html { redirect_to root_url, notice: "Замовлення успішно видалене." }
      format.json { head :no_content }
    end
  end

  private
    def set_order
      @order = Order.find(params[:id])
    end
end
