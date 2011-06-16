require 'rspec'
require 'mobme/codejam/top_actors'

module MobME
  module CodeJam
    describe TopActors do
      let(:t) { TopActors.new }
  
      before(:each) do 
        t.logger = Logger.new(StringIO.new)
        
        movies = {
          "The Shawshank Redemption"   =>  double(:title => "The Shawshank Redemption", :cast_members => ["Johnny Depp", "Mohanlal"]),
          "The Godfather"     =>  double(:title => "The Godfather", :cast_members => ["Johnny Depp", "Mohanlal"]),
          "Shawshank Acension"     =>  double(:title => "Shawshank Acension", :cast_members => ["Johnny Depp", "Mammooty"]),
          "Shawshank Acension II"  =>  double(:title => "Shawshank Acension II", :cast_members => ["Johnny Depp", "Mammooty"]),
          "Shawshank Acension III" => double(:title => "Shawshank Acension III", :cast_members => ["Johnny Depp", "Stuart Little"]),
          "Shawshank Acension IV" => double(:title => "Shawshank Acension IV", :cast_members => ["Mammooty", "Mohanlal"])
        }
    
        Imdb::Top250.stub(:new).and_return(double(:movies => movies.values))
        Imdb::Search.stub(:new) do |argument|
          double(:movies => [movies[argument]])
        end
      end
  
      describe "#top_movies" do
        it "should connect to IMDB top 250" do
          t.top_movies.should_not == nil
        end
    
        it "should get a reasonably correct list" do
          t.top_movies.should have_at_least(1).items
          t.top_movies.should include("The Shawshank Redemption")
          t.top_movies.should include("The Godfather")
        end
      end
      
      describe "#top_actors" do
        it "should get top actors from these movies" do
          t.top_actors.should have_at_least(1).items
        end
    
        it "should get number of appearances for actors" do
          t.top_actors.should include(["Johnny Depp", { :count => 5 }])
        end
      end
  
      describe "#rank_actors" do
        it "should rank actors based on standard competition ranking" do
          t.rank_actors.should == [ 
            { :actor => "Johnny Depp", :count => 5, :rank => 1 }, 
            { :actor => "Mohanlal", :count => 3, :rank => 2 }, 
            { :actor => "Mammooty", :count => 3, :rank => 2 }, 
            {:actor => "Stuart Little", :count => 1, :rank => 4 }
          ]
        end
      end
    end
  end
end
