# == Schema Information
#
# Table name: pairs
#
#  id            :bigint           not null, primary key
#  placement     :integer
#  player1_score :integer          default(0), not null
#  player2_score :integer          default(0), not null
#  seeded        :boolean          default(FALSE), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  player1_id    :bigint           not null
#  player2_id    :bigint           not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_pairs_on_player1_id     (player1_id)
#  index_pairs_on_player2_id     (player2_id)
#  index_pairs_on_tournament_id  (tournament_id)
#
# Foreign Keys
#
#  fk_rails_...  (player1_id => league_users.id)
#  fk_rails_...  (player2_id => league_users.id)
#  fk_rails_...  (tournament_id => tournaments.id)
#
class Pair < ApplicationRecord
  belongs_to :player1, class_name: "LeagueUser"
  belongs_to :player2, class_name: "LeagueUser"
  belongs_to :tournament

  has_many :matches_as_pair1, class_name: "Match", foreign_key: :pair1_id, dependent: :destroy
  has_many :matches_as_pair2, class_name: "Match", foreign_key: :pair2_id, dependent: :destroy
  has_many :won_matches, class_name: "Match", foreign_key: :winner_id, dependent: :nullify

  has_one_attached :photo

  before_create :snapshot_player_scores
  after_create :inherit_photo_from_league_history
  after_update :inherit_photo_from_league_history, if: :player_ids_changed?

  validate :players_must_be_different
  validate :each_player_once_per_tournament

  def score
    player1_score + player2_score
  end

  def partner_for(league_user_ids)
    league_user_ids.include?(player1_id) ? player2 : player1
  end

  private

  def player_ids_changed?
    saved_change_to_player1_id? || saved_change_to_player2_id?
  end

  def inherit_photo_from_league_history
    return if photo.attached?

    matching_pair = Pair
      .with_attached_photo
      .joins(:tournament)
      .where(tournaments: { league_id: tournament.league_id })
      .where.not(tournament_id: tournament_id)
      .where(
        "(player1_id = :p1 AND player2_id = :p2) OR (player1_id = :p2 AND player2_id = :p1)",
        p1: player1_id, p2: player2_id
      )
      .order(created_at: :desc)
      .first

    photo.attach(matching_pair.photo.blob) if matching_pair
  end

  def snapshot_player_scores
    self.player1_score = player1.score
    self.player2_score = player2.score
  end

  def players_must_be_different
    errors.add(:player2, "не может совпадать с игроком 1") if player1_id.present? && player1_id == player2_id
  end

  def each_player_once_per_tournament
    return unless tournament_id.present?
    return if tournament&.americano?

    occupied = Pair.where(tournament_id: tournament_id)
                   .where.not(id: id)
                   .where("player1_id IN (?) OR player2_id IN (?)", [ player1_id, player2_id ], [ player1_id, player2_id ])
    errors.add(:base, "один из игроков уже зарегистрирован на этот турнир") if occupied.exists?
  end
end
