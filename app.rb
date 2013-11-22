# app.rb

require 'sinatra'
require 'sinatra/activerecord'
require './environments'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'
require 'json'


enable :sessions


class Post < ActiveRecord::Base
  validates :title, presence: true, length: { minimum: 5 }
  validates :body, presence: true
end

class Company < ActiveRecord::Base
  

  validates :name, presence: true
  validates :address, presence: true
  validates :city, presence: true
  validates :country, presence: true


end
helpers do
  # helper for link_to,  
  def link_to(url,text=url,opts={})
  attributes = ""
    opts.each { |key,value| attributes << key.to_s << "=\"" << value << "\" "}
    "<a href=\"#{url}\" #{attributes}>#{text}</a>"
  end

  # helper for user delete call
  def delete_company_button(company_id)
    erb :_delete_company_button, locals: { company_id: company_id}
  end
end

['/', "/companies/*","/companies", "/companies/*/edit"].each do |path|
  before path do
    # create a empty response hash
    @response_service = {}
    @response_service[:status] = true
  end
end

helpers do
  def title
    if @title
      "#{@title}"
    else
      "Welcome."
    end
  end
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

# root URL for company
get '/' do
  @companies = Company.all
  if @companies
    @response_service[:data] = @companies
    @response_service[:message] = "Success" 
  else
    @response_service[:status] = false
    @response_service[:message] = "No Companies exist"
  end
  return @response_service.to_json  
end
get '/companies' do
  @companies = Company.all
  erb :"companies/index"
end

# Get the New company form
get '/companies/new' do
  @company = Company.new
  erb :"companies/new"
end

# Create company date and render to company details page(index)
post '/companies' do  
  @company = Company.new((params[:company]))
 if params[:passport] && (tmpfile = params[:passport][:tempfile]) && (name = params[:passport][:filename])
    directory = "public/passport"
    path = File.join(directory, name)
    if File.extname(path)!=".pdf"
      @response_service[:status] = false
      @response_service[:message] = "Please select a pdf file"
      return @response_service.to_json
    else
      @company.passport = path
    end
  end

  if @company.save    
    File.open(path, "wb") { |f| f.write(tmpfile.read) } unless path.nil?
    @response_service[:message] = "You have successfully created a company." 
    return @response_service.to_json
  else  
    @response_service[:status] = false
    @response_service[:message] = "Company not created successfully due to following reason #{@company.errors.full_messages.join(',')}"
    return @response_service.to_json
  end
end

# Deletes the company with this ID and redirects to homepage.
get "/companies/:id" do
  @company = Company.find((params[:id]))
  if @company
    @response_service[:data] = @company
    @response_service[:message] = "Success" 
  else
    @response_service[:status] = false
    @response_service[:message] = "User not exist"
  end
  return @response_service.to_json
  # APP_ROOT = File.dirname(__FILE__)
  # erb :'companies/show'
end

# Deletes the company with this ID and redirects to homepage.
delete "/companies/:id" do
  @company = Company.find(params[:id])
  if @company.destroy
    @response_service[:data] = @company
    @response_service[:message] = "Successfully deleted company." 
    # flash[:success] = "Company successfully deleted."
    # redirect '/'
  else
    @response_service[:status] = false
    @response_service[:message] = "Company does not exist"
    # flash[:error] = "Company not deleted."
    # redirect '/'
  end
end
 
get '/companies/:id/edit' do
  @company = Company.find(params[:id])
  if @company
    @response_service[:data] = @company
    @response_service[:message] = "Success" 
  else
    @response_service[:status] = false
    @response_service[:message] = "User not exist"
  end
  #return @response_service.to_json
  erb :'companies/edit'
end

put '/companies/:id' do
  
  @company = Company.find(params[:id])
  if params[:passport] && (tmpfile = params[:passport][:tempfile]) && (name = params[:passport][:filename])
    directory = "public/passport"
    path = File.join(directory, name)
    if File.extname(path)!=".pdf"
      @response_service[:status] = false
      @response_service[:message] = "Please select a pdf file"
      return @response_service.to_json
      # flash[:error] = "Please select a pdf file"
      # return erb :"companies/edit"
    else
      @company.passport = path
    end
  end
  if @company.update_attributes(params[:company]) 
    File.open(path, "wb") { |f| f.write(tmpfile.read) } unless path.nil?
    @response_service[:message] = "You have successfully updated a company." 
    return @response_service.to_json
    # flash[:success] = "Company successfully updated"
    # erb :'companies/show'
  else  
    @response_service[:status] = false
    @response_service[:message] = "Company not created successfully due to following reason #{@company.errors.full_messages.join(',')}"
    return @response_service.to_json
  end
end

get '/download_file/*' do
  send_file(File.expand_path(params[:splat].join(''), settings.public_folder+"/passport"))
end

# create new post
get "/posts/create" do
  @title = "Create post"
  @post = Post.new
  erb :"posts/create"
end
post "/posts" do
  @post = Post.new(params[:post])
  if @post.save
    redirect "posts/#{@post.id}", :notice => 'Congrats! Love the new post. (This message will disapear in 4 seconds.)'
  else
    redirect "posts/create", :error => 'Something went wrong. Try again. (This message will disapear in 4 seconds.)'
  end
end

# view post
get "/posts/:id" do
  @post = Post.find(params[:id])
  @title = @post.title
  erb :"posts/view"
end

# edit post
get "/posts/:id/edit" do
  @post = Post.find(params[:id])
  @title = "Edit Form"
  erb :"posts/edit"
end
put "/posts/:id" do
  @post = Post.find(params[:id])
  @post.update(params[:post])
  redirect "/posts/#{@post.id}"
end
