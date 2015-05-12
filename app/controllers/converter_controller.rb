class ConverterController < ApplicationController

  def download_tile
    x = params[:x].to_i
    y = params[:y].to_i
    z = params[:z].to_i
    scale = params[:scale]

    osgb36 = apple_maps_xyz_to_osgb_xyz x, y, z

    logger.debug "osgb36 x: #{params[:x]}->#{osgb36[:x]}\nosgb36 y: #{params[:y]}->#{osgb36[:y]}\nosgb36 z: #{params[:z]}->#{osgb36[:z]}"

    redirect_url = "http://52.16.224.120/tilesetV4/comp/DFGHX10LU5J901AS/0/9999/9999/#{osgb36[:z]}/#{osgb36[:x]}/#{osgb36[:y]}.png"

    redirect_to redirect_url
  end

  def apple_maps_xyz_to_osgb_xyz(x, y, z)
    latlon = get_lat_lng_from_gmaps_tile x, y, z
    lat = latlon[:lat_deg]
    lon = latlon[:lng_deg]

    wgs84_point = OsgbConvert::WGS84.new(lat, lon, z)
    osgb36_point = wgs84_point.osgb36
    osUKgridPoint = OsgbConvert::OSGrid.from_osgb36(osgb36_point)

    x = get_x_code_from_os_easting osUKgridPoint.easting, z
    y = get_y_code_from_os_northing osUKgridPoint.northing, z
    z = z

    { x: x, y: y, z: z }
  end

  def get_gmaps_tile_number(lat_deg, lng_deg, zoom)
    lat_rad = lat_deg/180 * Math::PI
    n = 2.0 ** zoom
    x = ((lng_deg + 180.0) / 360.0 * n).to_i
    y = ((1.0 - Math::log(Math::tan(lat_rad) + (1 / Math::cos(lat_rad))) / Math::PI) / 2.0 * n).to_i

    { :x => x, :y =>y }
  end

  def get_lat_lng_from_gmaps_tile(xtile, ytile, zoom)
    n = 2.0 ** zoom
    lon_deg = xtile / n * 360.0 - 180.0
    lat_rad = Math::atan(Math::sinh(Math::PI * (1 - 2 * ytile / n)))
    lat_deg = 180.0 * (lat_rad / Math::PI)
    { :lat_deg => lat_deg, :lng_deg => lon_deg }
  end

  # OSGB36 tile management

  def get_code_from_position_and_zoom(easting, zoom)
    tile_size = map_size/2**zoom
    (easting/tile_size).floor
  end

  def get_x_code_from_os_easting(easting, zoom)
    get_code_from_position_and_zoom easting, zoom
  end

  def get_y_code_from_os_northing(northing, zoom)
    northing_adjusted = map_size - northing
    get_code_from_position_and_zoom northing_adjusted, zoom
  end

  def map_size
    1000000
  end

end
