require 'sinatra'
require 'sequel'

DB = Sequel.sqlite("app.db")

configure do
  DB.create_table?(:pics) { primary_key :id; String :pic; Int :score }
  Dir["public/*.jpg"].each do |pic|
    name = pic.gsub('public/', '')
    DB[:pics].insert(pic: name, score: 1) if DB[:pics].where(pic: name).count == 0
  end
  DB[:pics].each do |pic|
    DB[:pics].exclude(pic: pic[:pic]) if Dir["public/#{pic[:pic]}"].count == 0
  end
end

def score(a, b, result)
  (a + 1 * (result * 1 / (10 ** (-(a - b) / 400) + 1))).floor
end

get '/' do
  @pics = DB.fetch("select a.rowid, a.pic, (select count(1) + 1 from pics b where b.score > a.score) as score from pics a order by random() limit 2").to_a
  @rank = DB.fetch("select a.id, a.pic, (select count(1) + 1 from pics b where b.score > a.score) as score from pics a order by a.score desc limit 10").to_a
  erb :index
end

get '/vote/:a/:b' do |a, b|
  score_a = DB.fetch('select score from pics where rowid = ?', a).to_a[0][:score]
  score_b = DB.fetch('select score from pics where rowid = ?', b).to_a[0][:score]
  DB.fetch('update pics set score = ? where rowid = ?', score(score_a, score_b, 2), a)
  DB.fetch('update pics set score = ? where rowid = ?', score(score_b, score_a, -2), b)

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
      a {
        text-decoration: none;
        color: darkblue;
      }
      a:hover {
        text-decoration: underline;
      }
      img.big {
        max-height: 450px;
        max-width: 40%;
      }
      #header {
        background-color: #8C1B08;
        color: #fff;
        padding: 5px;
      }
      #header a{
        color: #fff;
        text-decoration: none;
      }
      #main table {
        margin: 0 auto;
      }
      #footer {
        font: 12px Tahoma;
        margin: 25px 0 50px 0;
      }
      #footer a {
        margin-right: 10px;
      }
    </style>
  </head>
  <body>
    <div id="headr">
      <h1><a href="index.html">Picture Battle</a></h1>
    </div>
    <div id="main">
      <a href="/vote/<%= @pics.first[:id] %>/<%= @pics.last[:id] %>">
        <img class="big" src="/<%= @pics.first[:pic] %>">
      </a>
      <a href="/vote/<%= @pics.last[:id] %>/<%= @pics.first[:id] %>">
        <img class="big" src="/<%= @pics.last[:pic] %>">
      </a>
      <br>
      #<%= @pics.first[:score] %> place vs #<%= @pics.last[:score] %> place
      <script>
        document.onkeydown = function(e) {
          e = e || window.event;
          if (e.keyCode == '37') {
            window.location.href = '/vote/<%= @pics.first[:id] %>/<%= @pics.last[:id] %>';
          }
          else if (e.keyCode == '39') {
            window.location.href = '/vote/<%= @pics.last[:id] %>/<%= @pics.first[:id] %>';
          }
        }
      </script>
      <br><br><br>
      <% @rank.each do |board| %>
        <div style="float: left">
          <a href="/<%= board[:id] %>" target="_blank"><img src="/<%= board[:pic] %>" style="width: 200px"></a><br>
          #<%= board[:id] %> (score: <%= board[:score] %>)
        </div>
      <% end %>
      <div style="clear: both"></div>
    
    </div>
    <div id="footer">
    </div>
  </body>
</html>
