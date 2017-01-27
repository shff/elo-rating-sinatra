require 'sinatra'
require 'sqlite3'
# require 'sequel'

db = SQLite3::Database.new("app.db")
# DB = Sequel.sqlite("app2.db")

# configure do
#   DB.create_table?(:boards) { String :pic; Int :score }
#   Dir["public/*.jpg"].each do |pic|
#     if DB[:boards].where(pic: pic).count == 0
#       DB[:boards].insert(pic: pic.gsub('public/', '') , score: 1)
#     end
#   end
#   DB[:boards].each do |pic|
#     if Dir["public/#{pic[:pic]}"].count == 0
#       # DB[:boards].exclude(pic: pic[:pic])
#     end
#   end
# end

def score(a, b, result)
  (a + 1 * (result * 1 / (10 ** (-(a - b) / 400) + 1))).floor
end

if db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='boards';").count == 0
  db.execute("create table boards (pic varchar(50), score int);")
end
Dir["public/*.jpg"].each do |pic|
  pic = pic.gsub('public/', '')
  if db.execute('select * from boards where pic = ?', pic).count == 0
    db.execute("insert into boards(pic, score) values(?, 1)", pic)
  end
end
db.execute('select pic, rowid from boards').each do |pic|
  if Dir["public/#{pic[0]}"].count == 0
    db.execute('delete from boards where rowid = ?;', pic[1])
  end
end

get '/' do
  @boards = db.execute("select a.rowid, a.pic, (select count(1) + 1 from boards b where b.score > a.score) from boards a order by random() limit 2;")
  @rank = db.execute("select a.pic, (select count(1) + 1 from boards b where b.score > a.score) from boards a order by score desc limit 10;")
  erb :index
end

get '/vote/:a/:b' do |a, b|
  score_a = db.execute('select score from boards where rowid = ?', a)[0][0]
  score_b = db.execute('select score from boards where rowid = ?', b)[0][0]
  db.execute('update boards set score = ? where rowid = ?', score(score_a, score_b, 2), a)
  db.execute('update boards set score = ? where rowid = ?', score(score_b, score_a, -2), b)

  @boards = db.execute("select a.rowid, a.pic, (select count(1) + 1 from boards b where b.score > a.score) from boards a order by random() limit 2;")
  @rank = db.execute("select a.pic, (select count(1) + 1 from boards b where b.score > a.score), a.score from boards a order by score desc limit 10;")
  erb :index
end

__END__

@@layout
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
      <h1><a href="index.html">Pedalboard Battle</a></h1>
    </div>
    <div id="main">
    	<%= yield %>
    </div>
    <div id="footer">
    </div>
  </body>
</html>

@@index
<a href="/vote/<%= @boards[0][0] %>/<%= @boards[1][0] %>"><img class="big" src="/<%= @boards[0][1] %>"></a>
<a href="/vote/<%= @boards[1][0] %>/<%= @boards[0][0] %>"><img class="big" src="/<%= @boards[1][1] %>"></a>
<br>
#<%= @boards[0][2] %> place vs #<%= @boards[1][2] %> place
<script>
  document.onkeydown = function(e) {
    e = e || window.event;
    if (e.keyCode == '37') {
       window.location.href = '/vote/<%= @boards[0][0] %>/<%= @boards[1][0] %>';
    }
    else if (e.keyCode == '39') {
       window.location.href = '/vote/<%= @boards[1][0] %>/<%= @boards[0][0] %>';
    }
  }
</script>
<br><br><br>
<% @rank.each do |board| %>
  <div style="float: left">
    <a href="/<%= board[0] %>" target="_blank"><img src="/<%= board[0] %>" style="width: 200px"></a><br>
    #<%= board[1] %> (score: <%= board[2] %>)
  </div>
<% end %>
<div style="clear: both"></div>