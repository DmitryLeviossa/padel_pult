require "test_helper"

class TournamentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = users(:one)
    @other_user = users(:two)
    @draft_tournament = tournaments(:draft)
    @active_tournament = tournaments(:active)
  end

  test "owner can access edit for draft tournament" do
    sign_in @owner
    get edit_tournament_path(@draft_tournament)
    assert_response :success
  end

  test "owner is redirected from edit for non-draft tournament" do
    sign_in @owner
    get edit_tournament_path(@active_tournament)
    assert_redirected_to tournament_path(@active_tournament)
  end

  test "non-owner cannot access edit" do
    sign_in @other_user
    get edit_tournament_path(@draft_tournament)
    assert_redirected_to league_path(@draft_tournament.league)
  end

  test "unauthenticated user cannot access edit" do
    get edit_tournament_path(@draft_tournament)
    assert_redirected_to new_user_session_path
  end

  test "owner can update draft tournament" do
    sign_in @owner
    patch tournament_path(@draft_tournament), params: {
      tournament: { name: "Updated Name" }
    }
    assert_redirected_to tournament_path(@draft_tournament)
    assert_equal "Updated Name", @draft_tournament.reload.name
  end

  test "owner cannot update non-draft tournament" do
    sign_in @owner
    original_name = @active_tournament.name
    patch tournament_path(@active_tournament), params: {
      tournament: { name: "Changed" }
    }
    assert_redirected_to tournament_path(@active_tournament)
    assert_equal original_name, @active_tournament.reload.name
  end

  test "non-owner cannot update tournament" do
    sign_in @other_user
    original_name = @draft_tournament.name
    patch tournament_path(@draft_tournament), params: {
      tournament: { name: "Changed" }
    }
    assert_redirected_to league_path(@draft_tournament.league)
    assert_equal original_name, @draft_tournament.reload.name
  end

  test "update re-renders edit on validation failure" do
    sign_in @owner
    patch tournament_path(@draft_tournament), params: {
      tournament: { placement_points: [ { from: 0, to: 0, points: 0 } ] }
    }
    assert_response :unprocessable_entity
  end
end
