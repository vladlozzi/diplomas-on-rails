require "test_helper"

class DiplomaTest < ActiveSupport::TestCase
  fixtures :diplomas, :orders

  test "all diploma attributes must not be empty" do
    diploma = Diploma.new
    assert diploma.invalid?
    assert diploma.errors[:seria].size, 2
    assert diploma.errors[:seria][0], "Серія диплома не може бути порожньою"
    assert diploma.errors[:seria][1], "Серія диплома повинна містити одну з латинських букв B, C, E, M і 2 цифри"
    assert diploma.errors[:number].size, 2
    assert diploma.errors[:number][0], "Номер диплома не може бути порожнім"
    assert diploma.errors[:number][1], "Номер диплома повинен містити 6 цифр"
    assert diploma.errors[:name].size, 1
    assert diploma.errors[:name][0], "Назва диплома не може бути порожньою"
    diploma = Diploma.new(order_id: orders(:one).id, seria: diplomas(:one).seria)
    assert diploma.invalid?
    diploma = Diploma.new(order_id: orders(:one).id, number: diplomas(:one).number)
    assert diploma.invalid?
    diploma = Diploma.new(order_id: orders(:one).id, name: "5")
    assert diploma.invalid?
    diploma = Diploma.new(order_id: orders(:one).id, seria: diplomas(:one).seria, number: diplomas(:two).number)
    assert diploma.invalid?
    diploma = Diploma.new(order_id: orders(:one).id, seria: diplomas(:one).seria, name: "5")
    assert diploma.invalid?
    diploma = Diploma.new(order_id: orders(:one).id, number: diplomas(:one).number, name: "5")
    assert diploma.invalid?
  end

  test "diploma must belong to order" do
    diploma = Diploma.new(seria: diplomas(:one).seria,
                          number: "012345",
                          name: "5")
    assert diploma.invalid?
    diploma.order_id = orders(:one).id
    assert diploma.valid?
  end

  test "diploma seria and number must be unique" do
    diploma_try_unique = Diploma.new(seria: diplomas(:one).seria,
                                    number: diplomas(:one).number,
                                    order_id: orders(:one).id,
                                    name: "5"
    )
    assert diploma_try_unique.invalid?
    diploma_try_unique = Diploma.new(seria: diplomas(:one).seria,
                                    number: diplomas(:one).number,
                                    order_id: orders(:two).id,
                                    name: "6"
    )
    assert diploma_try_unique.invalid?
    diploma_try_unique = Diploma.new(seria: diplomas(:one).seria,
                                    number: "000001",
                                    order_id: orders(:two).id,
                                    name: "7"
    )
    assert diploma_try_unique.valid?
  end
end