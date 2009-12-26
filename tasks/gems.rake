
# This doesn't really need to do anything special, it just loads the environment,
# which will automatically install the gems with the right permissions.
namespace :gems do
  namespace :refresh do
    task(:production => [:load_cilantro])  { Cilantro.load_environment :production  }
    task(:development => [:load_cilantro]) { Cilantro.load_environment :development }
  end
end
