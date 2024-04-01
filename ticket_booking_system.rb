class Movie
  attr_reader :title, :genre, :show_timings

  def initialize(title, genre, show_timings)
    @title = title
    @genre = genre
    @show_timings = show_timings.map { |show_time| show_time.merge({ seats: Array.new(show_time[:total_seat], false) })}
  end

  def reserve_seat(show_time, number_tickets)
    show_time_hash = @show_timings.find { |st| st[:time] == show_time }

    unless show_time_hash
      return "Invalid show time."
    end

    available_seats = show_time_hash[:seats].count(false)

    if number_tickets > available_seats
      return "Sorry, only #{available_seats} seat(s) available for #{title} - #{show_time}."
    end

    booked_seats = []
    seats = show_time_hash[:seats]

    number_tickets.times do
      seat_index = seats.index(false)
      seats[seat_index] = true # true means booked seat
      booked_seats << seat_index + 1
    end

    show_time_hash[:seats] = seats
    return {title: title, show_time: show_time, booked_seats: booked_seats}
  end

  def display_status
    puts "Movie: #{title} (Genre: #{genre})"
    @show_timings.each do |show_time|
      available_seats = show_time[:total_seat] - show_time[:seats].count(true)
      puts "  Show: #{show_time[:time]}, Total Seats: #{show_time[:total_seat]}, Available Seats: #{available_seats}"
    end
    puts "-----------------------------------------"
  end

  def cancel_ticket(show_time, number_of_tickets)
    show_time_hash = @show_timings.find { |st| st[:time] == show_time }

    unless show_time_hash
      return "Invalid show time."
    end

    seats = show_time_hash[:seats]
    booked_seats_count = seats.count(true)

    if number_of_tickets > booked_seats_count
      return "You can only cancel up to #{booked_seats_count} ticket(s) for #{show_time}."
    end

    canceled_seats = []
    number_of_tickets.times do
      canceled_seat_index = seats.index(true)
      seats[canceled_seat_index] = false
      canceled_seats << canceled_seat_index + 1
    end

    show_time_hash[:seats] = seats

    # Make the canceled seats available again
    available_seats = show_time_hash[:seats].count(false)
    return { show_time: show_time, canceled_seats: canceled_seats, available_seats: available_seats }
  end
end

class TicketBookingSystem
  def initialize
    @movies = []
    @user_data = []
  end

  def add_movie(title, genre, show_timings)
    @movies << Movie.new(title, genre, show_timings)
  end

  def display_movie_status
    @movies.each do |movie|
      movie.display_status
    end
  end

  def book_tickets(movie_title, show_time, number_tickets, user_mobile_number)
    return "Invalid mobile number." unless valid_mobile_number?(user_mobile_number)

    movie = find_movie(movie_title)
    return "Unable to find Movie." unless movie

    response = movie.reserve_seat(show_time, number_tickets)
    return response unless response.is_a?(Hash)

    user_data_index = find_user_data_index(user_mobile_number)
    if user_data_index
      update_user_data(user_data_index, response)
    else
      create_new_user_data(user_mobile_number, response)
    end

    puts "#{@user_data}"
    "Tickets booked for #{response[:title]} - #{response[:show_time]}. Seat number(s): #{response[:booked_seats].join(', ')}"
  end

  def cancel_tickets(movie_title, show_time, number_of_tickets, user_mobile_number)
    return "Invalid mobile number." unless valid_mobile_number?(user_mobile_number)

    movie = find_movie(movie_title)
    return "Unable to find Movie." unless movie

    user_data_index = find_user_data_index(user_mobile_number)
    return "No booking found for the given mobile number." unless user_data_index

    response = movie.cancel_ticket(show_time, number_of_tickets)
    return response unless response.is_a?(Hash)

    user_data = @user_data[user_data_index]
    user_tickets = get_user_tickets(user_data, movie_title, show_time)

    return "No booking found for the given show time and mobile number." if user_tickets.nil? || user_tickets.empty?
    return "You can only cancel up to #{user_tickets.length} ticket(s) for #{movie_title} - #{show_time}." if user_tickets.length < number_of_tickets

    update_user_tickets(user_data_index, user_data, movie_title, show_time, response[:canceled_seats], user_tickets)


    puts "#{@user_data}"
    return "Tickets canceled for #{movie_title} - #{show_time}. Seat number(s): #{response[:canceled_seats].join(', ')}"
  end


  # Dynamic movie's max booking
  def max_bookings_for_show
    max = 0
    max_hash = {}

    @movies.each do |movie|
      movie.show_timings.each do |show|
        value = show[:total_seat] - show[:seats].count(false)
        if value > max
          max = value
          max_hash = { movie_title: movie.title, show_time: show[:time], bookings: max }
        end
      end
    end

    puts "Max Booking Show: #{max_hash}"
  end

  # Movie's Max booking using static data
  def max_bookings_for_show_static
    booking_hash = {"Avenger": {"4PM": 5, "12PM": 2}, "Titanic": {"9PM": 10, "2PM": 2}}

    max = 0
    max_hash = {}
    booking_hash.each do |key, value|
      value.each do |key1, value1|
        if value1 > max
          max = value1
          max_hash = { movie_name: key, time: key1, bookings: value}
        end
      end
    end

    puts "Max Booking Show: #{max_hash}"
  end

  private

  def find_movie(title)
    @movies.find { |movie| movie.title.downcase == title.downcase }
  end

  def valid_mobile_number?(user_mobile_number)
    user_mobile_number.to_s.length == 10 && user_mobile_number.to_s =~ /\A\d+\z/
  end

  def find_user_data_index(user_mobile_number)
    @user_data.find_index { |user| user[:mobile_number] == user_mobile_number }
  end

  def update_user_data(user_data_index, response)
    user_data = @user_data[user_data_index]
    title = response[:title].to_sym
    show_time = response[:show_time].to_sym
    booked_seats = response[:booked_seats]

    user_data[:tickets][title] ||= {}
    user_data[:tickets][title][show_time] ||= []
    user_data[:tickets][title][show_time] += booked_seats
  end

  def create_new_user_data(user_mobile_number, response)
    title = response[:title].to_sym
    show_time = response[:show_time].to_sym
    booked_seats = response[:booked_seats]

    new_user_data = {
      mobile_number: user_mobile_number,
      tickets: {
        title => {
          show_time => booked_seats
        }
      }
    }

    @user_data.push(new_user_data)
  end

  def get_user_tickets(user_data, movie_title, show_time)
    user_data[:tickets][movie_title.downcase.capitalize.to_sym][show_time.to_sym]
  end

  def update_user_tickets(user_data_index, user_data, movie_title, show_time, canceled_seats, user_tickets)
    updated_user_tickets = user_tickets - canceled_seats

    if updated_user_tickets.empty?
      user_data[:tickets][movie_title.downcase.capitalize.to_sym].delete(show_time.to_sym)
    else
      user_data[:tickets][movie_title.downcase.capitalize.to_sym][show_time.to_sym] = updated_user_tickets
    end

    @user_data[user_data_index] = user_data
  end
end

# CLI Interface
ticket_booking = TicketBookingSystem.new

ticket_booking.add_movie("Titanic", "Documentary", [{ time: "12:00 PM", total_seat: 15 }, { time: "03:00 PM", total_seat: 15 }, { time: "06:00 PM", total_seat: 15 }])
ticket_booking.add_movie("Thor", "Action", [{ time: "01:00 PM", total_seat: 15 }, { time: "04:00 PM", total_seat: 15 }, { time: "07:00 PM", total_seat: 15 }])

loop do
  puts "Welcome to Movie Ticket Booking System"
  puts ""
  puts "1. Display Movie Schedule"
  puts "2. Book a Ticket"
  puts "3. Cancel a Ticket"
  puts "4. Add Movie Details and Show Timings"
  puts "5. Max Booking"
  puts "6. Exit"
  choice = gets.chomp.to_i

  case choice
  when 1
    ticket_booking.display_movie_status
  when 2
    puts "Enter movie title:"
    movie_title = gets.chomp
    puts "Enter a showtime to book (e.g. 12:00 PM):"
    show_time = gets.chomp
    puts "How many tickets do you want to book?"
    number_tickets = gets.chomp.to_i
    puts "Enter mobile number:"
    user_mobile_number = gets.chomp.to_i
    puts ticket_booking.book_tickets(movie_title, show_time, number_tickets, user_mobile_number)
  when 3
    puts "Enter movie title:"
    movie_title = gets.chomp
    puts "Enter showtime of the ticket (e.g. 12:00 PM):"
    show_time = gets.chomp
    puts "How many tickets do you want to cancel?"
    number_of_tickets = gets.chomp.to_i
    puts "Enter Mobile number, which you have used to book the ticket"
    user_mobile_number = gets.chomp.to_i
    puts ticket_booking.cancel_tickets(movie_title, show_time, number_of_tickets, user_mobile_number)
  when 4
    puts "Enter movie title:"
    movie_title = gets.chomp
    puts "Enter Genre: "
    genre = gets.chomp
    puts "Enter number of show times for Movie (e.g. 3): "
    show_times = gets.chomp.to_i

    movie_show_seats = []
    show_times.times do |i|
      puts "Enter showtime #{i + 1} details:"
      puts "Time (e.g., 12:00 PM):"
      show_time = gets.chomp
      puts "Total seats:"
      total_seat = gets.chomp.to_i

      movie_show_seats << { time: show_time, total_seat: total_seat }
    end

    ticket_booking.add_movie(movie_title, genre, movie_show_seats)
  when 5
    ticket_booking.max_bookings_for_show
  when 6
    puts "Thank you for using Ticket Booking System. Goodbye!"
    break
  else
    puts "Invalid choice. Please try again."
  end
end
