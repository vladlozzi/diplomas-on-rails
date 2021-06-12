require "test_helper"

class OrderTest < ActiveSupport::TestCase
  fixtures :orders
  test "order attributes must not be empty" do
    order = Order.new
    assert order.invalid?
    assert order.errors[:name], "Виберіть файл замовлення"
  end

  test "order name must be unique" do
    order = Order.new(name: "t1.xml")
    assert order.invalid?
    assert order.errors[:name], "Такий файл вже є на сервері"
  end

  test "order name is valid" do
    order = Order.new(name: "Another.xml")
    assert order.valid?
    assert_difference'Order.count', 1 do
      order.save
    end
  end

end
