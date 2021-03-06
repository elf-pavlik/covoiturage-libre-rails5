class Trip < ApplicationRecord

  # use of this classification https://en.wikipedia.org/wiki/Hotel_rating
  CAR_RATINGS = %w(standard comfort first_class luxury).freeze
  STATES = %w(pending confirmed deleted).freeze

  has_many :points, -> { order('rank asc') }, inverse_of: :trip, dependent: :destroy
  has_many :messages, dependent: :destroy

  has_secure_token :confirmation_token
  has_secure_token :edition_token
  has_secure_token :deletion_token

  accepts_nested_attributes_for :points, allow_destroy: true, reject_if: proc {|attrs| attrs[:city].blank? && attrs[:kind]=='Step' }

  validates_presence_of :departure_date, :departure_time, :price, :title, :name, :email, :seats, :comfort, :state
  validates_inclusion_of :smoking, in: [true, false]
  validates_inclusion_of :comfort, in: CAR_RATINGS
  validates_inclusion_of :state, in: STATES
  validates_inclusion_of :departure_date, in: Date.today..Date.today+1.year, message: "Mettre une date situé entre aujourd hui et dans 1 an"
  validates_numericality_of :seats, { greater_than_or_equal_to: 1 }
  validates_numericality_of :price, { greater_than_or_equal_to: 0 }
  validates_numericality_of :age, allow_blank: true
  validate :must_have_from_and_to_points
  validates_acceptance_of :terms_of_service
  validates_format_of :email, with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i


  after_create :send_confirmation_email

  # eager load points each time a trip is requested
  default_scope { includes(:points).order('created_at ASC') }

  def to_param
    confirmation_token
  end

  # access the departure point that comes eager loaded with a trip
  def point_from
    points.find { |point| point.kind == 'From' }
  end

  # access the destination point that comes eager loaded with a trip
  def point_to
    points.find { |point| point.kind == 'To' }
  end

  # access the steps point that comes eager loaded with a trip
  def step_points
    points.select { |point| point.kind == 'Step' }
  end

  def confirm!
    self.update_attribute(:state, 'confirmed')
    self.send_information_email
  end

  def soft_delete!
    self.update_attribute(:state, 'deleted')
  end

  def confirmed?
    state == 'confirmed'
  end

  def deleted?
    state == 'deleted'
  end

  def send_confirmation_email
    UserMailer.trip_confirmation(self).deliver_later
  end

  def send_information_email
    UserMailer.trip_information(self).deliver_later
  end

  def clone_without_date
    new_trip = self.dup
    new_trip.departure_date = new_trip.departure_time = nil
    new_trip.points = self.points.map { |p| p.dup }
    new_trip
  end

  def clone_as_back_trip
    new_trip = self.dup
    new_trip.departure_date = new_trip.departure_time = nil
    new_trip.points = self.points.reverse.map { |p| p.dup }
    new_trip.points.first.kind = 'From'
    new_trip.points.last.kind = 'To'
    new_trip
  end

  class << self

    def search(search)
      # empty search not allowed
      return nil if search.blank? || !search.valid?

      sql_query_string = <<-SQL
          select trip_point_a.id, departure_date, point_a_rank as from_rank, rank as to_rank
          from (
            select trips.id, departure_date, points.rank as point_a_rank
            from trips
            inner join points on points.trip_id = trips.id
            where state = 'confirmed'
            and departure_date >= '%s'
            and
              ST_Dwithin(
                ST_GeographyFromText('SRID=4326;POINT(' || points.lon || ' ' || points.lat || ')'),
                ST_GeographyFromText('SRID=4326;POINT(%f %f)'),
                25000
              )
          ) as trip_point_a
          inner join points on points.trip_id = trip_point_a.id
          where
            ST_Dwithin(
              ST_GeographyFromText('SRID=4326;POINT(' || points.lon || ' ' || points.lat || ')'),
              ST_GeographyFromText('SRID=4326;POINT(%f %f)'),
              25000
            )
          and point_a_rank < points.rank
          order by departure_date asc
      SQL

      Trip.find_by_sql([
          sql_query_string,
          search.date_value,
          search.from_lon,
          search.from_lat,
          search.to_lon,
          search.to_lat
        ])
    end

  end

  private

    def must_have_from_and_to_points
      if points.empty? or point_from.nil? or point_to.nil?
        errors.add(:base, "Le départ et l'arrivée du voyage sont nécessaires")
      end
    end

end
