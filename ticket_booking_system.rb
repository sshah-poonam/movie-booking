require 'pry'

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
    movie = find_movie(movie_title)
    if movie
      response = movie.reserve_seat(show_time, number_tickets)
      if response.is_a?(Hash)
        user_data_index = @user_data.find_index { |user| user[:mobile_number] == user_mobile_number }

        if user_data_index
          user_data = @user_data[user_data_index]
          booked_ticket = user_data[:tickets][response[:title].to_sym]

          if booked_ticket
            booked_ticket[response[:show_time].to_sym] = (booked_ticket[response[:show_time].to_sym] || []).concat(response[:booked_seats])
          else
            booked_ticket = {
              "#{response[:show_time]}": response[:booked_seats]
            }
          end

          user_data[:tickets][response[:title].to_sym] = (user_data[:tickets][response[:title].to_sym] || {}).merge(booked_ticket)
          @user_data[user_data_index] = user_data
        else
          user_data = { mobile_number: user_mobile_number }

          user_data[:tickets] = {
            "#{response[:title]}": {
              "#{response[:show_time]}": response[:booked_seats]
            }
          }

          @user_data.push(user_data)
        end

        return "Tickets booked for #{response[:title]} - #{response[:show_time]}. Seat number(s): #{response[:booked_seats].join(', ')}"
      else
        return response
      end
    else
      return "Unable to find Movie."
    end
  end

  private

  def find_movie(title)
    @movies.find { |movie| movie.title.downcase == title.downcase }
  end
end

# CLI Interface
ticket_booking = TicketBookingSystem.new

ticket_booking.add_movie("Mission: Impossible", "Suspense", [{ time: "12:00 PM", total_seat: 15 }, { time: "03:00 PM", total_seat: 15 }, { time: "06:00 PM", total_seat: 15 }])
ticket_booking.add_movie("Thor", "Action", [{ time: "01:00 PM", total_seat: 15 }, { time: "04:00 PM", total_seat: 15 }, { time: "07:00 PM", total_seat: 15 }])

loop do
  puts "Welcome to Movie Ticket Booking System"
  puts ""
  puts "1. Display Movie Schedule"
  puts "2. Book a Ticket"
  puts "3. Exit"
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
    puts "Thank you for using Ticket Booking System. Goodbye!"
    break
  else
    puts "Invalid choice. Please try again."
  end
end
