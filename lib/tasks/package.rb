def generate_release_notes

  require 'redcarpet'

  renderer = Redcarpet::Render::HTML.new({with_toc_data: true, hard_wrap: true})
  markdown = Redcarpet::Markdown.new(renderer, {no_intra_emphasis: true, tables: true})

  release_note_source = File.read("./release_notes.md")

  markdown.render(release_note_source)
end

desc "Generate Package Manifest"
task :package_manifest do
  require 'builder'

  if File.exists?("./release_notes.md")
    File.open( File.join(build_area , "./release_notes.html") ,'w').write(generate_release_notes)
  end

  manifest_path = File.join(build_area, 'pkg_' + $package['name'] + '.xml')
  manifest_file = File.open(manifest_path, 'w')

  manifest = Builder::XmlMarkup.new(:indent => 2, :target => manifest_file)
  manifest.extension({:type => "package" , :version => $package['package']['target_version'], :method => :upgrade}) do |ext|
    ext.comment! "Package Manifest Generated by Builder Script at #{Time.now}"
    ext.name $package['package']['name']
    ext.description $package['package']['description']
    ext.author $package['package']['author']
    ext.packagename $package['name']
    ext.update $package['package']['update_site'] + '/updates.xml' unless $package['package']['update_site'].nil?
    ext.createionDate Time.now

    ext.version version_name

    ext.files do |package_part|
      if $package['contents'].keys.include? 'components'
        $package['contents']['components'].each do |component|
          ext.file({:type => "component" , :id => "com_#{component}"} , "com_#{component}.zip")
        end # Components
      end # if components

      if $package['contents'].keys.include? 'modules'
        $package['contents']['modules'].each do |mod|
          ext.file({:type => "module" , :id => "mod_#{mod}"} , "mod_#{mod}.zip")
        end # Components
      end # if components

      if $package['contents'].keys.include? 'plugins'
        $package['contents']['plugins'].keys.each do |group|
          $package['contents']['plugins'][group].each do |plugin|
            ext.file({:type => "plugin" , :id => plugin , :group => group}, "plg_#{group}_#{plugin}.zip")
          end # Plugins
        end   # Plugin Groups
      end     # If plugins

      if $package['contents'].keys.include? 'libraries'
        $package['contents']['libraries'].each do |library|
          ext.file({:type => "library", :id => library}, "lib_#{library}.zip")
        end # Libraries
      end # If Libraries


      if $package['contents'].keys.include? 'templates'
        $package['contents']['templates'].each do |template|
          ext.file({:type => "template", :id => template , :client => "site"}, "tpl_#{template}.zip")
        end
      end

    end # Package Parts

    unless $package['package']['update_site'].nil?
      ext.updateservers do |server|
        ext.server({:type => "extension", :name => $package['package']['name']}, $package['package']['update_site'] + '/updates.xml')
      end
    end

  end # Document (Extension)

  manifest.target!
  manifest_file.flush
  manifest_file.close
end

# Prepare files in `package_files` for packaging
directory build_area => [
                         :build_libraries,
                         :build_components,
                         :build_plugins,
                         :build_templates,
                         :build_modules,
                         :package_manifest
                        ]

# Build the package zip
desc 'Build package zip archive'
task :package => [package_file_path]

file package_file_path => [build_area] do
  chdir(build_area) do

    # Remove the do_not_include files
    if $package.keys.include? 'do_not_include'
      $package['do_not_include'].each do |glob|
        Dir[glob].each do |f|
          rm f
        end
      end
    end

    sh "zip -r ../#{package_name}.zip *.zip pkg_#{$package['name']}.xml release_notes.html"
  end
end


desc 'Preview the release notes'
task :release_notes do
  p generate_release_notes
end

desc 'Preview the update manifest'
task :update_manifest do
  p update_manifest
end
