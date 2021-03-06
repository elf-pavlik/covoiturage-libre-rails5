module ApplicationHelper

  def number_to_age(age)
    "#{age} ans".html_safe
  end

  def encode_decode(string)
    string.encode("iso-8859-1").force_encoding("utf-8") unless string.nil?
  end
  alias :ed :encode_decode

  def bootstrap_class_for(flash_type)
    { success: 'alert-success', error: 'alert-danger', alert: 'alert-warning', notice: 'alert-info' }[flash_type.to_sym] || flash_type.to_s
  end

  def flash_messages(opts = {})
    html = ''
    flash.each do |msg_type, message|
      html << content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)} fade in") do
        content_tag(:button, 'x', class: 'close', data: { dismiss: 'alert' })
        message
      end
    end
    html.html_safe
  end

  def trip_steps_breadcrumb(trip)
    breadcrumbs = ''
    trip.points.each_with_index do |step|
      breadcrumbs << step.city
      unless step == trip.points.last
        breadcrumbs << ' &rarr; '
      end
    end
    breadcrumbs.html_safe
  end

  def trip_title(trip)
    "Covoiturage gratuit #{trip_steps_breadcrumb(trip)} le #{l trip.departure_date} à #{l trip.departure_time, format: :short}".html_safe
  end

  def admin_page?
    /admin/.match(params[:controller])
  end

  def back_trip_page?
    /new_for_back/.match(params[:action])
  end

  def trip_copy_page?
    /new_from_copy/.match(params[:action])
  end

end
