require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

def generate_form_letters
  contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)
    form_letter = erb_template.result(binding)

    save_thank_you_letter(id, form_letter)
  end
end

def clean_phone_numbers(phone)
  if phone.nil? || phone.length < 10 || phone.length == 11 && phone[0] != 1 || phone.length > 11
    '0000000000'
  elsif phone.length == 11 && phone[0] == 1
    phone[1..-1]
  else
    phone
  end
end

# Time targeting
def time_targeting(csv_file)
  csv_file.reduce(Hash.new(0)) do |heatmap, row|
    register = Time.strptime(row[:regdate], "%m/%d/%Y %k:%M").hour
    heatmap[register] += 1
    heatmap
  end
end

def day_targeting(csv_file)
  csv_file.reduce(Hash.new(0)) do |heatmap, row|
    register = Time.strptime(row[:regdate], "%m/%d/%Y %k:%M").strftime("%A")
    heatmap[register] += 1
    heatmap
  end
end
