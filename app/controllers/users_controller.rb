class UsersController < ApplicationController
  # this method has a key and secret which is in the api server database as a client application.
  def self.consumer
    OAuth::Consumer.new("PGpv3jXSDphjXzP8AROzjA", "ldrrmQ3pEy6JUvNjKq9iDA3hhAns4RNEuU55EUBU", {:site => 'https://api.livework.com'})
  end

  # create a new user locally which has request information associated with it. Will direct the API server to hit the
  # callback method after this is successful.
  def create
    @request_token = UsersController.consumer.get_request_token
    session[:request_token] = @request_token.token
    session[:request_token_secret] = @request_token.secret
    redirect_to @request_token.authorize_url
  end

  # this method is called upon successfully authorizing the use of the client application. This method saves the newly
  # created user in the database as well as in your browser's cookies. You'll need that cookie to do other things. Like
  # have a nice scrumptious snack.
  def callback
    @request_token = OAuth::RequestToken.new(UsersController.consumer, session[:request_token], session[:request_token_secret])
    @access_token = @request_token.get_access_token
    @response = UsersController.consumer.request(:get, '/oauth/verify_credentials', @access_token, {:scheme => :query_string})

    case @response
    when Net::HTTPSuccess
      user_info = JSON.parse(@response.body)
      unless user_info['username']
        flash[:notice] = 'authentication failed'
        redirect_to :action => :index
        return
      end

      @user = User.new(:username => user_info['username'], :token => @access_token.token, :secret => @access_token.secret)
      @user.save!
      session['user'] = @user.username
      render :text => @user.to_json
    else
      # failure
      flash[:notice] = 'authentication failed'
      redirect_to :action => :index
      return
    end
  end

  # creates a project on the API server via the API. This project should be valid, if it isn't then you'll be sad and
  # confused. If you change category_id to 1 for example, then this project won't be created because validations won't
  # pass.
  # http://developer.livework.com/LiveWork-API-Method%3A-projects-create
  def create_project
    @user = User.find_by_username(session['user'])
    @access_token = OAuth::AccessToken.new(UsersController.consumer, @user.token, @user.secret)
    @response = UsersController.consumer.request(:post, '/api/v1/projects.xml', @access_token, {:scheme => :query_string},
                                                 {'project[title]' => 'Valid Project',
                                                  'project[category_id]' => 10,
                                                  'project[description]' => 'The most valid project you have ever seen!',
                                                  'project[requirements]' => 'Lots of validity.',
                                                  'project[start_date]' => Time.now,
                                                  'project[max_experts]' => 5,
                                                  'project[expert_fixed]' => 10})
    render :xml => @response.body
  end

  # Updates a project that you have the ability to modify.
  # http://developer.livework.com/LiveWork-API-Method%3A-projects-update
  def update_project
    @user = User.find_by_username(session['user'])
    @access_token = OAuth::AccessToken.new(UsersController.consumer, @user.token, @user.secret)
    @response = UsersController.consumer.request(:put, "/api/v1/projects/#{params[:id]}.xml", @access_token, {:scheme => :query_string},
                                                 {'project[title]' => 'Updated Valid Project'})
    render :xml => @response.body
  end

  # Gets details about a project
  # http://developer.livework.com/LiveWork-API-Method%3A-projects-show
  def show_project
    @user = User.find_by_username(session['user'])
    @access_token = OAuth::AccessToken.new(UsersController.consumer, @user.token, @user.secret)
    @response = UsersController.consumer.request(:get, "/api/v1/projects/#{params[:id]}.xml", @access_token, {:scheme => :query_string})
    render :xml => @response.body
  end

  # Gets details about a task
  # http://developer.livework.com/LiveWork-API-Method%3A-tasks-show
  def show_task
    @user = User.find_by_username(session['user'])
    @access_token = OAuth::AccessToken.new(UsersController.consumer, @user.token, @user.secret)
    @response = UsersController.consumer.request(:get, "/api/v1/tasks/#{params[:id]}.xml", @access_token, {:scheme => :query_string})
    render :xml => @response.body
  end

  # Creates a task with given task parameters -- you probably want to change project_id to be a project you created
  # http://developer.livework.com/LiveWork-API-Method%3A-tasks-create
  def create_task
    @user = User.find_by_username(session['user'])
    @access_token = OAuth::AccessToken.new(UsersController.consumer, @user.token, @user.secret)
    @response = UsersController.consumer.request(:post, "/api/v1/tasks.xml", @access_token, {:scheme => :query_string},
                                                 {'task[title]' => 'Valid Task',
                                                  'task[description]' => 'The most valid task you have ever seen!',
                                                  'task[project_id]' => 222, # try putting your project_id here (if you've created a project)
                                                  'task[priority]' => 2,
                                                  'task[managed_by]' => 2,
                                                  'task[due_date]' => Time.now})
    render :xml => @response.body
  end

  # Updates a task with given task parameters
  # http://developer.livework.com/LiveWork-API-Method%3A-tasks-update
  def update_task
    @user = User.find_by_username(session['user'])
    @access_token = OAuth::AccessToken.new(UsersController.consumer, @user.token, @user.secret)
    @response = UsersController.consumer.request(:put, "/api/v1/tasks/#{params[:id]}.xml", @access_token, {:scheme => :query_string},
                                                 {'task[title]' => 'Updated Valid Task'})
    render :xml => @response.body
  end

  # Accepts a task
  # http://developer.livework.com/LiveWork-API-Method%3A-tasks-accept
  def accept_task
    @user = User.find_by_username(session['user'])
    @access_token = OAuth::AccessToken.new(UsersController.consumer, @user.token, @user.secret)
    @response = UsersController.consumer.request(:put, "/api/v1/tasks/#{params[:id]}/accept.xml", @access_token, {:scheme => :query_string})
    render :xml => @response.body
  end

  # Start a task
  # http://developer.livework.com/LiveWork-API-Method%3A-tasks-start
  def start_task
    @user = User.find_by_username(session['user'])
    @access_token = OAuth::AccessToken.new(UsersController.consumer, @user.token, @user.secret)
    @response = UsersController.consumer.request(:put, "/api/v1/tasks/#{params[:id]}/start.xml", @access_token, {:scheme => :query_string})
    render :xml => @response.body
  end

  # Marks a task as complete
  # http://developer.livework.com/LiveWork-API-Method%3A-tasks-complete
  def complete_task
    @user = User.find_by_username(session['user'])
    @access_token = OAuth::AccessToken.new(UsersController.consumer, @user.token, @user.secret)
    @response = UsersController.consumer.request(:put, "/api/v1/tasks/#{params[:id]}/complete.xml", @access_token, {:scheme => :query_string})
    render :xml => @response.body
  end

  # Revise the amount of time spent working on a task which is paid for by the hour
  # http://developer.livework.com/LiveWork-API-Method%3A-tasks-revise_work_time
  def revise_work_time_task
    @user = User.find_by_username(session['user'])
    @access_token = OAuth::AccessToken.new(UsersController.consumer, @user.token, @user.secret)
    @response = UsersController.consumer.request(:put, "/api/v1/tasks/#{params[:id]}/revise_work_time.xml", @access_token, {:scheme => :query_string},
                                                 {'revised_hours' => 5,
                                                  'revised_minutes' => 15})
    render :xml => @response.body
  end
end
