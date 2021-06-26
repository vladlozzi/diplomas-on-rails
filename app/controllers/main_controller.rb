class MainController < ApplicationController
  require "sablon"

  DOC_TEMPLATES = {
    "Диплом молодшого бакалавра" => "junbachelor",
    "Диплом бакалавра" => "bachelor",
    "Диплом магістра" => "master",
    "Диплом молодшого спеціаліста" => "junspec",
    "Диплом спеціаліста" => "depre.specialist",
  }
  MONTHS_UKR_ENG = {
    "1" => " січня / January ", "2" => " лютого / February ", "3" => " березня / March ",
    "4" => " квітня / April ", "5" => " травня / May ", "6" => " червня / June ",
    "7" => " липня / July ", "8" => " серпня / August ", "9" => " вересня / September ",
    "10" => " жовтня / October ", "11" => " листопада / November ", "12" => " грудня / December "
  }

  def initialize
    super
    @orders = Order.order(:name)
  end

  def index
  end

  def create
    if params[:xml_file].present?
      order = Order.new(name: params[:xml_file].original_filename, xml_file: params[:xml_file])
      order.save
    end
    redirect_to root_url
  end

  def delete_orders
    Diploma.delete_all # Спочатку видаляємо всі дипломи, бо вони належать замовленням
    Order.delete_all
    redirect_to root_url, notice: "Усі замовлення видалено"
  end

  def get_diplomas
    @orders.each do |order|
      Diploma.delete_by(order_id: order.id) # Спершу видаляємо наявні дипломи з цього замовлення
      diplomas_hash = Hash.from_xml(order.xml_file.download.force_encoding('UTF-8'))
      diplomas_hash['Documents'].each do |documents|
        if documents[1].kind_of?(Array)
          documents[1].each do |document|
            create_diploma document, order.id
          end
        else
          create_diploma documents[1], order.id
        end
      end
    end
    # Упаковуємо файли дипломів в архів zip
    dt_now = Time.now.to_s.gsub(/[^0-9]/,'')
    zip_name = "diplomas_for_print-" +
      dt_now[0..3] + "-" + dt_now[4..5] + "-" + dt_now[6..7] + "T" + dt_now[8..13] + ".zip"
    zip_file_path = Rails.root.join('public', zip_name)
    File.file?(zip_file_path) ? File.delete(zip_file_path) : ""
    Zip::File.open(zip_file_path, Zip::File::CREATE) do |zipfile|
      Diploma.all.each do |diploma|
        filename_to_zip = diploma.diploma_file.filename.to_s
        File.open(File.join(Rails.root.join('tmp', filename_to_zip)), 'wb') do |file_to_zip|
          diploma.diploma_file.download { |item| file_to_zip.write(item) }
          file_to_zip.close
          zipfile.add(filename_to_zip, file_to_zip)
        end
      end
    end
    # Видаляємо файли, які були завантажені зі сховища і збережені в zip-архіві
    Diploma.all.each do |diploma|
      zipped_file_path = Rails.root.join('tmp', diploma.diploma_file.filename.to_s)
      File.delete(zipped_file_path)
    end
    # send_file(zip_file_path, type: 'application/zip', filename: zip_name)
    send_data(File.read(zip_file_path), type: 'application/zip', filename: zip_name)
    File.delete(zip_file_path) and return
    #   redirect_later send_diplomas_zip_path, msg: "Надсилання архіву з дипломами почнеться через %d сек."
    redirect_to root_url, notice: "Архів з дипломами " + zip_name + " надіслано в каталог завантажень браузера"
  end

  def send_diplomas_zip
    files = Dir.glob(Rails.root.join("public", "diplomas_for_print-*"))
    zip_file_path = files[0]
    zip_name = File.basename(zip_file_path)
    send_data(File.read(zip_file_path), type: 'application/zip', filename: zip_name)
  end

  private

    def create_diploma(document, order_id)
      absent_ukr = "інформація відсутня в первинному документі"
      absent_eng = "information is missing in original document"
      diploma = Diploma.new
      doc_award = document["AdditionalAwardInfo"].present? ? "(red)" : "(blue)" # Цей диплом з відзнакою?
      template_name = DOC_TEMPLATES[document["DocumentTypeName"]] + doc_award
      diploma.name = document["DocumentTypeName"] +
        (document["AdditionalAwardInfo"].present? ? " (" + document["AdditionalAwardInfo"] + ") " : " ") +
        document["DocumentSeries"] + " " + document["DocumentNumber"]
      diploma_file = template_name + "." + document["DocumentSeries"] + "." + document["DocumentNumber"] + ".docx"
      template_file = template_name + ".dotx"
      doc = Sablon.template(File.expand_path(Rails.root.join('public', 'templates', template_file)))
      context = {
        diploma: OpenStruct.new(
          "seria" => document["DocumentSeries"],
          "number" => document["DocumentNumber"],
          "firstNameUkr" => document["FirstName"],
          "firstNameEng" => document["FirstNameEn"],
          "lastNameUkr" => document["LastName"],
          "lastNameEng" => document["LastNameEn"],
          "sexIssuedUkr" => (document['SexName'] == "Жіноча") ? "закінчила" : "закінчив",
          "issueYear" => DateTime.parse(document['IssueDate']).year,
          "sexObtainedUkr" => (document['SexName'] == "Жіноча") ? "здобула" : "здобув",
          "studyProgramNameUkr" => document['StudyProgramName'].presence || absent_ukr,
          "studyProgramNameEng" => document['StudyProgramNameEn'].presence || absent_eng,
          "accreditationInstitutionNameUkr" => document['AccreditationInstitutionName'].presence || absent_ukr,
          "accreditationInstitutionNameEng" => document['AccreditationInstitutionNameEn'].presence || absent_eng,
          "industryNameUkr" => document['IndustryName'].presence || absent_ukr,
          "industryNameEng" => document['IndustryNameEn'].presence || absent_eng,
          "specialityNameUkr" => document['SpecialityName'].presence || absent_ukr,
          "specialityNameEng" => document['SpecialityNameEn'].presence || absent_eng,
          "additionalAwardInfoUkr" => document['AdditionalAwardInfo'].presence || absent_ukr,
          "additionalAwardInfoEng" => document['AdditionalAwardInfoEn'].presence || absent_eng,
          "graduateDate" =>
            DateTime.parse(document['GraduateDate']).day.to_s +
              MONTHS_UKR_ENG[DateTime.parse(document['GraduateDate']).month.to_s] +
              DateTime.parse(document['GraduateDate']).year.to_s
        )
      }
      doc.render_to_file File.expand_path(Rails.root.join('tmp', diploma_file)), context
      diploma.seria = document["DocumentSeries"]
      diploma.number = document["DocumentNumber"]
      diploma.order_id = order_id
      diploma.save
      diploma.diploma_file.attach(
        io: File.open(Rails.root.join('tmp', diploma_file)), filename: diploma_file,
        content_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      )
      File.delete(Rails.root.join('tmp', diploma_file))
    end
end