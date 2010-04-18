namespace :emt do
  desc 'Import bus stop data from emt.sqlite database'
  task :import_bus_stops => :environment do
    require 'sqlite3'

    db = SQLite3::Database.new(File.join(Rails.root, 'db', 'emt.sqlite'))
    Location.destroy_all
    Line.destroy_all
    Route.destroy_all
    db.execute("select * from BUSSTOP").each do |row|
      puts row.inspect
      begin
        location = Location.create! :emt_code => row[0], :name => row[1], :lat => row[2].to_f, :lng => row[3].to_f
        [row[4].split(' '), row[5].split(' ')].transpose.each do |pair|
          direction = ((pair.last[-1..-1] == '1') ? "normal" : "reverse")
          emt_line =  pair.last[0..-3]
          line = Line.find_or_create_by_name(pair.first)
          puts "\t #{line.name} [#{direction} direction]"
          route = Route.find_or_create_by_line_id_and_direction(line.id, direction)
          route.update_attributes(:emt_line => emt_line)
          location.routes << route
        end
      rescue
        puts "#{$!}"
      end
    end
  end
end
