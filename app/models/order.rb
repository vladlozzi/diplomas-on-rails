class Order < ApplicationRecord
  validates :name,
            presence: { message: "Виберіть файл замовлення" },
            uniqueness: { message: "Такий файл вже є на сервері" }
  has_one_attached :xml_file
  # validates :xml_file, attached: true
end