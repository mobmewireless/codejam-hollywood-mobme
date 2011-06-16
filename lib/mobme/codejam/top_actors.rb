require 'imdb'
require 'logger'
require 'java'

module MobME 
  module CodeJam 

    # Finds top hollywood actors based on their number of appearances in top movie lists.
    #
    #   TopActors.rank_actors
    #   # => [{ :actor => "Johnny Depp", :count => 5, :rank => 1 }, { :actor => "Mohanlal", :count => 3, :rank => 2 }, 
    #         { :actor => "Mammooty", :count => 3, :rank => 2 }, { :actor => "Stuart Little", :count => 1, :rank => 4 }]
    #
    # Requires an Internet connection since it uses API queries to work.
    class TopActors
      CONCURRENT_API_REQUESTS = 10
      API_WAIT_TIMEOUT = 600 #in seconds
      
      attr_accessor :logger
      
      # Finds top movies
      def top_movies
        @top_movies ||= imdb_top_movies
        
        logger.debug "Top Movies: #{@top_movies.inspect}"
        @top_movies
      end
  
      # Finds top actors using top movies.
      # Also sorts actors based on the count of their movie appearences (in reverse)
      def top_actors
        @top_actors ||= imdb_top_actors.sort_by { |actor, parameters| -parameters[:count] }
        
        logger.debug "Top Actors: #{@top_actors.inspect}"
        @top_actors
      end
  
      # Ranks actors from top movie lists. 
      # Ranking is done using standard competition ranking.
      def rank_actors      
        top_actors.inject([]) do |sorted, element|
          sorted << if sorted.last and sorted.last[:count] == element.last[:count]
            { :actor => element.first, :count => element.last[:count], :rank => sorted.last[:rank] }
          else
            { :actor => element.first, :count => element.last[:count], :rank => sorted.length + 1 }
          end
        end
      end
  
      private
  
      def imdb_top_movies
        logger.info "Querying IMDB Top 250 service..."
        top_250_service = Imdb::Top250.new
        top_250_service.movies.map { |movie| movie.title }
      rescue Errno::ETIMEDOUT => e
        logger.info "Timeout occurred, retrying..."
        retry
      end
  
      def imdb_top_actors
        threadpool = java.util.concurrent.Executors.newFixedThreadPool(CONCURRENT_API_REQUESTS)
        actor_list = java.util.concurrent.ConcurrentHashMap.new
        
        top_movies.each_with_index do |movie, index|
          threadpool.execute do
            logger.info "Querying for #{movie} (#{index + 1}/#{top_movies.count})..."
            begin
              movie_result = Imdb::Search.new(movie).movies[0]
              logger.debug "movie_result for #{movie}: #{movie_result.inspect}"
              next unless movie_result
              
              movie_result.cast_members.each do |cast|
                actor_list[cast] ||= { :count => 0 }
                actor_list[cast][:count] += 1
              end
            rescue Errno::ETIMEDOUT => e
              logger.info "Timeout occurred, retrying..."
              retry
            end
          end
        end
        
        threadpool.shutdown
        threadpool.awaitTermination(API_WAIT_TIMEOUT, java.util.concurrent.TimeUnit::SECONDS)
        
        logger.info "Actor Querying complete."
        logger.debug "actor_list: #{actor_list.inspect}"
        
        actor_list.to_hash
      end
    end
  end
end