# Merges duplicate user accounts that share the same first_name + last_name.
#
# Primary user selection priority:
#   1. User with remember_created_at (actually signed in with remember_me)
#   2. User without invitation_token (accepted invite or self-registered)
#   3. Oldest user (lowest created_at)
#
# Usage:
#   bin/rails users:merge_duplicates           # dry run – shows what would happen
#   bin/rails users:merge_duplicates DRY_RUN=false  # live run

namespace :users do
  desc "Merge duplicate users by name (dry run by default, set DRY_RUN=false to execute)"
  task merge_duplicates: :environment do
    dry_run = ENV["DRY_RUN"] != "false"
    puts "=== Merge duplicate users (#{dry_run ? 'DRY RUN' : 'LIVE'}) ==="

    duplicate_groups = User
      .group(:first_name, :last_name)
      .having("COUNT(*) > 1")
      .pluck(:first_name, :last_name)

    if duplicate_groups.empty?
      puts "No duplicate users found."
      next
    end

    puts "Found #{duplicate_groups.size} duplicate name group(s)\n\n"
    merged = 0
    errors = 0

    duplicate_groups.each do |first_name, last_name|
      users = User.where(first_name: first_name, last_name: last_name).order(:created_at)

      primary = users.min_by do |u|
        [
          u.remember_created_at ? 0 : 1,
          u.invitation_token.nil? ? 0 : 1,
          u.created_at
        ]
      end

      duplicates = users.reject { |u| u.id == primary.id }

      puts "Group: #{first_name} #{last_name} (#{users.count} users)"
      users.each do |u|
        marker = u.id == primary.id ? "PRIMARY" : "MERGE  "
        logged_in = u.remember_created_at ? "logged_in" : (u.invitation_token.nil? ? "accepted" : "pending")
        puts "  [#{marker}] id=#{u.id} email=#{u.email} #{logged_in} created=#{u.created_at.strftime('%Y-%m-%d')}"
      end

      duplicates.each do |dup|
        begin
          merge_users(primary, dup, dry_run)
          merged += 1
          puts "  => Merged user ##{dup.id} into ##{primary.id}#{dry_run ? ' (dry run)' : ''}"
        rescue => e
          errors += 1
          puts "  => ERROR merging user ##{dup.id}: #{e.message}"
        end
      end
      puts
    end

    puts "=== Done: #{merged} user(s) merged#{dry_run ? ' (dry run)' : ''}, #{errors} error(s) ==="
  end

  def merge_users(primary, duplicate, dry_run)
    ActiveRecord::Base.transaction do
      # --- league_users ---
      duplicate.league_users.each do |dup_lu|
        primary_lu = primary.league_users.find_by(league_id: dup_lu.league_id)

        if primary_lu
          # Primary already belongs to this league – redirect all references to primary's league_user
          puts "    league_id=#{dup_lu.league_id}: primary already member, redirecting references from lu##{dup_lu.id} to lu##{primary_lu.id}"

          unless dry_run
            # tournament_participants: skip if primary already participates in same tournament
            TournamentParticipant.where(league_user_id: dup_lu.id).find_each do |tp|
              if TournamentParticipant.exists?(tournament_id: tp.tournament_id, league_user_id: primary_lu.id)
                tp.delete
              else
                tp.update_column(:league_user_id, primary_lu.id)
              end
            end

            Pair.where(player1_id: dup_lu.id).update_all(player1_id: primary_lu.id)
            Pair.where(player2_id: dup_lu.id).update_all(player2_id: primary_lu.id)

            dup_lu.delete
          end
        else
          # Primary not in this league – move league_user to primary
          puts "    league_id=#{dup_lu.league_id}: reassigning lu##{dup_lu.id} to user##{primary.id}"
          dup_lu.update_column(:user_id, primary.id) unless dry_run
        end
      end

      # --- leagues owned by duplicate ---
      owned_leagues = League.where(owner_id: duplicate.id)
      if owned_leagues.any?
        puts "    Reassigning #{owned_leagues.count} owned league(s) to user##{primary.id}"
        owned_leagues.update_all(owner_id: primary.id) unless dry_run
      end

      # --- notifications ---
      notif_count = duplicate.notifications.count
      puts "    Reassigning #{notif_count} notification(s) to user##{primary.id}" if notif_count > 0
      duplicate.notifications.update_all(user_id: primary.id) unless dry_run

      # --- league_invitations ---
      duplicate.received_league_invitations.each do |inv|
        if LeagueInvitation.exists?(league_id: inv.league_id, invited_user_id: primary.id)
          puts "    Dropping duplicate invitation for league_id=#{inv.league_id}"
          inv.delete unless dry_run
        else
          puts "    Reassigning invitation for league_id=#{inv.league_id} to user##{primary.id}"
          inv.update_column(:invited_user_id, primary.id) unless dry_run
        end
      end

      # --- delete duplicate user ---
      puts "    Deleting user##{duplicate.id} (#{duplicate.email})"
      duplicate.delete unless dry_run

      raise ActiveRecord::Rollback if dry_run
    end
  end
end
