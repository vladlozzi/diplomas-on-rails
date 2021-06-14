require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @order = orders(:one)
  end

  test "should get show" do
    assert @order.xml_file.attached?
    assert @order.xml_file.attachment
    assert_not_empty @order.xml_file.download
    get order_path(@order)
    assert_response :success
    assert_select 'h1', "Деталі замовлення на дипломи " + @order.name
    assert_select 'p', @order.xml_file.download.force_encoding('UTF-8')
  end

  test "should get destroy" do
    assert_difference 'Order.count', -1 do
      delete order_path(@order)
    end
    assert_redirected_to root_url
    follow_redirect!
    assert_select 'p.notice', "Замовлення " + @order.name + " видалене"
    assert_select 'table.orders tbody td a', "Деталі", count: 1
    assert_select 'table.orders tbody td a', "Видалити", count: 1
    assert_select 'table.orders tbody tr td form input[type=submit]', count: 0
  end

end