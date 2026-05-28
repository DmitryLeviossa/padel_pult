# Clean slate (order matters due to foreign keys)
[ Notification, Match, Pair, Tournament, LeagueInvitation, LeagueUser, Season, League, Club ].each(&:destroy_all)

# Users — idempotent, kept across reruns
users_data = [
  { email: "admin@padel.com",      password: "111111",      first_name: "Дмитрий",    last_name: "Гусев",        gender: :male   },
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
  { email: "polina@padel.com",     password: "password123", first_name: "Полина",     last_name: "Степанова",    gender: :female },
  { email: "roman@padel.com",      password: "password123", first_name: "Роман",      last_name: "Тихонов",      gender: :male   },
  { email: "svetlana@padel.com",   password: "password123", first_name: "Светлана",   last_name: "Филиппова",    gender: :female },
  { email: "timur@padel.com",      password: "password123", first_name: "Тимур",      last_name: "Хасанов",      gender: :male   },
  { email: "ulyana@padel.com",     password: "password123", first_name: "Ульяна",     last_name: "Цветкова",     gender: :female },
  { email: "viktor@padel.com",     password: "password123", first_name: "Виктор",     last_name: "Чернов",       gender: :male   },
  { email: "xenia@padel.com",      password: "password123", first_name: "Ксения",     last_name: "Шарова",       gender: :female },
  { email: "yuri@padel.com",       password: "password123", first_name: "Юрий",       last_name: "Щербаков",     gender: :male   },
  { email: "zoya@padel.com",       password: "password123", first_name: "Зоя",        last_name: "Якимова",      gender: :female }
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
  igor, julia, konstantin, larisa, mikhail, natasha, oleg, polina,
  roman, svetlana, timur, ulyana, viktor, xenia, yuri, zoya = users

# Clubs
club_moscow_sport    = Club.create!(name: "Московский спортивный центр",    address: "Москва, ул. Спортивная, 1")
club_luzhniki        = Club.create!(name: "Олимпийский комплекс «Лужники»",  address: "Москва, Лужнецкая наб., 24")
club_dynamo_moscow   = Club.create!(name: "Спортивный клуб «Динамо»",        address: "Москва, Ленинградский пр-т, 36")
club_olimpiysky      = Club.create!(name: "Спортивный комплекс «Олимпийский»", address: "Москва, Олимпийский пр-т, 16")
club_champion        = Club.create!(name: "Спортивный клуб «Чемпион»",       address: "Москва, ул. Победы, 5")
club_arena           = Club.create!(name: "Спортивный комплекс «Арена»",     address: "Москва, ул. Арена, 10")
club_olimp           = Club.create!(name: "Теннисный клуб «Олимп»",          address: "Москва, ул. Олимпийская, 3")
club_piter           = Club.create!(name: "СКК «Петербургский»",             address: "Санкт-Петербург, пр. Юрия Гагарина, 8")

# Leagues
league1 = League.create!(
  name:               "Московская открытая лига",
  description:        "Соревновательная лига по падел-теннису в Москве",
  owner:              admin,
  tournaments_quota:  12
)

league2 = League.create!(
  name:               "Питерская летняя лига",
  description:        "Сезонная лига по падел-теннису для игроков Санкт-Петербурга",
  owner:              alexei,
  tournaments_quota:  10
)

# League members
# league1: all 24 users
league1_users = [
  admin, alexei, boris, vadim, darya, elena, fyodor, galina,
  igor, julia, konstantin, larisa, mikhail, natasha, oleg, polina,
  roman, svetlana, timur, ulyana, viktor, xenia, yuri, zoya
]
league1_members = league1_users.map do |user|
  LeagueUser.find_or_create_by!(league_id: league1.id, user_id: user.id) do |lu|
    lu.score = rand(10..100)
  end
end

# league2: 20 users (alexei auto-added as owner)
league2_users = [
  alexei, boris, vadim, darya, elena, igor, julia, konstantin,
  larisa, mikhail, natasha, oleg, polina, roman, svetlana, timur,
  ulyana, viktor, xenia, yuri
]
league2_members = league2_users.map do |user|
  LeagueUser.find_or_create_by!(league_id: league2.id, user_id: user.id) do |lu|
    lu.score = rand(10..80)
  end
end

# Seasons
season1 = Season.create!(
  league:      league1,
  name:        "Сезон Весна 2026",
  date_from:   Date.new(2026, 1, 1),
  date_to:     Date.new(2026, 6, 30),
  description: "Весенний сезон Московской открытой лиги 2026"
)

season2 = Season.create!(
  league:      league2,
  name:        "Сезон Весна 2026",
  date_from:   Date.new(2026, 1, 1),
  date_to:     Date.new(2026, 6, 30),
  description: "Весенний сезон Питерской летней лиги 2026"
)

standard_points = [
  { "from" => 1,  "to" => 1,  "points" => 10 },
  { "from" => 2,  "to" => 2,  "points" => 8  },
  { "from" => 3,  "to" => 3,  "points" => 6  },
  { "from" => 4,  "to" => 7,  "points" => 4  },
  { "from" => 8,  "to" => 12, "points" => 2  }
]

# Tournaments
t_completed_1 = Tournament.create!(
  name:              "Весенний кубок 2026",
  league:            league1,
  start_date:        Date.new(2026, 3, 1),
  end_date:          Date.new(2026, 3, 3),
  max_participants:  16,
  club:              club_moscow_sport,
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
  max_participants:  16,
  club:              club_piter,
  type:              "olympic",
  status:            "completed",
  description:       "Завершённый зимний кубок Питерской лиги",
  placement_points:  standard_points
)

t_completed_3 = Tournament.create!(
  name:              "Апрельский кубок 2026",
  league:            league1,
  start_date:        Date.new(2026, 4, 5),
  end_date:          Date.new(2026, 4, 7),
  max_participants:  16,
  club:              club_dynamo_moscow,
  type:              "olympic",
  status:            "completed",
  description:       "Завершённый апрельский кубок Московской лиги",
  placement_points:  standard_points
)

t_completed_4 = Tournament.create!(
  name:              "Мартовский турнир Питера 2026",
  league:            league2,
  start_date:        Date.new(2026, 3, 15),
  end_date:          Date.new(2026, 3, 17),
  max_participants:  16,
  club:              club_piter,
  type:              "olympic",
  status:            "completed",
  description:       "Завершённый мартовский турнир Питерской лиги",
  placement_points:  standard_points
)

t_active = Tournament.create!(
  name:              "Майский турнир 2026",
  league:            league1,
  start_date:        Date.new(2026, 5, 20),
  end_date:          Date.new(2026, 5, 22),
  max_participants:  16,
  club:              club_luzhniki,
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
  max_participants:  16,
  club:              club_dynamo_moscow,
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
  max_participants:  16,
  club:              club_piter,
  type:              "olympic",
  status:            "registration",
  description:       "Открыта регистрация на главный летний турнир Питерской лиги",
  placement_points:  standard_points
)

t_active_olympic_loser = Tournament.create!(
  name:              "Кубок Москвы: Олимпик с утешительной 2026",
  league:            league1,
  start_date:        Date.new(2026, 5, 21),
  end_date:          Date.new(2026, 5, 23),
  max_participants:  16,
  club:              club_olimpiysky,
  type:              "olympic",
  status:            "active",
  loser_bracket:     true,
  description:       "Олимпийский турнир с утешительной сеткой, идёт первый раунд",
  placement_points:  standard_points
)

t_active_rr = Tournament.create!(
  name:              "Лига Москвы: Круговой турнир 2026",
  league:            league1,
  start_date:        Date.new(2026, 5, 15),
  end_date:          Date.new(2026, 5, 25),
  max_participants:  16,
  club:              club_dynamo_moscow,
  type:              "round_robin",
  status:            "active",
  description:       "Активный круговой турнир Московской лиги",
  placement_points:  standard_points
)

t_active_mixed = Tournament.create!(
  name:              "Микст-кубок Москвы 2026",
  league:            league1,
  start_date:        Date.new(2026, 5, 18),
  end_date:          Date.new(2026, 5, 24),
  max_participants:  16,
  club:              club_champion,
  type:              "mixed",
  status:            "active",
  groups_count:      2,
  pairs_to_bracket:  4,
  loser_bracket:     false,
  description:       "Групповой этап завершён, идёт плей-офф",
  placement_points:  standard_points
)

t_mixed_registration = Tournament.create!(
  name:              "Открытый микст Питера 2026",
  league:            league2,
  start_date:        Date.new(2026, 6, 15),
  end_date:          Date.new(2026, 6, 20),
  max_participants:  16,
  club:              club_piter,
  type:              "mixed",
  status:            "registration",
  groups_count:      2,
  pairs_to_bracket:  4,
  loser_bracket:     true,
  description:       "Регистрация открыта. Два группы, утешительная сетка для непрошедших.",
  placement_points:  standard_points
)

t_mixed_loser_bracket = Tournament.create!(
  name:              "Кубок чемпионов с утешительной сеткой 2026",
  league:            league1,
  start_date:        Date.new(2026, 5, 17),
  end_date:          Date.new(2026, 5, 21),
  max_participants:  16,
  club:              club_arena,
  type:              "mixed",
  status:            "active",
  groups_count:      2,
  pairs_to_bracket:  4,
  loser_bracket:     true,
  description:       "Групповой этап завершён, идут основная и утешительная сетки",
  placement_points:  standard_points
)

t_mixed_group_stage = Tournament.create!(
  name:              "Летний микст-турнир 2026",
  league:            league1,
  start_date:        Date.new(2026, 5, 19),
  end_date:          Date.new(2026, 5, 23),
  max_participants:  16,
  club:              club_olimp,
  type:              "mixed",
  status:            "active",
  groups_count:      2,
  pairs_to_bracket:  4,
  loser_bracket:     false,
  description:       "Идёт групповой этап, первый тур сыгран",
  placement_points:  standard_points
)

# All tournaments have max_participants: 16 (8 eligible pairs).
# Applied players range from 16 to 24 (8–12 pairs registered).

# completed_1 (league1): 20 players applied = 10 pairs
league1_members.first(20).each_slice(2).with_index do |(p1, p2), i|
  Pair.create!(tournament: t_completed_1, player1: p1, player2: p2, created_at: 80.days.ago + (i * 3).hours)
end

# completed_2 (league2): 18 players applied = 9 pairs
league2_members.first(18).each_slice(2).with_index do |(p1, p2), i|
  Pair.create!(tournament: t_completed_2, player1: p1, player2: p2, created_at: 100.days.ago + (i * 4).hours)
end

# completed_3 (league1): 20 players applied = 10 pairs
league1_members.first(20).each_slice(2).with_index do |(p1, p2), i|
  Pair.create!(tournament: t_completed_3, player1: p1, player2: p2, created_at: 60.days.ago + (i * 3).hours)
end

# completed_4 (league2): 16 players applied = 8 pairs
league2_members.first(16).each_slice(2).with_index do |(p1, p2), i|
  Pair.create!(tournament: t_completed_4, player1: p1, player2: p2, created_at: 70.days.ago + (i * 3).hours)
end

# active olympic (league1): 24 players applied = 12 pairs
league1_members.each_slice(2).with_index do |(p1, p2), i|
  Pair.create!(tournament: t_active, player1: p1, player2: p2, created_at: 20.days.ago + (i * 6).hours)
end

# draft (league1): 16 players applied = 8 pairs
league1_members.first(16).each_slice(2).with_index do |(p1, p2), i|
  Pair.create!(tournament: t_draft, player1: p1, player2: p2, created_at: 10.days.ago + (i * 5).hours)
end

# registration (league2): 22 players applied = 11 pairs
league2_members.first(22).each_slice(2).with_index do |(p1, p2), i|
  Pair.create!(tournament: t_registration, player1: p1, player2: p2, created_at: 5.days.ago + (i * 8).hours)
end

# active olympic with loser bracket (league1): 22 players applied = 11 pairs
league1_members.first(22).each_slice(2).with_index do |(p1, p2), i|
  Pair.create!(tournament: t_active_olympic_loser, player1: p1, player2: p2, created_at: 18.days.ago + (i * 5).hours)
end

# active round-robin (league1): 20 players applied = 10 pairs
league1_members.first(20).each_slice(2).with_index do |(p1, p2), i|
  Pair.create!(tournament: t_active_rr, player1: p1, player2: p2, created_at: 25.days.ago + (i * 5).hours)
end

# active mixed (league1): 22 players applied = 11 pairs
league1_members.first(22).each_slice(2).with_index do |(p1, p2), i|
  Pair.create!(tournament: t_active_mixed, player1: p1, player2: p2, created_at: 22.days.ago + (i * 4).hours)
end

# mixed registration (league2): 18 players applied = 9 pairs
league2_members.first(18).each_slice(2).with_index do |(p1, p2), i|
  Pair.create!(tournament: t_mixed_registration, player1: p1, player2: p2, created_at: 3.days.ago + (i * 10).hours)
end

# loser bracket mixed (league1): 24 players applied = 12 pairs
league1_members.each_slice(2).with_index do |(p1, p2), i|
  Pair.create!(tournament: t_mixed_loser_bracket, player1: p1, player2: p2, created_at: 23.days.ago + (i * 4).hours)
end

# mixed group stage (league1): 20 players applied = 10 pairs
league1_members.first(20).each_slice(2).with_index do |(p1, p2), i|
  Pair.create!(tournament: t_mixed_group_stage, player1: p1, player2: p2, created_at: 21.days.ago + (i * 3).hours)
end

# Helpers
def complete_match!(match, winner_pair, winner_score, loser_score)
  match.update!(
    pair1_score: match.pair1 == winner_pair ? winner_score : loser_score,
    pair2_score: match.pair2 == winner_pair ? winner_score : loser_score,
    winner:      winner_pair,
    status:      :completed
  )
  Tournaments::Matches::AdvanceWinnerService.new(match).call
end

# Assigns placements and awards points for a fully completed olympic tournament.
def assign_olympic_placements!(tournament)
  bracket = tournament.brackets.bracket.first
  return unless bracket

  max_round = bracket.matches.maximum(:round_number)

  final = bracket.matches.find_by(round_number: max_round, position: 1)
  if final&.completed?
    final.winner.update_column(:placement, 1)
    loser = ([ final.pair1, final.pair2 ].compact - [ final.winner ]).first
    loser&.update_column(:placement, 2)
  end

  if max_round >= 2
    bracket.matches.where(round_number: max_round - 1).order(:position).each_with_index do |match, i|
      next unless match.completed?
      loser = ([ match.pair1, match.pair2 ].compact - [ match.winner ]).first
      loser&.update_column(:placement, 3 + i)
    end
  end

  if max_round >= 3
    current_place = 5
    bracket.matches.where(round_number: max_round - 2).order(:position).each do |match|
      next unless match.completed?
      loser = ([ match.pair1, match.pair2 ].compact - [ match.winner ]).first
      loser&.update_column(:placement, current_place)
      current_place += 1
    end
  end

  tournament.pairs.reload.where.not(placement: nil).each do |pair|
    pts = tournament.points_for_place(pair.placement)
    next if pts.zero?
    pair.player1.increment!(:score, pts)
    pair.player2.increment!(:score, pts)
  end
end

# Fully completes an olympic tournament: assigns pairs, plays all rounds, sets placements.
def complete_olympic_tournament!(tournament)
  Tournaments::Matches::AutoAssignPairsService.new(tournament).call

  bracket = tournament.brackets.bracket.first
  return unless bracket

  max_round = bracket.matches.maximum(:round_number)
  (1..max_round).each do |round|
    bracket.matches.where(round_number: round).order(:position).each do |match|
      match.reload
      next if match.pair1.nil? || match.pair2.nil?
      complete_match!(match, match.pair1, 6, rand(2..4))
    end
  end

  assign_olympic_placements!(tournament)
end

# Complete all four finished tournaments
complete_olympic_tournament!(t_completed_1)
complete_olympic_tournament!(t_completed_2)
complete_olympic_tournament!(t_completed_3)
complete_olympic_tournament!(t_completed_4)

# Active tournaments — assign pairs then complete some rounds to simulate in-progress state

Tournaments::Matches::AutoAssignPairsService.new(t_active).call
t_active.matches.bracket.where(round_number: 1).order(:position).each do |match|
  match.reload
  next if match.pair1.nil? || match.pair2.nil?
  complete_match!(match, match.pair1, 6, rand(2..4))
end

Tournaments::Matches::AutoAssignPairsService.new(t_active_olympic_loser).call
t_active_olympic_loser.matches.bracket.where(round_number: 1).order(:position).each do |match|
  match.reload
  next if match.pair1.nil? || match.pair2.nil?
  winner = [ match.pair1, match.pair2 ].sample
  complete_match!(match.reload, winner, 6, rand(2..4))
end

Tournaments::Matches::AutoAssignPairsService.new(t_active_rr).call
t_active_rr.matches.bracket.where(round_number: 1..3).order(:position).each do |match|
  match.reload
  next if match.pair1.nil? || match.pair2.nil?
  winner = [ match.pair1, match.pair2 ].sample
  complete_match!(match, winner, 6, rand(2..5))
end

Tournaments::Matches::AutoAssignPairsService.new(t_mixed_loser_bracket).call
t_mixed_loser_bracket.matches.group_stage.order(:position).each do |match|
  match.reload
  next if match.pair1.nil? || match.pair2.nil?
  winner = [ match.pair1, match.pair2 ].sample
  complete_match!(match.reload, winner, 6, rand(2..4))
end
Tournaments::Matches::StartBracketService.new(t_mixed_loser_bracket.reload).call
t_mixed_loser_bracket.matches.bracket.where(round_number: 1).order(:position).each do |match|
  match.reload
  next if match.pair1.nil? || match.pair2.nil?
  complete_match!(match.reload, match.pair1, 6, rand(2..4))
end
t_mixed_loser_bracket.matches.loser_bracket.where(round_number: 1).order(:position).each do |match|
  match.reload
  next if match.pair1.nil? || match.pair2.nil?
  complete_match!(match.reload, match.pair1, 6, rand(2..4))
end

Tournaments::Matches::AutoAssignPairsService.new(t_active_mixed).call
t_active_mixed.matches.group_stage.order(:position).each do |match|
  match.reload
  next if match.pair1.nil? || match.pair2.nil?
  winner = [ match.pair1, match.pair2 ].sample
  complete_match!(match.reload, winner, 6, rand(2..4))
end
Tournaments::Matches::StartBracketService.new(t_active_mixed.reload).call
t_active_mixed.matches.bracket.where(round_number: 1).order(:position).each do |match|
  match.reload
  next if match.pair1.nil? || match.pair2.nil?
  complete_match!(match.reload, match.pair1, 6, rand(2..4))
end

Tournaments::Matches::AutoAssignPairsService.new(t_mixed_group_stage).call
t_mixed_group_stage.matches.group_stage.where(round_number: 1).order(:position).each do |match|
  match.reload
  next if match.pair1.nil? || match.pair2.nil?
  winner = [ match.pair1, match.pair2 ].sample
  complete_match!(match.reload, winner, 6, rand(2..4))
end

# Notifications
[ boris, vadim, darya ].each do |user|
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

puts "Seeded: #{User.count} users, #{Club.count} clubs, #{League.count} leagues, #{Season.count} seasons, #{Tournament.count} tournaments, #{Pair.count} pairs, #{Match.count} matches, #{Notification.count} notifications"
