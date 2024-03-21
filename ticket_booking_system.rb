class Movie
  attr_reader :title, :genre, :show_timings

  def initialize(title, genre, show_timings, total_seats)
    @title = title
    @genre = genre
    @show_timings = show_timings
    @total_seats = total_seats
  end

  def display_status
    puts "Movie: #{title} (Genre: #{genre})"
    @show_timings.each do |show_time|
      puts "  Show: #{show_time}, Total Seats: #{@total_seats}"
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
end

# CLI Interface
ticket_booking = TicketBookingSystem.new

ticket_booking.add_movie("Mission: Impossible", "Suspense", ["12:00 PM", "03:00 PM", "06:00 PM"], 20)
ticket_booking.add_movie("Thor", "Action", ["01:00 PM", "04:00 PM", "07:00 PM"], 15)

loop do
  puts "Welcome to Movie Ticket Booking System"
  puts ""
  puts "1. Display Movie Schedule"
  choice = gets.chomp.to_i

  case choice
  when 1
    ticket_booking.display_movie_status
    break
  else
    puts "Invalid choice. Please try again."
  end
end
