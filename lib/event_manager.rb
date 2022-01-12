# frozen_string_literal: true

require 'time'
require 'erb'
require 'csv'
require 'google-apis-civicinfo_v2'

puts 'EventManager Initialized.'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phones(phone_number)
  phone_number.each_char { |char| phone_number.gsub!(char, '') unless ('0'..'9').include?(char) }
  phone_number.rjust(10, '0')[0..9]
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  File.open("output/thanks_#{id}.html", 'w'){ |file| file.puts(form_letter) }
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def adtime_finder(time_array)
  hours = time_array.map { |time| Time.parse(time).hour }
  hours.tally.map { |key, value| value == hours.tally.values.max ? key : next }.compact
end

adtime_finder(contents.map { |row| row[:regdate].split(' ')[1] })

contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)
template = File.read('form_letter.erb')
erb_template = ERB.new(template)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  number = clean_phones(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  save_thank_you_letter(id, erb_template.result(binding))
end
