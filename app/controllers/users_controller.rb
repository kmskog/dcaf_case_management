# Additional user methods in parallel with Devise -- all pertaining to call list
class UsersController < ApplicationController
  before_action :retrieve_patients, only: [:add_patient, :remove_patient]
  before_action :confirm_admin_user, only: [:new, :index, :update]
  before_action :confirm_admin_user_async, only: [:search]
  before_action :find_user, only: [:update, :edit, :destroy, :reset_password]

  rescue_from Mongoid::Errors::DocumentNotFound, with: -> { head :not_found }
  rescue_from Exceptions::UnauthorizedError, with: -> { head :unauthorized }

  def index
    @users = User.all
  end

  def edit; end

  def search
    @results = if params[:search].empty?
                 User.all
               else
                 User.search params[:search]
               end
    respond_to { |format| format.js }
  end

  def new
    @user = User.new
    session[:return_to] ||= request.referer
  end

  def update
    if @user.update_attributes user_params
      flash[:notice] = 'Successfully updated user details'
      redirect_to users_path
    else
      error_content = @user.errors.full_messages.to_sentence
      flash[:alert] = "Error saving user details - #{error_content}"
      render 'edit'
    end
  end

  def create
    raise Exceptions::UnauthorizedError unless current_user.admin?
    @user = User.new(user_params)
    hex = SecureRandom.urlsafe_base64
    @user.password, @user.password_confirmation = hex
    if @user.save
      flash[:notice] = 'User created!'
      redirect_to users_path
    else
      render 'new'
    end
  end

  # def toggle_lock
  #   # @user = User.find(params[:user_id])
  #   # if @user == current_user
  #   #   redirect_to edit_user_path @user
  #   # else
  #   #   if @user.access_locked?
  #   #     flash[:notice] = 'Successfully unlocked ' + @user.email
  #   #     @user.unlock_access!
  #   #   else
  #   #     flash[:notice] = 'Successfully locked ' + @user.email
  #   #     @user.lock_access!
  #   #   end
  #   #   redirect_to edit_user_path @user
  #   # end
  # end

  # # TODO find_user tweaking.
  # def reset_password
  #   # @user = User.find(params[:user_id])

  #   # TODO doesn't work in dev
  #   @user.send_reset_password_instructions

  #   flash[:notice] = "Successfully sent password reset instructions to #{@user.email}"
  #   redirect_to edit_user_path @user
  # end

  def add_patient
    current_user.add_patient @patient
    respond_to do |format|
      format.js { render template: 'users/refresh_patients', layout: false }
    end
  end

  def remove_patient
    current_user.remove_patient @patient
    respond_to do |format|
      format.js { render template: 'users/refresh_patients', layout: false }
    end
  end

  def clear_current_user_call_list
    current_user.clear_call_list
    respond_to do |format|
      format.js { render template: 'users/refresh_patients', layout: false }
    end
  end

  def reorder_call_list
    # TODO: fail if anything is not a BSON id
    current_user.reorder_call_list params[:order] # TODO: adjust to payload
    # respond_to { |format| format.js }
    head :ok
  end

  private

  def find_user # TODO needs more rigorous testing
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :role)
  end

  def retrieve_patients
    @patient = Patient.find params[:id]
    @urgent_patient = Patient.where(urgent_flag: true)
  end
end
