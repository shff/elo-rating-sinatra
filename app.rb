require 'sinatra'
require 'sequel'
require 'logger'

DB = Sequel.sqlite("app.db")
DB.logger = Logger.new(STDOUT)

configure do
  DB.create_table?(:pics) { primary_key :id; String :pic; Int :score }
  Dir.children("public").each do |name|
    DB[:pics].insert(pic: name, score: 1) unless DB[:pics].where(pic: name).any?
  end
  DB[:pics].each do |pic|
    DB[:pics].where(pic: pic[:pic]).delete if !Dir["public/#{pic[:pic]}"].any?
  end
end

def score(a, b, result)
  (a + 1 * (result * 1 / (10 ** (-(a - b) / 400) + 1))).floor
end

get '/' do
  @pics = DB.fetch("select a.id, a.pic, a.score, (select count(1) + 1 from pics b where b.score > a.score) as rank from pics a order by random() limit 2").to_a
  @rank = DB.fetch("select a.id, a.pic, a.score, (select count(1) + 1 from pics b where b.score > a.score) as rank from pics a order by a.score desc limit 10").to_a
  erb :index
end

get '/vote/:a/:b' do |a, b|
  score_a = DB[:pics].where(id: a).first[:score]
  score_b = DB[:pics].where(id: b).first[:score]
  DB[:pics].where(id: a).update(score: score(score_a, score_b, 2))
  DB[:pics].where(id: b).update(score: score(score_b, score_a, -2))

  redirect '/'
end

__END__

@@index
<!DOCTYPE html>
<html>
  <head>
    <title>Picture Battle</title>
    <style>
      body {
        font-family: Tahoma;
        margin: 0;
        padding: 0;
        text-align: center;
      }
      #header {
        background-color: #8C1B08;
        color: #fff;
        padding: 5px;
        margin-bottom: 8px;
      }
      #header a{
        color: #fff;
        text-decoration: none;
      }
      img.big {
        max-width: 450px;
        max-width: 40%;
      }
    </style>
  </head>
  <body>
    <div id="header">
      <h1><a href="/">Picture Battle</a></h1>
    </div>
    <div id="main">
      <a href="/vote/<%= @pics.first[:id] %>/<%= @pics.last[:id] %>">
        <img class="big" src="/<%= @pics.first[:pic] %>">
      </a>
      <a href="/vote/<%= @pics.last[:id] %>/<%= @pics.first[:id] %>">
        <img class="big" src="/<%= @pics.last[:pic] %>">
      </a>
      <br>
      #<%= @pics.first[:rank] %> place vs #<%= @pics.last[:rank] %> place
      <br><br><br>
      <% @rank.each do |board| %>
        <div style="float: left">
          <a href="/<%= board[:id] %>" target="_blank"><img src="/<%= board[:pic] %>" style="width: 200px"></a><br>
          #<%= board[:rank] %> (score: <%= board[:score] %>)
        </div>
      <% end %>
      <div style="clear: both"></div>
    </div>
    <script>
      document.onkeydown = function(e) {
        if (e.keyCode == '37')
          location.href = '/vote/<%= @pics.first[:id] %>/<%= @pics.last[:id] %>';
        else if (e.keyCode == '39')
          location.href = '/vote/<%= @pics.last[:id] %>/<%= @pics.first[:id] %>';
      }
    </script>
  </body>
</html>
