class Movie
  attr_reader :title, :genre, :show_timings

  def initialize(title, genre, show_timings, total_seats)
    @title = title
    @genre = genre
    @show_timings = show_timings
    @total_seats = total_seats
    @seats = Array.new(total_seats, false) # false means available seat
  end

  def available_seats_count(show_time)
    show_index = @show_timings.index(show_time)

    if show_index
      # calculate the range of seats for the show
      show_start = show_index * @total_seats / @show_timings.length
      show_end = (show_index + 1) * @total_seats / @show_timings.length

      available_seats = @seats[show_start...show_end].count(false) # count of available seats

      return available_seats
    else
      0
    end
  end

  def reserve_seat(show_time, number_tickets)
    if !@show_timings.include?(show_time)
      return "Invalid show time."
    end

    available_seats = available_seats_count(show_time)

    if number_tickets > available_seats
      return "Sorry, only #{available_seats} seat(s) available for #{title} - #{show_time}."
    end

    booked_seats = []
    number_tickets.times do
      seat_index = @seats.index(false)
      @seats[seat_index] = true # true means booked seat
      booked_seats << seat_index + 1
    end

    return "Tickets booked for #{title} - #{show_time}. Seat number(s): #{booked_seats.join(', ')}"
  end

  def display_status
    puts "Movie: #{title} (Genre: #{genre})"
    @show_timings.each do |show_time|
      available_seats = available_seats_count(show_time)
      puts "  Show: #{show_time}, Total Seats: #{@total_seats}, Available Seats: #{available_seats}"
    end
    puts "-----------------------------------------"
  end
end

class TicketBookingSystem
  def initialize
    @movies = []
  end

  def add_movie(title, genre, show_timings, total_seats)
    @movies << Movie.new(title, genre, show_timings, total_seats)
  end

  def display_movie_status
    @movies.each do |movie|
      movie.display_status
    end
  end

  def book_tickets(movie_title, show_time, number_tickets)
    movie = find_movie(movie_title)
    if movie
      return movie.reserve_seat(show_time, number_tickets)
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

ticket_booking.add_movie("Mission: Impossible", "Suspense", ["12:00 PM", "03:00 PM", "06:00 PM"], 20)
ticket_booking.add_movie("Thor", "Action", ["01:00 PM", "04:00 PM", "07:00 PM"], 15)

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
    puts ticket_booking.book_tickets(movie_title, show_time, number_tickets)
  when 3
    puts "Thank you for using Ticket Booking System. Goodbye!"
    break
  else
    puts "Invalid choice. Please try again."
  end
end
