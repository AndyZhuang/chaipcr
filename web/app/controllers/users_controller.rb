#
# Chai PCR - Software platform for Open qPCR and Chai's Real-Time PCR instruments.
# For more information visit http://www.chaibio.com
#
# Copyright 2016 Chai Biotechnologies Inc. <info@chaibio.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
class UsersController < ApplicationController
  before_filter :ensure_authenticated_user, :except => :create

  respond_to :json

  resource_description {
    formats ['json']
    description "all the actions only allowed if admin user logged in, otherwise response code 401 will be returned"
  }

  def_param_group :user do
    param :user, Hash, :desc => "User Info", :required => true do
      param :name, String, :desc => "User Name", :required => true
      param :email, String, :desc => "User Email", :required => true
      param :password, String, :desc => "User Password", :required => true, :action_aware => true
      param :password_confirmation, String, :desc => "User Password Confirmation", :required => true, :action_aware => true
      param :role, ["admin", "user"], :desc => "User Role", :required => false
     end
  end

  api :GET, "/users", "List all the users"
  example "[{'user':{'id':1,'name':'admin','email':'admin@admin.com','role':'admin'}}]"
  def index
    @users = User.all
    respond_to do |format|
      format.json { render "index", :status => :ok }
    end
  end

  api :GET, "/users/:id or /users/current", "show user with id or current user info"
  example "[{'user':{'id':1,'name':'test','email':'test@test.com','role':'user'}}]"
  def show
    if params[:id] == "current"
      @user = current_user
    else
      @user = User.find_by_id(params[:id])
    end
    respond_to do |format|
      format.json { render "show", :status => :ok}
    end
  end

  api :POST, "/users", "Create an user"
  param_group :user
  example "[{'user':{'id':1,'name':'test','email':'test@test.com','role':'user'}}]"
  def create
    if (User.empty? && params[:user][:role] == "admin") || ensure_authenticated_user
      @user = User.new(user_params)
      ret = @user.save
      respond_to do |format|
        format.json { render "show", :status => (ret)? :ok : :unprocessable_entity}
      end
    end
  end

  api :PUT, "/users/:id", "Update an user"
  param_group :user
  example "[{'user':{'id':1,'name':'test','email':'test@test.com','role':'user'}}]"
  def update
    @user = User.find_by_id(params[:id])
    ret  = @user.update_attributes(user_params)
    respond_to do |format|
      format.json { render "show", :status => (ret)? :ok : :unprocessable_entity}
    end
  end

  api :DELETE, "/users/:id", "Destroy an user"
  def destroy
    @user = User.find_by_id(params[:id])
    if @user == current_user
      ret = false
      @user.errors.add(:base, "cannot destroy yourself")
    else
      ret = @user.destroy
    end
    respond_to do |format|
      format.json { render "destroy", :status => (ret)? :ok : :unprocessable_entity}
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
  end

  def authorized?
    request.method == "GET" || current_user.admin? || (params[:action] == "update" && current_user.id == params[:id].to_i)
  end
end