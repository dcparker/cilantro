class Listings < Application
  path :listings

  get do
    template :index, :listings => Listing.all
  end

  post do
    if listing = Listing.create(params[:listing])
      redirect url(:listing, listing)
    else
      redirect url(:listings)
    end
  end

  path :listing => ':id' do

    setup do |id|
      template.title = "Hello World!"
      template.listing = Listing.get(id)
    end

    get do |id|
      template.url = url(:formatted_listing, id, 'xml')
      template :show
    end

    get :formatted_listing => /\.([\w]+)/ do |id,format|
      content_type 'application/xml'
      template :show_xml
    end

    delete do |id|
      if template.listing.destroy
        redirect url(:listings)
      else
        status 500
        "There was an error deleting Listing ##{template.listing.id}!"
      end
    end

  end

end
