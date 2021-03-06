class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Don't use locale from URL
  # needs to be set for use https://github.com/enriclluelles/route_translator
  # without a URL locale param for now
  skip_around_action :set_locale_from_url

  before_action :init_meta_tags

  private

    def init_meta_tags
      @meta ||= {
        title: 'Covoiturage libre',
        description: 'Covoiturage Libre : faites de la vraie économie du partage, covoiturez gratuitement et librement',
        image_url: "https://covoiturage-libre.fr/covoiturage-libre-RS-noel.png",
        author: 'Association Covoiturage libre',
        keywords: 'covoiturage, gratuit, libre, associatif',
        url: request.original_url
      }
    end
end
