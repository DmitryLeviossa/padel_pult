# Clean slate (order matters due to foreign keys)
[Notification, Pair, Tournament, LeagueInvitation, LeagueUser, League].each(&:destroy_all)

# Users — idempotent, kept across reruns
users_data = [
  { email: "admin@padel.com",      password: "111111",      first_name: "Админ",      last_name: "Пользователь", gender: :male   },
  { email: "alexei@padel.com",     password: "password123", first_name: "Алексей",    last_name: "Иванов",       gender: :male   },
  { email: "boris@padel.com",      password: "password123", first_name: "Борис",      last_name: "Смирнов",      gender: :male   },
  { email: "vadim@padel.com",      password: "password123", first_name: "Вадим",      last_name: "Козлов",       gender: :male   },
  { email: "darya@padel.com",      password: "password123", first_name: "Дарья",      last_name: "Новикова",     gender: :female },
  { email: "elena@padel.com",      password: "password123", first_name: "Елена",      last_name: "Морозова",     gender: :female },
  { email: "fyodor@padel.com",     password: "password123", first_name: "Фёдор",      last_name: "Волков",       gender: :male   },
  { email: "galina@padel.com",     password: "password123", first_name: "Галина",     last_name: "Петрова",      gender: :female },
  { email: "igor@padel.com",       password: "password123", first_name: "Игорь",      last_name: "Кузнецов",     gender: :male   },
  { email: "julia@padel.com",      password: "password123", first_name: "Юлия",       last_name: "Белова",       gender: :female },
  { email: "konstantin@padel.com", password: "password123", first_name: "Константин", last_name: "Орлов",        gender: :male   },
  { email: "larisa@padel.com",     password: "password123", first_name: "Лариса",     last_name: "Соколова",     gender: :female },
  { email: "mikhail@padel.com",    password: "password123", first_name: "Михаил",     last_name: "Лебедев",      gender: :male   },
  { email: "natasha@padel.com",    password: "password123", first_name: "Наталья",    last_name: "Зайцева",      gender: :female },
  { email: "oleg@padel.com",       password: "password123", first_name: "Олег",       last_name: "Семёнов",      gender: :male   },
  { email: "polina@padel.com",     password: "password123", first_name: "Полина",     last_name: "Степанова",    gender: :female }
]

users = users_data.map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.password              = attrs[:password]
    u.password_confirmation = attrs[:password]
    u.first_name            = attrs[:first_name]
    u.last_name             = attrs[:last_name]
    u.gender                = attrs[:gender]
  end
end

admin, alexei, boris, vadim, darya, elena, fyodor, galina,
  igor, julia, konstantin, larisa, mikhail, natasha, oleg, polina = users

# Leagues
league1 = League.create!(
  name: "Московская открытая лига",
  description: "Соревновательная лига по падел-теннису в Москве",
  owner: admin
)

league2 = League.create!(
  name: "Питерская летняя лига",
  description: "Сезонная лига по падел-теннису для игроков Санкт-Петербурга",
  owner: alexei
)

# League members
# league1: all 16 users → 8 pairs max
league1_users = [
  admin, alexei, boris, vadim, darya, elena, fyodor, galina,
  igor, julia, konstantin, larisa, mikhail, natasha, oleg, polina
]
league1_members = league1_users.map do |user|
  LeagueUser.find_or_create_by!(league_id: league1.id, user_id: user.id) do |lu|
    lu.score = rand(10..100)
  end
end

# league2: 8 users → 4 pairs max (alexei auto-added as owner)
league2_users = [alexei, boris, vadim, darya, elena, igor, julia, konstantin]
league2_members = league2_users.map do |user|
  LeagueUser.find_or_create_by!(league_id: league2.id, user_id: user.id) do |lu|
    lu.score = rand(10..80)
  end
end

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
t_completed_1 = Tournament.create!(
  name:              "Весенний кубок 2026",
  league:            league1,
  start_date:        Date.new(2026, 3, 1),
  end_date:          Date.new(2026, 3, 3),
  max_participants:  8,
  location:          "Московский спортивный центр",
  type:              "olympic",
  status:            "completed",
  description:       "Завершённый весенний кубок Московской лиги",
  placement_points:  standard_points
)

t_completed_2 = Tournament.create!(
  name:              "Зимний кубок Петербурга 2026",
  league:            league2,
  start_date:        Date.new(2026, 2, 10),
  end_date:          Date.new(2026, 2, 12),
  max_participants:  4,
  location:          "СКК «Петербургский»",
  type:              "olympic",
  status:            "completed",
  description:       "Завершённый зимний кубок Питерской лиги",
  placement_points:  small_points
)

t_active = Tournament.create!(
  name:              "Майский турнир 2026",
  league:            league1,
  start_date:        Date.new(2026, 5, 20),
  end_date:          Date.new(2026, 5, 22),
  max_participants:  8,
  location:          "Олимпийский комплекс «Лужники»",
  type:              "olympic",
  status:            "active",
  description:       "Активный майский турнир Московской лиги",
  placement_points:  standard_points
)

t_draft = Tournament.create!(
  name:              "Летний удар 2026",
  league:            league1,
  start_date:        Date.new(2026, 7, 1),
  end_date:          Date.new(2026, 7, 3),
  max_participants:  8,
  location:          "Спортивный клуб «Динамо»",
  type:              "olympic",
  status:            "draft",
  description:       "Предстоящий летний турнир (черновик)",
  placement_points:  standard_points
)

t_registration = Tournament.create!(
  name:              "Петербургский открытый 2026",
  league:            league2,
  start_date:        Date.new(2026, 6, 10),
  end_date:          Date.new(2026, 6, 12),
  max_participants:  4,
  location:          "СКК «Петербургский»",
  type:              "olympic",
  status:            "registration",
  description:       "Открыта регистрация на главный летний турнир Питерской лиги",
  placement_points:  small_points
)

# Pairs for completed_1 (league1): 4 pairs from first 8 members
league1_members.first(8).each_slice(2) do |p1, p2|
  Pair.create!(tournament: t_completed_1, player1: p1, player2: p2)
end

# Pairs for completed_2 (league2): 2 pairs from first 4 members
league2_members.first(4).each_slice(2) do |p1, p2|
  Pair.create!(tournament: t_completed_2, player1: p1, player2: p2)
end

# Pairs for active (league1): max = 8 pairs using all 16 members
league1_members.each_slice(2) do |p1, p2|
  Pair.create!(tournament: t_active, player1: p1, player2: p2)
end

# Pairs for registration (league2): max = 4 pairs using all 8 members
league2_members.each_slice(2) do |p1, p2|
  Pair.create!(tournament: t_registration, player1: p1, player2: p2)
end

# Notifications
[boris, vadim, darya].each do |user|
  Notification.create!(
    user: user,
    notification_type: :league_invitation,
    message: "Алексей Иванов пригласил вас в лигу «#{league2.name}»",
    url: "/leagues/#{league2.id}"
  )
end

league2_members.map(&:user).each do |user|
  Notification.create!(
    user: user,
    notification_type: :tournament_registration_open,
    message: "Открыта регистрация на турнир «#{t_registration.name}»",
    url: "/tournaments/#{t_registration.id}"
  )
end

Notification.create!(
  user: boris,
  notification_type: :tournament_added,
  message: "Вас добавили в турнир «#{t_active.name}»",
  url: "/tournaments/#{t_active.id}",
  read_at: Time.current
)

puts "Seeded: #{User.count} users, #{League.count} leagues, #{Tournament.count} tournaments, #{Pair.count} pairs, #{Notification.count} notifications"
