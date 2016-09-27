require 'pdf-reader'
require 'json'

class PDF::Reader
  module WidthCalculator
    class BuiltIn
      alias :original_glyph_width :glyph_width
      def glyph_width(code_point)
        return 400 if code_point = 160 || code_point < 0
        original_glyph_width(code_point)
      end
    end
  end
end

reader = PDF::Reader.new("courses.pdf")
result = []
reader.pages[1..86].each do |page|
  begin
    # Strip header
    txt = page.text.sub /.*?(?=[\d]{5})/m, ''

    # Strip footer
    txt = txt.sub /Marianopolis College\s*\d+/m, ''

    # Strip \n characters
    txt.gsub!(/\n/, '')
    txt.gsub!(/\r/, '')

    # Split entry by Section ID
    array = txt.split(/(?=[\d]{5}[^\d])/)


    array.each do |entry|
      # p entry
      # Section 
      reg_section = /(\d{5})\s+/
      section = entry.scan(reg_section).flatten.first
      entry.sub!(reg_section, '')

      # Course
      reg_course = /((\w{3}-\w{3})(-\w{2})?)\s+/
      course = entry.scan(reg_course).flatten.first
      entry.sub!(reg_course, '')

      # Time
      reg_time_room = /([M|T|W|H|F|S|D]+)\s+(\d+:\d+)-(\d+:\d+)\s*([\S]+)/
      times = []
      entry.scan(reg_time_room).collect do |time|
        times << {day: time[0], time: [time[1], time[2]], room: time[3]}
      end
      entry.gsub!(reg_time_room, '')


      # I gave up and just cheat, fuck regex -Binyuan 2016
      # Both Teacher and Description

      # bool_comma = false
      num_comma = 0
      arr_description_array = entry.split(/\s{2,}/)
      int_seperator_index = arr_description_array.length
      arr_description_array.reverse_each do |idgaf|
        if num_comma == 0 or num_comma % 2 == 1
          if idgaf[idgaf.length - 1] == ','
            num_comma += 1
            idgaf[idgaf.length - 1] = ''
          end
          if idgaf.include?(',')
            num_comma += idgaf.split(',').length
          end
          if idgaf.include?(';')
            num_comma += 1
          end
          int_seperator_index = arr_description_array.index(idgaf)
        else
          break
        end
        # if bool_comma == false
        #   if idgaf.include?(',')
        #     bool_comma = true
        #     int_seperator_index = arr_description_array.index(idgaf)
        #   end
        # else
        #   if (idgaf.include?(',') or idgaf.include?(';')) and (arr_description_array.index(idgaf) != 0)
        #     int_seperator_index = arr_description_array.index(idgaf)
        #     next
        #   end
        #   break
        # end
      end

      arr_description = arr_description_array[0, int_seperator_index]
      arr_teacher = arr_description_array - arr_description

      teacher = arr_teacher.join(' ')
      description = arr_description.join(' ')

      entry.clear

      # # Well only description is left
      # reg_desc = /(.+?)(?=\w+[[:word:]-]+(\w+[[:word:]-]+)?,)/
      # description = entry.scan(reg_desc).flatten.first.split.join(' ')
      # entry.sub!(reg_desc, '')

      # # Teacher

      # teacher = entry.split.join(' ')
      # entry.clear



      # Teacher
      # reg_teacher = /(((\s*;\s*)?((\s?[[:alpha:]]+)+\s*,\s*(\s?[^\s\d]+)+\s*))+)/
      # Holy mother fucker, so slow
      #teacher = entry.scan(reg_teacher).flatten.first.split.join(' ')
      # p entry.scan(reg_teacher).flatten.first.split.join(' ') unless entry.scan(reg_teacher).flatten.first.nil?
      # entry.sub!(reg_teacher, '')



      # BIG OBJECT!
      # Remove dup
      if result.find {|f| f[:section] == section and f[:code] == course} == nil
        result << {section: section, meeting: times, name: description, teacher: teacher, code: course}
      end
    end

    file = File.open("extracted.txt", "w")
    file.write(JSON.pretty_generate(result))
  rescue IOError => e
    p e.message
    #some error occur, dir not writable etc.
  ensure
    file.close unless file.nil?
  end
end
