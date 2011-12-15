class UpdatesController < ApplicationController
  before_filter :process_params
  before_filter :require_user, :only => [:timeline, :replies]

  def index
    render_index(Update)
  end

  def timeline
    render_index(current_user.timeline(params))
  end

  def replies
    render_index(current_user.at_replies(params))
  end

  def show
    @update = Update.first(:id => params[:id])
    render :layout => "update"
  end

  def create
    # XXX: This should really be put into a model. Fat controller here!
    do_tweet = params[:tweet] == "1"
    u = Update.new(:text => params[:text],
                   :referral_id => params[:referral_id],
                   :author => current_user.author,
                   :twitter => do_tweet)

    # add entry to user's feed
    current_user.feed.updates << u

    unless u.valid?
      flash[:notice] = u.errors.values.join("\n")
    else
      current_user.feed.save
      current_user.save
      # tell hubs there is a new entry
      current_user.feed.ping_hubs

      flash[:notice] = "Update created."
    end

    if request.referrer
      redirect_to request.referrer
    else
      redirect_to root_path
    end
  end

  def destroy
    update = Update.first :id => params[:id]

    # lolsecurity.
    if update.author == current_user.author
      update.destroy

      flash[:notice] = "Update Baleeted!"
      redirect_to root_path
    else
      flash[:notice] = "I'm afraid I can't let you do that, #{current_user.name}."
      redirect_to back
    end
  end

  protected

  # Manage page state
  def set_pagination
    set_params_page
		@companies = Company.all
		
    @updates = @updates.paginate(:page => params[:page], :per_page => params[:per_page], :order => :created_at.desc)
		for j in 0..@updates.length-1
			inp = @updates[j][:text];
			@inp =  inp.split(/ /)
			@inp1 = []
			@arr = []
				@inp.each_with_index do |input,index|
				#render :text => @inp[index].inspect and return false
        	if @inp[index][0..0] == '$'
 					company = Company.find_by_name(@inp[index][1..-1].downcase)
					 if !company.blank?
	          	@arr << '<a href="' + company.link.to_s + '">'  + @inp[index]  + '</a>'       
						else
							@arr << @inp[index]
						end
  				else
           @arr << @inp[index]
  				end
				end
				@updates[j][:text] = @arr.join(' ')
		end
    set_pagination_buttons(@updates)
  end

  # Render correct haml depending on request type
  def render_index(updates)
    @updates = updates
    set_pagination
    render :index, :layout => show_layout?
  end

  def process_params
    @update_id, @update_text = "", ""

    # Set update form state correctly
    id = params.fetch("reply") { params["share"] }
    if id
      u = Update.first(:id => id)
      @update_id = id
      @update_text = "@#{u.author.username} " if params["reply"]
      @update_text = "RS @#{u.author.username}: #{u.text}" if params["share"]
    elsif params["status"]
      @update_text = params["status"]
    end
  end
end
