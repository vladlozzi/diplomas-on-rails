class MainController < ApplicationController
  require "sablon"

  def initialize
    super
    @orders = Order.order(:name)
    @doc_templates = Hash.new("")
    @doc_templates["Диплом молодшого бакалавра"] = "junbachelor"
    @doc_templates["Диплом бакалавра"] = "bachelor"
    @doc_templates["Диплом магістра"] = "master"
    @doc_templates["Диплом молодшого спеціаліста"] = "junspec"
    @doc_templates["Диплом спеціаліста"] = "depre.specialist"
    @months = Hash.new("")
    @months[ "1"] = " січня / January "
    @months[ "2"] = " лютого / February "
    @months[ "3"] = " березня / March "
    @months[ "4"] = " квітня / April "
    @months[ "5"] = " травня / May "
    @months[ "6"] = " червня / June "
    @months[ "7"] = " липня / July "
    @months[ "8"] = " серпня / August "
    @months[ "9"] = " вересня / September "
    @months["10"] = " жовтня / October "
    @months["11"] = " листопада / November "
    @months["12"] = " грудня / December "
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
    redirect_to root_url, notice: "Усі документи, які є в замовленнях, згенеровано"
  end

  private

    def create_diploma(document, order_id)
      absent_ukr = "інформація відсутня в первинному документі"
      absent_eng = "information is missing in original document"
      diploma = Diploma.new
      doc_award = document["AdditionalAwardInfo"].present? ? "(red)" : "(blue)" # Цей диплом з відзнакою?
      template_name = @doc_templates[document["DocumentTypeName"]] + doc_award
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
          "studyProgramNameUkr" =>
            document['StudyProgramName'].present? ? document['StudyProgramName'] : absent_ukr,
          "studyProgramNameEng" =>
            document['StudyProgramNameEn'].present? ? document['StudyProgramNameEn'] : absent_eng,
          "accreditationInstitutionNameUkr" =>
            document['AccreditationInstitutionName'].present? ? document['AccreditationInstitutionName'] : absent_ukr,
          "accreditationInstitutionNameEng" =>
            document['AccreditationInstitutionNameEn'].present? ? document['AccreditationInstitutionNameEn'] : absent_eng,
          "industryNameUkr" =>
            document['IndustryName'].present? ? document['IndustryName'] : absent_ukr,
          "industryNameEng" =>
            document['IndustryNameEn'].present? ? document['IndustryNameEn'] : absent_eng,
          "specialityNameUkr" =>
            document['SpecialityName'].present? ? document['SpecialityName'] : absent_ukr,
          "specialityNameEng" =>
            document['SpecialityNameEn'].present? ? document['SpecialityNameEn'] : absent_eng,
          "additionalAwardInfoUkr" =>
            document['AdditionalAwardInfo'].present? ? document['AdditionalAwardInfo'] : absent_ukr,
          "additionalAwardInfoEng" =>
            document['AdditionalAwardInfoEn'].present? ? document['AdditionalAwardInfoEn'] : absent_eng,
          "graduateDate" =>
            DateTime.parse(document['GraduateDate']).day.to_s +
            @months[DateTime.parse(document['GraduateDate']).month.to_s] +
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
      # File.delete(Rails.root.join('tmp', diploma_file))
      diploma.diploma_file.filename
    end
end