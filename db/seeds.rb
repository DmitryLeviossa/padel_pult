# Idempotent seeds — safe to run multiple times

# Users
users = [
  { email: "admin@padel.com",   password: "password123", first_name: "Админ",    last_name: "Пользователь" },
  { email: "alexei@padel.com",  password: "password123", first_name: "Алексей",  last_name: "Иванов"       },
  { email: "boris@padel.com",   password: "password123", first_name: "Борис",    last_name: "Смирнов"      },
  { email: "vadim@padel.com",   password: "password123", first_name: "Вадим",    last_name: "Козлов"       },
  { email: "darya@padel.com",   password: "password123", first_name: "Дарья",    last_name: "Новикова"     },
  { email: "elena@padel.com",   password: "password123", first_name: "Елена",    last_name: "Морозова"     },
  { email: "fyodor@padel.com",  password: "password123", first_name: "Фёдор",    last_name: "Волков"       },
  { email: "galina@padel.com",  password: "password123", first_name: "Галина",   last_name: "Петрова"      }
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.password              = attrs[:password]
    u.password_confirmation = attrs[:password]
    u.first_name            = attrs[:first_name]
    u.last_name             = attrs[:last_name]
  end
end

admin, alexei, boris, vadim, darya, elena, fyodor, galina = users

# Leagues
league1 = League.find_or_create_by!(name: "Московская открытая лига") do |l|
  l.description = "Соревновательная лига по падел-теннису в Москве"
  l.owner = admin
end

league2 = League.find_or_create_by!(name: "Питерская летняя лига") do |l|
  l.description = "Сезонная лига по падел-теннису для игроков Санкт-Петербурга"
  l.owner = alexei
end

# League members
league1_members = [admin, alexei, boris, vadim, darya, elena, fyodor, galina].map do |user|
  LeagueUser.find_or_create_by!(league_id: league1.id, user_id: user.id) do |lu|
    lu.score = rand(0..100)
  end
end
admin_lu1, alexei_lu1, boris_lu1, vadim_lu1, darya_lu1, elena_lu1, fyodor_lu1, galina_lu1 = league1_members

league2_members = [boris, vadim, darya, elena].map do |user|
  LeagueUser.find_or_create_by!(league_id: league2.id, user_id: user.id) do |lu|
    lu.score = rand(0..50)
  end
end
boris_lu2, vadim_lu2, darya_lu2, elena_lu2 = league2_members

# Tournaments
t1 = Tournament.find_or_create_by!(name: "Весенний кубок 2026", league: league1) do |t|
  t.start_date = Date.new(2026, 5, 15)
  t.end_date = Date.new(2026, 5, 17)
  t.max_participants = 16
  t.location = "Московский спортивный центр"
  t.type = "olimpic"
  t.status = "active"
  t.description = "Ежегодный весенний турнир, открытый для всех участников лиги"
end

t2 = Tournament.find_or_create_by!(name: "Летний удар 2026", league: league1) do |t|
  t.start_date = Date.new(2026, 7, 1)
  t.end_date = Date.new(2026, 7, 3)
  t.max_participants = 8
  t.location = "Олимпийский комплекс «Лужники»"
  t.type = "olimpic"
  t.status = "draft"
  t.description = "Летний инвитейшнл для лучших игроков лиги"
end

t3 = Tournament.find_or_create_by!(name: "Петербургский открытый 2026", league: league2) do |t|
  t.start_date = Date.new(2026, 6, 10)
  t.end_date = Date.new(2026, 6, 12)
  t.max_participants = 8
  t.location = "СКК «Петербургский»"
  t.type = "olimpic"
  t.status = "draft"
  t.description = "Главный турнир Питерской лиги"
end

# Pairs for Spring Cup
Pair.find_or_create_by!(tournament: t1, player1: alexei_lu1, player2: boris_lu1)
Pair.find_or_create_by!(tournament: t1, player1: vadim_lu1, player2: darya_lu1)
Pair.find_or_create_by!(tournament: t1, player1: elena_lu1, player2: fyodor_lu1)
Pair.find_or_create_by!(tournament: t1, player1: galina_lu1, player2: admin_lu1)

# Pairs for Saint Petersburg Open
Pair.find_or_create_by!(tournament: t3, player1: boris_lu2, player2: vadim_lu2)
Pair.find_or_create_by!(tournament: t3, player1: darya_lu2, player2: elena_lu2)

puts "Seeded: #{User.count} users, #{League.count} leagues, #{Tournament.count} tournaments, #{Pair.count} pairs"
