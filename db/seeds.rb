# Idempotent seeds — safe to run multiple times

# Users
users = [
  { email: "admin@padel.com", password: "password123" },
  { email: "alice@padel.com", password: "password123" },
  { email: "bob@padel.com", password: "password123" },
  { email: "carlos@padel.com", password: "password123" },
  { email: "diana@padel.com", password: "password123" },
  { email: "erik@padel.com", password: "password123" },
  { email: "fiona@padel.com", password: "password123" },
  { email: "george@padel.com", password: "password123" }
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.password = attrs[:password]
    u.password_confirmation = attrs[:password]
  end
end

admin, alice, bob, carlos, diana, erik, fiona, george = users

# Leagues
league1 = League.find_or_create_by!(name: "Madrid Open League") do |l|
  l.description = "Competitive padel league in Madrid"
  l.owner = admin
end

league2 = League.find_or_create_by!(name: "Barcelona Summer League") do |l|
  l.description = "Seasonal padel league for Barcelona players"
  l.owner = alice
end

# League members
[alice, bob, carlos, diana, erik, fiona, george].each do |user|
  LeagueUser.find_or_create_by!(league_id: league1.id, user_id: user.id) do |lu|
    lu.score = rand(0..100)
  end
end

[bob, carlos, diana, erik].each do |user|
  LeagueUser.find_or_create_by!(league_id: league2.id, user_id: user.id) do |lu|
    lu.score = rand(0..50)
  end
end

# Tournaments
t1 = Tournament.find_or_create_by!(name: "Spring Cup 2026", league: league1) do |t|
  t.start_date = Date.new(2026, 5, 15)
  t.end_date = Date.new(2026, 5, 17)
  t.max_participants = 16
  t.location = "Madrid Sports Center"
  t.type = "olimpic"
  t.status = "active"
  t.description = "Annual spring tournament open to all league members"
end

t2 = Tournament.find_or_create_by!(name: "Summer Smash 2026", league: league1) do |t|
  t.start_date = Date.new(2026, 7, 1)
  t.end_date = Date.new(2026, 7, 3)
  t.max_participants = 8
  t.location = "La Caja Mágica"
  t.type = "olimpic"
  t.status = "draft"
  t.description = "Smaller summer invitational for top league players"
end

t3 = Tournament.find_or_create_by!(name: "Barcelona Open 2026", league: league2) do |t|
  t.start_date = Date.new(2026, 6, 10)
  t.end_date = Date.new(2026, 6, 12)
  t.max_participants = 8
  t.location = "Club Natació Atlètic-Barceloneta"
  t.type = "olimpic"
  t.status = "draft"
  t.description = "Barcelona league's flagship tournament"
end

# Pairs for Spring Cup
Pair.find_or_create_by!(tournament: t1, player1: alice, player2: bob)
Pair.find_or_create_by!(tournament: t1, player1: carlos, player2: diana)
Pair.find_or_create_by!(tournament: t1, player1: erik, player2: fiona)
Pair.find_or_create_by!(tournament: t1, player1: george, player2: admin)

# Pairs for Barcelona Open
Pair.find_or_create_by!(tournament: t3, player1: bob, player2: carlos)
Pair.find_or_create_by!(tournament: t3, player1: diana, player2: erik)

puts "Seeded: #{User.count} users, #{League.count} leagues, #{Tournament.count} tournaments, #{Pair.count} pairs"
