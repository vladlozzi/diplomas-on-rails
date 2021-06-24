require "test_helper"

class MainControllerTest < ActionDispatch::IntegrationTest
  test "get main page" do
    get root_url
    assert_response :success
    assert_select 'h1', "Підготовка до друку документів про вищу освіту"
    assert_select 'p', count: 1
    assert_select 'form'
    assert_select 'form label', "Виберіть файл замовлення .xml, одержаний з ЄДЕБО:", count: 1
    assert_select 'form input[type=file]', count: 1
    assert_select 'form input[type=submit]', count: 3
    assert_select 'table.orders', count: 1
    assert_select 'table.orders thead tr th', "Назва замовлення"
    assert_select 'table.orders thead tr th', "Дії"
    assert_select 'table.orders tbody tr td', orders(:one).name, count: 1
    assert_select 'table.orders tbody tr td', orders(:two).name, count: 1
    assert_select 'table.orders tbody tr td a', "Деталі", count: 2
    assert_select 'table.orders tbody tr td a', "Видалити", count: 2
    assert_select 'table.orders tbody tr td form input[type=submit]', count: 2
  end

  test "must have attached file" do
    get root_url
    assert_response :success
    assert_select 'form input[type=file]', count: 1
    file = fixture_file_upload(Rails.root.join('test/fixtures/files', 'Another.xml'), 'text/xml')
    assert_difference 'Order.count', 1 do
      post root_path, params: { xml_file: file }
    end
    another = Order.where(name: 'Another.xml').first
    assert another.xml_file.attached?
    assert_redirected_to root_url
    follow_redirect!
    assert_select 'table.orders tbody tr td', "Another.xml", count: 1
    assert_select 'table.orders tbody tr td a', "Деталі", count: 3
    assert_select 'table.orders tbody tr td a', "Видалити", count: 3
    get order_url(another)
    assert_response :success
    assert_select 'a', "Назад"
    assert_select 'h1', "Деталі замовлення на дипломи " + another.name
    assert_select 'p', another.xml_file.download.force_encoding('UTF-8')
  end

  test "should delete orders table" do
    get root_url
    assert_response :success
    assert_select 'table.orders'
    delete root_path
    assert_redirected_to root_url
    follow_redirect!
    assert_select 'h1', "Підготовка до друку документів про вищу освіту"
    assert_select 'p', count: 2
    assert_select 'p.notice', "Усі замовлення видалено"
    assert_select 'form'
    assert_select 'form label', "Виберіть файл замовлення .xml, одержаний з ЄДЕБО:", count: 1
    assert_select 'form input[type=file]', count: 1
    assert_select 'form input[type=submit]', count: 1
    assert_select 'table.orders', count: 0
  end

  test "should generate diplomas" do
    get root_url
    assert_response :success
    get diplomas_path
    assert_redirected_to root_url
    follow_redirect!
  end

end