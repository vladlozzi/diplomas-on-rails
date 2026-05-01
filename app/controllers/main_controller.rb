class MainController < ApplicationController
  before_action :set_cookies
  include MainHelper

  require "fileutils"
  require "tmpdir"
  require "zip"
  require 'find'
  require 'pathname'

  DOC_TEMPLATES = {
    "Диплом молодшого бакалавра" => "junbachelor",
    "Диплом бакалавра" => "bachelor",
    "Військові. Диплом бакалавра" => "bachelor",
    "Диплом магістра" => "master",
    "Військові. Диплом магістра" => "master",
    "Диплом доктора філософії" => "phd",
    "Диплом молодшого спеціаліста" => "junspec", # останній вступ - 2019р.,
                                                 # останній випуск за нормативного строку навчання 3 роки - 2022р.
    "Диплом спеціаліста" => "depre.specialist",
    "Військові. Диплом спеціаліста" => "depre.specialist", # застарілий, зараз видають лише дублікати
                                                # (оригінали видають лише тим, хто вступив до 2016р. включно
                                                # і кому з якихось причин перенесли випуск)
  }
  MONTHS_UKR_ENG = {
    "1" => " січня / January ", "2" => " лютого / February ", "3" => " березня / March ",
    "4" => " квітня / April ", "5" => " травня / May ", "6" => " червня / June ",
    "7" => " липня / July ", "8" => " серпня / August ", "9" => " вересня / September ",
    "10" => " жовтня / October ", "11" => " листопада / November ", "12" => " грудня / December "
  }
  MONTHS_UKR = MONTHS_UKR_ENG.map{ |m_number, m_name| [m_number, m_name.split('/').first] }.to_h
  MONTHS_ENG = MONTHS_UKR_ENG.map{ |m_number, m_name| [m_number, m_name.split('/').last] }.to_h

  def index
  end

  def demo
  end

  def create
    if cookies[:my_diplomas_cart].present? && params[:xml_file].present?
      order = Order.new(name: params[:xml_file].original_filename,
                        xml_file: params[:xml_file],
                        partner_uk: params[:partner_uk],
                        partner_en: params[:partner_en],
                        user: cookies[:my_diplomas_cart]
      )
      order.save
    end
    redirect_to root_url
  end

  def delete_orders
    if cookies[:my_diplomas_cart].present?
      @orders.each do |order|
        # Спочатку видаляємо всі дипломи, бо вони належать замовленням
        Diploma.where(order_id: order.id).all.each do |diploma|
          diploma.diploma_file.purge
        end
        Diploma.delete_by(order_id: order.id)
      end
      # Тепер видаляємо замовлення
      @orders.each do |order|
        order.xml_file.purge
        Order.delete_by(id: order.id)
      end
      cookies.delete :my_diplomas_cart
      redirect_to root_url, notice: "Усі замовлення видалено"
    end
  end

  def get_diplomas
    errors = 0
    @orders.each do |order|
      partner = { name_uk: order.partner_uk, name_en: order.partner_en }
      Diploma.delete_by(order_id: order.id) # Спершу видаляємо наявні дипломи з цього замовлення
      diplomas_hash = Hash.from_xml(order.xml_file.download.force_encoding('UTF-8'))
      if diplomas_hash['Documents'].present?
        diplomas_hash['Documents'].each do |documents|
          if documents[1].kind_of?(Array)
            documents[1].each do |document|
              create_diploma document, order.id, partner
            end
          else
            create_diploma documents[1], order.id, partner
          end
        end
      else
        errors += 1
        flash[:alert] = "#{flash[:alert]}Помилка в структурі XML, замовлення #{order.name}<br />"
      end
    end
    if errors == 0
      # Упаковуємо файли дипломів в архів zip
      dt_now = Time.now.to_s.gsub(/[^0-9]/,'')
      zip_name = "diplomas_to_print-#{dt_now[0..3]}-#{dt_now[4..5]}-#{dt_now[6..7]}T#{dt_now[8..13]}.zip"
      zip_file_path = Rails.root.join('public', zip_name)
      File.file?(zip_file_path) ? File.delete(zip_file_path) : ""
      total_diplomas_count, red_diplomas_count, blue_diplomas_count = [0, 0, 0]
      # Синтаксис для RubyZip 3.0
      Zip::File.open(zip_file_path, create: true) do |zipfile|
        @orders.each do |order|
          Diploma.where(order_id: order.id).each do |diploma|
            filename_to_zip = diploma.diploma_file.filename.to_s
            total_diplomas_count += 1
            red_diplomas_count += 1 if filename_to_zip.include?("(red)")
            blue_diplomas_count += 1 if filename_to_zip.include?("(blue)")
            File.open(File.join(Rails.root.join('tmp', filename_to_zip)), 'wb') do |file_to_zip|
              diploma.diploma_file.download { |item| file_to_zip.write(item) }
              file_to_zip.close
              zipfile.add(filename_to_zip, file_to_zip)
            end
          end
        end
      end
      # Видаляємо файли, які були завантажені зі сховища і збережені в zip-архіві
      @orders.each do |order|
        Diploma.where(order_id: order.id).each do |diploma|
          zipped_file_path = Rails.root.join('tmp', diploma.diploma_file.filename.to_s)
          File.delete(zipped_file_path)
        end
      end
      zip_name = (
        (red_diplomas_count + blue_diplomas_count).zero? ?
          "(#{total_diplomas_count}total_" :
          "(#{total_diplomas_count}total-#{red_diplomas_count}red-#{blue_diplomas_count}blue)_"
      ) + zip_name
      send_data(File.read(zip_file_path), type: 'application/zip', filename: zip_name)
      File.delete(zip_file_path) and return
    else
      redirect_to root_url
    end
  end

  def check
  end

  private

    def create_diploma(document, order_id, partner)
      diploma = Diploma.new
      missing_ukr = (document['IsDuplicate'] == "False" ? @absent_ukr : @missing_orig_ukr)
      missing_eng = (document['IsDuplicate'] == "False" ? @absent_eng : @missing_orig_eng)
      if document["DocumentTypeName"] == "Диплом доктора філософії"
        doc_award = ""
      else
        doc_award = document["AdditionalAwardInfo"].present? ? "(red)" : "(blue)" # Цей диплом з відзнакою?
      end
      foreigner = document['BeginningUniversityYear'].present? ? ".foreigner" : "" # Іноземець?
      template_name = DOC_TEMPLATES[document["DocumentTypeName"]] + doc_award + foreigner

      diploma.name = document["DocumentTypeName"] +
        (document["AdditionalAwardInfo"].present? ? " (" + document["AdditionalAwardInfo"] + ") " : " ") +
        document["DocumentSeries"] + " " + document["DocumentNumber"]
      diploma_file = template_name + "." + document["DocumentSeries"] + "." + document["DocumentNumber"] +
        (document['IsDuplicate'] == "False" ? "" : ".duplicate") + ".docx"
      template_filename = template_name + ".dotx"
      template_file_fullpath = Rails.root.join('public', 'templates', template_filename)
      if File.file?(template_file_fullpath)
        context = {
          "seria" => document["DocumentSeries"],
          "number" => document["DocumentNumber"],
          "firstNameUkr" => document["FirstName"].presence || "",
          "firstNameEng" => document["FirstNameEn"].presence || "",
          "lastNameUkr" => document["LastName"].presence || "",
          "lastNameEng" => document["LastNameEn"].presence || "",
          "sexEnrolledUkr" => document['SexName'] == "Жіноча" ? "вступила" : "вступив",
          "beginningUniversityYearUkr" => document['BeginningUniversityYear'].presence || "\"#{missing_ukr}\"",
          "beginningUniversityYearEng" => document['BeginningUniversityYear'].presence || "\"#{missing_eng}\"",
          "beginningUniversityNameUkr" => document['BeginningUniversityName'].presence || "\"#{missing_ukr}\"",
          "beginningUniversityNameEng" => document['BeginningUniversityNameEn'].presence || "\"#{missing_eng}\"",
          "sexIssuedUkr" => document['SexName'] == "Жіноча" ? "закінчила" : "закінчив",
          "sexPreparedUkr" => document['SexName'] == "Жіноча" ? "виконала" : "виконав",
          "issueYear" => document['IssueDate'].present? ? DateTime.parse(document['IssueDate']).year.to_s : "",
          "issueUniversityNameUkr" => document['UniversityPrintName'].presence || "\"#{missing_ukr}\"",
          "issueUniversityNameEng" => document['UniversityPrintNameEn'].presence || "\"#{missing_eng}\"",
          "sexObtainedUkr" => document['SexName'] == "Жіноча" ? "здобула" : "здобув",
          "dualDiplomasUkr" => partner[:name_uk].present? ? "подвійних дипломів" : "",
          "dualDiplomasEng" => partner[:name_en].present? ? "Dual Degree" : "",
          "studyProgramNameUkr" => document['StudyProgramName'].presence || missing_ukr,
          "studyProgramNameEng" => document['StudyProgramNameEn'].presence || missing_eng,
          "partnerNameUkr" => partner[:name_uk].present? ? "(у співпраці з #{partner[:name_uk]})" : "",
          "partnerNameEng" => partner[:name_en].present? ? "(in collaboration with #{partner[:name_en]})" : "",
          "accreditationInstitutionNameUkr" => document['AccreditationInstitutionName'].present? ?
                                                 institution_to_instrumental(document['AccreditationInstitutionName']) : missing_ukr,
          "accreditationInstitutionNameEng" => document['AccreditationInstitutionNameEn'].presence || missing_eng,
          "industryNameUkr" => document['IndustryName'].presence || missing_ukr,
          "industryNameEng" => document['IndustryNameEn'].presence || missing_eng,
          "specialityNameUkr" => document['SpecialityName'].presence || missing_ukr,
          "specialityNameEng" => document['SpecialityNameEn'].presence || missing_eng,
          "additionalAwardInfoUkr" => document['AdditionalAwardInfo'].presence || missing_ukr,
          "additionalAwardInfoEng" => document['AdditionalAwardInfoEn'].presence || missing_eng,
          "scientificDegreeDateUkr" => document['ScientificDegreeDate'].present? ?
            "#{DateTime.parse(document['ScientificDegreeDate']).day}#{MONTHS_UKR[DateTime.parse(document['ScientificDegreeDate']).month.to_s]}#{DateTime.parse(document['ScientificDegreeDate']).year}р." : "",
          "scientificDegreeDateEng" => document['ScientificDegreeDate'].present? ?
            "#{DateTime.parse(document['ScientificDegreeDate']).day}#{MONTHS_ENG[DateTime.parse(document['ScientificDegreeDate']).month.to_s]}#{DateTime.parse(document['ScientificDegreeDate']).year}" : "",
            "graduateDate" => "#{DateTime.parse(document['GraduateDate']).day}#{MONTHS_UKR_ENG[DateTime.parse(document['GraduateDate']).month.to_s]}#{DateTime.parse(document['GraduateDate']).year}"
        }

        doc_fullpath = File.expand_path(Rails.root.join('tmp', diploma_file))
        template_file = File.expand_path(template_file_fullpath)

        # Розпаковуємо шаблон .dotx як zip-файл у тимчасовий каталог

        temp_dir_path = Rails.root.join('tmp', 'dotx_unpack_').to_s
        Dir.mkdir(temp_dir_path) unless Dir.exist?(temp_dir_path)
        # puts "Temp dir: #{temp_dir_path}"

        Zip::File.open(template_file) do |zip|
          zip.each do |entry|
            relative_name = entry.name.sub(/\A\/*/, '')
            entry_path = File.expand_path(File.join(temp_dir_path, relative_name))

            unless entry_path.start_with?(temp_dir_path)
              raise "Zip Slip detected: #{entry_path}"
            end

            FileUtils.mkdir_p(File.dirname(entry_path))

            # Витягуємо вручну через IO
            entry.get_input_stream do |is|
              File.open(entry_path, 'wb') do |f|
                IO.copy_stream(is, f)
              end
            end
          end
        end

        # puts "Розпаковано в: #{temp_dir_path}. Перегляньте"
        # gets

        # Тут працюємо з файлом document.xml:
        document_path = File.join(temp_dir_path, "word", "document.xml")
        # p document_path
        if File.exist?(document_path)
          content = File.read(document_path)
          context.each do |key, value|
            content.gsub!("%%#{key}%%", value)
          end
          File.write(document_path, content)
        end

        # puts "Перегляньте змінений файл #{document_path} і натисніть Enter для продовження"
        # gets
        output_path = Rails.root.join('tmp', diploma_file)
=begin
        Zip::File.open(output_path, create: true) do |zip|
          Dir[File.join(temp_dir_path, '**', '*')].each do |file|
            p file
            next if File.directory?(file)
            zip_path = file.sub("#{temp_dir_path}/", '').gsub('\\', '/')
            p zip_path
            zip.add(zip_path, file)
          end
        end
=end
        Zip::File.open(output_path, create: true) do |zip|
          Find.find(temp_dir_path) do |file|
            p file
            next if File.directory?(file)
            zip_path = Pathname.new(file).relative_path_from(Pathname.new(temp_dir_path)).to_s.gsub('\\', '/')
            p zip_path
            puts "Adding: #{zip_path}" if zip_path.include?('.rels')
            zip.add(zip_path, file)
          end
        end
        # puts "Перегляньте створений диплом #{diploma_file} і натисніть Enter для продовження"
        # gets

        FileUtils.remove_entry(temp_dir_path)
        # puts "Тимчасовий каталог #{temp_dir_path} видалено"

        diploma.seria = document["DocumentSeries"]
        diploma.number = document["DocumentNumber"]
        diploma.order_id = order_id
        diploma.save
        diploma.diploma_file.purge
        diploma.diploma_file.attach(
          io: File.open(Rails.root.join('tmp', diploma_file)), filename: diploma_file,
          content_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        )
        File.delete(Rails.root.join('tmp', diploma_file))
      else
        puts "Файл " + template_file_fullpath.to_s + " не знайдено"
      end
    end

    def set_cookies
      cookies.permanent[:my_diplomas_cart] = cookies[:my_diplomas_cart].presence || request.remote_ip + " / " + Time.now.to_s
      @orders = Order.where(user: cookies[:my_diplomas_cart]).order(:name)
      @absent_ukr = "інформація відсутня"
      @absent_eng = "information is missing"
      @missing_orig_ukr = "інформація відсутня в первинному документі"
      @missing_orig_eng = "information is missing in original document"
    end

end