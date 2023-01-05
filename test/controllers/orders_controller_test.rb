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
    assert_select 'a', "Назад"
    assert_select 'h1', "Деталі замовлення на дипломи " + @order.name
    assert_select 'p'
    order_xml_formatted = ""
    REXML::Document.new(@order.xml_file.download.force_encoding('UTF-8'))
                   .write(output: order_xml_formatted, indent: 2)
    assert_select 'pre', order_xml_formatted
  end

  test "should upload file and delete order" do
    Order.delete_all
    file = fixture_file_upload(Rails.root.join('test/fixtures/files', 't1.xml'), 'text/xml')
    assert_difference "Order.where(user: cookies['my_diplomas_cart']).count", 1 do
      post root_path, params: { xml_file: file, user: cookies['my_diplomas_cart'] }
    end
    assert_redirected_to root_url
    follow_redirect!
    assert_select 'table.orders thead tr th', "Назва замовлення"
    assert_select 'table.orders thead tr th', "Дії"
    assert_select 'table.orders tbody tr td a', "Деталі", count: 1
    assert_select 'table.orders tbody tr td form input[type=submit][value="Видалити"]', count: 1
    assert_select 'table.orders tbody tr td a', "Інформація для перевірки", count: 1
    assert_select 'table.orders tbody tr td form input[type=submit]', count: 2
    assert_select 'table.orders tfoot tr th',
                  "Примітка. Zip-файл з дипломами буде надіслано в браузер відповідно до його налаштувань.",
                  count: 1
    order = Order.where(user: cookies['my_diplomas_cart'], name: 't1.xml').first
    assert_difference "Order.where(user: cookies['my_diplomas_cart']).count", -1 do
      delete order_path(order)
    end
    assert_redirected_to root_url
    follow_redirect!
    assert_select 'p.notice', "Замовлення " + order.name + " видалене"
    assert_select 'table.orders', count: 0
  end

end