def convert(file, namespace, value)
  if value.is_a?(Hash)
    value.each do |key, value|
      convert(file, "#{namespace}.#{key}", value)
    end
  else
    file.puts %{"#{namespace}" = "#{value.to_s}";}
  end
end

def write_lproj_file(locale, all_translations)
  FileUtils.mkdir_p("resources/#{locale}.lproj")
  File.open("resources/#{locale}.lproj/Localizable.strings", 'w') do |file|
    all_translations.each do |key, value|
      convert(file, key, value)
    end
  end
end

def ios_translate
  require 'i18n'

I18n::Backend::Simple.include(I18n::Backend::Gettext)

  files = Dir.glob("locale/*.po")

  I18n.load_path.clear
  I18n.load_path << files

  files.each do |locale_file|
    locale = File.basename(locale_file).sub(".po", "")
    all_translations = I18n.backend.send(:lookup, locale.to_sym, "")
#    write_lproj_file('pt-BR', all_translations) if locale == 'pt'
#    write_lproj_file('pt', all_translations) if locale == 'pt-BR'
    write_lproj_file(locale, all_translations)
  end
end

desc "Translate (ios)"
task :translate do
  ios_translate
end

namespace :build do
  task :simulator => :translate
  task :device => :translate
end