class SessionsController < ApplicationController
  before_action :increment_view_count, :current_user, :db_user, :blogs, :current_blog, :guests, only: :index
  helper_method :current_user, :logged_in?, :db_user, :current_blog

  def index
    current_blog params[:blog]
  end


  def create
    session[:info] = request.env['omniauth.auth']['info']

    session[:user_id] = request.env['omniauth.auth']['uid']

    session[:user_token] = request.env['omniauth.auth']['credentials']['token']
    session[:user_secret] = request.env['omniauth.auth']['credentials']['secret']
    session[:consumer_key] = request.env['omniauth.auth']['extra']['access_token'].as_json['consumer'].as_json['key']
    session[:consumer_secret] = request.env['omniauth.auth']['extra']['access_token'].as_json['consumer'].as_json['secret']

    increment_view_count

    current_user
    redirect_to action: 'index'
  end

  def failure
    render :text => 'FAILURE :-('
  end

  def increment_view_count
    unless logged_in?
      return
    end

    if db_user
      db_user.views_count = db_user.views_count + 1
      db_user.save
    else
      @db_user = User.create(name: session[:user_id], views_count: 1)
    end
  end

  def current_user
    unless logged_in?
      return
    end

    Tumblr.configure do |config|
      config.consumer_key = session[:consumer_key]
      config.consumer_secret = session[:consumer_secret]
      config.oauth_token = session[:user_token]
      config.oauth_token_secret = session[:user_secret]
    end
    @client = Tumblr::Client.new(:client => :httpclient)
    @current_user = @client.info['user']
  end

  def db_user
    @db_user ||= User.find_by_name session[:user_id]
  end

  def current_blog(name='')
    unless logged_in?
      return
    end

    @blogs.each do |b|
      if name
        b['current'] = b['name'] == name
      end
      @current_blog = b if b['current']
    end

    unless @current_blog
      @current_blog = @blogs[0]
      @current_blog['current'] = true
    end
  end

  def blogs
    unless logged_in?
      return
    end
    @current_user['blogs'].each do |new_blog|
      new_blog['notes'] = 0
      posts = @client.posts(new_blog['name'], notes_info: true, reblog_info: true)['posts']
      posts.each do |p|
        if p['reblogged_from_id']
          p['repost_note_count'] = @client.posts(p['reblogged_from_name'], id: p['reblogged_from_id'])['posts'][0]['note_count']
          p['note_count'] = p['note_count'].to_i - p['repost_note_count'].to_i
        end

        new_blog['notes'] = new_blog['notes'] + p['note_count'].to_i
      end

      blog = Blog.find_by_name new_blog['name']
      unless blog
        blog = Blog.new(name: new_blog['name'], notes: new_blog['notes'], followers: new_blog['followers'], posts: new_blog['posts'], queue: new_blog['queue'])
        blog.user = User.find_by_name @current_user['name']
        blog.save
      end

      %w(notes, followers, posts, queue).each do |param|
        new_blog['prev_' + param] = blog[param]
      end
    end
    @blogs ||= @current_user['blogs']
  end

  def logged_in?
    session[:user_id] != nil
  end

  def guests
    @guests ||= User.limit 10
  end

end
