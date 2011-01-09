require "rubygems"
require "couchrest"

#Set database

@db = CouchRest.database!("http://pmark.couchone.com/elevation_pacnw")

#Set source file to srtm

srtm = File.open("srtm.asc")

#Extract values from header constants

ncols = srtm.readline.sub("ncols", "").sub("\n", "").gsub(/\s/, "").to_f
nrows = srtm.readline.sub("nrows", "").sub("\n", "").gsub(/\s/, "").to_f
xllcorner = srtm.readline.sub("xllcorner", "").sub("\n", "").gsub(/\s/, "").to_f
yllcorner = srtm.readline.sub("yllcorner", "").sub("\n", "").gsub(/\s/, "").to_f
cellsize = srtm.readline.sub("cellsize", "").sub("\n", "").gsub(/\s/, "").to_f
NODATA_value = srtm.readline.sub("NODATA_value", "").sub("\n", "").gsub(/\s/, "").to_f

#Convert elevation values string to gridline array

celly = 0

(0..nrows).each do |i|

  break if srtm.eof?

  gridline = srtm.readline

  if (i >= 4200) 

      gridline = gridline.split.collect { |e| e.to_i }

      #Get array position

      cellx = 0
      celly = i

      #Populate passthrough array with processing point

      lat = yllcorner + cellsize * celly

      gridline.collect do |elev| 

        elev = '' if (elev == -9999)
        
        long = xllcorner+cellsize*cellx

        @db.save_doc({ :elev => elev, :geometry => { :type => 'Point', :coordinates => [long, lat] } })

        cellx += 1
      end

       puts "row #{i}" if (i % 100) == 0
  end
end
  
puts "\nDone importing #{celly+1-4200} rows\n"
