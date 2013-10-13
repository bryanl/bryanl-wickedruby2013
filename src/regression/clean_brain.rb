#!/usr/bin/env ruby

require 'csv'

CSV.open('brain.csv', "wb") do |csv|
  CSV.foreach("brain.txt") do |row|
    if row[1].to_f < 30
      csv << row
    end
  end
end