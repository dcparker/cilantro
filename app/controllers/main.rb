class Main < Application

  scope '/'

  get :home => '' do
    template :index
  end

  scope :posts => 'posts' do
    get do
      template.posts = Post.all
      template :index
    end

    post do
      if post = Post.create(params[:post])
        redirect url(:post, post)
      else
      end
    end

    scope :post => ':id' do
      get do |id|
        template :show, :post => Post.get(id)
      end

      delete do |id|
        post = Post.get(id)
        if post.destroy
          redirect url(:posts)
        end
      end
    end
  end

  # This is not yet scoped to just one controller or scope.
  error do
    Cilantro.report_error(env['sinatra.error'])
    template :error_page
  end
end
