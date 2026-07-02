require "rails_helper"
require "rake"

RSpec.describe "users:merge_duplicates rake task", type: :task do
  before(:all) do
    Rake.application.rake_require("tasks/merge_duplicate_users")
    Rake::Task.define_task(:environment)
  end

  before { Rake::Task["users:merge_duplicates"].reenable }

  def run_task(dry_run: true)
    ENV["DRY_RUN"] = dry_run ? "true" : "false"
    Rake::Task["users:merge_duplicates"].invoke
  ensure
    ENV.delete("DRY_RUN")
  end

  def create_duplicate(first_name:, last_name:, **attrs)
    create(:user, first_name: first_name, last_name: last_name, **attrs)
  end

  describe "dry run (default)" do
    it "does not merge users when DRY_RUN is true" do
      create_duplicate(first_name: "John", last_name: "Doe")
      create_duplicate(first_name: "John", last_name: "Doe")

      expect { run_task(dry_run: true) }.not_to change(User, :count)
    end
  end

  describe "live run" do
    context "with two users sharing the same name" do
      let!(:primary) do
        create_duplicate(first_name: "Alice", last_name: "Smith",
                         remember_created_at: Time.current)
      end
      let!(:duplicate) do
        create_duplicate(first_name: "Alice", last_name: "Smith")
      end

      it "deletes the duplicate user" do
        expect { run_task(dry_run: false) }.to change(User, :count).by(-1)
        expect(User.exists?(duplicate.id)).to be false
        expect(User.exists?(primary.id)).to be true
      end
    end

    context "primary selection: prefers user with remember_created_at" do
      let!(:with_remember) do
        create_duplicate(first_name: "Bob", last_name: "Jones",
                         remember_created_at: 1.day.ago)
      end
      let!(:without_remember) do
        create_duplicate(first_name: "Bob", last_name: "Jones")
      end

      it "keeps the user with remember_created_at" do
        run_task(dry_run: false)
        expect(User.exists?(with_remember.id)).to be true
        expect(User.exists?(without_remember.id)).to be false
      end
    end

    context "primary selection: prefers accepted invite over pending" do
      let!(:accepted) do
        create_duplicate(first_name: "Carol", last_name: "White",
                         invitation_token: nil)
      end
      let!(:pending_invite) do
        create_duplicate(first_name: "Carol", last_name: "White",
                         invitation_token: SecureRandom.hex)
      end

      it "keeps the accepted user" do
        run_task(dry_run: false)
        expect(User.exists?(accepted.id)).to be true
        expect(User.exists?(pending_invite.id)).to be false
      end
    end

    context "reassigning league_users" do
      let(:league) { create(:league) }
      let!(:primary) { create_duplicate(first_name: "Dave", last_name: "Brown", remember_created_at: Time.current) }
      let!(:duplicate) { create_duplicate(first_name: "Dave", last_name: "Brown") }
      let!(:dup_lu) { create(:league_user, user: duplicate, league: league) }

      it "moves league_user to primary user" do
        run_task(dry_run: false)
        expect(dup_lu.reload.user_id).to eq(primary.id)
      end
    end

    context "when primary already belongs to the same league" do
      let(:league) { create(:league) }
      let!(:primary) { create_duplicate(first_name: "Eve", last_name: "Davis", remember_created_at: Time.current) }
      let!(:duplicate) { create_duplicate(first_name: "Eve", last_name: "Davis") }
      let!(:primary_lu) { create(:league_user, user: primary, league: league) }
      let!(:dup_lu) { create(:league_user, user: duplicate, league: league) }

      it "removes the duplicate league_user" do
        run_task(dry_run: false)
        expect(LeagueUser.exists?(dup_lu.id)).to be false
        expect(LeagueUser.exists?(primary_lu.id)).to be true
      end
    end

    context "reassigning owned leagues" do
      let!(:primary) { create_duplicate(first_name: "Frank", last_name: "Green", remember_created_at: Time.current) }
      let!(:duplicate) { create_duplicate(first_name: "Frank", last_name: "Green") }
      let!(:owned_league) { create(:league, owner: duplicate) }

      it "transfers league ownership to primary" do
        run_task(dry_run: false)
        expect(owned_league.reload.owner_id).to eq(primary.id)
      end
    end

    context "when no duplicates exist" do
      it "does not change user count" do
        create(:user, first_name: "Unique", last_name: "Person")
        expect { run_task(dry_run: false) }.not_to change(User, :count)
      end
    end
  end
end
