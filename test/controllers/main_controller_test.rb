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
    assert_select 'form input[type=submit][value="Надіслати файл на сервер"]', count: 1
    assert_select 'table.orders', count: 0
    assert_select 'a[href="/demo"]', "Сторінка з демо-файлами замовлень (буде відкрито в новій вкладці)"
  end

  test "get demo page" do
    get demo_url
    assert_response :success
    assert_select 'h3',
                  'Приклади замовлень у форматі XML для демонстрації ' +
                  'роботи сервісу "Друк документів про вищу освіту":'
    assert_select 'ul li a[href="/demo/demo1.xml"]', "Завантажити"
    assert_select 'ul li a[href="/demo/demo2.xml"]', "Завантажити"
    assert_select 'ul li a[href="/demo/demo3.xml"]', "Завантажити"
    assert_select 'ul li a[href="/demo/demo4.xml"]', "Завантажити"
    assert_select 'p', "Після завантаження демо-файлів рекомендовано закрити цю вкладку."
    assert_select 'h5'
  end

  test "must have attached file" do
    get root_url
    assert_response :success
    assert_select 'form input[type=file]', count: 1
    file = fixture_file_upload(Rails.root.join('test/fixtures/files', 'Another.xml'), 'text/xml')
    assert_difference "Order.where(user: cookies['my_diplomas_cart']).count", 1 do
      post root_path, params: { xml_file: file, user: cookies['my_diplomas_cart'] }
    end
    another = Order.where(user: cookies['my_diplomas_cart'], name: 'Another.xml').first
    assert another.xml_file.attached?
    assert_redirected_to root_url
    follow_redirect!
    assert_select 'table.orders thead tr th', "Назва замовлення"
    assert_select 'table.orders thead tr th', "Дії з замовленням"
    assert_select 'table.orders tbody tr td', "Another.xml", count: 1
    assert_select 'table.orders tbody tr td a', "Деталі", count: 1
    assert_select 'table.orders tbody tr td form input[type=submit][value="Видалити"]', count: 1
    assert_select 'table.orders tbody tr td form input[type=submit]', count: 2
    get order_url(another)
    assert_response :success
    assert_select 'a', "Назад"
    assert_select 'h1', "Деталі замовлення на дипломи " + another.name
    assert_select 'p'
    order_xml_formatted = ""
    REXML::Document.new(another.xml_file.download.force_encoding('UTF-8'))
                   .write(output: order_xml_formatted, indent: 2)
    assert_select 'pre', order_xml_formatted
  end

  test "should upload files, generate diplomas and delete orders from table" do
    Diploma.delete_all # До цього тесту видаляємо записи про дипломи, які є в тестовій базі,
                        # оскільки контролер згенерує і збереже їх заново,
                        # і буде конфлікт унікальності в полі Diploma.name
    get root_url
    assert_response :success
    assert_select 'table.orders', count: 0
    file = fixture_file_upload(Rails.root.join('test/fixtures/files', 't1.xml'), 'text/xml')
    assert_difference "Order.where(user: cookies['my_diplomas_cart']).count", 1 do
      post root_path, params: { xml_file: file, user: cookies['my_diplomas_cart'] }
    end
    file = fixture_file_upload(Rails.root.join('test/fixtures/files', 't2.xml'), 'text/xml')
    assert_difference "Order.where(user: cookies['my_diplomas_cart']).count", 1 do
      post root_path, params: { xml_file: file, user: cookies['my_diplomas_cart'] }
    end
    assert_redirected_to root_url
    follow_redirect!
    assert_select 'table.orders'
    assert_select 'table.orders tbody tr td', "t1.xml", count: 1
    assert_select 'table.orders tbody tr td', "t2.xml", count: 1
    assert_select 'table.orders tbody tr td a', "Деталі", count: 2
    assert_select 'table.orders tbody tr td form input[type=submit][value="Видалити"]', count: 2
    assert_select 'table.orders tbody tr td form input[type=submit]', count: 3
    get check_path
    assert_response :success
    assert_select 'a[href="/"]', "Назад"
    assert_select 'p',"Інформація, яка буде надрукована в дипломах (на основі даних в ЄДЕБО, замовлення t1.xml)"
    assert_select 'p',"Інформація, яка буде надрукована в дипломах (на основі даних в ЄДЕБО, замовлення t2.xml)"
    assert_select 'table.check', count: 2
    get root_path
    assert_response :success
    get diplomas_path
    assert_response :success
    assert_equal Diploma.count, 2
    assert_equal Diploma.first.diploma_file.filename.to_s, "master(blue).foreigner.M21.000001.docx"
    assert_equal Diploma.second.diploma_file.filename.to_s, "depre.specialist(blue).C21.000976.duplicate.docx"
    assert_not_nil Diploma.first.diploma_file.download
    assert_not_nil Diploma.second.diploma_file.download
    assert_not_empty Diploma.first.diploma_file.download
    assert_not_empty Diploma.second.diploma_file.download
    delete root_path
    assert_redirected_to root_url
    follow_redirect!
    assert_select 'h1', "Підготовка до друку документів про вищу освіту"
    assert_select 'p', count: 2
    assert_select 'p.notice', "Усі замовлення видалено"
    assert_select 'form'
    assert_select 'form label', "Виберіть файл замовлення .xml, одержаний з ЄДЕБО:", count: 1
    assert_select 'form input[type=file]', count: 1
    assert_select 'form input[type=submit][value="Надіслати файл на сервер"]', count: 1
    assert_select 'table.orders', count: 0
  end

end