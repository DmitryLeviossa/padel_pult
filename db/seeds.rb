# Idempotent seeds — safe to run multiple times

# Users
users = [
  { email: "admin@padel.com",   password: "111111", first_name: "Админ",    last_name: "Пользователь", gender: :male   },
  { email: "alexei@padel.com",  password: "password123", first_name: "Алексей",  last_name: "Иванов",       gender: :male   },
  { email: "boris@padel.com",   password: "password123", first_name: "Борис",    last_name: "Смирнов",      gender: :male   },
  { email: "vadim@padel.com",   password: "password123", first_name: "Вадим",    last_name: "Козлов",       gender: :male   },
  { email: "darya@padel.com",   password: "password123", first_name: "Дарья",    last_name: "Новикова",     gender: :female },
  { email: "elena@padel.com",   password: "password123", first_name: "Елена",    last_name: "Морозова",     gender: :female },
  { email: "fyodor@padel.com",  password: "password123", first_name: "Фёдор",    last_name: "Волков",       gender: :male   },
  { email: "galina@padel.com",  password: "password123", first_name: "Галина",   last_name: "Петрова",      gender: :female }
].map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.password              = attrs[:password]
    u.password_confirmation = attrs[:password]
    u.first_name            = attrs[:first_name]
    u.last_name             = attrs[:last_name]
    u.gender                = attrs[:gender]
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
league1_members = [ admin, alexei, boris, vadim, darya, elena, fyodor, galina ].map do |user|
  LeagueUser.find_or_create_by!(league_id: league1.id, user_id: user.id) do |lu|
    lu.score = rand(0..100)
  end
end
admin_lu1, alexei_lu1, boris_lu1, vadim_lu1, darya_lu1, elena_lu1, fyodor_lu1, galina_lu1 = league1_members

league2_members = [ boris, vadim, darya, elena ].map do |user|
  LeagueUser.find_or_create_by!(league_id: league2.id, user_id: user.id) do |lu|
    lu.score = rand(0..50)
  end
end
boris_lu2, vadim_lu2, darya_lu2, elena_lu2 = league2_members

standard_points = [
  { "from" => 1,  "to" => 1,  "points" => 10 },
  { "from" => 2,  "to" => 2,  "points" => 8  },
  { "from" => 3,  "to" => 3,  "points" => 6  },
  { "from" => 4,  "to" => 7,  "points" => 4  },
  { "from" => 8,  "to" => 12, "points" => 2  }
]

small_points = [
  { "from" => 1, "to" => 1, "points" => 15 },
  { "from" => 2, "to" => 2, "points" => 10 },
  { "from" => 3, "to" => 4, "points" => 5  }
]

# Tournaments
t1 = Tournament.find_or_create_by!(name: "Весенний кубок 2026", league: league1) do |t|
  t.start_date       = Date.new(2026, 5, 15)
  t.end_date         = Date.new(2026, 5, 17)
  t.max_participants = 16
  t.location         = "Московский спортивный центр"
  t.type             = "olimpic"
  t.status           = "active"
  t.description      = "Ежегодный весенний турнир, открытый для всех участников лиги"
  t.placement_points = standard_points
end

t2 = Tournament.find_or_create_by!(name: "Летний удар 2026", league: league1) do |t|
  t.start_date       = Date.new(2026, 7, 1)
  t.end_date         = Date.new(2026, 7, 3)
  t.max_participants = 8
  t.location         = "Олимпийский комплекс «Лужники»"
  t.type             = "olimpic"
  t.status           = "draft"
  t.description      = "Летний инвитейшнл для лучших игроков лиги"
  t.placement_points = small_points
end

t3 = Tournament.find_or_create_by!(name: "Петербургский открытый 2026", league: league2) do |t|
  t.start_date       = Date.new(2026, 6, 10)
  t.end_date         = Date.new(2026, 6, 12)
  t.max_participants = 8
  t.location         = "СКК «Петербургский»"
  t.type             = "olimpic"
  t.status           = "draft"
  t.description      = "Главный турнир Питерской лиги"
  t.placement_points = small_points
end

# Pairs for Spring Cup
Pair.find_or_create_by!(tournament: t1, player1: alexei_lu1, player2: boris_lu1)
Pair.find_or_create_by!(tournament: t1, player1: vadim_lu1, player2: darya_lu1)
Pair.find_or_create_by!(tournament: t1, player1: elena_lu1, player2: fyodor_lu1)
Pair.find_or_create_by!(tournament: t1, player1: galina_lu1, player2: admin_lu1)

# Pairs for Saint Petersburg Open
Pair.find_or_create_by!(tournament: t3, player1: boris_lu2, player2: vadim_lu2)
Pair.find_or_create_by!(tournament: t3, player1: darya_lu2, player2: elena_lu2)

# Notifications
Notification.destroy_all

# League invitation notifications (alexei invited boris, vadim, darya into league2)
[ boris, vadim, darya ].each do |user|
  Notification.create!(
    user: user,
    notification_type: :league_invitation,
    message: "Алексей Иванов пригласил(а) вас в лигу «#{league2.name}»",
    url: "/leagues/#{league2.id}"
  )
end

# Tournament registration open notifications (t2 opened for league1 members)
[ alexei, boris, vadim, darya, elena, fyodor, galina, admin ].each do |user|
  Notification.create!(
    user: user,
    notification_type: :tournament_registration_open,
    message: "Открыта регистрация на турнир «#{t2.name}»",
    url: "/tournaments/#{t2.id}"
  )
end

# Tournament added notification (partner added to Spring Cup)
Notification.create!(
  user: boris,
  notification_type: :tournament_added,
  message: "Алексей Иванов добавил(а) вас в турнир «#{t1.name}»",
  url: "/tournaments/#{t1.id}",
  read_at: Time.current
)

puts "Seeded: #{User.count} users, #{League.count} leagues, #{Tournament.count} tournaments, #{Pair.count} pairs, #{Notification.count} notifications"
