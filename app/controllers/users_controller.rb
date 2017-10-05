# frozen_string_literal: true
class UsersController < ApplicationController
  before_action :ensure_correct_user

  # Return a user profile. Only shows the current user
  #
  # ==== Example
  #
  # GET users/profile.json
  # {
  #    "user" : {
  #       "id" : 1,
  #       "github_id" : 3074765,
  #       "github_login" : "jules2689",
  #       "last_synced_at" : "2017-02-22T15:49:32.104Z",
  #       "created_at" : "2017-02-22T15:49:32.099Z",
  #       "updated_at" : "2017-02-22T15:49:32.099Z"
  #    }
  # }
  def profile; end

  def edit;
    # check if api token associated if not add it
    # add the api_keys on demands
    if !current_user.api_key
      current_user.generate_api_key()
    end
  end

  # Update a user profile. Only updates the current user
  #
  # * +:personal_access_token+ - The user's personal access token
  # * +:refresh_interval+ - The refresh interval on which a sync should be initiated (while viewing the app). In milliseconds.
  #
  # ==== Example
  #
  # PATCH users/:id.json
  # { "user" : { "refresh_interval" : 60000 } }
  # HEAD OK
  #
  def update
    if current_user.update_attributes(update_user_params)
      respond_to do |format|
        format.html { redirect_to root_path }
        format.json { head :ok }
      end
    else
      respond_to do |format|
        format.html do
          flash[:error] = 'Could not update your account'
          flash[:alert] = current_user.errors.full_messages.to_sentence
          redirect_to :settings
        end
        format.json { render json: { errors: current_user.errors.full_messages.to_sentence }, status: :unprocessable_entity }
      end
    end
  end

  # Delete your user profile. Only can delete the current user
  #
  # ==== Example
  #
  # DELETE users/:id.json
  # HEAD OK
  #
  def destroy
    user = User.find(current_user.id)
    github_login = user.github_login
    user.destroy

    respond_to do |format|
      format.html do
        flash[:success] = "User deleted: #{github_login}"
        redirect_to root_path
      end
      format.json { head :ok }
    end
  end

  private

  def ensure_correct_user
    return unless params[:id]
    head :unauthorized unless current_user.id.to_s == params[:id]
  end

  def update_user_params
    if params[:user].has_key? :refresh_interval_minutes
      params[:user][:refresh_interval] = params[:user][:refresh_interval_minutes].to_i * 60_000
    end

    # If the user changes nothing in the form, personal_access_token will be blank.  In that case we don't want to update it.
    if params[:user][:personal_access_token].blank?
      params[:user][:personal_access_token] = current_user.personal_access_token if params[:user][:personal_access_token].blank?
    end

    # No matter what is in the personal_access_token field, we want it cleared if the checkbox is checked
    if params.has_key?('clear_personal_access_token')
      params[:user][:personal_access_token] = nil
    end

    params.require(:user).permit(:personal_access_token, :refresh_interval)
  end
end
