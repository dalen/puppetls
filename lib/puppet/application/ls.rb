require 'puppet/application/face_base'

class Puppet::Application::Ls < Puppet::Application::FaceBase
  def app_defaults
    super.merge({
      :catalog_terminus => :rest,
      :catalog_cache_terminus => :json,
    })
  end

  def setup
    if Puppet[:catalog_cache_terminus]
      Puppet::Resource::Catalog.indirection.cache_class = Puppet[:catalog_cache_terminus]
    end
    super
  end
end
