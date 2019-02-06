require "motion-gradle"

class MainActivity < Android::Support::V7::App::AppCompatActivity
  def onCreate(savedInstanceState)
    super
    UI.context = self

    welcome_screen = WelcomeScreen.new
    $navigation = UI::Navigation.new(welcome_screen)
    $app = UI::Application.new($navigation, self)
    $app.start
  end
end
