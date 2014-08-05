# -*- coding: utf-8 -*-
require_relative 'helpers'

desc "Build the Components"
task :build_components do
  $package['contents']['components'].each { |c| build_component c } unless $package['contents']['components'].nil?
end

def build_component(name)
  component_build_area = File.join(build_area, 'com_' + name)

  mkdir_p component_build_area

  {"/administrator" => "admin","" => "site"}.each do |context,target_context|
    # Do Languages
    language_dirs = Dir.glob(".#{context}/language/*")

    language_dirs.each do |language_dir|
      language = language_dir.split("/").last

      language_files = Rake::FileList.new(".#{context}/language/#{language}/*com_#{name}*")

      language_files.each do |language_file|
        copy_to_dir = File.join(component_build_area, target_context, "language" , language)
        mkdir_p copy_to_dir rescue nil
        cp language_file , copy_to_dir
      end
    end

    # Do the other stuff
    mkdir_p File.join(component_build_area , target_context)
    files = Rake::FileList.new(".#{context}/components/com_#{name}/**/*")

    # Copy the installer script.
    if context == '/administrator'
      cp "./administrator/components/com_#{name}/script.php" , File.join(component_build_area, 'script.php')
    end

    files.each do |file_name|
      target_file_name = file_name.gsub(".#{context}/components/com_#{name}",target_context)
      if File.directory?(file_name)
        mkdir_p File.join(component_build_area, target_file_name)
      else
        copy_to = File.join(component_build_area, File.dirname(target_file_name))
        mkdir_p copy_to unless File.exist?(copy_to)
        cp file_name, File.join(copy_to,  File.basename(target_file_name)) 
      end
    end
  end
  
  # Build the manifest
  manifest_path = File.join(component_build_area , name + '.xml')
  manifest_file = File.open(manifest_path, 'w:UTF-8')
  manifest = Builder::XmlMarkup.new(:indent => 4, :target => manifest_file)

  manifest.instruct!

  manifest.extension({
                       :type => "component" , 
                       :version => $package['package']['target_version'] , 
                       :method => "upgrade"}) do |ext|

    ext.comment! "Manifest generated by builder script at #{Time.now}"

    ext.name 'com_' + name
    ext.description"COM_#{name.upcase}_XML_DESCRIPTION"
    ext.version version_name
    ext.copyright $package['package']['copyright']
    ext.creationDate "01 Jan 2010"
    ext.author $package['package']['author']
    ext.authorEmail $package['package']['author_email']
    ext.authorUrl $package['package']['author_url']

    ext.install do |install|
      install.sql do |sql|
        sql.file({:driver => "mysql" , :charset => "utf8"}, "sql/install.mysql.utf8.sql")
      end
    end


    ext.uninstall do |uninstall|
      uninstall.sql do |sql|
        sql.file({:driver => "mysql" , :charset => "utf8"}, "sql/uninstall.mysql.utf8.sql")
      end
    end

    ext.update do |update|
      update.schemas do |schema|
        schema.schemapath({:type => "mysql"}, "admin/sql/updates")
      end
    end


    ext.scriptfile "script.php" if File.exist?( File.join(component_build_area , 'admin' , 'script.php') )
    
    ext.administration do |admin|
      admin.menu({:img => "components/com_#{name}/assets/menu_icon.png"}, "COM_#{name.upcase}_MENUTITLE")

      admin.languages do |languages|
        language_dirs = Dir.glob( File.join(component_build_area, 'admin', 'language', '*') )
        language_dirs.each do |language_dir|

          language_code = language_dir.split('/').last
          language_files = Dir.glob(File.join(language_dir , '*.ini'))

          language_files.each do |language_file|
            language_path = language_file.gsub(component_build_area , '')
            languages.language({:tag => language_code}, language_path)
          end # language_files.each
        end # language_dir.each
      end # admin.languages
                            

      admin.files({:folder => "admin"}) do |files|
        Dir.glob(File.join(component_build_area , 'admin' , '*')).each do |f|
          if File.directory? f
            files.folder File.basename( f )
          else
            files.filename File.basename( f )
          end
        end
      end # Admin files
    end   # Admin

    ext.files({:folder => "site"}) do |files|
      Dir.glob(File.join(component_build_area, 'site' , '*')).each do |f|
        if File.directory? f
          files.folder File.basename( f )
        else
          files.filename File.basename( f )
        end # IF
      end # Files.each
    end   # Files
  end     # Manifest

  manifest.target!
  manifest_file.flush
  manifest_file.close

  chdir(component_build_area) do
    sh %{zip -r ../com_#{name}.zip *}
  end

end
