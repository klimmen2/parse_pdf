class HardWorkerrrrrrrrrrrrrrrrrrrrr
  include Sidekiq::Worker
  include SidekiqStatus::Worker
  sidekiq_options retry: false

  def perform(name_file)
  	contents = open_file(name_file)
      parse = parse_file(contents)
      if parse != false 
        @client =  new_db_client(parse)        
        @client.save       
      end
  end

  def open_file(name_file)
    all_content=[] 
    reader = PDF::Reader.new("public/uploads/#{name_file}")       
    reader.pages.each do |page|
      all_content.push(page.text)
    end
    return all_content
  end
  
  def parse_file(contents)    
      client = contents[0].slice(/CLIENT\W+N\W+\w+/).slice(/\d+/).to_i
      bill = contents[0].slice(/BILL\WN\W+\w+/).slice(/\d+/).to_i
      n_pages_individual_detail = 0 # количество пропарсиный страниц individual_detail (в заданини первые 5)
      data_cellular_numbers = []      
      # создаем хеш с даными для заполнения полей individual_detail, первые елементы масивов - регулярки для 
      # поиска нужных данных 
      parse = {service_plan_name: [/Service Plan Name/], additional_local_airtime:  [/Additional Local Airtime/],
        long_distance_charges: [/Long Distance Charges/], data_and_other_services: [/Data and Other Services/],
        value_addded_services: [/Value Added Services/],saving: [/Total\W+Month's\W+Savings\W+\d+.\d+/],
        total_current_charges: [/Total Current Charges\W+\d+.\d+/]}
      contents.each do |content| # парсинг по страницам
        # exit_cellular_numbers - переход с поиска данных с таблицы cellular_number на таблицу individual_detail
        exit_cellular_numbers = content.scan(/I\WN\WD\WI\WV\WI\WD\WU\WA\WL\WD\WE\WT\WA\WI\WL/) 
        if exit_cellular_numbers.empty?
          # вытягиваем все данные для таблицы cellular_number     (/\w+\W+(\d+\-){2}\d+(\W+\d+\.\d+){12}/) 
          data_cellular_numbers += content.scan(/\w+\W+\d+\-\d+\-\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+/)
        elsif !exit_cellular_numbers.empty? && n_pages_individual_detail < 5       
          if !content.slice(/C u r r e n t C h a r g e s - D e t a i l/).nil? # есть ли данные на странице для individual_detail
            n_pages_individual_detail += 1
            totals_individual_detail = [] # для вытягивание тоталов на странице
            totals_individual_detail = content.scan(/Total\W+\$ \d+.\d+/)
            totals_individual_detail.map! do |k| # вытягиваем или тоталов только числовое значение
              k.slice(/\d+.\d+/)
            end   
            n_totals_individual_detail = 0 # нужна для присваивания нужного значения нужному столбцу таблицы individual_detail
            parse.each_key do |key|
              if content.slice(parse[key][0]).nil? # если даных для столбца на странице нет то присв. - 0
                parse[key].push(0)
              elsif key == :saving || key == :total_current_charges  
                parse[key].push(content.slice(parse[key][0]).slice(/\d+.\d+/))
              else
                parse[key].push(totals_individual_detail[n_totals_individual_detail])
                n_totals_individual_detail += 1
              end
            end              
          end
        else n_pages_individual_detail >= 5       
          break       
        end
      end  
      data_cellular_numbers.map! do |i| # данные для таблицы cellular_number заганяем в масив
        i.split
      end
      parse.each_key do |key|  # удаляем регулярки, за ненадобностью
        parse[key].delete_at(0)
      end   
      # загоняем все нужные переменные в хеш для ретурна
      parse[:client] = client
      parse[:bill] =  bill
      parse[:data_cellular_numbers] = data_cellular_numbers
      return parse 
  end

  def new_db_client(parse)
    client = Client.new(client_number:parse[:client], bill_number:parse[:bill] )
    parse[:data_cellular_numbers].each do |data_cellular_number|
      client.cellular_numbers << new_db_cellular_number(data_cellular_number)
    end
    parse[:saving].each_index do |i|
      client.individual_details << new_db_individual_detail(parse[:saving][i], 
                                  parse[:total_current_charges][i], parse[:service_plan_name][i], 
                                  parse[:additional_local_airtime][i], parse[:long_distance_charges][i],
                                  parse[:data_and_other_services][i], parse[:value_addded_services][i])
    end
    client
  end

  def new_db_cellular_number(data_cellular_number)
    cellular_number = CellularNumber.new
    cellular_number.user = data_cellular_number[1]
    cellular_number.service_plan_price = data_cellular_number[2].to_f
    cellular_number.additional_local_airtime = data_cellular_number[3].to_f
    cellular_number.ld_and_roaming_charges = data_cellular_number[4].to_f
    cellular_number.data_voice_and_other = data_cellular_number[5].to_f
    cellular_number.other_frees = data_cellular_number[9].to_f
    cellular_number.gst = data_cellular_number[12].to_f
    cellular_number.subtotal = data_cellular_number[11].to_f
    cellular_number.total = data_cellular_number[13].to_f 
    return cellular_number  
  end

  def new_db_individual_detail(saving, total_current_charges, service_plan_name,
                               additional_local_airtime, long_distance_charges,
                               data_and_other_services, value_addded_services)
    individual_detail = IndividualDetail.new
    individual_detail.total_onths_savings = saving.to_f
    individual_detail.total = total_current_charges.to_f
    individual_detail.service_plan_name = service_plan_name
    individual_detail.additional_local_airtime = additional_local_airtime
    individual_detail.long_distance_charges = long_distance_charges
    individual_detail.data_and_other_services = data_and_other_services
    individual_detail.value_addded_services = value_addded_services
    return individual_detail
  end

  
end