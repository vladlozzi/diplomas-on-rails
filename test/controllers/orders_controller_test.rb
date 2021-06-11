require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @order = orders(:one)
  end

  test "should get show" do
    assert @order.xml_file.attached?
    assert @order.xml_file.attachment
    # Далі цей тест не проходить:
    # ActiveStorage::FileNotFoundError: ActiveStorage::FileNotFoundError
    # Ймовірна причина - неправильно зроблені .yml.
    # Прошу підказки експертів, де недобре, бо нагуглити так і не зміг.
    assert @order.xml_file.download
    p @order.xml_file.download.force_encoding('UTF-8')
    get order_path(@order)
    assert_response :success
    #assert_select 'h1', "Деталі замовлення на дипломи " + @order.name
    #assert_select 'p', @order.xml_file.download.force_encoding('UTF-8')
  end

  test "should get destroy" do
    assert_difference 'Order.count', -1 do
      delete order_path(@order)
    end
    assert_redirected_to root_url
    follow_redirect!
    assert_select 'table.orders tbody td a', "Деталі", count: 1
    assert_select 'table.orders tbody td a', "Видалити", count: 1
  end
end