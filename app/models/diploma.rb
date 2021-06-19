class Diploma < ApplicationRecord
  validates :seria, presence: { message: "Серія диплома не може бути порожньою" }
  validates :number, presence: { message: "Номер диплома не може бути порожнім" }
  validates :name, presence: { message: "Назва диплома не може бути порожньою" }
  validates :seria, format: { with: /(B|C|E|M)\d{2}/,
                              message: "Серія диплома повинна містити одну з латинських букв B, C, E, M і 2 цифри"
  }
  validates :number, format: { with: /\d{6}/,
                               message: "Номер диплома повинен містити 6 цифр"
  }
  validates :number, uniqueness: { scope: :seria }
  belongs_to :order
  has_one_attached :diploma_file
end
