Dir.chdir("/Users/ethomasburkeiv/Projects/BezierGarden/tools/cgiar")

#Open ArcASCII file

arc = File.open("new_arc.asc")

#Extract values from header constants

ncols = arc.readline.sub("ncols", "").sub("\n", "").gsub(/\s/, "").to_f
nrows = arc.readline.sub("nrows", "").sub("\n", "").gsub(/\s/, "").to_f
xllcorner = arc.readline.sub("xllcorner", "").sub("\n", "").gsub(/\s/, "").to_f
yllcorner = arc.readline.sub("yllcorner", "").sub("\n", "").gsub(/\s/, "").to_f
cellsize = arc.readline.sub("cellsize", "").sub("\n", "").gsub(/\s/, "").to_f
NODATA_value = arc.readline.sub("NODATA_value", "").sub("\n", "").gsub(/\s/, "").to_f

#Set point spacing in dekameters

point_spacing = 9

#We should also recalculate the longitudinal point spacing based on the latitude of the row

pass_through = Array.new

until arc.eof?

  gridline = arc.readline.each { |e| e.to_i }

  pass_through << gridline

end

pass_through.reverse!

arc.close

pass_through.flatten!

one_point = Array.new

v_values = Array.new

v_array = Array.new

pass_through_line = Array.new

celly = 0

until celly >= nrows

  cellx = 0

  until cellx >= ncols

    pass_through_line = pass_through.at(celly).split

    one_point << "v"

    one_point << cellx * point_spacing

    one_point << celly * point_spacing

    one_point << pass_through_line.at(cellx)

    v_array << one_point

    v_values << v_array.join(" ")

    v_array.clear

    one_point.clear

    cellx += 1

  end

  celly += 1

end

arcobj = File.open("arc.obj","a") do |f1|

  f1.puts v_values

end


vertex_connect = Array.new

vertex_connect_point = Array.new

position = 1

stop_point = (nrows * ncols) - ncols

until position == stop_point

  vertex_connect_point << "f"

  vertex_connect_point << position

  vertex_connect_point << position + 1

  vertex_connect_point << (position + ncols + 1).to_i

  vertex_connect_point << (position + ncols).to_i

  puts vertex_connect_point

  vertex_connect << vertex_connect_point.join(" ")

  vertex_connect_point.clear

  position += 1

end


arcobj = File.open("arc.obj","a") do |f1|

  f1.puts vertex_connect

end



#end

#puts arcobj